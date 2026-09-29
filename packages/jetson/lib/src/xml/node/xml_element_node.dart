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

// ignore_for_file: prefer_final_fields

import 'package:jetleaf_lang/lang.dart';

import 'xml_node.dart';

/// Implementation of [XmlNode] representing an XML element.
final class XmlElementNode implements XmlNode<Map<String, dynamic>> {
  final String _name;
  final Map<String, String> _attributes;
  final List<XmlNode> _children;
  XmlNode? _parent;

  XmlElementNode(this._name, this._attributes, this._children, [this._parent]);

  @override
  String? getName() => _name;

  @override
  String? getText() {
    final textNodes = _children.whereType<XmlNode>().where((n) => n.getText() != null);
    return textNodes.map((n) => n.getText()).join('');
  }

  @override
  XmlNode? get(String name) {
    return _children.find((child) => child.getName() == name);
  }

  @override
  List<XmlNode> getAll(String name) {
    return _children.where((child) => child.getName() == name).toList();
  }

  @override
  String? getAttribute(String name) => _attributes[name];

  @override
  Map<String, String> getAttributes() => Map.unmodifiable(_attributes);

  @override
  List<XmlNode> getChildren() => List.unmodifiable(_children);

  @override
  XmlNode? getParent() => _parent;

  @override
  Map<String, dynamic> toObject() {
    final result = <String, dynamic>{};
    
    if (_attributes.isNotEmpty) {
      result['@attributes'] = _attributes;
    }
    
    if (_children.isEmpty) {
      return result;
    }
    
    final textContent = getText();
    if (_children.length == 1 && textContent != null && textContent.isNotEmpty) {
      result['#text'] = textContent;
    } else {
      for (final child in _children) {
        final childName = child.getName();
        if (childName != null) {
          final childObj = child.toObject();
          if (result.containsKey(childName)) {
            if (result[childName] is List) {
              (result[childName] as List).add(childObj);
            } else {
              result[childName] = [result[childName], childObj];
            }
          } else {
            result[childName] = childObj;
          }
        }
      }
    }
    
    return result;
  }
}