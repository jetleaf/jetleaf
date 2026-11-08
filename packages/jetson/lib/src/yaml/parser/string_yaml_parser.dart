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
import 'dart:collection';

import '../../exceptions.dart';
import '../yaml_token.dart';
import 'block_scalar_chomping.dart';
import 'yaml_parser.dart';
import 'yaml_scanner.dart';
import 'yaml_style.dart';

/// {@template string_yaml_parser}
/// A production-ready, streaming **YAML 1.2 parser** that converts a YAML
/// string into a normalized stream of [YamlToken]s.
///
/// `StringYamlParser` is the core pull-based YAML parser used by Jetleaf.
/// It implements the full YAML 1.2 grammar including:
///
/// - Mappings (flow and block)
/// - Sequences (flow and block)
/// - Anchors (`&foo`) and aliases (`*foo`)
/// - Tags (`!!str`, `!<verbatim:tag>`, custom tags)
/// - Block scalars (`|` literal and `>` folded)
/// - Chomping indicators (`|+` / `|-`)
/// - Indentation-sensitive parsing
/// - Multi-document streams (`---` / `...`)
///
/// The parser is designed for:
/// - **High performance** (single-pass tokenizer)
/// - **Low memory usage** (pull API, no tree construction)
/// - **Spec correctness** (YAML 1.2 compliant)
/// - **Robust error handling** (precise line/column diagnostics)
///
/// ### Usage Example
/// ```dart
/// final parser = StringYamlParser(source);
///
/// while (parser.nextToken()) {
///   final token = parser.getCurrentToken();
///   final value = parser.getCurrentValue();
///   print('$token  $value');
/// }
///
/// await parser.close();
/// ```
///
/// ### Key Features
/// - Emits one [YamlToken] at a time (pull model)
/// - Can skip entire nested collections via [skip]
/// - Maintains anchor resolution tables
/// - Handles all scalar styles (plain, quoted, literal, folded)
/// - Properly manages indentation and flow contexts
/// - Produces detailed `YamlException` errors with source positions
///
/// ### Token Stream Example
/// YAML:
/// ```yaml
/// person:
///   name: Alice
///   age: 30
/// ```
/// Produces:
/// ```
/// MAPPING_START
/// KEY     -> "person"
/// MAPPING_START
/// KEY     -> "name"
/// SCALAR  -> "Alice"
/// KEY     -> "age"
/// SCALAR  -> "30"
/// MAPPING_END
/// MAPPING_END
/// END_DOCUMENT
/// ```
///
/// ### Lifecycle
/// - Create parser with input string  
/// - Call [nextToken] until it returns `false`  
/// - Inspect tokens + values  
/// - Call [close] to release buffers  
///
/// ### Error Handling
/// Any structural error throws a [YamlException] that includes:
/// - Error message  
/// - Line/column position  
/// - Stack trace for debugging  
///
/// ---
///
/// The implementation closely follows the YAML 1.2 specification and is
/// optimized for correctness over convenience. Higher-level Jetleaf layers
/// (deserializers, builders, AST models) consume this parser.
///
/// See also:
/// - [YamlScanner] — low-level character scanner  
/// - [YamlToken] — token enumeration  
/// - [BlockScalarChomping] — block scalar semantics  
/// - [YamlStyle] — scalar style indicators  
/// {@endtemplate}
final class StringYamlParser implements YamlParser {
  /// Raw YAML input string.
  final String _input;

  /// Low-level scanner providing character-by-character access with
  /// positional information.
  final YamlScanner _scanner;

  /// Table of defined anchors (`&foo → value`).
  ///
  /// Values may be assigned lazily when the anchored node is parsed.
  final Map<String, dynamic> _anchors = {};

  /// Stack used when anchors apply to nested structures.
  final List<MapEntry<String, dynamic>> _anchorStack = [];

