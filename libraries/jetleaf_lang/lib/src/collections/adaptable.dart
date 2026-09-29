import 'dart:collection' as collection;

import 'package:jetleaf_build/jetleaf_build.dart';

import '../exceptions.dart';
import '../meta/class/class.dart';
import 'array_list.dart';
import 'hash_map.dart';
import 'hash_set.dart';

/// {@template jetleaf_adaptable_list}
/// A specialized **list collection** that can **adapt itself or another source**
/// into a strongly-typed [List] of elements.
///
/// The [AdaptableList] extends [ArrayList<Object>] and provides a generic
/// method [adapt] that converts another collection or itself into a `List<E>`.
///
/// ### Purpose
/// This class is intended to:
/// - Provide a type-safe adaptation mechanism for heterogeneous lists.
/// - Enable automatic conversion from Jetleaf-specific [ArrayList] and native
///   Dart [List] types into a typed list.
/// - Serve as a utility for frameworks, services, or libraries that require
///   generic list adaptation.
///
/// ### Features
/// - **Generic conversion:** Converts elements to a specific type [E].
/// - **Multiple source support:** Accepts [ArrayList], [List], or defaults to `this`.
/// - **Exception safety:** Throws [IllegalArgumentException] if the conversion is impossible.
///
/// ### Lifecycle and Usage
/// Each instance of [AdaptableList] can adapt itself or other compatible sources:
/// ```dart
/// final adaptable = AdaptableList();
/// adaptable.addAll([1, 2, 3]);
/// final typedList = adaptable.adapt<int>(); // List<int>
/// 
/// final anotherList = ArrayList<dynamic>()..addAll(['a', 'b']);
/// final stringList = adaptable.adapt<String>(anotherList); // List<String>
/// ```
///
/// ### Extensibility
/// - Can be subclassed to override [adapt] behavior for project-specific
///   conversion rules.
/// - Supports integration with generic frameworks or conversion services.
///
/// ### Error Handling
/// - Throws [IllegalArgumentException] when the [source] cannot be adapted.
///
/// ### See Also
/// - [ArrayList]
/// - [AdaptableMap]
/// - [AdaptableSet]
/// {@endtemplate}
final class AdaptableList extends ArrayList<Object> {
  /// Represents the metadata class for `AdaptableList`.
  /// 
  /// This can be used for reflection or type identification purposes.
  /// The `PackageNames.LANG` indicates that this class belongs to the core language package.
  static final Class<AdaptableList> CLASS = Class<AdaptableList>(null, PackageNames.LANG);

  /// {@macro jetleaf_adaptable_list}
  AdaptableList();

  /// {@macro jetleaf_adaptable_list}
  factory AdaptableList.create(List<Object> entries) {
    final list = AdaptableList();
    list.addAll(entries);
    return list;
  }

  /// Converts the given [source] or `this` into a strongly-typed [List<E>].
  ///
  /// - If [source] is an [ArrayList], each element is cast to [E].
  /// - If [source] is a Dart [List], a typed copy is returned.
  /// - Otherwise, an [IllegalArgumentException] is thrown.
  ///
  /// Example:
  /// ```dart
  /// final adaptable = AdaptableList();
  /// adaptable.addAll([1, 2, 3]);
  /// final typedList = adaptable.adapt<int>(); // List<int>
  /// ```
  List<E> adapt<E>([Object? source]) {
    source ??= this;

    if (source is ArrayList) {
      final list = ArrayList<E>();
      for (var e in source) {
        list.add(e as E);
      }

      return list;
    }

    if (source is List) {
      return List<E>.from(source);
    }

    throw IllegalArgumentException('Cannot adapt $source to List<$E>');
  }
}

/// {@template jetleaf_adaptable_map}
/// A specialized **map collection** that can **adapt itself or another source**
/// into a strongly-typed [Map] of keys and values.
///
/// The [AdaptableMap] extends [HashMap<Object, Object>] and provides a
/// generic [adapt] method to convert:
/// - Jetleaf-specific [HashMap]
/// - Dart [collection.HashMap]
/// - Native Dart [Map]
/// into a `Map<K, V>`.
///
/// ### Purpose
/// This class is intended to:
/// - Facilitate type-safe conversion for heterogeneous or dynamic maps.
/// - Allow seamless adaptation between Jetleaf and standard Dart map types.
/// - Support framework-level or service-level map transformation.
///
/// ### Features
/// - **Generic adaptation:** Converts keys and values to types [K] and [V].
/// - **Multiple source types:** Supports [HashMap], [collection.HashMap], and [Map].
/// - **Exception safety:** Throws [IllegalArgumentException] if adaptation is not possible.
///
/// ### Lifecycle and Usage
/// ```dart
/// final adaptable = AdaptableMap();
/// adaptable['key'] = 42;
/// final typedMap = adaptable.adapt<String, int>(); // Map<String, int>
///
/// final source = collection.HashMap<dynamic, dynamic>();
/// source['name'] = 'Jetleaf';
/// final map = adaptable.adapt<String, String>(source); // Map<String, String>
/// ```
///
/// ### Extensibility
/// - Subclass [AdaptableMap] to implement custom key/value conversion rules.
/// - Can integrate with conversion services or framework-specific registries.
///
/// ### Error Handling
/// - Throws [IllegalArgumentException] for unsupported sources.
///
/// ### See Also
/// - [HashMap]
/// - [AdaptableList]
/// - [AdaptableSet]
/// {@endtemplate}
final class AdaptableMap extends HashMap<Object, Object> {
  /// Represents the metadata class for `AdaptableSet`.
  /// 
  /// This can be used for reflection or type identification purposes.
  /// The `PackageNames.LANG` indicates that this class belongs to the core language package.
  static final Class<AdaptableSet> CLASS = Class<AdaptableSet>(null, PackageNames.LANG);

