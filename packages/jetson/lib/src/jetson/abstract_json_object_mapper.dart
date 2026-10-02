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

import 'dart:convert';

import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_utils/utils.dart' as utils;
import 'package:meta/meta.dart';

import '../base/object_mapper.dart';
import '../common/standard_deserializers.dart';
import '../common/standard_serializers.dart';
import '../common/time_serialization_adapters.dart';
import '../json/adapter/list_json_serialization_adapter.dart';
import '../json/adapter/map_json_serialization_adapter.dart';
import '../json/adapter/set_json_serialization_adapter.dart';
import '../json/context/json_deserialization_context.dart';
import '../json/context/json_serialization_context.dart';
import '../exceptions.dart';
import '../json/generator/json_generator.dart';
import '../json/adapter/json_adapter.dart';
import '../json/json_object_mapper.dart';
import '../json/json_token.dart';
import '../json/node/json_array_node.dart';
import '../json/node/json_boolean_node.dart';
import '../json/node/json_node.dart';
import '../json/node/json_null_node.dart';
import '../json/node/json_number_node.dart';
import '../json/node/json_map_node.dart';
import '../json/node/json_text_node.dart';
import '../json/parser/json_parser.dart';
import '../json/generator/string_json_generator.dart';
import '../json/parser/string_json_parser.dart';
import '../serialization/deserialization_context.dart';
import '../serialization/object_deserializer.dart';
import '../serialization/object_serialization_adapter.dart';
import '../serialization/object_serializer.dart';
import '../serialization/serialization_context.dart';
import '../serialization/serialization_feature.dart';

/// A factory function type for creating [JsonParser] instances from a raw JSON string.
///
/// Users can provide a custom parser implementation by assigning a factory of this type.
/// This allows full control over parsing behavior, such as supporting non-standard JSON,
/// streaming, or integrating with external libraries.
///
/// ### Example
/// ```dart
/// JsonParser myParserFactory(String content) => MyCustomJsonParser(content);
/// objectMapper.setJsonParserFactory(myParserFactory);
/// ```
typedef JsonParserFactory = JsonParser Function(String content);

/// {@template jetleaf_jetson_object_mapper}
/// A comprehensive **JSON object mapper** for Dart, supporting serialization
/// and deserialization of Dart objects to/from JSON.
///
/// This class handles standard types, collections, date/time values, URIs, and
/// supports pluggable custom serializers, deserializers, and converters.
///
/// ### Features
/// - Registers standard serializers/deserializers for common Dart types:
///   - Primitives: `String`, `int`, `double`, `bool`, `num`
///   - Collections: `List`, `Map`, `Set`
///   - Date/Time: `DateTime`, `ZonedDateTime`, `LocalDateTime`, `LocalDate`, `Duration`
///   - URIs: `Uri`, `Url`
/// - Supports custom adapters via [registerAdapter].
/// - Maintains a configurable [NamingStrategy] for field name mapping.
/// - Integrates with an [ApplicationContext] for environment and conversion services.
/// - Converts Dart objects to JSON string or map, and parses JSON content to Dart objects or [JsonNode] trees.
///
/// ### Usage Example
/// ```dart
/// final mapper = AbstractJsonObjectMapper();
///
/// final jsonMap = {
///   'name': 'Alice',
///   'age': 30,
/// };
///
/// // Serialize to JSON string
/// final jsonString = mapper.writeValueAsString(jsonMap);
/// print(jsonString); // {"name":"Alice","age":30}
///
/// // Deserialize from JSON string
/// final map = mapper.readValue<Map<String, dynamic>>(jsonString, Class<Map<String, dynamic>>());
/// print(map['name']); // Alice
/// ```
///
/// ### Design Notes
/// - Thread-safe serialization and deserialization using `synchronized`.
/// - Lazily initializes internal components like [JsonGenerator], [JsonSerializationContext], and [JsonDeserializationContext].
/// - Delegates type-specific serialization/deserialization to registered serializers/deserializers.
/// - Supports feature flags via [enableFeature] and [disableFeature].
/// {@endtemplate}
abstract class AbstractJsonObjectMapper implements JsonObjectMapper {
  /// Stores **registered serializers** for specific Dart types.
  ///
  /// Each serializer converts a Dart object of a given type into a JSON representation.
  /// The map key is the [Class] of the type, and the value is the corresponding [ObjectSerializer].
  ///
  /// ### Behavior Notes
  /// - Standard serializers (e.g., for `String`, `int`, `List`, `Map`, `Set`) are
  ///   registered automatically on construction.
  /// - Custom serializers can be added via [registerSerializer].
  /// - The map is used internally by the [JsonSerializationContext] to locate the correct
  ///   serializer at runtime.
  ///
  /// ### Example
  /// ```dart
  /// objectMapper.registerSerializer(Class<MyCustomType>(), MyCustomSerializer());
  /// ```
  final Map<Class, ObjectSerializer> _serializers = {};

