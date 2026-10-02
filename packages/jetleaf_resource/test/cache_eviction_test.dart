import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_resource/cache.dart';

void main() {
  group('FifoEvictionPolicy', () {
    late FifoEvictionPolicy policy;

    setUp(() {
      policy = FifoEvictionPolicy();
    });

    test('should return FIFO as name', () {
      expect(policy.getName(), equals('FIFO'));
    });

    test('should return null for empty entries', () {
      final result = policy.determineEvictionCandidate({});
      expect(result, isNull);
    });

    test('should return oldest entry key', () {
      final now = ZonedDateTime.now(ZoneId.UTC);
      final entries = {
        'key1': DefaultCache('v1', null, now.minus(Duration(seconds: 10)), ZoneId.UTC),
        'key2': DefaultCache('v2', null, now.minus(Duration(seconds: 5)), ZoneId.UTC),
        'key3': DefaultCache('v3', null, now, ZoneId.UTC),
      };
      final result = policy.determineEvictionCandidate(entries);
      expect(result, equals('key1'));
    });

    test('should return single entry key', () {
      final now = ZonedDateTime.now(ZoneId.UTC);
      final entries = {
        'key1': DefaultCache('v1', null, now, ZoneId.UTC),
      };
      final result = policy.determineEvictionCandidate(entries);
      expect(result, equals('key1'));
    });
  });

  group('LfuEvictionPolicy', () {
    late LfuEvictionPolicy policy;

    setUp(() {
      policy = LfuEvictionPolicy();
    });

    test('should return LFU as name', () {
      expect(policy.getName(), equals('LFU'));
    });

    test('should return null for empty entries', () {
      final result = policy.determineEvictionCandidate({});
      expect(result, isNull);
    });

    test('should return entry with lowest access count', () {
      final now = ZonedDateTime.now(ZoneId.UTC);
      final cache1 = DefaultCache('v1', null, now, ZoneId.UTC);
      final cache2 = DefaultCache('v2', null, now, ZoneId.UTC);
      final cache3 = DefaultCache('v3', null, now, ZoneId.UTC);

      // cache1: 0 accesses, cache2: 2 accesses, cache3: 1 access
      cache2.recordAccess();
      cache2.recordAccess();
      cache3.recordAccess();

      final entries = {
        'key1': cache1,
        'key2': cache2,
        'key3': cache3,
      };
      final result = policy.determineEvictionCandidate(entries);
      expect(result, equals('key1'));
    });

    test('should return single entry key', () {
      final now = ZonedDateTime.now(ZoneId.UTC);
      final entries = {
        'key1': DefaultCache('v1', null, now, ZoneId.UTC),
      };
      final result = policy.determineEvictionCandidate(entries);
      expect(result, equals('key1'));
    });
  });

  group('LruEvictionPolicy', () {
    late LruEvictionPolicy policy;

    setUp(() {
      policy = LruEvictionPolicy();
    });

    test('should return LRU as name', () {
      expect(policy.getName(), equals('LRU'));
    });

    test('should return null for empty entries', () {
      final result = policy.determineEvictionCandidate({});
      expect(result, isNull);
    });

    test('should return least recently accessed entry', () {
      final now = ZonedDateTime.now(ZoneId.UTC);
      final cache1 = DefaultCache('v1', null, now.minus(Duration(seconds: 10)), ZoneId.UTC);
      final cache2 = DefaultCache('v2', null, now.minus(Duration(seconds: 5)), ZoneId.UTC);
      final cache3 = DefaultCache('v3', null, now, ZoneId.UTC);

      // Record access on cache2 to update its last accessed time
      cache2.recordAccess();

      final entries = {
        'key1': cache1,
        'key2': cache2,
        'key3': cache3,
      };
      final result = policy.determineEvictionCandidate(entries);
      // cache1 has oldest lastAccessedAt (never accessed, created 10s ago)
      expect(result, equals('key1'));
    });

    test('should return single entry key', () {
      final now = ZonedDateTime.now(ZoneId.UTC);
      final entries = {
        'key1': DefaultCache('v1', null, now, ZoneId.UTC),
      };
      final result = policy.determineEvictionCandidate(entries);
      expect(result, equals('key1'));
    });
  });
}
