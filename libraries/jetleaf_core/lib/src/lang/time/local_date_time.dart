import '../exceptions.dart';
import '../extensions/primitives/int.dart';
import 'local_date.dart';
import 'local_time.dart';

/// {@template local_date_time}
/// A date-time object without a timezone, composed of a [LocalDate] and [LocalTime].
/// 
/// This class represents a specific moment on a calendar, combining a date and time without referencing any timezone.
/// It is immutable and supports arithmetic and comparison operations.
/// 
/// ### Example:
/// ```dart
/// final dateTime = LocalDateTime.of(2024, 12, 31, 23, 59);
/// print(dateTime); // 2024-12-31T23:59:00
/// ```
/// {@endtemplate}
class LocalDateTime implements Comparable<LocalDateTime> {
  /// The date component.
  final LocalDate date;

  /// The time component.
  final LocalTime time;

  /// {@macro local_date_time}
  LocalDateTime(this.date, this.time);

  /// Creates a [LocalDateTime] from individual components.
  ///
  /// [second] and [millisecond] are optional and default to 0.
  ///
  /// ### Example:
  /// ```dart
  /// final dt = LocalDateTime.of(2025, 6, 27, 14, 30);
  /// ```
  /// 
  /// {@macro local_date_time}
  LocalDateTime.of(int year, int month, int day, int hour, int minute, [int second = 0, int millisecond = 0])
      : date = LocalDate(year, month, day),
        time = LocalTime(hour, minute, second, millisecond);

  /// Returns the current local date and time.
  ///
  /// ### Example:
  /// ```dart
  /// final now = LocalDateTime.now();
  /// ```
  /// 
  /// {@macro local_date_time}
  factory LocalDateTime.now() {
    final now = DateTime.now();
    return LocalDateTime.fromDateTime(now);
  }

  /// Creates a [LocalDateTime] from a Dart [DateTime] instance.
  ///
  /// ### Example:
  /// ```dart
  /// final dartNow = DateTime.now();
  /// final customNow = LocalDateTime.fromDateTime(dartNow);
  /// ```
  /// 
  /// {@macro local_date_time}
  factory LocalDateTime.fromDateTime(DateTime dateTime) {
    return LocalDateTime(
      LocalDate.fromDateTime(dateTime),
      LocalTime.fromDateTime(dateTime),
    );
  }

  /// Parses a string in ISO 8601 format: `YYYY-MM-DDTHH:mm[:ss[.SSS]]`
  ///
  /// Throws [InvalidFormatException] for invalid formats.
  ///
  /// ### Example:
  /// ```dart
  /// final parsed = LocalDateTime.parse("2025-06-27T08:15:30.123");
  /// ```
  /// 
  /// {@macro local_date_time}
  factory LocalDateTime.parse(String dateTimeString) {
    final parts = dateTimeString.split('T');
    if (parts.length != 2) {
      throw InvalidFormatException('Invalid datetime format. Expected YYYY-MM-DDTHH:mm:ss');
    }
    final date = LocalDate.parse(parts[0]);
    final time = LocalTime.parse(parts[1]);
    return LocalDateTime(date, time);
  }

  /// The year component of the date.
  /// 
  /// ### Example:
  /// ```dart
  /// final dt = LocalDateTime.of(2025, 6, 27, 14, 30);
  /// final year = dt.year;
  /// ```
  int get year => date.year;

  /// The month component of the date (1–12).
  /// 
  /// ### Example:
  /// ```dart
  /// final dt = LocalDateTime.of(2025, 6, 27, 14, 30);
  /// final month = dt.month;
  /// ```
  int get month => date.month;

  /// The day component of the date.
  /// 
  /// ### Example:
  /// ```dart
  /// final dt = LocalDateTime.of(2025, 6, 27, 14, 30);
  /// final day = dt.day;
  /// ```
  int get day => date.day;

  /// The hour component of the time (0–23).
  /// 
  /// ### Example:
  /// ```dart
  /// final dt = LocalDateTime.of(2025, 6, 27, 14, 30);
  /// final hour = dt.hour;
  /// ```
  int get hour => time.hour;

  /// The minute component of the time (0–59).
  /// 
  /// ### Example:
  /// ```dart
  /// final dt = LocalDateTime.of(2025, 6, 27, 14, 30);
  /// final minute = dt.minute;
  /// ```
  int get minute => time.minute;

  /// The second component of the time (0–59).
  /// 
  /// ### Example:
  /// ```dart
  /// final dt = LocalDateTime.of(2025, 6, 27, 14, 30);
  /// final second = dt.second;
  /// ```
  int get second => time.second;

  /// The millisecond component of the time (0–999).
  /// 
  /// ### Example:
  /// ```dart
  /// final dt = LocalDateTime.of(2025, 6, 27, 14, 30);
  /// final millisecond = dt.millisecond;
  /// ```
  int get millisecond => time.millisecond;

  /// The ISO weekday number, where Monday = 1 and Sunday = 7.
  /// 
  /// ### Example:
  /// ```dart
  /// final dt = LocalDateTime.of(2025, 6, 27, 14, 30);
  /// final dayOfWeek = dt.dayOfWeek;
  /// ```
  int get dayOfWeek => date.dayOfWeek;

