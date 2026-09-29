import 'dart:io' show Platform;

import 'package:jetleaf_lang/lang.dart';
import 'package:meta/meta.dart';

import '../property_source/mutable_property_sources.dart';
import 'abstract_environment.dart';
import '../property_source/system_environment_property_source.dart';

/// {@template standard_environment}
/// A concrete implementation of [AbstractEnvironment] that represents the
/// default runtime environment for most applications.
///
/// It supports:
/// - System environment variables via [Platform.environment]
/// - Active and default profile management
/// - Placeholder resolution and conversion via the parent class
///
/// This class automatically registers a [SystemEnvironmentPropertySource] under
/// the name `'systemEnvironment'`. It also maintains a set of active and default
/// profiles, which can be queried using [acceptsProfiles] and [matchesProfiles].
///
/// ### Example usage:
///
/// ```dart
/// final env = StandardEnvironment();
///
/// env.setActiveProfiles(['dev']);
/// env.setDefaultProfiles(['default']);
///
/// print(env.activeProfiles); // [dev]
/// print(env.getProperty('PATH')); // system environment variable
///
/// if (env.acceptsProfiles(Profiles.of(['dev']))) {
///   print('Running in dev mode');
/// }
/// ```
///
/// The default profile is always `'default'` unless overridden explicitly.
/// {@endtemplate}
class GlobalEnvironment extends AbstractEnvironment {
  /// The name used to register the system environment property source.
  static final String SYSTEM_ENVIRONMENT_PROPERTY_SOURCE_NAME = 'systemEnvironment';

  /// The name used to register the system properties property source.
  static final String SYSTEM_PROPERTIES_PROPERTY_SOURCE_NAME = "systemProperties";

  /// The reserved name for the default profile.
  static const String RESERVED_DEFAULT_PROFILE_NAME = 'default';

  /// {@macro standard_environment}
  GlobalEnvironment();

  /// {@macro standard_environment}
  @protected
  GlobalEnvironment.source(super.propertySources) : super.source();

  @override
  void customizePropertySources(MutablePropertySources propertySources) {
    propertySources.addAll(propertySources.toList());
    propertySources.addLast(SystemEnvironmentPropertySource(SYSTEM_ENVIRONMENT_PROPERTY_SOURCE_NAME, getSystemEnvironment()));
    propertySources.addLast(SystemEnvironmentPropertySource(SYSTEM_PROPERTIES_PROPERTY_SOURCE_NAME, getSystemProperties()));
  }

  @override
  String getPackageName() => PackageNames.ENV;
}