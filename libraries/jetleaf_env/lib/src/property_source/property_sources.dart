import 'package:jetleaf_lang/lang.dart';

import 'property_source.dart';

/// {@template property_sources}
/// A collection of [PropertySource]s that provides lookup and stream support.
///
/// This abstract class is used in the Jetleaf environment system to hold
/// multiple `PropertySource` instances, such as system environment variables,
/// command-line arguments, or custom maps.
///
/// You can use this class to:
/// - Stream through all available property sources
/// - Check whether a named property source exists
/// - Retrieve a property source by name
///
/// Example usage:
/// ```dart
/// final sources = MyPropertySources(); // your custom implementation
/// if (sources.contains('systemEnv')) {
///   final envSource = sources.get('systemEnv');
///   print(envSource?.getProperty('HOME'));
/// }
/// ```
///
/// Subclasses must implement the [contains] and [get] methods to define how
/// sources are stored and accessed.
///
/// {@endtemplate}
abstract class PropertySources extends Iterable<PropertySource> {
  /// {@macro property_sources}
  const PropertySources();

  /// {@template property_sources_stream}
  /// Returns a [GenericStream] over all [PropertySource]s in this collection.
  ///
  /// This method allows functional-style operations over the property sources.
  /// It uses [StreamSupport.stream] internally to create the stream from
  /// the iterable.
  ///
  /// Example:
  /// ```dart
  /// sources.stream()
  ///   .filter((s) => s.name.startsWith('system'))
  ///   .forEach((s) => print(s.name));
  /// ```
  /// {@endtemplate}
  GenericStream<PropertySource> stream() => StreamSupport.stream(this);

  /// {@template property_sources_get}
  /// Returns the [PropertySource] with the given name, or `null` if not found.
  ///
  /// This method performs a lookup for a source by its name (as returned by
  /// `PropertySource.getName()`).
  ///
  /// Example:
  /// ```dart
  /// final source = sources.get('applicationConfig');
  /// if (source != null) {
  ///   print(source.getProperty('app.name'));
  /// }
  /// ```
  ///
  /// - [name]: the name of the property source to find
  /// - Returns: the [PropertySource] if present, otherwise `null`
  /// {@endtemplate}
  PropertySource? get(String name) => find((s) => s.getName().equals(name));

  /// {@template property_sources_get_property_names}
  /// Returns a list of the names of all [PropertySource]s in this collection,
  /// in iteration order.
  ///
  /// This is a convenience method for quickly inspecting or debugging the
  /// currently registered property sources without needing to traverse them.
  ///
  /// ### Example
  /// ```dart
  /// final names = sources.getPropertyNames();
  /// print(names); 
  /// // → ['systemEnvironment', 'systemProperties', 'applicationInfo', ...]
  /// ```
  ///
  /// The returned list is a snapshot and does not update if the underlying
  /// collection changes.
  /// {@endtemplate}
  List<String> getPropertyNames() => map((p) => p.getName()).toList();
}