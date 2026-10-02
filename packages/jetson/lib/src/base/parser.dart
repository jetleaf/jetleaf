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

import 'package:jetleaf_lang/lang.dart';

/// Base interface for all token-based streaming parsers.
///
/// A `Parser<Token>` exposes a **cursor-style streaming API** for reading
/// structured input one token at a time. Implementations commonly back
/// JSON, YAML, or custom data formats where deserializers need efficient,
/// forward-only processing.
///
/// ## Core Behavior
/// A parser exposes three fundamental operations:
/// 1. **Advance** to the next token — [nextToken]  
/// 2. **Inspect** the current token — [getCurrentToken]  
/// 3. **Skip** nested structures — [skip]
///
/// Tokens are format-specific (e.g., `JsonToken`), but the usage pattern is
/// consistent across all implementations.
///
/// ## Basic Usage
/// ```dart
/// while (parser.nextToken()) {
///   switch (parser.getCurrentToken()) {
///     case JsonToken.fieldName:
///       print('Field: ${parser.getCurrentName()}');
///       break;
///     case JsonToken.valueString:
///       print('Value: ${parser.getValueAsString()}');
///       break;
///   }
/// }
/// ```
///
/// ## Streaming Semantics
/// - The parser is **initially positioned before the first token**  
/// - After each successful call to [nextToken], the current token becomes valid  
/// - When input ends, [nextToken] returns `false` and the cursor is exhausted  
///
/// ## Skipping Behavior
/// Calling [skip] allows efficiently ignoring entire object/array structures:
///
/// ```dart
/// if (parser.getCurrentToken() == JsonToken.startArray) {
///   parser.skip(); // reader jumps past the entire array
/// }
/// ```
///
/// Implementers must ensure:
/// - Correctly balanced skipping of nested structures  
/// - Cursor ends on the token *after* the skipped section  
///
/// ## Type Parameter
/// - `Token` is the token enumeration or class type defining the grammar.
///   Examples: `JsonToken`, `XmlToken`, `TomlToken`.
@Generic(Parser)
abstract interface class Parser<Token> implements Closeable {
  /// Advances the parser to the **next token**.
  ///
  /// Returns:
  /// - `true` if another token was read  
  /// - `false` when there are no more tokens (end of input)
  ///
  /// Calling this method positions the parser on a new current token,
  /// retrievable via [getCurrentToken].
  ///
  /// ### Example
  /// ```dart
  /// while (parser.nextToken()) {
  ///   print('Token: ${parser.getCurrentToken()}');
  /// }
  /// ```
  ///
  /// ### Notes
  /// - Safe to call repeatedly until it returns `false`
  /// - May throw parsing exceptions on malformed input
  bool nextToken();

  /// Returns the **text or raw value** associated with the current token.
  ///
  /// For value tokens, this returns the token’s actual content, such as a string,
  /// number, or boolean. For non-value tokens (like `{` or `}`), it may return `null`.
  ///
  /// ### Example
  /// ```dart
  /// if (parser.getCurrentToken() == JsonToken.VALUE_STRING) {
  ///   print('Value: ${parser.getCurrentValue()}');
  /// }
  /// ```
  ///
  /// ### Notes
  /// - May return primitive types, strings, or `null`  
  /// - For number tokens, the type may depend on the parser implementation
  Object? getCurrentValue();

  /// Returns the **current token** after a successful [nextToken] call.
  ///
  /// The token identifies the parser's position in the stream, such as:
  /// - `startObject`
  /// - `endObject`
  /// - `fieldName`
  /// - `valueString`
  ///
  /// ### Example
  /// ```dart
  /// if (parser.getCurrentToken() == JsonToken.fieldName) {
  ///   print("Field name: ${parser.getCurrentName()}");
  /// }
  /// ```
  ///
  /// ### Notes
  /// - Returns `null` before the first call to [nextToken]
  /// - Must always reflect the most recent token read
  Token? getCurrentToken();

  /// Skips the **entire nested structure** at the current cursor position.
  ///
  /// Useful for ignoring parts of input that are irrelevant to the current
  /// deserialization task.
  ///
  /// ### Example
  /// ```dart
  /// if (parser.getCurrentToken() == JsonToken.startObject) {
  ///   parser.skip(); // jumps to just after the object
  /// }
  /// ```
  ///
  /// ### Rules
  /// - The parser **must be positioned on a structural start token**, such as
  ///   an object or array opening.
  /// - Nested structures must be skipped completely.
  /// - After return, the parser must be positioned **after** the skipped block.
  ///
  /// ### Error Conditions
  /// - Calling on a non-structural token should throw
  /// - Unbalanced structures must throw format-specific parse errors
  void skip();
}