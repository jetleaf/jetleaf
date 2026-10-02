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

import 'package:jetleaf_convert/convert.dart';
import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';

import '../../base/object_mapper.dart';
import '../../naming_strategy/naming_strategy.dart';
import '../../serialization/object_serializer.dart';
import '../../serialization/serialization_context.dart';
import '../adapter/dart_json_serialization_adapter.dart';
import '../generator/json_generator.dart';

/// {@template default_serializer_provider}
/// Default implementation of [SerializationContext] for Jetleaf’s JSON subsystem.
///
/// The [JsonSerializationContext] is responsible for locating, caching,
/// and managing [ObjectSerializer] instances used during object serialization.
/// It serves as the **central serialization registry**, queried by the
/// [ObjectMapper] whenever an object needs to be converted to JSON.
///
/// ### Responsibilities
/// - Maintain lookup caches for configured and framework-level serializers.
/// - Dynamically resolve serializers for user-defined or system types.
/// - Provide fallback to generic [DartJsonSerializer] for unregistered classes.
/// - Integrate tightly with the [ObjectMapper] for consistent
///   configuration, naming, and conversion behavior.
///
/// ### Serializer Resolution Flow
/// 1. Attempt lookup in configured (user-provided) serializers.
/// 2. Fall back to framework-provided serializers.
/// 3. Check internal cache for a pre-resolved serializer.
/// 4. Match serializer by capability (`canSerialize`) or exact type match.
/// 5. If none is found, register and return a [DartJsonSerializer] for the type.
///
/// ### Example
/// ```dart
/// final provider = JsonSerializationContext(objectMapper, {});
/// final serializer = provider.findSerializerForType(Class.forType(MyModel));
/// serializer?.serialize(myModel, generator, provider);
/// ```
///
/// ### See also
/// - [ObjectSerializer]
/// - [ObjectMapper]
/// - [SerializationContext]
/// - [DartJsonSerializer]
/// {@endtemplate}
@Author("Evaristus Adimonyemma")
class JsonSerializationContext implements SerializationContext<JsonGenerator> {
  /// Internal cache mapping [Class] types to their resolved [ObjectSerializer] instances.
  ///
  /// This cache is lazily populated as serializers are discovered or created.
  /// It includes both user-registered and framework-level serializers,
  /// enabling quick lookup without recomputation.
  final Map<Class, ObjectSerializer> _serializers;

  /// The [ObjectMapper] associated with this provider.
  ///
  /// Provides global serialization configuration, including:
  /// - Naming strategy (e.g., snake_case, camelCase)
  /// - Conversion service for type coercion
  /// - Environmental context for feature flags or profiles
  final ObjectMapper _objectMapper;

  /// Cache of **user-configured** serializers explicitly registered
  /// by developers through the [ObjectMapper].
  ///
  /// These serializers take precedence over framework serializers,
  /// allowing user customization for domain-specific classes.
  final Map<Class, ObjectSerializer> _configuredSerializers = {};

  /// Cache of **framework-provided** serializers automatically discovered
  /// from the Jetleaf core packages (e.g., those under `PackageNames.JETSON`).
  ///
  /// These handle built-in types such as `String`, `int`, and Jetleaf entities.
  final Map<Class, ObjectSerializer> _frameworkSerializers = {};

  /// Creates a new [JsonSerializationContext] bound to the given [ObjectMapper].
  ///
  /// The [_serializers] map may optionally include pre-populated serializers.
  /// On initialization, the constructor automatically categorizes
  /// serializers into framework and configured caches based on package origin.
  ///
  /// {@macro default_serializer_provider}
  JsonSerializationContext(this._objectMapper, this._serializers) {
    for (final entry in _serializers.entries) {
      final key = entry.key;
      final s = entry.value;

      if (s.getClass().getPackage().getName() == PackageNames.JETSON) {
        _frameworkSerializers.add(key, s);
      } else {
        _configuredSerializers.add(key, s);
      }
    }
  }

  @override
  ObjectSerializer? findSerializerForType(Class type) {
    if ((find(type, _configuredSerializers) ?? find(type, _frameworkSerializers)) case final deserializer?) {
      return deserializer;
    }

    // Fall back to dart serializer for complex objects
    final dartSerializer = DartJsonSerializationAdapter(type);
    _frameworkSerializers[type] = dartSerializer;

    return dartSerializer;
  }

  /// Attempts to locate a [ObjectSerializer] for the specified [type]
  /// within the provided [serializers] map.
  ///
  /// The search follows a hierarchical matching strategy:
  /// 1. **Direct lookup:** Returns immediately if the type exists as a key.
  /// 2. **Capability match:** Checks each serializer’s `canSerialize` predicate.
  /// 3. **Type equivalence:** Matches serializers whose declared type or
  ///    underlying Dart type equals the requested [type].
  ///
  /// Returns the best-matching [ObjectSerializer] or `null` if none found.
  ///
  /// ### Example
  /// ```dart
  /// final serializer = provider.find(Class.forType(MyModel), configuredSerializers);
  /// if (serializer != null) {
  ///   print("Found serializer for ${serializer.toClass().getName()}");
  /// }
  /// ```
  ObjectSerializer? find(Class type, Map<Class, ObjectSerializer> serializers) {
    if (serializers[type] case final serializer?) {
      return serializer;
    }

    if (serializers.values.find((serializer) => serializer.canSerialize(type)) case final serializer?) {
      return serializer;
    }

    if (serializers.values.find((ss) => ss.toClass() == type || ss.toClass().getType() == type.getType()) case final serializer?) {
      return serializer;
    }

    return null;
  }

  @override
  ObjectMapper getObjectMapper() => _objectMapper;

  @override
  NamingStrategy getNamingStrategy() => _objectMapper.getNamingStrategy();

  @override
  ConversionService getConversionService() => _objectMapper.getConversionService();

  @override
  Environment getEnvironment() => _objectMapper.getEnvironment();

  @override
  void serialize(Object? object, JsonGenerator generator) {
    if (object == null) {
      generator.writeNull();
      return;
    }

    // Find appropriate serializer
    final type = object.getClass();

    if (findSerializerForType(type) case final serializer?) {
      serializer.serialize(object, generator, this);
    } else {
      // Fallback: write as string
      generator.writeString(object.toString());
    }
  }
}