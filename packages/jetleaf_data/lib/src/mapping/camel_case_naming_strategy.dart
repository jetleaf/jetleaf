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

/// {@template jetleaf_camel_case_naming_strategy}
/// [NamingStrategy] that preserves `camelCase` field names and lowercases only
/// the leading character of class names (`UserProfile` → `userProfile`,
/// `createdAt` → `createdAt`).
/// {@endtemplate}
final class CamelCaseNamingStrategy extends NamingStrategy {
  /// Reflective [Class] handle for [CamelCaseNamingStrategy].
  static final Class<CamelCaseNamingStrategy> CLASS =
      Class<CamelCaseNamingStrategy>(null, PackageNames.DATA);

  /// {@macro jetleaf_camel_case_naming_strategy}
  const CamelCaseNamingStrategy();

  @override
  String classToTableName(String simpleName) {
    if (simpleName.isEmpty) {
      return simpleName;
    }
    return simpleName[0].toLowerCase() + simpleName.substring(1);
  }

  @override
  String fieldToColumnName(String fieldName) => fieldName;
}
