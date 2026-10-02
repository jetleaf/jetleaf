import 'package:jetleaf_build/jetleaf_build.dart';

import '../exceptions.dart';

/// {@template custom_hash_set}
/// A custom implementation of a hash set that implements the `Set<E>` interface.
///
/// This `HashSet` stores unique elements and provides constant-time operations for
/// insertion, removal, and lookup in the average case.
///
/// It uses **open addressing with chaining** to resolve hash collisions:
/// each bucket is a list of values (`List<E>`) that share the same hash index.
///
/// When the load factor (size / capacity) exceeds 0.75, the internal
/// bucket array is resized to maintain efficiency.
///
/// ---
///
/// ### ⚙️ Design Highlights:
/// - Uses `_buckets: List<List<E>?>` for collision handling
/// - On collision: appends to the list in the corresponding bucket
/// - Grows dynamically when usage exceeds load factor threshold
///
/// ---
///
/// ### 📦 Example Usage:
/// ```dart
/// final set = HashSet<String>();
/// set.add('apple');
/// set.add('banana');
/// set.add('apple'); // Duplicate, ignored
///
/// print(set.contains('banana')); // true
/// print(set.length); // 2
/// print(set); // {apple, banana}
/// ```
///
/// {@endtemplate}
@Generic(HashSet)
class HashSet<E> implements Set<E> {
  static const int _initialCapacity = 16;
  static const double _loadFactorThreshold = 0.75;

  List<List<E>?> _buckets;
  int _size = 0;
  int _capacity;

  /// {@macro custom_hash_set}
  ///
  /// Creates an empty set with an initial capacity of 16.
  HashSet() : _capacity = _initialCapacity, _buckets = List.filled(_initialCapacity, null);

  /// Calculates the bucket index for an element.
  int _getBucketIndex(Object? element) {
    // Handle null hashCode for null elements
    final hashCode = element.hashCode;
    return (hashCode.abs() % _capacity);
  }

  /// Resizes the hash set when the load factor is exceeded.
  void _resize() {
    final oldBuckets = _buckets;
    _capacity *= 2;
    _buckets = List.filled(_capacity, null);
    _size = 0; // Reset size, as elements will be re-added

    for (final bucket in oldBuckets) {
      if (bucket != null) {
        for (final element in bucket) {
          add(element); // Re-add elements to new buckets
        }
      }
    }
  }

  @override
  bool add(E element) {
    if (_size / _capacity > _loadFactorThreshold) {
      _resize();
    }

    final index = _getBucketIndex(element);
    _buckets[index] ??= []; // Initialize bucket if null

    final bucket = _buckets[index]!;
    for (final existingElement in bucket) {
      if (existingElement == element) {
        return false; // Element already exists
      }
    }

    bucket.add(element);
    _size++;
    return true;
  }

  @override
  bool remove(Object? value) {
    if (isEmpty) return false;

    final index = _getBucketIndex(value);
    final bucket = _buckets[index];

    if (bucket != null) {
      for (int i = 0; i < bucket.length; i++) {
        if (bucket[i] == value) {
          bucket.removeAt(i);
          _size--;
          // If bucket becomes empty, set to null to save memory (optional)
          if (bucket.isEmpty) {
            _buckets[index] = null;
          }
          return true;
        }
      }
    }
    return false;
  }

