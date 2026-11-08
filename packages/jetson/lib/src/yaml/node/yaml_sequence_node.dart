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

import 'yaml_node.dart';
import 'yaml_node_type.dart';

/// Implementation of [YamlNode] representing a YAML sequence (array).
final class YamlSequenceNode implements YamlNode<List<dynamic>> {
  final List<YamlNode> _elements;
  // ignore: unused_field
  YamlNode? _parent;

  YamlSequenceNode(this._elements, [this._parent]);

  @override
  YamlNodeType getNodeType() => YamlNodeType.SEQUENCE;

  @override
  String? getText() => null;

  @override
  YamlNode? get(String key) {
    // Support array indexing via string keys like "[0]"
    if (key.startsWith('[') && key.endsWith(']')) {
      final indexStr = key.substring(1, key.length - 1);
      final index = int.tryParse(indexStr);
      if (index != null && index >= 0 && index < _elements.length) {
        return _elements[index];
      }
    }
    return null;
  }

  @override
  List<YamlNode> getAll(String key) => [];

  @override
  List<String> getKeys() => [];

  @override
  List<YamlNode> getElements() => List.unmodifiable(_elements);

  @override
  List<dynamic> toObject() {
    return _elements.map((e) => e.toObject()).toList();
  }
}