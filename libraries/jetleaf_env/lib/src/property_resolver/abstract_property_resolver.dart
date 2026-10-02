import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_logging/logging.dart';
import 'package:jetleaf_utils/utils.dart';
import 'package:jetleaf_convert/convert.dart';
import 'package:meta/meta.dart';

import '../exceptions.dart';
import 'property_resolver.dart';

/// {@template environment_logging_listener}
/// A reactive listener that holds environment-specific logging configuration.
///
/// This listener tracks a mapping of [LogLevel]s to string values, typically
/// representing log output destinations or formatting rules. It allows
/// dynamic observation of logging settings within the environment context,
/// enabling other parts of the system to respond when logging configuration
/// changes.
///
/// ### Example
/// ```dart
/// // Update the logging configuration at runtime
/// environmentLoggingListener.value = {
///   LogLevel.info: 'stdout',
///   LogLevel.error: 'stderr',
/// };
///
/// // Observe changes to logging configuration
/// environmentLoggingListener.listen((config) {
///   print('Logging updated: $config');
/// });
/// ```
/// {@endtemplate}
final environmentLoggingListener = Obs<Map<LogLevel, String>>({});

/// {@template abstract_property_resolver}
/// An abstract base implementation of [ConfigurablePropertyResolver] that provides
/// common functionality for resolving property placeholders, type conversion,
/// and required property validation.
///
/// This class centralizes configuration for:
/// - Placeholder syntax (prefix, suffix, and value separators).
/// - Escape characters for literal placeholders.
/// - Integration with a [ConfigurableConversionService] for type-safe conversions.
///
/// Subclasses are expected to implement:
/// - [getProperty] → Retrieve a property value as a string or typed object.
/// - [containsProperty] → Check whether a property key exists.
/// - Any additional accessors required for property resolution.
///
/// ### Responsibilities
/// - Resolving nested placeholders in property values.
/// - Delegating conversion to the active [ConversionService].
/// - Handling both optional and required property lookups.
/// - Providing hooks for ignoring or enforcing unresolvable placeholders.
///
/// ### Example
/// ```dart
/// class EnvPropertyResolver extends AbstractPropertyResolver {
///   final Map<String, String> _env;
///
///   EnvPropertyResolver(this._env);
///
///   @override
///   String? getProperty(String key) => _env[key];
///
///   @override
///   bool containsProperty(String key) => _env.containsKey(key);
/// }
///
/// void main() {
///   final resolver = EnvPropertyResolver({'app.name': 'Jetleaf'});
///   final value = resolver.resolveNestedPlaceholders('Welcome to \${app.name}');
///   print(value); // "Welcome to Jetleaf"
/// }
/// ```
/// {@endtemplate}
abstract class AbstractPropertyResolver implements ConfigurablePropertyResolver {
  /// {@macro abstract_property_resolver}
  AbstractPropertyResolver();

  /// The conversion service used for converting property values to target types.
	ConfigurableConversionService? _conversionService;

  /// The placeholder helper used for resolving placeholders.
  /// 
  /// This is used for non-strict placeholder resolution.
	PropertyPlaceholderHelper? _nonStrictHelper;

  /// The placeholder helper used for resolving placeholders.
  /// 
  /// This is used for strict placeholder resolution.
	PropertyPlaceholderHelper? _strictHelper;

  /// If `true`, unresolvable nested placeholders will be ignored
  /// instead of throwing an exception. Default is `false`.
	bool _ignoreUnresolvableNestedPlaceholders = false;

  /// The prefix used to denote the beginning of a placeholder.
  ///
  /// Default is `#{`.
	String _placeholderPrefix = SystemPropertyUtils.PLACEHOLDER_PREFIX;

  /// The suffix used to denote the end of a placeholder.
  ///
  /// Default is `}`.
	String _placeholderSuffix = SystemPropertyUtils.PLACEHOLDER_SUFFIX;

  /// Optional separator between property key and default value in a placeholder.
  ///
  /// For example: `#{my.prop:default}`. Default is `:`. Can be `null`.
	String? _valueSeparator = SystemPropertyUtils.VALUE_SEPARATOR;