  /// The day of the year (1–365 or 366).
  /// 
  /// ### Example:
  /// ```dart
  /// final dt = LocalDateTime.of(2025, 6, 27, 14, 30);
  /// final dayOfYear = dt.dayOfYear;
  /// ```
  int get dayOfYear => date.dayOfYear;

  /// Adds a [Duration] to this [LocalDateTime].
  ///
  /// This operation adjusts both date and time appropriately.
  ///
  /// ### Example:
  /// ```dart
  /// final result = dt.plus(Duration(hours: 5));
  /// ```
  LocalDateTime plus(Duration duration) {
    final dateTime = toDateTime().add(duration);
    return LocalDateTime.fromDateTime(dateTime);
  }

  /// Adds a number of days to the date component.
  /// 
  /// ### Example:
  /// ```dart
  /// final dt = LocalDateTime.of(2024, 6, 27, 14, 30);
  /// final result = dt.plusDays(2);
  /// ```
  LocalDateTime plusDays(int days) => LocalDateTime(date.plusDays(days), time);

  /// Adds hours to the time component.
  /// 
  /// ### Example:
  /// ```dart
  /// final dt = LocalDateTime.of(2024, 6, 27, 14, 30);
  /// final result = dt.plusHours(2);
  /// ```
  LocalDateTime plusHours(int hours) => plus(Duration(hours: hours));

  /// Adds minutes to the time component.
  /// 
  /// ### Example:
  /// ```dart
  /// final dt = LocalDateTime.of(2024, 6, 27, 14, 30);
  /// final result = dt.plusMinutes(30);
  /// ```
  LocalDateTime plusMinutes(int minutes) => plus(Duration(minutes: minutes));

  /// Adds seconds to the time component.
  /// 
  /// ### Example:
  /// ```dart
  /// final dt = LocalDateTime.of(2024, 6, 27, 14, 30);
  /// final result = dt.plusSeconds(30);
  /// ```
  LocalDateTime plusSeconds(int seconds) => plus(Duration(seconds: seconds));

  /// Adds milliseconds to the time component.
  /// 
  /// ### Example:
  /// ```dart
  /// final dt = LocalDateTime.of(2024, 6, 27, 14, 30);
  /// final result = dt.plusMilliseconds(500);
  /// ```
  LocalDateTime plusMilliseconds(int milliseconds) => plus(Duration(milliseconds: milliseconds));

  /// Adds weeks to the date component.
  /// 
  /// ### Example:
  /// ```dart
  /// final dt = LocalDateTime.of(2024, 6, 27, 14, 30);
  /// final result = dt.plusWeeks(2);
  /// ```
  LocalDateTime plusWeeks(int weeks) => LocalDateTime(date.plusWeeks(weeks), time);

  /// Adds months to the date component.
  /// 
  /// ### Example:
  /// ```dart
  /// final dt = LocalDateTime.of(2024, 6, 27, 14, 30);
  /// final result = dt.plusMonths(2);
  /// ```
  LocalDateTime plusMonths(int months) => LocalDateTime(date.plusMonths(months), time);

  /// Adds years to the date component.
  /// 
  /// ### Example:
  /// ```dart
  /// final dt = LocalDateTime.of(2024, 6, 27, 14, 30);
  /// final result = dt.plusYears(1);
  /// ```
  LocalDateTime plusYears(int years) => LocalDateTime(date.plusYears(years), time);

  /// Subtracts a [Duration] from this [LocalDateTime].
  ///
  /// ### Example:
  /// ```dart
  /// final result = dt.minus(Duration(days: 2));
  /// ```
  LocalDateTime minus(Duration duration) {
    final dateTime = toDateTime().subtract(duration);
    return LocalDateTime.fromDateTime(dateTime);
  }

  /// Subtracts days from the date component.
  /// 
  /// ### Example:
  /// ```dart
  /// final dt = LocalDateTime.of(2024, 6, 27, 14, 30);
  /// final result = dt.minusDays(2);
  /// ```
  LocalDateTime minusDays(int days) => plusDays(-days);

  /// Subtracts hours from the time component.
  /// 
  /// ### Example:
  /// ```dart
  /// final dt = LocalDateTime.of(2024, 6, 27, 14, 30);
  /// final result = dt.minusHours(2);
  /// ```
  LocalDateTime minusHours(int hours) => plusHours(-hours);

  /// Subtracts minutes from the time component.
  /// 
  /// ### Example:
  /// ```dart
  /// final dt = LocalDateTime.of(2024, 6, 27, 14, 30);
  /// final result = dt.minusMinutes(30);
  /// ```
  LocalDateTime minusMinutes(int minutes) => plusMinutes(-minutes);

  /// Subtracts seconds from the time component.
  /// 
  /// ### Example:
  /// ```dart
  /// final dt = LocalDateTime.of(2024, 6, 27, 14, 30);
  /// final result = dt.minusSeconds(30);
  /// ```
  LocalDateTime minusSeconds(int seconds) => plusSeconds(-seconds);

