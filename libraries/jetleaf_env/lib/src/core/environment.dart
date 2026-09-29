import 'package:jetleaf_lang/lang.dart';

import '../profiles/profiles.dart';
import '../property_resolver/property_resolver.dart';
import '../property_source/mutable_property_sources.dart';
import '../property_source/property_source.dart';

// =========================================== ENVIRONMENT =========================================

/// {@template environment}
/// **Environment Contract**
///
/// Defines the core abstraction for accessing environment configuration
/// and managing active profiles. This interface extends both:
/// - [PropertyResolver]: for resolving configuration properties (e.g.,
///   values defined in environment variables, property files, or injected maps).
/// - [PackageIdentifier]: for uniquely identifying the runtime context
///   or configuration package.
///
/// # Profiles
/// Profiles are logical groupings of configuration settings that allow an
/// application to adapt to different runtime contexts such as:
/// - `dev` (development)
/// - `test` (testing/CI)
/// - `staging` (pre-production verification)
/// - `prod` (production)
///
/// Profiles can be explicitly activated or fall back to defaults when none
/// are provided. They are commonly used in conditional configuration, e.g.,
/// loading different data sources, enabling debugging, or disabling
/// experimental features.
///
/// # Example
/// ```dart
/// void configure(Environment env) {
///   if (env.matchesProfiles(['dev & !prod'])) {
///     // Apply development-only settings
///   }
/// }
/// ```
///
/// {@endtemplate}
abstract class Environment extends PropertyResolver implements PackageIdentifier {
  /// {@template environment_active_profiles}
  /// **Active Profiles**
  ///
  /// Returns the list of explicitly activated profiles for the current
  /// runtime environment. These represent the user- or system-defined
  /// profile set that determines configuration.
  ///
  /// # Behavior
  /// - If profiles were explicitly activated (e.g., via CLI flags, config
  ///   files, or environment variables), those are returned here.
  /// - If none are active, [getDefaultProfiles] provides the fallback.
  ///
  /// # Example
  /// ```dart
  /// final profiles = env.getActiveProfiles();
  /// if (profiles.contains('prod')) {
  ///   enableOptimizations();
  /// }
  /// ```
  ///
  /// # Notes
  /// - Profile names are case-sensitive unless your environment
  ///   implementation normalizes them.
  /// - May return an empty list if nothing is set and no defaults are used.
  /// {@endtemplate}
  List<String> getActiveProfiles();

  /// {@template environment_default_profiles}
  /// **Default Profiles**
  ///
  /// Returns the list of default profiles used when no profiles are
  /// explicitly active. This ensures that applications always have
  /// a baseline configuration profile available.
  ///
  /// # Example
  /// A common default is:
  /// ```dart
  /// ['default']
  /// ```
  ///
  /// # Behavior
  /// - If [getActiveProfiles] returns an empty list, these defaults
  ///   become the effective active profiles.
  /// - If [getActiveProfiles] has entries, this list is ignored.
  ///
  /// # Notes
  /// - Defaults should always be non-empty to avoid runtime ambiguity.
  /// - Implementations may allow overriding the defaults.
  /// {@endtemplate}
  List<String> getDefaultProfiles();

  /// {@template environment_matches_profiles}
  /// **Profile Expression Matcher**
  ///
  /// Returns `true` if the provided profile expressions match against the
  /// environment's active (or default) profiles.
  ///
  /// This is a convenience wrapper around [acceptsProfiles], which accepts
  /// a prebuilt [Profiles] instance.
  ///
  /// # Example
  /// ```dart
  /// if (env.matchesProfiles(['dev & !test'])) {
  ///   print('Running in development without tests enabled');
  /// }
  /// ```
  ///
  /// # Behavior
  /// - Supports expressions such as:
  ///   - `&` (AND)
  ///   - `|` (OR)
  ///   - `!` (NOT)
  ///   - Parentheses for grouping
  /// - Automatically converts the given expressions into a [Profiles]
  ///   instance before evaluation.
  ///
  /// # Notes
  /// - Throws [EnvironmentParsingException] if an invalid expression
  ///   is passed.
  /// {@endtemplate}
  bool matchesProfiles(List<String> profileExpressions) =>
      acceptsProfiles(Profiles.of(profileExpressions));

  /// {@template environment_accepts_profiles}
  /// **Profile Predicate Evaluation**
  ///
  /// Evaluates a [Profiles] predicate against the current environment.
  /// This method should be preferred over [matchesProfiles] when the caller
  /// already has a compiled [Profiles] object for efficiency.
  ///
  /// # Example
  /// ```dart
  /// final profiles = Profiles.of(['staging | prod']);
  /// if (env.acceptsProfiles(profiles)) {
  ///   connectToProductionDb();
  /// }
  /// ```
  ///
  /// # Behavior
  /// - Executes the predicate using the environment’s active or default
  ///   profiles.
  /// - Allows reuse of compiled [Profiles] across multiple evaluations.
  ///
  /// # Notes
  /// - Use [matchesProfiles] for quick ad-hoc checks.
  /// - Use [acceptsProfiles] when evaluating the same expression repeatedly.
  /// {@endtemplate}
  bool acceptsProfiles(Profiles profiles);