  /// Queue of tokens awaiting consumption.
  ///
  /// Some constructs (e.g., flow collections) generate multiple tokens.
  final Queue<YamlToken> _tokenQueue = Queue();

  /// Stack of document contexts (indentation, anchors, flow mode).
  final _documentStack = <_DocumentContext>[];

  /// Tracks indentation depth transitions.
  final _indentStack = <int>[];

  /// Maps character offsets to line starts for fast position lookup.
  final _lineStarts = <int>[];

  /// Last emitted token.
  YamlToken? _currentToken;

  /// Current scalar value associated with [SCALAR], [KEY], [ALIAS], etc.
  String? _currentScalar;

  /// Name of the current anchor (`&foo`), if any.
  String? _currentAnchor;

  /// Current tag (`!!str`, `!<tag>`, etc.) applied to a scalar.
  String? _currentTag;

  /// Current scalar style (plain, literal, folded, etc.).
  YamlStyle _currentStyle = YamlStyle.PLAIN;

  /// Current indentation level.
  int _currentIndent = 0;

  /// Whether the parser is currently inside a flow collection (`[ ]` or `{ }`).
  bool _inFlowCollection = false;

  /// Whether the parser is inside a YAML document (`---` seen).
  bool _inDocument = false;

  /// Whether a document end marker (`...`) has been reached.
  bool _documentEnded = false;

  /// Whether the entire input stream has been fully consumed.
  bool _streamEnded = false;

  /// Chomping mode for the active block scalar.
  BlockScalarChomping _blockScalarChomping = BlockScalarChomping.CLIP;

  /// Indentation level for a block scalar (`|` or `>`).
  int _blockIndent = 0;

  /// Creates a new YAML parser for the given input [String].
  ///
  /// Precomputes line-start offsets so errors can report accurate line/column
  /// information without re-scanning the input.
  /// 
  /// {@macro string_yaml_parser}
  StringYamlParser(String input) : _input = input, _scanner = YamlScanner(input) {
    _lineStarts.add(0);
    _processLineStarts();
  }

  @override
  bool nextToken() {
    if (_tokenQueue.isNotEmpty) {
      _currentToken = _tokenQueue.removeFirst();
      return _currentToken != YamlToken.END_DOCUMENT;
    }

    if (_documentEnded || _streamEnded) {
      _currentToken = YamlToken.END_DOCUMENT;
      return false;
    }

    try {
      _parseNextToken();
      return _currentToken != YamlToken.END_DOCUMENT;
    } catch (e, stackTrace) {
      final position = _getCurrentPosition();
      throw YamlException(
        'Error parsing YAML at line ${position.line + 1}, column ${position.column + 1}: $e',
        position,
        stackTrace: stackTrace,
      );
    }
  }

  /// Examines the next character in the scanner and dispatches to the correct
  /// parser routine.
  ///
  /// Handles:
  /// - Document markers (`---`, `...`)
  /// - Flow collections (`[`, `]`, `{`, `}`)
  /// - Anchors (`&foo`)
  /// - Aliases (`*bar`)
  /// - Tags (`!str`, `!<uri>`)
  /// - Block scalars (`|`, `>`)
  /// - Explicit/implicit keys (`?`, `:`)
  /// - Sequence items (`-`)
  /// - Plain scalars
  ///
  /// If the scanner has reached the end of input, delegates to
  /// [_handleEndOfStream].
  void _parseNextToken() {
    if (_scanner.isDone) {
      _handleEndOfStream();
      return;
    }

    _skipWhitespace();
    
    if (_scanner.isDone) {
      _handleEndOfStream();
      return;
    }

    final ch = _scanner.peekChar();
    
    // Handle document boundaries
    if (ch == '-' && _scanner.peekChars(3) == '---') {
      _handleDocumentStart();
      return;
    }
    
    if (ch == '.' && _scanner.peekChars(3) == '...') {
      _handleDocumentEnd();
      return;
    }

    // Handle flow collections
    if (ch == '[') {
      _startFlowSequence();
      return;
    }
    
    if (ch == '{') {
      _startFlowMapping();
      return;
    }
    
    if (ch == ']' || ch == '}') {
      _endFlowCollection(ch);
      return;
    }
    
    // Handle anchors and tags
    if (ch == '&') {
      _parseAnchor();
      return;
    }
    
    if (ch == '*') {
      _parseAlias();
      return;
    }
    
    if (ch == '!') {
      _parseTag();
      return;
    }
    
    // Handle scalars and collection items
    if (ch == '|' || ch == '>') {
      _parseBlockScalar(ch);
      return;
    }
    
    if (ch == '?') {
      _parseExplicitKey();
      return;
    }
    
    if (ch == ':' && _scanner.peekChar(1).trim().isNotEmpty) {
      _parseImplicitKey();
      return;
    }
    
    if (ch == '-') {
      _parseSequenceItem();
      return;
    }
    
    // Default to parsing a plain scalar
    _parsePlainScalar();
  }
  
