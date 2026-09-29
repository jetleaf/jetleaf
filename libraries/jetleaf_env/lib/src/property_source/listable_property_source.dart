import 'package:jetleaf_lang/lang.dart';

import 'property_source.dart';

/// {@template enumerable_property_source}
/// A specialized [PropertySource] capable of enumerating all available property keys,
/// allowing efficient lookup operations.
///
/// Unlike generic property sources, this class supports retrieval of all known
/// property names through [getPropertyNames]. This makes methods like
/// [containsProperty] fast and lightweight, as they can check membership without
/// calling [getProperty].
///
/// Framework-level sources like environment variables, maps, or configuration files
/// often extend this class to benefit from key enumeration.
///
/// Example:
/// ```dart
/// class MapPropertySource extends ListablePropertySource<Map<String, Object>> {
///   MapPropertySource(super.name, super.source);
///
///   @override
///   List<String> getPropertyNames() => source.keys.toList();
///
///   @override
///   Object? getProperty(String name) => source[name];
/// }
/// ```
///
/// {@endtemplate}
@Generic(ListablePropertySource)
abstract class ListablePropertySource<T> extends PropertySource<T> {
  /// {@macro enumerable_property_source}
  ListablePropertySource(super.name, super.source);

  /// {@macro enumerable_property_source}
  ListablePropertySource.named(super.name) : super.named();

  @override
  bool containsProperty(String name) => getPropertyNames().contains(name);

  /// {@template enumerable_property_source_get_property_names}
  /// Returns the full list of property names known to this [PropertySource].
  ///
  /// Subclasses must implement this method to return all available keys.
  ///
  /// Example:
  /// ```dart
  /// final propertyNames = mySource.getPropertyNames();
  /// print(propertyNames); // ['host', 'port', 'username']
  /// ```
  ///
  /// This is used internally by [containsProperty] and other introspection features.
  /// {@endtemplate}
  List<String> getPropertyNames();
}