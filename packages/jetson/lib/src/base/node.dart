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

/// {@template jetleaf_node}
/// Generic interface representing a parsed **node** in Jetleaf's structured
/// data model (JSON/YAML/other).  
///
/// `Node<ObjectType>` is the canonical abstraction for any parsed value and
/// intentionally maps to a native Dart type via [toObject].
///
/// This interface is designed for:
/// - Providing a uniform API across different node kinds (object, array,
///   string, number, boolean, null)  
/// - Allowing generated or runtime parsers to expose parsed content without
///   forcing callers to depend on parser internals  
/// - Enabling conversions to standard Dart collections and primitives
///
/// ### Usage Example
/// ```dart
/// // When deserializing:
/// final Node<Map<String, Object?>> root = await parser.parse();
/// final Map<String, Object?> map = root.toObject();
///
/// // Working with arrays:
/// final Node<List<Object?>> arr = someNode as Node<List<Object?>>;
/// final list = arr.toObject();
/// ```
///
/// ### Design Notes
/// - `ObjectType` is the concrete Dart type produced by [toObject]. Implementors
///   should guarantee the returned value conforms to that type.  
/// - Conversions are typically **recursive**: nested nodes become nested Dart
///   collections (maps / lists).  
/// - The interface is intentionally minimal to keep node implementations small
///   and easily generated for codegen use-cases.  
/// - Prefer returning nullable element types in collections (`Object?`) to
///   reflect possible `null` values in parsed data.
///
/// ### Example Mapping
/// | Node Kind | `toObject()` result type |
/// |-----------|--------------------------|
/// | Object    | `Map<String, Object?>`   |
/// | Array     | `List<Object?>`          |
/// | String    | `String`                 |
/// | Number    | `num`                    |
/// | Boolean   | `bool`                   |
/// | Null      | `null`                   |
///
/// ### See Also
/// - [Parser] — streaming token parser that produces nodes  
/// - `NodeMap`, `NodeArray`, `NodeString` — typical node implementations  
/// - Jetleaf serialization/deserialization utilities
/// {@endtemplate}
@Generic(Node)
abstract interface class Node<ObjectType> {
  /// {@macro jetleaf_node}
  ///
  /// Converts the parsed node into a **native Dart object**.
  ///
  /// The returned object matches the parsed type:
  /// - parsed object → `Map<String, Object?>`  
  /// - parsed array → `List<Object?>`  
  /// - parsed string → `String`  
  /// - parsed number → `num`  
  /// - parsed boolean → `bool`  
  /// - parsed null → `null`
  ///
  /// Use this method to work with standard Dart collections instead of
  /// custom node types.
  ///
  /// ### Example
  /// ```dart
  /// final map = node.toObject() as Map<String, Object?>;
  /// print(map['name']); // prints the value of the 'name' field
  /// ```
  ObjectType toObject();
}