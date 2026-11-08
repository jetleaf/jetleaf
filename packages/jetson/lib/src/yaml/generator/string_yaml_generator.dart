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

import 'dart:async';

import '../../exceptions.dart';
import '../node/yaml_node_type.dart';
import 'yaml_generator.dart';

/// {@template string_yaml_generator}
/// Internal [YamlGenerator] implementation that writes YAML into a [StringBuffer].
///
/// Manages syntactically correct YAML output with proper indentation and structure.
/// {@endtemplate}
final class StringYamlGenerator implements YamlGenerator {
  final StringBuffer _buffer = StringBuffer();
  final List<YamlNodeType> _contextStack = []; // YamlNodeType.MAPPING or YamlNodeType.SEQUENCE
  final int indentSize;
  int _depth = 0;
  bool _expectValue = false;

  StringYamlGenerator({this.indentSize = 2});

  void _indent() {
    _buffer.write(' ' * (_depth * indentSize));
  }

  void _newline() {
    if (_buffer.isNotEmpty) {
      _buffer.write('\n');
    }
  }

  void _writePrefix() {
    if (_contextStack.isNotEmpty && _contextStack.last == YamlNodeType.SEQUENCE) {
      _newline();
      _indent();
      _buffer.write('- ');
    } else if (!_expectValue) {
      _newline();
      _indent();
    } else {
      _buffer.write(' ');
    }
  }

  @override
  void writeStartMapping() {
    _writePrefix();
    _contextStack.add(YamlNodeType.MAPPING);
    _depth++;
    _expectValue = false;
  }

  @override
  void writeEndMapping() {
    if (_contextStack.isEmpty || _contextStack.last != YamlNodeType.MAPPING) {
      throw ObjectGeneratorException('No mapping to close');
    }
    _contextStack.removeLast();
    _depth--;
  }

  @override
  void writeStartSequence() {
    _writePrefix();
    _contextStack.add(YamlNodeType.SEQUENCE);
    _depth++;
    _expectValue = false;
  }

  @override
  void writeEndSequence() {
    if (_contextStack.isEmpty || _contextStack.last != YamlNodeType.SEQUENCE) {
      throw ObjectGeneratorException('No sequence to close');
    }
    _contextStack.removeLast();
    _depth--;
  }

  @override
  void writeKey(String key) {
    if (_contextStack.isEmpty || _contextStack.last != YamlNodeType.MAPPING) {
      throw ObjectGeneratorException('Cannot write key outside mapping');
    }

    _newline();
    _indent();
    _buffer.write('$key:');
    _expectValue = true;
  }

  @override
  void writeString(String value) {
    _writePrefix();
    // Simple quoting logic - can be enhanced
    if (value.contains(':') || value.contains('#') || value.startsWith('-')) {
      _buffer.write('"$value"');
    } else {
      _buffer.write(value);
    }
    _expectValue = false;
  }

  @override
  void writeNumber(num value) {
    _writePrefix();
    _buffer.write(value);
    _expectValue = false;
  }

  @override
  void writeBoolean(bool value) {
    _writePrefix();
    _buffer.write(value);
    _expectValue = false;
  }

  @override
  void writeNull() {
    _writePrefix();
    _buffer.write('null');
    _expectValue = false;
  }

  @override
  String toString() {
    if (_contextStack.isNotEmpty) {
      throw ObjectGeneratorException('Unclosed YAML structures: ${_contextStack.join(", ")}');
    }

    final result = _buffer.toString();

    close();

    return result;
  }

  @override
  FutureOr<void> close() {
    _buffer.clear();
    _contextStack.clear();
    _depth = 0;
    _expectValue = false;
  }
}