import 'package:jetleaf_lang/lang.dart';

/// {@template property_source}
/// A base abstraction representing a source of key-value properties, such as
/// maps, environment variables, or configuration files.
///
/// Each [PropertySource] has a unique [_name] and a backing [_source] of type `T`,
/// which holds the actual data. Concrete subclasses implement lookup behavior
/// using [containsProperty] and [getProperty].
///
/// Common implementations include:
/// - [MapPropertySource]
/// - [PropertiesPropertySource]
///
/// This abstraction allows a flexible property resolution system where multiple
/// sources can be layered and resolved by a resolver such as
/// [PropertySourcesPropertyResolver].
///
/// ### Example usage:
///
/// ```dart
/// class MyEnvSource extends PropertySource<Map<String, String>> {
///   MyEnvSource(String name, Map<String, String> source) : super(name, source);
///
///   @override
///   bool containsProperty(String name) => source.containsKey(name);
///
///   @override
///   Object? getProperty(String name) => source[name];
/// }
///
/// final env = MyEnvSource('env', {'APP_ENV': 'prod'});
/// print(env.getProperty('APP_ENV')); // prod
/// ```
/// {@endtemplate}
@Generic(PropertySource)
abstract class PropertySource<T> with EqualsAndHashCode {
  /// {@template property_source_name}
  /// The unique name that identifies this property source. 
  /// Typically used for logging, debugging, and source resolution order.
  ///
  /// Example: `"applicationConfig"`, `"systemEnvironment"`, etc.
  /// {@endtemplate}
  final String _name;

  /// {@template property_source_source}
  /// The underlying object that holds the raw property data.
  ///
  /// For example:
  /// - A `Map<String, Object>` for in-memory key-value sources
  /// - A `Properties` object for Java-style property files
  /// - A file, YAML map, or even a shell environment variable map.
  ///
  /// Subclasses are expected to access this during lookups.
  /// {@endtemplate}
  final T _source;

  /// {@macro property_source}
  PropertySource(String name, T source) : _name = name, _source = source;

  /// {@macro property_source}
  ///
  /// Creates a named property source without any backing source.
  /// Useful for stubs or symbolic sources.
  PropertySource.named(String name) : this(name, Object() as T);

  /// Returns `true` if this property source contains a value for the given
  /// property [name].
  ///
  /// This method delegates to [getProperty], interpreting any non-`null` value
  /// as presence of the property. Concrete subclasses may override this for
  /// more efficient lookups (e.g., direct `Map.containsKey` checks), but the
  /// default implementation provides a safe, consistent fallback.
  ///
  /// This method does **not** distinguish between:
  /// - missing properties, and
  /// - properties explicitly set to `null`
  ///
  /// because property sources commonly treat `null` as “not defined.”
  bool containsProperty(String name) => (getProperty(name) != null);

  /// Retrieves the value associated with the given property [name], or `null`
  /// if the property is not present in this source.
  ///
  /// Subclasses must provide the concrete lookup behavior appropriate for the
  /// underlying [_source] type. For example:
  /// - A map-based source may return `_source[name]`
  /// - A file-based source may perform key normalization or parsing
  /// - An environment variable source may apply case or platform rules
  ///
  /// Returning `null` indicates absence of a value and is used internally by
  /// [containsProperty] and external resolvers such as
  /// [PropertySourcesPropertyResolver] to determine whether a property exists.
  Object? getProperty(String name);

  /// Returns the unique, human-readable name of this property source.
  ///
  /// {@macro property_source_name}
  ///
  /// This identifier is typically used for:
  /// - debugging and diagnostic output
  /// - resolution ordering when multiple sources are layered
  /// - logs showing which source contributed a given property
  ///
  /// The name does **not** necessarily correspond to a filename or path; it is
  /// simply an identifier assigned at construction.
  String getName() => _name;

  /// Returns the underlying source object from which property data is retrieved.
  ///
  /// {@macro property_source_source}
  ///
  /// Consumers rarely need this directly, but subclasses rely on it to
  /// implement [getProperty] and [containsProperty]. It may represent a map,
  /// structured configuration object, parsed YAML/JSON tree, or any custom
  /// property container.
  T getSource() => _source;

  @override
  List<Object?> equalizedProperties() => [_name, _source];

  @override
  String toString() => "$runtimeType(name: $_name, source: $_source)";
}