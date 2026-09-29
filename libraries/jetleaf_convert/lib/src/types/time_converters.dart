import 'package:jetleaf_lang/lang.dart';

import '../exceptions.dart';
import '../helpers/_commons.dart';

/// {@template time_converters}
/// Comprehensive collection of converters for time-related objects.
/// 
/// This file contains bi-directional converters for:
/// - Custom time objects: LocalDateTime, LocalDate, LocalTime, ZoneId, ZonedDateTime
/// - Dart built-in objects: DateTime, Duration
/// - String representations and parsing
/// - Epoch milliseconds and timestamps
/// - Cross-conversions between different time types
/// 
/// All converters follow the standard converter pattern with proper error handling,
/// null safety, and comprehensive documentation.
/// {@endtemplate}

// =============================================================================
// STRING CONVERTERS
// =============================================================================

/// Converts String to DateTime using DateTime.parse()
/// 
/// Supports ISO 8601 format and other standard DateTime string formats.
/// 
/// Example:
/// ```dart
/// final converter = StringToDateTimeConverter();
/// final dateTime = converter.convert('2023-12-25T15:30:00Z');
/// ```
class StringToDateTimeConverter extends CommonConverter<String, DateTime> {
  @override
  DateTime convert(String input) {
    try {
      return DateTime.parse(input);
    } catch (e) {
      throw ConversionFailedException(sourceType: Class<String>(), targetType: Class<DateTime>(), value: input, point: e);
    }
  }
}

/// Converts DateTime to String using ISO 8601 format
/// 
/// Example:
/// ```dart
/// final converter = DateTimeToStringConverter();
/// final string = converter.convert(DateTime.now());
/// ```
class DateTimeToStringConverter extends CommonConverter<DateTime, String> {
  @override
  String convert(DateTime input) {
    return input.toIso8601String();
  }
}

/// Converts String to LocalDateTime using LocalDateTime.parse()
/// 
/// Supports format: YYYY-MM-DDTHH:mm:ss[.SSS]
/// 
/// Example:
/// ```dart
/// final converter = StringToLocalDateTimeConverter();
/// final localDateTime = converter.convert('2023-12-25T15:30:00');
/// ```
class StringToLocalDateTimeConverter extends CommonConverter<String, LocalDateTime> {
  @override
  LocalDateTime convert(String input) {
    try {
      return LocalDateTime.parse(input);
    } catch (e) {
      throw ConversionFailedException(sourceType: Class<String>(), targetType: Class<LocalDateTime>(), value: input, point: e);
    }
  }
}

/// Converts LocalDateTime to String using ISO 8601 format
/// 
/// Example:
/// ```dart
/// final converter = LocalDateTimeToStringConverter();
/// final string = converter.convert(LocalDateTime.now());
/// ```
class LocalDateTimeToStringConverter extends CommonConverter<LocalDateTime, String> {
  @override
  String convert(LocalDateTime input) {
    return input.toString();
  }
}

/// Converts String to LocalDate using LocalDate.parse()
/// 
/// Supports format: YYYY-MM-DD
/// 
/// Example:
/// ```dart
/// final converter = StringToLocalDateConverter();
/// final localDate = converter.convert('2023-12-25');
/// ```
class StringToLocalDateConverter extends CommonConverter<String, LocalDate> {
  @override
  LocalDate convert(String input) {
    try {
      return LocalDate.parse(input);
    } catch (e) {
      throw ConversionFailedException(sourceType: Class<String>(), targetType: Class<LocalDate>(), value: input, point: e);
    }
  }
}

/// Converts LocalDate to String using ISO 8601 format
/// 
/// Example:
/// ```dart
/// final converter = LocalDateToStringConverter();
/// final string = converter.convert(LocalDate.now());
/// ```
class LocalDateToStringConverter extends CommonConverter<LocalDate, String> {
  @override
  String convert(LocalDate input) {
    return input.toString();
  }
}

