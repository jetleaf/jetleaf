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
import 'dart:convert';

import '../../exceptions.dart';
import 'json_generator.dart';

/// {@template string_json_generator}
/// Internal [JsonGenerator] implementation that writes JSON into a [StringBuffer].
///
/// The [StringJsonGenerator] is responsible for emitting valid JSON text
/// as objects, arrays, and primitives are serialized through the
/// Jetleaf serialization pipeline.
///
/// ### Responsibilities
/// - Manage syntactically correct JSON output (commas, nesting, quoting)  
/// - Escape special characters inside JSON strings  
/// - Track structural context using internal stacks  
/// - Prevent trailing commas and malformed JSON output
///
/// ### Example (internal)
/// ```dart
/// final generator = StringJsonGenerator();
/// generator.writeStartObject();
/// generator.writeFieldName('message');
/// generator.writeString('Hello, Jetleaf!');
/// generator.writeEndObject();
///
/// print(generator.toJsonString()); // {"message":"Hello, Jetleaf!"}
/// ```
///
/// ### Notes
/// - Used internally by [ObjectMapper]  
/// - Designed for efficiency and correctness
/// - Thread-safety is not guaranteed (should not be reused across isolates)
///
/// ### See also
/// - [StringJsonParser]
/// - [JsonGenerator]
/// - [ObjectMapper]
/// 
/// {@endtemplate}
final class StringJsonGenerator implements JsonGenerator {
  /// Internal string buffer that accumulates generated JSON text.
  final StringBuffer _buffer = StringBuffer();

  /// Stack tracking nesting context (object or array).
  final List<_JsonContext> _contextStack = [];

  /// Whether to format JSON output with line breaks and indentation.
  final bool pretty;

  /// The number of spaces to use for each indentation level when [pretty] printing is enabled.
  final int indentSize;

  /// The current depth of the JSON structure being written.
  int _depth = 0;

  /// Creates a new [StringJsonGenerator].
  ///
  /// {@macro string_json_generator}
  StringJsonGenerator({this.pretty = false, this.indentSize = 2});

  /// Writes indentation based on current depth (only if pretty printing).
  void _indent() {
    if (pretty) {
      _buffer.write(' ' * (_depth * indentSize));
    }
  }

  /// Writes a newline and indent (only if pretty printing).
  void _newline() {
    if (pretty) {
      _buffer.write('\n');
      _indent();
    }
  }

  /// Gets the current context, or throws if stack is empty.
  _JsonContext _currentContext() {
    if (_contextStack.isEmpty) {
      throw ObjectGeneratorException('No active JSON context');
    }
    return _contextStack.last;
  }

  /// Writes a comma and newline before an element at current depth (for arrays and first values).
  /// Not used for object field names or field values.
  void _writeElementPrefix() {
    final context = _currentContext();

    if (context.elementCount > 0) {
      _buffer.write(',');
      if (pretty) _newline();
    } else {
      if (pretty) _newline();
    }

    context.elementCount++;
  }

  @override
  void writeStartObject() {
    // If we're in an array, write element prefix. If in object, this is a field value
    if (_contextStack.isNotEmpty && !_contextStack.last.isObject) {
      _writeElementPrefix();
    }

    _buffer.write('{');
    _depth++;

    // Push new object context
    _contextStack.add(_JsonContext(isObject: true));
  }

  @override
  void writeEndObject() {
    if (_contextStack.isEmpty || !_contextStack.last.isObject) {
      throw ObjectGeneratorException('writeEndObject() called without matching writeStartObject()');
    }

    _contextStack.removeLast();
    _depth--;

    if (pretty) _newline();
    _buffer.write('}');
  }

  @override
  void writeStartArray() {
    // If we're in an array, write element prefix. If in object, this is a field value
    if (_contextStack.isNotEmpty && !_contextStack.last.isObject) {
      _writeElementPrefix();
    }

    _buffer.write('[');
    _depth++;

    // Push new array context
    _contextStack.add(_JsonContext(isObject: false));
  }

  @override
  void writeEndArray() {
    if (_contextStack.isEmpty || _contextStack.last.isObject) {
      throw ObjectGeneratorException('writeEndArray() called without matching writeStartArray()');
    }

    _contextStack.removeLast();
    _depth--;

    if (pretty) _newline();
    _buffer.write(']');
  }

  @override
  void writeFieldName(String name) {
    final context = _currentContext();

    if (!context.isObject) {
      throw ObjectGeneratorException('writeFieldName() called in array context');
    }

    // Write comma before field name if we've already written fields
    if (context.elementCount > 0) {
      _buffer.write(',');
      if (pretty) _newline();
    } else {
      if (pretty) _newline();
    }

    _buffer.write('"${_escapeString(name)}":');
    if (pretty) _buffer.write(' ');

    context.elementCount++;
  }

  @override
  void writeString(String value) {
    // In object context, this is a field value — don't add element prefix
    // In array context, this is an element — add prefix
    if (_contextStack.isNotEmpty && !_contextStack.last.isObject) {
      _writeElementPrefix();
    }

    _buffer.write('"${_escapeString(value)}"');
  }

