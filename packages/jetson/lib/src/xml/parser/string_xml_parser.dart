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

import '../xml_token.dart';
import 'xml_parser.dart';

/// Simple XML parser implementation for parsing XML strings.
final class StringXmlParser implements XmlParser {
  final String _content;
  int _position = 0;
  XmlToken? _currentToken;
  String? _currentElementName;
  String? _currentText;
  Map<String, String> _currentAttributes = {};

  StringXmlParser(this._content);

  @override
  bool nextToken() {
    _skipWhitespace();
    
    if (_position >= _content.length) {
      _currentToken = XmlToken.END_DOCUMENT;
      return false;
    }
    
    if (_content[_position] == '<') {
      if (_position + 1 < _content.length && _content[_position + 1] == '/') {
        // End element
        _position += 2;
        _currentElementName = _readUntil('>');
        _position++;
        _currentToken = XmlToken.END_ELEMENT;
        return true;
      } else if (_position + 3 < _content.length && _content.substring(_position, _position + 4) == '<!--') {
        // Comment
        _position += 4;
        _readUntil('-->');
        _position += 3;
        _currentToken = XmlToken.COMMENT;
        return nextToken(); // Skip comments
      } else {
        // Start element
        _position++;
        final elementWithAttrs = _readUntil('>');
        _position++;
        
        final parts = elementWithAttrs.split(' ');
        _currentElementName = parts[0];
        _currentAttributes = {};
        
        // Parse attributes
        for (int i = 1; i < parts.length; i++) {
          final attrPart = parts[i].trim();
          if (attrPart.contains('=')) {
            final attrParts = attrPart.split('=');
            final attrName = attrParts[0];
            final attrValue = attrParts[1].replaceAll('"', '').replaceAll("'", '');
            _currentAttributes[attrName] = attrValue;
          }
        }
        
        _currentToken = XmlToken.START_ELEMENT;
        return true;
      }
    } else {
      // Text content
      _currentText = _readUntil('<');
      _currentToken = XmlToken.TEXT;
      return true;
    }
  }

  String _readUntil(String delimiter) {
    final start = _position;
    while (_position < _content.length) {
      if (delimiter.length == 1) {
        if (_content[_position] == delimiter) {
          return _content.substring(start, _position);
        }
      } else {
        if (_position + delimiter.length <= _content.length &&
            _content.substring(_position, _position + delimiter.length) == delimiter) {
          return _content.substring(start, _position);
        }
      }
      _position++;
    }
    return _content.substring(start);
  }

  void _skipWhitespace() {
    while (_position < _content.length && _content[_position].trim().isEmpty) {
      _position++;
    }
  }

  @override
  XmlToken? getCurrentToken() => _currentToken;

  @override
  void skip() {
    if (_currentToken == XmlToken.START_ELEMENT) {
      int depth = 1;
      while (depth > 0 && nextToken()) {
        if (_currentToken == XmlToken.START_ELEMENT) {
          depth++;
        } else if (_currentToken == XmlToken.END_ELEMENT) {
          depth--;
        }
      }
    }
  }

  @override
  String? getElementName() => _currentElementName;

  @override
  String? getCurrentValue() => _currentText;

  @override
  Map<String, String> getAttributes() => Map.unmodifiable(_currentAttributes);

  @override
  FutureOr<void> close() {
    _position = 0;
    _currentToken = null;
    _currentElementName = null;
    _currentText = null;
    _currentAttributes = {};
  }
}