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

import '../context/json_deserialization_context.dart';
import '../context/json_serialization_context.dart';
import '../generator/json_generator.dart';
import '../json_token.dart';
import '../parser/json_parser.dart';
import 'json_adapter.dart';

/// {@template map_json_serialization_adapter}
/// Handles **serialization and deserialization of `Map` objects** in Jetleaf’s JSON subsystem.
///
/// The [MapJsonSerializationAdapter] provides a reflection-aware adapter for
/// converting JSON objects into Dart `Map<String, Object>` instances and vice versa.
///
/// ### Core Responsibilities
/// - Deserialize JSON objects into strongly-typed Dart `Map` objects.
/// - Serialize Dart `Map` objects into JSON objects.
/// - Respect naming strategies for keys using [NamingStrategy].
/// - Recursively handle nested objects and arrays by delegating to the
///   appropriate deserializers in [JsonDeserializationContext].
/// - Skip null values during deserialization if they appear in the JSON.
/// - Resolve value types via `componentType` metadata or runtime type.
///
/// ### Example
/// ```dart
/// final adapter = MapJsonSerializationAdapter();
///
/// final parser = JsonParser('{ "name": "Alice", "age": 30 }');
/// final map = adapter.deserialize(parser, context, Class.forType(Map));
///
/// final generator = JsonGenerator();
/// adapter.serialize(map, generator, serializerContext);
/// ```
///
/// ### Notes
/// - Supports primitive, complex, and nested values.
/// - Integrates with [JsonDeserializationContext] and [JsonSerializationContext]
///   to respect naming strategies and type conversion.
/// - Works for both generic `Map<String, T>` and raw `Map` types.
///
/// ### See also
/// - [JsonDeserializationContext]
/// - [JsonSerializationContext]
/// - [JsonSerializationAdapter]
/// {@endtemplate}
final class MapJsonSerializationAdapter extends JsonSerializationAdapter<Map> {
  /// Creates a constant instance of [MapJsonSerializationAdapter].
  ///
  /// Since map handling is generic, this adapter does not need to store
  /// per-instance state.
  /// 
  /// {@macro map_json_serialization_adapter}
  const MapJsonSerializationAdapter();

  @override
  bool canSerialize(Class type) => type == Class<Map>() || type.getType() == Map;

  @override
  void serialize(Map value, JsonGenerator generator, JsonSerializationContext serializer) {
    generator.writeStartObject();
    final naming = serializer.getNamingStrategy();

    for (final entry in value.entries) {
      final key = entry.key.toString();
      final jsonKey = naming.toJsonName(key);
      generator.writeFieldName(jsonKey);
      serializer.serialize(entry.value, generator);
    }

    generator.writeEndObject();
  }

  @override
  bool canDeserialize(Class type) => type == Class<Map>() || type.getType() == Map;

  @override
  Map? deserialize(JsonParser parser, JsonDeserializationContext ctxt, Class toClass) {
    final token = parser.getCurrentToken();

    if (token == JsonToken.VALUE_NULL) {
      return null;
    }

    if (token != JsonToken.START_OBJECT) {
      throw FormatException('Expected START_OBJECT, got $token');
    }

    final map = <String, Object>{};
    final naming = ctxt.getNamingStrategy();

    while (parser.nextToken()) {
      final currentToken = parser.getCurrentToken();

      if (currentToken == JsonToken.END_OBJECT) {
        break;
      }

      if (currentToken == JsonToken.FIELD_NAME) {
        final jsonKey = parser.getCurrentName()!;
        final dartKey = naming.toDartName(jsonKey);

        parser.nextToken();
        final currentValueToken = parser.getCurrentToken();

        // If the value is a nested object/array, delegate to context so the
        // appropriate deserializer can consume it entirely.
        if (currentValueToken == JsonToken.START_OBJECT || currentValueToken == JsonToken.START_ARRAY) {
          final valueType = toClass.componentType() ?? Class.forType(Object);
          final result = ctxt.deserialize(parser, valueType);
          map[dartKey] = result;

          continue;
        }

        if (currentValueToken == JsonToken.VALUE_NULL) {
          continue;
        }

        final value = parser.getCurrentValue();
        if (value == null) {
          continue;
        }


        // Try to use the declared map value component type first
        if (toClass.componentType() case final valueType?) {
          if (ctxt.findDeserializerForType(valueType) case final valueDeserializer?) {
            final deserialized = valueDeserializer.deserialize(parser, ctxt, valueType);
            map[dartKey] = deserialized;

            continue;
          }
        }

        // Fallback to runtime value's deserializer
        final valueClass = value.getClass();
        if (ctxt.findDeserializerForType(valueClass) case final deserializer?) {
          final result = deserializer.deserialize(parser, ctxt, valueClass);
          map[dartKey] = result;
          
          continue;
        }

        // If nothing else, put raw value
        map[dartKey] = value;
      }
    }

    return map;
  }

  @override
  Class<Map> toClass() => Class<Map>(null, PackageNames.DART);
}