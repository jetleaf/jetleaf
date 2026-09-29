import 'property_source.dart';

/// {@template map_property_source}
/// A [PropertySource] implementation backed by a [Map] of key-value pairs.
///
/// This class allows accessing properties from an in-memory map, making it
/// suitable for programmatically defined configurations such as application
/// defaults, test configurations, or runtime-supplied settings.
///
/// It supports property lookup via [containsProperty] and [getProperty].
///
/// ### Example usage:
///
/// ```dart
/// final config = {
///   'app.name': 'Jetleaf',
///   'app.port': 8080,
/// };
///
/// final propertySource = MapPropertySource('defaultConfig', config);
///
/// print(propertySource.containsProperty('app.name')); // true
/// print(propertySource.getProperty('app.port')); // 8080
/// ```
///
/// This can be added to a [MutablePropertySources] collection for use with
/// a [PropertySourcesPropertyResolver].
/// {@endtemplate}
class MapPropertySource extends PropertySource<Map<String, Object>> {
  /// {@macro map_property_source}
  MapPropertySource(super.name, super.source);

  @override
  bool containsProperty(String name) => getSource().containsKey(name);

  @override
  Object? getProperty(String name) => getSource()[name];
}