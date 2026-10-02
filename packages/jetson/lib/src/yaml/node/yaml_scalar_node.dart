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

/// Implementation of [YamlNode] representing a scalar value.
final class YamlScalarNode implements YamlNode<String> {
  final String _value;
  // ignore: unused_field
  YamlNode? _parent;

  YamlScalarNode(this._value, [this._parent]);

  @override
  YamlNodeType getNodeType() => YamlNodeType.SCALAR;

  @override
  String? getText() => _value;

  @override
  YamlNode? get(String key) => null;

  @override
  List<YamlNode> getAll(String key) => [];

  @override
  List<String> getKeys() => [];

  @override
  List<YamlNode> getElements() => [];

  @override
  String toObject() => _value;
}