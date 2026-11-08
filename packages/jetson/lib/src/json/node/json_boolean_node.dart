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

/// {@template jetleaf_json_boolean_node}
/// Represents a **JSON boolean node** (`true` or `false`) in the Dart JSON model.
///
/// This node wraps a [bool] value and provides type-checking consistent with
/// [JsonNode].
///
/// ### Usage Example
/// ```dart
/// final boolNode = JsonBooleanNode(true);
///
/// if (boolNode.isBoolean()) {
///   print(boolNode.toObject()); // true
/// }
/// ```
///
/// ### Behavior Overview
/// | Dart JSON Value | Internal Representation | Description |
/// |-----------------|------------------------|-------------|
/// | `true` | `value = true` | Boolean true |
/// | `false` | `value = false` | Boolean false |
///
/// ### Design Notes
/// - Stores the boolean value in a final [value] field for immutability.
/// - Supports conversion back to native Dart [bool] via [toObject].
/// - Type-checking methods align with the [JsonNode] interface.
/// {@endtemplate}
class JsonBooleanNode implements JsonNode<bool> {
  /// The boolean value of this JSON node.
  final bool value;

  /// {@macro jetleaf_json_boolean_node}
  ///
  /// Creates a new [JsonBooleanNode] wrapping the given boolean [value].
  ///
  /// ### Example
  /// ```dart
  /// final node = JsonBooleanNode(false);
  /// print(node.value); // false
  /// ```
  JsonBooleanNode(this.value);

  @override
  bool isObject() => false;

  @override
  bool isArray() => false;

  @override
  bool isTextual() => false;

  @override
  bool isNumber() => false;

  @override
  bool isBoolean() => true;

  @override
  bool isNull() => false;

  @override
  bool toObject() => value;
}