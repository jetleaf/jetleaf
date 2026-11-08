part of 'local_thread.dart';

/// {@template thread_local_storage_bucket}
/// A mutable storage container for a [LocalThread] value, bound to a specific [Isolate].
///
/// Internally, it uses a `List<T?>` to store a single value, which allows mutation without
/// replacing the container itself. This technique supports per-isolate scoped thread-local data.
///
/// The storage can hold only one value at a time. The `get`, `set`, and `remove` methods
/// allow access and management of the thread-local state.
///
/// Typically used internally by the [LocalThread] class to isolate thread-local
/// values per [Isolate].
///
/// ### Example
/// ```dart
/// final isolate = Isolate.current;
/// final bucket = ThreadLocalStorageBucket<String>('initial', isolate);
///
/// print(bucket.get()); // prints: initial
///
/// bucket.set('updated');
/// print(bucket.get()); // prints: updated
///
/// bucket.remove();
/// print(bucket.get()); // prints: null
/// ```
/// {@endtemplate}
@Generic(LocalThreadStorageBucket)
final class LocalThreadStorageBucket<T> {
  // Internal storage for the value.
  T? _storage;

  // The isolate this bucket is bound to.
  final Isolate _isolate;

  /// {@macro thread_local_storage_bucket}
  ///
  /// Creates a new [LocalThreadStorageBucket] bound to the given [isolate].
  /// 
  /// If [initialValue] is provided, it is stored immediately.
  LocalThreadStorageBucket(T? initialValue, Isolate isolate) : _isolate = isolate {
    if (initialValue != null) {
      _storage = initialValue;
    }
  }

  /// Returns the value stored in this bucket.
  ///
  /// If no value is present, it returns `null`.
  ///
  /// ### Example
  /// ```dart
  /// final bucket = ThreadLocalStorageBucket<int>(null, Isolate.current);
  /// print(bucket.get()); // null
  /// ```
  T? get() {
    return _storage;
  }

  /// Sets or replaces the stored value.
  ///
  /// This clears any previous value and inserts the new one.
  ///
  /// ### Example
  /// ```dart
  /// final bucket = ThreadLocalStorageBucket<int>(null, Isolate.current);
  /// bucket.set(42);
  /// print(bucket.get()); // 42
  /// ```
  void set(T value) {
    _storage = value;
  }

  /// Clears the stored value and kills the associated isolate.
  ///
  /// After calling this, the bucket is empty and the isolate is no longer running.
  ///
  /// ### Warning
  /// Killing the isolate is **destructive** and should be used with caution.
  ///
  /// ### Example
  /// ```dart
  /// final bucket = ThreadLocalStorageBucket<String>('bye', Isolate.current);
  /// bucket.remove(); // clears value and kills isolate
  /// ```
  void remove() {
    _storage = null;
  }

  /// Returns the isolate this bucket is bound to.
  ///
  /// ### Example
  /// ```dart
  /// final bucket = ThreadLocalStorageBucket<int>(null, Isolate.current);
  /// print(bucket.isolate); // prints: Isolate.current
  /// ```
  Isolate get isolate => _isolate;
}