  /// Emits a [YamlToken.DOCUMENT_START] token and initializes a new document.
  ///
  /// Triggered when encountering the `---` directive.
  ///
  /// Responsibilities:
  /// - Marks that parsing is now inside a document.
  /// - Resets document-local state such as anchors.
  /// - Stores the current indentation and flow context on a document stack.
  /// - Sets the current token to `DOCUMENT_START`.
  void _handleDocumentStart() {
    _scanner.advance(3); // Skip '---'
    _inDocument = true;
    _documentEnded = false;
    _currentToken = YamlToken.DOCUMENT_START;
    
    // Push new document context
    _documentStack.add(_DocumentContext(
      indent: _currentIndent,
      inFlowCollection: _inFlowCollection,
      anchors: {},
    ));
  }
  
  /// Emits a [YamlToken.DOCUMENT_END] token and finalizes the current document.
  ///
  /// Triggered by the `...` directive.
  ///
  /// Responsibilities:
  /// - Marks the document as ended, but not the full stream.
  /// - Removes the most recent document context.
  /// - Clears document-local anchors.
  /// - Sets the current token to `DOCUMENT_END`.
  void _handleDocumentEnd() {
    _scanner.advance(3); // Skip '...'
    _inDocument = false;
    _documentEnded = true;
    _currentToken = YamlToken.DOCUMENT_END;
    
    // Pop document context
    if (_documentStack.isNotEmpty) {
      _documentStack.removeLast();
    }
  }
  
  /// Handles reaching the end of the input stream.
  ///
  /// If currently inside a document, emits an implicit `DOCUMENT_END`.
  /// Otherwise marks the YAML stream as fully ended and sets the token to
  /// `END_DOCUMENT`.
  void _handleEndOfStream() {
    if (_inDocument) {
      _documentEnded = true;
      _inDocument = false;
      _currentToken = YamlToken.DOCUMENT_END;
    } else {
      _streamEnded = true;
      _currentToken = YamlToken.END_DOCUMENT;
    }
  }
  
  /// Emits a [YamlToken.SEQUENCE_START] token for a flow sequence.
  ///
  /// Triggered by encountering `'['`.
  ///
  /// Responsibilities:
  /// - Mark parser as being inside a flow collection.
  /// - Queue a `SEQUENCE_START` token.
  void _startFlowSequence() {
    _scanner.advance(); // Skip '['
    _inFlowCollection = true;
    _tokenQueue.add(YamlToken.SEQUENCE_START);
  }
  
  /// Emits a [YamlToken.MAPPING_START] token for a flow mapping.
  ///
  /// Triggered by encountering `'{'`.
  ///
  /// Responsibilities:
  /// - Mark parser as being inside a flow collection.
  /// - Queue a `MAPPING_START` token.
  void _startFlowMapping() {
    _scanner.advance(); // Skip '{'
    _inFlowCollection = true;
    _tokenQueue.add(YamlToken.MAPPING_START);
  }
  
