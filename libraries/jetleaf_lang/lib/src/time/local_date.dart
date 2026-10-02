import '../exceptions.dart';
import '../extensions/primitives/int.dart';

/// {@template local_date}
/// Represents a calendar date without time or timezone.
/// 
/// This class provides date-only operations such as computing weekdays,
/// adding or subtracting days/months/years, and converting from/to strings.
/// 
/// It ensures valid dates (e.g. February never has more than 29 days).
///
/// ### Example
/// ```dart
/// final date = LocalDate(2024, 6, 27);
/// print(date); // "2024-06-27"
/// ```
/// 
/// {@endtemplate}
class LocalDate implements Comparable<LocalDate> {
  final int year;
  final int month;
  final int day;

  /// Creates a new [LocalDate] instance for a specific year, month, and day.
  ///
  /// Throws [InvalidArgumentException] if the date is not valid (e.g. April 31).
  ///
  /// Example:
  /// ```dart
  /// final d = LocalDate(2023, 2, 28);
  /// ```
  /// 
  /// {@macro local_date}
  LocalDate(this.year, this.month, this.day) {
    _validateDate(year, month, day);
  }

  /// Validates the [year], [month], and [day] to ensure the date is correct.
  static void _validateDate(int year, int month, int day) {
    if (month < 1 || month > 12) {
      throw InvalidArgumentException('Month must be between 1 and 12');
    }
    if (day < 1 || day > _daysInMonth(year, month)) {
      throw InvalidArgumentException('Day $day is invalid for month $month in year $year');
    }
  }

  /// Returns the number of days in a given [month] and [year].
  static int _daysInMonth(int year, int month) {
    switch (month) {
      case 2:
        return _isLeapYear(year) ? 29 : 28;
      case 4:
      case 6:
      case 9:
      case 11:
        return 30;
      default:
        return 31;
    }
  }

  /// Returns true if the given [year] is a leap year.
  static bool _isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  /// Returns the current date as a [LocalDate].
  ///
  /// Example:
  /// ```dart
  /// final today = LocalDate.now();
  /// ```
  /// 
  /// {@macro local_date}
  factory LocalDate.now() {
    final now = DateTime.now();
    return LocalDate(now.year, now.month, now.day);
  }

  /// Creates a [LocalDate] from a [DateTime] object.
  ///
  /// Time components are ignored.
  ///
  /// Example:
  /// ```dart
  /// final dt = DateTime(2023, 3, 10, 14);
  /// final date = LocalDate.fromDateTime(dt); // 2023-03-10
  /// ```
  /// 
  /// {@macro local_date}
  factory LocalDate.fromDateTime(DateTime dateTime) {
    return LocalDate(dateTime.year, dateTime.month, dateTime.day);
  }

  /// Parses a [LocalDate] from an ISO string in the format `YYYY-MM-DD`.
  ///
  /// Throws [InvalidFormatException] if the input is invalid.
  ///
  /// Example:
  /// ```dart
  /// final date = LocalDate.parse("2024-06-27");
  /// ```
  /// 
  /// {@macro local_date}
  factory LocalDate.parse(String dateString) {
    final parts = dateString.split('-');
    if (parts.length != 3) {
      throw InvalidFormatException('Invalid date format. Expected YYYY-MM-DD');
    }
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    return LocalDate(year, month, day);
  }

  /// Returns the ISO 8601 day of the week (1 = Monday, ..., 7 = Sunday).
  ///
  /// Example:
  /// ```dart
  /// final weekday = LocalDate(2023, 10, 25).dayOfWeek; // 3 (Wednesday)
  /// ```
  int get dayOfWeek => DateTime(year, month, day).weekday;

  /// Returns the ordinal day of the year (1 to 365 or 366).
  int get dayOfYear {
    int dayCount = day;
    for (int m = 1; m < month; m++) {
      dayCount += _daysInMonth(year, m);
    }
    return dayCount;
  }

  /// Returns true if this date's year is a leap year.
  bool get isLeapYear => _isLeapYear(year);

  /// Returns the number of days in this date's month.
  int get lengthOfMonth => _daysInMonth(year, month);

  /// Returns the number of days in this date's year (365 or 366).
  int get lengthOfYear => isLeapYear ? 366 : 365;

  /// Returns a new [LocalDate] with [days] added.
  LocalDate plusDays(int days) {
    final dateTime = DateTime(year, month, day).add(Duration(days: days));
    return LocalDate.fromDateTime(dateTime);
  }

  /// Returns a new [LocalDate] with [weeks] added.
  LocalDate plusWeeks(int weeks) => plusDays(weeks * 7);

