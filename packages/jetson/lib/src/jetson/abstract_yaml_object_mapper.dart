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
import 'package:jetleaf_utils/utils.dart' as utils;

import '../base/object_mapper.dart';
import '../common/standard_deserializers.dart';
import '../common/standard_serializers.dart';
import '../common/time_serialization_adapters.dart';
import '../exceptions.dart';
import '../serialization/object_deserializer.dart';
import '../serialization/object_serialization_adapter.dart';
import '../serialization/object_serializer.dart';
import '../yaml/adapter/list_yaml_serialization_adapter.dart';
import '../yaml/adapter/map_yaml_serialization_adapter.dart';
import '../yaml/adapter/set_yaml_serialization_adapter.dart';
import '../yaml/node/yaml_map_node.dart';
import '../yaml/node/yaml_scalar_node.dart';
import '../yaml/node/yaml_sequence_node.dart';
import '../yaml/yaml_object_mapper.dart';
import '../yaml/yaml_token.dart';
import '../yaml/generator/string_yaml_generator.dart';
import '../yaml/generator/yaml_generator.dart';
import '../yaml/context/yaml_serialization_context.dart';
import '../yaml/context/yaml_deserialization_context.dart';
import '../yaml/node/yaml_node.dart';
import '../yaml/parser/yaml_parser.dart';
import '../yaml/parser/string_yaml_parser.dart';
import '../serialization/serialization_context.dart';
import '../serialization/deserialization_context.dart';
import 'abstract_xml_object_mapper.dart';

/// {@template abstract_yaml_object_mapper}
/// Abstract base implementation of [YamlObjectMapper] extending
/// [AbstractXmlObjectMapper] to provide YAML-specific serialization/deserialization.
///
/// This class implements all [YamlObjectMapper] methods, handling
/// YAML parsing and generation. It maintains the hierarchy: ObjectMapper →
/// AbstractXmlObjectMapper → AbstractYamlObjectMapper, allowing clean separation
/// of XML and YAML concerns.
///
/// ### Design Hierarchy
/// ```
/// ObjectMapper (JSON)
///   ↓
/// AbstractXmlObjectMapper (XML)
///   ↓
/// AbstractYamlObjectMapper (YAML)
///   ↓
/// JetsonObjectMapper (Concrete implementation)
/// ```
///
/// ### Responsibilities
/// This class handles:
/// - YAML content parsing via [YamlParser]
/// - Tree-based YAML navigation via [YamlNode]
/// - Format conversions between YAML strings and maps
/// - Support for YAML-specific features (anchors, aliases)
/// - Integration with Jetson's naming strategies and converters
///
/// ### Extension
/// Subclasses should override:
/// - [writeValueAsYaml] - Customize YAML serialization
/// - [readYamlValue] - Customize YAML deserialization
/// - Other YAML-specific methods as needed
///
/// ### Example
/// ```dart
/// class MyYamlMapper extends AbstractYamlObjectMapper {
///   @override
///   String writeValueAsYaml(Object? value) {
///     // Custom YAML serialization
///   }
///   
///   @override
///   T readYamlValue<T>(String yaml, Class<T> type) {
///     // Custom YAML deserialization
///   }
/// }
/// ```
///
/// ### Related Classes
/// - [AbstractXmlObjectMapper] - XML serialization layer
/// - [YamlObjectMapper] - Interface definition
/// - [ObjectMapper] - Base contract for all mappers
/// {@endtemplate}
abstract class AbstractYamlObjectMapper extends AbstractXmlObjectMapper implements YamlObjectMapper {
  /// A registry of serializers used to convert Dart objects into YAML nodes.
  ///
  /// Each entry maps a Dart `Class` to its corresponding [ObjectSerializer]
  /// implementation.  
  ///  
  /// When generating YAML, the system looks up the serializer for the
  /// runtime type of the object being serialized. If no serializer is
  /// registered for a type, serialization for that type cannot proceed.
  final Map<Class, ObjectSerializer> _yamlSerializers = {};

  /// A registry of deserializers used to convert YAML nodes back into Dart objects.
  ///
  /// Each entry maps a Dart `Class` to its corresponding [ObjectDeserializer]
  /// implementation.
  ///  
  /// During YAML parsing, the system uses this map to locate the correct
  /// deserializer based on the expected target type. If no deserializer is
  /// registered for a given type, deserialization for that type cannot proceed.
  final Map<Class, ObjectDeserializer> _yamlDeserializers = {};

  /// Lazily-initialized generator responsible for converting Dart objects
  /// into YAML documents.
  ///
  /// The generator orchestrates the serialization process by coordinating
  /// serializers, contexts, and YAML node building.  
  ///  
  /// Will be created on demand when serialization is first invoked.
  YamlGenerator? _yamlGenerator;

