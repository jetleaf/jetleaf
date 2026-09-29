import 'dart:async';

import 'package:test/test.dart';
import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_resource/cache.dart';

class _MockCacheStorage implements CacheStorage, EqualsAndHashCode {
  final String _name;

  _MockCacheStorage(this._name);

  @override
  String getName() => _name;

  @override
  FutureOr<Cache?> get(Object key) async => null;

  @override
  FutureOr<T?> getAs<T>(Object key, [Class<T>? type]) async => null;

  @override
  FutureOr<void> put(Object key, [Object? value, Duration? ttl]) async {}

  @override
  FutureOr<Cache?> putIfAbsent(Object key, [Object? value, Duration? ttl]) async => null;

  @override
  FutureOr<void> evict(Object key) async {}

  @override
  FutureOr<bool> evictIfPresent(Object key) async => false;

  @override
  FutureOr<void> clear() async {}

  @override
  FutureOr<void> invalidate() async {}

  @override
  Resource<Object, Cache> getResource() => throw UnimplementedError();

  @override
  List<Object?> equalizedProperties() => [runtimeType, _name];
}

void main() {
  group('ThrowableCacheErrorHandler', () {
    late ThrowableCacheErrorHandler handler;
    late _MockCacheStorage cache;

    setUp(() {
      handler = const ThrowableCacheErrorHandler();
      cache = _MockCacheStorage('testCache');
    });

    test('should rethrow on onGet', () async {
      final exception = Exception('get error');
      final stackTrace = StackTrace.current;
      expect(
        () => handler.onGet(exception, stackTrace, cache, 'key'),
        throwsA(equals(exception)),
      );
    });

    test('should rethrow on onPut', () async {
      final exception = Exception('put error');
      final stackTrace = StackTrace.current;
      expect(
        () => handler.onPut(exception, stackTrace, cache, 'key', 'value'),
        throwsA(equals(exception)),
      );
    });

    test('should rethrow on onEvict', () async {
      final exception = Exception('evict error');
      final stackTrace = StackTrace.current;
      expect(
        () => handler.onEvict(exception, stackTrace, cache, 'key'),
        throwsA(equals(exception)),
      );
    });

    test('should rethrow on onClear', () async {
      final exception = Exception('clear error');
      final stackTrace = StackTrace.current;
      expect(
        () => handler.onClear(exception, stackTrace, cache),
        throwsA(equals(exception)),
      );
    });
  });

  group('LoggableCacheErrorHandler', () {
    late LoggableCacheErrorHandler handler;
    late _MockCacheStorage cache;

    setUp(() {
      handler = LoggableCacheErrorHandler();
      cache = _MockCacheStorage('testCache');
    });

    test('should not throw on onGet', () async {
      final exception = Exception('get error');
      final stackTrace = StackTrace.current;
      await handler.onGet(exception, stackTrace, cache, 'key');
    });

    test('should not throw on onPut', () async {
      final exception = Exception('put error');
      final stackTrace = StackTrace.current;
      await handler.onPut(exception, stackTrace, cache, 'key', 'value');
    });

    test('should not throw on onEvict', () async {
      final exception = Exception('evict error');
      final stackTrace = StackTrace.current;
      await handler.onEvict(exception, stackTrace, cache, 'key');
    });

    test('should not throw on onClear', () async {
      final exception = Exception('clear error');
      final stackTrace = StackTrace.current;
      await handler.onClear(exception, stackTrace, cache);
    });
  });
}
