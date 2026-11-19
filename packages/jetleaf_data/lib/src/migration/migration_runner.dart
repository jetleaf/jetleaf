// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
//
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'package:jetleaf_core/lang.dart';
import 'package:jetleaf_core/logging.dart';

import '../dialect/database_dialect.dart';
import '../dialect/document_dialect.dart';
import '../dialect/sql_dialect.dart';
import '../driver/database_client.dart';
import '../exception/data_access_exception.dart';
import 'migration.dart';
import 'migration_run_result.dart';
import 'migration_version.dart';

export 'migration_run_result.dart';

/// {@template jetleaf_migration_runner}
/// Executes ordered, checksum-verified schema [Migration]s against a
/// [DatabaseClient] and [DatabaseDialect].
///
/// ### Features
/// - Creates and maintains the `jetleaf_schema_migrations` bookkeeping table
///   (or collection for document stores).
/// - Computes FNV-1a 64-bit checksums to detect post-application drift.
/// - Executes each SQL migration inside an atomic transaction, rolling back
///   on failure.
/// {@endtemplate}
final class MigrationRunner with EqualsAndHashCode {
  /// Reflective [Class] handle for [MigrationRunner].
  static final Class<MigrationRunner> CLASS =
      Class<MigrationRunner>(null, PackageNames.DATA);

  /// Default bookkeeping table/collection name.
  static const String MIGRATIONS_TABLE = 'jetleaf_schema_migrations';

  /// Alias for [MIGRATIONS_TABLE].
  static const String migrationsTable = MIGRATIONS_TABLE;

  final DatabaseClient _client;
  final DatabaseDialect _dialect;
  final Log _logger = LogFactory.getLog('migrationRunner');

  /// {@macro jetleaf_migration_runner}
  MigrationRunner(this._client, this._dialect);

  /// Returns the [DatabaseClient] used by this runner.
  DatabaseClient getClient() => _client;

  /// Returns the [DatabaseDialect] used by this runner.
  DatabaseDialect getDialect() => _dialect;

  /// Applies all pending migrations in [migrations] in ascending version order.
  Future<MigrationRunResult> migrate(List<Migration> migrations) async {
    _checkDuplicates(migrations);

    await _ensureBookkeepingTable();
    final appliedRows = await _appliedRows();
    _verifyChecksums(migrations, appliedRows);

    final pending = [...migrations]
      ..sort((a, b) => a.getVersion().compareTo(b.getVersion()));
    final appliedNow = <MigrationVersion>[];
    final skipped = <MigrationVersion>[];

    for (final migration in pending) {
      final version = migration.getVersion();
      if (appliedRows.containsKey(version.getValue())) {
        skipped.add(version);
        continue;
      }

      _logger.info(
        'Applying migration ${version.getValue()}${version.getDescription() != null ? ' (${version.getDescription()})' : ''}',
      );
      await _applyOne(migration);
      appliedNow.add(version);
    }

    _logger.info(
      'Migration complete — ${appliedNow.length} applied, ${skipped.length} already up to date',
    );
    return MigrationRunResult(
      applied: List.unmodifiable(appliedNow),
      skipped: List.unmodifiable(skipped),
    );
  }

  /// Validates checksums of already-applied migrations against [migrations],
  /// returning any mismatched [MigrationVersion]s.
  Future<List<MigrationVersion>> validate(List<Migration> migrations) async {
    await _ensureBookkeepingTable();
    final appliedRows = await _appliedRows();
    final mismatches = <MigrationVersion>[];

    for (final migration in migrations) {
      final version = migration.getVersion();
      final row = appliedRows[version.getValue()];
      if (row == null) continue;

      if (_checksumOf(migration) != row.checksum) {
        mismatches.add(version);
      }
    }

    return mismatches;
  }

  void _checkDuplicates(List<Migration> migrations) {
    final seen = <String>{};
    for (final migration in migrations) {
      final versionVal = migration.getVersion().getValue();
      if (!seen.add(versionVal)) {
        throw MigrationException(
          'Duplicate migration version $versionVal in the supplied set',
        );
      }
    }
  }

  Future<void> _ensureBookkeepingTable() async {
    if (_dialect is DocumentDialect) {
      return;
    }

    final sql = _dialect as SqlDialect;
    final table = sql.escapeIdentifier(MIGRATIONS_TABLE);
    final statement = '''
CREATE TABLE IF NOT EXISTS $table (
  version VARCHAR(255) PRIMARY KEY,
  description VARCHAR(1024),
  checksum VARCHAR(64) NOT NULL,
  applied_at TEXT NOT NULL
)''';

    await _client.execute(statement);
  }

