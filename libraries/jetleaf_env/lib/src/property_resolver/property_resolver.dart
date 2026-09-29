import 'package:jetleaf_convert/convert.dart';
import 'package:jetleaf_lang/lang.dart';

/// {@template property_resolver}
/// A service abstraction for resolving application properties and configuration values.
///
/// This interface defines methods for reading, converting, and resolving
/// property values from environment variables, `.env`, YAML, or other sources.
///
/// Useful for configuration loading, dynamic placeholder resolution,
/// and runtime property injection.
///
/// ---
///
/// ### 🔧 Common Use Cases:
/// ```dart
/// final port = resolver.getPropertyAsWithDefault<int>('server.port', 8080);
/// final name = resolver.getRequiredProperty('app.name');
/// final message = resolver.resolvePlaceholders('Running #{app.name} on port #{server.port}');
/// ```
/// ## Supported Patterns
/// 
/// ### Environment Variables:
/// - `${VAR_NAME}` - Standard shell-style environment variable
/// - `#{VAR_NAME}` - Alternative environment variable syntax
/// - `$VAR_NAME` - Short environment variable syntax
/// - `#VAR_NAME` - Alternative short environment variable syntax
/// 
/// ### Property References:
/// - `@property.name@` - Property reference with @ delimiters
/// - `${property.name}` - Property reference using ${} syntax
/// - `#{property.name}` - Property reference using #{} syntax
/// 
/// ## Example Usage
/// ```dart
/// // Environment: BASE_URL=https://api.example.com, API=v1
/// // Properties: server.timeout=30, app.name=MyApp
/// 
/// final interpolator = ResourceInterpolator(resources);
/// 
/// // Various interpolation patterns:
/// interpolator.interpolate('${BASE_URL}/${API}')           // → https://api.example.com/v1
/// interpolator.interpolate('#{BASE_URL}/#{API}')           // → https://api.example.com/v1
/// interpolator.interpolate('$BASE_URL/$API')               // → https://api.example.com/v1
/// interpolator.interpolate('#BASE_URL/#API')               // → https://api.example.com/v1
/// interpolator.interpolate('$BASE_URL/check')              // → https://api.example.com/check
/// interpolator.interpolate('@app.name@ timeout: @server.timeout@s') // → MyApp timeout: 30s
/// ```
///
/// ---
///
/// {@endtemplate}
abstract class PropertyResolver {
  /// {@macro property_resolver}
  const PropertyResolver();

  /// {@template contains_property}
  /// Returns whether the given property [key] is defined.
  ///
  /// This is useful when optional configuration might exist.
  ///
  /// ### Example:
  /// ```dart
  /// if (resolver.containsProperty('app.debug')) {
  ///   print('Debug mode enabled');
  /// }
  /// ```
  /// {@endtemplate}
  bool containsProperty(String key);

  /// {@template get_property_nullable}
  /// Retrieves the value for the given property [key], or `null` if not found.
  /// 
  /// If [defaultValue] is provided, it returns the default value instead of null.
  ///
  /// Equivalent to: `getProperty(key) ?? defaultValue`.
  ///
  /// ### Example:
  /// ```dart
  /// final dbUrl = resolver.getProperty('database.url');
  /// final dbUrl = resolver.getProperty('database.url', 'localhost');
  /// ```
  ///
  /// See also:
  /// - [getPropertyWithDefault]
  /// - [getRequiredProperty]
  /// {@endtemplate}
  String? getProperty(String key, [String? defaultValue]);

  /// {@template get_property_t_nullable}
  /// Retrieves and converts the value of [key] to the desired type [T].
  /// 
  /// If [defaultValue] is provided, it returns the default value instead of null.
  ///
  /// Returns `null` if the property is not found or cannot be converted.
  /// 
  /// targetType - the expected type of the property value
  /// key - the property key
  ///
  /// ### Example:
  /// ```dart
  /// final port = resolver.getPropertyAs<int>('server.port', Class<int>());
  /// final port = resolver.getPropertyAs<int>('server.port', Class<int>(), 8080);
  /// ```
  /// {@endtemplate}
  T? getPropertyAs<T>(String key, Class<T> targetType, [T? defaultValue]);

  /// {@template get_required_property}
  /// Returns the property value for [key], or throws [IllegalStateException] if the property is not defined.
  ///
  /// This is useful for required configuration values such as API keys.
  ///
  /// ### Example:
  /// ```dart
  /// final apiKey = resolver.getRequiredProperty('security.apiKey');
  /// ```
  /// {@endtemplate}
  String getRequiredProperty(String key);

  /// {@template get_required_property_t}
  /// Retrieves and converts the property [key] to type [T], or throws [IllegalStateException] if missing or invalid.
  /// 
  /// targetType - the expected type of the property value
  /// key - the property key
  ///
  /// ### Example:
  /// ```dart
  /// final timeout = resolver.getRequiredPropertyAs<int>('http.timeout');
  /// ```
  /// {@endtemplate}
  T getRequiredPropertyAs<T>(String key, Class<T> targetType);