/// Converts String to LocalTime using LocalTime.parse()
/// 
/// Supports formats: HH:mm, HH:mm:ss, HH:mm:ss.SSS
/// 
/// Example:
/// ```dart
/// final converter = StringToLocalTimeConverter();
/// final localTime = converter.convert('15:30:45.123');
/// ```
class StringToLocalTimeConverter extends CommonConverter<String, LocalTime> {
  @override
  LocalTime convert(String input) {
    try {
      return LocalTime.parse(input);
    } catch (e) {
      throw ConversionFailedException(sourceType: Class<String>(), targetType: Class<LocalTime>(), value: input, point: e);
    }
  }
}

/// Converts LocalTime to String using HH:mm:ss[.SSS] format
/// 
/// Example:
/// ```dart
/// final converter = LocalTimeToStringConverter();
/// final string = converter.convert(LocalTime.now());
/// ```
class LocalTimeToStringConverter extends CommonConverter<LocalTime, String> {
  @override
  String convert(LocalTime input) {
    return input.toString();
  }
}

/// Converts String to ZoneId using ZoneId()
/// 
/// Example:
/// ```dart
/// final converter = StringToZoneIdConverter();
/// final zoneId = converter.convert('America/New_York');
/// ```
class StringToZoneIdConverter extends CommonConverter<String, ZoneId> {
  @override
  ZoneId convert(String input) {
    try {
      return ZoneId.of(input);
    } catch (e) {
      throw ConversionFailedException(sourceType: Class<String>(), targetType: Class<ZoneId>(), value: input, point: e);
    }
  }
}

/// Converts ZoneId to String using the zone ID
/// 
/// Example:
/// ```dart
/// final converter = ZoneIdToStringConverter();
/// final string = converter.convert(ZoneId.UTC);
/// ```
class ZoneIdToStringConverter extends CommonConverter<ZoneId, String> {
  @override
  String convert(ZoneId input) {
    return input.id;
  }
}

/// Converts String to ZonedDateTime using ZonedDateTime.parse()
/// 
/// Supports ISO 8601 format with timezone information
/// 
/// Example:
/// ```dart
/// final converter = StringToZonedDateTimeConverter();
/// final zonedDateTime = converter.convert('2023-12-25T15:30:00+01:00[Europe/Paris]');
/// ```
class StringToZonedDateTimeConverter extends CommonConverter<String, ZonedDateTime> {
  @override
  ZonedDateTime convert(String input) {
    try {
      return ZonedDateTime.parse(input);
    } catch (e) {
      throw ConversionFailedException(sourceType: Class<String>(), targetType: Class<ZonedDateTime>(), value: input, point: e);
    }
  }
}

/// Converts ZonedDateTime to String using ISO 8601 format with timezone
/// 
/// Example:
/// ```dart
/// final converter = ZonedDateTimeToStringConverter();
/// final string = converter.convert(ZonedDateTime.now());
/// ```
class ZonedDateTimeToStringConverter extends CommonConverter<ZonedDateTime, String> {
  @override
  String convert(ZonedDateTime input) {
    return input.toString();
  }
}

/// Converts String to Duration using Duration parsing
/// 
/// Supports formats like "1:30:45.123" (hours:minutes:seconds.milliseconds)
/// 
/// Example:
/// ```dart
/// final converter = StringToDurationConverter();
/// final duration = converter.convert('2:30:15.500');
/// ```
class StringToDurationConverter extends CommonConverter<String, Duration> {
  @override
  Duration convert(String input) {
    try {
      // Parse format: [hours:]minutes:seconds[.milliseconds]
      final parts = input.split(':');
      if (parts.isEmpty || parts.length > 3) {
        throw IllegalArgumentException('Invalid duration format');
      }

      int hours = 0;
      int minutes = 0;
      int seconds = 0;
      int milliseconds = 0;

      if (parts.length == 3) {
        // hours:minutes:seconds[.milliseconds]
        hours = int.parse(parts[0]);
        minutes = int.parse(parts[1]);
        final secondsParts = parts[2].split('.');
        seconds = int.parse(secondsParts[0]);
        if (secondsParts.length == 2) {
          milliseconds = int.parse(secondsParts[1].padRight(3, '0').substring(0, 3));
        }
      } else if (parts.length == 2) {
        // minutes:seconds[.milliseconds]
        minutes = int.parse(parts[0]);
        final secondsParts = parts[1].split('.');
        seconds = int.parse(secondsParts[0]);
        if (secondsParts.length == 2) {
          milliseconds = int.parse(secondsParts[1].padRight(3, '0').substring(0, 3));
        }
      } else {
        // seconds[.milliseconds]
        final secondsParts = parts[0].split('.');
        seconds = int.parse(secondsParts[0]);
        if (secondsParts.length == 2) {
          milliseconds = int.parse(secondsParts[1].padRight(3, '0').substring(0, 3));
        }
      }

      return Duration(
        hours: hours,
        minutes: minutes,
        seconds: seconds,
        milliseconds: milliseconds,
      );
    } catch (e) {
      throw ConversionFailedException(sourceType: Class<String>(), targetType: Class<Duration>(), value: input, point: e);
    }
  }
}