  @override
  bool contains(Object? element) {
    if (isEmpty) return false;

    final index = _getBucketIndex(element);
    final bucket = _buckets[index];

    if (bucket != null) {
      for (final existingElement in bucket) {
        if (existingElement == element) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  void clear() {
    _buckets = List.filled(_initialCapacity, null);
    _capacity = _initialCapacity;
    _size = 0;
  }

  @override
  int get length => _size;

  @override
  bool get isEmpty => _size == 0;

  @override
  bool get isNotEmpty => _size > 0;

  @override
  Iterator<E> get iterator => _HashSetIterator(this);

  @override
  void addAll(Iterable<E> elements) {
    for (final element in elements) {
      add(element);
    }
  }

  @override
  Set<E> intersection(Set<Object?> other) {
    final result = HashSet<E>();
    for (final element in this) {
      if (other.contains(element)) {
        result.add(element);
      }
    }
    return result;
  }

  @override
  Set<E> union(Set<E> other) {
    final result = HashSet<E>();
    result.addAll(this);
    result.addAll(other);
    return result;
  }

  @override
  Set<E> difference(Set<Object?> other) {
    final result = HashSet<E>();
    for (final element in this) {
      if (!other.contains(element)) {
        result.add(element);
      }
    }
    return result;
  }

  @override
  E? lookup(Object? element) {
    if (isEmpty) return null;

    final index = _getBucketIndex(element);
    final bucket = _buckets[index];

    if (bucket != null) {
      for (final existingElement in bucket) {
        if (existingElement == element) {
          return existingElement;
        }
      }
    }
    return null;
  }

  @override
  Set<E> toSet() => this; // Already a Set

  @override
  String toString() {
    if (isEmpty) return '{}';
    final buffer = StringBuffer('{');
    bool first = true;
    for (final element in this) {
      if (!first) {
        buffer.write(', ');
      }
      buffer.write(element);
      first = false;
    }
    buffer.write('}');
    return buffer.toString();
  }

  @override
  bool any(bool Function(E element) test) {
    for (final element in this) {
      if (test(element)) {
        return true;
      }
    }
    return false;
  }

  @override
  Set<R> cast<R>() => Set.castFrom<E, R>(this);

  @override
  bool containsAll(Iterable<Object?> other) {
    for (final element in other) {
      if (!contains(element)) {
        return false;
      }
    }
    return true;
  }

  @override
  E elementAt(int index) {
    if (index < 0 || index >= _size) {
      throw RangeError.index(index, this, 'index', null, _size);
    }
    int count = 0;
    for (final element in this) {
      if (count == index) {
        return element;
      }
      count++;
    }
    // Should not be reached if index is valid
    throw IllegalStateException('Element not found at index $index');
  }

  @override
  bool every(bool Function(E element) test) {
    for (final element in this) {
      if (!test(element)) {
        return false;
      }
    }
    return true;
  }

  @override
  Iterable<T> expand<T>(Iterable<T> Function(E element) toElements) sync* {
    for (final element in this) {
      yield* toElements(element);
    }
  }

  @override
  E get first {
    if (isEmpty) {
      throw IllegalStateException('No element');
    }
    // Create a new iterator and move to the first element
    final iter = iterator;
    iter.moveNext();
    return iter.current;
  }

  @override
  E firstWhere(bool Function(E element) test, {E Function()? orElse}) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    if (orElse != null) {
      return orElse();
    }
    throw IllegalStateException('No element satisfies the predicate.');
  }

  @override
  T fold<T>(T initialValue, T Function(T previousValue, E element) combine) {
    T value = initialValue;
    for (final element in this) {
      value = combine(value, element);
    }
    return value;
  }

  @override
  Iterable<E> followedBy(Iterable<E> other) sync* {
    yield* this;
    yield* other;
  }

  @override
  void forEach(void Function(E element) action) {
    for (final element in this) {
      action(element);
    }
  }

  @override
  String join([String separator = ""]) {
    final buffer = StringBuffer();
    bool first = true;
    for (final element in this) {
      if (!first) {
        buffer.write(separator);
      }
      buffer.write(element.toString());
      first = false;
    }
    return buffer.toString();
  }

  @override
  E get last {
    if (isEmpty) {
      throw IllegalStateException('No element');
    }
    E? lastElement;
    for (final element in this) {
      lastElement = element;
    }
    return lastElement as E;
  }

  @override
  E lastWhere(bool Function(E element) test, {E Function()? orElse}) {
    E? result;
    bool found = false;
    for (final element in this) {
      if (test(element)) {
        result = element;
        found = true;
      }
    }
    if (found) {
      return result as E;
    }
    if (orElse != null) {
      return orElse();
    }
    throw IllegalStateException('No element satisfies the predicate.');
  }

  @override
  Iterable<T> map<T>(T Function(E e) toElement) sync* {
    for (final element in this) {
      yield toElement(element);
    }
  }

  @override
  E reduce(E Function(E value, E element) combine) {
    if (isEmpty) {
      throw IllegalStateException('No element');
    }
    Iterator<E> iterator = this.iterator;
    iterator.moveNext();
    E value = iterator.current;
    while (iterator.moveNext()) {
      value = combine(value, iterator.current);
    }
    return value;
  }

  @override
  void removeAll(Iterable<Object?> elements) {
    for (final element in elements) {
      remove(element);
    }
  }

  @override
  void removeWhere(bool Function(E element) test) {
    // Create a temporary list of elements to remove to avoid concurrent modification
    final elementsToRemove = <E>[];
    for (final element in this) {
      if (test(element)) {
        elementsToRemove.add(element);
      }
    }
    for (final element in elementsToRemove) {
      remove(element);
    }
  }

  @override
  void retainAll(Iterable<Object?> elements) {
    final elementsToRetain = HashSet<Object?>();
    elementsToRetain.addAll(elements);

    final elementsToRemove = <E>[];
    for (final element in this) {
      if (!elementsToRetain.contains(element)) {
        elementsToRemove.add(element);
      }
    }
    for (final element in elementsToRemove) {
      remove(element);
    }
  }

  @override
  void retainWhere(bool Function(E element) test) {
    final elementsToRemove = <E>[];
    for (final element in this) {
      if (!test(element)) {
        elementsToRemove.add(element);
      }
    }
    for (final element in elementsToRemove) {
      remove(element);
    }
  }

  @override
  E get single {
    if (_size != 1) {
      throw IllegalStateException('Expected single element, but got $_size');
    }
    return first;
  }

  @override
  E singleWhere(bool Function(E element) test, {E Function()? orElse}) {
    E? result;
    bool found = false;
    for (final element in this) {
      if (test(element)) {
        if (found) {
          throw IllegalStateException('More than one element satisfies the predicate.');
        }
        result = element;
        found = true;
      }
    }
    if (found) {
      return result as E;
    }
    if (orElse != null) {
      return orElse();
    }
    throw IllegalStateException('No element satisfies the predicate.');
  }

  @override
  Iterable<E> skip(int count) sync* {
    if (count < 0) throw InvalidArgumentException('$count cannot be negative');
    int skipped = 0;
    for (final element in this) {
      if (skipped >= count) {
        yield element;
      }
      skipped++;
    }
  }

  @override
  Iterable<E> skipWhile(bool Function(E value) test) sync* {
    bool skipping = true;
    for (final element in this) {
      if (skipping && test(element)) {
        // Still skipping
      } else {
        skipping = false;
        yield element;
      }
    }
  }

  @override
  Iterable<E> take(int count) sync* {
    if (count < 0) throw InvalidArgumentException('$count cannot be negative');
    int taken = 0;
    for (final element in this) {
      if (taken < count) {
        yield element;
        taken++;
      } else {
        break;
      }
    }
  }

  @override
  Iterable<E> takeWhile(bool Function(E value) test) sync* {
    for (final element in this) {
      if (test(element)) {
        yield element;
      } else {
        break;
      }
    }
  }

  @override
  List<E> toList({bool growable = true}) {
    final List<E> list = [];
    for (final element in this) {
      list.add(element);
    }
    return list;
  }

  @override
  Iterable<E> where(bool Function(E element) test) sync* {
    for (final element in this) {
      if (test(element)) {
        yield element;
      }
    }
  }

  @override
  Iterable<T> whereType<T>() sync* {
    for (final element in this) {
      if (element is T) {
        yield element;
      }
    }
  }
}

/// Custom iterator for HashSet.
@Generic(_HashSetIterator)
class _HashSetIterator<E> implements Iterator<E> {
  final HashSet<E> _hashSet;
  int _bucketIndex = 0;
  int _elementIndexInBucket = 0;
  E? _currentElement;

  // Constructor should NOT call moveNext()
  _HashSetIterator(this._hashSet);

  @override
  E get current => _currentElement as E;

  @override
  bool moveNext() {
    _currentElement = null; // Reset current element before finding the next one

    while (_bucketIndex < _hashSet._capacity) {
      final bucket = _hashSet._buckets[_bucketIndex];
      if (bucket != null) {
        if (_elementIndexInBucket < bucket.length) {
          _currentElement = bucket[_elementIndexInBucket];
          _elementIndexInBucket++;
          return true; // Found next element
        } else {
          // No more elements in this bucket, move to the next bucket
          _bucketIndex++;
          _elementIndexInBucket = 0; // Reset element index for the new bucket
        }
      } else {
        // Current bucket is null, move to the next bucket
        _bucketIndex++;
        _elementIndexInBucket = 0; // Reset element index for the new bucket
      }
    }
    // No more elements in any bucket
    return false;
  }
}