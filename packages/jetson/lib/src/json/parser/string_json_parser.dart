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

import 'dart:convert';

import '../json_token.dart';
import '../json_validator.dart';
import 'json_parser.dart';

/// {@template string_json_parser}
/// A **string-based streaming JSON parser** that reads and tokenizes JSON input.
///
/// The [StringJsonParser] is Jetleaf’s default implementation of [JsonParser],
/// designed for parsing JSON from in-memory strings. It decodes the JSON data
/// into Dart objects and iteratively exposes [JsonToken]s for consumption by
/// deserializers.
///
/// ### Purpose
/// - Converts raw JSON strings into token streams  
/// - Provides sequential access to JSON fields, values, and structures  
/// - Supports nested arrays and objects via an internal stack
///
/// ### Example
/// ```dart
/// final parser = StringJsonParser('{"name": "Alice", "age": 30}');
///
/// while (parser.nextToken()) {
///   print('${parser.getCurrentToken()}: ${parser.getCurrentValue()}');
/// }
///
/// await parser.close();
/// ```
///
/// ### Notes
/// - Supports both object (`{}`) and array (`[]`) structures  
/// - Recursively traverses nested values using an internal [_ParserState] stack  
/// - Automatically decodes primitive types (`String`, `num`, `bool`, `null`)  
/// - Once closed, the parser cannot be reused  
///
/// ### See also
/// - [JsonParser]
/// - [JsonToken]
/// - [ObjectMapper]
/// - [JsonDeserializer]
/// {@endtemplate}
final class StringJsonParser implements JsonParser {
  /// The parsed JSON data (decoded from input string).
  late final dynamic _data;

  /// The stack of parser states for nested object/array traversal.
  final List<_ParserState> _stack = [];

  /// The currently active parsing state.
  _ParserState? _currentState;

  /// Whether the parser has been closed.
  bool _closed = false;

  /// Creates a new [StringJsonParser] from a JSON string.
  ///
  /// {@macro string_json_parser}
  StringJsonParser(String json) {
    JsonValidator.validateJsonString(json);
    _data = jsonDecode(json);
    
    // Initialize parser with a root state but don't emit its START token
    // until the first nextToken() call. This allows callers that expect
    // to see START_OBJECT/START_ARRAY as the current token after moving
    // the parser forward once.
    _currentState = _ParserState.fromValue(_data);
  }

  @override
  bool nextToken() {
    if (_closed || _currentState == null) return false;

    final state = _currentState!;

    // Advance the current state. If it returns true we have a new token
    // available. If it returns false it means this state has finished
    // emitting tokens (i.e. reached END_OBJECT/END_ARRAY) and we should
    // pop back to the parent state if any.
    if (state.advance()) {
      // If the current token is a START_OBJECT or START_ARRAY and the
      // associated currentValue is a Map/List, push a new frame so nested
      // traversal begins inside that value on the next call.
      final token = state.currentToken;
      final val = state.currentValue;

      if ((token == JsonToken.START_OBJECT && val is Map) ||
          (token == JsonToken.START_ARRAY && val is List)) {
        // Push parent state to stack and enter child. Then step into the
        // child so the first token inside it (START_OBJECT/START_ARRAY)
        // is emitted by this call.
        _stack.add(state);
        _currentState = _ParserState.fromValue(val);
        return nextToken();
      }

      return true;
    }

    // If the state finished (returned false), emit the END token for that
    // state and then restore the parent state if available. The parent
    // should continue from the position after the child value.
    if (_stack.isNotEmpty) {
      final parent = _stack.removeLast();
      // Parent's advance() previously advanced to the child value. We need
      // to ensure the parent is positioned after the child; calling
      // parent.advance() will move it forward. Set current state to parent
      // and call nextToken recursively to produce the next appropriate token
      // (which may be END_OBJECT/END_ARRAY or next field).
      _currentState = parent;
      return nextToken();
    }

    return false;
  }

  @override
  JsonToken? getCurrentToken() => _currentState?.currentToken;

  @override
  String? getCurrentName() => _currentState?.currentName;

  @override
  Object? getCurrentValue() => _currentState?.currentValue;

  @override
  void skip() {
    if (_currentState == null) return;
    
    final token = getCurrentToken();
    if (token == JsonToken.START_OBJECT || token == JsonToken.START_ARRAY) {
      _currentState!.skipToEnd();
    }
  }

  @override
  Future<void> close() async {
    _closed = true;
    _stack.clear();
    _currentState = null;
  }
}

