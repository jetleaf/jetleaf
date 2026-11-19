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

import 'migration_operations.dart';
import 'migration_version.dart';
import 'sql_migration.dart';

export 'migration_operations.dart';
export 'sql_migration.dart';

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
  static final Class<Migration> CLASS =
      Class<Migration>(null, PackageNames.DATA);

  /// {@macro jetleaf_migration}
  const Migration();

  /// Returns the [MigrationVersion] of this migration.
  MigrationVersion getVersion();

  /// Applies this migration using [operations].
  Future<void> up(MigrationOperations operations);

  @override
  List<Object?> equalizedProperties() => [getVersion(), runtimeType];
}
