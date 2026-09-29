part of 'local_thread.dart';

/// {@template isolate_local_value_store}
/// Internal store used by [LocalThread] to maintain isolate-local state.
///
/// Each isolate can have its own unique set of thread-local values. This class
/// maps a specific [Isolate] to its corresponding [LocalThreadStorageBucket].
///
/// This store ensures that each [LocalThread] has a private, mutable
/// value scoped to the current isolate.
///
/// ### Example (Internal Usage)
/// ```dart
/// final isolate = Isolate.current;
/// final bucket = isolateLocalValueStore.getBucket<String>(isolate);
/// bucket.set('myLocalValue');
/// print(bucket.get()); // prints: myLocalValue
/// ```
///
/// This class is not intended for public use, but is essential in
/// supporting isolate-local thread-local variables.
/// {@endtemplate}
class _IsolateLocalValueStore {
  // Maps an Isolate to its ThreadLocalStorageBucket
  final Map<Isolate, Map<LocalThreadKey, LocalThreadStorageBucket<dynamic>>> _isolateValues = {};

  /// Returns the [LocalThreadStorageBucket] associated with the given [isolate].
  ///
  /// If no bucket exists for that isolate, a new one is created and cached.
  ///
  /// This method is generic and returns a [ThreadLocalStorageBucket<T>], allowing
  /// type-safe value retrieval from the thread-local context.
  ///
  /// ### Example
  /// ```dart
  /// final isolate = Isolate.current;
  /// final bucket = isolateLocalValueStore.getBucket<int>(isolate);
  /// bucket.set(99);
  /// print(bucket.get()); // prints: 99
  /// ```
  LocalThreadStorageBucket<T> getBucket<T>(Isolate isolate, LocalThreadKey key) {
    final isolateMap = _isolateValues.putIfAbsent(isolate, () => <LocalThreadKey, LocalThreadStorageBucket<dynamic>>{});
    return isolateMap.putIfAbsent(key, () => LocalThreadStorageBucket<T>(null, isolate)) as LocalThreadStorageBucket<T>;
  }
}

/// {@template isolate_local_value_store_instance}
/// Singleton instance of the [_IsolateLocalValueStore].
///
/// Used internally by [LocalThread] to retrieve per-isolate buckets.
/// {@endtemplate}
final isolateLocalValueStore = _IsolateLocalValueStore();