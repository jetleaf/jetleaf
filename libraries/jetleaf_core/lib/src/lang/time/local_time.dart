import '../exceptions.dart';
import '../extensions/primitives/int.dart';

/// {@template local_time}
/// A value object representing a time of day without any date or timezone information.
///
/// `LocalTime` is immutable and supports operations such as:
/// - Parsing from strings
/// - Formatting to strings
/// - Time arithmetic (addition/subtraction)
/// - Comparison and equality checks
///
/// This class is useful when working with:
/// - Scheduling systems
/// - Time pickers
/// - Representing specific times (like "08:30 AM") without a date context
///
/// ### Example
/// ```dart
/// final time = LocalTime(14, 30); // 2:30 PM
/// final later = time.plusMinutes(45); // 3:15 PM
/// print(later); // 15:15:00
/// ```
/// {@endtemplate}
class LocalTime implements Comparable<LocalTime> {
  /// The hour in 24-hour format. Must be between 0 and 23.
  final int hour;

  /// The minute of the hour. Must be between 0 and 59.
  final int minute;

  /// The second of the minute. Must be between 0 and 59.
  final int second;

  /// The millisecond of the second. Must be between 0 and 999.
  final int millisecond;

  /// Constructs a [LocalTime] instance from its components.
  ///
  /// Throws an [InvalidArgumentException] if any input is outside valid ranges.
  ///
  /// ### Example
  /// ```dart
  /// final time = LocalTime(9, 15, 30, 500);
  /// ```
  /// {@macro local_time}
  LocalTime(this.hour, this.minute, [this.second = 0, this.millisecond = 0]) {
    _validateTime(hour, minute, second, millisecond);
  }

  /// Validates that time components are within their acceptable ranges.
  ///
  /// Throws [InvalidArgumentException] with a descriptive message on failure.
  static void _validateTime(int hour, int minute, int second, int millisecond) {
    if (hour < 0 || hour > 23) {
      throw InvalidArgumentException('Hour must be between 0 and 23');
    }
    if (minute < 0 || minute > 59) {
      throw InvalidArgumentException('Minute must be between 0 and 59');
    }
    if (second < 0 || second > 59) {
      throw InvalidArgumentException('Second must be between 0 and 59');
    }
    if (millisecond < 0 || millisecond > 999) {
      throw InvalidArgumentException('Millisecond must be between 0 and 999');
    }
  }

  /// {@macro local_time_constructor}
  ///
  /// Creates a [LocalTime] representing the current system time (local clock).
  ///
  /// ### Example
  /// ```dart
  /// final now = LocalTime.now();
  /// print(now); // e.g. 13:47:05.123
  /// ```
  /// {@macro local_time}
  factory LocalTime.now() {
    final now = DateTime.now();
    return LocalTime.fromDateTime(now);
  }

  /// {@macro local_time_constructor}
  ///
  /// Constructs a [LocalTime] from a [DateTime] object by extracting its time portion.
  ///
  /// ### Example
  /// ```dart
  /// final dt = DateTime(2024, 1, 1, 10, 45, 30);
  /// final time = LocalTime.fromDateTime(dt); // 10:45:30
  /// ```
  /// {@macro local_time}
  factory LocalTime.fromDateTime(DateTime dateTime) {
    return LocalTime(dateTime.hour, dateTime.minute, dateTime.second, dateTime.millisecond);
  }

