import 'package:jetleaf_build/jetleaf_build.dart';

import '../extensions/primitives/string.dart';
import '../exceptions.dart';

/// {@template jetleaf_case_insensitive_map}
/// A **map that performs case-insensitive string key lookups** while preserving
/// the original casing of keys.
///
/// This map implements `Map<String, V>` and ensures that **all key lookups,
/// insertions, updates, and removals are case-insensitive**. The original
/// casing of a key is preserved for iteration, `keys`, and `entries`.
///
/// ### Rules
/// - Lookup keys are compared **case-insensitively**.  
///   e.g., `'Content-Type'`, `'content-type'`, `'CONTENT-TYPE'` all match the same entry.
/// - When inserting a key that differs only in case from an existing key,
///   the old key is replaced, but the value remains the same.
/// - Null keys are **not allowed** because the map only supports `String` keys.
/// - Values may be null if the type `V` allows it.
///
/// ### Examples
/// ```dart
/// final map = CaseInsensitiveMap<String>();
/// map['Content-Type'] = 'application/json';
/// print(map['content-type']); // 'application/json'
/// print(map['CONTENT-TYPE']); // 'application/json'
///
/// // Updating a key with different casing replaces the original key
/// map['content-type'] = 'text/html';
/// print(map['Content-Type']); // 'text/html'
/// ```
///
/// ### Edge Cases
/// | Operation | Key | Value | Result |
/// |-----------|-----|-------|--------|
/// | Insert    | 'Token' | 'abc' | Stored as 'Token' |
/// | Lookup    | 'token' | - | Returns 'abc' |
/// | Update    | 'TOKEN' | 'xyz' | Replaces 'Token', value now 'xyz' |
/// | Remove    | 'tOkEn' | - | Key removed |
///
/// ### Design Notes
/// - Uses a private map `_map` for storing keys with original casing and values.
/// - The `_findOriginalKey` method performs case-insensitive comparison for lookups.
/// - Fully compatible with standard Dart `Map<String, V>` APIs (e.g., `addAll`, `update`, `removeWhere`).
/// - Efficient for typical usage, but very large maps may have performance implications
///   because `_findOriginalKey` iterates over all keys linearly.
///
/// ### See Also
/// - [Map] — base interface implemented
/// - [HashMap] — standard Dart hash-based map
/// {@endtemplate}
@Generic(CaseInsensitiveMap)
class CaseInsensitiveMap<V> implements Map<String, V> {
  /// Internal map storing the key-value pairs with original key casing.
  final Map<String, V> _map = {};

  /// {@macro jetleaf_case_insensitive_map}
  ///
  /// Creates an empty [CaseInsensitiveMap]. You can use it like a regular Dart
  /// `Map<String, V>`, but all key lookups are **case-insensitive**.
  CaseInsensitiveMap();

  /// Creates a [CaseInsensitiveMap] containing all key-value pairs from [other].
  ///
  /// The keys from [other] will be added to this map with their original casing,
  /// but subsequent lookups will be case-insensitive.
  /// 
  /// {@macro jetleaf_case_insensitive_map}
  factory CaseInsensitiveMap.from(Map<String, V> other) {
    final map = CaseInsensitiveMap<V>();
    map.addAll(other);
    return map;
  }

  /// Creates a [CaseInsensitiveMap] from another map where the keys and values
  /// are computed from [other]'s keys and values.
  /// 
  /// {@macro jetleaf_case_insensitive_map}
  factory CaseInsensitiveMap.fromIterable(
    Iterable iterable, {
    String Function(dynamic element)? key,
    V Function(dynamic element)? value,
  }) {
    final map = CaseInsensitiveMap<V>();
    for (final element in iterable) {
      final k = key != null ? key(element) : element.toString();
      final v = value != null ? value(element) : element as V;
      map[k] = v;
    }
    return map;
  }

  /// Creates a [CaseInsensitiveMap] from the entries of [entries].
  /// 
  /// {@macro jetleaf_case_insensitive_map}
  factory CaseInsensitiveMap.fromEntries(Iterable<MapEntry<String, V>> entries) {
    final map = CaseInsensitiveMap<V>();
    map.addEntries(entries);
    return map;
  }

  /// Finds the original key in the map that matches the given key case-insensitively.
  String? _findOriginalKey(String key) {
    for (final originalKey in _map.keys) {
      if (originalKey.equalsIgnoreCase(key)) {
        return originalKey;
      }
    }
    return null;
  }

  @override
  V? operator [](Object? key) {
    if (key is! String) return null;
    final originalKey = _findOriginalKey(key);
    return originalKey != null ? _map[originalKey] : null;
  }

  @override
  void operator []=(String key, V value) {
    final originalKey = _findOriginalKey(key);
    if (originalKey != null) {
      // Key exists with different case, remove the old one
      if (originalKey != key) {
        _map.remove(originalKey);
      }
    }
    _map[key] = value;
  }

  @override
  void addAll(Map<String, V> other) {
    other.forEach((key, value) {
      this[key] = value;
    });
  }

  @override
  void addEntries(Iterable<MapEntry<String, V>> newEntries) {
    for (final entry in newEntries) {
      this[entry.key] = entry.value;
    }
  }

  @override
  Map<RK, RV> cast<RK, RV>() => _map.cast<RK, RV>();

  @override
  void clear() {
    _map.clear();
  }

  @override
  bool containsKey(Object? key) {
    if (key is! String) return false;
    return _findOriginalKey(key) != null;
  }

  @override
  bool containsValue(Object? value) => _map.containsValue(value);

  @override
  Iterable<MapEntry<String, V>> get entries => _map.entries;

  @override
  void forEach(void Function(String key, V value) action) {
    _map.forEach(action);
  }

  @override
  bool get isEmpty => _map.isEmpty;

  @override
  bool get isNotEmpty => _map.isNotEmpty;

  @override
  Iterable<String> get keys => _map.keys;

  @override
  int get length => _map.length;

  @override
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> Function(String key, V value) convert) => _map.map(convert);

  @override
  V putIfAbsent(String key, V Function() ifAbsent) {
    final originalKey = _findOriginalKey(key);
    if (originalKey != null) {
      return _map[originalKey]!;
    }
    final value = ifAbsent();
    _map[key] = value;
    return value;
  }

  @override
  V? remove(Object? key) {
    if (key is! String) return null;
    final originalKey = _findOriginalKey(key);
    return originalKey != null ? _map.remove(originalKey) : null;
  }

  @override
  void removeWhere(bool Function(String key, V value) test) {
    final keysToRemove = <String>[];
    _map.forEach((key, value) {
      if (test(key, value)) {
        keysToRemove.add(key);
      }
    });
    for (final key in keysToRemove) {
      _map.remove(key);
    }
  }

  @override
  V update(String key, V Function(V value) update, {V Function()? ifAbsent}) {
    final originalKey = _findOriginalKey(key);
    
    if (originalKey != null) {
      final newValue = update(_map[originalKey] as V);
      _map[originalKey] = newValue;
      return newValue;
    }
    
    if (ifAbsent != null) {
      final value = ifAbsent();
      _map[key] = value;
      return value;
    }
    
    throw InvalidArgumentException('Key not found: $key');
  }

  @override
  void updateAll(V Function(String key, V value) update) {
    _map.updateAll(update);
  }

  @override
  Iterable<V> get values => _map.values;

  @override
  String toString() => _map.toString();
}