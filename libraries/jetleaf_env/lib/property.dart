/// **Jetleaf Property System**
///
/// This library provides the core infrastructure for resolving and managing
/// configuration values within the Jetleaf Framework.
///
/// It exposes the property resolution pipeline, property sources, and
/// annotations used to bind configuration into application components.
///
///
/// ## 🔍 What This Library Does
///
/// - Resolves configuration values from multiple sources
/// - Normalizes and queries hierarchical properties
/// - Allows custom property sources to be registered
/// - Supports strongly-typed configuration binding
///
///
/// ## 📦 Exports Overview
///
/// ### 🧩 Property Resolution
///
/// - `PropertyResolver` — contract for resolving property values
/// - `AbstractPropertyResolver` — base implementation with shared logic
/// - `PropertySourcesPropertyResolver` — resolver backed by multiple sources
///
///
/// ### 🏗 Property Sources
///
/// - `_PropertySource` — internal base representation
/// - `PropertySource` — public abstraction of a configuration source
///
/// Examples of property sources may include:
/// - environment variables
/// - system properties
/// - configuration files
/// - in-memory definitions
///
///
/// ### 🔒 Configuration Binding
///
/// - `ConfigurationProperties` — annotation for binding structured config
/// - `JetleafProperty` — metadata for defining individual config fields
///
/// Used to map external configuration into typed classes, similar to:
/// ```dart
/// @ConfigurationProperties(prefix: 'server')
/// class ServerConfig {
///   final int port;
///
///   const ServerConfig({required this.port});
/// }
/// ```
///
///
/// ## ✅ Intended Usage
///
/// Importing this library grants access to the Jetleaf configuration system:
///
/// ```dart
/// import 'package:jetleaf_env/property.dart';
///
/// final value = resolver.getProperty('app.name');
/// ```
///
/// Typically, applications will not implement resolvers directly—
/// instead, Jetleaf assembles them through the environment layer.
library;

export 'src/property_resolver/abstract_property_resolver.dart';
export 'src/property_resolver/property_sources_property_resolver.dart';
export 'src/property_resolver/property_resolver.dart';

export 'src/property_source/system_environment_property_source.dart';
export 'src/property_source/command_line_property_source.dart';
export 'src/property_source/composite_property_source.dart';
export 'src/property_source/listable_property_source.dart';
export 'src/property_source/map_property_source.dart';
export 'src/property_source/mutable_property_sources.dart';
export 'src/property_source/property_source.dart';
export 'src/property_source/property_sources.dart';
export 'src/property_source/simple_command_line_property_source.dart';

export 'src/property_source_ordering/common_rules.dart';
export 'src/property_source_ordering/property_source_ordering_rule.dart';

export 'src/property/configuration_properties.dart';
export 'src/property/jetleaf_property.dart';