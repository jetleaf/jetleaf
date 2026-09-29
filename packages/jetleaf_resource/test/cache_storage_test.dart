import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_resource/jetleaf_resource.dart';

void main() {
  group('DefaultCache', () {
    test('should store and retrieve value', () {
      final now = ZonedDateTime.now(ZoneId.UTC);
      final cache = DefaultCache('hello', null, now, ZoneId.UTC);
      expect(cache.get(), equals('hello'));
    });

    test('should store null value', () {
      final now = ZonedDateTime.now(ZoneId.UTC);
      final cache = DefaultCache(null, null, now, ZoneId.UTC);
      expect(cache.get(), isNull);
    });

    test('should return null TTL when not set', () {
      final now = ZonedDateTime.now(ZoneId.UTC);
      final cache = DefaultCache('value', null, now, ZoneId.UTC);
      expect(cache.getTtl(), isNull);
    });

    test('should return TTL when set', () {
      final now = ZonedDateTime.now(ZoneId.UTC);
      final cache = DefaultCache('value', Duration(minutes: 5), now, ZoneId.UTC);
      expect(cache.getTtl(), equals(Duration(minutes: 5)));
    });

    test('should not expire when TTL is null', () {
      final now = ZonedDateTime.now(ZoneId.UTC);
      final cache = DefaultCache('value', null, now, ZoneId.UTC);
      expect(cache.isExpired(), isFalse);
    });

    test('should not expire when within TTL', () {
      final now = ZonedDateTime.now(ZoneId.UTC);
      final cache = DefaultCache('value', Duration(minutes: 5), now, ZoneId.UTC);
      expect(cache.isExpired(), isFalse);
    });

    test('should expire when past TTL', () {
      final past = ZonedDateTime.now(ZoneId.UTC).minus(Duration(minutes: 10));
      final cache = DefaultCache('value', Duration(minutes: 5), past, ZoneId.UTC);
      expect(cache.isExpired(), isTrue);
    });

    test('should track access count', () {
      final now = ZonedDateTime.now(ZoneId.UTC);
      final cache = DefaultCache('value', null, now, ZoneId.UTC);
      expect(cache.getAccessCount(), equals(0));
      cache.recordAccess();
      expect(cache.getAccessCount(), equals(1));
      cache.recordAccess();
      expect(cache.getAccessCount(), equals(2));
    });

    test('should update last accessed time on recordAccess', () {
      final now = ZonedDateTime.now(ZoneId.UTC);
      final cache = DefaultCache('value', null, now, ZoneId.UTC);
      final initialAccess = cache.getLastAccessedAt();
      cache.recordAccess();
      final afterAccess = cache.getLastAccessedAt();
      expect(afterAccess.compareTo(initialAccess) >= 0, isTrue);
    });

    test('should return creation time', () {
      final now = ZonedDateTime.now(ZoneId.UTC);
      final cache = DefaultCache('value', null, now, ZoneId.UTC);
      expect(cache.getCreatedAt(), equals(now));
    });

    test('should calculate age in milliseconds', () {
      final now = ZonedDateTime.now(ZoneId.UTC);
      final cache = DefaultCache('value', null, now, ZoneId.UTC);
      final age = cache.getAgeInMilliseconds();
      expect(age, greaterThanOrEqualTo(0));
      expect(age, lessThan(1000));
    });

    test('should return remaining TTL as null when no TTL', () {
      final now = ZonedDateTime.now(ZoneId.UTC);
      final cache = DefaultCache('value', null, now, ZoneId.UTC);
      expect(cache.getRemainingTtl(), isNull);
    });

    test('should return remaining TTL when TTL is set', () {
      final now = ZonedDateTime.now(ZoneId.UTC);
      final cache = DefaultCache('value', Duration(minutes: 5), now, ZoneId.UTC);
      final remaining = cache.getRemainingTtl();
      expect(remaining, isNotNull);
      expect(remaining!.inSeconds, greaterThanOrEqualTo(290));
      expect(remaining.inSeconds, lessThanOrEqualTo(300));
    });
  });

  group('DefaultCacheStorage', () {
    test('should create with default name', () {
      final storage = DefaultCacheStorage();
      expect(storage.getName(), equals('default'));
    });

    test('should create with custom name', () {
      final storage = DefaultCacheStorage.named('myCache');
      expect(storage.getName(), equals('myCache'));
    });

    test('should have default null TTL', () {
      final storage = DefaultCacheStorage.named('test');
      expect(storage.getDefaultTtl(), isNull);
    });

    test('should have default null max entries', () {
      final storage = DefaultCacheStorage.named('test');
      expect(storage.getMaxEntries(), isNull);
    });

    test('should have default null eviction policy', () {
      final storage = DefaultCacheStorage.named('test');
      expect(storage.getEvictionPolicy(), isNull);
    });

    test('should set default TTL', () {
      final storage = DefaultCacheStorage.named('test');
      storage.setDefaultTtl(Duration(minutes: 10));
      expect(storage.getDefaultTtl(), equals(Duration(minutes: 10)));
    });

    test('should set max entries', () {
      final storage = DefaultCacheStorage.named('test');
      storage.setMaxEntries(100);
      expect(storage.getMaxEntries(), equals(100));
    });

    test('should set eviction policy', () {
      final storage = DefaultCacheStorage.named('test');
      storage.setEvictionPolicy(LruEvictionPolicy());
      expect(storage.getEvictionPolicy(), isA<LruEvictionPolicy>());
    });

    test('should set zone id', () {
      final storage = DefaultCacheStorage.named('test');
      storage.setZoneId('America/New_York');
      expect(storage.getZoneId()?.id, equals('America/New_York'));
    });

    test('should have default metrics', () {
      final storage = DefaultCacheStorage.named('test');
      final metrics = storage.getMetrics();
      expect(metrics, isA<SimpleCacheMetrics>());
    });

    test('should return resource', () {
      final storage = DefaultCacheStorage.named('test');
      final resource = storage.getResource();
      expect(resource, isNotNull);
    });
  });
}
