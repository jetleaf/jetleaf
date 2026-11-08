part of 'garbage_collector.dart';

@Generic(_Garbage)
final class _Garbage<T> implements Garbage<T> {
  final T _source;
  final String _key;
  final DateTime _createdAt;

  _Garbage(this._key, this._source) : _createdAt = DateTime.now();

  @override
  List<Object?> equalizedProperties() => [_key, _source is EqualsAndHashCode ? _source : _Garbage];

  @override
  String getKey() => _key;

  @override
  T getSource() => _source;

  @override
  String toString() => "Garbage[key=$_key, type=${_source.runtimeType}, createdAt=$_createdAt]";
}

final class _GarbageCollector extends GarbageCollector {
  int _maxSize = 100;
  Timer? _periodicCleanupTimer;

  _GarbageCollector._();
  
  @override
  Garbage<T> addGarbage<T>(String key, T source) {
    final garbage = _Garbage<T>(key, source);
    this[key] = garbage;
    _trimWhenNeeded();

    return garbage;
  }

  @override
  Garbage findOrAdd(String key, Object source) {
    if (findGarbage(key) case final garbage?) {
      return garbage;
    }

    return addGarbage(key, source);
  }

  @override
  Garbage<T> getOrCreate<T>(String key, T source) {
    if (getGarbage<T>(key) case final garbage?) {
      return garbage;
    }

    return addGarbage<T>(key, source);
  }
  
  @override
  void cleanup() {
    for (final item in entries) {
      remove(item.key);
    }
  }

  @override
  bool exists(String key) => findGarbage(key) != null;
  
  @override
  void enablePeriodicCleanup([Duration duration = const Duration(minutes: 5)]) {
    _periodicCleanupTimer?.cancel();
    _periodicCleanupTimer = Timer.periodic(duration, (_) => _trimWhenNeeded());
  }

  void _trimWhenNeeded() {
    if (length <= _maxSize) return;

    final excess = length - _maxSize;
    final keysToRemove = keys.take(excess).toList();

    for (final key in keysToRemove) {
      remove(key);
    }
  }
  
  @override
  List<Object?> equalizedProperties() => [_GarbageCollector, GarbageCollector];
  
  @override
  Garbage<T>? getGarbage<T>(String key) {
    if (this[key] case Garbage<T> value?) {
      return value;
    }

    return null;
  }

  @override
  Garbage? findGarbage(String key) => this[key];
  
  @override
  void setMaxItemSize(int maxSize) {
    _maxSize = maxSize;
    _trimWhenNeeded();
  }
  
  @override
  void delete(String key) => remove(key);
  
  @override
  void performCleanupWhenNecessary() => _trimWhenNeeded();

  @override
  String toString() {
    return "This garbage collector currently manages $length "
          "entr${length == 1 ? 'y' : 'ies'} "
          "(max=$_maxSize).";
  }
}