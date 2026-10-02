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
import 'yaml_node_type.dart';

/// {@template yaml_node}
/// Represents a **node in a YAML document tree** (DOM-like structure).
///
/// A [YamlNode] provides both **hierarchical navigation** and **direct access**
/// to YAML data, supporting mappings (objects), sequences (arrays), and scalars
/// (values).
///
/// ### Node Types
/// - **Mapping nodes** - Represent YAML key-value mappings (like maps)
/// - **Sequence nodes** - Represent YAML arrays/lists
/// - **Scalar nodes** - Represent simple values (strings, numbers, booleans)
/// - **Alias nodes** - Represent references to anchored values
///
/// ### Navigation
/// ```dart
/// final root = tree.get('users');
/// final firstUser = root.get('[0]');
/// final name = firstUser.get('name').getText();
/// ```
///
/// ### Example
/// ```dart
/// final yaml = '''
/// users:
///   - name: Alice
///     age: 30
///   - name: Bob
///     age: 25
/// ''';
/// final tree = parser.readTree(yaml);
/// final users = tree.get('users');
/// final alice = users.get('[0]');
///
/// print(alice.get('name').getText()); // "Alice"
/// print(alice.get('age').getText()); // "30"
/// ```
/// {@endtemplate}
@Generic(YamlNode)
abstract interface class YamlNode<ObjectType> implements Node<ObjectType> {
  /// Returns the **type** of this YAML node.
  ///
  /// Can be 'mapping', 'sequence', or 'scalar'.
  YamlNodeType getNodeType();

  /// Returns the **scalar value** of this node.
  ///
  /// For SCALAR nodes, returns the parsed value.
  /// For MAPPING or SEQUENCE nodes, may return null.
  String? getText();

  /// Returns the **child node** with the given [key].
  ///
  /// For mappings, [key] is the map key.
  /// For sequences, [key] should be an index like '[0]', '[1]', etc.
  /// Returns `null` if no matching child exists.
  ///
  /// ### Example
  /// ```dart
  /// final name = mapping.get('name');
  /// final first = sequence.get('[0]');
  /// ```
  YamlNode? get(String key);

  /// Returns **all child nodes** with the given [key].
  ///
  /// For sequences, returns all elements.
  /// For mappings, may return values for all matching keys (rarely used).
  /// Returns an empty list if no children match.
  List<YamlNode> getAll(String key);

  /// Returns the **list of all keys** in a mapping node.
  ///
  /// For non-mapping nodes, returns an empty list.
  List<String> getKeys();

  /// Returns the **list of all child nodes** in a sequence.
  ///
  /// For non-sequence nodes, returns an empty list.
  List<YamlNode> getElements();
}