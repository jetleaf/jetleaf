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
import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';

import '../json/adapter/json_adapter.dart';
import '../json/generator/json_generator.dart';
import '../naming_strategy/naming_strategy.dart';
import '../serialization/deserialization_context.dart';
import '../serialization/object_deserializer.dart';
import '../serialization/object_serializer.dart';
import '../serialization/serialization_context.dart';
import '../xml/generator/xml_generator.dart';
import '../yaml/generator/yaml_generator.dart';
import 'abstract_yaml_object_mapper.dart';

/// {@template abstract_aware_object_mapper}
/// An enhanced, application-aware Jetson object mapper that integrates
/// seamlessly with the Jetleaf dependency injection, environment system,
/// and conversion infrastructure.
///
/// `AbstractAwareObjectMapper` extends [AbstractYamlObjectMapper] with
/// awareness of:
///
/// * **ApplicationContext** – used to discover and register serializers,
///   deserializers, adapters, naming strategies, and generator implementations.
/// * **ConversionService** – automatically injected unless explicitly set,
///   enabling cross-type conversions during serialization and deserialization.
/// * **Environment** – provides access to configuration properties and
///   environment variables, injected from the application context if not
///   manually provided.
/// * **Pod lifecycle** – implements [InitializingPod], allowing it to register
///   Jetson components during startup.
/// * **Context-aware generators** – automatically configures JSON, XML,
///   and YAML generators if they exist in the application context.
///
///
/// ### 🔧 Responsibilities
///
/// This mapper acts as a fully-managed, dependency-aware object mapper inside
/// the Jetleaf ecosystem. During application bootstrap it:
///
/// 1. Discovers all registered:
///    * [ObjectSerializer]s  
///    * [ObjectDeserializer]s  
///    * [JsonSerializationAdapter]s  
/// 2. Orders them using Jetleaf’s annotation-based ordering system.
/// 3. Registers them into the mapper.
/// 4. Automatically wires available generators:
///    * [JsonGenerator]  
///    * [XmlGenerator]  
///    * [YamlGenerator]
/// 5. Applies discovered:
///    * [NamingStrategy]
///    * [DeserializationContext]
///    * [SerializationContext]
/// 6. Lazily initializes or injects:
///    * [ConversionService]
///    * [Environment]
///
///
/// ### 🔁 Initialization Lifecycle
///
/// When Jetleaf constructs this mapper:
///
/// 1. **ApplicationContext is injected** via [setApplicationContext].
/// 2. If not manually set:
///    * The mapper receives the application’s global [ConversionService].
///    * The mapper inherits the global [Environment].
/// 3. On `onReady()`:
///    * All mappers, adapters, contexts, generators, and strategies are
///      registered in a deterministic order.
///
/// ### 🌱 Conversion & Environment Awareness
///
/// The mapper behaves gracefully if specific components are not available:
///
/// * If no [ConversionService] is injected, it falls back to a
///   [SimpleConversionService].
/// * If no [Environment] is injected, it defaults to the
///   global [GlobalEnvironment].
///
/// You may override either manually:
///
/// ```dart
/// mapper.setEnvironment(myEnvironment);
/// mapper.setConversionService(myConversionService);
/// ```
///
///
/// ### 🧩 Extending This Class
///
/// Custom Jetleaf modules typically extend this mapper to preconfigure
/// serialization behavior, add custom adapters, or override Jetson settings.
///
/// Example:
///
/// ```dart
/// class MyAppObjectMapper extends AbstractAwareObjectMapper {
///   MyAppObjectMapper() {
///     // Additional configuration here
///   }
/// }
/// ```
///
///
/// ### 📦 Package Integration
///
/// This mapper resides in the `web` package space and acts as the underlying
/// mapper powering Jetleaf’s HTTP message converters (JSON, XML, YAML).
///
///
/// {@endtemplate}
abstract class AbstractAwareObjectMapper extends AbstractYamlObjectMapper implements ApplicationContextAware, InitializingPod, EnvironmentAware, ConversionServiceAware {
  /// The active [ApplicationContext] associated with this mapper.
  ///
  /// This context provides access to environment properties, configuration
  /// values, dependency providers, and runtime services required by the
  /// serialization and deserialization pipeline.
  ///
  /// The field is marked `late` because it must be initialized externally
  /// during setup, typically by the application or container that owns
  /// the mapper instance. It is guaranteed to be assigned before any
  /// serialization, deserialization, or configuration lookups occur.
  late ApplicationContext _applicationContext;

