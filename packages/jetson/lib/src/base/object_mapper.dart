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

import '../jetson/jetson_object_mapper.dart';
import '../naming_strategy/naming_strategy.dart';
import '../serialization/base_serializer.dart';
import '../serialization/deserialization_context.dart';
import '../serialization/object_deserializer.dart';
import '../serialization/object_serialization_adapter.dart';
import '../serialization/object_serializer.dart';
import '../serialization/serialization_context.dart';
import 'object_mapper_type.dart';

/// {@template object_mapper}
/// Provides a unified abstraction for **object serialization and deserialization**
/// within the Jetleaf framework.
///
/// The [ObjectMapper] serves as the central entry point for converting between
/// Dart objects and their JSON (or `Map<String, dynamic>`) representations.
/// It respects naming strategies, annotations, and registered converters,
/// enabling consistent and extensible data mapping.
///
/// ### Core Responsibilities
/// - Serialize objects to JSON strings or maps
/// - Deserialize JSON data into strongly typed Dart objects
/// - Manage custom serializers, deserializers, and adapters
/// - Apply naming strategies and type coercion via [ConversionService]
///
/// ### Example
/// ```dart
/// final mapper = DefaultObjectMapper();
/// mapper.setNamingStrategy(SnakeCaseNamingStrategy());
///
/// final user = User(name: 'Alice', age: 30);
/// final json = mapper.writeValueAsString(user);
///
/// final restored = mapper.readValue<User>(json, Class<User>());
/// ```
///
/// ### Extensibility
/// - Register new [JsonSerializer] or [JsonDeserializer] implementations
/// - Customize field name mapping via [NamingStrategy]
/// - Integrate type converters through [ConversionService]
///
/// ### See also
/// - [NamingStrategy]
/// - [JsonSerializer]
/// - [JsonDeserializer]
/// - [ConversionService]
/// - [JsonConverterAdapter]
/// {@endtemplate}
abstract interface class ObjectMapper implements BaseSerializer {
  /// The configuration key for specifying the default timezone used by Jetson.
  ///
  /// When set, this property controls how `DateTime` values are serialized
  /// and deserialized across all mappers, converters, and annotated fields.
  ///
  /// ### Default
  /// If not explicitly configured, Jetson uses the system’s local timezone.
  ///
  /// ### Example
  /// ```dart
  /// environment.setProperty(ObjectMapper.TIMEZONE_PROPERTY, "UTC");
  /// ```
  static const String TIMEZONE_PROPERTY = "jetson.timezone";

  /// Configuration property key that controls the number of spaces used
  /// when pretty-printing structured output.
  ///
  /// ### Example
  /// ```dart
  /// environment.setProperty(ObjectMapper.INDENT_SIZE, 4);
  /// ```
  static const String INDENT_SIZE = "jetson.pretty-print.indent-size";

  /// Creates a new instance of the default Jetson [ObjectMapper] implementation.
  ///
  /// The returned mapper supports reflection-driven (de)serialization
  /// of structured object data into a variety of formats (e.g., JSON, YAML, XML).
  ///
  /// It includes:
  /// - Support for Jetson annotations (`@JsonField`, `@JsonIgnore`, `@JsonCreator`)
  /// - Integration with Jetleaf’s `Class` reflection system
  /// - Configurable naming strategies
  /// - Automatic discovery of converters
  ///
  /// ### Example:
  /// ```dart
  /// final mapper = ObjectMapper();
  /// final dataString = mapper.writeValueAsString(user); // JSON, YAML, etc.
  /// final user = mapper.readValue<User>(dataString, Class<User>());
  /// ```
  factory ObjectMapper() => JetsonObjectMapper();

  // ─────────────────────────────────────────────────────────────
  // Serialization
  // ─────────────────────────────────────────────────────────────

  /// Serializes a Dart object into a **structured format string**.
  ///
  /// The format can be JSON, YAML, XML, or any supported representation
  /// depending on the configuration or generator provided.
  ///
  /// The active [NamingStrategy], annotations, and converters are applied.
  ///
  /// ### Example
  /// ```dart
  /// final dataString = mapper.writeValueAsString(user); 
  /// ```
  String writeValueAsString(Object? value, [ObjectMapperType mapWith = ObjectMapperType.JSON]);

