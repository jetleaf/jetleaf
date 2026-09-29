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
import '../../exceptions.dart';
import '../../serialization/object_deserializer.dart';
import '../adapter/dart_json_serialization_adapter.dart';
import '../parser/json_parser.dart';
import '../../naming_strategy/naming_strategy.dart';
import '../../serialization/deserialization_context.dart';

/// {@template default_deserialization_context}
/// Default implementation of [DeserializationContext] in Jetleaf’s JSON subsystem.
///
/// The [JsonDeserializationContext] acts as the **central deserialization registry**
/// for the [ObjectMapper]. It is responsible for locating, caching, and invoking
/// the correct [ObjectDeserializer] for a given type during JSON-to-object conversion.
///
/// ### Responsibilities
/// - Manage user-defined and framework-provided deserializers.
/// - Resolve [ObjectDeserializer] instances dynamically based on type compatibility.
/// - Provide fallback to generic [DartJsonDeserializer] when no specific handler exists.
/// - Integrate with the [ObjectMapper] for consistent naming, type conversion,
///   and environment configuration.
///
/// ### Deserializer Resolution Flow
/// 1. Attempt lookup in user-configured deserializers.
/// 2. Fallback to framework-level deserializers.
/// 3. Match by type or deserialization capability (`canDeserialize`).
/// 4. Create a [DartJsonDeserializer] if no match is found and cache it for future use.
///
/// ### Example
/// ```dart
/// final context = JsonDeserializationContext(objectMapper, {});
/// final user = context.deserialize(parser, Class.forType(User));
/// ```
///
/// ### See also
/// - [ObjectDeserializer]
/// - [ObjectMapper]
/// - [DeserializationContext]
/// - [DartJsonDeserializer]
/// {@endtemplate}
@Author("Evaristus Adimonyemma")
class JsonDeserializationContext implements DeserializationContext<JsonParser> {
  // ---------------------------------------------------------------------------
  // Fields
  // ---------------------------------------------------------------------------

  /// The parent [ObjectMapper] that owns this context.
  ///
  /// Provides global configuration, features, and component access for
  /// deserialization operations.
  final ObjectMapper _objectMapper;

  /// Cache of resolved [ObjectDeserializer] instances, keyed by their [Class] type.
  ///
  /// This map is lazily populated as types are encountered during deserialization.
  /// It allows quick lookup and avoids re-instantiating known deserializers.
  final Map<Class, ObjectDeserializer> _deserializers;

  /// Cache of **user-configured deserializers**, registered via the [ObjectMapper].
  ///
  /// These deserializers take precedence over framework-level ones and are typically
  /// used to handle custom or domain-specific model classes.
  final Map<Class, ObjectDeserializer> _configuredDeserializers = {};

  /// Cache of **framework-provided deserializers**, automatically discovered from
  /// Jetleaf’s core packages (for example, packages under [PackageNames.JETSON]).
  ///
  /// These handle standard and infrastructure-level types, including core Jetleaf
  /// entities and built-in primitives.
  final Map<Class, ObjectDeserializer> _frameworkDeserializers = {};

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------

