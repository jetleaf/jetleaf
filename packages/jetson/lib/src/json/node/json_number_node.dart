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

/// {@template jetleaf_json_numeric_node}
/// Represents a **JSON numeric node** in the Dart JSON model.
///
/// This node wraps a numeric value (`int` or `double`) and provides
/// type-checking consistent with [JsonNode].
///
/// ### Usage Example
/// ```dart
/// final numNode = JsonNumberNode(42);
///
/// if (numNode.isNumber()) {
///   print(numNode.toObject()); // 42
/// }
/// ```
///
/// ### Behavior Overview
/// | Dart JSON Value | Internal Representation | Description |
/// |-----------------|------------------------|-------------|
/// | `42` | `value = 42` | Integer value |
/// | `3.14` | `value = 3.14` | Floating-point value |
///
/// ### Design Notes
/// - Stores the numeric value in a final [value] field for immutability.
/// - Supports conversion back to native Dart [num] via [toObject].
/// - Type-checking methods align with the [JsonNode] interface.
/// {@endtemplate}
class JsonNumberNode implements JsonNode<num> {
  /// The numeric value of this JSON node.
  final num value;

  /// {@macro jetleaf_json_numeric_node}
  ///
  /// Creates a new [JsonNumberNode] wrapping the given numeric [value].
  ///
  /// ### Example
  /// ```dart
  /// final node = JsonNumberNode(3.14);
  /// print(node.value); // 3.14
  /// ```
  JsonNumberNode(this.value);

  @override
  bool isObject() => false;

  @override
  bool isArray() => false;

  @override
  bool isTextual() => false;

  @override
  bool isNumber() => true;

  @override
  bool isBoolean() => false;

  @override
  bool isNull() => false;

  @override
  num toObject() => value;
}