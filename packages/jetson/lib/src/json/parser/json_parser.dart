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

import '../json_token.dart';
import '../../base/parser.dart';

/// {@template json_parser}
/// A **streaming JSON reader** that sequentially exposes parsed JSON tokens.
///
/// The [JsonParser] provides low-level, pull-based access to JSON input,
/// allowing deserializers to process data incrementally rather than loading
/// entire structures into memory.
///
/// ### Overview
/// - Reads from strings, byte streams, or other character sources  
/// - Emits tokens (`JsonToken`) as it parses  
/// - Allows skipping nested objects and arrays efficiently  
///
/// ### Example
/// ```dart
/// final parser = StringJsonParser('{"name": "Alice", "age": 30}');
/// while (parser.nextToken()) {
///   print(parser.getCurrentToken());
/// }
/// parser.close();
/// ```
///
/// ### Typical Usage
/// Implementations are primarily used internally by:
/// - `ObjectMapper` deserializers
/// - Custom JSON readers
/// - Streaming APIs where partial JSON reading is required
///
/// ### See also
/// - [JsonToken]
/// - [ObjectMapper]
/// - [JsonDeserializer]
/// - [Closeable]
/// {@endtemplate}
abstract interface class JsonParser implements Parser<JsonToken>, Closeable {
  /// Represents the [JsonParser] type for reflection-based registration and
  /// dependency resolution.
  ///
  /// Used by the Jetson deserialization pipeline to dynamically recognize
  /// parser components responsible for reading structured JSON data from
  /// an input source (string, stream, etc.).
  static final Class<JsonParser> CLASS = Class<JsonParser>(null, PackageNames.JETSON);

  /// Returns the **current field name**, if the parser is positioned
  /// at a JSON object field.
  ///
  /// ### Example
  /// ```dart
  /// if (parser.getCurrentToken() == JsonToken.FIELD_NAME) {
  ///   print(parser.getCurrentName());
  /// }
  /// ```
  ///
  /// Returns `null` for tokens outside object field contexts.
  String? getCurrentName();
}