  @override
  void writeNumber(num value) {
    // In array context, add element prefix. In object, this is a field value
    if (_contextStack.isNotEmpty && !_contextStack.last.isObject) {
      _writeElementPrefix();
    }

    _buffer.write(value);
  }

  @override
  void writeBoolean(bool value) {
    // In array context, add element prefix. In object, this is a field value
    if (_contextStack.isNotEmpty && !_contextStack.last.isObject) {
      _writeElementPrefix();
    }

    _buffer.write(value);
  }

  @override
  void writeNull() {
    // In array context, add element prefix. In object, this is a field value
    if (_contextStack.isNotEmpty && !_contextStack.last.isObject) {
      _writeElementPrefix();
    }

    _buffer.write('null');
  }

  @override
  void writeRaw(String json) {
    _buffer.write(json);
  }

  /// Escapes special characters in JSON strings per JSON spec.
  String _escapeString(String str) {
    final result = StringBuffer();
    for (final char in str.split('')) {
      switch (char) {
        case '\\':
          result.write('\\\\');
          break;
        case '"':
          result.write('\\"');
          break;
        case '\n':
          result.write('\\n');
          break;
        case '\r':
          result.write('\\r');
          break;
        case '\t':
          result.write('\\t');
          break;
        case '\b':
          result.write('\\b');
          break;
        case '\f':
          result.write('\\f');
          break;
        default:
          result.write(char);
      }
    }
    return result.toString();
  }

  @override
  String toString() {
    if (_contextStack.isNotEmpty) {
      throw ObjectGeneratorException('Incomplete JSON: ${_contextStack.length} unclosed structure(s)');
    }

    final raw = _buffer.toString();

    // Reset for potential reuse
    close();

    return _cleanJson(raw);
  }

  /// Cleans and optionally pretty-prints a JSON string.
  ///
  /// This method attempts to:
  /// 1. Parse the input JSON
  /// 2. Recursively remove empty structures via [_removeEmpty], including:
  ///    - Empty maps (`{}`)
  ///    - Empty lists (`[]`)
  ///    - Null values
  /// 3. Re-serialize the cleaned result
  ///
  /// ### Formatting Behavior
  ///
  /// - If `pretty` is `false`, the output is returned as a compact JSON string.
  /// - If `pretty` is `true`, the output is formatted using the configured
  ///   indentation (`indentSize` spaces).
  ///
  /// ### Fail-Safe Behavior
  ///
  /// If parsing fails for any reason (e.g., malformed JSON), the original
  /// `json` string is returned unchanged. This ensures that the method never
  /// interrupts response rendering.
  ///
  /// ### Example
  /// ```dart
  /// final output = _cleanJson('{"a": null, "b": [], "c": 1}');
  /// // → {"c":1}
  /// ```
  String _cleanJson(String json) {
    try {
      final decoded = jsonDecode(json);
      final cleaned = _removeEmpty(decoded);

      if (!pretty) {
        return jsonEncode(cleaned);
      }

      final encoder = JsonEncoder.withIndent(' ' * indentSize);
      return encoder.convert(cleaned);

    } catch (_) {
      // fail-safe — never break responses
      return json;
    }
  }

  /// Recursively removes empty and null values from JSON-compatible structures.
  ///
  /// This utility processes nested values and returns a cleaned version by:
  ///
  /// - Removing:
  ///   - Empty maps (`{}`)
  ///   - Empty lists (`[]`)
  ///   - Null values
  ///
  /// - Preserving:
  ///   - Non-empty collections
  ///   - Scalar types (e.g., `String`, `num`, `bool`)
  ///
  /// ### Behavior Details
  ///
  /// - When given a `Map`, each entry is processed and only retained if
  ///   the cleaned value is non-empty and non-null.
  ///
  /// - When given a `List`, all items are recursively processed and filtered
  ///   using the same rules.
  ///
  /// - For all other types, the value is returned unchanged.
  ///
  /// ### Example
  /// ```dart
  /// _removeEmpty({"a": {}, "b": [null, {}], "c": 1});
  /// // → {"c": 1}
  /// ```
  dynamic _removeEmpty(dynamic value) {
    if (value is Map) {
      final result = <String, dynamic>{};

      for (final entry in value.entries) {
        final cleaned = _removeEmpty(entry.value);

        final isEmptyMap  = cleaned is Map && cleaned.isEmpty;
        final isEmptyList = cleaned is List && cleaned.isEmpty;

        if (!isEmptyMap && !isEmptyList && cleaned != null) {
          result[entry.key] = cleaned;
        }
      }

      return result;
    }

    if (value is List) {
      return value.map(_removeEmpty).where((v) {
        final isEmptyMap  = v is Map && v.isEmpty;
        final isEmptyList = v is List && v.isEmpty;
        return !isEmptyMap && !isEmptyList && v != null;
      }).toList();
    }

    return value;
  }

  @override
  FutureOr<void> close() {
    _buffer.clear();
    _contextStack.clear();
    _depth = 0;
  }
}

/// Internal context for tracking a JSON object or array.
class _JsonContext {
  /// Whether this context is an object (`true`) or array (`false`).
  final bool isObject;

  /// Number of elements written at this level.
  int elementCount = 0;

  /// Whether any content has been written.
  bool hasContent = false;

  _JsonContext({required this.isObject});
}