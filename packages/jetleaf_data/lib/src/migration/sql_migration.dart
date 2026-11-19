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

import 'migration.dart';

import 'migration_version.dart';

/// {@template jetleaf_sql_migration}
/// Concrete [Migration] implementation backed by an ordered list of SQL
/// statements.
/// {@endtemplate}
final class SqlMigration extends Migration {
  /// Reflective [Class] handle for [SqlMigration].
  static final Class<SqlMigration> CLASS =
      Class<SqlMigration>(null, PackageNames.DATA);

  final MigrationVersion _version;
  final List<String> _statements;

  /// {@macro jetleaf_sql_migration}
  const SqlMigration(this._version, this._statements);

  @override
  MigrationVersion getVersion() => _version;

  /// Returns the ordered list of SQL statements executed by this migration.
  List<String> getStatements() => _statements;

  @override
  Future<void> up(MigrationOperations operations) async {
    for (final statement in _statements) {
      await operations.execute(statement);
    }
  }

  @override
  List<Object?> equalizedProperties() => [_version, _statements];
}
