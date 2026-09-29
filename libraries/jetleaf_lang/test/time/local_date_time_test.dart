import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../dependencies/exceptions.dart';

void main() {
  group('LocalDate', () {
    test('should create LocalDate with valid components', () {
      final date = LocalDate(2023, 12, 25);
      expect(date.year, equals(2023));
      expect(date.month, equals(12));
      expect(date.day, equals(25));
    });

    test('should validate date components', () {
      expect(() => LocalDate(2023, 13, 1), throwsInvalidArgumentException);
      expect(() => LocalDate(2023, 2, 30), throwsInvalidArgumentException);
      expect(() => LocalDate(2023, 4, 31), throwsInvalidArgumentException);
    });

    test('should parse LocalDate from string', () {
      final date = LocalDate.parse('2023-12-25');
      expect(date.year, equals(2023));
      expect(date.month, equals(12));
      expect(date.day, equals(25));
    });

    test('should handle leap years', () {
      final leapYear = LocalDate(2020, 2, 29);
      expect(leapYear.isLeapYear, isTrue);
      expect(leapYear.lengthOfYear, equals(366));
      
      final nonLeapYear = LocalDate(2021, 2, 28);
      expect(nonLeapYear.isLeapYear, isFalse);
      expect(nonLeapYear.lengthOfYear, equals(365));
    });

    test('should calculate day of week and day of year', () {
      final date = LocalDate(2023, 1, 1); // Sunday
      expect(date.dayOfWeek, equals(7));
      expect(date.dayOfYear, equals(1));
      
      final date2 = LocalDate(2023, 12, 31);
      expect(date2.dayOfYear, equals(365));
    });

    test('should add and subtract days', () {
      final date = LocalDate(2023, 12, 25);
      
      final nextWeek = date.plusDays(7);
      expect(nextWeek, equals(LocalDate(2024, 1, 1)));
      
      final lastWeek = date.minusDays(7);
      expect(lastWeek, equals(LocalDate(2023, 12, 18)));
    });

    test('should add and subtract months', () {
      final date = LocalDate(2023, 1, 31);
      
      final nextMonth = date.plusMonths(1);
      expect(nextMonth, equals(LocalDate(2023, 2, 28))); // Adjusted for shorter month
      
      final lastMonth = date.minusMonths(1);
      expect(lastMonth, equals(LocalDate(2022, 12, 31)));
    });

    test('should add and subtract years', () {
      final date = LocalDate(2020, 2, 29); // Leap year
      
      final nextYear = date.plusYears(1);
      expect(nextYear, equals(LocalDate(2021, 2, 28))); // Adjusted for non-leap year
      
      final lastYear = date.minusYears(1);
      expect(lastYear, equals(LocalDate(2019, 2, 28)));
    });

    test('should compare dates', () {
      final date1 = LocalDate(2023, 12, 25);
      final date2 = LocalDate(2023, 12, 26);
      final date3 = LocalDate(2023, 12, 25);
      
      expect(date1.compareTo(date2), lessThan(0));
      expect(date2.compareTo(date1), greaterThan(0));
      expect(date1.compareTo(date3), equals(0));
      
      expect(date1.isBefore(date2), isTrue);
      expect(date2.isAfter(date1), isTrue);
      expect(date1.isEqual(date3), isTrue);
    });

    test('should convert to DateTime', () {
      final date = LocalDate(2023, 12, 25);
      final dateTime = date.toDateTime();
      
      expect(dateTime.year, equals(2023));
      expect(dateTime.month, equals(12));
      expect(dateTime.day, equals(25));
      expect(dateTime.hour, equals(0));
      expect(dateTime.minute, equals(0));
      expect(dateTime.second, equals(0));
    });

    test('should convert to string', () {
      final date = LocalDate(2023, 12, 25);
      expect(date.toString(), equals('2023-12-25'));
      
      final date2 = LocalDate(2023, 1, 5);
      expect(date2.toString(), equals('2023-01-05'));
    });

    test('should handle equality and hashCode', () {
      final date1 = LocalDate(2023, 12, 25);
      final date2 = LocalDate(2023, 12, 25);
      final date3 = LocalDate(2023, 12, 26);
      
      expect(date1, equals(date2));
      expect(date1.hashCode, equals(date2.hashCode));
      expect(date1, isNot(equals(date3)));
    });
  });
}