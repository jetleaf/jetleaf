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
import 'xml_generator.dart';

/// {@template string_xml_generator}
/// Internal [XmlGenerator] implementation that writes XML into a [StringBuffer].
///
/// Manages syntactically correct XML output with proper element nesting,
/// attribute handling, and text escaping.
/// {@endtemplate}
final class StringXmlGenerator implements XmlGenerator {
  final StringBuffer _buffer = StringBuffer();
  final List<String> _elementStack = [];
  final bool pretty;
  final int indentSize;
  int _depth = 0;
  bool _elementOpen = false;

  StringXmlGenerator({this.pretty = false, this.indentSize = 2});

  void _indent() {
    if (pretty) {
      _buffer.write(' ' * (_depth * indentSize));
    }
  }

  void _newline() {
    if (pretty) {
      _buffer.write('\n');
    }
  }

  void _closeOpenElement() {
    if (_elementOpen) {
      _buffer.write('>');
      _elementOpen = false;
    }
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  @override
  void writeStartElement(String name) {
    _closeOpenElement();
    if (_elementStack.isNotEmpty) {
      _newline();
    }
    _indent();
    _buffer.write('<$name');
    _elementStack.add(name);
    _elementOpen = true;
    _depth++;
  }

  @override
  void writeEndElement() {
    if (_elementStack.isEmpty) {
      throw ObjectGeneratorException('No element to close');
    }
    
    final name = _elementStack.removeLast();
    _depth--;
    
    if (_elementOpen) {
      _buffer.write('/>');
      _elementOpen = false;
    } else {
      _newline();
      _indent();
      _buffer.write('</$name>');
    }
  }

  @override
  void writeAttribute(String name, String value) {
    if (!_elementOpen) {
      throw ObjectGeneratorException('Cannot write attribute outside element start');
    }
    _buffer.write(' $name="${_escapeXml(value)}"');
  }

  @override
  void writeString(String text) {
    _closeOpenElement();
    _buffer.write(_escapeXml(text));
  }

  @override
  void writeNull() {
    // XML typically represents null as empty element or omission
    // We'll close the element immediately
    _closeOpenElement();
  }

  @override
  String toString() {
    if (_elementStack.isNotEmpty) {
      throw ObjectGeneratorException('Unclosed XML elements: ${_elementStack.join(", ")}');
    }

    final result = _buffer.toString();
    
    close();

    return result;
  }

  @override
  FutureOr<void> close() {
    _buffer.clear();
    _elementStack.clear();
    _depth = 0;
    _elementOpen = false;
  }
}