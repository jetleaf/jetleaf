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

import '../base/object_mapper.dart';
import '../serialization/object_deserializer.dart';
import '../serialization/object_serialization_adapter.dart';
import '../serialization/object_serializer.dart';
import 'generator/json_generator.dart';
import 'parser/json_parser.dart';
import 'node/json_node.dart';

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
/// - Register new [ObjectSerializer] or [ObjectDeserializer] implementations
/// - Customize field name mapping via [NamingStrategy]
/// - Integrate type converters through [ConversionService]
///
/// ### See also
/// - [NamingStrategy]
/// - [ObjectSerializer]
/// - [ObjectDeserializer]
/// - [ConversionService]
/// - [ObjectSerializationAdapter]
/// {@endtemplate}
abstract interface class JsonObjectMapper implements ObjectMapper {
  /// Serializes a Dart object into a JSON string.
  ///
  /// This method respects:
  /// - The active [NamingStrategy]
  /// - Jetson annotations such as `@JsonField` and `@JsonIgnore`
  /// - Registered converters and custom serializers
  ///
  /// ### Example
  /// ```dart
  /// final json = mapper.writeValueAsJson(user);
  /// print(json);
  /// ```
  String writeValueAsJson(Object? value);

  /// Serializes a Dart object into a `Map<String, dynamic>` representation.
  ///
  /// This produces a format-neutral object structure suitable for
  /// conversion into JSON format.
  Map<String, dynamic> writeValueAsJsonMap(Object? value);

  /// Deserializes a structured json string into an object of type [T].
  ///
  /// ### Example
  /// ```dart
  /// final user = mapper.readValue<User>(dataString, Class<User>());
  /// ```
  T readJsonValue<T>(String data, Class<T> type);

  /// Deserializes a pre-parsed map into an object of type [T].
  ///
  /// Useful when structured data is already available as a map.
  T readJsonValueFromMap<T>(Map<String, dynamic> map, Class<T> type);

  /// Parses the given JSON [content] string into a [JsonNode] tree.
  ///
  /// This allows you to traverse or inspect JSON data without binding it
  /// to a specific object type.
  ///
  /// Throws a parsing exception if the content is invalid JSON.
  ///
  /// ### Example
  /// ```dart
  /// final tree = objectMapper.readContentTree('{"name":"Alice"}');
  /// print(tree.get("name").toObject()); // "Alice"
  /// ```
  JsonNode readContentTree(String content);

  /// Reads and parses JSON content from the given [JsonParser] into a [JsonNode] tree.
  ///
  /// Useful when working with streaming or preconfigured parsers.
  /// The returned tree can be navigated like a DOM or queried dynamically.
  ///
  /// ### Example
  /// ```dart
  /// final parser = objectMapper.createParser('{"age":30}');
  /// final tree = objectMapper.readTree(parser);
  /// print(tree.get("age").toObject()); // 30
  /// ```
  JsonNode readTree(JsonParser parser);

  /// Sets the active [JsonGenerator] used for serializing Dart objects to JSON.
  ///
  /// The provided [generator] will be used by the mapper for all subsequent
  /// serialization operations. This allows users to inject a custom generator
  /// implementation, e.g., one that writes to a `StringBuffer`, a file, or
  /// a network stream.
  ///
  /// If not explicitly set, the mapper lazily creates a default [StringJsonGenerator]
  /// via [getJsonGenerator].
  ///
  /// ### Example
  /// ```dart
  /// final customGenerator = MyCustomJsonGenerator();
  /// objectMapper.setJsonGenerator(customGenerator);
  /// final json = objectMapper.writeValueAsString(myObject);
  /// ```
  ///
  /// ### Notes
  /// - Replacing the generator at runtime affects all threads that share this
  ///   mapper instance, so it should be done carefully in concurrent contexts.
  /// - Any features like `SerializationFeature.INDENT_OUTPUT` will still
  ///   apply to the new generator.
  void setJsonGenerator(JsonGenerator generator);
}