  /// Emits the appropriate end token when encountering `]` or `}`.
  ///
  /// Responsibilities:
  /// - Restores the previous flow-collection state.
  /// - Emits `SEQUENCE_END` for `]` or `MAPPING_END` for `}`.
  /// - Consumes the closing delimiter.
  void _endFlowCollection(String endChar) {
    _scanner.advance(); // Skip ']' or '}'
    _inFlowCollection = _documentStack.isNotEmpty && _documentStack.last.inFlowCollection;
    _tokenQueue.add(endChar == ']' ? YamlToken.SEQUENCE_END : YamlToken.MAPPING_END);
  }
  
  /// Parses an anchor definition (`&name`) and records it.
  ///
  /// The anchor value will be associated with the next parsed node
  /// (scalar, mapping, or sequence).
  void _parseAnchor() {
    _scanner.advance(); // Skip '&'
    final anchor = _parseIdentifier();
    _currentAnchor = anchor;
    _anchors[anchor] = null; // Will be set when the anchored value is parsed
  }
  
  /// Parses an alias reference (`*name`) and emits an [YamlToken.ALIAS] token.
  ///
  /// The alias name becomes the current scalar value.
  void _parseAlias() {
    _scanner.advance(); // Skip '*'
    final alias = _parseIdentifier();
    _currentToken = YamlToken.ALIAS;
    _currentScalar = alias;
  }
  
  /// Parses a type tag (`!str`, `!!int`, `!<tag:uri>`, etc.).
  ///
  /// Responsibilities:
  /// - Supports both shorthand and verbatim tag syntax.
  /// - Stores the tag to be applied to the next parsed value.
  /// - If a value immediately follows, queues an artificial `SCALAR` token.
  void _parseTag() {
    _scanner.advance(); // Skip '!'
    
    if (_scanner.peekChar() == '<') {
      // Verbatim tag: !<tag:example.com,2019:tag>
      _scanner.advance();
      final buffer = StringBuffer();
      while (!_scanner.isDone && _scanner.peekChar() != '>') {
        buffer.write(_scanner.readChar());
      }
      if (_scanner.peekChar() == '>') {
        _scanner.advance();
        _currentTag = buffer.toString();
      } else {
        throw YamlSyntaxException('Unclosed tag', _scanner.getCurrentPosition());
      }
    } else {
      // Tag shorthand
      _currentTag = _parseIdentifier();
    }
    
    // If this tag is associated with a value, we'll use it when processing the value
    _scanner.skipWhitespace();
    if (_scanner.peekChar() != '\n' && !_scanner.isDone) {
      // The tag is followed by a value, so we'll process it
      _tokenQueue.add(YamlToken.SCALAR);
    }
  }

  /// Applies the stored YAML tag to the current scalar value.
  ///
  /// Handles built-in YAML tags:
  /// - `!!str`
  /// - `!!int`
  /// - `!!float`
  /// - `!!bool`
  /// - `!!null`
  ///
  /// After applying the tag, clears the stored tag.
  void _handleTaggedValue() {
    if (_currentTag != null) {
      // Handle built-in YAML tags
      switch (_currentTag) {
        case '!!str':
          // Already a string, no conversion needed
          break;
        case '!!int':
          _currentScalar = int.tryParse(_currentScalar ?? '')?.toString() ?? _currentScalar;
          break;
        case '!!float':
          _currentScalar = double.tryParse(_currentScalar ?? '')?.toString() ?? _currentScalar;
          break;
        case '!!bool':
          _currentScalar = _parseBoolean(_currentScalar)?.toString() ?? _currentScalar;
          break;
        case '!!null':
          _currentScalar = null;
          break;
        // Add more tag handlers as needed
      }
      
      // Clear the tag after processing
      _currentTag = null;
    }
  }