  /// Optional character used to escape placeholder syntax. Default is `null`.
	Character? _escapeCharacter;

  /// List of required property keys that must be present in the environment.
  ///
  /// If any are missing, [validateRequiredProperties] will throw.
	final Set<String> _requiredProperties = {};

  // ---------------------------------------------------------------------------------------------------------
  // Overridden methods
  // ---------------------------------------------------------------------------------------------------------

  @override
  ConfigurableConversionService getConversionService() {
    // Need to provide an independent DefaultConversionService, not the
		// shared DefaultConversionService used by PropertySourcesPropertyResolver.
		ConfigurableConversionService? cs = _conversionService;
		if (cs == null) {
			return synchronized(this, () {
				cs = _conversionService;
				if (cs == null) {
					cs = DefaultConversionService();
					_conversionService = cs;
				}

        return cs!;
			});
		}
		return cs;
  }

  @override
  void setConversionService(ConfigurableConversionService service) {
    _conversionService = service;
  }

  @override
  void setPlaceholderPrefix(String placeholderPrefix) {
		_placeholderPrefix = placeholderPrefix;
	}

  @override
  void setPlaceholderSuffix(String placeholderSuffix) {
		_placeholderSuffix = placeholderSuffix;
	}

  @override
  void setValueSeparator(String? valueSeparator) {
		_valueSeparator = valueSeparator;
	}

  @override
  void setEscapeCharacter(Character? escapeCharacter) {
		_escapeCharacter = escapeCharacter;
	}

  @override
  void setIgnoreUnresolvableNestedPlaceholders(bool ignoreUnresolvableNestedPlaceholders) {
		_ignoreUnresolvableNestedPlaceholders = ignoreUnresolvableNestedPlaceholders;
	}

  @override
  void setRequiredProperties(List<String> requiredProperties) {
		_requiredProperties.addAll(requiredProperties);
	}

  @override
  void validateRequiredProperties() {
    MissingRequiredPropertiesException ex = MissingRequiredPropertiesException();
		for (final key in _requiredProperties) {
			if (getProperty(key) == null) {
				ex.addMissingRequiredProperty(key);
			}
		}

		if (ex.getMissingRequiredProperties().isNotEmpty) {
			throw ex;
		}
  }

  @override
  bool containsProperty(String key) => getProperty(key) != null;

  @override
  String? getProperty(String key, [String? defaultValue]) => getPropertyAs<String>(key, Class<String>(), defaultValue);

  @override
  String getRequiredProperty(String key) {
		if (getProperty(key) case final value?) {
			return value;
		}

		throw IllegalStateException("Required key '$key' not found");
	}

  @override
  T getRequiredPropertyAs<T>(String key, Class<T> valueType) {
		if (getPropertyAs<T>(key, valueType) case final value?) {
			return value;
		}

		throw IllegalStateException("Required key '$key' not found");
	}

  @override
  String resolvePlaceholders(String text) {
		_nonStrictHelper ??= _createPlaceholderHelper(true);
		return _doResolvePlaceholders(text, _nonStrictHelper!);
	}

  @override
  String resolveRequiredPlaceholders(String text) {
		_strictHelper ??= _createPlaceholderHelper(false);
		return _doResolvePlaceholders(text, _strictHelper!);
	}

  // ---------------------------------------------------------------------------------------------------------
  // Protected methods
  // ---------------------------------------------------------------------------------------------------------

  /// {@template resolve_nested_placeholders}
  /// Resolve nested placeholders within a given [value].
  ///
  /// This method inspects the input string and replaces placeholders using
  /// the configured [PropertyPlaceholderHelper]. It differentiates between
  /// two modes:
  ///
  /// - **Ignore unresolvable placeholders** → calls [resolvePlaceholders].
  /// - **Require resolvable placeholders** → calls [resolveRequiredPlaceholders].
  ///
  /// If the input [value] is empty, it is returned as-is without processing.
  ///
  /// ### Example
  /// ```dart
  /// final result = resolveNestedPlaceholders('Hello \${user.name}');
  /// print(result); // "Hello Alice" (assuming user.name=Alice)
  /// ```
  /// {@endtemplate}
  @protected
  String resolveNestedPlaceholders(String value) {
    if (value.isEmpty) {
      return value;
    }
    
    return (_ignoreUnresolvableNestedPlaceholders ? resolvePlaceholders(value) : resolveRequiredPlaceholders(value));
  }