  /// {@template environment_suggestions}
  /// **Configuration Suggestions**
  ///
  /// Returns a list of suggestions for the given [key]. Suggestions are
  /// typically generated based on partial matches, available configuration
  /// keys, or introspection of the environment.
  ///
  /// # Example
  /// ```dart
  /// final hints = env.suggestions('db.us');
  /// print(hints); // might print ['db.user', 'db.username']
  /// ```
  ///
  /// # Use Cases
  /// - Improving developer experience with autocompletion or hints.
  /// - Detecting typos in property keys by suggesting valid alternatives.
  ///
  /// # Notes
  /// - The behavior is implementation-specific and may involve fuzzy
  ///   matching or prefix-based lookups.
  /// - Returns an empty list if no suggestions are found.
  /// {@endtemplate}
  @override
  List<String> suggestions(String key);
}

// ========================================= CONFIGURABLE ENVIRONMENT =========================================

/// {@template configurable_environment}
/// A configurable extension of the [Environment] interface that allows mutation
/// of environment internals such as active profiles and property sources.
///
/// This interface exposes:
/// - `propertySources`: the mutable stack of [PropertySource]s used for
///   resolving properties.
/// - `setActiveProfiles`: to explicitly set the profiles considered active
///   during configuration.
/// - `setDefaultProfiles`: to define fallback profiles when no active profiles
///   are provided.
///
/// It is typically implemented by core environment types like
/// [AbstractEnvironment] and [StandardEnvironment].
///
/// ### Example usage:
///
/// ```dart
/// final env = StandardEnvironment();
///
/// env.setActiveProfiles(['dev']);
/// env.setDefaultProfiles(['default']);
///
/// env.propertySources.addLast(
///   MapPropertySource('app', {'debug': 'true'}),
/// );
///
/// print(env.getProperty('debug')); // true
/// ```
///
/// Use this interface when building frameworks or apps that require profile-based
/// configuration or dynamic property source injection.
/// {@endtemplate}
abstract class ConfigurableEnvironment extends Environment implements ConfigurablePropertyResolver {
  /// {@template configurable_environment_set_active_profiles}
  /// Replaces the current set of active profiles with the given list.
  ///
  /// Active profiles influence conditional configuration, especially with
  /// profile-based pods or property loading.
  ///
  /// Example:
  /// ```dart
  /// env.setActiveProfiles(['production']);
  /// ```
  /// {@endtemplate}
  void setActiveProfiles(List<String> profiles);

  /// {@template configurable_environment_set_default_profiles}
  /// Defines the default profiles to fall back on when no active profiles
  /// have been explicitly set.
  ///
  /// These are used only when `activeProfiles` is empty.
  ///
  /// Example:
  /// ```dart
  /// env.setDefaultProfiles(['default']);
  /// ```
  /// {@endtemplate}
  void setDefaultProfiles(List<String> profiles);

  /// {@template configurable_environment_add_active_profile}
  /// Adds an additional active profile to the current set.
  ///
  /// This can be used to programmatically enrich the environment at runtime.
  ///
  /// Example:
  /// ```dart
  /// env.addActiveProfile('integration-test');
  /// ```
  /// {@endtemplate}
  void addActiveProfile(String profile);

  /// {@template configurable_environment_get_system_properties}
  /// Returns the system properties available to the Dart VM (if any),
  /// such as those passed via `--define` or custom bootstrap logic.
  ///
  /// Keys and values are returned as `String`-`String` pairs.
  /// {@endtemplate}
  Map<String, String> getSystemProperties();

  /// {@template configurable_environment_get_system_environment}
  /// Returns the environment variables of the underlying OS.
  ///
  /// Keys and values are returned as `String`-`String` pairs.
  /// {@endtemplate}
  Map<String, String> getSystemEnvironment();

  /// {@template configurable_environment_merge}
  /// Merges another [ConfigurableEnvironment] into this one.
  ///
  /// Property sources, profiles, and system accessors may be merged
  /// based on implementation logic.
  ///
  /// This is useful when bootstrapping from parent contexts or templates.
  /// {@endtemplate}
  void merge(ConfigurableEnvironment parent);

  /// {@template configurable_environment_get_property_sources}
  /// Returns the [MutablePropertySources] backing this environment.
  ///
  /// This is functionally equivalent to accessing [propertySources],
  /// but may differ in subclasses that override it dynamically.
  /// {@endtemplate}
  MutablePropertySources getPropertySources();
}