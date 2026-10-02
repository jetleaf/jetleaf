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

import '../../annotations.dart';
import '../../exceptions.dart';
import '../../jetson_utils.dart';
import '../../serialization/deserialization_feature.dart';
import '../../serialization/serialization_feature.dart';
import '../context/json_deserialization_context.dart';
import '../context/json_serialization_context.dart';
import '../generator/json_generator.dart';
import '../json_factory.dart';
import '../json_token.dart';
import '../parser/json_parser.dart';
import 'json_adapter.dart';

/// {@template dart_json_serialization_adapter}
/// Provides a **generic serialization and deserialization adapter** for Dart classes
/// using reflection within the Jetleaf JSON subsystem.
///
/// The [DartJsonSerializationAdapter] serves as a bridge between the JSON representation
/// and a Dart class type, handling field mapping, annotations, and type conversions.
///
/// ### Core Responsibilities
/// - Deserialize JSON objects into Dart class instances
/// - Serialize Dart class instances into JSON objects
/// - Respect field-level annotations such as:
///   - [JsonIgnore] to skip fields
///   - [JsonField] for default values, required fields, or custom names
///   - [JsonConverter] for type-specific serialization/deserialization
///   - [ToJson] for custom creator methods
/// - Integrate with [JsonDeserializationContext] and [JsonSerializationContext] for
///   naming strategies, type conversions, and feature flags
///
/// ### Example
/// ```dart
/// final adapter = DartJsonSerializationAdapter(Class.forType(User));
/// final userJson = '{ "name": "Alice", "age": 30 }';
/// final parser = JsonParser(userJson);
/// final user = adapter.deserialize(parser, context, Class.forType(User));
///
/// final generator = JsonGenerator();
/// adapter.serialize(user, generator, serializerContext);
/// ```
///
/// ### Notes
/// - This adapter relies heavily on reflection (`Class` metadata) to access fields
///   and methods of the Dart class.
/// - Supports both standard deserialization paths and custom converters per field.
/// - Honors serialization and deserialization feature flags such as
///   ignoring null values or failing on unknown properties.
///
/// ### See also
/// - [JsonDeserializationContext]
/// - [JsonSerializationContext]
/// - [JsonSerializer]
/// - [JsonDeserializer]
/// - [JsonConverter]
/// {@endtemplate}
final class DartJsonSerializationAdapter extends JsonSerializationAdapter<Object> {
  /// The reflected [Class] metadata representing the target Dart type.
  final Class _type;

  /// Creates a new [DartJsonSerializationAdapter] for the specified Dart [Class].
  ///
  /// The adapter will use reflection to read and write fields, honoring
  /// annotations and applying custom converters when present.
  /// 
  /// {@macro dart_json_serialization_adapter}
  DartJsonSerializationAdapter(this._type);

  @override
  bool canDeserialize(Class type) => type == _type;

  @override
  Object? deserialize(JsonParser parser, JsonDeserializationContext ctxt, Class toClass) {
    final token = parser.getCurrentToken();

    if (token == JsonToken.VALUE_NULL) {
      return null;
    }

    if (token != JsonToken.START_OBJECT) {
      throw InvalidFormatException('Expected START_OBJECT, got $token');
    }

    final naming = ctxt.getNamingStrategy();
    final allowUnknown = !ctxt.getObjectMapper().isFeatureEnabled(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES.name);
    final type = _type;
    final fieldValues = <String, Object>{};

    // Parse all JSON fields into Dart field map
    while (parser.nextToken()) {
      final currentToken = parser.getCurrentToken();

      if (currentToken == JsonToken.END_OBJECT) {
        break;
      }

      if (currentToken == JsonToken.FIELD_NAME) {
        final jsonKey = parser.getCurrentName()!;
        parser.nextToken();
        
        final jsonValue = parser.getCurrentValue();

        // Map JSON key → Dart field (do this before attempting nested delegation)
        final dartKey = naming.toDartName(jsonKey);
        try {
          // Handle unknown properties
          if (type.getField(dartKey) case final field?) {
            final fieldClass = field.getReturnClass();

            // Skip ignored fields
            if (field.hasDirectAnnotation<JsonIgnore>()) continue;

            final jsonField = field.getDirectAnnotation<JsonField>();
            if (jsonField != null && jsonField.ignore) continue;

            // Handle @JsonField (default values / required)
            if (jsonValue == null) {
              final defaultValue = jsonField?.defaultValue;
              if (defaultValue != null) {
                fieldValues[dartKey] = defaultValue;
                continue;
              }
            }

            if (jsonValue == null && jsonField?.required == true) {
              throw JsonParsingException('Required field "$dartKey" missing for ${_type.getName()}');
            }

            // Apply @JsonConverter if present
            if (field.getDirectAnnotation<JsonConverter>() case final jsonConverter?) {
              final converterInstance = jsonConverter.converter;
              final ct = jsonConverter.type;

              final adapter = ct != null ? ct.toClass().getNoArgConstructor()?.newInstance() : converterInstance;
              if (adapter != null && adapter is JsonDeserializer) {
                fieldValues[dartKey] = adapter.deserialize(parser, ctxt, fieldClass);
                continue;
              }
            }

            // Try type-based deserializer
            fieldValues[dartKey] = ctxt.deserialize(parser, fieldClass);
          } else if (!allowUnknown) {
            throw JsonParsingException('Unknown property "$jsonKey" for type ${_type.getName()}');
          } else {
            continue;
          }
        } on FieldAccessException catch (e) {
          if (e.getCause() is NoSuchMethodError) {
            // ignore method error
            continue;
          }

          rethrow;
        }
      }
    }

    // Construct the dart
    return JetsonUtils.construct(fieldValues, type);
  }