  /// {@template create_placeholder_helper}
  /// Create a new instance of [PropertyPlaceholderHelper].
  ///
  /// This helper encapsulates placeholder parsing rules such as:
  /// - [prefix] and [suffix] used to denote placeholders (e.g., `\${...}`).
  /// - A [separator] for default values.
  /// - An [escape character] for literal placeholders.
  /// - Whether unresolvable placeholders should be ignored.
  ///
  /// ### Example
  /// ```dart
  /// final helper = _createPlaceholderHelper(true);
  /// final result = helper.replacePlaceholdersWithResolver(
  ///   'Database: \${db.name:defaultDB}',
  ///   (key) => properties[key],
  /// );
  /// ```
  /// {@endtemplate}
  PropertyPlaceholderHelper _createPlaceholderHelper(bool ignoreUnresolvablePlaceholders) {
    return PropertyPlaceholderHelper.more(
      _placeholderPrefix,
      _placeholderSuffix,
      _valueSeparator,
      _escapeCharacter,
      ignoreUnresolvablePlaceholders,
    );
  }

  /// {@template do_resolve_placeholders}
  /// Perform placeholder resolution on a [text] string using a [helper].
  ///
  /// This delegates to [PropertyPlaceholderHelper.replacePlaceholdersWithResolver],
  /// passing in a resolver that retrieves property values using
  /// [getPropertyAsRawString].
  ///
  /// ### Example
  /// ```dart
  /// final resolved = _doResolvePlaceholders(
  ///   'Host: \${server.host}, Port: \${server.port}',
  ///   helper,
  /// );
  /// ```
  /// {@endtemplate}
  String _doResolvePlaceholders(String text, PropertyPlaceholderHelper helper) {
    return helper.replacePlaceholdersWithResolver(text, (key) => getPropertyAsRawString(key));
  }

  /// {@template get_property_as_raw_string}
  /// Retrieve the raw property value for the given [key].
  ///
  /// Implementations should return the string value of a property **without**
  /// applying any type conversion or placeholder resolution. May return `null`
  /// if the property is not defined.
  ///
  /// This method is **protected** and intended for use by subclasses that
  /// implement property resolution strategies (e.g., environment variables,
  /// configuration files).
  /// {@endtemplate}
  @protected
  String? getPropertyAsRawString(String key);

  /// {@template convert_value_if_necessary}
  /// Convert a given [value] into the specified [targetType] if necessary.
  ///
  /// This method uses a [ConversionService] to handle type conversions.
  /// If no conversion service is explicitly set, it falls back to
  /// [DefaultConversionService.getCommonInstance].
  ///
  /// If the [targetType] is `null`, the value is simply cast to [T].
  ///
  /// ### Parameters
  /// - [value]: The input object to convert.
  /// - [targetType]: The desired target type.
  /// - [source]: An optional [Class] describing the source type (used for
  ///   conversion context).
  ///
  /// ### Example
  /// ```dart
  /// final result = convertValueIfNecessary<int>('42', Class<int>(null, 'dart'));
  /// print(result); // 42
  /// ```
  /// {@endtemplate}
  T? convertValueIfNecessary<T>(Object value, Class<T>? targetType, [Class? source]) {
    if (targetType == null) {
      return value as T;
    }

    ConversionService? conversionServiceToUse = _conversionService;
    if (conversionServiceToUse == null) {
      // Avoid initialization of shared DefaultConversionService if
      // no standard type conversion is needed in the first place...
      if (targetType.isInstance(value)) {
        return value as T;
      }
      conversionServiceToUse = DefaultConversionService.getCommonInstance();
    }

    source ??= value.getClass();
    return conversionServiceToUse.convert<T>(value, targetType, source.getQualifiedName());
  }
}