  /// Stores **registered deserializers** for specific Dart types.
  ///
  /// Each deserializer converts a JSON value into a Dart object of a given type.
  /// The map key is the [Class] of the target type, and the value is the corresponding [ObjectDeserializer].
  ///
  /// ### Behavior Notes
  /// - Standard deserializers (e.g., for `String`, `int`, `List`, `Map`, `Set`) are
  ///   registered automatically on construction.
  /// - Custom deserializers can be added via [registerDeserializer] or [registerAdapter].
  /// - The map is used internally by the [JsonDeserializationContext] to locate the correct
  ///   deserializer at runtime.
  ///
  /// ### Example
  /// ```dart
  /// objectMapper.registerDeserializer(Class<MyCustomType>(), MyCustomDeserializer());
  /// ```
  final Map<Class, ObjectDeserializer> _deserializers = {};

  /// Optional factory function to create a [JsonParser] from a string of JSON content.
  ///
  /// If not set, the mapper falls back to the default [StringJsonParser].
  ///
  /// ### Example
  /// ```dart
  /// objectMapper.setJsonParserFactory((content) => MyCustomJsonParser(content));
  /// ```
  JsonParserFactory? _jsonParserFactory;

  /// Lazily initialized [JsonGenerator] used for serializing Dart objects to JSON.
  ///
  /// Created on first access via [getJsonGenerator], with optional pretty-print
  /// settings based on enabled features.
  JsonGenerator? _jsonGenerator;

  /// Lazily initialized [JsonSerializationContext] responsible for locating and invoking
  /// the correct [JsonSerializer] for each object type.
  ///
  /// Created on first access via [getJsonSerializationContext].
  JsonSerializationContext? _serializationContext;

  /// Lazily initialized [JsonDeserializationContext] responsible for locating and invoking
  /// the correct [JsonDeserializer] for each object type.
  ///
  /// Created on first access via [getJsonDeserializationContext].
  JsonDeserializationContext? _deserializationContext;

  /// Whether to auto add default adapters on instantiation
  bool autoRegisterStandardAdapters = true;