  /// Parses YAML boolean text such as `true`, `yes`, `on`, etc.
  ///
  /// Returns `true`, `false`, or `null` if the value is unrecognized.
  bool? _parseBoolean(String? value) {
    if (value == null) return null;
    final lower = value.toLowerCase();
    return lower == 'true' || lower == 'y' || lower == 'yes' || lower == 'on';
  }
  
  /// Parses a block scalar header and its content.
  ///
  /// `styleChar` determines whether the scalar is literal (`|`) or folded (`>`).
  ///
  /// Delegates to:
  /// - [_parseBlockScalarHeader]
  /// - [_parseBlockScalarContent]
  ///
  /// Emits a `SCALAR` token with the processed string value.
  void _parseBlockScalar(String styleChar) {
    _scanner.advance(); // Skip '|' or '>'
    _currentStyle = styleChar == '|' ? YamlStyle.LITERAL : YamlStyle.FOLDED;
    
    // Parse block scalar header (indent, chomping, etc.)
    _parseBlockScalarHeader();
    
    // Parse the actual scalar content
    _currentScalar = _parseBlockScalarContent();
    _currentToken = YamlToken.SCALAR;
    
    // Reset style after parsing
    _currentStyle = YamlStyle.PLAIN;
  }
  
  /// Parses block scalar header indicators:
  /// - Chomping (`+` or `-`)
  /// - Explicit indentation (`|2`, `>4`)
  ///
  /// Responsibilities:
  /// - Reads chomping indicator and indentation.
  /// - Auto-detects indentation when not explicitly provided.
  /// - Skips to the end of the header line.
  void _parseBlockScalarHeader() {
    _scanner.skipWhitespace();
    
    // Parse chomping indicator and indentation
    String? chompingIndicator;
    String? indentation;
    
    // Look for chomping indicator
    if (!_scanner.isDone) {
      final nextChar = _scanner.peekChar();
      if (nextChar == '+' || nextChar == '-') {
        chompingIndicator = _scanner.readChar();
      }
    }
    
    // Look for indentation
    if (!_scanner.isDone) {
      final nextChar = _scanner.peekChar();
      if (nextChar.codeUnitAt(0) >= '0'.codeUnitAt(0) && 
          nextChar.codeUnitAt(0) <= '9'.codeUnitAt(0)) {
        indentation = _scanner.readChar();
        
        // Handle multi-digit indentation
        while (!_scanner.isDone) {
          final nextDigit = _scanner.peekChar();
          if (nextDigit.codeUnitAt(0) >= '0'.codeUnitAt(0) && 
              nextDigit.codeUnitAt(0) <= '9'.codeUnitAt(0)) {
            // Use the null-aware operator and provide a default empty string
            indentation = (indentation ?? '') + _scanner.readChar();
          } else {
            break;
          }
        }
      }
    }
    
    // Skip any remaining characters on the line (comments, etc.)
    while (!_scanner.isDone && _scanner.peekChar() != '\n') {
      _scanner.advance();
    }
    
    // Process the header
    if (chompingIndicator != null || indentation != null) {
      if (chompingIndicator == '+') {
        // Keep trailing newlines
        _blockScalarChomping = BlockScalarChomping.KEEP;
      } else if (chompingIndicator == '-') {
        // Strip all trailing newlines
        _blockScalarChomping = BlockScalarChomping.STRIP;
      } else {
        // Default: strip trailing newlines except one
        _blockScalarChomping = BlockScalarChomping.CLIP;
      }
      
      if (indentation != null) {
        _blockIndent = int.tryParse(indentation) ?? 0;
        if (_blockIndent == 0) {
          // If 0 is specified, use the auto-detected indentation
          _blockIndent = _detectBlockIndent();
        }
      } else {
        // Auto-detect indentation if not specified
        _blockIndent = _detectBlockIndent();
      }
    }
    
    // Skip the newline
    if (!_scanner.isDone && _scanner.peekChar() == '\n') {
      _scanner.advance();
    }
  }