  /// Subtracts milliseconds from the time component.
  /// 
  /// ### Example:
  /// ```dart
  /// final dt = LocalDateTime.of(2024, 6, 27, 14, 30);
  /// final result = dt.minusMilliseconds(500);
  /// ```
  LocalDateTime minusMilliseconds(int milliseconds) => plusMilliseconds(-milliseconds);

  /// Subtracts weeks from the date component.
  /// 
  /// ### Example:
  /// ```dart
  /// final dt = LocalDateTime.of(2024, 6, 27, 14, 30);
  /// final result = dt.minusWeeks(2);
  /// ```
  LocalDateTime minusWeeks(int weeks) => plusWeeks(-weeks);

  /// Subtracts months from the date component.
  /// 
  /// ### Example:
  /// ```dart
  /// final dt = LocalDateTime.of(2024, 6, 27, 14, 30);
  /// final result = dt.minusMonths(2);
  /// ```
  LocalDateTime minusMonths(int months) => plusMonths(-months);

  /// Subtracts years from the date component.
  /// 
  /// ### Example:
  /// ```dart
  /// final dt = LocalDateTime.of(2024, 6, 27, 14, 30);
  /// final result = dt.minusYears(1);
  /// ```
  LocalDateTime minusYears(int years) => plusYears(-years);

  /// Converts this instance to a standard [DateTime].
  ///
  /// ### Example:
  /// ```dart
  /// DateTime dartDT = localDT.toDateTime();
  /// ```
  DateTime toDateTime() => DateTime.utc(year, month, day, hour, minute, second, millisecond);

  /// Returns the date component only.
  /// 
  /// ### Example:
  /// ```dart
  /// final dt = LocalDateTime.of(2024, 6, 27, 14, 30);
  /// final date = dt.toLocalDate();
  /// ```
  LocalDate toLocalDate() => date;

  /// Returns the time component only.
  /// 
  /// ### Example:
  /// ```dart
  /// final dt = LocalDateTime.of(2024, 6, 27, 14, 30);
  /// final time = dt.toLocalTime();
  /// ```
  LocalTime toLocalTime() => time;

  /// ISO 8601 formatted string: `YYYY-MM-DDTHH:mm:ss[.SSS]`
  @override
  String toString() => '${date}T$time';

  /// Compares two [LocalDateTime] instances chronologically.
  ///
  /// Returns a negative number if this is earlier, 0 if equal, positive if later.
  ///
  /// ### Example:
  /// ```dart
  /// final dt1 = LocalDateTime.of(2024, 6, 27, 14, 30);
  /// final dt2 = LocalDateTime.of(2024, 6, 27, 15, 30);
  /// print(dt1.compareTo(dt2)); // -1
  /// print(dt2.compareTo(dt1)); // 1
  /// ```
  @override
  int compareTo(LocalDateTime other) {
    int result = date.compareTo(other.date);
    if (result.isNotEqualTo(0)) return result;
    return time.compareTo(other.time);
  }

  /// Generates a hash code for this object.
  @override
  int get hashCode => Object.hash(date, time);

  /// Compares this [LocalDateTime] to another for equality.
  /// 
  /// ### Example:
  /// ```dart
  /// final dt1 = LocalDateTime.of(2024, 6, 27, 14, 30);
  /// final dt2 = LocalDateTime.of(2024, 6, 27, 14, 30);
  /// print(dt1 == dt2); // true
  /// ```
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocalDateTime && date.isEqual(other.date) && time.isEqual(other.time);
  }

  /// Returns true if this instance is earlier than [other].
  /// 
  /// ### Example:
  /// ```dart
  /// final dt1 = LocalDateTime.of(2024, 6, 27, 14, 30);
  /// final dt2 = LocalDateTime.of(2024, 6, 27, 15, 30);
  /// print(dt1.isBefore(dt2)); // true
  /// print(dt2.isBefore(dt1)); // false
  /// ```
  bool isBefore(LocalDateTime other) => compareTo(other).isLessThan(0);

  /// Returns true if this instance is later than [other].
  /// 
  /// ### Example:
  /// ```dart
  /// final dt1 = LocalDateTime.of(2024, 6, 27, 14, 30);
  /// final dt2 = LocalDateTime.of(2024, 6, 27, 15, 30);
  /// print(dt1.isAfter(dt2)); // false
  /// print(dt2.isAfter(dt1)); // true
  /// ```
  bool isAfter(LocalDateTime other) => compareTo(other).isGreaterThan(0);

  /// Returns true if this instance represents the same date and time as [other].
  /// 
  /// ### Example:
  /// ```dart
  /// final dt1 = LocalDateTime.of(2024, 6, 27, 14, 30);
  /// final dt2 = LocalDateTime.of(2024, 6, 27, 14, 30);
  /// print(dt1.isEqual(dt2)); // true
  /// print(dt2.isEqual(dt1)); // true
  /// ```
  bool isEqual(LocalDateTime other) => compareTo(other).isEqualTo(0);
}