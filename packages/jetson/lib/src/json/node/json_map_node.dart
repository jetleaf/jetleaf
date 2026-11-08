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

/// {@template jetleaf_json_object_node}
/// Represents a **JSON object node** (`{...}`) in the Dart JSON model.
///
/// Each field in the object is stored as a key-value pair, where the key
/// is a `String` and the value is another [JsonNode]. This node allows
/// building hierarchical JSON structures programmatically.
///
/// ### Usage Example
/// ```dart
/// final objNode = JsonObjectNode();
/// objNode.set('name', JsonTextNode('Alice'));
/// objNode.set('age', JsonNumberNode(30));
///
/// final nameNode = objNode.get('name');
/// print(nameNode?.toObject()); // 'Alice'
///
/// final map = objNode.toObject();
/// print(map); // {'name': 'Alice', 'age': 30}
/// ```
///
/// ### Behavior Overview
/// | Dart JSON Object | Internal Representation | Description |
/// |-----------------|------------------------|-------------|
/// | `{}` | `_fields` empty map | Empty JSON object |
/// | `{"a": 1}` | `_fields['a'] = JsonNumberNode(1)` | Simple field |
/// | `{"nested": {"x": true}}` | `_fields['nested'] = JsonObjectNode(...)` | Nested object |
///
/// ### Design Notes
/// - Maintains fields in a `Map<String, JsonNode>` for fast key lookup.
/// - Supports programmatic addition and retrieval of fields via [set] and [get].
/// - [toObject] converts the node and all nested nodes to native Dart objects recursively.
/// - Type-checking is consistent with [JsonNode] methods.
/// {@endtemplate}
class JsonMapNode implements JsonNode<Map<String, dynamic>> {
  /// {@macro jetleaf_json_object_node}
  JsonMapNode();

  /// Internal storage for the object’s fields.
  final Map<String, JsonNode> _fields = {};

  /// Sets or replaces a field in the JSON object.
  ///
  /// If a field with the given [key] already exists, its value is replaced
  /// with [value]. Otherwise, a new field is added.
  ///
  /// ### Example
  /// ```dart
  /// final obj = JsonObjectNode();
  /// obj.set('name', JsonTextNode('Alice'));
  /// obj.set('age', JsonNumberNode(30));
  /// ```
  void set(String key, JsonNode value) {
    _fields[key] = value;
  }

  /// Retrieves the [JsonNode] associated with the given [key].
  ///
  /// Returns `null` if the key does not exist in this object.
  ///
  /// ### Example
  /// ```dart
  /// final node = obj.get('name');
  /// if (node != null && node.isTextual()) {
  ///   print(node.toObject()); // 'Alice'
  /// }
  /// ```
  JsonNode? get(String key) => _fields[key];

  /// Returns an unmodifiable view of all fields in this JSON object.
  ///
  /// The keys are [String] and the values are [JsonNode]. Modifying the
  /// returned map will affect the internal state of this object.
  ///
  /// ### Example
  /// ```dart
  /// final allFields = obj.fields;
  /// print(allFields.keys); // ['name', 'age']
  /// ```
  Map<String, JsonNode> get fields => _fields;

  @override
  bool isObject() => true;

  @override
  bool isArray() => false;

  @override
  bool isTextual() => false;

  @override
  bool isNumber() => false;

  @override
  bool isBoolean() => false;

  @override
  bool isNull() => false;

  @override
  Map<String, dynamic> toObject() {
    final map = <String, dynamic>{};
    _fields.forEach((k, v) => map[k] = v.toObject());
    return map;
  }
}