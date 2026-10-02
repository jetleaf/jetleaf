import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_monitor/jetleaf_monitor.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultMemoryAnalytics', () {
    test('should create with default values', () {
      final analytics = DefaultMemoryAnalytics();
      expect(analytics.getMinimumMemoryInMegaByte().value, equals(0.0));
      expect(analytics.getMaximumMemoryInMegaByte().value, equals(0.0));
      expect(analytics.getAverageMemoryInMegaByte().value, equals(0.0));
      expect(analytics.getCurrentMemoryInMegaByte().value, equals(0.0));
      expect(analytics.getTimeWindow(), equals(Duration.zero));
      expect(analytics.getReadings(), isEmpty);
    });

    test('should create with custom values', () {
      final analytics = DefaultMemoryAnalytics(
        timeWindow: Duration(minutes: 5),
        minMemoryMB: 100.0,
        maxMemoryMB: 500.0,
        avgMemoryMB: 300.0,
        currentMemoryMB: 350.0,
      );
      expect(analytics.getMinimumMemoryInMegaByte().value, equals(100.0));
      expect(analytics.getMaximumMemoryInMegaByte().value, equals(500.0));
      expect(analytics.getAverageMemoryInMegaByte().value, equals(300.0));
      expect(analytics.getCurrentMemoryInMegaByte().value, equals(350.0));
      expect(analytics.getTimeWindow(), equals(Duration(minutes: 5)));
    });

    test('should return readings as unmodifiable list', () {
      final readings = [
        DefaultMemoryReading(memoryMB: 100.0),
        DefaultMemoryReading(memoryMB: 200.0),
      ];
      final analytics = DefaultMemoryAnalytics(readings: readings);
      final result = analytics.getReadings();
      expect(result.length, equals(2));
      expect(() => result.add(DefaultMemoryReading()), throwsA(isA<UnsupportedError>()));
    });

    test('should compute minimum delta', () {
      final analytics = DefaultMemoryAnalytics(
        minMemoryMB: 100.0,
        currentMemoryMB: 350.0,
      );
      expect(analytics.getMinimumDelta().value, equals(250.0));
    });

    test('should compute maximum delta', () {
      final analytics = DefaultMemoryAnalytics(
        maxMemoryMB: 500.0,
        currentMemoryMB: 350.0,
      );
      expect(analytics.getMaximumDelta().value, equals(-150.0));
    });

    test('should compute range', () {
      final analytics = DefaultMemoryAnalytics(
        minMemoryMB: 100.0,
        maxMemoryMB: 500.0,
      );
      expect(analytics.getRange().value, equals(400.0));
    });

    test('should format minimum delta as string', () {
      final analytics = DefaultMemoryAnalytics(
        minMemoryMB: 100.0,
        currentMemoryMB: 350.123,
      );
      expect(analytics.getMinimumDeltaString(), equals('250.12MB'));
    });

    test('should format maximum delta as string', () {
      final analytics = DefaultMemoryAnalytics(
        maxMemoryMB: 500.0,
        currentMemoryMB: 350.0,
      );
      expect(analytics.getMaximumDeltaString(), equals('-150.00MB'));
    });

    test('should format range as string', () {
      final analytics = DefaultMemoryAnalytics(
        minMemoryMB: 100.0,
        maxMemoryMB: 500.0,
      );
      expect(analytics.getRangeString(), equals('400.00MB'));
    });

    test('should format min memory as string', () {
      final analytics = DefaultMemoryAnalytics(minMemoryMB: 123.456);
      expect(analytics.getMinimumMemoryInMegaByteString(), equals('123.46MB'));
    });

    test('should format max memory as string', () {
      final analytics = DefaultMemoryAnalytics(maxMemoryMB: 500.0);
      expect(analytics.getMaximumMemoryInMegaByteString(), equals('500.00MB'));
    });

    test('should format avg memory as string', () {
      final analytics = DefaultMemoryAnalytics(avgMemoryMB: 300.123);
      expect(analytics.getAverageMemoryInMegaByteString(), equals('300.12MB'));
    });

    test('should format current memory as string', () {
      final analytics = DefaultMemoryAnalytics(currentMemoryMB: 350.5);
      expect(analytics.getCurrentMemoryInMegaByteString(), equals('350.50MB'));
    });

    test('should serialize to JSON', () {
      final analytics = DefaultMemoryAnalytics(
        timeWindow: Duration(minutes: 5),
        minMemoryMB: 100.0,
        maxMemoryMB: 500.0,
        avgMemoryMB: 300.0,
        currentMemoryMB: 350.0,
      );
      final json = analytics.toJson();
      expect(json['time_window'], equals(5));
      expect(json['min_memory_in_mb'], equals('100.00MB'));
      expect(json['max_memory_in_mb'], equals('500.00MB'));
      expect(json['avg_memory_in_mb'], equals('300.00MB'));
      expect(json['current_memory_in_mb'], equals('350.00MB'));
      expect(json['maximum_delta_in_mb'], isA<String>());
      expect(json['minimum_delta_in_mb'], isA<String>());
      expect(json['range_in_mb'], isA<String>());
    });

    test('should implement MemoryAnalytics interface', () {
      final analytics = DefaultMemoryAnalytics();
      expect(analytics, isA<MemoryAnalytics>());
    });

    test('should implement AbstractMemoryAnalytics', () {
      final analytics = DefaultMemoryAnalytics();
      expect(analytics, isA<AbstractMemoryAnalytics>());
    });

    test('should have equalizedProperties', () {
      final analytics = DefaultMemoryAnalytics(
        timeWindow: Duration(minutes: 5),
        minMemoryMB: 100.0,
        maxMemoryMB: 500.0,
        avgMemoryMB: 300.0,
        currentMemoryMB: 350.0,
      );
      final props = analytics.equalizedProperties();
      expect(props.length, equals(6));
    });

    test('should implement EqualsAndHashCode', () {
      final a1 = DefaultMemoryAnalytics(
        timeWindow: Duration(minutes: 5),
        minMemoryMB: 100.0,
        maxMemoryMB: 500.0,
        avgMemoryMB: 300.0,
        currentMemoryMB: 350.0,
      );
      expect(a1, isA<EqualsAndHashCode>());
    });

    test('should not be equal with different values', () {
      final a1 = DefaultMemoryAnalytics(minMemoryMB: 100.0);
      final a2 = DefaultMemoryAnalytics(minMemoryMB: 200.0);
      expect(a1, isNot(equals(a2)));
    });
  });
}
