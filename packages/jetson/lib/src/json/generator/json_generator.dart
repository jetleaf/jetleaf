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

import '../../base/generator.dart';

/// {@template json_generator}
/// A **streaming JSON writer** that outputs JSON tokens sequentially.
///
/// The [JsonGenerator] provides structured, incremental JSON output for
/// Jetleaf’s serialization engine. It supports object and array boundaries,
/// primitive values, and raw JSON injection for custom serialization cases.
///
/// ### Overview
/// - Produces syntactically valid JSON documents
/// - Supports streaming or in-memory output
/// - Typically used by [ObjectMapper] and custom serializers
///
/// ### Example
/// ```dart
/// final generator = StringJsonGenerator();
/// generator.writeStartObject();
/// generator.writeFieldName('name');
/// generator.writeString('Alice');
/// generator.writeFieldName('age');
/// generator.writeNumber(30);
/// generator.writeEndObject();
///
/// print(generator.toString());
/// // Output: {"name":"Alice","age":30}
/// ```
///
/// ### See also
/// - [JsonParser]
/// - [ObjectMapper]
/// - [JsonSerializer]
/// {@endtemplate}
abstract interface class JsonGenerator implements Generator {
  /// Represents the [JsonGenerator] type for reflection and dynamic discovery.
  ///
  /// This reference identifies components responsible for writing JSON data
  /// during serialization. It allows Jetson to register, configure, and
  /// customize output generators at runtime.
  static final Class<JsonGenerator> CLASS = Class<JsonGenerator>(null, PackageNames.JETSON);

  /// Writes the **start of a JSON object** (`{`).
  ///
  /// This opens a new object context. Every [writeStartObject] must be paired
  /// with a corresponding [writeEndObject].
  ///
  /// ### Example
  /// ```dart
  /// generator.writeStartObject();
  /// generator.writeFieldName('id');
  /// generator.writeNumber(42);
  /// generator.writeEndObject();
  /// ```
  ///
  /// ### Notes
  /// - Nested objects are supported  
  /// - Improper balancing may result in invalid JSON
  void writeStartObject();

  /// Writes the **end of the current JSON object** (`}`).
  ///
  /// Completes the current object scope opened by [writeStartObject].
  ///
  /// ### Example
  /// ```dart
  /// generator.writeStartObject();
  /// generator.writeFieldName('active');
  /// generator.writeBoolean(true);
  /// generator.writeEndObject();
  /// ```
  ///
  /// ### Notes
  /// - Should only be called after [writeStartObject]
  void writeEndObject();

  /// Writes the **start of a JSON array** (`[`).
  ///
  /// This opens an array scope, allowing multiple sequential value writes.
  ///
  /// ### Example
  /// ```dart
  /// generator.writeStartArray();
  /// generator.writeString('A');
  /// generator.writeString('B');
  /// generator.writeEndArray();
  /// // ["A","B"]
  /// ```
  ///
  /// ### Notes
  /// - Must be closed by [writeEndArray]
  void writeStartArray();

  /// Writes the **end of a JSON array** (`]`).
  ///
  /// Completes the current array context opened by [writeStartArray].
  ///
  /// ### Example
  /// ```dart
  /// generator.writeStartArray();
  /// generator.writeNumber(1);
  /// generator.writeNumber(2);
  /// generator.writeEndArray();
  /// ```
  void writeEndArray();

  /// Writes a **field name** within an object context.
  ///
  /// This should precede the corresponding field value.
  ///
  /// ### Example
  /// ```dart
  /// generator.writeStartObject();
  /// generator.writeFieldName('title');
  /// generator.writeString('Jetleaf');
  /// generator.writeEndObject();
  /// ```
  ///
  /// ### Notes
  /// - Must be inside an object  
  /// - Should not be called outside `{}` blocks
  void writeFieldName(String name);

  /// Writes a **numeric value**.
  ///
  /// Supports integers and floating-point numbers.
  ///
  /// ### Example
  /// ```dart
  /// generator.writeNumber(3.14);
  /// // Output: 3.14
  /// ```
  void writeNumber(num value);

  /// Writes a **boolean value**.
  ///
  /// ### Example
  /// ```dart
  /// generator.writeBoolean(false);
  /// // Output: false
  /// ```
  void writeBoolean(bool value);

  /// Writes a **null literal**.
  ///
  /// ### Example
  /// ```dart
  /// generator.writeNull();
  /// // Output: null
  /// ```
  void writeNull();

  /// Writes a **raw JSON fragment** directly to output.
  ///
  /// This bypasses validation and escaping logic, allowing insertion
  /// of preformatted JSON content.
  ///
  /// ### ⚠️ Warning
  /// Use cautiously — malformed JSON fragments will corrupt the output stream.
  ///
  /// ### Example
  /// ```dart
  /// generator.writeRaw('"custom": {"nested": true}');
  /// ```
  ///
  /// ### Notes
  /// - Best used for embedding external JSON or advanced serializers
  void writeRaw(String json);
}