  /// {@macro jetleaf_jetson_object_mapper}
  ///
  /// Creates a new [AbstractJsonObjectMapper] and registers all standard
  /// serializers and deserializers.
  AbstractJsonObjectMapper([this.autoRegisterStandardAdapters = true]) {
    if (autoRegisterStandardAdapters) {
      // Primitives
      registerSerializer(Class<String>(), StringSerializer<JsonGenerator, JsonSerializationContext>());
      registerSerializer(Class<int>(), IntSerializer<JsonGenerator, JsonSerializationContext>());
      registerSerializer(Class<double>(), DoubleSerializer<JsonGenerator, JsonSerializationContext>());
      registerSerializer(Class<bool>(), BoolSerializer<JsonGenerator, JsonSerializationContext>());
      registerSerializer(Class<num>(), NumSerializer<JsonGenerator, JsonSerializationContext>());

      // Primitives
      registerDeserializer(Class<String>(), StringDeserializer<JsonParser, JsonDeserializationContext>());
      registerDeserializer(Class<int>(), IntDeserializer<JsonParser, JsonDeserializationContext>());
      registerDeserializer(Class<double>(), DoubleDeserializer<JsonParser, JsonDeserializationContext>());
      registerDeserializer(Class<bool>(), BoolDeserializer<JsonParser, JsonDeserializationContext>());
      registerDeserializer(Class<num>(), NumDeserializer<JsonParser, JsonDeserializationContext>());

      // Collections
      registerAdapter(Class<List>(), ListJsonSerializationAdapter());
      registerAdapter(Class<Map>(), MapJsonSerializationAdapter());
      registerAdapter(Class<Set>(), SetJsonSerializationAdapter());

      // Date/Time (from converter adapters)
      registerAdapter(Class<DateTime>(), DateTimeSerializationAdapter<JsonGenerator, JsonParser, JsonDeserializationContext, JsonSerializationContext>());
      registerAdapter(Class<ZonedDateTime>(), ZonedDateTimeSerializationAdapter<JsonGenerator, JsonParser, JsonDeserializationContext, JsonSerializationContext>());
      registerAdapter(Class<LocalDateTime>(), LocalDateTimeSerializationAdapter<JsonGenerator, JsonParser, JsonDeserializationContext, JsonSerializationContext>());
      registerAdapter(Class<LocalDate>(), LocalDateSerializationAdapter<JsonGenerator, JsonParser, JsonDeserializationContext, JsonSerializationContext>());
      registerAdapter(Class<Duration>(), DurationSerializationAdapter<JsonGenerator, JsonParser, JsonDeserializationContext, JsonSerializationContext>());

      // URIs
      registerAdapter(Class<Uri>(), UriSerializationAdapter<JsonGenerator, JsonParser, JsonDeserializationContext, JsonSerializationContext>());
      registerAdapter(Class<Url>(), UrlSerializationAdapter<JsonGenerator, JsonParser, JsonDeserializationContext, JsonSerializationContext>());
    }
  }

  /// Returns the active [JsonGenerator], initializing it lazily if necessary.
  ///
  /// The generator is used to serialize Dart objects into JSON strings. It
  /// respects the `SerializationFeature.INDENT_OUTPUT` feature for pretty-printing
  /// and uses an indent size from the environment, defaulting to 2.
  ///
  /// ### Example
  /// ```dart
  /// final generator = objectMapper.getJsonGenerator();
  /// generator.writeStartObject();
  /// generator.writeFieldName('name');
  /// generator.writeString('Alice');
  /// generator.writeEndObject();
  /// print(generator.toJsonString()); // {"name":"Alice"}
  /// ```
  JsonGenerator getJsonGenerator() => _jsonGenerator ??= StringJsonGenerator(
    pretty: isFeatureEnabled(SerializationFeature.INDENT_OUTPUT.name),
    indentSize: getEnvironment().getPropertyAs(ObjectMapper.INDENT_SIZE, Class<int>(), 2) ?? 2
  );

  /// Returns a [JsonParser] for the given JSON [content].
  ///
  /// If a custom parser factory has been provided via [setJsonParserFactory],
  /// it is used to create the parser. Otherwise, the default [StringJsonParser]
  /// is used as a fallback.
  ///
  /// ### Example
  /// ```dart
  /// final parser = objectMapper.getJsonParser('{"name":"Alice"}');
  /// parser.nextToken(); // advances to START_OBJECT
  /// ```
  JsonParser getJsonParser(String content) {
    if (_jsonParserFactory != null) {
      return _jsonParserFactory!(content);
    }

    // fallback to default parser if no factory provided
    return StringJsonParser(content);
  }

  /// Returns the active [JsonDeserializationContext], creating it if necessary.
  ///
  /// The deserialization context provides access to all registered JSON
  /// deserializers and maintains the state required to convert JSON data
  /// structures into Dart objects.  
  ///
  /// A new context instance is created only on first access and then cached
  /// for reuse across the entire deserialization lifecycle.
  JsonDeserializationContext getJsonDeserializationContext() => 
    _deserializationContext ?? JsonDeserializationContext(this, _deserializers);

  /// Returns the active [JsonSerializationContext], creating it lazily when needed.
  ///
  /// The serialization context manages configuration, registered serializers,
  /// and utilities required to convert Dart objects into JSON-compatible
  /// structures.  
  ///
  /// The instance is created on first use and cached for subsequent
  /// serialization operations.
  JsonSerializationContext getJsonSerializationContext() =>
    _serializationContext ?? JsonSerializationContext(this, _serializers);