  /// The serialization context associated with the current YAML generation run.
  ///
  /// This context stores state, configuration, and utilities used during
  /// object-to-YAML conversion, such as type information, custom handlers,
  /// and active serializer lookup.
  ///
  /// It may remain `null` until serialization occurs.
  YamlSerializationContext? _yamlSerializationContext;

  /// The deserialization context associated with the current YAML parsing run.
  ///
  /// This context provides the environment needed to read YAML nodes and turn
  /// them into Dart objects. It stores reference resolution data, type lookup
  /// utilities, and custom deserializer access.
  ///
  /// It may remain `null` until deserialization is triggered.
  YamlDeserializationContext? _yamlDeserializationContext;

  /// {@macro abstract_yaml_object_mapper}
  AbstractYamlObjectMapper([super.autoRegisterStandardAdapters = true]) : super() {
    if (autoRegisterStandardAdapters) {
      // Primitives
      registerSerializer(Class<String>(), StringSerializer<YamlGenerator, YamlSerializationContext>());
      registerSerializer(Class<int>(), IntSerializer<YamlGenerator, YamlSerializationContext>());
      registerSerializer(Class<double>(), DoubleSerializer<YamlGenerator, YamlSerializationContext>());
      registerSerializer(Class<bool>(), BoolSerializer<YamlGenerator, YamlSerializationContext>());
      registerSerializer(Class<num>(), NumSerializer<YamlGenerator, YamlSerializationContext>());

      // Primitives
      registerDeserializer(Class<String>(), StringDeserializer<YamlParser, YamlDeserializationContext>());
      registerDeserializer(Class<int>(), IntDeserializer<YamlParser, YamlDeserializationContext>());
      registerDeserializer(Class<double>(), DoubleDeserializer<YamlParser, YamlDeserializationContext>());
      registerDeserializer(Class<bool>(), BoolDeserializer<YamlParser, YamlDeserializationContext>());
      registerDeserializer(Class<num>(), NumDeserializer<YamlParser, YamlDeserializationContext>());

      // Collections
      registerAdapter(Class<List>(), ListYamlSerializationAdapter());
      registerAdapter(Class<Map>(), MapYamlSerializationAdapter());
      registerAdapter(Class<Set>(), SetYamlSerializationAdapter());

      // Date/Time (from converter adapters)
      registerAdapter(Class<DateTime>(), DateTimeSerializationAdapter<YamlGenerator, YamlParser, YamlDeserializationContext, YamlSerializationContext>());
      registerAdapter(Class<ZonedDateTime>(), ZonedDateTimeSerializationAdapter<YamlGenerator, YamlParser, YamlDeserializationContext, YamlSerializationContext>());
      registerAdapter(Class<LocalDateTime>(), LocalDateTimeSerializationAdapter<YamlGenerator, YamlParser, YamlDeserializationContext, YamlSerializationContext>());
      registerAdapter(Class<LocalDate>(), LocalDateSerializationAdapter<YamlGenerator, YamlParser, YamlDeserializationContext, YamlSerializationContext>());
      registerAdapter(Class<Duration>(), DurationSerializationAdapter<YamlGenerator, YamlParser, YamlDeserializationContext, YamlSerializationContext>());

      // URIs
      registerAdapter(Class<Uri>(), UriSerializationAdapter<YamlGenerator, YamlParser, YamlDeserializationContext, YamlSerializationContext>());
      registerAdapter(Class<Url>(), UrlSerializationAdapter<YamlGenerator, YamlParser, YamlDeserializationContext, YamlSerializationContext>());
    }
  }

  /// Returns the active [YamlGenerator], creating one if needed.
  ///
  /// If no generator has been created yet, a [StringYamlGenerator] is
  /// instantiated using environment-based configuration:
  ///
  /// - `indentSize`: pulled from `ObjectMapper.INDENT_SIZE`, defaulting to `2`.
  ///
  /// The created generator is cached and reused for all subsequent YAML
  /// serialization operations.
  YamlGenerator getYamlGenerator() => _yamlGenerator ??= StringYamlGenerator(
    indentSize: getEnvironment().getPropertyAs(ObjectMapper.INDENT_SIZE, Class<int>(), 2) ?? 2
  );

  /// Returns the current [YamlSerializationContext], creating it if necessary.
  ///
  /// The serialization context stores configuration, active serializers, and
  /// supporting utilities used during YAML serialization. It is lazily
  /// initialized on first access.
  YamlSerializationContext getYamlSerializationContext() => 
    _yamlSerializationContext ?? YamlSerializationContext(this, _yamlSerializers);

