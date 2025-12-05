import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_logging/logging.dart';
import 'package:meta/meta.dart';

import '../listener/run_listener.dart';

/// Provides common support for loading and applying environment profiles
/// during application startup.
///
/// This abstract base class is intended for listeners that participate in the
/// application bootstrap process. It inspects the current
/// [ConfigurableEnvironment] and determines which profiles should be active
/// or used as defaults.  
///
/// Profile resolution follows a hierarchical lookup:
///
/// 1. **Active profiles** are read from:
///    - System properties  
///    - Environment variables  
///    - Parsed configuration assets  
///
/// 2. **Default profiles** are applied when no active profiles are explicitly set.
///
/// If neither active nor default profiles are provided, the implementation
/// ensures that the reserved fallback profile,
/// [AbstractEnvironment.RESERVED_DEFAULT_PROFILE_NAME], is applied as both
/// the default and active profile.
///
/// Subclasses may extend this listener to customize environment preparation
/// before the application fully starts.
abstract class AbstractEnvironmentProfileSupport extends ApplicationRunListener {
  /// The logger to use
  @protected
  final Log logger = LogFactory.getLog("env");

  /// Initializes the active and default profiles for the given environment.
  ///
  /// This method reads profile configuration from the provided
  /// [ConfigurableEnvironment] and applies them according to the following rules:
  ///
  /// - If an *active profiles* value is present (via system properties,
  ///   environment variables, or parsed assets), it is parsed and set.
  /// - If no active profiles are given, but *default profiles* are present,
  ///   those are parsed and used as a fallback.
  /// - If neither active nor default profiles are configured, the reserved
  ///   default profile, [AbstractEnvironment.RESERVED_DEFAULT_PROFILE_NAME], is
  ///   assigned to both active and default profile sets to guarantee that the
  ///   environment always contains at least one profile.
  ///
  /// Debug logging is emitted when profile assignments are applied.
  @protected
  void configureEnvironmentProfile(ConfigurableEnvironment environment) {
    // 1) Look for active profiles: system props -> system env -> parsed assets (list)
    String? activeRaw = environment.getProperty(AbstractEnvironment.ACTIVE_PROFILES_PROPERTY_NAME);

    // 2) Look for default profiles (if active wasn't provided)
    String? defaultRaw = environment.getProperty(AbstractEnvironment.DEFAULT_PROFILES_PROPERTY_NAME);

    // 3) Apply to environment
    if (activeRaw != null && activeRaw.trim().isNotEmpty) {
      final activeProfiles = _parseProfilesString(activeRaw);
      if (activeProfiles.isNotEmpty) {
        environment.setActiveProfiles(activeProfiles);
        if (logger.getIsDebugEnabled()) {
          logger.debug('Set active profiles from config: $activeProfiles');
        }
      }
    }

    if (defaultRaw != null && defaultRaw.trim().isNotEmpty) {
      final defaultProfiles = _parseProfilesString(defaultRaw);
      if (defaultProfiles.isNotEmpty) {
        environment.setDefaultProfiles(defaultProfiles);
        if (logger.getIsDebugEnabled()) {
          logger.debug('Set default profiles from config: $defaultProfiles');
        }
      }
    }

    // If nothing set, ensure there is at least [AbstractEnvironment.RESERVED_DEFAULT_PROFILE_NAME]
    if (environment.getDefaultProfiles().isEmpty) {
      environment.setDefaultProfiles([AbstractEnvironment.RESERVED_DEFAULT_PROFILE_NAME]);
    }

    if (environment.getActiveProfiles().isEmpty) {
      environment.setActiveProfiles([AbstractEnvironment.RESERVED_DEFAULT_PROFILE_NAME]);
    }
  }

  /// {@template environment_listener_parse_profiles}
  /// Parse a raw profiles string into a list of profile names.
  ///
  /// Splits on commas and whitespace, trims each profile, and removes
  /// any empty entries.
  ///
  /// ### Example
  /// ```dart
  /// final listener = EnvironmentListener();
  /// final profiles = listener._parseProfilesString("dev, test prod");
  /// print(profiles); // ["dev", "test", "prod"]
  /// ```
  /// {@endtemplate}
  List<String> _parseProfilesString(String? raw) {
    if (raw == null) return <String>[];
    return raw.split(RegExp(r'[,\s]+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }
}