  /// Returns a new [LocalDate] with [months] added.
  ///
  /// Example:
  /// ```dart
  /// final date = LocalDate(2023, 1, 31);
  /// final result = date.plusMonths(1); // 2023-02-28
  /// ```
  LocalDate plusMonths(int months) {
    int newYear = year;
    int newMonth = month + months;
    while (newMonth > 12) {
      newMonth -= 12;
      newYear++;
    }
    while (newMonth < 1) {
      newMonth += 12;
      newYear--;
    }
    int newDay = day;
    final maxDay = _daysInMonth(newYear, newMonth);
    if (newDay > maxDay) {
      newDay = maxDay;
    }
    return LocalDate(newYear, newMonth, newDay);
  }

  /// Returns a new [LocalDate] with [years] added.
  ///
  /// Adjusts February 29 to February 28 if the new year is not a leap year.
  /// 
  /// ### Example:
  /// ```dart
  /// final date = LocalDate(2023, 2, 29);
  /// final result = date.plusYears(1); // 2024-02-29
  /// ```
  LocalDate plusYears(int years) {
    int newYear = year + years;
    int newDay = day;
    if (month == 2 && day == 29 && !_isLeapYear(newYear)) {
      newDay = 28;
    }
    return LocalDate(newYear, month, newDay);
  }

  /// Returns a new [LocalDate] with [days] subtracted.
  /// 
  /// ### Example:
  /// ```dart
  /// final date = LocalDate(2023, 2, 29);
  /// final result = date.minusDays(1); // 2023-02-28
  /// ```
  LocalDate minusDays(int days) => plusDays(-days);

  /// Returns a new [LocalDate] with [weeks] subtracted.
  /// 
  /// ### Example:
  /// ```dart
  /// final date = LocalDate(2023, 2, 29);
  /// final result = date.minusWeeks(1); // 2023-02-22
  /// ```
  LocalDate minusWeeks(int weeks) => plusWeeks(-weeks);

  /// Returns a new [LocalDate] with [months] subtracted.
  /// 
  /// ### Example:
  /// ```dart
  /// final date = LocalDate(2023, 2, 29);
  /// final result = date.minusMonths(1); // 2023-01-29
  /// ```
  LocalDate minusMonths(int months) => plusMonths(-months);

  /// Returns a new [LocalDate] with [years] subtracted.
  /// 
  /// ### Example:
  /// ```dart
  /// final date = LocalDate(2023, 2, 29);
  /// final result = date.minusYears(1); // 2022-02-28
  /// ```
  LocalDate minusYears(int years) => plusYears(-years);

  /// Converts this date to a [DateTime] set to midnight.
  /// 
  /// ### Example:
  /// ```dart
  /// final date = LocalDate(2024, 6, 27);
  /// final dateTime = date.toDateTime();
  /// print(dateTime); // 2024-06-27 00:00:00.000
  /// ```
  DateTime toDateTime() => DateTime(year, month, day);

  /// Returns the ISO 8601 date string in format `YYYY-MM-DD`.
  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  /// Compares this date with another.
  ///
  /// Returns a negative value if this is before [other], 0 if equal,
  /// and a positive value if after.
  @override
  int compareTo(LocalDate other) {
    int result = year.compareTo(other.year);
    if (result != 0) return result;
    result = month.compareTo(other.month);
    if (result != 0) return result;
    return day.compareTo(other.day);
  }

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalDate &&
          year.isEqualTo(other.year) &&
          month.isEqualTo(other.month) &&
          day.isEqualTo(other.day);

  /// Returns true if this date is before [other].
  /// 
  /// ### Example:
  /// ```dart
  /// final date1 = LocalDate(2024, 6, 27);
  /// final date2 = LocalDate(2024, 6, 28);
  /// print(date1.isBefore(date2)); // true
  /// print(date2.isBefore(date1)); // false
  /// ```
  bool isBefore(LocalDate other) => compareTo(other).isLessThan(0);

  /// Returns true if this date is after [other].
  /// 
  /// ### Example:
  /// ```dart
  /// final date1 = LocalDate(2024, 6, 27);
  /// final date2 = LocalDate(2024, 6, 28);
  /// print(date1.isAfter(date2)); // false
  /// print(date2.isAfter(date1)); // true
  /// ```
  bool isAfter(LocalDate other) => compareTo(other).isGreaterThan(0);

  /// Returns true if this date is the same as [other].
  /// 
  /// ### Example:
  /// ```dart
  /// final date1 = LocalDate(2024, 6, 27);
  /// final date2 = LocalDate(2024, 6, 27);
  /// print(date1.isEqual(date2)); // true
  /// print(date2.isEqual(date1)); // true
  /// ```
  bool isEqual(LocalDate other) => compareTo(other).isEqualTo(0);
}