  /// Returns the current [YamlDeserializationContext], creating it if needed.
  ///
  /// The deserialization context provides access to registered YAML
  /// deserializers and maintains internal state required when turning YAML
  /// nodes into Dart objects. This context is lazily instantiated.
  YamlDeserializationContext getYamlDeserializationContext() => 
    _yamlDeserializationContext ?? YamlDeserializationContext(this, _yamlDeserializers);

  /// Creates a new [YamlParser] for the given YAML content string.
  ///
  /// Each call returns a fresh [StringYamlParser] capable of parsing the
  /// provided content into a structured YAML representation.
  YamlParser getYamlParser(String content) => StringYamlParser(content);

  @override
  String writeValueAsYaml(Object? value) {
    if (value == null) return "";
    
    final generator = getYamlGenerator();
    
    return synchronized(generator, () {
      getYamlSerializationContext().serialize(value, generator);
      final yaml = generator.toString();
      generator.close();
      
      return yaml;
    });
  }

  @override
  Map<String, dynamic> writeValueAsYamlMap(Object? value) {
    if (value == null) return {};
    
    final yamlString = writeValueAsYaml(value);
    return utils.YamlParser().parse(yamlString);
  }

  @override
  T readYamlValue<T>(String yaml, Class<T> type) {
    final parser = getYamlParser(yaml);
    final result = getYamlDeserializationContext().deserialize(parser, type);
    parser.close();

    return result;
  }

  @override
  T readYamlValueFromMap<T>(Map<String, dynamic> map, Class<T> type) {
    return readJsonValueFromMap(map, type);
  }

  @override
  YamlNode readYamlContentTree(String content) {
    final parser = getYamlParser(content);
    final node = readYamlTree(parser);
    parser.close();
    return node;
  }

  @override
  YamlNode readYamlTree(YamlParser parser) {
    parser.nextToken();
    
    if (parser.getCurrentToken() == YamlToken.MAPPING_START) {
      final map = <String, YamlNode>{};
      
      while (parser.nextToken()) {
        if (parser.getCurrentToken() == YamlToken.MAPPING_END) {
          break;
        }
        
        if (parser.getCurrentToken() == YamlToken.KEY) {
          final key = parser.getCurrentValue()?.toString() ?? 'unknown';
          parser.nextToken(); // Move to value
          map[key] = readYamlTree(parser);
        }
      }
      
      return YamlMappingNode(map);
    } else if (parser.getCurrentToken() == YamlToken.SEQUENCE_START) {
      final list = <YamlNode>[];
      
      while (parser.nextToken()) {
        if (parser.getCurrentToken() == YamlToken.SEQUENCE_END) {
          break;
        }
        
        list.add(readYamlTree(parser));
      }
      
      return YamlSequenceNode(list);
    } else if (parser.getCurrentToken() == YamlToken.SCALAR) {
      return YamlScalarNode(parser.getCurrentValue()?.toString() ?? '');
    }
    
    // If we're already at a scalar (e.g. recursive call)
    if (parser.getCurrentToken() == YamlToken.SCALAR) {
      return YamlScalarNode(parser.getCurrentValue()?.toString() ?? '');
    }
    
    throw IllegalObjectTokenException('Unexpected YAML token: ${parser.getCurrentToken()}');
  }

  @override
  void registerAdapter(Class type, ObjectSerializationAdapter adapter) {
    return synchronized(this, () {
      if (adapter.supports(getYamlDeserializationContext())) {
        _yamlDeserializers.put(type, adapter);
        _yamlSerializers.put(type, adapter);
      }

      super.registerAdapter(type, adapter);
    });
  }

  @override
  void registerDeserializer(Class type, ObjectDeserializer deserializer) {
    return synchronized(this, () {
      if (deserializer.supports(getYamlDeserializationContext())) {
        _yamlDeserializers.put(type, deserializer);
      }

      super.registerDeserializer(type, deserializer);
    });
  }

  @override
  void registerSerializer(Class type, ObjectSerializer serializer) {
    return synchronized(this, () {
      if (serializer.supportsContext(getYamlSerializationContext())) {
        _yamlSerializers.put(type, serializer);
      }

      super.registerSerializer(type, serializer);
    });
  }

  @override
  void setSerializationContext(SerializationContext context) {
    super.setSerializationContext(context);
    if (context is YamlSerializationContext) {
      _yamlSerializationContext = context;
    }
  }

  @override
  void setDeserializationContext(DeserializationContext context) {
    super.setDeserializationContext(context);
    if (context is YamlDeserializationContext) {
      _yamlDeserializationContext = context;
    }
  }

  @override
  void setYamlGenerator(YamlGenerator generator) {
    _yamlGenerator = generator;
  }
}