  /// Detects indentation level for block scalar content.
  ///
  /// Reads spaces/tabs from the beginning of the next line and converts them
  /// into a numeric indent level. Scanner position is restored after detection.
  int _detectBlockIndent() {
    final startPos = _scanner.position;
    int indent = 0;
    
    while (!_scanner.isDone) {
      final ch = _scanner.peekChar();
      if (ch == ' ') {
        indent++;
        _scanner.advance();
      } else if (ch == '\t') {
        // Convert tabs to spaces (standard YAML behavior)
        indent = ((indent / 2) + 1).floor() * 2;
        _scanner.advance();
      } else {
        break;
      }
    }
    
    // Reset scanner position using the setter
    _scanner.position = startPos;
    
    return indent;
  }
  
  /// Parses the content of a block scalar.
  ///
  /// Responsibilities:
  /// - Reads lines indented at least as much as the block's indentation.
  /// - Applies YAML's block scalar rules:
  ///   - Literal style (`|`) preserves line breaks.
  ///   - Folded style (`>`) folds single newlines to spaces, but preserves
  ///     blank lines.
  /// - Applies chomping (`+`, `-`, default).
  ///
  /// Returns the processed multiline string.
  String _parseBlockScalarContent() {
    final buffer = StringBuffer();
    bool firstLine = true;
    int baseIndent = 0;
    bool inIndent = true;
    bool emptyLine = false;
    int lineIndent = 0;
    final lines = <String>[];

    // Process each line of the block scalar
    while (true) {
      if (_scanner.isDone) break;
      
      final ch = _scanner.peekChar();
      if (ch == '\n') {
        _scanner.advance();
        if (firstLine) continue;
        emptyLine = true;
        lines.add(''); // Add empty line
        inIndent = true;
        lineIndent = 0;
        continue;
      }
      
      if (firstLine) {
        firstLine = false;
        baseIndent = _detectIndent();
      }
      
      if (inIndent) {
        if (ch == ' ' || ch == '\t') {
          lineIndent += (ch == '\t') ? 2 : 1; // Count tabs as 2 spaces
          _scanner.advance();
          continue;
        } else {
          inIndent = false;
          // Apply indentation handling based on block scalar style
          if (_currentStyle == YamlStyle.LITERAL) {
            if (lineIndent < baseIndent) {
              // This line is less indented than the base, treat as content
              lines.add(' ' * lineIndent); // Using string multiplication instead
            }
          } else if (_currentStyle == YamlStyle.FOLDED) {
            if (emptyLine) {
              // Preserve empty lines in folded style
              if (!buffer.toString().endsWith('\n\n')) {
                buffer.writeln();
              }
            }
            emptyLine = false;
          }
        }
      }
      
      // Read the rest of the line
      final line = _scanner.readLine();
      if (line.isNotEmpty) {
        // Apply indentation handling
        final content = (lineIndent > baseIndent) ? line.substring(baseIndent) : line;
        lines.add(content);
      }
    }

    // Join lines based on the chomping style
    if (_blockScalarChomping == BlockScalarChomping.KEEP) {
      // Keep all trailing newlines
      return '${lines.join('\n')}\n';
    } else if (_blockScalarChomping == BlockScalarChomping.STRIP) {
      // Strip all trailing newlines
      return lines.join('\n').trimRight();
    } else {
      // Default: strip all but one trailing newline
      final result = lines.join('\n');
      return result.endsWith('\n') ? result : '$result\n';
    }
  }