  /// Optional [ConversionService] used for type conversions during
  /// serialization and deserialization.
  ///
  /// If not explicitly set, a default [SimpleConversionService] will be used.
  /// Typically injected from the [ApplicationContext] or set via
  /// [setConversionService].
  ///
  /// ### Example
  /// ```dart
  /// this.setConversionService(MyCustomConversionService());
  /// ```
  ConversionService? _conversionService;

  /// Optional [Environment] providing configuration properties and environment
  /// variables.
  ///
  /// If not explicitly set, a default [GlobalEnvironment] is used. Typically
  /// injected from the [ApplicationContext] or set via [setEnvironment].
  ///
  /// ### Example
  /// ```dart
  /// this.setEnvironment(myEnvironment);
  /// ```
  Environment? _environment;

  /// {@macro abstract_aware_object_mapper}
  AbstractAwareObjectMapper([super.autoRegisterStandardAdapters]);

  @override
  ConversionService getConversionService() => _conversionService ?? SimpleConversionService();

  @override
  Environment getEnvironment() => _environment ?? GlobalEnvironment();
  
  @override
  String getPackageName() => PackageNames.WEB;

  @override
  void setApplicationContext(ApplicationContext applicationContext) {
    _conversionService ??= applicationContext.getConversionService();

    _environment ??= applicationContext.getEnvironment();

    _applicationContext = applicationContext;
  }

  @override
  void setConversionService(ConversionService conversionService) {
    _conversionService = conversionService;
  }

  @override
  void setEnvironment(Environment environment) {
    _environment = environment;
  }
  
  @override
  Future<void> onReady() async {
    try {
      final serializers = await _applicationContext.getPodsOf(ObjectSerializer.CLASS, allowEagerInit: true);
      if (serializers.isNotEmpty) {
        final ordered = AnnotationAwareOrderComparator.getOrderedItems(serializers.values);
        for (final value in ordered) {
          registerSerializer(value.toClass(), value);
        }
      } else {
        // No registrars found - this is normal for many applications
      }

      final deserializers = await _applicationContext.getPodsOf(ObjectDeserializer.CLASS, allowEagerInit: true);
      if (deserializers.isNotEmpty) {
        final ordered = AnnotationAwareOrderComparator.getOrderedItems(deserializers.values);
        for (final value in ordered) {
          registerDeserializer(value.toClass(), value);
        }
      } else {
        // No registrars found - this is normal for many applications
      }

      final adapters = await _applicationContext.getPodsOf(JsonSerializationAdapter.CLASS, allowEagerInit: true);
      if (adapters.isNotEmpty) {
        final ordered = AnnotationAwareOrderComparator.getOrderedItems(adapters.values);
        for (final value in ordered) {
          registerAdapter(value.toClass(), value);
        }
      } else {
        // No registrars found - this is normal for many applications
      }

      if (await _applicationContext.containsType(JsonGenerator.CLASS)) {
        final value = await _applicationContext.get(JsonGenerator.CLASS);
        setJsonGenerator(value);
      }

      if (await _applicationContext.containsType(XmlGenerator.CLASS)) {
        final value = await _applicationContext.get(XmlGenerator.CLASS);
        setXmlGenerator(value);
      }

      if (await _applicationContext.containsType(YamlGenerator.CLASS)) {
        final value = await _applicationContext.get(YamlGenerator.CLASS);
        setYamlGenerator(value);
      }

      if (await _applicationContext.containsType(NamingStrategy.CLASS)) {
        final value = await _applicationContext.get(NamingStrategy.CLASS);
        setNamingStrategy(value);
      }

      final deserializationContexts = await _applicationContext.getPodsOf(DeserializationContext.CLASS);
      for (final value in deserializationContexts.values) {
        setDeserializationContext(value);
      }

      final serializationContexts = await _applicationContext.getPodsOf(SerializationContext.CLASS);
      for (final value in serializationContexts.values) {
        setSerializationContext(value);
      }
    } catch (_) { }
  }
}