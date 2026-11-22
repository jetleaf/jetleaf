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

/// 🚀 **JetLeaf Schema Migration & DDL Generation Library**
///
/// Provides versioned, checksum-verified database migrations and automatic
/// schema DDL generation from `@Entity` metadata:
/// - [Migration], [SqlMigration], [MigrationOperations], [MigrationVersion]
/// - [MigrationRunner] & [MigrationRunResult]
/// - [SchemaGenerator] & [SchemaGenerationResult]
///
/// ### Usage Example
/// ```dart
/// import 'package:jetleaf_data/migration.dart';
///
/// final runner = MigrationRunner(
///   client: databaseClient,
///   dialect: dialect,
///   migrations: [
///     SqlMigration(
///       MigrationVersion.parse('V1__create_users'),
///       ['CREATE TABLE users (id TEXT PRIMARY KEY, email TEXT NOT NULL)'],
///     ),
///   ],
/// );
/// final result = await runner.migrate();
/// ```
library;

export 'src/migration/migration.dart';
export 'src/migration/migration_runner.dart';
export 'src/migration/migration_version.dart';
export 'src/migration/schema_generator.dart';