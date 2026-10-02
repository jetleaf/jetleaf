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

import 'json_node.dart';

/// {@template jetleaf_json_text_node}
/// Represents a **JSON string node** in the Dart JSON model.
///
/// This node wraps a [String] value and provides type-checking
/// consistent with [JsonNode].
///
/// ### Usage Example
/// ```dart
/// final textNode = JsonTextNode('Hello, world!');
///
/// if (textNode.isTextual()) {
///   print(textNode.toObject()); // 'Hello, world!'
/// }
/// ```
///
/// ### Behavior Overview
/// | Dart JSON Value | Internal Representation | Description |
/// |-----------------|------------------------|-------------|
/// | `"text"` | `value = 'text'` | Simple JSON string |
/// | `""` | `value = ''` | Empty string |
///
/// ### Design Notes
/// - Stores the string in a final [value] field for immutability.
/// - Supports safe conversion back to native Dart [String] via [toObject].
/// - Type-checking methods are consistent with the [JsonNode] interface.
/// {@endtemplate}
class JsonTextNode implements JsonNode<String> {
  /// The underlying string value of this JSON node.
  final String value;

  /// Creates a new [JsonTextNode] wrapping the given [value].
  ///
  /// ### Example
  /// ```dart
  /// final node = JsonTextNode('Alice');
  /// print(node.value); // 'Alice'
  /// ```
  /// 
  /// {@macro jetleaf_json_text_node}
  JsonTextNode(this.value);

  @override
  bool isObject() => false;

  @override
  bool isArray() => false;

  @override
  bool isTextual() => true;

  @override
  bool isNumber() => false;

  @override
  bool isBoolean() => false;

  @override
  bool isNull() => false;

  @override
  String toObject() => value;
}