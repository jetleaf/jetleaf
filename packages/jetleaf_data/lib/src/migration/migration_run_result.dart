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

import 'migration_version.dart';

/// {@template jetleaf_migration_run_result}
/// Immutable summary of a `MigrationRunner.migrate` execution.
/// {@endtemplate}
final class MigrationRunResult with EqualsAndHashCode {
  /// Reflective [Class] handle for [MigrationRunResult].
  static final Class<MigrationRunResult> CLASS =
      Class<MigrationRunResult>(null, PackageNames.DATA);

  final List<MigrationVersion> _applied;
  final List<MigrationVersion> _skipped;

  /// {@macro jetleaf_migration_run_result}
  const MigrationRunResult({
    List<MigrationVersion> applied = const [],
    List<MigrationVersion> skipped = const [],
  })  : _applied = applied,
        _skipped = skipped;

  /// Returns the [MigrationVersion]s applied during this run.
  List<MigrationVersion> getApplied() => _applied;

  /// Returns the [MigrationVersion]s skipped because they were already applied.
  List<MigrationVersion> getSkipped() => _skipped;

  /// Returns the total number of migrations evaluated (`getApplied().length + getSkipped().length`).
  int getTotal() => _applied.length + _skipped.length;

  @override
  List<Object?> equalizedProperties() => [_applied, _skipped];
}
