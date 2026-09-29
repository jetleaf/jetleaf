import 'package:jetleaf_build/jetleaf_build.dart';

import '../exceptions.dart';

/// {@template hash_map}
/// A custom implementation of a hash map that implements the `Map<K, V>` interface.
///
/// This map uses **open addressing with chaining** to resolve hash collisions.
/// Each bucket holds a list of `_HashMapEntry<K, V>` objects, allowing multiple entries
/// to exist in the same bucket if they hash to the same index.
///
/// It supports automatic resizing when the load factor exceeds `0.75`, ensuring
/// performance remains optimal as the number of entries grows.
///
/// This is useful for educational purposes or when custom behavior is required
/// beyond what `dart:collection` offers.
///
/// ---
///
/// ### ⚙️ Internal Design:
/// - Backed by an array of lists: `List<List<_HashMapEntry<K, V>>?> _buckets`
/// - On collision: new entries are appended to the appropriate list
/// - Resize logic doubles capacity when load factor exceeds the threshold
///
/// ---
///
/// ### 📦 Example Usage:
/// ```dart
/// final map = HashMap<String, int>();
/// map['apple'] = 3;
/// map['banana'] = 5;
/// print(map['apple']); // 3
/// print(map.containsKey('banana')); // true
/// print(map.length); // 2
/// ```
///
/// {@endtemplate}
@Generic(HashMap)
class HashMap<K, V> implements Map<K, V> {
  static const int _initialCapacity = 16;
  static const double _loadFactorThreshold = 0.75;

  List<List<_HashMapEntry<K, V>>?> _buckets;
  int _size = 0;
  int _capacity;

  /// {@macro hash_map}
  ///
  /// Creates an empty hash map with an initial capacity of 16.
  HashMap() : _capacity = _initialCapacity, _buckets = List.filled(_initialCapacity, null);

  /// Creates a hash map from an existing map.
  /// 
  /// This is a factory constructor that creates a new hash map from an existing map.
  /// {@macro hash_map}
  factory HashMap.from(Map<K, V> map) {
    final result = HashMap<K, V>();
    map.forEach((key, value) {
      result[key] = value;
    });
    return result;
  }

  /// Calculates the bucket index for a key.
  int _getBucketIndex(Object? key) {
    // Handle null hashCode for null keys
    final hashCode = key.hashCode;
    return (hashCode.abs() % _capacity);
  }

  /// Resizes the hash map when the load factor is exceeded.
  void _resize() {
    final oldBuckets = _buckets;
    _capacity *= 2;
    _buckets = List.filled(_capacity, null);
    _size = 0; // Reset size, as entries will be re-added

    for (final bucket in oldBuckets) {
      if (bucket != null) {
        for (final entry in bucket) {
          this[entry.key] = entry.value; // Re-add entries to new buckets
        }
      }
    }
  }

  @override
  V? operator [](Object? key) {
    if (isEmpty) return null;

    final index = _getBucketIndex(key);
    final bucket = _buckets[index];

    if (bucket != null) {
      for (final entry in bucket) {
        if (entry.key == key) {
          return entry.value;
        }
      }
    }
    return null;
  }

  @override
  void operator []=(K key, V value) {
    if (_size / _capacity > _loadFactorThreshold) {
      _resize();
    }

    final index = _getBucketIndex(key);
    _buckets[index] ??= []; // Initialize bucket if null

    final bucket = _buckets[index]!;
    for (final entry in bucket) {
      if (entry.key == key) {
        entry.value = value; // Update existing value
        return;
      }
    }

    // Key not found, add new entry
    bucket.add(_HashMapEntry(key, value));
    _size++;
  }

  @override
  V? remove(Object? key) {
    if (isEmpty) return null;

    final index = _getBucketIndex(key);
    final bucket = _buckets[index];

    if (bucket != null) {
      for (int i = 0; i < bucket.length; i++) {
        if (bucket[i].key == key) {
          final removedValue = bucket[i].value;
          bucket.removeAt(i);
          _size--;
          // If bucket becomes empty, set to null to save memory (optional)
          if (bucket.isEmpty) {
            _buckets[index] = null;
          }
          return removedValue;
        }
      }
    }
    return null;
  }

  @override
  void clear() {
    _buckets = List.filled(_initialCapacity, null);
    _capacity = _initialCapacity;
    _size = 0;
  }

