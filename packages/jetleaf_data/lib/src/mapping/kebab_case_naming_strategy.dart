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

import 'naming_strategy.dart';

/// {@template jetleaf_kebab_case_naming_strategy}
/// [NamingStrategy] converting identifiers into `kebab-case`
/// (`UserProfile` → `user-profile`, `createdAt` → `created-at`).
/// {@endtemplate}
final class KebabCaseNamingStrategy extends NamingStrategy {
  /// Reflective [Class] handle for [KebabCaseNamingStrategy].
  static final Class<KebabCaseNamingStrategy> CLASS =
      Class<KebabCaseNamingStrategy>(null, PackageNames.DATA);

  /// {@macro jetleaf_kebab_case_naming_strategy}
  const KebabCaseNamingStrategy();

  @override
  String classToTableName(String simpleName) =>
      SnakeCaseNamingStrategy.toSnakeCase(simpleName).replaceAll('_', '-');

  @override
  String fieldToColumnName(String fieldName) =>
      SnakeCaseNamingStrategy.toSnakeCase(fieldName).replaceAll('_', '-');
}
