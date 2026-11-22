// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
//
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'type_reifier.dart';

/// {@template jetleaf_standard_type_reifier}
/// Default generic implementation of [TypeReifier] bound to a compile-time
/// type parameter [T].
///
/// Instances of [StandardTypeReifier] are lightweight `const` singletons
/// registered automatically by `MaterializedLibrary.registerType<T>` during
/// AOT initialization or when `Class<T>` handles are constructed.
///
/// ### Usage Example
/// ```dart
/// const reifier = StandardTypeReifier<User>();
/// final users = reifier.createList([user1, user2]);
/// assert(users is List<User>);
/// ```
///
/// ### See Also
/// - [TypeReifier]
/// - [MaterializedLibrary]
/// {@endtemplate}
final class StandardTypeReifier<T> implements TypeReifier {
  /// {@macro jetleaf_standard_type_reifier}
  const StandardTypeReifier();

  @override
  Type getType() => T;

  @override
  Type getListType({bool nullable = false}) => nullable ? List<T?> : List<T>;

  @override
  Type getSetType({bool nullable = false}) => nullable ? Set<T?> : Set<T>;

  @override
  Type getIterableType({bool nullable = false}) => nullable ? Iterable<T?> : Iterable<T>;

  @override
  bool isInstance(Object? value) => value is T;

  @override
  bool isListInstance(Object? value, {bool nullable = false}) =>
      nullable ? value is List<T?> : value is List<T>;

  @override
  bool isSetInstance(Object? value, {bool nullable = false}) =>
      nullable ? value is Set<T?> : value is Set<T>;

  @override
  List<Object?> createList([Iterable<dynamic>? elements, bool nullable = false]) {
    if (elements == null) {
      return nullable ? <T?>[] : <T>[];
    }
    if (!nullable && elements is List<T>) {
      return elements;
    }
    if (nullable && elements is List<T?>) {
      return elements;
    }
    return nullable ? List<T?>.from(elements) : List<T>.from(elements);
  }

  @override
  Set<Object?> createSet([Iterable<dynamic>? elements, bool nullable = false]) {
    if (elements == null) {
      return nullable ? <T?>{} : <T>{};
    }
    if (!nullable && elements is Set<T>) {
      return elements;
    }
    if (nullable && elements is Set<T?>) {
      return elements;
    }
    return nullable ? Set<T?>.from(elements) : Set<T>.from(elements);
  }

  @override
  Iterable<Object?> createIterable([Iterable<dynamic>? elements, bool nullable = false]) {
    if (elements != null) {
      if (!nullable && elements is Iterable<T>) {
        return elements;
      }
      if (nullable && elements is Iterable<T?>) {
        return elements;
      }
    }
    return createList(elements, nullable);
  }

  @override
  Map<Object?, Object?> createMapWithValue(
    TypeReifier valueReifier, [
    Map<dynamic, dynamic>? entries,
    bool nullableValue = false,
  ]) => valueReifier.createMapWithKey<T>(entries, nullableValue);

  @override
  Map<K, Object?> createMapWithKey<K>([
    Map<dynamic, dynamic>? entries,
    bool nullableValue = false,
  ]) {
    if (entries == null || entries.isEmpty) {
      return nullableValue ? <K, T?>{} : <K, T>{};
    }
    if (!nullableValue && entries is Map<K, T>) {
      return entries;
    }
    if (nullableValue && entries is Map<K, T?>) {
      return entries;
    }
    return nullableValue
        ? <K, T?>{for (final entry in entries.entries) entry.key as K: entry.value as T?}
        : <K, T>{for (final entry in entries.entries) entry.key as K: entry.value as T};
  }

  @override
  TypeReifier getListReifier({bool nullable = false}) =>
      nullable ? StandardTypeReifier<List<T?>>() : StandardTypeReifier<List<T>>();

  @override
  TypeReifier getSetReifier({bool nullable = false}) =>
      nullable ? StandardTypeReifier<Set<T?>>() : StandardTypeReifier<Set<T>>();

  @override
  TypeReifier getMapReifierWithValue(TypeReifier valueReifier, {bool nullableValue = false}) =>
      valueReifier.getMapReifierWithKey<T>(nullableValue: nullableValue);

  @override
  TypeReifier getMapReifierWithKey<K>({bool nullableValue = false}) =>
      nullableValue ? StandardTypeReifier<Map<K, T?>>() : StandardTypeReifier<Map<K, T>>();
}