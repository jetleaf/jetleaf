part of 'obs.dart';

/// Single class to observe any value, lists or maps.
/// For collection mutation events, use the helper methods below or `mutate`.
@Generic(_Obs)
class _Obs<T> implements Obs<T> {
  T? _value;
  final _controller = StreamController<ObsEvent>.broadcast(sync: false);
  bool _disposed = false;

  // batching
  int _batchLevel = 0;
  final List<ObsEvent> _batchBuffer = [];

  _Obs([T? initial]) : _value = initial;

  /// Current snapshot of the observed value.
  ///
  /// This may be `null`.  
  /// If `T` is a collection (`List` or `Map`), prefer using
  /// the mutation helpers (`add`, `put`, etc.) or [`mutate`]
  /// to ensure proper events are emitted.
  T? get value => _value;

  @override
  void set(T? newValue, {bool force = false}) {
    if (_disposed) return;
    final old = _value;
    if (!force && identical(old, newValue)) return;
    _value = newValue;
    _emit(ValueChanged<T>(old, newValue));
  }

  @override
  StreamSubscription<ObsEvent> listen(void Function(ObsEvent) onData) =>
      _controller.stream.listen(onData);

  @override
  R transaction<R>(R Function() fn) {
    if (_disposed) return fn();
    _batchLevel++;
    try {
      return fn();
    } finally {
      _batchLevel--;
      if (_batchLevel == 0 && _batchBuffer.isNotEmpty) {
        final batched = List<ObsEvent>.from(_batchBuffer);
        _batchBuffer.clear();
        _controller.add(BulkChange(batched));
      }
    }
  }

  @override
  void add<E>(E element) {
    final list = _ensureList<E>();
    final idx = list.length;
    list.add(element);
    _emit(ListChange<E>.add(idx, element));
  }

  @override
  void addAll<E>(Iterable<E> iterable) {
    final list = _ensureList<E>();
    if (iterable.isEmpty) return;
    final changes = <ListChange<E>>[];
    var i = list.length;
    for (final e in iterable) {
      list.add(e);
      changes.add(ListChange<E>.add(i, e));
      i++;
    }
    _emit(BulkChange(changes));
  }

  @override
  bool removeFromList<E>(E element) {
    final list = _ensureList<E>();
    final idx = list.indexOf(element); // now parameter type matches E
    if (idx < 0) return false;
    final old = list.removeAt(idx);
    _emit(ListChange<E>.remove(idx, old));
    return true;
  }

  @override
  bool removeFromListAny<E>(Object? element) {
    final list = _ensureList<E>();
    // find index by equality test (safe without casting)
    final idx = list.indexWhere((e) => e == element);
    if (idx < 0) return false;
    final old = list.removeAt(idx);
    _emit(ListChange<E>.remove(idx, old));
    return true;
  }

  @override
  E removeAt<E>(int index) {
    final list = _ensureList<E>();
    final old = list.removeAt(index);
    _emit(ListChange<E>.remove(index, old));
    return old;
  }

  @override
  void clearList<E>() {
    final list = _ensureList<E>();
    if (list.isEmpty) return;
    final snapshot = List<E>.from(list);
    list.clear();
    final changes = <ListChange<E>>[];
    for (var i = 0; i < snapshot.length; i++) {
      changes.add(ListChange<E>.remove(i, snapshot[i]));
    }
    _emit(BulkChange(changes));
  }

  @override
  void replaceAllInList<E>(Iterable<E> items) {
    final list = _ensureList<E>();
    final before = List<E>.from(list);
    list
      ..clear()
      ..addAll(items);
    final changes = <ListChange<E>>[];
    for (var i = 0; i < before.length; i++) {
      changes.add(ListChange<E>.remove(i, before[i]));
    }
    for (var i = 0; i < list.length; i++) {
      changes.add(ListChange<E>.add(i, list[i]));
    }
    _emit(BulkChange(changes));
  }

  @override
  V? put<K, V>(K key, V value) {
    final map = _ensureMap<K, V>();
    final old = map.containsKey(key) ? map[key] : null;
    map[key] = value;
    _emit(MapChange<K, V>.put(key, old, value));
    return old;
  }

  @override
  void putAll<K, V>(Map<K, V> entries) {
    final map = _ensureMap<K, V>();
    if (entries.isEmpty) return;
    final changes = <MapChange<K, V>>[];
    entries.forEach((k, v) {
      final old = map.containsKey(k) ? map[k] : null;
      map[k] = v;
      changes.add(MapChange<K, V>.put(k, old, v));
    });
    _emit(BulkChange(changes));
  }

  @override
  V? removeKey<K, V>(K key) {
    final map = _ensureMap<K, V>();
    if (!map.containsKey(key)) return null;
    final old = map.remove(key);
    _emit(MapChange<K, V>.remove(key, old));
    return old;
  }

  @override
  void clearMap<K, V>() {
    final map = _ensureMap<K, V>();
    if (map.isEmpty) return;
    final snapshot = Map<K, V>.from(map);
    map.clear();
    final changes = <MapChange<K, V>>[];
    snapshot.forEach((k, v) => changes.add(MapChange<K, V>.put(k, v, null)));
    _emit(BulkChange(changes));
  }

  void _emit(ObsEvent e) {
    if (_disposed) return;
    if (_batchLevel > 0) {
      _batchBuffer.add(e);
      return;
    }
    try {
      _controller.add(e);
    } catch (_) {}
  }

  // runtime checks + casts with helpful error messages
  List<E> _ensureList<E>() {
    if (_value == null) {
      return <E>[];
    }
    if (_value is List<E>) return _value as List<E>;
    if (_value is List) return (_value as List).cast<E>();
    throw IllegalStateException('_Obs value is not a List<$E>. Actual: ${_value.runtimeType}');
  }

  Map<K, V> _ensureMap<K, V>() {
    if (_value == null) {
      return <K, V>{};
    }
    if (_value is Map<K, V>) return _value as Map<K, V>;
    if (_value is Map) return (_value as Map).cast<K, V>();
    throw IllegalStateException('_Obs value is not a Map<$K, $V>. Actual: ${_value.runtimeType}');
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _controller.close();
  }
}