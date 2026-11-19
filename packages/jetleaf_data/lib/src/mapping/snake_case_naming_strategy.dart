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

/// {@template jetleaf_snake_case_naming_strategy}
/// Default [NamingStrategy] converting `PascalCase` and `camelCase` identifiers
/// into lowercase `snake_case` (`UserProfile` → `user_profile`,
/// `createdAt` → `created_at`).
/// {@endtemplate}
final class SnakeCaseNamingStrategy extends NamingStrategy {
  /// Reflective [Class] handle for [SnakeCaseNamingStrategy].
  static final Class<SnakeCaseNamingStrategy> CLASS =
      Class<SnakeCaseNamingStrategy>(null, PackageNames.DATA);

  /// {@macro jetleaf_snake_case_naming_strategy}
  const SnakeCaseNamingStrategy();

  @override
  String classToTableName(String simpleName) => toSnakeCase(simpleName);

  @override
  String fieldToColumnName(String fieldName) => toSnakeCase(fieldName);

  /// Converts [value] to `snake_case`.
  static String toSnakeCase(String value) {
    final buffer = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      final char = value[i];
      if (char == '_' || char == '-') {
        buffer.write('_');
        continue;
      }

      if (i > 0 &&
          _isUpper(char) &&
          (_isLower(value[i - 1]) ||
              _isDigit(value[i - 1]) ||
              (_isUpper(value[i - 1]) &&
                  i + 1 < value.length &&
                  _isLower(value[i + 1])))) {
        buffer.write('_');
      }

      buffer.write(char.toLowerCase());
    }

    return buffer.toString().replaceAll(RegExp(r'__+'), '_');
  }

  static bool _isUpper(String c) =>
      c == c.toUpperCase() && c != c.toLowerCase();

  static bool _isLower(String c) =>
      c == c.toLowerCase() && c != c.toUpperCase();

  static bool _isDigit(String c) {
    final code = c.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }
}
