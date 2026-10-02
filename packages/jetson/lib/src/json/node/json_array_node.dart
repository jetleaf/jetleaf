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

/// {@template jetleaf_json_array_node}
/// Represents a **JSON array node** (`[...]`) in the Dart JSON model.
///
/// Each element in the array is a [JsonNode], allowing hierarchical
/// JSON structures to be constructed programmatically.
///
/// ### Usage Example
/// ```dart
/// final arrayNode = JsonArrayNode();
/// arrayNode.add(JsonTextNode('Alice'));
/// arrayNode.add(JsonNumberNode(30));
///
/// final first = arrayNode.elements.first;
/// print(first.toObject()); // 'Alice'
///
/// final list = arrayNode.toObject();
/// print(list); // ['Alice', 30]
/// ```
///
/// ### Behavior Overview
/// | Dart JSON Array | Internal Representation | Description |
/// |----------------|------------------------|-------------|
/// | `[]` | `_elements` empty list | Empty array |
/// | `[1, 2, 3]` | `_elements = [JsonNumberNode(1), ...]` | Simple numeric array |
/// | `[{"a":1}, "text"]` | Nested object and string nodes | Mixed types supported |
///
/// ### Design Notes
/// - Maintains elements in a `List<JsonNode>` to preserve order.
/// - Supports programmatic addition via [add].
/// - [toObject] converts the node and all nested nodes to native Dart objects recursively.
/// - Type-checking is consistent with [JsonNode] methods.
/// {@endtemplate}
class JsonArrayNode implements JsonNode<List<dynamic>> {
  /// {@macro jetleaf_json_array_node}
  JsonArrayNode();

  /// Internal storage for the array’s elements.
  final List<JsonNode> _elements = [];

  /// Adds a [JsonNode] to the end of this JSON array.
  ///
  /// Preserves the order of insertion. The array can contain mixed types.
  ///
  /// ### Example
  /// ```dart
  /// final array = JsonArrayNode();
  /// array.add(JsonTextNode('Alice'));
  /// array.add(JsonNumberNode(30));
  /// ```
  void add(JsonNode value) => _elements.add(value);

  /// Returns a read-only view of the elements in this array.
  ///
  /// Each element is a [JsonNode], allowing traversal or inspection.
  ///
  /// ### Example
  /// ```dart
  /// final first = array.elements.first;
  /// print(first.toObject()); // 'Alice'
  /// ```
  List<JsonNode> get elements => _elements;

  @override
  bool isObject() => false;

  @override
  bool isArray() => true;

  @override
  bool isTextual() => false;

  @override
  bool isNumber() => false;

  @override
  bool isBoolean() => false;

  @override
  bool isNull() => false;

  @override
  List<dynamic> toObject() => _elements.map((e) => e.toObject()).toList();
}