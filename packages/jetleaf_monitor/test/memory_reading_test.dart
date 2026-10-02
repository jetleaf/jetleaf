import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_monitor/jetleaf_monitor.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultMemoryReading', () {
    test('should create with default values', () {
      final reading = DefaultMemoryReading();
      expect(reading.getCreatedAt(), isA<DateTime>());
      expect(reading.getMemoryInMegaByte().value, equals(0.0));
      expect(reading.getUptime(), equals(Duration.zero));
    });

    test('should create with custom values', () {
      final now = DateTime(2025, 6, 15, 10, 30);
      final reading = DefaultMemoryReading(
        timestamp: now,
        memoryMB: 256.5,
        uptime: Duration(minutes: 10),
      );
      expect(reading.getCreatedAt(), equals(now));
      expect(reading.getMemoryInMegaByte().value, equals(256.5));
      expect(reading.getUptime(), equals(Duration(minutes: 10)));
    });

    test('should return memory as Double', () {
      final reading = DefaultMemoryReading(memoryMB: 123.45);
      expect(reading.getMemoryInMegaByte(), isA<Double>());
      expect(reading.getMemoryInMegaByte().value, equals(123.45));
    });

    test('should format memory as string with MB suffix', () {
      final reading = DefaultMemoryReading(memoryMB: 123.456);
      expect(reading.getMemoryInMegaByteString(), equals('123.46MB'));
    });

    test('should format memory as string with two decimal places', () {
      final reading = DefaultMemoryReading(memoryMB: 100.0);
      expect(reading.getMemoryInMegaByteString(), equals('100.00MB'));
    });

    test('should format zero memory as string', () {
      final reading = DefaultMemoryReading(memoryMB: 0.0);
      expect(reading.getMemoryInMegaByteString(), equals('0.00MB'));
    });

    test('should have equalizedProperties', () {
      final reading = DefaultMemoryReading(
        timestamp: DateTime(2025),
        memoryMB: 100.0,
        uptime: Duration(seconds: 5),
      );
      final props = reading.equalizedProperties();
      expect(props.length, equals(3));
      expect(props[0], equals(100.0));
      expect(props[1], equals(DateTime(2025)));
      expect(props[2], equals(Duration(seconds: 5)));
    });

    test('should implement EqualsAndHashCode', () {
      final r1 = DefaultMemoryReading(
        timestamp: DateTime(2025),
        memoryMB: 100.0,
        uptime: Duration(seconds: 5),
      );
      expect(r1, isA<EqualsAndHashCode>());
    });

    test('should not be equal with different memory', () {
      final r1 = DefaultMemoryReading(memoryMB: 100.0);
      final r2 = DefaultMemoryReading(memoryMB: 200.0);
      expect(r1, isNot(equals(r2)));
    });

    test('should have readable toString', () {
      final reading = DefaultMemoryReading(
        timestamp: DateTime(2025, 1, 1),
        memoryMB: 123.45,
        uptime: Duration(minutes: 5),
      );
      final str = reading.toString();
      expect(str, contains('MemoryReading'));
      expect(str, contains('123.45MB'));
      expect(str, contains('uptime:'));
    });

    test('should implement MemoryReading interface', () {
      final reading = DefaultMemoryReading();
      expect(reading, isA<MemoryReading>());
    });

    test('should implement AbstractMemoryReading', () {
      final reading = DefaultMemoryReading();
      expect(reading, isA<AbstractMemoryReading>());
    });
  });
}