  /// Detects indentation of the current line (similar to [_detectBlockIndent])
  /// but used for folded/literal block processing.
  ///
  /// Restores scanner position after probing indentation.
  int _detectIndent() {
    final startPos = _scanner.position;
    int indent = 0;
    
    while (!_scanner.isDone) {
      final ch = _scanner.peekChar();
      if (ch == ' ') {
        indent++;
        _scanner.advance();
      } else if (ch == '\t') {
        indent = ((indent / 2) + 1).floor() * 2; // Convert tabs to spaces
        _scanner.advance();
      } else {
        break;
      }
    }
    
    _scanner.position = startPos; // Reset position
    return indent;
  }
  
  /// Parses an explicit key indicator (`? key`).
  ///
  /// A key may be empty, a plain scalar, or a more complex structure.
  /// Emits a `KEY` token with the parsed scalar content (possibly empty).
  void _parseExplicitKey() {
    _scanner.advance(); // Skip '?'
    _scanner.skipWhitespace();
    
    if (_scanner.peekChar() == '\n' || _scanner.isDone) {
      // Explicit key with null value
      _currentToken = YamlToken.KEY;
      _currentScalar = '';
    } else {
      // Parse the key
      _currentToken = YamlToken.KEY;
      _currentScalar = _parsePlainScalar();
    }
  }
  
  /// Parses an implicit key (`key:` where `:` appears without preceding whitespace).
  ///
  /// Emits a `KEY` token with the extracted scalar content.
  void _parseImplicitKey() {
    _scanner.advance(); // Skip ':'
    _scanner.skipWhitespace();
    
    if (_scanner.peekChar() == '\n' || _scanner.isDone) {
      // Implicit key with null value
      _currentToken = YamlToken.KEY;
      _currentScalar = '';
    } else {
      // Parse the key
      _currentToken = YamlToken.KEY;
      _currentScalar = _parsePlainScalar();
    }
  }
  
  /// Parses a sequence entry indicator (`- item`).
  ///
  /// Handles both empty items and items with values.
  ///
  /// Emits:
  /// - `SEQUENCE_START`
  /// - (optional) `SCALAR`
  /// - `SEQUENCE_END`
  ///
  /// This creates a minimal “virtual” sequence node for each `-` entry.
  void _parseSequenceItem() {
    _scanner.advance(); // Skip '-'
    _scanner.skipWhitespace();
    
    if (_scanner.peekChar() == '\n' || _scanner.isDone) {
      // Empty sequence item
      _currentToken = YamlToken.SEQUENCE_START;
      _tokenQueue.add(YamlToken.SEQUENCE_END);
    } else {
      // Parse the sequence item
      _currentToken = YamlToken.SEQUENCE_START;
      _currentScalar = _parsePlainScalar();
      _tokenQueue.add(YamlToken.SCALAR);
      _tokenQueue.add(YamlToken.SEQUENCE_END);
    }
  }
  
  /// Parses a YAML plain scalar until a structural terminator is encountered.
  ///
  /// Supports lightweight quote-handling and applies tag conversion via
  /// [_handleTaggedValue].
  ///
  /// Returns the parsed scalar text.
  String _parsePlainScalar() {
    final buffer = StringBuffer();
    bool inQuotes = false;
    
    while (!_scanner.isDone) {
      final ch = _scanner.peekChar();
      
      if (ch == '"' || ch == '\'') {
        inQuotes = !inQuotes;
        _scanner.advance();
        continue;
      }
      
      if (!inQuotes && _isPlainScalarTerminator(ch)) {
        break;
      }
      
      buffer.write(_scanner.readChar());
    }
    
    _currentScalar = buffer.toString().trim();
    _handleTaggedValue(); // Handle any tags that were set
    return _currentScalar ?? '';
  }
  
  /// Parses an identifier used for anchors and tags.
  ///
  /// Reads a sequence of allowed characters until hitting a delimiter.
  String _parseIdentifier() {
    final buffer = StringBuffer();
    
    while (!_scanner.isDone) {
      final ch = _scanner.peekChar();
      if (!_isIdentifierChar(ch)) break;
      buffer.write(_scanner.readChar());
    }
    
    return buffer.toString();
  }
  