  /// {@template local_time_parse}
  /// Parses a time string into a [LocalTime] instance.
  ///
  /// Accepted formats:
  /// - `HH:mm`
  /// - `HH:mm:ss`
  /// - `HH:mm:ss.SSS`
  ///
  /// Throws [InvalidFormatException] if the format is invalid or components can't be parsed.
  ///
  /// ### Example
  /// ```dart
  /// final t1 = LocalTime.parse('08:30');
  /// final t2 = LocalTime.parse('14:45:59');
  /// final t3 = LocalTime.parse('06:12:03.456');
  /// ```
  /// {@endtemplate}
  /// {@macro local_time}
  factory LocalTime.parse(String timeString) {
    final parts = timeString.split(':');
    if (parts.length.isLessThan(2) || parts.length.isGreaterThan(3)) {
      throw InvalidFormatException('Invalid time format. Expected HH:mm, HH:mm:ss or HH:mm:ss.SSS');
    }

    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    int second = 0;
    int millisecond = 0;

    try {
      if (parts.length.equals(3)) {
        final secondParts = parts[2].split('.');
        second = int.parse(secondParts[0]);
        if (secondParts.length.equals(2)) {
          millisecond = int.parse(secondParts[1].padRight(3, '0').substring(0, 3));
        }
      }

      return LocalTime(hour, minute, second, millisecond);
    } catch (e) {
      throw InvalidFormatException('Invalid time format. Expected HH:mm, HH:mm:ss or HH:mm:ss.SSS');
    }
  }

  /// {@template local_time_midnight}
  /// Returns a [LocalTime] instance for midnight (00:00:00.000).
  ///
  /// Useful as a base time or for resets.
  /// {@endtemplate}
  /// {@macro local_time}
  factory LocalTime.midnight() => LocalTime(0, 0, 0, 0);

  /// {@template local_time_noon}
  /// Returns a [LocalTime] instance for noon (12:00:00.000).
  /// {@endtemplate}
  /// {@macro local_time}
  factory LocalTime.noon() => LocalTime(12, 0, 0, 0);

  /// {@template local_time_add}
  /// Returns a new [LocalTime] with the given [duration] added.
  ///
  /// If the result exceeds 24 hours, it wraps around from midnight.
  ///
  /// ### Example
  /// ```dart
  /// final t = LocalTime(23, 30);
  /// final next = t.plus(Duration(minutes: 90)); // 01:00
  /// ```
  /// {@endtemplate}
  LocalTime plus(Duration duration) {
    final totalMilliseconds = toMillisecondOfDay() + duration.inMilliseconds;
    final normalized = totalMilliseconds % _dayMilliseconds;
    return LocalTime.fromMillisecondOfDay(normalized);
  }

  /// {@macro local_time_add}
  LocalTime plusHours(int hours) => plus(Duration(hours: hours));

  /// {@macro local_time_add}
  LocalTime plusMinutes(int minutes) => plus(Duration(minutes: minutes));

  /// {@macro local_time_add}
  LocalTime plusSeconds(int seconds) => plus(Duration(seconds: seconds));

  /// {@macro local_time_add}
  LocalTime plusMilliseconds(int milliseconds) => plus(Duration(milliseconds: milliseconds));

  /// {@template local_time_subtract}
  /// Returns a new [LocalTime] with the given [duration] subtracted.
  ///
  /// If the result is negative, it wraps backward from the end of the day.
  ///
  /// ### Example
  /// ```dart
  /// final t = LocalTime(0, 15);
  /// final prev = t.minus(Duration(minutes: 30)); // 23:45 of previous cycle
  /// ```
  /// {@endtemplate}
  LocalTime minus(Duration duration) {
    final totalMilliseconds = toMillisecondOfDay() - duration.inMilliseconds;
    final normalized = (totalMilliseconds % _dayMilliseconds + _dayMilliseconds) % _dayMilliseconds;
    return LocalTime.fromMillisecondOfDay(normalized);
  }

  /// {@macro local_time_subtract}
  LocalTime minusHours(int hours) => minus(Duration(hours: hours));

  /// {@macro local_time_subtract}
  LocalTime minusMinutes(int minutes) => minus(Duration(minutes: minutes));

  /// {@macro local_time_subtract}
  LocalTime minusSeconds(int seconds) => minus(Duration(seconds: seconds));

  /// {@macro local_time_subtract}
  LocalTime minusMilliseconds(int milliseconds) => minus(Duration(milliseconds: milliseconds));

