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
import 'generator/xml_generator.dart';
import 'node/xml_node.dart';
import 'parser/xml_parser.dart';

/// {@template xml_object_mapper}
/// Extends the [ObjectMapper] interface to provide specialized support for
/// **XML serialization and deserialization**.
///
/// The [XmlObjectMapper] builds upon the base [ObjectMapper] contract by adding
/// XML-specific methods for reading and writing Dart objects in XML format.
/// It maintains full compatibility with the standard JSON mapper interface
/// while providing XML-focused operations.
///
/// ### Core Methods
/// - **[readXmlValue]** - Deserializes XML string to Dart object
/// - **[readXmlValueFromMap]** - Deserializes XML map to Dart object
/// - **[readXmlTree]** - Parses XML string to [XmlNode] tree
/// - **[writeValueAsXml]** - Serializes Dart object to XML string
/// - **[writeValueAsXmlMap]** - Serializes Dart object to XML map
///
/// ### Design Notes
/// - Inherits all JSON serialization methods from [ObjectMapper]
/// - XML-specific methods follow the same naming patterns as JSON counterparts
/// - Supports both tree-based (DOM) and streaming (SAX-like) XML processing
/// - Integrates with Jetson's naming strategies and converters
///
/// ### Example
/// ```dart
/// final mapper = XmlObjectMapper();
///
/// // Serialization
/// final user = User(id: 1, name: 'Alice');
/// final xml = mapper.writeValueAsXml(user);
/// // Output: <user><id>1</id><name>Alice</name></user>
///
/// // Deserialization
/// final restored = mapper.readXmlValue<User>(xml, Class<User>());
/// ```
///
/// ### Related Interfaces
/// - [ObjectMapper] - Base serialization/deserialization contract
/// - [YamlObjectMapper] - YAML-specific operations
/// - [XmlNode] - XML DOM tree representation
/// {@endtemplate}
abstract interface class XmlObjectMapper implements ObjectMapper {
  // ─────────────────────────────────────────────────────────────
  // XML Serialization
  // ─────────────────────────────────────────────────────────────

  /// Serializes a Dart object into an XML string.
  ///
  /// Converts the given [value] into an XML-encoded string using the current
  /// [NamingStrategy], annotations, and registered serializers.
  ///
  /// ### Example
  /// ```dart
  /// final xml = mapper.writeValueAsXml(user);
  /// print(xml);
  /// // <user><id>1</id><name>Alice</name></user>
  /// ```
  ///
  /// ### Notes
  /// - Respects XML-specific naming conventions
  /// - Handles nested objects, collections, and custom types
  /// - Applies encoding and XML declaration as configured
  String writeValueAsXml(Object? value);

  /// Serializes a Dart object into an XML `Map<String, dynamic>` representation.
  ///
  /// This method traverses all serializable fields of [value] and produces
  /// a nested map structure compatible with XML generation.
  ///
  /// ### Example
  /// ```dart
  /// final map = mapper.writeValueAsXmlMap(user);
  /// print(map['user']['id']); // 1
  /// ```
  Map<String, dynamic> writeValueAsXmlMap(Object? value);

  // ─────────────────────────────────────────────────────────────
  // XML Deserialization
  // ─────────────────────────────────────────────────────────────

  /// Deserializes an XML string into an object of type [T].
  ///
  /// The XML is parsed into an intermediate [XmlNode] tree, which is then
  /// mapped to a Dart object using reflection and configured converters.
  ///
  /// ### Example
  /// ```dart
  /// final user = mapper.readXmlValue<User>(
  ///   '<user><id>1</id><name>Alice</name></user>',
  ///   Class<User>()
  /// );
  /// ```
  ///
  /// ### Error Handling
  /// Throws an exception if:
  /// - The XML is malformed
  /// - No deserializer found for type [T]
  T readXmlValue<T>(String xml, Class<T> type);

  /// Deserializes an XML-compatible map into an instance of type [T].
  ///
  /// This bypasses XML parsing and directly performs field mapping from
  /// a nested [Map<String, dynamic>] to a Dart object.
  ///
  /// ### Example
  /// ```dart
  /// final user = mapper.readXmlValueFromMap<User>({
  ///   'user': {
  ///     'id': 1,
  ///     'name': 'Alice'
  ///   }
  /// }, Class<User>());
  /// ```
  T readXmlValueFromMap<T>(Map<String, dynamic> map, Class<T> type);

  // ─────────────────────────────────────────────────────────────
  // XML Tree Operations
  // ─────────────────────────────────────────────────────────────

  /// Parses the given XML [content] string into an [XmlNode] tree.
  ///
  /// This allows you to traverse or inspect XML data without binding it
  /// to a specific object type.
  ///
  /// ### Example
  /// ```dart
  /// final tree = mapper.readXmlContentTree('<root><child>value</child></root>');
  /// print(tree.get('child').getText()); // "value"
  /// ```
  ///
  /// ### Notes
  /// - Returns the root [XmlNode] of the parsed document
  /// - Supports navigation via [XmlNode] methods
  /// - Preserves element attributes and text content
  XmlNode readXmlContentTree(String content);

  /// Reads and parses XML content from the given [XmlParser] into an [XmlNode] tree.
  ///
  /// Useful when working with streaming or preconfigured XML parsers.
  /// The returned tree can be navigated like a DOM.
  ///
  /// ### Example
  /// ```dart
  /// final parser = mapper.createXmlParser(xmlString);
  /// final tree = mapper.readXmlTree(parser);
  /// ```
  ///
  /// ### See also
  /// - [XmlParser]
  /// - [readXmlContentTree]
  XmlNode readXmlTree(XmlParser parser);

  /// Sets the active [XmlGenerator] used for serializing Dart objects to XML.
  ///
  /// The provided [generatorr] will be used by the mapper for all subsequent
  /// serialization operations. This allows users to inject a custom generator
  /// implementation, e.g., one that writes to a `StringBuffer`, a file, or
  /// a network stream.
  ///
  /// If not explicitly set, the mapper lazily creates a default [StringXmlGenerator]
  /// via [getXmlGenerator].
  ///
  /// ### Example
  /// ```dart
  /// final customGenerator = MyCustomXmlGenerator();
  /// objectMapper.setXmlGenerator(customGenerator);
  /// final json = objectMapper.writeValueAsString(myObject);
  /// ```
  ///
  /// ### Notes
  /// - Replacing the generator at runtime affects all threads that share this
  ///   mapper instance, so it should be done carefully in concurrent contexts.
  /// - Any features like `SerializationFeature.INDENT_OUTPUT` will still
  ///   apply to the new generator.
  void setXmlGenerator(XmlGenerator generatorr);
}