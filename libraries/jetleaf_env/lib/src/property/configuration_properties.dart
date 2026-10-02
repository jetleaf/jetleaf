import 'package:jetleaf_lang/lang.dart';
import 'package:meta/meta.dart';

import 'jetleaf_property.dart';

/// A base class for defining structured and strongly typed configuration classes
/// in the Jetleaf framework.
///
/// This replaces the need for `@ConfigurationProperties` annotations by requiring
/// subclasses to override the [properties] method. This method returns a
/// [ApplicationConfigurationProperties] instance, which contains metadata like the profile
/// (e.g. "dev", "prod") and source file name.
///
/// The Jetleaf framework uses this base class to automatically discover, validate,
/// and inject environment-specific configurations at runtime.
///
/// ---
///
/// ## 🛠️ How to Use
///
/// 1. **Create a class that extends [ApplicationConfigurationProperty]**
/// 2. **Implement the [properties] method**, returning the profile and metadata
///
/// ```dart
/// class DevConfig extends ConfigurationProperty {
///   final int port = 3000;
///   final bool debug = true;
///
///   @override
///   ConfigurationProperties properties() => ConfigurationProperties({
///     JetleafProperty.SERVER_PORT.copyWith(value: port),
///     JetleafProperty.DEBUG.copyWith(value: debug),
///   });
/// }
/// ```
///
/// ---
///
/// ## 📦 Default Profile Example
///
/// If your configuration is from `application.dart`, use the default profile:
///
/// ```dart
/// class AppConfig extends ConfigurationProperty {
///   final int port = 8080;
///   final bool secure = false;
///
///   @override
///   ConfigurationProperties properties() => ConfigurationProperties.empty(); // default
/// }
/// ```
///
/// ---
///
/// ## 🔍 What This Enables
///
/// - 🧭 Automatic profile resolution (e.g., `application_dev.dart` → `dev`)
/// - 🧪 Type-safe property validation via [JetleafProperty]
/// - 🧰 Code generation or runtime scanning for all configuration providers
/// - ✅ No need for custom annotations or reflection
///
/// ---
///
/// ## 🧱 Why You Must Extend [ApplicationConfigurationProperty]
///
/// - Allows Jetleaf to discover configuration classes at runtime
/// - Enables profile-specific overrides and conditional loading
/// - Encourages typed, expressive configuration definitions
///
/// ---
///
/// ## 🔁 Switching Configurations by Profile
///
/// Jetleaf uses the `profile` field from [ApplicationConfigurationProperties] to decide
/// which config to apply. For example:
///
/// ```dart
/// ConfigurationProperties({JetleafProperty.PROFILE.copyWith(value: 'dev')})
/// ```
/// will be used when `application_dev.dart` is the active environment.
///
/// ---
///
/// ## ✅ Summary
///
/// | Feature              | Description                                          |
/// |----------------------|------------------------------------------------------|
/// | Profile Support      | Built-in via `application_dev.dart`       |
/// | Source Metadata      | Optional, for debugging or documentation             |
/// | Annotation-Free      | No annotation required, uses Dart idioms             |
/// | Type Safety          | Powered by [JetleafProperty] and runtime validation    |
///
/// ---
///
/// See also: [ApplicationConfigurationProperties]
///
abstract class ApplicationConfigurationProperty {
  /// Returns a [ApplicationConfigurationProperties] instance that contains metadata
  /// such as the active profile (`default`, `dev`, `prod`, etc.) and
  /// optional source info (e.g., file name or module origin).
  ///
  /// Must be overridden in subclasses.
  @mustBeOverridden
  ApplicationConfigurationProperties properties();
}

/// {@template configuration_properties}
/// ConfigurationProperties is a class for defining application configuration in a typed and expressive way,
/// similar to defining settings in `application.yaml`, but directly in Dart.
///
/// This provides a structured way to define and access configuration properties.
///
/// ## Example: Typed config definition
/// ```dart
/// ConfigurationProperties({
///     JetleafProperty.SERVER_PORT.copyWith(value: 8081),
///     JetleafProperty.SECURITY_ENABLED.copyWith(value: true),
///     JetleafProperty.MY_FEATURE_ENABLED.copyWith(value: true),
/// })
/// ```
/// 
/// {@endtemplate}
final class ApplicationConfigurationProperties {
  /// The internal map of [JetleafProperty] to values.
  final Set<JetleafProperty> _properties;

  /// Creates a new configuration property from the provided [properties] map.
  ///
  /// If no map is provided, an empty configuration is initialized.
  ///
  /// {@macro configuration_properties}
  ApplicationConfigurationProperties([Set<JetleafProperty>? properties]) : _properties = properties ?? <JetleafProperty>{};

  /// Creates a completely empty configuration.
  ///
  /// Example:
  /// ```dart
  /// ConfigurationProperties.empty()
  /// ```
  /// 
  /// {@macro configuration_properties}
  ApplicationConfigurationProperties.empty() : _properties = <JetleafProperty>{};

  /// Converts the internal typed map to a standard `Map<String, dynamic>`,
  /// mapping each [JetleafProperty.key] to its associated value.
  ///
  /// This result is suitable for passing into application environments or serialization.
  ///
  /// Example:
  /// ```dart
  /// final property = ConfigurationProperties({
  ///     JetleafProperty.SERVER_PORT: 8081,
  ///     JetleafProperty.SECURITY_ENABLED: true,
  ///     JetleafProperty.MY_FEATURE_ENABLED: true,
  /// });
  /// final result = property.build();
  /// resource.load(result);
  /// ```
  /// 
  /// {@macro configuration_properties}
  Map<String, Object> build() => _properties.toMap((key) => key.key, (key) => key.value);
}