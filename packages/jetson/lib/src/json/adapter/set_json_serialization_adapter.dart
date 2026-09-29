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

/// {@template set_json_serialization_adapter}
/// Provides **serialization and deserialization support for Dart `Set` types**
/// within Jetleaf’s JSON subsystem.
///
/// The [SetJsonSerializationAdapter] is responsible for converting JSON arrays
/// into Dart `Set` instances and serializing Dart sets back into JSON arrays.
/// It mirrors the behavior of the List adapter but produces a `Set` to preserve
/// uniqueness of elements.
///
/// ### Core Responsibilities
/// - Deserialize JSON arrays into Dart `Set` objects.
/// - Serialize Dart `Set` objects into JSON arrays.
/// - Handle nested containers recursively by delegating to
///   [JsonDeserializationContext].
/// - Resolve per-element types from `componentType()` metadata when available.
/// - Fallback to runtime element type when no static type is provided.
/// - Ignore JSON `null` values within arrays.
///
/// ### Example
/// ```dart
/// final adapter = SetJsonSerializationAdapter();
///
/// final parser = JsonParser('[1, 2, 3]');
/// final result = adapter.deserialize(parser, context, Class.forType(Set));
///
/// final generator = JsonGenerator();
/// adapter.serialize(result, generator, serializerContext);
/// ```
///
/// ### Notes
/// - Supports primitive, complex, and nested object structures.
/// - Integrates with Jetleaf’s naming strategies, serializers, and deserializers
///   via the provided context objects.
/// - Works with generic `Set<T>` as well as raw `Set`.
///
/// ### See also
/// - [JsonSerializationAdapter]
/// - [JsonDeserializationContext]
/// - [JsonSerializationContext]
/// {@endtemplate}
final class SetJsonSerializationAdapter extends JsonSerializationAdapter<Set> {
  /// Creates a constant instance of [SetJsonSerializationAdapter].
  ///
  /// Set serialization/deserialization is generic and requires no stored state.
  /// 
  /// {@macro set_json_serialization_adapter}
  const SetJsonSerializationAdapter();

  @override
  bool canSerialize(Class type) => type == Class<Set>() || type.getType() == Set;

  @override
  void serialize(Set value, JsonGenerator generator, JsonSerializationContext serializer) {
    generator.writeStartArray();
    for (final item in value) {
      serializer.serialize(item, generator);
    }
    generator.writeEndArray();
  }

  @override
  bool canDeserialize(Class type) => type == Class<Set>() || type.getType() == Set;

  @override
  Set? deserialize(JsonParser parser, JsonDeserializationContext ctxt, Class toClass) {
    final token = parser.getCurrentToken();

    if (token == JsonToken.VALUE_NULL) {
      return null;
    }

    if (token != JsonToken.START_ARRAY) {
      throw FormatException('Expected START_ARRAY, got $token');
    }

    final set = <Object>{};

    while (parser.nextToken()) {
      final currentToken = parser.getCurrentToken();

      if (currentToken == JsonToken.END_ARRAY) {
        break;
      }

      // Handle nested containers by delegating to the context
      if (currentToken == JsonToken.START_OBJECT || currentToken == JsonToken.START_ARRAY) {
        final elementType = toClass.componentType() ?? Class.forType(Object);
        final result = ctxt.deserialize(parser, elementType);
        set.add(result);
        continue;
      }

      if (currentToken == JsonToken.VALUE_NULL) {
        continue;
      }

      final value = parser.getCurrentValue();
      if (value == null) {
        continue;
      }

      if (toClass.componentType() case final componentType?) {
        if (ctxt.findDeserializerForType(componentType) case final deserializer?) {
          final result = deserializer.deserialize(parser, ctxt, componentType);
          set.add(result);
          continue;
        }
      }

      final valueClass = value.getClass();
      if (ctxt.findDeserializerForType(valueClass) case final deserializer?) {
        final result = deserializer.deserialize(parser, ctxt, valueClass);
        set.add(result);
        continue;
      }

      set.add(value);
    }

    return set;
  }

  @override
  Class<Set> toClass() => Class<Set>(null, PackageNames.DART);
}