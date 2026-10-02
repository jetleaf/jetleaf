import 'package:test/test.dart';
import 'package:jetleaf_resource/cache.dart';

void main() {
  group('SimpleCacheMetrics', () {
    late SimpleCacheMetrics metrics;

    setUp(() {
      metrics = SimpleCacheMetrics('testCache');
    });

    test('should initialize with zero counts', () {
      expect(metrics.getTotalNumberOfHits(), equals(0));
      expect(metrics.getTotalNumberOfMisses(), equals(0));
      expect(metrics.getTotalNumberOfEvictions(), equals(0));
      expect(metrics.getTotalNumberOfExpirations(), equals(0));
      expect(metrics.getNumberOfPutOperations(), equals(0));
      expect(metrics.getTotalNumberOfAccesses(), equals(0));
    });

    test('should return 0.0 hit rate when no accesses', () {
      expect(metrics.getHitRate(), equals(0.0));
    });

    test('should record hits', () {
      metrics.recordHit('key1');
      metrics.recordHit('key2');
      expect(metrics.getTotalNumberOfHits(), equals(2));
    });

    test('should record misses', () {
      metrics.recordMiss('key1');
      expect(metrics.getTotalNumberOfMisses(), equals(1));
    });

    test('should record evictions', () {
      metrics.recordEviction('key1');
      metrics.recordEviction('key2');
      metrics.recordEviction('key3');
      expect(metrics.getTotalNumberOfEvictions(), equals(3));
    });

    test('should record expirations', () {
      metrics.recordExpiration('key1');
      expect(metrics.getTotalNumberOfExpirations(), equals(1));
    });

    test('should record puts', () {
      metrics.recordPut('key1');
      metrics.recordPut('key2');
      expect(metrics.getNumberOfPutOperations(), equals(2));
    });

    test('should calculate total accesses as hits + misses', () {
      metrics.recordHit('key1');
      metrics.recordHit('key2');
      metrics.recordMiss('key1');
      expect(metrics.getTotalNumberOfAccesses(), equals(3));
    });

    test('should calculate hit rate correctly', () {
      metrics.recordHit('key1');
      metrics.recordHit('key2');
      metrics.recordMiss('key1');
      // 2 hits / 3 total = 66.67%
      expect(metrics.getHitRate(), closeTo(66.67, 0.1));
    });

    test('should calculate hit rate as 100% when all hits', () {
      metrics.recordHit('key1');
      metrics.recordHit('key2');
      expect(metrics.getHitRate(), equals(100.0));
    });

    test('should calculate hit rate as 0% when all misses', () {
      metrics.recordMiss('key1');
      metrics.recordMiss('key2');
      expect(metrics.getHitRate(), equals(0.0));
    });

    test('should reset all counters', () {
      metrics.recordHit('key1');
      metrics.recordMiss('key1');
      metrics.recordPut('key1');
      metrics.recordEviction('key1');
      metrics.recordExpiration('key1');

      metrics.reset();

      expect(metrics.getTotalNumberOfHits(), equals(0));
      expect(metrics.getTotalNumberOfMisses(), equals(0));
      expect(metrics.getNumberOfPutOperations(), equals(0));
      expect(metrics.getTotalNumberOfEvictions(), equals(0));
      expect(metrics.getTotalNumberOfExpirations(), equals(0));
    });

    test('should build graph with no operations', () {
      final graph = metrics.buildGraph();
      expect(graph['cache_name'], equals('testCache'));
      expect(graph['operations'], equals('No operation performed'));
    });

    test('should build graph with operations', () {
      metrics.recordHit('key1');
      metrics.recordHit('key1');
      metrics.recordMiss('key2');
      metrics.recordPut('key3');

      final graph = metrics.buildGraph();
      expect(graph['cache_name'], equals('testCache'));

      final operations = graph['operations'] as Map<String, Map<String, int>>;
      expect(operations['get']!['key1'], equals(2));
      expect(operations['miss']!['key2'], equals(1));
      expect(operations['put']!['key3'], equals(1));
    });

    test('should track duplicate keys in graph', () {
      metrics.recordHit('key1');
      metrics.recordHit('key1');
      metrics.recordHit('key1');

      final graph = metrics.buildGraph();
      final operations = graph['operations'] as Map<String, Map<String, int>>;
      expect(operations['get']!['key1'], equals(3));
    });
  });
}
