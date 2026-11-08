/// 🌍 **Jetleaf Environment & Configuration Subsystem**
///
/// This library provides the runtime environment and configuration infrastructure
/// for Jetleaf applications, managing:
/// - **Hierarchical Property Sources:** Layered resolution with deterministic precedence.
/// - **Environment Profiles:** Conditional property activation (`dev`, `prod`, `test`).
/// - **Command-Line Arguments:** Parsing positional, option, and flag arguments.
/// - **Type-Safe Property Resolution:** Type conversion and default value fallback.
///
/// ---
///
/// ## 📊 Property Resolution Precedence
///
/// Properties are resolved in order of decreasing precedence:
///
/// ```text
/// ┌─────────────────────────────────────────────────────────────┐
/// │ 1. Command-Line Arguments        (--server.port=9090)       │
/// │                           │                                 │
/// │ 2. System Environment Variables   (SERVER_PORT=8080)        │
/// │                           │                                 │
/// │ 3. Profile-Specific Properties   (application-prod.yaml)   │
/// │                           │                                 │
/// │ 4. Default Application Config     (application.yaml)        │
/// │                           │                                 │
/// │ 5. Programmatic Defaults         (defaultValue: 3000)       │
/// └─────────────────────────────────────────────────────────────┘
/// ```
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### 🌍 Environment Contracts
/// - [Environment] — the primary interface for inspecting profiles and resolving properties.
/// - [AbstractEnvironment] — extensible base environment orchestrating property sources.
/// - [GlobalEnvironment] — process-wide singleton environment holding default system state.
///
/// ### 🏷️ Profiles
/// - [Profiles] — utility contract for querying and matching active and default profiles.
///
/// ### ⚙️ Application Arguments
/// - [ApplicationArguments] — structured command-line argument abstraction.
/// - [DefaultApplicationArguments] — parses raw CLI arguments into option and non-option args.
///
/// ---
///
/// ## 🎯 Usage Example: Layered Configuration & Profile Activation
///
/// ```dart
/// import 'package:jetleaf_core/env.dart';
/// import 'package:jetleaf_core/lang.dart';
/// import 'package:jetleaf_core/property.dart';
///
/// void main() {
///   final env = ApplicationEnvironment();
///
///   // 1. Activate environment profiles
///   env.getActiveProfiles().addAll(['prod', 'cloud']);
///   if (env.acceptsProfiles(Profiles.of(['prod']))) {
///     print('Running in PRODUCTION profile.');
///   }
///
///   // 2. Add custom layered property sources
///   env.getPropertySources().addLast(MapPropertySource('defaultConfig', {
///     'server.host': '127.0.0.1',
///     'server.port': 8080,
///     'server.ssl': false,
///   }));
///
///   // 3. Resolve properties with type safety and fallback
///   final host = env.getProperty('server.host', 'localhost');
///   final port = env.getPropertyAs<int>('server.port', Class<int>(), 3000);
///   final ssl = env.getPropertyAs<bool>('server.ssl', Class<bool>(), false);
///
///   print('Server listening on: $host:$port (SSL: $ssl)');
/// }
/// ```
library;

export 'src/env/argument/application_arguments.dart';
export 'src/env/argument/default_application_arguments.dart';

export 'src/env/core/environment.dart';
export 'src/env/core/abstract_environment.dart';
export 'src/env/core/configuration_property_source.dart';
export 'src/env/core/global_environment.dart';
export 'src/env/core/env.dart';

export 'src/env/profiles/profiles.dart';

export 'src/env/exceptions.dart';