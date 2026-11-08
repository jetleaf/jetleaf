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

/// {@template yaml_position}
/// Represents an exact position in the YAML source text.
///
/// A `YamlPosition` stores a 0-based line and column index and is used
/// throughout the parser and scanner to provide accurate error messages
/// and debugging information.
/// 
/// {@endtemplate}
class YamlPosition {
  /// The 0-based line number in the source.
  final int line;

  /// The 0-based column number in the source.
  final int column;

  /// Creates a new [YamlPosition] with the given [line] and [column].
  /// 
  /// {@macro yaml_position}
  const YamlPosition({required this.line, required this.column});

  @override
  String toString() => 'line ${line + 1}, column ${column + 1}';
}

/// {@template yaml_scanner}
/// A forward-only scanner that provides character-by-character access
/// to the YAML input string.
///
/// The scanner maintains:
/// - the current absolute position,
/// - the current line and column numbers,
/// - a stack for saving and restoring positions (for lookahead).
///
/// It is intentionally minimal and leaves higher-level parsing logic to
/// `StringYamlParser`.
/// 
/// {@endtemplate}
class YamlScanner {
  /// The raw YAML input.
  final String _input;

  /// Current absolute offset in the input (0-based).
  int _position = 0;

  /// Current 0-based line number.
  int _line = 0;

  /// Current 0-based column number.
  int _column = 0;

  /// Internal stack used for lookahead (`pushPosition` / `popPosition`).
  final List<int> _positionStack = [];

  /// Creates a new scanner for the given YAML [_input].
  /// 
  /// {@macro yaml_scanner}
  YamlScanner(this._input);

  /// Returns `true` if the scanner has reached the end of the input.
  bool get isDone => _position >= _input.length;

  /// The current absolute character position in the input.
  int get position => _position;

  /// The current 0-based line index.
  int get line => _line;

  /// The current 0-based column index.
  int get column => _column;

  /// Peeks at the character at the given [offset] from the current position
  /// without consuming it.
  ///
  /// Returns an empty string if the offset points past the end of the input.
  String peekChar([int offset = 0]) {
    final pos = _position + offset;
    return pos < _input.length ? _input[pos] : '';
  }
  
  /// Peeks at the next [count] characters without consuming them.
  /// Returns a string that may be shorter than [count] if near the end of input.
  String peekChars(int count) {
    final end = _position + count;
    return _position < _input.length 
        ? _input.substring(_position, end < _input.length ? end : _input.length)
        : '';
  }
  
  /// Consumes and returns the next character.
  /// Returns the empty string if at the end of input.
  String readChar() {
    if (isDone) return '';
    
    final ch = _input[_position++];
    
    if (ch == '\n') {
      _line++;
      _column = 0;
    } else {
      _column++;
    }
    
    return ch;
  }

  /// Sets the scanner's absolute character position and recalculates
  /// the line/column counters.
  ///
  /// Throws [RangeError] if [newPosition] falls outside the input bounds.
  set position(int newPosition) {
    if (newPosition < 0 || newPosition > _input.length) {
      throw RangeError('Position $newPosition is out of range (0-${_input.length})');
    }
    
    // Reset line and column tracking
    _position = newPosition;
    _line = 0;
    _column = 0;
    
    // Recalculate line and column
    for (int i = 0; i < _position; i++) {
      if (_input[i] == '\n') {
        _line++;
        _column = 0;
      } else {
        _column++;
      }
    }
  }
  
  /// Consumes and returns the next [count] characters.
  /// Returns a string that may be shorter than [count] if near the end of input.
  String readChars(int count) {
    final buffer = StringBuffer();
    for (var i = 0; i < count && !isDone; i++) {
      buffer.write(readChar());
    }
    return buffer.toString();
  }
  
  /// Consumes and returns all characters until the end of the current line.
  String readLine() {
    if (isDone) return '';
    
    final buffer = StringBuffer();
    while (!isDone) {
      final ch = readChar();
      if (ch == '\n') break;
      buffer.write(ch);
    }
    return buffer.toString();
  }
  
  /// Advances the scanner by [count] characters.
  void advance([int count = 1]) {
    for (var i = 0; i < count && !isDone; i++) {
      readChar();
    }
  }
  
  /// Saves the current position for later restoration.
  void pushPosition() {
    _positionStack.add(_position);
    _positionStack.add(_line);
    _positionStack.add(_column);
  }
  
  /// Restores the previously saved position.
  void popPosition() {
    _column = _positionStack.removeLast();
    _line = _positionStack.removeLast();
    _position = _positionStack.removeLast();
  }
  
  /// Discards the most recently saved position.
  void discardPosition() {
    _positionStack.length -= 3; // Remove line, column, and position
  }
  
  /// Skips whitespace characters (spaces and tabs).
  void skipWhitespace() {
    while (!isDone) {
      final ch = peekChar();
      if (ch != ' ' && ch != '\t') break;
      advance();
    }
  }
  
  /// Skips whitespace and comments until the next non-whitespace, non-comment character.
  void skipWhitespaceAndComments() {
    while (true) {
      skipWhitespace();
      
      // Skip comments
      if (peekChar() == '#') {
        skipToEndOfLine();
      } else {
        break;
      }
    }
  }
  
  /// Skips to the end of the current line.
  void skipToEndOfLine() {
    while (!isDone) {
      if (readChar() == '\n') break;
    }
  }
  
  /// Closes the scanner and releases any resources.
  void close() {
    // No resources to release in this implementation
  }
  
  /// Returns the current position as a [YamlPosition] object.
  YamlPosition getCurrentPosition() => YamlPosition(line: _line, column: _column);
}

/// Extension methods for string manipulation.
extension StringExtensions on String {
  /// Returns true if the string is a valid YAML tag handle.
  bool get isYamlTagHandle {
    if (isEmpty) return false;
    
    // Tag handles must start with '!' and not contain whitespace or flow indicators
    if (this[0] != '!') return false;
    
    for (var i = 1; i < length; i++) {
      final ch = this[i];
      if (ch.codeUnitAt(0) <= 0x20 || 
          ch == '[' || ch == ']' || ch == '{' || ch == '}' || 
          ch == ',') {
        return false;
      }
    }
    
    return true;
  }
  
  /// Returns true if the string is a valid YAML anchor or alias name.
  bool get isYamlAnchorName {
    if (isEmpty) return false;
    
    // Anchor names must not contain whitespace or flow indicators
    for (var i = 0; i < length; i++) {
      final ch = this[i];
      if (ch.codeUnitAt(0) <= 0x20 || 
          ch == '[' || ch == ']' || ch == '{' || ch == '}' || 
          ch == ',' || ch == ':' || ch == '#' || ch == '*' || 
          ch == '&' || ch == '!' || ch == '|' || ch == '>' || 
          ch == '`' || ch == '\\' || ch == '"' || ch == '\'') {
        return false;
      }
    }
    
    return true;
  }
}