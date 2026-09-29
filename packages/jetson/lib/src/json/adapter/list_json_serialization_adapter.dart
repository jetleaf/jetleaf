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

/// {@template list_json_serialization_adapter}
/// Handles **serialization and deserialization of `List` objects** in Jetleaf’s JSON subsystem.
///
/// The [ListJsonSerializationAdapter] provides a reflection-aware adapter for
/// converting JSON arrays into Dart `List` instances and vice versa.
///
/// ### Core Responsibilities
/// - Deserialize JSON arrays into strongly-typed Dart `List` objects.
/// - Serialize Dart `List` objects into JSON arrays.
/// - Recursively handle nested arrays and objects by delegating to the
///   appropriate deserializers in [JsonDeserializationContext].
/// - Skip null values during deserialization if they appear in the JSON.
/// - Resolve element types via `componentType` metadata or runtime type.
///
/// ### Example
/// ```dart
/// final adapter = ListJsonSerializationAdapter();
///
/// final parser = JsonParser('[1, 2, 3]');
/// final list = adapter.deserialize(parser, context, Class.forType(List));
///
/// final generator = JsonGenerator();
/// adapter.serialize(list, generator, serializerContext);
/// ```
///
/// ### Notes
/// - Supports primitive, complex, and nested elements.
/// - Integrates with [JsonDeserializationContext] and [JsonSerializationContext]
///   to respect naming strategies and type conversion.
/// - Works for both generic `List<T>` and raw `List` types.
///
/// ### See also
/// - [JsonDeserializationContext]
/// - [JsonSerializationContext]
/// - [JsonSerializationAdapter]
/// {@endtemplate}
final class ListJsonSerializationAdapter extends JsonSerializationAdapter<List> {
  /// Creates a constant instance of [ListJsonSerializationAdapter].
  ///
  /// Since list handling is generic, this adapter does not need to store
  /// per-instance state.
  /// 
  /// {@macro list_json_serialization_adapter}
  const ListJsonSerializationAdapter();

  @override
  bool canDeserialize(Class type) => type == Class<List>() || type.getType() == List;

  @override
  List? deserialize(JsonParser parser, JsonDeserializationContext ctxt, Class toClass) {
    final token = parser.getCurrentToken();
    
    if (token == JsonToken.VALUE_NULL) {
      return null;
    }

    if (token != JsonToken.START_ARRAY) {
      throw IllegalArgumentException('Expected START_ARRAY, got $token');
    }

    final list = <Object>[];

    while (parser.nextToken()) {
      final currentToken = parser.getCurrentToken();

      if (currentToken == JsonToken.END_ARRAY) {
        break;
      }

      // Handle nested containers specially: if the element is an object/array,
      // delegate to the context so the appropriate deserializer can consume
      // the entire nested structure from the parser.
      if (currentToken == JsonToken.START_OBJECT || currentToken == JsonToken.START_ARRAY) {
        final elementType = toClass.componentType() ?? Class.forType(Object);
        final result = ctxt.deserialize(parser, elementType);

        list.add(result);
        continue;
      }

      if (currentToken == JsonToken.VALUE_NULL) {
        continue;
      }

      // Primitive/scalar values: try to resolve deserializer either from the
      // declared component type or from the runtime value's class.
      final value = parser.getCurrentValue();
      if (value == null) {
        // Nothing to do for unexpected nulls; push null and continue.
        continue;
      }

      if (toClass.componentType() case final componentType?) {
        if (ctxt.findDeserializerForType(componentType) case final deserializer?) {
          final result = deserializer.deserialize(parser, ctxt, componentType);
          
          list.add(result);
          continue;
        }
      }

      // Fallback: resolve deserializer by runtime value class
      final valueClass = value.getClass();
      if (ctxt.findDeserializerForType(valueClass) case final deserializer?) {
        final result = deserializer.deserialize(parser, ctxt, valueClass);
        
        list.add(result);
        continue;
      }

      // If no deserializer found, add raw value
      list.add(value);
    }

    return list;
  }

  @override
  bool canSerialize(Class type) => type == Class<List>() || type.getType() == List;

  @override
  void serialize(List value, JsonGenerator generator, JsonSerializationContext serializer) {
    generator.writeStartArray();
    
    for (final item in value) {
      serializer.serialize(item, generator);
    }

    generator.writeEndArray();
  }

  @override
  Class<List> toClass() => Class<List>(null, PackageNames.DART);
}