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

/// Enumerates all **token types** that a [JsonParser] can encounter during
/// JSON parsing.
///
/// Tokens represent both **structural** and **value-level** elements within
/// a JSON document, enabling fine-grained parsing control.
///
/// ### Example
/// ```dart
/// if (parser.getCurrentToken() == JsonToken.VALUE_NUMBER) {
///   print('Found a number: ${parser.getCurrentValue()}');
/// }
/// ```
///
/// ### Categories
/// - **Structural tokens:** [START_OBJECT], [END_OBJECT], [START_ARRAY], [END_ARRAY]  
/// - **Field tokens:** [FIELD_NAME]  
/// - **Value tokens:** [VALUE_STRING], [VALUE_NUMBER], [VALUE_BOOLEAN], [VALUE_NULL]
///
/// See also:
/// - [JsonParser]
enum JsonToken {
  /// Indicates the beginning of a JSON object (`{`).
  START_OBJECT,

  /// Indicates the end of a JSON object (`}`).
  END_OBJECT,

  /// Indicates the beginning of a JSON array (`[`).
  START_ARRAY,

  /// Indicates the end of a JSON array (`]`).
  END_ARRAY,

  /// Represents a field name within a JSON object.
  FIELD_NAME,

  /// Represents a string value.
  VALUE_STRING,

  /// Represents a numeric value.
  VALUE_NUMBER,

  /// Represents a boolean value (`true` or `false`).
  VALUE_BOOLEAN,

  /// Represents a null literal (`null`).
  VALUE_NULL,
}