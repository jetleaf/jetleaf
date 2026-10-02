import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_logging/logging.dart';

import '../property_source/property_source.dart';
import '../property_source/property_sources.dart';
import 'abstract_property_resolver.dart';

/// {@template property_sources_property_resolver}
/// A concrete implementation of [AbstractPropertyResolver] that retrieves
/// property values from a collection of [PropertySource]s managed by a
/// [MutablePropertySources] container.
///
/// This class supports resolving placeholders in property values and converting
/// properties to specific types using a registered [ConversionService].
///
/// ### Example usage:
///
/// ```dart
/// final sources = MutablePropertySources();
/// sources.addPropertySource(MapPropertySource('config', {'app.name': 'Jetleaf'}));
///
/// final resolver = PropertySourcesPropertyResolver(sources);
/// print(resolver.getProperty('app.name')); // Jetleaf
/// print(resolver.getPropertyWithDefault('app.port', '8080')); // 8080
/// ```
///
/// Placeholder resolution:
///
/// ```dart
/// sources.addPropertySource(MapPropertySource('env', {
///   'host': 'localhost',
///   'url': 'http://${host}:8080'
/// }));
///
/// print(resolver.resolvePlaceholders('API: ${url}')); // API: http://localhost:8080
/// ```
/// {@endtemplate}
class PropertySourcesPropertyResolver extends AbstractPropertyResolver {
  /// The collection of [PropertySource] instances from which this resolver
  /// retrieves property values.
  ///
  /// The list is typically managed by a [MutablePropertySources] container,
  /// which defines both the **ordering** and **precedence** used during
  /// property lookup.
  ///
  /// - The *first* matching property source in iteration order wins.
  /// - May be `null` if no property sources were configured.
  ///
  /// This field is consulted internally by lookup operations such as
  /// [containsProperty], [getProperty], and type-conversion retrieval methods.
  final PropertySources? propertySources;

  /// {@macro property_sources_property_resolver}
  PropertySourcesPropertyResolver(this.propertySources);

  @override
  bool containsProperty(String key) {
    if (propertySources case final sources?) {
      return sources.any((source) => source.containsProperty(key));
    }
    
		return false;
  }

  @override
  String? getProperty(String key, [String? defaultValue]) => _getProperty(key, Class<String>(), true) ?? defaultValue;

  @override
  T? getPropertyAs<T>(String key, Class<T> targetType, [T? defaultValue]) => _getProperty(key, targetType, true) ?? defaultValue;
  
  @override
  String? getPropertyAsRawString(String key) => _getProperty(key, Class<String>(), false);

  /// Internal property lookup routine that performs a full-resolution search
  /// across all configured [propertySources].
  ///
  /// ### Behavior
  /// - Searches each [PropertySource] in iteration order.
  /// - Logs every lookup attempt at **TRACE** level for diagnostic visibility.
  /// - Returns the first non-null value encountered.
  /// - Optionally resolves nested placeholder expressions (e.g. `"${host}"`).
  /// - Converts the raw value to the requested [targetValueType] using
  ///   [convertValueIfNecessary].
  ///
  /// ### Parameters
  /// - `key` — the property name to search for.
  /// - `targetValueType` — the desired type for the returned value.
  /// - `resolveNestedPlaceholders` — when `true`, placeholder expressions
  ///   inside string values are resolved before conversion.
  ///
  /// ### Logging
  /// - Logs every search attempt against each property source.
  /// - Logs the first successful match via [_logFound].
  /// - Logs a miss if no sources contain the requested key.
  ///
  /// ### Returns
  /// - The converted value of type `T`, or `null` if not found.
  ///
  /// This method is the central workhorse for all property retrieval APIs,
  /// including `getProperty`, `getPropertyAs<T>`, and raw string accessors.
  T? _getProperty<T>(String key, Class<T> targetValueType, bool resolveNestedPlaceholders) {
		if (propertySources case final sources?) {
			for (final propertySource in sources) {
        environmentLoggingListener.put(LogLevel.TRACE, "Searching for key '$key' in PropertySource '${propertySource.getName()}'");

				if (propertySource.getProperty(key) case Object value?) {
					if (resolveNestedPlaceholders) {
						if (value is String) {
							value = super.resolveNestedPlaceholders(value);
						} else if (value is String && targetValueType == Class<String>()) {
							value = super.resolveNestedPlaceholders(value.toString());
						}
					}

					_logFound(key, propertySource, value);
					return convertValueIfNecessary(value, targetValueType);
				}
			}
		}

    environmentLoggingListener.put(LogLevel.TRACE, "Could not find key '$key' in any property source");
		return null;
	}

  /// Logs a successful property lookup for diagnostic and traceability purposes.
  ///
  /// This method is invoked whenever a property key is found in a
  /// [PropertySource], immediately before type conversion is performed.
  ///
  /// ### Logging Details
  /// - Logged at **DEBUG** level.
  /// - Includes:
  ///   - The property key
  ///   - The source that provided the value
  ///   - The runtime type of the resolved raw value
  ///
  /// Example log output:
  /// ```
  /// Found key 'app.port' in PropertySource 'config' with value of type String
  /// ```
  ///
  /// This message is particularly useful when analyzing property precedence,
  /// debugging configuration issues, or tracing runtime resolution paths.
  void _logFound(String key, PropertySource propertySource, Object value) {
    environmentLoggingListener.put(LogLevel.DEBUG, "Found key '$key' in PropertySource '${propertySource.getName()}' with value of type ${value.runtimeType}");
	}

  @override
  List<String> suggestions(String key) {
    List<String> suggestions = [];
    if (propertySources case final sources?) {
      for (final propertySource in sources) {
        if (propertySource.getName().contains(key) || propertySource.getName().equals(key)) {
          suggestions.add(propertySource.getName());
        }
      }
    }

    return suggestions;
  }
}