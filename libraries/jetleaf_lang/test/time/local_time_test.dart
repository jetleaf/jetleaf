import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../dependencies/exceptions.dart';

void main() {
  group('LocalTime', () {
    test('constructs with valid time', () {
      final t = LocalTime(13, 45, 30, 500);
      expect(t.hour, 13);
      expect(t.minute, 45);
      expect(t.second, 30);
      expect(t.millisecond, 500);
    });

    test('throws on invalid hour', () {
      expect(() => LocalTime(24, 0), throwsInvalidArgumentException);
    });

    test('throws on invalid minute', () {
      expect(() => LocalTime(12, 60), throwsInvalidArgumentException);
    });

    test('throws on invalid second', () {
      expect(() => LocalTime(12, 30, 60), throwsInvalidArgumentException);
    });

    test('throws on invalid millisecond', () {
      expect(() => LocalTime(12, 30, 30, 1000), throwsInvalidArgumentException);
    });

    test('parse valid time strings', () {
      final t1 = LocalTime.parse('08:30');
      expect(t1.hour, 8);
      expect(t1.minute, 30);
      expect(t1.second, 0);
      expect(t1.millisecond, 0);

      final t2 = LocalTime.parse('14:45:59');
      expect(t2.hour, 14);
      expect(t2.minute, 45);
      expect(t2.second, 59);

      final t3 = LocalTime.parse('06:12:03.456');
      expect(t3.hour, 6);
      expect(t3.second, 3);
      expect(t3.millisecond, 456);
    });

    test('parse throws on invalid format', () {
      expect(() => LocalTime.parse('99:99'), throwsInvalidFormatException);
      expect(() => LocalTime.parse('12:30:abc'), throwsInvalidFormatException);
    });

    test('plus and minus wraps correctly', () {
      final t = LocalTime(23, 45);
      final next = t.plusMinutes(30); // should wrap to 00:15
      expect(next.hour, 0);
      expect(next.minute, 15);

      final prev = LocalTime(0, 15).minusMinutes(30); // should wrap to 23:45
      expect(prev.hour, 23);
      expect(prev.minute, 45);
    });

    test('from and to millisecond of day', () {
      final t = LocalTime(14, 8, 22, 70);
      final ms = t.toMillisecondOfDay();
      final restored = LocalTime.fromMillisecondOfDay(ms);
      expect(restored, t);
    });

    test('comparison works correctly', () {
      final t1 = LocalTime(9, 5, 3);
      final t2 = LocalTime(14, 8, 22, 70);
      expect(t1.compareTo(t2), lessThan(0));
      expect(t2.compareTo(t1), greaterThan(0));
      expect(t1.compareTo(t1), 0);
    });

    test('equality and hashCode', () {
      final t1 = LocalTime(9, 5, 3);
      final t2 = LocalTime(9, 5, 3);
      final t3 = LocalTime(9, 5, 4);
      expect(t1, equals(t2));
      expect(t1 == t3, isFalse);
      expect(t1.hashCode, equals(t2.hashCode));
    });

    test('toString formats correctly', () {
      expect(LocalTime(9, 5, 3).toString(), '09:05:03');
      expect(LocalTime(14, 8, 22, 70).toString(), '14:08:22.070');
    });

    test('named constructors: midnight, noon, now', () {
      final midnight = LocalTime.midnight();
      expect(midnight.hour, 0);
      expect(midnight.minute, 0);

      final noon = LocalTime.noon();
      expect(noon.hour, 12);
      expect(noon.minute, 0);

      final now = LocalTime.now();
      final sys = DateTime.now();
      expect(now.hour, sys.hour);
    });

    test('isBefore, isAfter, isEqual', () {
      final a = LocalTime(10, 0);
      final b = LocalTime(11, 0);
      expect(a.isBefore(b), isTrue);
      expect(b.isAfter(a), isTrue);
      expect(a.isEqual(LocalTime(10, 0)), isTrue);
    });
  });
}