  /// {@template resolve_placeholders}
  /// Resolves `#{...}` placeholders in the input [text] using available properties.
  ///
  /// If a placeholder has no matching property, it is left unchanged.
  ///
  /// ### Example:
  /// ```dart
  /// // If app.name=Jetleaf
  /// resolver.resolvePlaceholders('Welcome to #{app.name}');
  /// // → "Welcome to Jetleaf"
  /// ```
  /// {@endtemplate}
  String resolvePlaceholders(String text);

  /// {@template resolve_required_placeholders}
  /// Resolves `#{...}` placeholders in the input [text] using available properties.
  ///
  /// Throws [InvalidArgumentException] if any placeholder is unresolved.
  ///
  /// ### Example:
  /// ```dart
  /// // If app.path is not defined, this will throw
  /// resolver.resolveRequiredPlaceholders('Path: #{app.path}');
  /// ```
  /// {@endtemplate}
  String resolveRequiredPlaceholders(String text);

  /// {@template suggestions}
  /// Returns a list of suggestions for the given key.
  /// 
  /// This is useful when optional configuration might exist.
  /// 
  /// ### Example:
  /// ```dart
  /// final suggestions = resolver.suggestions('app.name');
  /// ```
  /// {@endtemplate}
  List<String> suggestions(String key);
}

/// {@template configurable_property_resolver}
/// A specialized [PropertyResolver] that allows full control over property
/// placeholder behavior and type conversion logic using a configurable
/// [ConfigurableConversionService].
///
/// This interface enables:
/// - Custom placeholder syntax configuration (prefix, suffix, separator, escape).
/// - Tolerance or strictness for unresolvable nested placeholders.
/// - Custom [Converter] registration.
/// - Required property validation.
///
/// ---
///
/// ### 🔁 Example:
/// ```dart
/// final resolver = MyPropertyResolver();
/// resolver.setPlaceholderPrefix('#{');
/// resolver.setPlaceholderSuffix('}');
/// resolver.setValueSeparator(':');
/// resolver.setEscapeCharacter(r'\');
/// resolver.setIgnoreUnresolvableNestedPlaceholders(false);
///
/// resolver.getConversionService().addConverter(StringToDurationConverter());
/// ```
///
/// This is intended for internal use by [Environment] implementations and
/// advanced property injection infrastructure.
/// {@endtemplate}
abstract interface class ConfigurablePropertyResolver extends PropertyResolver {
  /// {@macro configurable_property_resolver}
  const ConfigurablePropertyResolver();

  /// Returns the [ConfigurableConversionService] used to perform type conversions.
  ///
  /// This allows dynamic registration of custom [Converter] or [ConverterFactory] instances:
  ///
  /// ```dart
  /// configurablePropertyResolver.getConversionService()
  ///     .addConverter(StringToUriConverter());
  /// ```
  ConfigurableConversionService getConversionService();

  /// Replaces the underlying [ConfigurableConversionService] used for type conversions.
  ///
  /// ⚠️ It's usually preferable to mutate the existing conversion service
  /// (via [getConversionService]) rather than replacing it entirely.
  void setConversionService(ConfigurableConversionService conversionService);

  /// Sets the prefix that identifies a placeholder in property values.
  ///
  /// For example, in `#{host}`, the prefix is `'#{'`.
  void setPlaceholderPrefix(String placeholderPrefix);

  /// Sets the suffix that identifies the end of a placeholder in property values.
  ///
  /// For example, in `#{host}`, the suffix is `'}'`.
  void setPlaceholderSuffix(String placeholderSuffix);

  /// Sets the separator for default values within placeholders.
  ///
  /// For example, `#{host:localhost}` uses `':'` as the separator.
  void setValueSeparator(String? valueSeparator);

  /// Sets the escape character used to ignore placeholder prefix and separator.
  ///
  /// For example, `\#{host}` will be treated as a literal instead of a placeholder.
  void setEscapeCharacter(Character? escapeCharacter);

  /// Enables or disables ignoring unresolvable nested placeholders.
  ///
  /// If `false`, unresolved nested placeholders will throw an exception.
  /// If `true`, unresolved placeholders will remain in their original form (e.g., `#{...}`).
  void setIgnoreUnresolvableNestedPlaceholders(bool ignoreUnresolvableNestedPlaceholders);

  /// Sets the list of property names that are required to be present and non-null.
  void setRequiredProperties(List<String> requiredProperties);

  /// Validates that all required properties are present and non-null.
  ///
  /// Throws [MissingRequiredPropertiesException] if any required properties are missing.
  void validateRequiredProperties();
}