/// Internal state representing a single parsing frame in [StringJsonParser].
///
/// Each [_ParserState] instance maintains contextual information about
/// a JSON value — including its type, current token, and iteration progress.
///
/// ### Responsibilities
/// - Tracks traversal position within objects or arrays  
/// - Determines token type based on the current JSON value  
/// - Supports skipping and sequential token advancement  
///
/// ### Example (internal)
/// ```dart
/// final state = _ParserState.fromValue({'key': 42});
/// while (state.advance()) {
///   print('${state.currentToken}: ${state.currentValue}');
/// }
/// // Prints FIELD_NAME then VALUE_NUMBER
/// ```
///
/// ### Notes
/// - Used exclusively by [StringJsonParser]  
/// - Not part of Jetleaf’s public API  
/// - Handles token emission for nested structures  
///
/// ### See also
/// - [StringJsonParser]
/// - [JsonToken]
class _ParserState {
  /// The current JSON value associated with this parser frame.
  final dynamic value;

  /// The current token type emitted by this state.
  JsonToken? currentToken;

  /// The current field name (for object traversal).
  String? currentName;

  /// The current token's value.
  Object? currentValue;

  /// Internal traversal position counter.
  int _position = -1;

  /// Cached keys for object traversal.
  List<dynamic>? _keys;

  /// Creates a new [_ParserState] for the given [value].
  _ParserState(this.value);

  /// Factory constructor that initializes state based on [value] type.
  factory _ParserState.fromValue(dynamic value) {
    final state = _ParserState(value);
    state._initialize();
    return state;
  }

  /// Initializes the current token based on [value] type.
  void _initialize() {
    // Do not emit any token at initialization. The first token for this
    // state will be produced on the first call to `advance()`.
    _position = -1;
    if (value is Map) {
      _keys = (value as Map).keys.toList();
    }
    // For non-container values we still keep the raw value available; the
    // token for it will be emitted when advance() is called.
  }

  /// Advances the parser to the next token within the current structure.
  ///
  /// Returns `true` if a new token is available, or `false` if this structure
  /// has been fully traversed.
  bool advance() {
    if (value is Map) {
      return _advanceObject();
    } else if (value is List) {
      return _advanceArray();
    }

    return _advanceValue();
  }

  /// Advances iteration over a JSON object (`{}`).
  bool _advanceObject() {
    final map = value as Map;

    // First call should emit START_OBJECT
    if (_position == -1) {
      currentToken = JsonToken.START_OBJECT;
      currentValue = null;
      _position = 0;
      return true;
    }

    // Emit fields and values. We use positions: even -> FIELD_NAME, odd -> value
    if (_position < (_keys!.length * 2)) {
      final keyIndex = _position ~/ 2;
      final isKey = _position % 2 == 0;

      if (isKey) {
        currentName = _keys![keyIndex].toString();
        currentToken = JsonToken.FIELD_NAME;
        currentValue = currentName;
      } else {
        final key = _keys![keyIndex];
        currentValue = map[key];
        currentToken = _tokenForValue(currentValue);
      }

      _position++;
      return true;
    }

    // Emit END_OBJECT exactly once after all fields
    if (_position == (_keys!.length * 2)) {
      currentToken = JsonToken.END_OBJECT;
      currentValue = null;
      _position++;
      return true;
    }

    // All tokens consumed
    return false;
  }

  /// Advances iteration over a JSON array (`[]`).
  bool _advanceArray() {
    final list = value as List;

    // First call: START_ARRAY
    if (_position == -1) {
      currentToken = JsonToken.START_ARRAY;
      currentValue = null;
      _position = 0;
      return true;
    }

    if (_position < list.length) {
      currentValue = list[_position];
      currentToken = _tokenForValue(currentValue);
      _position++;
      return true;
    }

    if (_position == list.length) {
      currentToken = JsonToken.END_ARRAY;
      currentValue = null;
      _position++;
      return true;
    }

    return false;
  }

  /// Skips remaining tokens within the current object or array.
  void skipToEnd() {
    if (value is Map) {
      _position = (_keys!.length * 2) + 1; // move past END
      currentToken = JsonToken.END_OBJECT;
    } else if (value is List) {
      _position = (value as List).length + 1;
      currentToken = JsonToken.END_ARRAY;
    } else {
      // primitive: mark as consumed
      _position = 1;
      currentToken = _tokenForValue(value);
      currentValue = value;
    }
  }

  /// Determines the [JsonToken] type for the given [val].
  JsonToken _tokenForValue(dynamic val) {
    if (val == null) return JsonToken.VALUE_NULL;
    if (val is String) return JsonToken.VALUE_STRING;
    if (val is num) return JsonToken.VALUE_NUMBER;
    if (val is bool) return JsonToken.VALUE_BOOLEAN;
    if (val is Map) return JsonToken.START_OBJECT;
    if (val is List) return JsonToken.START_ARRAY;
    return JsonToken.VALUE_NULL;
  }

  bool _advanceValue() {
    // For primitive (non-container) values, emit the value once.
    if (_position == -1) {
      currentToken = _tokenForValue(value);
      currentValue = value;
      _position = 0;
      return true;
    }

    return false;
  }
}