/// Converts Duration to String in readable format
/// 
/// Example:
/// ```dart
/// final converter = DurationToStringConverter();
/// final string = converter.convert(Duration(hours: 2, minutes: 30, seconds: 15));
/// ```
class DurationToStringConverter extends CommonConverter<Duration, String> {
  @override
  String convert(Duration input) {
    final hours = input.inHours;
    final minutes = input.inMinutes.remainder(60);
    final seconds = input.inSeconds.remainder(60);
    final milliseconds = input.inMilliseconds.remainder(1000);

    if (hours > 0) {
      if (milliseconds > 0) {
        return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(3, '0')}';
      } else {
        return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      }
    } else if (minutes > 0) {
      if (milliseconds > 0) {
        return '$minutes:${seconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(3, '0')}';
      } else {
        return '$minutes:${seconds.toString().padLeft(2, '0')}';
      }
    } else {
      if (milliseconds > 0) {
        return '$seconds.${milliseconds.toString().padLeft(3, '0')}';
      } else {
        return seconds.toString();
      }
    }
  }
}

// =============================================================================
// DATETIME CONVERTERS
// =============================================================================

/// Converts DateTime to LocalDateTime
/// 
/// Example:
/// ```dart
/// final converter = DateTimeToLocalDateTimeConverter();
/// final localDateTime = converter.convert(DateTime.now());
/// ```
class DateTimeToLocalDateTimeConverter extends CommonConverter<DateTime, LocalDateTime> {
  @override
  LocalDateTime convert(DateTime input) {
    return LocalDateTime.fromDateTime(input);
  }
}

/// Converts LocalDateTime to DateTime (assumes UTC)
/// 
/// Example:
/// ```dart
/// final converter = LocalDateTimeToDateTimeConverter();
/// final dateTime = converter.convert(LocalDateTime.now());
/// ```
class LocalDateTimeToDateTimeConverter extends CommonConverter<LocalDateTime, DateTime> {
  @override
  DateTime convert(LocalDateTime input) {
    return input.toDateTime();
  }
}

/// Converts DateTime to LocalDate
/// 
/// Example:
/// ```dart
/// final converter = DateTimeToLocalDateConverter();
/// final localDate = converter.convert(DateTime.now());
/// ```
class DateTimeToLocalDateConverter extends CommonConverter<DateTime, LocalDate> {
  @override
  LocalDate convert(DateTime input) {
    return LocalDate.fromDateTime(input);
  }
}

/// Converts LocalDate to DateTime (at midnight UTC)
/// 
/// Example:
/// ```dart
/// final converter = LocalDateToDateTimeConverter();
/// final dateTime = converter.convert(LocalDate.now());
/// ```
class LocalDateToDateTimeConverter extends CommonConverter<LocalDate, DateTime> {
  @override
  DateTime convert(LocalDate input) {
    return input.toDateTime();
  }
}

/// Converts DateTime to LocalTime
/// 
/// Example:
/// ```dart
/// final converter = DateTimeToLocalTimeConverter();
/// final localTime = converter.convert(DateTime.now());
/// ```
class DateTimeToLocalTimeConverter extends CommonConverter<DateTime, LocalTime> {
  @override
  LocalTime convert(DateTime input) {
    return LocalTime.fromDateTime(input);
  }
}

