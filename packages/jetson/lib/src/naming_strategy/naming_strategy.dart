// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & Jetleaf Contributors. All rights reserved.
//
// This source file is part of the Jetleaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the Jetleaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'package:jetleaf_lang/lang.dart';

/// {@template naming_strategy}
/// Provides a unified interface for **field name transformation** between
/// Dart-style and JSON-style representations.
///
/// The [NamingStrategy] defines the transformation rules used to map
/// Dart identifiers (typically in `camelCase`) to JSON-compatible
/// names (such as `snake_case` or `kebab-case`) and back.
///
/// ### Overview
/// Implementations of this interface provide predictable and reversible
/// conversions between internal Dart field names and external JSON keys.
///
/// This is a **core abstraction** used by Jetleaf serialization systems
/// such as `JsonMapper`, `ObjectCodec`, and other reflection-based
/// adapters that require naming consistency.
///
/// ### Example
/// ```dart
/// final strategy = SnakeCaseNamingStrategy();
///
/// final jsonKey = strategy.toJsonName('userName'); // 'user_name'
/// final dartField = strategy.toDartName('user_name'); // 'userName'
/// ```
///
/// ### Common Strategies
/// - **Snake case** (`userName` → `user_name`)
/// - **Kebab case** (`userName` → `user-name`)
/// - **Pascal case** (`userName` → `UserName`)
///
/// ### Implementation Notes
/// - Implementations must be **deterministic** (same input yields same output)
/// - The transformation must be **reversible** (see [toDartName])
/// - Should handle **acronyms**, **numbers**, and **edge cases** gracefully
///
/// ### See also
/// - [toJsonName]
/// - [toDartName]
/// {@endtemplate}
abstract interface class NamingStrategy {
  /// Represents the [NamingStrategy] type for reflection and framework-level
  /// type resolution within the Jetson serialization system.
  ///
  /// This static [Class] reference allows runtime introspection and dynamic
  /// discovery of custom naming strategies (e.g., snake_case, camelCase).
  /// It enables the framework to identify parameters or components requiring
  /// a specific naming policy.
  static final Class<NamingStrategy> CLASS = Class<NamingStrategy>(null, PackageNames.JETSON);

  /// Converts a Dart field name into a JSON-compatible name.
  ///
  /// Called during **serialization** to transform `camelCase`
  /// identifiers into the desired JSON format.
  ///
  /// Example:
  /// ```dart
  /// toJsonName('userName'); // → user_name
  /// ```
  ///
  /// Implementations should ensure consistent, reversible transformations.
  String toJsonName(String name);

  /// Converts a JSON field name back into a Dart-compatible identifier.
  ///
  /// Called during **deserialization** to transform `snake_case` or
  /// `kebab-case` names into valid Dart field identifiers.
  ///
  /// Example:
  /// ```dart
  /// toDartName('user_name'); // → userName
  /// ```
  ///
  /// Should be the inverse of [toJsonName].
  String toDartName(String name);
}