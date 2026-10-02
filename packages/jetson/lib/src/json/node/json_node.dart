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

import '../../base/node.dart';

/// {@template jetleaf_json_node}
/// Base class for all **JSON nodes** in the Dart model.  
///
/// Each implementation represents a JSON value, such as an object, array,
/// string, number, boolean, or null. This class provides type-checking
/// helpers and a method to convert the node back to a Dart object.
///
/// ### Usage Example
/// ```dart
/// final node = JsonObjectNode({
///   'name': JsonTextNode('Alice'),
///   'age': JsonNumberNode(30),
/// });
///
/// if (node.isObject()) {
///   print('This is a JSON object.');
/// }
///
/// final obj = node.toObject();
/// print(obj); // {'name': 'Alice', 'age': 30}
/// ```
///
/// ### Behavior Overview
/// | Node Type | Dart Representation | Description |
/// |-----------|------------------|-------------|
/// | Object | `Map<String, Object>` | JSON objects |
/// | Array | `List<Object>` | JSON arrays |
/// | Text | `String` | JSON strings |
/// | Number | `num` | JSON numbers |
/// | Boolean | `bool` | JSON boolean |
/// | Null | `null` | JSON null |
///
/// ### Design Notes
/// - Provides convenient type-checking methods (`isObject()`, `isArray()`, etc.).  
/// - Supports conversion back to Dart objects via `toObject()`.  
/// - Serves as the base for all concrete JSON node implementations.  
///
/// ### See Also
/// - [JsonObjectNode]
/// - [JsonArrayNode]
/// - [JsonTextNode]
/// - [JsonNumberNode]
/// - [JsonBooleanNode]
/// - [JsonNullNode]
/// {@endtemplate}
@Generic(JsonNode)
abstract interface class JsonNode<ObjectType> implements Node<ObjectType> {
  /// {@macro jetleaf_json_node}
  const JsonNode();
  
  /// Returns `true` if this node represents a JSON object (`{...}`).
  ///
  /// JSON objects are represented as Dart [Map<String, Object>] when converted
  /// via [toObject]. Use this method to safely check the node type before
  /// casting or iterating its fields.
  ///
  /// ### Example
  /// ```dart
  /// if (node.isObject()) {
  ///   final map = node.toObject() as Map<String, Object>;
  ///   print(map.keys);
  /// }
  /// ```
  bool isObject();

  /// Returns `true` if this node represents a JSON array (`[...]`).
  ///
  /// JSON arrays are represented as Dart [List<Object>] when converted
  /// via [toObject]. This is useful for iterating elements or validating
  /// the type before performing array operations.
  ///
  /// ### Example
  /// ```dart
  /// if (node.isArray()) {
  ///   final list = node.toObject() as List<Object>;
  ///   print(list.length);
  /// }
  /// ```
  bool isArray();

  /// Returns `true` if this node represents a JSON string.
  ///
  /// JSON strings are represented as Dart [String] when converted via
  /// [toObject]. This method allows safe type-checking before performing
  /// string operations like concatenation or formatting.
  ///
  /// ### Example
  /// ```dart
  /// if (node.isTextual()) {
  ///   final text = node.toObject() as String;
  ///   print(text.toUpperCase());
  /// }
  /// ```
  bool isTextual();

  /// Returns `true` if this node represents a JSON number.
  ///
  /// JSON numbers can be either [int] or [double] in Dart. This method
  /// ensures that the node can safely be cast to [num] before arithmetic
  /// operations.
  ///
  /// ### Example
  /// ```dart
  /// if (node.isNumber()) {
  ///   final number = node.toObject() as num;
  ///   print(number + 10);
  /// }
  /// ```
  bool isNumber();

  /// Returns `true` if this node represents a JSON boolean (`true` or `false`).
  ///
  /// JSON booleans are represented as Dart [bool]. Use this method to
  /// safely check the node type before performing logical operations.
  ///
  /// ### Example
  /// ```dart
  /// if (node.isBoolean()) {
  ///   final flag = node.toObject() as bool;
  ///   print(flag ? 'Yes' : 'No');
  /// }
  /// ```
  bool isBoolean();

  /// Returns `true` if this node represents a JSON `null`.
  ///
  /// JSON null is represented as Dart `null`. This method allows you to
  /// detect missing or empty values safely.
  ///
  /// ### Example
  /// ```dart
  /// if (node.isNull()) {
  ///   print('This node is null');
  /// }
  /// ```
  bool isNull();
}