/// Converts DateTime to ZonedDateTime with specified zone
/// 
/// Example:
/// ```dart
/// final converter = DateTimeToZonedDateTimeConverter();
/// final zonedDateTime = converter.convert(DateTime.now());
/// ```
class DateTimeToZonedDateTimeConverter extends CommonConverter<DateTime, ZonedDateTime> {
  final ZoneId? defaultZone;

  DateTimeToZonedDateTimeConverter([this.defaultZone]);

  @override
  ZonedDateTime convert(DateTime input) {
    final zone = defaultZone ?? ZoneId.UTC;
    return ZonedDateTime.fromDateTime(input, zone);
  }
}

/// Converts ZonedDateTime to DateTime
/// 
/// Example:
/// ```dart
/// final converter = ZonedDateTimeToDateTimeConverter();
/// final dateTime = converter.convert(ZonedDateTime.now());
/// ```
class ZonedDateTimeToDateTimeConverter extends CommonConverter<ZonedDateTime, DateTime> {
  @override
  DateTime convert(ZonedDateTime input) {
    return input.toDateTime();
  }
}

// =============================================================================
// EPOCH MILLISECONDS CONVERTERS
// =============================================================================

/// Converts int (epoch milliseconds) to DateTime
/// 
/// Example:
/// ```dart
/// final converter = IntToDateTimeConverter();
/// final dateTime = converter.convert(1703520000000);
/// ```
class IntToDateTimeConverter extends CommonConverter<int, DateTime> {
  @override
  DateTime convert(int input) {
    try {
      return DateTime.fromMillisecondsSinceEpoch(input);
    } catch (e) {
      throw ConversionFailedException(sourceType: Class<int>(), targetType: Class<DateTime>(), value: input, point: e);
    }
  }
}

/// Converts DateTime to int (epoch milliseconds)
/// 
/// Example:
/// ```dart
/// final converter = DateTimeToIntConverter();
/// final epochMillis = converter.convert(DateTime.now());
/// ```
class DateTimeToIntConverter extends CommonConverter<DateTime, int> {
  @override
  int convert(DateTime input) {
    return input.millisecondsSinceEpoch;
  }
}

/// Converts int (epoch milliseconds) to ZonedDateTime
/// 
/// Example:
/// ```dart
/// final converter = IntToZonedDateTimeConverter();
/// final zonedDateTime = converter.convert(1703520000000);
/// ```
class IntToZonedDateTimeConverter extends CommonConverter<int, ZonedDateTime> {
  final ZoneId? defaultZone;

  IntToZonedDateTimeConverter([this.defaultZone]);

  @override
  ZonedDateTime convert(int input) {
    final zone = defaultZone ?? ZoneId.UTC;
    return ZonedDateTime.fromEpochMilli(input, zone);
  }
}

/// Converts ZonedDateTime to int (epoch milliseconds)
/// 
/// Example:
/// ```dart
/// final converter = ZonedDateTimeToIntConverter();
/// final epochMillis = converter.convert(ZonedDateTime.now());
/// ```
class ZonedDateTimeToIntConverter extends CommonConverter<ZonedDateTime, int> {
  @override
  int convert(ZonedDateTime input) {
    return input.toEpochMilli();
  }
}

/// Converts int (milliseconds) to Duration
/// 
/// Example:
/// ```dart
/// final converter = IntToDurationConverter();
/// final duration = converter.convert(90000); // 1.5 minutes
/// ```
class IntToDurationConverter extends CommonConverter<int, Duration> {
  @override
  Duration convert(int input) {
    return Duration(milliseconds: input);
  }
}

/// Converts Duration to int (milliseconds)
/// 
/// Example:
/// ```dart
/// final converter = DurationToIntConverter();
/// final milliseconds = converter.convert(Duration(minutes: 5));
/// ```
class DurationToIntConverter extends CommonConverter<Duration, int> {
  @override
  int convert(Duration input) {
    return input.inMilliseconds;
  }
}

// =============================================================================
// CROSS-TYPE CONVERTERS
// =============================================================================

