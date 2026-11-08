import 'package:jetleaf_core/env.dart';

/// {@template application_environment}
/// A concrete environment for standard Jetleaf applications.
///
/// This class extends [GlobalEnvironment] and serves as the default
/// runtime environment for most Jetleaf-based applications unless explicitly overridden.
///
/// It inherits all behavior from [GlobalEnvironment], including support for:
/// - System environment variables
/// - System properties (if available)
/// - Default property sources
/// - Active and default profiles
///
/// ### Example:
/// ```dart
/// final env = ApplicationEnvironment();
///
/// // Configure active profiles
/// env.getActiveProfiles().add('production');
///
/// // Add layered property source
/// env.getPropertySources().addLast(MapPropertySource('app-config', {
///   'server.port': 8080,
///   'server.ssl': true,
/// }));
///
/// final port = env.getPropertyAs<int>('server.port', Class<int>(), 3000);
/// print('Running on port: $port');
/// ```
///
/// You can customize this environment by registering new property sources or profiles
/// during the boot phase.
///
/// {@endtemplate}
class ApplicationEnvironment extends GlobalEnvironment {
  /// {@macro application_environment}
  ApplicationEnvironment() : super() {
    setPlaceholderPrefix("\${");
  }
}