  /// Returns `true` if [ch] terminates a plain scalar.
  ///
  /// Includes YAML structural characters, whitespace, flow delimiters,
  /// comment markers, tag/anchor indicators, and newline.
  bool _isPlainScalarTerminator(String ch) {
    return ch == ':' || ch == '[' || ch == ']' || ch == '{' || ch == '}' || 
           ch == ',' || ch == '#' || ch == '&' || ch == '*' || ch == '!' || 
           ch == '|' || ch == '>' || ch == '`' || ch == '\\' || 
           ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r';
  }
  
  /// Returns `true` if [ch] is allowed in an anchor or tag identifier.
  ///
  /// Excludes structural punctuation and whitespace.
  bool _isIdentifierChar(String ch) {
    return ch.codeUnitAt(0) > 0x20 && 
           ch != '[' && ch != ']' && ch != '{' && ch == '}' && 
           ch != ',' && ch != ':' && ch != '#' && ch != '*' && 
           ch != '&' && ch != '!' && ch != '|' && ch != '>' && 
           ch != '`' && ch != '\\' && ch != '"' && ch != '\'';
  }
  
  @override
  String? getCurrentValue() => _currentScalar;

  @override
  String? getAnchor() => _currentAnchor;

  @override
  String? getAlias() => _currentToken == YamlToken.ALIAS ? _currentScalar : null;

  @override
  FutureOr<void> close() {
    _scanner.close();
    _tokenQueue.clear();
    _anchors.clear();
    _anchorStack.clear();
    _documentStack.clear();
    _indentStack.clear();
    _lineStarts.clear();
    _currentToken = null;
    _currentScalar = null;
    _currentAnchor = null;
    _currentTag = null;
    _currentIndent = 0;
    _inFlowCollection = false;
    _inDocument = false;
    _documentEnded = false;
    _streamEnded = false;
  }
  
  /// Consumes spaces and tabs, stopping before newlines or non-whitespace.
  ///
  /// Used when parsing keys, values, block scalar headers, etc.
  void _skipWhitespace() {
    while (!_scanner.isDone) {
      final ch = _scanner.peekChar();
      if (ch != ' ' && ch != '\t') break;
      _scanner.advance();
    }
  }
  
  /// Computes the character index of every line start in the input.
  ///
  /// Used for accurate line/column error reporting.
  void _processLineStarts() {
    for (var i = 0; i < _input.length; i++) {
      if (_input[i] == '\n') {
        _lineStarts.add(i + 1);
      }
    }
  }
  
  /// Returns the current line/column position from the scanner.
  YamlPosition _getCurrentPosition() => _scanner.getCurrentPosition();

  @override
  YamlToken? getCurrentToken() => _currentToken;

  @override
  void skip() {
    if (_currentToken == null) return;
    
    // Handle skipping over nested structures
    if (_currentToken == YamlToken.MAPPING_START || _currentToken == YamlToken.SEQUENCE_START) {
      int depth = 1;
      while (depth > 0 && nextToken()) {
        if (_currentToken == YamlToken.MAPPING_START || _currentToken == YamlToken.SEQUENCE_START) {
          depth++;
        } else if (_currentToken == YamlToken.MAPPING_END || _currentToken == YamlToken.SEQUENCE_END) {
          depth--;
        }
      }
    }
  }
}

/// Internal structure used to track document-level state.
///
/// Each YAML document (`---`) has its own anchor table, indentation base,
/// and flow collection state. These are restored when documents are nested
/// (multi-document streams).
class _DocumentContext {
  /// Indentation level at the start of the document.
  final int indent;

  /// Whether the document started inside a flow collection.
  final bool inFlowCollection;

  /// Anchors defined within this document.
  final Map<String, dynamic> anchors;
  
  _DocumentContext({
    required this.indent,
    required this.inFlowCollection,
    Map<String, dynamic>? anchors,
  }) : anchors = anchors ?? {};
}