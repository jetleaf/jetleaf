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

import 'json_node.dart';

/// {@template jetleaf_json_null_node}
/// Represents a **JSON null node** (`null`) in the Dart JSON model.
///
/// This node indicates the absence of a value and behaves consistently
/// with [JsonNode] type-checking methods.
///
/// ### Usage Example
/// ```dart
/// final nullNode = JsonNullNode();
///
/// if (nullNode.isNull()) {
///   print(nullNode.toObject()); // null
/// }
/// ```
///
/// ### Behavior Overview
/// | Dart JSON Value | Internal Representation | Description |
/// |-----------------|------------------------|-------------|
/// | `null` | `JsonNullNode()` | Represents a null value |
///
/// ### Design Notes
/// - This class is immutable and uses a `const` constructor.
/// - [toObject] returns Dart `null`.
/// - Type-checking is consistent with [JsonNode] interface.
/// {@endtemplate}
class JsonNullNode implements JsonNode<Object> {
  /// {@macro jetleaf_json_null_node}
  ///
  /// Creates a new [JsonNullNode] representing JSON `null`.
  const JsonNullNode();

  @override
  bool isObject() => false;

  @override
  bool isArray() => false;

  @override
  bool isTextual() => false;

  @override
  bool isNumber() => false;

  @override
  bool isBoolean() => false;

  @override
  bool isNull() => true;

  @override
  Object toObject() => Null();
}