  /// {@template local_time_from_millis}
  /// Creates a [LocalTime] from the number of milliseconds since midnight.
  ///
  /// Values are normalized to the range of a 24-hour day (0 to 86,399,999).
  /// {@endtemplate}
  /// {@macro local_time}
  factory LocalTime.fromMillisecondOfDay(int millisecondOfDay) {
    final hour = millisecondOfDay ~/ (60 * 60 * 1000);
    final minute = (millisecondOfDay % (60 * 60 * 1000)) ~/ (60 * 1000);
    final second = (millisecondOfDay % (60 * 1000)) ~/ 1000;
    final millisecond = millisecondOfDay % 1000;
    return LocalTime(hour, minute, second, millisecond);
  }

  /// Returns the total number of milliseconds since midnight.
  ///
  /// ### Example
  /// ```dart
  /// final t = LocalTime(14, 8, 22, 70);
  /// print(t.toMillisecondOfDay()); // 52822700
  /// ```
  int toMillisecondOfDay() {
    return hour * 60 * 60 * 1000 + minute * 60 * 1000 + second * 1000 + millisecond;
  }

  /// Returns the total number of seconds since midnight.
  ///
  /// ### Example
  /// ```dart
  /// final t = LocalTime(14, 8, 22, 70);
  /// print(t.toSecondOfDay()); // 52822
  /// ```
  int toSecondOfDay() => toMillisecondOfDay() ~/ 1000;

  /// Returns a string representation of the time in `HH:mm:ss` or `HH:mm:ss.SSS` format.
  ///
  /// ### Example
  /// ```dart
  /// print(LocalTime(9, 5, 3));         // 09:05:03
  /// print(LocalTime(14, 8, 22, 70));   // 14:08:22.070
  /// ```
  @override
  String toString() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    final s = second.toString().padLeft(2, '0');

    if (millisecond.isEqualTo(0)) {
      return '$h:$m:$s';
    } else {
      final ms = millisecond.toString().padLeft(3, '0');
      return '$h:$m:$s.$ms';
    }
  }

  /// Compares this time with another [LocalTime].
  ///
  /// Returns a negative number if this is earlier, positive if later, or zero if equal.
  ///
  /// ### Example
  /// ```dart
  /// final t1 = LocalTime(9, 5, 3);
  /// final t2 = LocalTime(14, 8, 22, 70);
  /// print(t1.compareTo(t2)); // -1
  /// print(t2.compareTo(t1)); // 1
  /// ```
  @override
  int compareTo(LocalTime other) {
    return toMillisecondOfDay().compareTo(other.toMillisecondOfDay());
  }

  /// Returns a hash code based on hour, minute, second, and millisecond.
  @override
  int get hashCode => Object.hash(hour, minute, second, millisecond);

  /// Checks if another object is a [LocalTime] with the same values.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocalTime &&
        hour.isEqualTo(other.hour) &&
        minute.isEqualTo(other.minute) &&
        second.isEqualTo(other.second) &&
        millisecond.isEqualTo(other.millisecond);
  }

  /// Returns `true` if this time is earlier than [other].
  ///
  /// ### Example
  /// ```dart
  /// final t1 = LocalTime(9, 5, 3);
  /// final t2 = LocalTime(14, 8, 22, 70);
  /// print(t1.isBefore(t2)); // true
  /// print(t2.isBefore(t1)); // false
  /// ```
  bool isBefore(LocalTime other) => compareTo(other).isLessThan(0);

  /// Returns `true` if this time is later than [other].
  ///
  /// ### Example
  /// ```dart
  /// final t1 = LocalTime(9, 5, 3);
  /// final t2 = LocalTime(14, 8, 22, 70);
  /// print(t1.isAfter(t2)); // false
  /// print(t2.isAfter(t1)); // true
  /// ```
  bool isAfter(LocalTime other) => compareTo(other).isGreaterThan(0);

  /// Returns `true` if this time is equal to [other].
  ///
  /// ### Example
  /// ```dart
  /// final t1 = LocalTime(9, 5, 3);
  /// final t2 = LocalTime(9, 5, 3);
  /// print(t1.isEqual(t2)); // true
  /// print(t2.isEqual(t1)); // true
  /// ```
  bool isEqual(LocalTime other) => compareTo(other).isEqualTo(0);

  static const int _dayMilliseconds = 24 * 60 * 60 * 1000;
}