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

import '../base/object_mapper_type.dart';
import '../naming_strategy/naming_strategies.dart';
import '../naming_strategy/naming_strategy.dart';
import 'abstract_aware_object_mapper.dart';

/// {@template jetleaf_jetson_object_mapper}
/// A high-level, multi-format Jetson object mapper with integrated support for
/// JSON, XML, and YAML serialization and deserialization.
///
/// `JetsonObjectMapper` is the primary, production-grade object mapper used in
/// the Jetleaf framework. It builds on top of [AbstractAwareObjectMapper],
/// providing:
///
/// * **Format-aware** read/write operations (JSON, XML, YAML)
/// * **Feature flags** for customizing serialization behavior
/// * **Naming strategies** for transforming Dart field names
/// * **Auto-registration** of Jetson serializers, deserializers, and adapters
/// * **ApplicationContext, Environment, and ConversionService awareness**
///
/// It is the same mapper used internally by Jetleaf’s HTTP message converters,
/// DI container integrations, and serialization infrastructure.
///
///
/// ### 🌐 Multi-Format Serialization
///
/// All read and write APIs accept an optional [ObjectMapperType] parameter:
///
/// ```dart
/// mapper.writeValueAsString(user, ObjectMapperType.XML);
/// mapper.readValue<User>(jsonString, Class<User>(), ObjectMapperType.JSON);
/// mapper.writeValueAsMap(user, ObjectMapperType.YAML);
/// ```
///
/// This makes the mapper a unified entry point for **all supported formats**,
/// without requiring users to instantiate separate specialized mappers.
///
///
/// ### 🔧 Configurable Serialization Features
///
/// Features are stored as simple string identifiers using `_features`.
/// They can be toggled dynamically at runtime:
///
/// ```dart
/// mapper.enableFeature(SerializationFeature.INDENT_OUTPUT.name);
/// mapper.disableFeature("CUSTOM_RULE");
/// if (mapper.isFeatureEnabled("FOO")) { /* ... */ }
/// ```
///
/// This allows higher-level modules or libraries to plug in optional behaviors
/// without modifying the mapper itself.
///
///
/// ### 🧩 Naming Strategy Support
///
/// The mapper uses a [NamingStrategy] to convert Dart field names to
/// serialized keys. By default, it uses:
///
/// ```dart
/// SnakeCaseNamingStrategy()
/// ```
///
/// but can be replaced easily:
///
/// ```dart
/// mapper.setNamingStrategy(CamelCaseNamingStrategy());
/// ```
///
/// Naming strategies apply uniformly across JSON, XML, and YAML.
///
///
/// ### 🔁 Application-Aware Behavior
///
/// As a subclass of [AbstractAwareObjectMapper], this mapper:
///
/// * Discovers all serializers, deserializers, generators, naming strategies,
///   adapters, and contexts via the Jetleaf `ApplicationContext`.
/// * Registers everything during `onReady()` using Jetleaf's annotation-based
///   ordering model.
/// * Automatically wires JSON, XML, and YAML generators if available.
/// * Inherits its [Environment] and [ConversionService] from the application
///   context unless manually overridden.
///
/// This makes the mapper fully integrated with Jetleaf’s inversion-of-control
/// and configuration system.
///
///
/// ### 🧱 Example: Basic JSON Use
///
/// ```dart
/// final mapper = JetsonObjectMapper();
///
/// final user = mapper.readValue<User>('{"name":"Alice"}', Class<User>());
/// final json = mapper.writeValueAsString(user);
/// ```
///
///
/// ### 🧱 Example: XML + YAML Use
///
/// ```dart
/// final xml = mapper.writeValueAsString(order, ObjectMapperType.XML);
/// final yaml = mapper.writeValueAsString(order, ObjectMapperType.YAML);
///
/// final parsed = mapper.readValue<Order>(xml, Class<Order>(), ObjectMapperType.XML);
/// ```
///
///
/// ### 📦 Integration
///
/// This mapper is automatically used by:
///
/// * `Jetson2HttpMessageConverter` (JSON)
/// * `Jetson2XmlHttpMessageConverter` (XML)
/// * `Jetson2YamlHttpMessageConverter` (YAML)
///
/// making it the central serialization component of Jetleaf’s web layer.
///
///
/// {@endtemplate}
final class JetsonObjectMapper extends AbstractAwareObjectMapper {
  /// Tracks all currently **enabled features** for serialization and deserialization.
  ///
  /// Features control optional behaviors such as pretty printing, custom formatting,
  /// or other serialization flags. Use [enableFeature] and [disableFeature] to
  /// modify the set at runtime.
  ///
  /// ### Example
  /// ```dart
  /// objectMapper.enableFeature(SerializationFeature.INDENT_OUTPUT.name);
  /// print(objectMapper.isFeatureEnabled(SerializationFeature.INDENT_OUTPUT.name)); // true
  /// ```
  final Set<String> _features = {};

  /// The [NamingStrategy] used to convert Dart field names to JSON property names.
  ///
  /// Defaults to [SnakeCaseNamingStrategy]. Can be customized using
  /// [setNamingStrategy].
  ///
  /// ### Example
  /// ```dart
  /// objectMapper.setNamingStrategy(CamelCaseNamingStrategy());
  /// ```
  NamingStrategy _namingStrategy = SnakeCaseNamingStrategy();

  /// {@macro jetleaf_jetson_object_mapper}
  ///
  /// Creates a new [JetsonObjectMapper] and registers all standard
  /// serializers and deserializers.
  JetsonObjectMapper([super.autoRegisterStandardAdapters]);

  @override
  void disableFeature(String featureName) {
    _features.remove(featureName);
  }

  @override
  void enableFeature(String featureName) {
    _features.add(featureName);
  }

  @override
  NamingStrategy getNamingStrategy() => _namingStrategy;

  @override
  bool isFeatureEnabled(String featureName) => _features.contains(featureName);

  @override
  T readValue<T>(String data, Class<T> type, [ObjectMapperType mapWith = ObjectMapperType.JSON]) {
    if (mapWith == ObjectMapperType.XML) {
      return readXmlValue(data, type);
    }

    if (mapWith == ObjectMapperType.YAML) {
      return readYamlValue(data, type);
    }

    return readJsonValue(data, type);
  }

  @override
  T readValueFromMap<T>(Map<String, dynamic> map, Class<T> type, [ObjectMapperType mapWith = ObjectMapperType.JSON]) {
    if (mapWith == ObjectMapperType.XML) {
      return readXmlValueFromMap(map, type);
    }

    if (mapWith == ObjectMapperType.YAML) {
      return readYamlValueFromMap(map, type);
    }

    return readJsonValueFromMap(map, type);
  }

  @override
  void setNamingStrategy(NamingStrategy strategy) {
    _namingStrategy = strategy;
  }

  @override
  Map<String, dynamic> writeValueAsMap(Object? value, [ObjectMapperType mapWith = ObjectMapperType.JSON]) {
    if (value == null) return {};
    
    if (mapWith == ObjectMapperType.XML) {
      return writeValueAsXmlMap(value);
    }

    if (mapWith == ObjectMapperType.YAML) {
      return writeValueAsYamlMap(value);
    }

    return writeValueAsJsonMap(value);
  }

  @override
  String writeValueAsString(Object? value, [ObjectMapperType mapWith = ObjectMapperType.JSON]) {
    if (value == null) return "";
    
    if (mapWith == ObjectMapperType.XML) {
      return writeValueAsXml(value);
    }

    if (mapWith == ObjectMapperType.YAML) {
      return writeValueAsYaml(value);
    }

    return writeValueAsJson(value);
  }
}