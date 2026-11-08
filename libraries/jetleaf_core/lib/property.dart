/// 📑 **Jetleaf Property Source & Resolution Subsystem**
///
/// This library provides low-level abstractions for property sources, mutable hierarchies,
/// and property resolver pipelines in Jetleaf applications.
///
/// Key capabilities:
/// - **Pluggable Property Sources:** Extensible abstraction wrapping maps, system environment, or files.
/// - **Ordered Mutability:** Insert sources at specific precedence positions (`addFirst`, `addLast`, `addBefore`, `addAfter`).
/// - **Type-Safe Value Resolution:** Resolving values with type converters and placeholder substitution.
///
/// ---
///
/// ## 🗂️ Property Hierarchy Pipeline
///
/// ```text
/// ┌─────────────────────────────────────────────────────────────┐
/// │                     MutablePropertySources                  │
/// ├─────────────────────────────────────────────────────────────┤
/// │ [First]   Command-Line Flags       (highest precedence)     │
/// │    │                                                        │
/// │    ▼                                                        │
/// │ [Middle]  Custom Application Map    (override source)        │
/// │    │                                                        │
/// │    ▼                                                        │
/// │ [Last]    System Defaults           (lowest fallback)       │
/// └─────────────────────────────────────────────────────────────┘
/// ```
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### 🗄️ Property Sources
/// - [PropertySource] — base class holding a named key-value source of properties.
/// - [MapPropertySource] — property source backed by an in-memory Dart `Map<String, Object>`.
/// - [SystemEnvironmentPropertySource] — property source exposing OS system environment variables.
/// - [CompositePropertySource] — composite source aggregating multiple nested property sources.
/// - [MutablePropertySources] — ordered collection of property sources supporting precedence mutation.
///
/// ### 🔍 Resolvers
/// - [PropertyResolver] — contract for querying properties and resolving placeholders.
/// - [PropertySourcesPropertyResolver] — resolver implementation delegating to [PropertySources].
///
/// ---
///
/// ## 🎯 Usage Example: Mutable Property Ordering & Resolving
///
/// ```dart
/// import 'package:jetleaf_core/property.dart';
/// import 'package:jetleaf_core/lang.dart';
///
/// void main() {
///   final sources = MutablePropertySources();
///
///   // Add default fallback properties
///   sources.addLast(MapPropertySource('defaults', {
///     'app.name': 'Jetleaf Base',
///     'app.port': 3000,
///   }));
///
///   // Add high-priority override properties
///   sources.addFirst(MapPropertySource('overrides', {
///     'app.port': 8080,
///   }));
///
///   final resolver = PropertySourcesPropertyResolver(sources);
///   final appName = resolver.getProperty('app.name');
///   final port = resolver.getPropertyAs<int>('app.port', Class<int>());
///
///   print('$appName running on port: $port');
///   // Output: Jetleaf Base running on port: 8080
/// }
/// ```
library;

export 'src/env/property_source/property_source.dart';
export 'src/env/property_source/map_property_source.dart';
export 'src/env/property_source/system_environment_property_source.dart';
export 'src/env/property_source/composite_property_source.dart';
export 'src/env/property_source/mutable_property_sources.dart';
export 'src/env/property_source/property_sources.dart';
export 'src/env/property_source/listable_property_source.dart';

export 'src/env/property_resolver/property_resolver.dart';
export 'src/env/property_resolver/property_sources_property_resolver.dart';

export 'src/env/property/jetleaf_property.dart';
export 'src/env/property/configuration_properties.dart';
export 'src/env/property_source_ordering/common_rules.dart';
export 'src/env/property_source_ordering/property_source_ordering_rule.dart';