  @override
  bool containsKey(Object? key) {
    if (isEmpty) return false;

    final index = _getBucketIndex(key);
    final bucket = _buckets[index];

    if (bucket != null) {
      for (final entry in bucket) {
        if (entry.key == key) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  bool containsValue(Object? value) {
    for (final bucket in _buckets) {
      if (bucket != null) {
        for (final entry in bucket) {
          if (entry.value == value) {
            return true;
          }
        }
      }
    }
    return false;
  }

  @override
  void forEach(void Function(K key, V value) action) {
    for (final bucket in _buckets) {
      if (bucket != null) {
        for (final entry in bucket) {
          action(entry.key, entry.value);
        }
      }
    }
  }

  @override
  Iterable<K> get keys => _HashMapKeys(this);

  @override
  Iterable<V> get values => _HashMapValues(this);

  @override
  int get length => _size;

  @override
  bool get isEmpty => _size == 0;

  @override
  bool get isNotEmpty => _size > 0;

  @override
  void addAll(Map<K, V> other) {
    other.forEach((key, value) {
      this[key] = value;
    });
  }

  @override
  Map<RK, RV> cast<RK, RV>() => Map.castFrom<K, V, RK, RV>(this);

  @override
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> Function(K key, V value) convert) {
    final newMap = HashMap<K2, V2>();
    forEach((key, value) {
      final entry = convert(key, value);
      newMap[entry.key] = entry.value;
    });
    return newMap;
  }

  @override
  String toString() {
    if (isEmpty) return '{}';
    final buffer = StringBuffer('{');
    bool first = true;
    forEach((key, value) {
      if (!first) {
        buffer.write(', ');
      }
      buffer.write('$key: $value');
      first = false;
    });
    buffer.write('}');
    return buffer.toString();
  }

  @override
  void addEntries(Iterable<MapEntry<K, V>> newEntries) {
    for (final entry in newEntries) {
      this[entry.key] = entry.value;
    }
  }

  @override
  Iterable<MapEntry<K, V>> get entries => _HashMapEntries(this);

  @override
  V putIfAbsent(K key, V Function() ifAbsent) {
    if (containsKey(key)) {
      return this[key] as V;
    } else {
      final value = ifAbsent();
      this[key] = value;
      return value;
    }
  }

  @override
  void removeWhere(bool Function(K key, V value) test) {
    final keysToRemove = <K>[];
    forEach((key, value) {
      if (test(key, value)) {
        keysToRemove.add(key);
      }
    });
    for (final key in keysToRemove) {
      remove(key);
    }
  }

  @override
  V update(K key, V Function(V value) update, {V Function()? ifAbsent}) {
    if (containsKey(key)) {
      final oldValue = this[key] as V;
      final newValue = update(oldValue);
      this[key] = newValue;
      return newValue;
    } else {
      if (ifAbsent != null) {
        final newValue = ifAbsent();
        this[key] = newValue;
        return newValue;
      }
      throw InvalidArgumentException('$key not found and no ifAbsent function provided.');
    }
  }

  @override
  void updateAll(V Function(K key, V value) update) {
    final updatedEntries = <K, V>{};
    forEach((key, value) {
      updatedEntries[key] = update(key, value);
    });
    updatedEntries.forEach((key, value) {
      this[key] = value; // Update in place
    });
  }
}

/// Iterable for HashMap keys.
@Generic(_HashMapKeys)
class _HashMapKeys<K, V> extends Iterable<K> {
  final HashMap<K, V> _map;
  _HashMapKeys(this._map);

  @override
  Iterator<K> get iterator => _HashMapKeyIterator(_map);
}

/// Iterator for HashMap keys.
@Generic(_HashMapKeyIterator)
class _HashMapKeyIterator<K, V> implements Iterator<K> {
  final HashMap<K, V> _map;
  int _bucketIndex = 0;
  int _elementIndexInBucket = 0;
  K? _currentKey;

  // Constructor should NOT call moveNext()
  _HashMapKeyIterator(this._map);

  @override
  K get current => _currentKey as K;

  @override
  bool moveNext() {
    _currentKey = null; // Reset current element before finding the next one

    while (_bucketIndex < _map._capacity) {
      final bucket = _map._buckets[_bucketIndex];
      if (bucket != null) {
        if (_elementIndexInBucket < bucket.length) {
          _currentKey = bucket[_elementIndexInBucket].key;
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
    _currentKey = null;
    return false;
  }
}

/// Iterable for HashMap values.
@Generic(_HashMapValues)
class _HashMapValues<K, V> extends Iterable<V> {
  final HashMap<K, V> _map;
  _HashMapValues(this._map);

  @override
  Iterator<V> get iterator => _HashMapValueIterator(_map);
}

/// Iterator for HashMap values.
@Generic(_HashMapValueIterator)
class _HashMapValueIterator<K, V> implements Iterator<V> {
  final HashMap<K, V> _map;
  int _bucketIndex = 0;
  int _elementIndexInBucket = 0;
  V? _currentValue;

  // Constructor should NOT call moveNext()
  _HashMapValueIterator(this._map);

  @override
  V get current => _currentValue as V;

  @override
  bool moveNext() {
    _currentValue = null; // Reset current element before finding the next one

    while (_bucketIndex < _map._capacity) {
      final bucket = _map._buckets[_bucketIndex];
      if (bucket != null) {
        if (_elementIndexInBucket < bucket.length) {
          _currentValue = bucket[_elementIndexInBucket].value;
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
    _currentValue = null;
    return false;
  }
}

/// Iterable for HashMap entries.
@Generic(_HashMapEntries)
class _HashMapEntries<K, V> extends Iterable<MapEntry<K, V>> {
  final HashMap<K, V> _map;
  _HashMapEntries(this._map);

  @override
  Iterator<MapEntry<K, V>> get iterator => _HashMapEntryIterator(_map);
}

/// Iterator for HashMap entries.
@Generic(_HashMapEntryIterator)
class _HashMapEntryIterator<K, V> implements Iterator<MapEntry<K, V>> {
  final HashMap<K, V> _map;
  int _bucketIndex = 0;
  int _elementIndexInBucket = 0;
  MapEntry<K, V>? _currentEntry;

  // Constructor should NOT call moveNext()
  _HashMapEntryIterator(this._map);

  @override
  MapEntry<K, V> get current => _currentEntry as MapEntry<K, V>;

  @override
  bool moveNext() {
    _currentEntry = null; // Reset current element before finding the next one

    while (_bucketIndex < _map._capacity) {
      final bucket = _map._buckets[_bucketIndex];
      if (bucket != null) {
        if (_elementIndexInBucket < bucket.length) {
          final entry = bucket[_elementIndexInBucket];
          _currentEntry = MapEntry(entry.key, entry.value);
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
    _currentEntry = null;
    return false;
  }
}

/// Represents a key-value entry in the HashMap.
@Generic(_HashMapEntry)
class _HashMapEntry<K, V> {
  K key;
  V value;

  _HashMapEntry(this.key, this.value);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _HashMapEntry && key == other.key;
  }

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => '{$key: $value}';
}