  @override
  bool canSerialize(Class type) => type == _type;

  @override
  void serialize(Object value, JsonGenerator generator, JsonSerializationContext serializer) {
    final type = value.getClass();
    final namingStrategy = serializer.getNamingStrategy();
    final allowNullValues = serializer.getObjectMapper().isFeatureEnabled(SerializationFeature.WRITE_NULL_MAP_VALUES.name);

    // 1. Check for [ToJsonFactory] sub class
    if (value case ToJsonFactory value) {
      serializer.serialize(value.toJson(), generator);
      return;
    }

    // 2. Check for [ToJson] annotation
    if (type.getDirectAnnotation<ToJson>() case final toJson?) {
      serializer.serialize(toJson.creator(value), generator);
      return;
    }

    // 3. Prefer custom [JsonOutput] annotated method if defined
    if (type.getMethods().find((me) => me.hasDirectAnnotation<JsonOutput>()) case final jsonOutput?) {
      if (jsonOutput.getParameterCount() == 0) {
        serializer.serialize(jsonOutput.invoke(value), generator);
        return;
      }
    }

    // 4. Prefer custom `toJson()` method if defined
    final toJson = type.getMethod("toJson");
    if (toJson != null && toJson.getParameterCount() == 0) {
      serializer.serialize(toJson.invoke(value), generator);
      return;
    }

    final fields = type.getFields();

    generator.writeStartObject();

    // 3. Reflect over fields
    for (final field in fields) {
      // Skip ignored fields
      if (field.hasDirectAnnotation<JsonIgnore>()) continue;

      final jsonField = field.getDirectAnnotation<JsonField>();
      if (jsonField != null && jsonField.ignore) continue;

      final fieldName = field.getName();
      try {
        final fieldValue = field.getValue(value);

        // Skip nulls if not allowed
        if (fieldValue == null && !allowNullValues) continue;

        // Determine final JSON field name
        final jsonFieldName = jsonField?.name ?? namingStrategy.toJsonName(fieldName);

        // Handle field-level converter
        if (field.getDirectAnnotation<JsonConverter>() case final converterAnn?) {
          final converterInstance = converterAnn.converter;
          final ct = converterAnn.type;

          final adapter = ct != null ? ct.toClass().getNoArgConstructor()?.newInstance() : converterInstance;

          if (adapter is JsonSerializer) {
            generator.writeFieldName(jsonFieldName);
            adapter.serialize(fieldValue, generator, serializer);
            continue; // handled by converter
          }
        }

        // Use appropriate serializer for field type
        if (serializer.findSerializerForType(field.getReturnClass()) case final possibleSerializer?) {
          generator.writeFieldName(jsonFieldName);
          possibleSerializer.serialize(fieldValue, generator, serializer);
          continue;
        }

        // Default serialization path
        generator.writeFieldName(jsonFieldName);
        serializer.serialize(fieldValue, generator);
      } on FieldAccessException catch (e) {
        if (e.getCause() is NoSuchMethodError) {
          // ignore method error
          continue;
        }

        rethrow;
      }
    }

    generator.writeEndObject();
  }

  @override
  Class<Object> toClass() => Class.fromQualifiedName(_type.getQualifiedName());
}