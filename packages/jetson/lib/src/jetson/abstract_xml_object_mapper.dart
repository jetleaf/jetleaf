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
import '../xml/adapter/list_xml_serialization_adapter.dart';
import '../xml/adapter/map_xml_serialization_adapter.dart';
import '../xml/adapter/set_xml_serialization_adapter.dart';
import '../xml/node/xml_element_node.dart';
import '../xml/node/xml_node.dart';
import '../xml/node/xml_text_node.dart';
import '../xml/parser/xml_parser.dart';
import '../xml/xml_object_mapper.dart';
import '../xml/xml_token.dart';
import '../xml/generator/string_xml_generator.dart';
import '../xml/generator/xml_generator.dart';
import '../xml/context/xml_serialization_context.dart';
import '../xml/context/xml_deserialization_context.dart';
import '../xml/parser/string_xml_parser.dart';
import '../serialization/serialization_context.dart';
import '../serialization/deserialization_context.dart';
import '../serialization/serialization_feature.dart';
import 'abstract_json_object_mapper.dart';

/// {@template abstract_xml_object_mapper}
/// Abstract base implementation of [XmlObjectMapper] providing core XML
/// serialization and deserialization functionality.
///
/// This class implements all [XmlObjectMapper] methods using XML parsing
/// and serialization. Subclasses provide the actual implementation details for
/// parsing XML content and building objects from XML nodes.
///
/// ### Design
/// - Handles XML serialization and deserialization contract
/// - Delegates format-specific XML processing to subclasses
/// - Reuses [ObjectMapper] methods for JSON operations where applicable
/// - Provides XML-specific entry points without coupling to implementation
///
/// ### Responsibilities
/// This class handles:
/// - XML content parsing and tree traversal
/// - Tree-based XML navigation via [XmlNode]
/// - Format conversions between XML strings and maps
/// - Integration with Jetson's naming strategies and converters
///
/// ### Extension
/// Subclasses should override:
/// - [writeValueAsXml] - Custom XML serialization
/// - [readXmlValue] - Custom XML deserialization
/// - [readXmlTree] - XML tree parsing implementation
/// - Other methods as needed for custom XML processing
///
/// ### Example
/// ```dart
/// class MyXmlMapper extends AbstractXmlObjectMapper {
///   @override
///   String writeValueAsXml(Object? value) {
///     // Custom XML serialization
///   }
/// }
/// ```
///
/// ### Related Classes
/// - [AbstractYamlObjectMapper] - YAML extension
/// - [XmlObjectMapper] - Interface definition
/// - [ObjectMapper] - Base mapping contract
/// {@endtemplate}
abstract class AbstractXmlObjectMapper extends AbstractJsonObjectMapper implements XmlObjectMapper {
  /// A registry of XML serializers keyed by the Dart [Class] they support.
  ///
  /// Each entry defines how instances of a given type are converted
  /// into XML nodes during serialization.  
  ///
  /// Custom serializers may be added or replaced at runtime.
  final Map<Class, ObjectSerializer> _xmlSerializers = {};

  /// A registry of XML deserializers mapped to the Dart [Class] they can produce.
  ///
  /// These deserializers are responsible for constructing Dart objects from
  /// parsed XML elements during deserialization.
  ///
  /// Custom deserializers may be dynamically registered or overridden.
  final Map<Class, ObjectDeserializer> _xmlDeserializers = {};
  
  /// Lazily initialized XML generator used to convert Dart objects into XML.
  ///
  /// Created on first access, then cached and reused for subsequent
  /// serialization operations. The generator defines formatting and output
  /// strategies for XML emission.
  XmlGenerator? _xmlGenerator;

  /// Lazily initialized context used for XML serialization.
  ///
  /// The context stores configuration, registered serializers, and supporting
  /// metadata needed during the transformation of Dart objects into XML.
  XmlSerializationContext? _xmlSerializationContext;

  /// Lazily initialized context used for XML deserialization.
  ///
  /// This context provides access to the registered deserializers and maintains
  /// state needed when converting XML nodes into Dart objects.
  XmlDeserializationContext? _xmlDeserializationContext;

