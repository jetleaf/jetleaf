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
import 'package:jetson/src/serialization/deserialization_context.dart';
import 'package:jetson/src/serialization/serialization_context.dart';

import '../../serialization/object_deserializer.dart';
import '../../serialization/object_serialization_adapter.dart';
import '../../serialization/object_serializer.dart';
import '../context/json_deserialization_context.dart';
import '../context/json_serialization_context.dart';
import '../generator/json_generator.dart';
import '../parser/json_parser.dart';

/// {@template jetson_json_serializer}
/// A specialization of [ObjectSerializer] for **JSON serialization** using
/// a [JsonGenerator].
///
/// This interface provides type-safe serialization for objects of type [T]
/// specifically to JSON. It inherits all serialization behavior and contract
/// from [ObjectSerializer], but fixes the generator type to [JsonGenerator].
///
/// ### Example
/// ```dart
/// class UserSerializer extends JsonSerializer<User> {
///   @override
///   void serialize(User value, JsonGenerator generator, SerializerProvider serializer) {
///     generator.writeStartObject();
///     generator.writeField("id", value.id);
///     generator.writeField("name", value.name);
///     generator.writeEndObject();
///   }
/// }
/// ```
///
/// ### See Also
/// - [ObjectSerializer]
/// - [SerializationContext]
/// - [JsonGenerator]
/// {@endtemplate}
@Generic(JsonSerializer)
abstract interface class JsonSerializer<T> implements ObjectSerializer<T, JsonGenerator, JsonSerializationContext> {}

/// {@template jetson_json_deserializer}
/// A specialization of [ObjectDeserializer] for **JSON deserialization** using
/// a [JsonParser].
///
/// This interface provides type-safe deserialization for objects of type [T]
/// specifically from JSON. It inherits all deserialization behavior and contract
/// from [ObjectDeserializer], but fixes the parser type to [JsonParser].
///
/// ### Example
/// ```dart
/// class UserDeserializer extends JsonDeserializer<User> {
///   @override
///   User? deserialize(JsonParser parser, DeserializationContext ctxt, Class toClass) {
///     // Parse the JSON object using parser and return a User instance
///   }
/// }
/// ```
///
/// ### See Also
/// - [ObjectDeserializer]
/// - [DeserializationContext]
/// - [JsonParser]
/// {@endtemplate}
@Generic(JsonDeserializer)
abstract interface class JsonDeserializer<T> implements ObjectDeserializer<T, JsonParser, JsonDeserializationContext> {}

/// {@template json_converter_adapter}
/// A **bidirectional JSON converter** that implements both
/// [ObjectSerializer] and [ObjectDeserializer] for type [T].
///
/// The [JsonSerializationAdapter] provides a unified way to serialize and
/// deserialize objects of type [T], ensuring consistent logic in both
/// directions.
///
/// ### Purpose
/// - Encapsulates both serialization and deserialization for a type  
/// - Simplifies registration of custom adapters via [ObjectMapper.registerAdapter]  
/// - Ensures symmetrical conversion between JSON and Dart models
///
/// ### Example
/// ```dart
/// final class DateTimeAdapter extends JsonConverterAdapter<DateTime> {
///   const DateTimeAdapter();
///
///   @override
///   void serialize(DateTime value, JsonGenerator generator, SerializerProvider provider) {
///     generator.writeString(value.toIso8601String());
///   }
///
///   @override
///   DateTime? deserialize(JsonParser parser, DeserializationContext ctxt) {
///     final raw = parser.getCurrentValue() as String;
///     return DateTime.parse(raw);
///   }
/// }
///
/// // Registration
/// objectMapper.registerAdapter(const DateTimeAdapter());
/// ```
///
/// ### Notes
/// - Typically used for primitive or lightweight types (e.g., DateTime, UUID)
/// - Adapters are reusable across multiple mappers  
/// - Both methods must be deterministic and symmetrical  
///
/// ### See also
/// - [ObjectSerializer]
/// - [ObjectDeserializer]
/// - [ObjectMapper]
/// - [DeserializationContext]
/// - [SerializerProvider]
/// {@endtemplate}
@Generic(JsonSerializationAdapter)
abstract class JsonSerializationAdapter<T> implements ObjectSerializationAdapter<T, JsonGenerator, JsonParser, JsonDeserializationContext, JsonSerializationContext> {
  /// Represents the [JsonSerializationAdapter] type for reflection and integration.
  ///
  /// This reference enables Jetson to detect and apply converters that bridge
  /// JSON serialization/deserialization logic to other frameworks or data
  /// formats (e.g., XML, BSON, YAML).
  static final Class<JsonSerializationAdapter> CLASS = Class<JsonSerializationAdapter>(null, PackageNames.JETSON);

  /// Creates a new bidirectional JSON converter for type [T].
  ///
  /// {@macro json_converter_adapter}
  const JsonSerializationAdapter();

  @override
  bool supports(DeserializationContext context) => context is JsonDeserializationContext;

  @override
  bool supportsContext(SerializationContext context) => context is JsonSerializationContext;
}