  @override
  JsonNode readContentTree(String content) {
    final parser = getJsonParser(content);
    final node = readTree(parser);

    parser.close();
    return node;
  }

  @override
  T readJsonValue<T>(String json, Class<T> type) {
    final parser = getJsonParser(json);
    final result = getJsonDeserializationContext().deserialize(parser, type);

    parser.close();
    return result;
  }

  @override
  T readJsonValueFromMap<T>(Map<String, dynamic> map, Class<T> type) {
    final content = jsonEncode(map);
    return readValue(content, type);
  }

  @override
  JsonNode readTree(JsonParser parser) {
    if (parser.getCurrentToken() == JsonToken.START_OBJECT) {
      final node = JsonMapNode();
      parser.nextToken();
      while (parser.getCurrentToken() != JsonToken.END_OBJECT) {
        final key = parser.getCurrentName()!;
        parser.nextToken();
        node.set(key, readTree(parser));
        parser.nextToken();
      }

      return node;
    } else if (parser.getCurrentToken() == JsonToken.START_ARRAY) {
      final node = JsonArrayNode();
      parser.nextToken();
      while (parser.getCurrentToken() != JsonToken.END_ARRAY) {
        node.add(readTree(parser));
        parser.nextToken();
      }

      return node;
    } else if (parser.getCurrentToken() == JsonToken.VALUE_STRING) {
      return JsonTextNode(parser.getCurrentValue().toString());
    } else if (parser.getCurrentToken() == JsonToken.VALUE_NUMBER) {
      return JsonNumberNode(parser.getCurrentValue() as num);
    } else if (parser.getCurrentToken() == JsonToken.VALUE_BOOLEAN) {
      return JsonBooleanNode(parser.getCurrentValue() as bool);
    } else if (parser.getCurrentToken() == JsonToken.VALUE_NULL) {
      return JsonNullNode();
    }

    throw JsonParsingException('Unknown JSON token: ${parser.getCurrentToken()}');
  }

  @override
  @mustCallSuper
  void registerAdapter(Class type, ObjectSerializationAdapter adapter) {
    return synchronized(this, () {
      if (adapter.supports(getJsonDeserializationContext())) {
        _deserializers.put(type, adapter);
        _serializers.put(type, adapter);
      }
    });
  }

  @override
  @mustCallSuper
  void registerDeserializer(Class type, ObjectDeserializer deserializer) {
    return synchronized(this, () {
      if (deserializer.supports(getJsonDeserializationContext())) {
        _deserializers.put(type, deserializer);
      }
    });
  }

  @override
  @mustCallSuper
  void registerSerializer(Class type, ObjectSerializer serializer) {
    return synchronized(this, () {
      if (serializer.supportsContext(getJsonSerializationContext())) {
        _serializers.put(type, serializer);
      }
    });
  }

  /// Sets a custom JSON parser factory to create [JsonParser] instances from
  /// raw JSON strings.
  ///
  /// If not set, the mapper falls back to the default [StringJsonParser].
  ///
  /// ### Example
  /// ```dart
  /// objectMapper.setJsonParserFactory((content) => MyCustomJsonParser(content));
  /// ```
  void setJsonParserFactory(JsonParserFactory factory) {
    _jsonParserFactory = factory;
  }

  @override
  void setJsonGenerator(JsonGenerator jsonGenerator) {
    _jsonGenerator = jsonGenerator;
  }

  @override
  @mustCallSuper
  void setSerializationContext(SerializationContext context) {
    if (context is JsonSerializationContext) {
      _serializationContext = context;
    }
  }

  @override
  @mustCallSuper
  void setDeserializationContext(DeserializationContext context) {
    if (context is JsonDeserializationContext) {
      _deserializationContext = context;
    }
  }

  @override
  Map<String, dynamic> writeValueAsJsonMap(Object? value) {
    if (value == null) return {};
    
    final generated = writeValueAsJson(value);
    return utils.JsonParser().parse(generated);
  }

  @override
  String writeValueAsJson(Object? value) {
    if (value == null) return "";
  
    final generator = getJsonGenerator();

    return synchronized(generator, () {
      getJsonSerializationContext().serialize(value, generator);
      final result = generator.toString();

      generator.close();

      return result;
    });
  }
}