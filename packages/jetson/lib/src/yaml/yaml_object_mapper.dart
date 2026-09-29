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
import 'generator/yaml_generator.dart';
import 'node/yaml_node.dart';
import 'parser/yaml_parser.dart';

/// {@template yaml_object_mapper}
/// Extends the [ObjectMapper] interface to provide specialized support for
/// **YAML serialization and deserialization**.
///
/// The [YamlObjectMapper] builds upon the base [ObjectMapper] contract by adding
/// YAML-specific methods for reading and writing Dart objects in YAML format.
/// It maintains full compatibility with the standard JSON mapper interface
/// while providing YAML-focused operations.
///
/// ### Core Methods
/// - **[readYamlValue]** - Deserializes YAML string to Dart object
/// - **[readYamlValueFromMap]** - Deserializes YAML map to Dart object
/// - **[readYamlTree]** - Parses YAML string to [YamlNode] tree
/// - **[writeValueAsYaml]** - Serializes Dart object to YAML string
/// - **[writeValueAsYamlMap]** - Serializes Dart object to YAML map
///
/// ### Design Notes
/// - Inherits all JSON serialization methods from [ObjectMapper]
/// - YAML-specific methods follow the same naming patterns as JSON counterparts
/// - Supports both tree-based (DOM) and streaming YAML processing
/// - Integrates with Jetson's naming strategies and converters
/// - Supports YAML-specific features like anchors, aliases, and multi-line strings
///
/// ### Example
/// ```dart
/// final mapper = YamlObjectMapper();
///
/// // Serialization
/// final user = User(id: 1, name: 'Alice', email: 'alice@example.com');
/// final yaml = mapper.writeValueAsYaml(user);
/// // Output:
/// // user:
/// //   id: 1
/// //   name: Alice
/// //   email: alice@example.com
///
/// // Deserialization
/// final restored = mapper.readYamlValue<User>(yaml, Class<User>());
/// ```
///
/// ### Related Interfaces
/// - [ObjectMapper] - Base serialization/deserialization contract
/// - [XmlObjectMapper] - XML-specific operations
/// - [YamlNode] - YAML DOM tree representation
/// {@endtemplate}
abstract interface class YamlObjectMapper implements ObjectMapper {
  // ─────────────────────────────────────────────────────────────
  // YAML Serialization
  // ─────────────────────────────────────────────────────────────

  /// Serializes a Dart object into a YAML string.
  ///
  /// Converts the given [value] into a YAML-encoded string using the current
  /// [NamingStrategy], annotations, and registered serializers.
  ///
  /// ### Example
  /// ```dart
  /// final yaml = mapper.writeValueAsYaml(user);
  /// print(yaml);
  /// // user:
  /// //   id: 1
  /// //   name: Alice
  /// ```
  ///
  /// ### Notes
  /// - Respects YAML-specific naming conventions
  /// - Handles nested objects, collections, and custom types
  /// - Supports YAML features like anchors and aliases for deduplication
  /// - Produces human-readable, indented output by default
  String writeValueAsYaml(Object? value);

  /// Serializes a Dart object into a YAML `Map<String, dynamic>` representation.
  ///
  /// This method traverses all serializable fields of [value] and produces
  /// a nested map structure compatible with YAML generation.
  ///
  /// ### Example
  /// ```dart
  /// final map = mapper.writeValueAsYamlMap(user);
  /// print(map['user']['id']); // 1
  /// ```
  Map<String, dynamic> writeValueAsYamlMap(Object? value);

  // ─────────────────────────────────────────────────────────────
  // YAML Deserialization
  // ─────────────────────────────────────────────────────────────

  /// Deserializes a YAML string into an object of type [T].
  ///
  /// The YAML is parsed into an intermediate [YamlNode] tree, which is then
  /// mapped to a Dart object using reflection and configured converters.
  ///
  /// ### Example
  /// ```dart
  /// final user = mapper.readYamlValue<User>(
  ///   'user:\n  id: 1\n  name: Alice',
  ///   Class<User>()
  /// );
  /// ```
  ///
  /// ### Error Handling
  /// Throws an exception if:
  /// - The YAML is malformed
  /// - No deserializer found for type [T]
  /// - Required fields are missing
  T readYamlValue<T>(String yaml, Class<T> type);

  /// Deserializes a YAML-compatible map into an instance of type [T].
  ///
  /// This bypasses YAML parsing and directly performs field mapping from
  /// a nested [Map<String, dynamic>] to a Dart object.
  ///
  /// ### Example
  /// ```dart
  /// final user = mapper.readYamlValueFromMap<User>({
  ///   'user': {
  ///     'id': 1,
  ///     'name': 'Alice'
  ///   }
  /// }, Class<User>());
  /// ```
  T readYamlValueFromMap<T>(Map<String, dynamic> map, Class<T> type);

  // ─────────────────────────────────────────────────────────────
  // YAML Tree Operations
  // ─────────────────────────────────────────────────────────────

  /// Parses the given YAML [content] string into a [YamlNode] tree.
  ///
  /// This allows you to traverse or inspect YAML data without binding it
  /// to a specific object type.
  ///
  /// ### Example
  /// ```dart
  /// final tree = mapper.readYamlContentTree('root:\n  child: value');
  /// print(tree.get('root').get('child').getText()); // "value"
  /// ```
  ///
  /// ### Notes
  /// - Returns the root [YamlNode] of the parsed document
  /// - Supports navigation via [YamlNode] methods
  /// - Preserves mapping keys and scalar values
  /// - Handles YAML-specific features like anchors and aliases
  YamlNode readYamlContentTree(String content);

  /// Reads and parses YAML content from the given [YamlParser] into a [YamlNode] tree.
  ///
  /// Useful when working with streaming or preconfigured YAML parsers.
  /// The returned tree can be navigated like a DOM.
  ///
  /// ### Example
  /// ```dart
  /// final parser = mapper.createYamlParser(yamlString);
  /// final tree = mapper.readYamlTree(parser);
  /// ```
  ///
  /// ### See also
  /// - [YamlParser]
  /// - [readYamlContentTree]
  YamlNode readYamlTree(YamlParser parser);

  /// Sets the active [YamlGenerator] used for serializing Dart objects to YAML.
  ///
  /// The provided [generator] will be used by the mapper for all subsequent
  /// serialization operations. This allows users to inject a custom generator
  /// implementation, e.g., one that writes to a `StringBuffer`, a file, or
  /// a network stream.
  ///
  /// If not explicitly set, the mapper lazily creates a default [StringYamlGenerator]
  /// via [getYamlGenerator].
  ///
  /// ### Example
  /// ```dart
  /// final customGenerator = MyCustomYamlGenerator();
  /// objectMapper.setYamlGenerator(customGenerator);
  /// final json = objectMapper.writeValueAsString(myObject);
  /// ```
  ///
  /// ### Notes
  /// - Replacing the generator at runtime affects all threads that share this
  ///   mapper instance, so it should be done carefully in concurrent contexts.
  /// - Any features like `SerializationFeature.INDENT_OUTPUT` will still
  ///   apply to the new generator.
  void setYamlGenerator(YamlGenerator generator);
}