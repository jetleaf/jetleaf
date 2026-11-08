/// 🌍 **Jetleaf Environment, Profiles & Property Resolution Subsystem**
///
/// This library provides the centralized environment abstraction, multi-profile management,
/// and hierarchical property resolution engine for the Jetleaf framework.
///
/// It encapsulates:
/// - **Environment Abstractions:** [Environment], [ConfigurableEnvironment], [StandardEnvironment].
/// - **Multi-Profile Management:** Active profiles, default profiles, profile evaluation.
/// - **Property Sources:** [PropertySource], [MapPropertySource], [CommandLinePropertySource].
/// - **Property Resolvers:** [PropertyResolver], [ConfigurablePropertyResolver], [AbstractPropertyResolver].
/// - **Type-Safe Configuration Binding:** Expression evaluation and property conversion.
///
/// ---
///
/// ## 🏛️ Hierarchical Property Resolution Cascade
///
/// Jetleaf resolves configuration properties by cascading through ordered property sources:
///
/// ```text
/// ┌────────────────────────────────────────────────────────────────────────┐
/// │                 Hierarchical Property Sources (Highest to Lowest)      │
/// ├────────────────────────────────────────────────────────────────────────┤
/// │ 1. Command-Line Arguments   (--server.port=9090, -Dcustom=val)         │
/// │                                    │                                   │
/// │ 2. Environment Variables    (SERVER_PORT=8080, JETLEAF_ACTIVE_PROFILES)│
/// │                                    │                                   │
/// │ 3. Profile-Specific Files   (application-prod.properties / .yaml)      │
/// │                                    │                                   │
/// │ 4. Default Application File (application.properties / .yaml / .json)   │
/// │                                    │                                   │
/// │ 5. Programmatic Defaults    (DefaultPropertiesPropertySource)          │
/// └────────────────────────────────────────────────────────────────────────┘
/// ```
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### 🌍 Environment Management
/// - [Environment] — read-only access to active profiles and configuration properties.
/// - [ConfigurableEnvironment] — allows mutation of active profiles and property sources.
/// - [StandardEnvironment] — standard production environment incorporating system env and properties.
/// - [Profiles] — utility for profile predicate evaluation (e.g. `dev & !cloud`).
///
/// ### 🔍 Property Resolvers & Sources
/// - [PropertyResolver] — contract for querying string and typed properties with fallback defaults.
/// - [PropertySource] — named source of key-value property pairs.
/// - [MapPropertySource] — in-memory map backed property source.
/// - [CommandLinePropertySource] — parses `--key=value` command-line arguments into properties.
/// - [SimpleCommandLinePropertySource] — lightweight CLI argument parser source.
/// - [PropertySources] — ordered container managing the precedence of multiple property sources.
///
/// ---
///
/// ## 🎯 Usage Example: Configuring Profiles & Reading Typed Properties
///
/// ```dart
/// import 'package:jetleaf/env.dart';
///
/// void main() {
///   final env = StandardEnvironment();
///
///   // 1. Configure active environment profiles
///   env.setActiveProfiles(['production', 'eu-west']);
///
///   // 2. Add an in-memory property source
///   env.getPropertySources().addFirst(
///     MapPropertySource('customConfig', {
///       'server.host': '0.0.0.0',
///       'server.port': 8080,
///       'cache.enabled': true,
///     }),
///   );
///
///   // 3. Resolve properties with defaults
///   final host = env.getProperty<String>('server.host', 'localhost');
///   final port = env.getProperty<int>('server.port', 3000);
///   final isCache = env.getProperty<bool>('cache.enabled', false);
///
///   print('Server listening on: $host:$port (Cache: $isCache)');
///   print('Active profiles: ${env.getActiveProfiles()}');
/// }
/// ```
///
/// {@category Jetleaf}
library;

export 'package:jetleaf_core/env.dart';
export 'package:jetleaf_core/property.dart';
