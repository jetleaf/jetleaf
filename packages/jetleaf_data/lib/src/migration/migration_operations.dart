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

/// {@template jetleaf_migration_operations}
/// Execution context passed to `Migration.up` for running schema DDL and
/// data evolution statements.
/// {@endtemplate}
abstract interface class MigrationOperations {
  /// Reflective [Class] handle for [MigrationOperations].
  static final Class<MigrationOperations> CLASS =
      Class<MigrationOperations>(null, PackageNames.DATA);

  /// Executes a raw SQL or DDL statement against the target database.
  Future<void> execute(String sql);
}
