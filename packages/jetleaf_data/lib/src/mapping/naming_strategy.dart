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

import 'naming_strategies.dart';

/// {@template jetleaf_naming_strategy}
/// Strategy contract for translating Dart class and field identifiers into
/// physical database **table** and **column** names.
///
/// | Strategy | Class `UserProfile` | Field `createdAt` |
/// |----------|---------------------|-------------------|
/// | [SnakeCaseNamingStrategy] | `user_profile` | `created_at` |
/// | [CamelCaseNamingStrategy] | `userProfile` | `createdAt` |
/// | [KebabCaseNamingStrategy] | `user-profile` | `created-at` |
///
/// ### See Also
/// - [SnakeCaseNamingStrategy]
/// - [CamelCaseNamingStrategy]
/// - [KebabCaseNamingStrategy]
/// {@endtemplate}
abstract class NamingStrategy with EqualsAndHashCode {
  /// Reflective [Class] handle for [NamingStrategy].
  static final Class<NamingStrategy> CLASS = Class<NamingStrategy>(null, PackageNames.DATA);

  /// Canonical `snake_case` naming strategy (`UserProfile` → `user_profile`).
  static const NamingStrategy snakeCase = SnakeCaseNamingStrategy();

  /// Canonical `camelCase` naming strategy (`UserProfile` → `userProfile`).
  static const NamingStrategy camelCase = CamelCaseNamingStrategy();

  /// Canonical `kebab-case` naming strategy (`UserProfile` → `user-profile`).
  static const NamingStrategy kebabCase = KebabCaseNamingStrategy();

  /// {@macro jetleaf_naming_strategy}
  const NamingStrategy();

  /// Converts an entity class [simpleName] into its physical table or
  /// collection name.
  String classToTableName(String simpleName);

  /// Converts an entity [fieldName] into its physical column or document key
  /// name.
  String fieldToColumnName(String fieldName);

  @override
  List<Object?> equalizedProperties() => [runtimeType];
}