  /// {@macro abstract_xml_object_mapper}
  AbstractXmlObjectMapper([super.autoRegisterStandardAdapters = true]) : super() {
    if (autoRegisterStandardAdapters) {
      // Primitives
      registerSerializer(Class<String>(), StringSerializer<XmlGenerator, XmlSerializationContext>());
      registerSerializer(Class<int>(), IntSerializer<XmlGenerator, XmlSerializationContext>());
      registerSerializer(Class<double>(), DoubleSerializer<XmlGenerator, XmlSerializationContext>());
      registerSerializer(Class<bool>(), BoolSerializer<XmlGenerator, XmlSerializationContext>());
      registerSerializer(Class<num>(), NumSerializer<XmlGenerator, XmlSerializationContext>());

      // Primitives
      registerDeserializer(Class<String>(), StringDeserializer<XmlParser, XmlDeserializationContext>());
      registerDeserializer(Class<int>(), IntDeserializer<XmlParser, XmlDeserializationContext>());
      registerDeserializer(Class<double>(), DoubleDeserializer<XmlParser, XmlDeserializationContext>());
      registerDeserializer(Class<bool>(), BoolDeserializer<XmlParser, XmlDeserializationContext>());
      registerDeserializer(Class<num>(), NumDeserializer<XmlParser, XmlDeserializationContext>());

      // Collections
      registerAdapter(Class<List>(), ListXmlSerializationAdapter());
      registerAdapter(Class<Map>(), MapXmlSerializationAdapter());
      registerAdapter(Class<Set>(), SetXmlSerializationAdapter());

      // Date/Time (from converter adapters)
      registerAdapter(Class<DateTime>(), DateTimeSerializationAdapter<XmlGenerator, XmlParser, XmlDeserializationContext, XmlSerializationContext>());
      registerAdapter(Class<ZonedDateTime>(), ZonedDateTimeSerializationAdapter<XmlGenerator, XmlParser, XmlDeserializationContext, XmlSerializationContext>());
      registerAdapter(Class<LocalDateTime>(), LocalDateTimeSerializationAdapter<XmlGenerator, XmlParser, XmlDeserializationContext, XmlSerializationContext>());
      registerAdapter(Class<LocalDate>(), LocalDateSerializationAdapter<XmlGenerator, XmlParser, XmlDeserializationContext, XmlSerializationContext>());
      registerAdapter(Class<Duration>(), DurationSerializationAdapter<XmlGenerator, XmlParser, XmlDeserializationContext, XmlSerializationContext>());

      // URIs
      registerAdapter(Class<Uri>(), UriSerializationAdapter<XmlGenerator, XmlParser, XmlDeserializationContext, XmlSerializationContext>());
      registerAdapter(Class<Url>(), UrlSerializationAdapter<XmlGenerator, XmlParser, XmlDeserializationContext, XmlSerializationContext>());
    }
  }

  /// Returns the active [XmlGenerator], creating one if necessary.
  ///
  /// If no XML generator has been instantiated yet, this method constructs a
  /// [StringXmlGenerator] configured using the current environment:
  ///
  /// - `pretty`: enabled when the `SerializationFeature.INDENT_OUTPUT` feature
  ///   flag is active.
  /// - `indentSize`: resolved from `ObjectMapper.INDENT_SIZE`, defaulting to `2`
  ///   when not set.
  ///
  /// The created generator is cached and reused for subsequent XML serialization
  /// operations.
  XmlGenerator getXmlGenerator() => _xmlGenerator ??= StringXmlGenerator(
    pretty: isFeatureEnabled(SerializationFeature.INDENT_OUTPUT.name),
    indentSize: getEnvironment().getPropertyAs(ObjectMapper.INDENT_SIZE, Class<int>(), 2) ?? 2
  );

  /// Returns the active [XmlSerializationContext], creating it lazily if needed.
  ///
  /// The serialization context supplies configuration, the registered XML
  /// serializers, and utilities required for converting Dart objects into XML
  /// structures.
  ///
  /// A new context is only created on first access.
  XmlSerializationContext getXmlSerializationContext() => 
    _xmlSerializationContext ?? XmlSerializationContext(this, _xmlSerializers);

  /// Returns the active [XmlDeserializationContext], creating it lazily if necessary.
  ///
  /// The deserialization context maintains access to registered XML
  /// deserializers and the state needed to convert XML nodes into Dart objects.
  ///
  /// A new context is instantiated upon first request.
  XmlDeserializationContext getXmlDeserializationContext() =>
    _xmlDeserializationContext ?? XmlDeserializationContext(this, _xmlDeserializers);