  /// {@macro jetleaf_adaptable_map}
  AdaptableMap();

  /// {@macro jetleaf_adaptable_map}
  factory AdaptableMap.create(Map<Object, Object> entries) {
    final map = AdaptableMap();
    map.addAll(entries);
    return map;
  }

  /// Converts the given [source] or `this` into a strongly-typed [Map<K, V>].
  ///
  /// - If [source] is [HashMap] or [collection.HashMap], keys and values are cast to [K] and [V].
  /// - If [source] is a native [Map], a typed copy is returned.
  /// - Otherwise, throws [IllegalArgumentException].
  ///
  /// Example:
  /// ```dart
  /// final adaptable = AdaptableMap();
  /// adaptable['a'] = 1;
  /// final typedMap = adaptable.adapt<String, int>(); // Map<String, int>
  /// ```
  Map<K, V> adapt<K, V>([Object? source]) {
    source ??= this;

    if (source is HashMap) {
      final map = HashMap<K, V>();
      for (var e in source.entries) {
        map[e.key as K] = e.value as V;
      }

      return map;
    }

    if (source is collection.HashMap) {
      final map = collection.HashMap<K, V>();
      for (var e in source.entries) {
        map[e.key as K] = e.value as V;
      }

      return map;
    }

    if (source is Map) {
      return Map<K, V>.from(source);
    }

    throw IllegalArgumentException('Cannot adapt $source to Map<$K, $V>');
  }
}

/// {@template jetleaf_adaptable_set}
/// A specialized **set collection** that can **adapt itself or another source**
/// into a strongly-typed [Set] of elements.
///
/// The [AdaptableSet] extends [HashSet<Object>] and provides a generic [adapt]
/// method that converts:
/// - Jetleaf-specific [HashSet]
/// - Dart [collection.HashSet]
/// - Native Dart [Set]
/// into a `Set<E>`.
///
/// ### Purpose
/// This class is intended to:
/// - Facilitate type-safe conversion for heterogeneous sets.
/// - Enable framework-level or service-level collection adaptation.
/// - Provide a consistent API across Jetleaf and standard Dart collections.
///
/// ### Features
/// - **Generic adaptation:** Converts elements to type [E].
/// - **Source flexibility:** Supports [HashSet], [collection.HashSet], and [Set].
/// - **Exception safety:** Throws [IllegalArgumentException] when conversion fails.
///
/// ### Lifecycle and Usage
/// ```dart
/// final adaptable = AdaptableSet();
/// adaptable.addAll([1, 2, 3]);
/// final typedSet = adaptable.adapt<int>(); // Set<int>
///
/// final source = collection.HashSet<dynamic>();
/// source.addAll(['a', 'b']);
/// final stringSet = adaptable.adapt<String>(source); // Set<String>
/// ```
///
/// ### Extensibility
/// - Subclass to provide custom element conversion rules.
/// - Integrate with conversion services for automatic type transformations.
///
/// ### Error Handling
/// - Throws [IllegalArgumentException] for unsupported or incompatible sources.
///
/// ### See Also
/// - [HashSet]
/// - [AdaptableList]
/// - [AdaptableMap]
/// {@endtemplate}
final class AdaptableSet extends HashSet<Object> {
  /// Represents the metadata class for `AdaptableMap`.
  /// 
  /// This can be used for reflection or type identification purposes.
  /// The `PackageNames.LANG` indicates that this class belongs to the core language package.
  static final Class<AdaptableMap> CLASS = Class<AdaptableMap>(null, PackageNames.LANG);

  /// {@macro jetleaf_adaptable_set}
  AdaptableSet();

  /// {@macro jetleaf_adaptable_set}
  factory AdaptableSet.create(List<Object> entries) {
    final set = AdaptableSet();
    set.addAll(entries);
    return set;
  }

  /// Converts the given [source] or `this` into a strongly-typed [Set<E>].
  ///
  /// - If [source] is [HashSet] or [collection.HashSet], elements are cast to [E].
  /// - If [source] is a native [Set], a typed copy is returned.
  /// - Otherwise, throws [IllegalArgumentException].
  ///
  /// Example:
  /// ```dart
  /// final adaptable = AdaptableSet();
  /// adaptable.addAll([1, 2, 3]);
  /// final typedSet = adaptable.adapt<int>(); // Set<int>
  /// ```
  Set<E> adapt<E>([Object? source]) {
    source ??= this;

    if (source is HashSet) {
      final set = HashSet<E>();
      for (var e in source) {
        set.add(e as E);
      }

      return set;
    }

    if (source is collection.HashSet) {
      final set = collection.HashSet<E>();
      for (var e in source) {
        set.add(e as E);
      }

      return set;
    }

    if (source is Set) {
      return Set<E>.from(source);
    }

    throw IllegalArgumentException('Cannot adapt $source to Set<$E>');
  }
}