  Future<Map<String, _AppliedRow>> _appliedRows() async {
    if (_dialect is DocumentDialect) {
      final documents = await _client.findDocuments(
        MIGRATIONS_TABLE,
        const {},
      );

      return {
        for (final document in documents)
          if (document['version'] != null)
            document['version'].toString(): _AppliedRow(
              version: document['version'].toString(),
              description: document['description']?.toString(),
              checksum: document['checksum']?.toString() ?? '',
            ),
      };
    }

    final sql = _dialect as SqlDialect;
    final table = sql.escapeIdentifier(MIGRATIONS_TABLE);
    final result = await _client.query(
      'SELECT version, description, checksum FROM $table',
    );

    return {
      for (final row in result.getRows())
        row['version']?.toString() ?? '': _AppliedRow(
          version: row['version']?.toString() ?? '',
          description: row['description']?.toString(),
          checksum: row['checksum']?.toString() ?? '',
        ),
    };
  }

  void _verifyChecksums(
    List<Migration> migrations,
    Map<String, _AppliedRow> appliedRows,
  ) {
    for (final migration in migrations) {
      final versionVal = migration.getVersion().getValue();
      final row = appliedRows[versionVal];
      if (row == null) continue;

      final expected = _checksumOf(migration);
      if (expected != row.checksum) {
        throw MigrationException(
          'Checksum mismatch for migration $versionVal — the migration was applied but has since been modified. '
          'Fix the checksum history or revert the migration.',
        );
      }
    }
  }

  String _checksumOf(Migration migration) {
    var hash = 0xcbf29ce484222325;
    const prime = 0x100000001b3;

    void absorb(String value) {
      for (final unit in value.codeUnits) {
        hash ^= unit;
        hash = (hash * prime) & 0xffffffffffffffff;
      }
    }

    absorb(migration.getVersion().getValue());
    switch (migration) {
      case SqlMigration sql:
        for (final statement in sql.getStatements()) {
          absorb(statement);
        }
      default:
        absorb(migration.runtimeType.toString());
    }

    return hash.toRadixString(16).padLeft(16, '0');
  }

  Future<void> _applyOne(Migration migration) async {
    final operations = _ClientMigrationOperations(_client);
    final versionVal = migration.getVersion().getValue();

    if (_dialect is DocumentDialect) {
      try {
        await migration.up(operations);
      } on Object catch (error) {
        throw MigrationException(
          'Migration $versionVal failed: $error',
          error,
        );
      }
      await _recordApplied(migration);
      return;
    }

    await _client.beginTransaction();
    try {
      await migration.up(operations);
      await _recordApplied(migration);
      await _client.commitTransaction();
    } on Object catch (error) {
      await _client.rollbackTransaction();
      throw MigrationException(
        'Migration $versionVal failed: $error',
        error,
      );
    }
  }

  Future<void> _recordApplied(Migration migration) async {
    final appliedAt = DateTime.now().toUtc().toIso8601String();
    final version = migration.getVersion();

    if (_dialect is DocumentDialect) {
      await _client.insertDocument(MIGRATIONS_TABLE, {
        'version': version.getValue(),
        'description': version.getDescription(),
        'checksum': _checksumOf(migration),
        'applied_at': appliedAt,
      });
      return;
    }

    final sql = _dialect as SqlDialect;
    final table = sql.escapeIdentifier(MIGRATIONS_TABLE);
    final isDollar =
        sql.getParameterStyle() == SqlParameterStyle.dollarNumbered;
    final placeholders = isDollar ? r'$1, $2, $3, $4' : '?, ?, ?, ?';

    await _client.execute(
      'INSERT INTO $table (version, description, checksum, applied_at) VALUES ($placeholders)',
      parameters: [
        version.getValue(),
        version.getDescription(),
        _checksumOf(migration),
        appliedAt,
      ],
    );
  }

  @override
  List<Object?> equalizedProperties() => [_client, _dialect];
}

final class _AppliedRow {
  final String version;
  final String? description;
  final String checksum;

  _AppliedRow({
    required this.version,
    required this.description,
    required this.checksum,
  });
}

final class _ClientMigrationOperations implements MigrationOperations {
  final DatabaseClient client;

  _ClientMigrationOperations(this.client);

  @override
  Future<void> execute(String sql) => client.execute(sql);
}
