/// **Jetleaf Env API**
///
/// This library serves as a convenience entry point for accessing the Jetleaf
/// environment and property-resolution system from a single import.
///
/// It re-exports the primary configuration layers so application code can
/// easily retrieve runtime settings and bind structured configuration
/// without needing to reference deeper internal modules.
///
///
/// ## ✅ What This Library Provides
///
/// ### 🌍 Environment Access
/// Re-exported from `env.dart`:
/// - Global environment accessors
/// - Profile awareness (e.g., `dev`, `prod`)
/// - Configuration source aggregation
///
/// Allows retrieving values like:
/// ```dart
/// import 'package:jetleaf/config.dart';
///
/// final active = env.activeProfiles;
/// ```
///
///
/// ### 🔑 Property Resolution
/// Re-exported from `property.dart`:
/// - Property resolution APIs
/// - Annotation-based configuration binding
/// - Property sources and resolvers
///
/// Example usage:
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
/// ## 🎯 Intended Usage
///
/// Instead of importing multiple packages:
/// ```dart
/// import 'package:jetleaf_env/env.dart';
/// import 'package:jetleaf_env/property.dart';
/// ```
///
/// You can simply rely on this entrypoint:
/// ```dart
/// import 'package:jetleaf_env/jetleaf_env.dart';
/// ```
///
/// This keeps application code clean and consistent.
library;

export 'env.dart';
export 'property.dart';