  /// Creates a new [JsonDeserializationContext] associated with the given [ObjectMapper].
  ///
  /// The optional [_deserializers] cache can be pre-filled with known deserializers.
  /// During initialization, each deserializer is categorized as either
  /// **framework** or **configured**, based on its package origin.
  ///
  /// {@macro default_deserialization_context}
  JsonDeserializationContext(this._objectMapper, this._deserializers) {
    for (final entry in _deserializers.entries) {
      final key = entry.key;
      final des = entry.value;

      if (des.getClass().getPackage().getName() == PackageNames.JETSON) {
        _frameworkDeserializers.add(key, des);
      } else {
        _configuredDeserializers.add(key, des);
      }
    }
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
  ObjectDeserializer? findDeserializerForType(Class type) {
    if ((find(type, _configuredDeserializers) ?? find(type, _frameworkDeserializers)) case final deserializer?) {
      return deserializer;
    }

    // Fall back to dart deserializer for complex objects
    final dartDeserializer = DartJsonSerializationAdapter(type);
    _frameworkDeserializers[type] = dartDeserializer;
    
    return dartDeserializer;
  }

  /// Attempts to locate a [ObjectDeserializer] for the specified [type]
  /// within the given [deserializers] map.
  ///
  /// The lookup follows a multi-step resolution strategy:
  /// 1. **Direct key match:** Returns immediately if the type is present as a map key.
  /// 2. **Capability match:** Scans for a deserializer whose `canDeserialize`
  ///    method confirms compatibility with the given type.
  /// 3. **Type equivalence:** Matches based on exact or underlying type identity.
  ///
  /// Returns the matching [ObjectDeserializer], or `null` if no match is found.
  ///
  /// ### Example
  /// ```dart
  /// final deserializer = context.find(Class.forType(User), configuredDeserializers);
  /// if (deserializer != null) {
  ///   final user = deserializer.deserialize(parser, context, Class.forType(User));
  /// }
  /// ```
  ObjectDeserializer? find(Class type, Map<Class, ObjectDeserializer> deserializers) {
    if (deserializers[type] case final deserializer?) {
      return deserializer;
    }

    if (deserializers.values.find((deserializer) => deserializer.canDeserialize(type)) case final deserializer?) {
      return deserializer;
    }

    if (deserializers.values.find((ss) => ss.toClass() == type || ss.toClass().getType() == type.getType()) case final deserializer?) {
      return deserializer;
    }

    return null;
  }

  @override
  T deserialize<T>(JsonParser parser, Class<T> type) {
    final deserializer = findDeserializerForType(type);

    // Ensure parser is positioned at the first token for the incoming value.
    // Some callers create a parser but don't advance it; many deserializers
    // expect to see START_OBJECT/START_ARRAY as the current token. If the
    // parser has no current token, advance it once.
    if (parser.getCurrentToken() == null) {
      parser.nextToken();
    }

    final result = deserializer != null ? deserializer.deserialize(parser, this, type) : parser.getCurrentValue();

    try {
      if (result case T result) {
        return result;
      }

      if (getConversionService().convert(result, type) case T result?) {
        return result;
      }

      return getConversionService().convert(result, type) as T;
    } on ConverterNotFoundException catch (_) {
      return result as T;
    } catch (e, st) {
      final prettyMessage = _buildDeserializationErrorMessage(type);
      throw FailedDeserializationException(prettyMessage, cause: e, stackTrace: st);
    }
  }

  String _buildDeserializationErrorMessage(Class type) {
    final buffer = StringBuffer();

    buffer.writeln('🚨  Jetson Failed Deserialization Error');
    buffer.writeln('──────────────────────────────────────────────');
    buffer.writeln('❌  Unable to construct object of type: `$type`');
    buffer.writeln('');
    buffer.writeln('💡  **Why this happened:**');
    buffer.writeln('This usually occurs when Jetson cannot figure out how to convert JSON data');
    buffer.writeln('into a Dart object, especially for:');
    buffer.writeln('- Complex generic types (e.g. `List<T>`, `Map<String, CustomClass>`).');
    buffer.writeln('- Nested or abstract classes without explicit deserialization hints.');
    buffer.writeln('- Missing `@FromJson`, `@ToJson`, or `@JsonCreator` annotations.');
    buffer.writeln('');
    buffer.writeln('🧭  **How to fix it:**');
    buffer.writeln('1️⃣  Ensure your class has one of the following:');
    buffer.writeln('    • `@FromJson((Map<String, Object> json) => MyClass.fromMap(json))`. Object is not a Map but the instance of the typed object like Home');
    buffer.writeln('    • `@ToJson((instance) => instance.toMap())`');
    buffer.writeln('    • `@JsonCreator()` on a `factory fromJson(Map<String, dynamic> json)`');
    buffer.writeln('');
    buffer.writeln('2️⃣  For nested or generic fields, use `@JsonConverter` to specify a converter:');
    buffer.writeln('    ```dart');
    buffer.writeln('    @JsonConverter(converter: MyCustomConverter())');
    buffer.writeln('    final MyComplexType field;');
    buffer.writeln('    ```');
    buffer.writeln('');
    buffer.writeln('3️⃣  If you have fields to ignore or rename, use:');
    buffer.writeln('    `@JsonField(name: "custom_name")` or `@JsonIgnore()`');
    buffer.writeln('');

    return buffer.toString();
  }
}