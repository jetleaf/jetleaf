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

/// {@template xml_node}
/// Represents a **node in an XML document tree** (DOM-like structure).
///
/// An [XmlNode] provides both **hierarchical navigation** and **direct access**
/// to XML element data, supporting attributes, text content, and child elements.
///
/// ### Node Types
/// - **Element nodes** - Represent XML elements with attributes and children
/// - **Text nodes** - Contain text content between elements
/// - **Attribute nodes** - Represent XML attributes
/// - **Document nodes** - Represent the root of the XML tree
///
/// ### Navigation
/// ```dart
/// final root = tree.get('users');
/// final firstUser = root.get('user[0]');
/// final name = firstUser.get('name').getText();
/// ```
///
/// ### Example
/// ```dart
/// final xml = '<root><child attr="value">text</child></root>';
/// final tree = parser.readTree(xml);
/// final child = tree.get('child');
///
/// print(child.getText()); // "text"
/// print(child.getAttribute('attr')); // "value"
/// ```
/// {@endtemplate}
@Generic(XmlNode)
abstract interface class XmlNode<ObjectType> implements Node<ObjectType> {
  /// Returns the **name of this element**.
  ///
  /// For element nodes, returns the tag name (e.g., 'user', 'book').
  /// For text nodes, may return null or a special marker.
  String? getName();

  /// Returns the **text content** of this node.
  ///
  /// For TEXT nodes, returns the content directly.
  /// For ELEMENT nodes, returns concatenated text of all children.
  /// For other nodes, may return null.
  String? getText();

  /// Returns the **child element** with the given [name].
  ///
  /// If multiple children have the same name, returns the first one.
  /// Returns `null` if no matching child exists.
  ///
  /// ### Example
  /// ```dart
  /// final user = tree.get('user');
  /// ```
  XmlNode? get(String name);

  /// Returns **all child elements** with the given [name].
  ///
  /// Returns an empty list if no children match.
  ///
  /// ### Example
  /// ```dart
  /// final users = tree.getAll('user');
  /// for (final user in users) {
  ///   print(user.getText());
  /// }
  /// ```
  List<XmlNode> getAll(String name);

  /// Returns the **value of an attribute** by name.
  ///
  /// Returns `null` if the attribute does not exist.
  ///
  /// ### Example
  /// ```dart
  /// final id = element.getAttribute('id');
  /// ```
  String? getAttribute(String name);

  /// Returns **all attributes** of this element as a map.
  ///
  /// For non-element nodes, may return an empty map.
  Map<String, String> getAttributes();

  /// Returns the **list of all child nodes**.
  ///
  /// Includes both element and text nodes.
  List<XmlNode> getChildren();

  /// Returns the **parent node** of this node.
  ///
  /// Returns `null` if this is the root node.
  XmlNode? getParent();
}