/// Converts LocalDateTime to LocalDate
/// 
/// Example:
/// ```dart
/// final converter = LocalDateTimeToLocalDateConverter();
/// final localDate = converter.convert(LocalDateTime.now());
/// ```
class LocalDateTimeToLocalDateConverter extends CommonConverter<LocalDateTime, LocalDate> {
  @override
  LocalDate convert(LocalDateTime input) {
    return input.toLocalDate();
  }
}

/// Converts LocalDateTime to LocalTime
/// 
/// Example:
/// ```dart
/// final converter = LocalDateTimeToLocalTimeConverter();
/// final localTime = converter.convert(LocalDateTime.now());
/// ```
class LocalDateTimeToLocalTimeConverter extends CommonConverter<LocalDateTime, LocalTime> {
  @override
  LocalTime convert(LocalDateTime input) {
    return input.toLocalTime();
  }
}

/// Converts LocalDate and LocalTime to LocalDateTime
/// 
/// Example:
/// ```dart
/// final converter = LocalDateAndLocalTimeToLocalDateTimeConverter();
/// final localDateTime = converter.convert([LocalDate.now(), LocalTime.now()]);
/// ```
class LocalDateAndLocalTimeToLocalDateTimeConverter extends CommonConverter<List<dynamic>, LocalDateTime> {
  @override
  LocalDateTime convert(List<dynamic> input) {
    if (input.length != 2) {
      throw ConversionFailedException(sourceType: Class<List<dynamic>>(), targetType: Class<LocalDateTime>(), value: input);
    }
    
    if (input[0] is! LocalDate || input[1] is! LocalTime) {
      throw ConversionFailedException(sourceType: Class<List<dynamic>>(), targetType: Class<LocalDateTime>(), value: input);
    }
    
    return LocalDateTime(input[0] as LocalDate, input[1] as LocalTime);
  }
}

/// Converts LocalDateTime to ZonedDateTime with specified zone
/// 
/// Example:
/// ```dart
/// final converter = LocalDateTimeToZonedDateTimeConverter(ZoneId.UTC);
/// final zonedDateTime = converter.convert(LocalDateTime.now());
/// ```
class LocalDateTimeToZonedDateTimeConverter extends CommonConverter<LocalDateTime, ZonedDateTime> {
  final ZoneId zone;

  LocalDateTimeToZonedDateTimeConverter(this.zone);

  @override
  ZonedDateTime convert(LocalDateTime input) {
    return ZonedDateTime.of(input, zone);
  }
}

/// Converts ZonedDateTime to LocalDateTime
/// 
/// Example:
/// ```dart
/// final converter = ZonedDateTimeToLocalDateTimeConverter();
/// final localDateTime = converter.convert(ZonedDateTime.now());
/// ```
class ZonedDateTimeToLocalDateTimeConverter extends CommonConverter<ZonedDateTime, LocalDateTime> {
  @override
  LocalDateTime convert(ZonedDateTime input) {
    return input.localDateTime;
  }
}

/// Converts ZonedDateTime to LocalDate
/// 
/// Example:
/// ```dart
/// final converter = ZonedDateTimeToLocalDateConverter();
/// final localDate = converter.convert(ZonedDateTime.now());
/// ```
class ZonedDateTimeToLocalDateConverter extends CommonConverter<ZonedDateTime, LocalDate> {
  @override
  LocalDate convert(ZonedDateTime input) {
    return input.toLocalDate();
  }
}

/// Converts ZonedDateTime to LocalTime
/// 
/// Example:
/// ```dart
/// final converter = ZonedDateTimeToLocalTimeConverter();
/// final localTime = converter.convert(ZonedDateTime.now());
/// ```
class ZonedDateTimeToLocalTimeConverter extends CommonConverter<ZonedDateTime, LocalTime> {
  @override
  LocalTime convert(ZonedDateTime input) {
    return input.toLocalTime();
  }
}

/// Converts ZonedDateTime to ZoneId
/// 
/// Example:
/// ```dart
/// final converter = ZonedDateTimeToZoneIdConverter();
/// final zoneId = converter.convert(ZonedDateTime.now());
/// ```
class ZonedDateTimeToZoneIdConverter extends CommonConverter<ZonedDateTime, ZoneId> {
  @override
  ZoneId convert(ZonedDateTime input) {
    return input.zone;
  }
}