import 'package:test/test.dart';
import 'package:jetleaf_resource/cache.dart';

void main() {
  group('CacheHitEvent', () {
    test('should create with source, cacheName, and value', () {
      final event = CacheHitEvent('user:42', 'users', 'Alice');
      expect(event.getSource(), equals('user:42'));
      expect(event.cacheName, equals('users'));
      expect(event.value, equals('Alice'));
    });

    test('should create with null value', () {
      final event = CacheHitEvent('key1', 'cache1', null);
      expect(event.value, isNull);
    });

    test('should create with timestamp', () {
      final timestamp = DateTime(2025, 1, 1);
      final event = CacheHitEvent('key', 'cache', 'value', timestamp);
      expect(event.getTimestamp(), equals(timestamp));
    });

    test('should have correct toString', () {
      final event = CacheHitEvent('user:42', 'users', 'Alice');
      expect(event.toString(), contains('CacheHitEvent'));
      expect(event.toString(), contains('users'));
    });
  });

  group('CacheMissEvent', () {
    test('should create with source and cacheName', () {
      final event = CacheMissEvent('user:42', 'users');
      expect(event.getSource(), equals('user:42'));
      expect(event.cacheName, equals('users'));
    });

    test('should create with timestamp', () {
      final timestamp = DateTime(2025, 1, 1);
      final event = CacheMissEvent('key', 'cache', timestamp);
      expect(event.getTimestamp(), equals(timestamp));
    });

    test('should have correct toString', () {
      final event = CacheMissEvent('key1', 'cache1');
      expect(event.toString(), contains('CacheMissEvent'));
    });
  });

  group('CachePutEvent', () {
    test('should create with source, cacheName, and value', () {
      final event = CachePutEvent('user:42', 'users', 'Alice');
      expect(event.getSource(), equals('user:42'));
      expect(event.cacheName, equals('users'));
      expect(event.value, equals('Alice'));
    });

    test('should create with ttl', () {
      final event = CachePutEvent('key', 'cache', 'value', Duration(minutes: 10));
      expect(event.ttl, equals(Duration(minutes: 10)));
    });

    test('should create with null ttl', () {
      final event = CachePutEvent('key', 'cache', 'value', null);
      expect(event.ttl, isNull);
    });

    test('should create with timestamp', () {
      final timestamp = DateTime(2025, 1, 1);
      final event = CachePutEvent('key', 'cache', 'value', null, timestamp);
      expect(event.getTimestamp(), equals(timestamp));
    });

    test('should have correct toString', () {
      final event = CachePutEvent('key', 'cache', 'value', Duration(seconds: 30));
      expect(event.toString(), contains('CachePutEvent'));
    });
  });

  group('CacheEvictEvent', () {
    test('should create with source, cacheName, and reason', () {
      final event = CacheEvictEvent('user:42', 'users', 'manual');
      expect(event.getSource(), equals('user:42'));
      expect(event.cacheName, equals('users'));
      expect(event.reason, equals('manual'));
    });

    test('should create with timestamp', () {
      final timestamp = DateTime(2025, 1, 1);
      final event = CacheEvictEvent('key', 'cache', 'policy', timestamp);
      expect(event.getTimestamp(), equals(timestamp));
    });

    test('should have correct toString', () {
      final event = CacheEvictEvent('key', 'cache', 'ttl_expired');
      expect(event.toString(), contains('CacheEvictEvent'));
      expect(event.toString(), contains('ttl_expired'));
    });
  });

  group('CacheExpireEvent', () {
    test('should create with source, cacheName, and ttl', () {
      final event = CacheExpireEvent('user:42', 'users', Duration(minutes: 5));
      expect(event.getSource(), equals('user:42'));
      expect(event.cacheName, equals('users'));
      expect(event.ttl, equals(Duration(minutes: 5)));
    });

    test('should create with value', () {
      final event = CacheExpireEvent('key', 'cache', Duration(seconds: 10), 'value');
      expect(event.value, equals('value'));
    });

    test('should create with null value', () {
      final event = CacheExpireEvent('key', 'cache', Duration(seconds: 10), null);
      expect(event.value, isNull);
    });

    test('should create with timestamp', () {
      final timestamp = DateTime(2025, 1, 1);
      final event = CacheExpireEvent('key', 'cache', Duration(seconds: 10), null, timestamp);
      expect(event.getTimestamp(), equals(timestamp));
    });

    test('should have correct toString', () {
      final event = CacheExpireEvent('key', 'cache', Duration(seconds: 30));
      expect(event.toString(), contains('CacheExpireEvent'));
    });
  });

  group('CacheClearEvent', () {
    test('should create with source, cacheName, and entriesCleared', () {
      final event = CacheClearEvent('trigger_key', 'users', 42);
      expect(event.getSource(), equals('trigger_key'));
      expect(event.cacheName, equals('users'));
      expect(event.entriesCleared, equals(42));
    });

    test('should create with timestamp', () {
      final timestamp = DateTime(2025, 1, 1);
      final event = CacheClearEvent('key', 'cache', 10, timestamp);
      expect(event.getTimestamp(), equals(timestamp));
    });

    test('should have correct toString', () {
      final event = CacheClearEvent('key', 'cache', 25);
      expect(event.toString(), contains('CacheClearEvent'));
      expect(event.toString(), contains('25'));
    });

    test('should handle zero entries cleared', () {
      final event = CacheClearEvent('key', 'cache', 0);
      expect(event.entriesCleared, equals(0));
    });
  });
}
