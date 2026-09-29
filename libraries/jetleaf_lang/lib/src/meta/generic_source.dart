import 'class/class.dart';

/// {@template generic_source}
/// A reflective abstraction for extracting **generic type information** from
/// parameterized classes such as collections, maps, and other templated types.
///
/// This interface provides a consistent API to query the key type,
/// component (element) type, and all declared type parameters of a given class.
///
/// ### Purpose
/// Many Dart runtime systems erase generic type information (type erasure).
/// [GenericSource] allows frameworks like Jetleaf to retrieve and reason about
/// generic metadata, enabling features such as:
/// - Runtime serialization and deserialization
/// - Request parameter binding
/// - Dynamic type inspection
/// - Generic-aware dependency injection
///
/// ### Example
/// ```dart
/// final clazz = Class.forType<Map<String, int>>();
/// final source = clazz;
///
/// final keyType = source.keyType<String>();     // -> Class<String>
/// final valueType = source.componentType<int>(); // -> Class<int>
/// ```
///
/// ### Notes
/// - Implementations should always prefer compile-time type hints where possible.
/// - If a type parameter cannot be resolved, return `Class<dynamic>`
///   or `null` depending on the context.
/// - This interface is meant for **framework and reflection internals**, not for
///   application-level use.
/// {@endtemplate}
abstract interface class GenericSource {
  /// {@macro generic_class_key_type}
  ///
  /// Retrieves the key type (`K`) of a **map-like** or **pair-like** generic structure.
  ///
  /// ### Common Scenarios
  /// - Maps: `Map<K, V>` → returns `Class<K>`
  /// - Pairs: `Tuple<K, V>` → returns `Class<K>`
  /// - Non-map classes: returns `Class<dynamic>` or `null`
  ///
  /// ### Example
  /// ```dart
  /// final mapClass = Class.forType<Map<String, int>>();
  /// final keyType = mapClass.asGenericSource().keyType<String>();
  /// print(keyType.getName()); // 'String'
  /// ```
  Class<K>? keyType<K>();

  /// {@macro generic_class_component_type}
  ///
  /// Retrieves the element or value type (`C`) of a **collection-like**
  /// or **container-like** generic structure.
  ///
  /// ### Supported Generic Types
  /// - Lists: `List<T>` → returns `Class<T>`
  /// - Sets: `Set<T>` → returns `Class<T>`
  /// - Maps: `Map<K, V>` → returns `Class<V>`
  /// - Queues, Streams, or any class with a single generic parameter.
  ///
  /// ### Example
  /// ```dart
  /// final listClass = Class.forType<List<double>>();
  /// final componentType = listClass.asGenericSource().componentType<double>();
  /// print(componentType.getName()); // 'double'
  /// ```
  Class<C>? componentType<C>();

  /// {@macro class_get_type_parameters}
  ///
  /// Returns all declared type parameters of this class in the order
  /// they appear in the class declaration.
  ///
  /// ### Example
  /// ```dart
  /// class Pair<K, V> {}
  /// final clazz = Class.forType<Pair>();
  /// final params = clazz.getTypeParameters();
  ///
  /// print(params.map((p) => p.getName())); // ['K', 'V']
  /// ```
  ///
  /// ### Returns
  /// - A list of [Class] objects representing each generic parameter.
  /// - Returns an empty list for non-generic types.
  Iterable<Class> getTypeParameters();

  /// Checks if this class represents a key-value pair type.
  ///
  /// {@template class_is_key_value_paired}
  /// Returns:
  /// - `true` for Map and Map-like types
  /// - `false` for other collection types
  /// {@endtemplate}
  bool isKeyValuePaired();

  /// Checks if this class has generic type parameters.
  /// 
  /// {@template class_has_generic}
  /// Returns:
  /// - `true` if this class has generic type parameters
  /// - `false` otherwise
  /// {@endtemplate}
  bool hasGenerics();
}