  /// Creates and returns a new [XmlParser] for the provided XML content string.
  ///
  /// Each invocation produces a fresh [StringXmlParser] capable of parsing the
  /// given XML text into a structured representation suitable for
  /// deserialization.
  XmlParser getXmlParser(String content) => StringXmlParser(content);

  @override
  String writeValueAsXml(Object? value) {
    if (value == null) return "";
    
    final generator = getXmlGenerator();
    
    return synchronized(generator, () {
      final className = value.getClass().getName();
      generator.writeStartElement(className);
      getXmlSerializationContext().serialize(value, generator);
      generator.writeEndElement();
      
      final xml = generator.toString();
      generator.close();
      return xml;
    });
  }

  @override
  Map<String, dynamic> writeValueAsXmlMap(Object? value) {
    if (value == null) return {};
    
    final xmlString = writeValueAsXml(value);
    return utils.XmlParser().parse(xmlString);
  }

  @override
  T readXmlValue<T>(String xml, Class<T> type) {
    final parser = getXmlParser(xml);
    final result = getXmlDeserializationContext().deserialize(parser, type);
    parser.close();
    return result;
  }

  @override
  T readXmlValueFromMap<T>(Map<String, dynamic> map, Class<T> type) {
    return readJsonValueFromMap(map, type);
  }

  @override
  XmlNode readXmlContentTree(String content) {
    final parser = getXmlParser(content);
    final node = readXmlTree(parser);
    parser.close();
    return node;
  }

  @override
  XmlNode readXmlTree(XmlParser parser) {
    parser.nextToken();
    
    if (parser.getCurrentToken() == XmlToken.START_ELEMENT) {
      final name = parser.getElementName() ?? 'root';
      final attributes = parser.getAttributes();
      final children = <XmlNode>[];
      
      while (parser.nextToken()) {
        if (parser.getCurrentToken() == XmlToken.END_ELEMENT) {
          break;
        }
        
        if (parser.getCurrentToken() == XmlToken.TEXT) {
          final text = parser.getCurrentValue()?.toString();
          if (text != null && text.trim().isNotEmpty) {
            children.add(XmlTextNode(text));
          }
        } else if (parser.getCurrentToken() == XmlToken.START_ELEMENT) {
          children.add(readXmlTree(parser));
        }
      }
      
      return XmlElementNode(name, attributes, children);
    } else if (parser.getCurrentToken() == XmlToken.TEXT) {
      return XmlTextNode(parser.getCurrentValue()?.toString() ?? '');
    }
    
    throw IllegalObjectTokenException('Unexpected XML token: ${parser.getCurrentToken()}');
  }

  @override
  void registerAdapter(Class type, ObjectSerializationAdapter adapter) {
    return synchronized(this, () {
      if (adapter.supports(getXmlDeserializationContext())) {
        _xmlDeserializers.put(type, adapter);
        _xmlSerializers.put(type, adapter);
      }

      super.registerAdapter(type, adapter);
    });
  }

  @override
  void registerDeserializer(Class type, ObjectDeserializer deserializer) {
    return synchronized(this, () {
      if (deserializer.supports(getXmlDeserializationContext())) {
        _xmlDeserializers.put(type, deserializer);
      }

      super.registerDeserializer(type, deserializer);
    });
  }

  @override
  void registerSerializer(Class type, ObjectSerializer serializer) {
    return synchronized(this, () {
      if (serializer.supportsContext(getXmlSerializationContext())) {
        _xmlSerializers.put(type, serializer);
      }

      super.registerSerializer(type, serializer);
    });
  }

  @override
  void setSerializationContext(SerializationContext context) {
    super.setSerializationContext(context);
    if (context is XmlSerializationContext) {
      _xmlSerializationContext = context;
    }
  }

  @override
  void setDeserializationContext(DeserializationContext context) {
    super.setDeserializationContext(context);
    if (context is XmlDeserializationContext) {
      _xmlDeserializationContext = context;
    }
  }

  @override
  void setXmlGenerator(XmlGenerator generator) {
    _xmlGenerator = generator;
  }
}