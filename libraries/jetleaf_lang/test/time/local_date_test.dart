import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../dependencies/exceptions.dart';

void main() {
  group('LocalDate', () {
    test('constructor creates valid date', () {
      final date = LocalDate(2024, 6, 27);
      expect(date.year, 2024);
      expect(date.month, 6);
      expect(date.day, 27);
    });

    test('throws on invalid date', () {
      expect(() => LocalDate(2023, 4, 31), throwsInvalidArgumentException);
    });

    test('parses from ISO string', () {
      final date = LocalDate.parse('2024-06-27');
      expect(date.year, 2024);
      expect(date.month, 6);
      expect(date.day, 27);
    });

    test('throws on invalid ISO string', () {
      expect(() => LocalDate.parse('2024/06/27'), throwsInvalidFormatException);
    });

    test('current date returns today', () {
      final today = LocalDate.now();
      final now = DateTime.now();
      expect(today.year, now.year);
      expect(today.month, now.month);
      expect(today.day, now.day);
    });

    test('day of week is correct', () {
      final date = LocalDate(2023, 10, 25); // Wednesday
      expect(date.dayOfWeek, DateTime.wednesday);
    });

    test('leap year check', () {
      expect(LocalDate(2024, 1, 1).isLeapYear, isTrue);
      expect(LocalDate(2023, 1, 1).isLeapYear, isFalse);
    });

    test('day of year is correct', () {
      expect(LocalDate(2024, 1, 1).dayOfYear, 1);
      expect(LocalDate(2024, 12, 31).dayOfYear, 366);
    });

    test('plusDays works correctly', () {
      final date = LocalDate(2024, 6, 27).plusDays(5);
      expect(date.toString(), '2024-07-02');
    });

    test('minusDays works correctly', () {
      final date = LocalDate(2024, 6, 1).minusDays(1);
      expect(date.toString(), '2024-05-31');
    });

    test('plusMonths handles month overflow', () {
      final date = LocalDate(2023, 1, 31).plusMonths(1);
      expect(date.toString(), '2023-02-28');
    });

    test('plusYears handles leap year edge case', () {
      final date = LocalDate(2020, 2, 29).plusYears(1);
      expect(date.toString(), '2021-02-28');
    });

    test('minusMonths and minusYears work', () {
      final date = LocalDate(2023, 3, 31);
      expect(date.minusMonths(1).toString(), '2023-02-28');
      expect(date.minusYears(1).toString(), '2022-03-31');
    });

    test('comparison operations', () {
      final a = LocalDate(2023, 5, 1);
      final b = LocalDate(2023, 5, 2);
      expect(a.isBefore(b), isTrue);
      expect(b.isAfter(a), isTrue);
      expect(a.isEqual(LocalDate(2023, 5, 1)), isTrue);
    });

    test('conversion to DateTime', () {
      final date = LocalDate(2024, 6, 27).toDateTime();
      expect(date, DateTime(2024, 6, 27));
    });

    test('string conversion is ISO formatted', () {
      final date = LocalDate(2024, 6, 7);
      expect(date.toString(), '2024-06-07');
    });

    test('equality and hashCode', () {
      final a = LocalDate(2024, 6, 27);
      final b = LocalDate(2024, 6, 27);
      final c = LocalDate(2024, 6, 28);
      expect(a == b, isTrue);
      expect(a == c, isFalse);
      expect(a.hashCode, b.hashCode);
    });
  });
}