  /// Serializes a Dart object into a `Map<String, dynamic>` representation.
  ///
  /// This produces a format-neutral object structure suitable for
  /// conversion into JSON, YAML, XML, or other structured formats.
  Map<String, dynamic> writeValueAsMap(Object? value, [ObjectMapperType mapWith = ObjectMapperType.JSON]);

  // ─────────────────────────────────────────────────────────────
  // Deserialization
  // ─────────────────────────────────────────────────────────────

  /// Deserializes a structured string into an object of type [T].
  ///
  /// The string can represent JSON, YAML, XML, or any supported format.
  ///
  /// ### Example
  /// ```dart
  /// final user = mapper.readValue<User>(dataString, Class<User>());
  /// ```
  T readValue<T>(String data, Class<T> type, [ObjectMapperType mapWith = ObjectMapperType.JSON]);

  /// Deserializes a pre-parsed map into an object of type [T].
  ///
  /// Useful when structured data is already available as a map.
  T readValueFromMap<T>(Map<String, dynamic> map, Class<T> type, [ObjectMapperType mapWith = ObjectMapperType.JSON]);

  // ─────────────────────────────────────────────────────────────
  // Configuration
  // ─────────────────────────────────────────────────────────────

  /// Sets the active [NamingStrategy] for this mapper.
  ///
  /// Determines how Dart field names are mapped to JSON keys.
  ///
  /// Built-in strategies include:
  /// - [CamelCaseNamingStrategy] (default)
  /// - [SnakeCaseNamingStrategy]
  /// - [KebabCaseNamingStrategy]
  ///
  /// ### Example
  /// ```dart
  /// mapper.setNamingStrategy(SnakeCaseNamingStrategy());
  /// ```
  void setNamingStrategy(NamingStrategy strategy);

  /// Assigns the [SerializationContext] used during serialization.
  ///
  /// The context supplies serializers, caching, configuration, and extension
  /// mechanisms used while writing objects to JSON.
  ///
  /// ### Example
  /// ```dart
  /// mapper.setSerializationContext(serializerContext);
  /// ```
  void setSerializationContext(SerializationContext context);

  /// Assigns the [DeserializationContext] used during deserialization.
  ///
  /// The context handles:
  /// - Type metadata  
  /// - Reference resolution  
  /// - Error handling  
  /// - Registered deserializers and converters  
  ///
  /// ### Example
  /// ```dart
  /// mapper.setDeserializationContext(deserializationContext);
  /// ```
  void setDeserializationContext(DeserializationContext context);

  // ─────────────────────────────────────────────────────────────
  // Feature Flags
  // ─────────────────────────────────────────────────────────────

  /// Enables a configurable feature flag within the mapping engine.
  ///
  /// Jetson supports feature toggles similar in concept to Jackson’s
  /// serialization/deserialization features (e.g., `"FAIL_ON_UNKNOWN_PROPERTIES"`).
  void enableFeature(String featureName);

  /// Disables a configurable feature flag.
  void disableFeature(String featureName);

  /// Returns whether a feature flag is currently enabled.
  bool isFeatureEnabled(String featureName);

  // ─────────────────────────────────────────────────────────────
  // Registration
  // ─────────────────────────────────────────────────────────────

  /// Registers a custom serializer for type [T].
  ///
  /// This serializer will be used whenever an instance of [T] (or a subclass)
  /// is encountered during serialization.
  ///
  /// ---
  ///
  /// ### Example:
  /// ```dart
  /// mapper.registerSerializer(Class<DateTime>(), DateTimeSerializer());
  /// ```
  ///
  /// ---
  void registerSerializer(Class type, ObjectSerializer serializer);

  /// Registers a custom deserializer for type [T].
  ///
  /// Used to control how JSON values are converted into Dart objects of type [T].
  ///
  /// ---
  ///
  /// ### Example:
  /// ```dart
  /// mapper.registerDeserializer(Class<DateTime>(), DateTimeDeserializer());
  /// ```
  ///
  /// ---
  void registerDeserializer(Class type, ObjectDeserializer deserializer);

  /// Registers a bidirectional adapter ([ObjectSerializationAdapter]) for type [T].
  ///
  /// Equivalent to registering both a serializer and a deserializer.
  ///
  /// ---
  ///
  /// ### Example:
  /// ```dart
  /// mapper.registerAdapter<DateTime>(DateTimeAdapter());
  /// ```
  ///
  /// ---
  void registerAdapter(Class type, ObjectSerializationAdapter adapter);
}