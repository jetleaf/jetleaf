import 'dart:async';

import 'package:jetleaf_build/jetleaf_build.dart';

import '../exceptions.dart';
import 'obs_event.dart';
import 'obs_types.dart';

part '_obs.dart';

/// {@template obs}
/// A reactive wrapper for values, lists, or maps.
///
/// `Obs<T>` allows you to listen for changes to its internal
/// value. It supports observing:
///
/// - Single values (`ValueChanged`)
/// - List mutations (`ListChange`)
/// - Map mutations (`MapChange`)
/// - Grouped events (`BulkChange`)
///
/// You can use it in state management, reactive UIs, or any situation
/// where you need to react to changes in data structures.
///
/// ### Example (basic value)
/// ```dart
/// final obs = Obs<int>(0);
///
/// // Listen for changes
/// obs.listen((event) {
///   if (event is ValueChanged<int>) {
///     print('Value changed from ${event.oldValue} to ${event.newValue}');
///   }
/// });
///
/// obs.set(42);
/// // Prints: Value changed from 0 to 42
/// ```
///
/// ### Example (list)
/// ```dart
/// final observableList = Obs<List<String>>([]);
///
/// observableList.listen((event) {
///   if (event is ListChange<String>) {
///     print('List changed: $event');
///   }
/// });
///
/// observableList.add('apple');
/// observableList.add('banana');
/// ```
///
/// ### Example (map)
/// ```dart
/// final observableMap = Obs<Map<String, int>>({});
///
/// observableMap.listen((event) {
///   if (event is MapChange<String, int>) {
///     print('Map changed: $event');
///   }
/// });
///
/// observableMap.put('Alice', 10);
/// observableMap.put('Bob', 20);
/// ```
/// {@endtemplate}
@Generic(Obs)
abstract class Obs<T> {
  /// {@macro obs}
  factory Obs([T? initial]) => _Obs(initial);

  /// Replace the current value and emit a [ValueChanged] event.
  ///
  /// If the new value is identical to the old value, no event will
  /// be emitted unless [force] is `true`.
  ///
  /// ### Example
  /// ```dart
  /// final obs = Obs<int>(1);
  /// obs.listen((event) => print(event));
  ///
  /// obs.set(2); // Emits ValueChanged(1 -> 2)
  /// obs.set(2); // Does not emit (same value)
  /// obs.set(2, force: true); // Forces emission
  /// ```
  void set(T? newValue, {bool force = false});

  /// Subscribe to change events.
  ///
  /// Events include:
  /// - [ValueChanged]
  /// - [ListChange]
  /// - [MapChange]
  /// - [BulkChange]
  ///
  /// Returns a [StreamSubscription] that you should cancel
  /// when no longer needed.
  ///
  /// ### Example
  /// ```dart
  /// final obs = Obs<String>('hello');
  /// final sub = obs.listen((event) {
  ///   print('Observed: $event');
  /// });
  ///
  /// obs.set('world');
  /// sub.cancel();
  /// ```
  StreamSubscription<ObsEvent> listen(void Function(ObsEvent) onData);

  /// Perform multiple operations atomically.
  ///
  /// Events emitted inside [fn] are batched into a single [BulkChange].
  ///
  /// ### Example
  /// ```dart
  /// final obs = Obs<List<int>>([]);
  ///
  /// obs.listen((event) => print(event));
  ///
  /// obs.transaction(() {
  ///   obs.add(1);
  ///   obs.add(2);
  ///   obs.add(3);
  /// });
  /// // Emits one BulkChange with 3 ListChange events
  /// ```
  R transaction<R>(R Function() fn);

  // ---------- List helpers (when T is List<E>) ----------

  /// Add an element to the list.
  ///
  /// Emits a [ListChange.add] event.
  ///
  /// ### Example
  /// ```dart
  /// final obs = Obs<List<String>>([]);
  /// obs.listen((e) => print(e));
  ///
  /// obs.add('apple'); // Emits ListChange.add
  /// ```
  void add<E>(E element);

  /// Add multiple elements to the list.
  ///
  /// Emits a single [BulkChange] containing multiple [ListChange.add] events.
  void addAll<E>(Iterable<E> iterable);

  /// Remove the first occurrence of [element] from the list.
  ///
  /// Emits a [ListChange.remove] event if successful.  
  /// Returns `true` if removed, `false` otherwise.
  bool removeFromList<E>(E element);

  /// Remove the first occurrence matching [element] using equality.
  ///
  /// Unlike [removeFromList], this accepts `Object?` to handle
  /// cases where generic type `E` is unknown at compile time.
  ///
  /// Emits a [ListChange.remove] event if successful.
  bool removeFromListAny<E>(Object? element);

  /// Remove and return the element at [index].
  ///
  /// Emits a [ListChange.remove] event.
  E removeAt<E>(int index);

  /// Clear all elements from the list.
  ///
  /// Emits a [BulkChange] with multiple [ListChange.remove] events.
  void clearList<E>();

  /// Replace all elements in the list with [items].
  ///
  /// Emits a [BulkChange] with multiple `remove` and `add` events.
  void replaceAllInList<E>(Iterable<E> items);

  // ---------- Map helpers (when T is Map<K,V>) ----------

  /// Insert or update a key-value pair in the map.
  ///
  /// Emits a [MapChange.put] event.  
  /// Returns the old value if present, otherwise `null`.
  V? put<K, V>(K key, V value);

  /// Insert or update multiple key-value pairs in the map.
  ///
  /// Emits a [BulkChange] containing multiple [MapChange.put] events.
  void putAll<K, V>(Map<K, V> entries);

  /// Remove a key-value pair from the map by [key].
  ///
  /// Emits a [MapChange.remove] event.  
  /// Returns the old value if removed, otherwise `null`.
  V? removeKey<K, V>(K key);

  /// Clear all key-value pairs in the map.
  ///
  /// Emits a [BulkChange] containing one [MapChange.remove] per entry.
  void clearMap<K, V>();

  /// Dispose of this obs.
  ///
  /// After calling this, no more events will be emitted
  /// and all listeners should be considered invalid.
  Future<void> dispose();
}