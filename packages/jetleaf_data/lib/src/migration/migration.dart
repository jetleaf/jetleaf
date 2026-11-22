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

import 'dart:async';

import 'package:jetleaf_core/lang.dart';

import 'migration_version.dart';

/// {@template jetleaf_migration_operations}
/// Execution context passed to [Migration.up] for running schema DDL and
/// data evolution statements.
/// {@endtemplate}
abstract interface class MigrationOperations {
  /// Reflective [Class] handle for [MigrationOperations].
  static final Class<MigrationOperations> CLASS = Class<MigrationOperations>(null, PackageNames.DATA);

  /// Executes a raw SQL or DDL statement against the target database.
  Future<void> execute(String sql);
}

/// {@template jetleaf_migration}
/// Abstract base class for a versioned, checksum-verified schema migration.
///
/// ### Usage Example
/// ```dart
/// final class AddUserEmailIndex extends Migration {
///   const AddUserEmailIndex();
///
///   @override
///   MigrationVersion getVersion() =>
///       MigrationVersion.parse('V3__add_unique_index');
///
///   @override
///   Future<void> up(MigrationOperations operations) async {
///     await operations.execute(
///       'CREATE UNIQUE INDEX idx_users_email ON users (email)',
///     );
///   }
/// }
/// ```
///
/// ### See Also
/// - [SqlMigration]
/// - [MigrationVersion]
/// - [MigrationOperations]
/// - `MigrationRunner`
/// {@endtemplate}
abstract class Migration with EqualsAndHashCode {
  /// Reflective [Class] handle for [Migration].
  static final Class<Migration> CLASS = Class<Migration>(null, PackageNames.DATA);

  /// {@macro jetleaf_migration}
  const Migration();

  /// Returns the [MigrationVersion] of this migration.
  MigrationVersion getVersion();

  /// Applies this migration using [operations].
  Future<void> up(MigrationOperations operations);

  @override
  List<Object?> equalizedProperties() => [getVersion(), runtimeType];
}

/// {@template jetleaf_sql_migration}
/// Concrete [Migration] implementation backed by an ordered list of SQL
/// statements.
/// {@endtemplate}
final class SqlMigration extends Migration {
  /// Reflective [Class] handle for [SqlMigration].
  static final Class<SqlMigration> CLASS = Class<SqlMigration>(null, PackageNames.DATA);

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