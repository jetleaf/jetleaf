import '../exceptions.dart';
import '../locale/locale.dart';
import 'local_date.dart';
import 'local_date_time.dart';
import 'local_time.dart';
import 'zone_id.dart';
import 'zoned_date_time.dart';

/// {@template date_time_formatter}
/// A formatter and parser for date-time objects based on patterns, similar to Java's DateTimeFormatter.
///
/// This class provides pattern-based formatting and parsing of date-time values with support for
/// locales and timezones. It follows Java-like method naming conventions (e.g., `getDate()`, `getPattern()`).
///
/// ## Pattern Syntax
///
/// The formatter uses the following pattern symbols (case-sensitive):
/// - `y` or `yyyy`: Year (e.g., 2024)
/// - `M`: Month (1-12)
/// - `MM`: Month (01-12)
/// - `MMM`: Month abbreviation (Jan, Feb, etc.)
/// - `MMMM`: Full month name (January, February, etc.)
/// - `d`: Day of month (1-31)
/// - `dd`: Day of month (01-31)
/// - `EEE`: Day of week abbreviation (Mon, Tue, etc.)
/// - `EEEE`: Full day of week name (Monday, Tuesday, etc.)
/// - `H`: Hour (0-23)
/// - `HH`: Hour (00-23)
/// - `m`: Minute (0-59)
/// - `mm`: Minute (00-59)
/// - `s`: Second (0-59)
/// - `ss`: Second (00-59)
/// - `S`: Millisecond (0-999)
/// - `SSS`: Millisecond (000-999)
/// - `z`: Timezone abbreviation (EST, PST, etc.)
/// - `zzz`: Timezone name (America/New_York, etc.)
/// - `Z`: Timezone offset (+HH:mm)
/// - `X`: ISO 8601 timezone offset (Z for UTC, ±HH:mm for others)
///
/// ## Usage Examples
///
/// ```dart
/// // Create a formatter with a pattern
/// final formatter = DateTimeFormatter.ofPattern('dd/MM/yyyy HH:mm:ss', Locale('en', 'US'));
///
/// // Format a LocalDateTime
/// final date = LocalDateTime.of(2024, 6, 27, 14, 30, 45);
/// final formatted = formatter.getFormattedDate(date);
/// print(formatted); // Output: 27/06/2024 14:30:45
///
/// // Format a ZonedDateTime
/// final zoned = ZonedDateTime.now(ZoneId.of('America/New_York'));
/// final withZone = formatter.getFormattedZonedDate(zoned);
/// print(withZone); // Output with timezone info
///
/// // Parse a string back to LocalDateTime
/// final parsed = formatter.parseDate('27/06/2024 14:30:45');
/// print(parsed); // LocalDateTime(2024, 6, 27, 14, 30, 45)
/// ```
/// {@endtemplate}
class DateTimeFormatter {
  final String _pattern;
  final Locale _locale;
  final ZoneId? _zone;

  /// Private constructor for internal use.
  DateTimeFormatter._(this._pattern, this._locale, [this._zone]);

  /// {@template of_pattern_method}
  /// Creates a DateTimeFormatter with the specified pattern and optional locale and timezone.
  ///
  /// Example:
  /// ```dart
  /// final formatter = DateTimeFormatter.ofPattern('dd MMM yyyy HH:mm:ss');
  /// final withLocale = DateTimeFormatter.ofPattern('dd MMMM yyyy', Locale('fr', 'FR'));
  /// final withZone = DateTimeFormatter.ofPattern('yyyy-MM-dd HH:mm:ss Z', Locale('en', 'US'), ZoneId.UTC);
  /// ```
  /// {@endtemplate}
  /// 
  /// {@macro date_time_formatter}
  factory DateTimeFormatter.ofPattern(String pattern, [Locale? locale, ZoneId? zone]) {
    if (pattern.isEmpty) {
      throw InvalidFormatException('Pattern cannot be empty');
    }
    locale ??= Locale('en', 'US');
    return DateTimeFormatter._(pattern, locale, zone);
  }

  /// A preconfigured [DateTimeFormatter] for the RFC-1123 date-time format.
  ///
  /// The pattern is `"EEE, dd MMM yyyy HH:mm:ss 'GMT'"`, which is commonly used
  /// in HTTP headers like `Date` and `Expires`.
  ///
  /// Example:
  /// ```dart
  /// final now = DateTime.now().toUtc();
  /// final formatted = DateTimeFormatter.RFC_1123_DATE_TIME.format(now);
  /// print(formatted); // e.g., "Sat, 02 Nov 2025 14:30:00 GMT"
  /// ```
  static final DateTimeFormatter RFC_1123_DATE_TIME = DateTimeFormatter._(
    "EEE, dd MMM yyyy HH:mm:ss 'GMT'",
    Locale('en', 'US'),
    ZoneId.UTC,
  );

  /// Returns a copy of this [DateTimeFormatter] with the specified time zone.
  ///
  /// This does **not** modify the original formatter; instead, it creates a
  /// new instance with the same pattern and locale, but using the provided
  /// zone ID.
  ///
  /// Example:
  /// ```dart
  /// final formatter = DateTimeFormatter.ofPattern('yyyy-MM-dd HH:mm:ss');
  /// final withZone = formatter.withZone('UTC');
  /// final withZoneNY = formatter.withZone('America/New_York');
  /// ```
  ///
  /// Throws an [InvalidFormatException] if the [zone] string is empty or invalid.
  DateTimeFormatter withZone(Object zone) {
    if (zone is String) {
      if (zone.isEmpty) {
        throw InvalidFormatException('Zone id cannot be empty');
      }

      return DateTimeFormatter._(_pattern, _locale, ZoneId.of(zone));
    }

    if (zone is ZoneId) {
      return DateTimeFormatter._(_pattern, _locale, zone);
    }

    throw IllegalArgumentException("Zone must either be a string zone id or ZoneId object");
  }

  /// Returns the pattern string.
  String getPattern() => _pattern;

  /// Returns the locale.
  Locale getLocale() => _locale;

  /// Returns the timezone if set, or null.
  ZoneId? getZone() => _zone;

  /// {@template format_date_method}
  /// Formats a [LocalDateTime] according to the pattern.
  ///
  /// Example:
  /// ```dart
  /// final formatter = DateTimeFormatter.ofPattern('dd/MM/yyyy HH:mm:ss');
  /// final date = LocalDateTime.of(2024, 6, 27, 14, 30, 45);
  /// print(formatter.getFormattedDate(date)); // 27/06/2024 14:30:45
  /// ```
  /// {@endtemplate}
  String getFormattedDate(LocalDateTime dateTime) {
    return _format(dateTime, null);
  }

  /// {@template format_date_only_method}
  /// Formats only the date component of a [LocalDateTime].
  ///
  /// Example:
  /// ```dart
  /// final formatter = DateTimeFormatter.ofPattern('EEEE, MMMM d, yyyy');
  /// final date = LocalDateTime.of(2024, 6, 27, 14, 30, 45);
  /// print(formatter.getFormattedDateOnly(date)); // Thursday, June 27, 2024
  /// ```
  /// {@endtemplate}
  String getFormattedDateOnly(LocalDateTime dateTime) {
    return _formatDateOnly(dateTime);
  }

  /// {@template format_time_only_method}
  /// Formats only the time component of a [LocalDateTime].
  ///
  /// Example:
  /// ```dart
  /// final formatter = DateTimeFormatter.ofPattern('HH:mm:ss');
  /// final date = LocalDateTime.of(2024, 6, 27, 14, 30, 45);
  /// print(formatter.getFormattedTimeOnly(date)); // 14:30:45
  /// ```
  /// {@endtemplate}
  String getFormattedTimeOnly(LocalDateTime dateTime) {
    return _formatTimeOnly(dateTime);
  }

  /// {@template format_zoned_date_method}
  /// Formats a [ZonedDateTime] including timezone information.
  ///
  /// Example:
  /// ```dart
  /// final formatter = DateTimeFormatter.ofPattern('yyyy-MM-dd HH:mm:ss Z');
  /// final zoned = ZonedDateTime.now(ZoneId.AMERICA_NEW_YORK);
  /// print(formatter.getFormattedZonedDate(zoned));
  /// ```
  /// {@endtemplate}
  String getFormattedZonedDate(ZonedDateTime dateTime) {
    return _format(dateTime.localDateTime, dateTime);
  }

  /// {@template format_local_date_method}
  /// Formats a [LocalDate].
  ///
  /// Example:
  /// ```dart
  /// final formatter = DateTimeFormatter.ofPattern('yyyy-MM-dd');
  /// final date = LocalDate(2024, 6, 27);
  /// print(formatter.getFormattedLocalDate(date)); // 2024-06-27
  /// ```
  /// {@endtemplate}
  String getFormattedLocalDate(LocalDate date) {
    final dateTime = LocalDateTime(date, LocalTime(0, 0, 0));
    return _formatDateOnly(dateTime);
  }

  /// {@template format_local_time_method}
  /// Formats a [LocalTime].
  ///
  /// Example:
  /// ```dart
  /// final formatter = DateTimeFormatter.ofPattern('HH:mm:ss');
  /// final time = LocalTime(14, 30, 45);
  /// print(formatter.getFormattedLocalTime(time)); // 14:30:45
  /// ```
  /// {@endtemplate}
  String getFormattedLocalTime(LocalTime time) {
    return _formatTime(time);
  }

  /// Core formatting implementation.
  String _format(LocalDateTime dateTime, ZonedDateTime? zoned) {
    String result = _pattern;
    
    // Format timezone info first (longest patterns)
    result = _replacePattern(result, 'zzz', _getTimezoneName(dateTime, zoned));
    result = _replacePattern(result, 'z', _getTimezoneAbbr(dateTime, zoned));
    result = _replacePattern(result, 'Z', _getTimezoneOffset(zoned));
    result = _replacePattern(result, 'X', _getIsoTimezoneOffset(zoned));
    
    // Format date components
    result = _replacePattern(result, 'yyyy', dateTime.year.toString().padLeft(4, '0'));
    result = _replacePattern(result, 'yy', (dateTime.year % 100).toString().padLeft(2, '0'));
    result = _replacePattern(result, 'y', dateTime.year.toString());
    
    result = _replacePattern(result, 'MMMM', _getFullMonthName(dateTime.month));
    result = _replacePattern(result, 'MMM', _getMonthAbbr(dateTime.month));
    result = _replacePattern(result, 'MM', dateTime.month.toString().padLeft(2, '0'));
    result = _replacePattern(result, 'M', dateTime.month.toString());
    
    result = _replacePattern(result, 'dd', dateTime.day.toString().padLeft(2, '0'));
    result = _replacePattern(result, 'd', dateTime.day.toString());
    
    result = _replacePattern(result, 'EEEE', _getFullDayName(dateTime.dayOfWeek));
    result = _replacePattern(result, 'EEE', _getDayAbbr(dateTime.dayOfWeek));
    
    // Format time components
    result = _replacePattern(result, 'HH', dateTime.hour.toString().padLeft(2, '0'));
    result = _replacePattern(result, 'H', dateTime.hour.toString());
    
    result = _replacePattern(result, 'mm', dateTime.minute.toString().padLeft(2, '0'));
    result = _replacePattern(result, 'm', dateTime.minute.toString());
    
    result = _replacePattern(result, 'ss', dateTime.second.toString().padLeft(2, '0'));
    result = _replacePattern(result, 's', dateTime.second.toString());
    
    result = _replacePattern(result, 'SSS', dateTime.millisecond.toString().padLeft(3, '0'));
    result = _replacePattern(result, 'S', dateTime.millisecond.toString());
    
    return result;
  }

  /// Format date only by filtering the pattern.
  String _formatDateOnly(LocalDateTime dateTime) {
    // Extract date-only patterns
    String datePattern = _pattern
        .replaceAll(RegExp(r'HH|H|mm|m|ss|s|SSS|S|Z|z|X'), '')
        .trim();
    
    if (datePattern.isEmpty) {
      datePattern = 'yyyy-MM-dd'; // Default
    }
    
    String result = datePattern;
    result = _replacePattern(result, 'yyyy', dateTime.year.toString().padLeft(4, '0'));
    result = _replacePattern(result, 'yy', (dateTime.year % 100).toString().padLeft(2, '0'));
    result = _replacePattern(result, 'MMMM', _getFullMonthName(dateTime.month));
    result = _replacePattern(result, 'MMM', _getMonthAbbr(dateTime.month));
    result = _replacePattern(result, 'MM', dateTime.month.toString().padLeft(2, '0'));
    result = _replacePattern(result, 'M', dateTime.month.toString());
    result = _replacePattern(result, 'dd', dateTime.day.toString().padLeft(2, '0'));
    result = _replacePattern(result, 'd', dateTime.day.toString());
    result = _replacePattern(result, 'EEEE', _getFullDayName(dateTime.dayOfWeek));
    result = _replacePattern(result, 'EEE', _getDayAbbr(dateTime.dayOfWeek));
    
    return result;
  }

  /// Format time only by filtering the pattern.
  String _formatTimeOnly(LocalDateTime dateTime) {
    return _formatTime(dateTime.time);
  }

  /// Format just time component.
  String _formatTime(LocalTime time) {
    String result = _pattern
        .replaceAll(RegExp(r'yyyy|yy|y|MMMM|MMM|MM|M|dd|d|EEEE|EEE|Z|z|X'), '')
        .trim();
    
    if (result.isEmpty) {
      result = 'HH:mm:ss'; // Default
    }
    
    result = _replacePattern(result, 'HH', time.hour.toString().padLeft(2, '0'));
    result = _replacePattern(result, 'H', time.hour.toString());
    result = _replacePattern(result, 'mm', time.minute.toString().padLeft(2, '0'));
    result = _replacePattern(result, 'm', time.minute.toString());
    result = _replacePattern(result, 'ss', time.second.toString().padLeft(2, '0'));
    result = _replacePattern(result, 's', time.second.toString());
    result = _replacePattern(result, 'SSS', time.millisecond.toString().padLeft(3, '0'));
    result = _replacePattern(result, 'S', time.millisecond.toString());
    
    return result;
  }

  /// {@template parse_date_method}
  /// Parses a string into a [LocalDateTime] according to the pattern.
  ///
  /// This method attempts to match the input string against the pattern.
  /// 
  /// Example:
  /// ```dart
  /// final formatter = DateTimeFormatter.ofPattern('dd/MM/yyyy HH:mm:ss');
  /// final parsed = formatter.parseDate('27/06/2024 14:30:45');
  /// print(parsed); // LocalDateTime(2024, 6, 27, 14, 30, 45)
  /// ```
  /// {@endtemplate}
  LocalDateTime parseDate(String dateString) {
    try {
      final values = _extractDateTimeValues(dateString);
      
      final year = values['year'] as int? ?? DateTime.now().year;
      final month = values['month'] as int? ?? 1;
      final day = values['day'] as int? ?? 1;
      final hour = values['hour'] as int? ?? 0;
      final minute = values['minute'] as int? ?? 0;
      final second = values['second'] as int? ?? 0;
      final millisecond = values['millisecond'] as int? ?? 0;
      
      return LocalDateTime.of(year, month, day, hour, minute, second, millisecond);
    } catch (e) {
      throw InvalidFormatException('Failed to parse date: $dateString with pattern: $_pattern');
    }
  }

  /// {@template parse_local_date_method}
  /// Parses a string into a [LocalDate].
  ///
  /// Example:
  /// ```dart
  /// final formatter = DateTimeFormatter.ofPattern('yyyy-MM-dd');
  /// final parsed = formatter.parseLocalDate('2024-06-27');
  /// print(parsed); // LocalDate(2024, 6, 27)
  /// ```
  /// {@endtemplate}
  LocalDate parseLocalDate(String dateString) {
    try {
      final values = _extractDateTimeValues(dateString);
      final year = values['year'] as int? ?? DateTime.now().year;
      final month = values['month'] as int? ?? 1;
      final day = values['day'] as int? ?? 1;
      return LocalDate(year, month, day);
    } catch (e) {
      throw InvalidFormatException('Failed to parse date: $dateString with pattern: $_pattern');
    }
  }

  /// {@template parse_local_time_method}
  /// Parses a string into a [LocalTime].
  ///
  /// Example:
  /// ```dart
  /// final formatter = DateTimeFormatter.ofPattern('HH:mm:ss');
  /// final parsed = formatter.parseLocalTime('14:30:45');
  /// print(parsed); // LocalTime(14, 30, 45)
  /// ```
  /// {@endtemplate}
  LocalTime parseLocalTime(String timeString) {
    try {
      final values = _extractDateTimeValues(timeString);
      final hour = values['hour'] as int? ?? 0;
      final minute = values['minute'] as int? ?? 0;
      final second = values['second'] as int? ?? 0;
      final millisecond = values['millisecond'] as int? ?? 0;
      return LocalTime(hour, minute, second, millisecond);
    } catch (e) {
      throw InvalidFormatException('Failed to parse time: $timeString with pattern: $_pattern');
    }
  }

  /// Extracts date-time values from a string using the pattern.
  Map<String, dynamic> _extractDateTimeValues(String input) {
    final Map<String, dynamic> values = {};
    
    // Build a regex pattern from the format pattern
    String regexPattern = _pattern;
    
    // Month names - must be done before M/MM
    final monthMapping = _buildMonthNameMap();
    
    // Replace all patterns with capturing groups
    regexPattern = regexPattern.replaceAll('MMMM', '(${monthMapping.keys.join('|')})');
    regexPattern = regexPattern.replaceAll('MMM', '(${monthMapping.keys.map((k) => k.substring(0, 3)).join('|')})');
    
    // Day names
    final dayMapping = _buildDayNameMap();
    regexPattern = regexPattern.replaceAll('EEEE', '(${dayMapping.keys.join('|')})');
    regexPattern = regexPattern.replaceAll('EEE', '(${dayMapping.keys.map((k) => k.substring(0, 3)).join('|')})');
    
    // Date patterns (must be in order: longer first)
    regexPattern = regexPattern.replaceAll('yyyy', r'(\d{4})');
    regexPattern = regexPattern.replaceAll('yy', r'(\d{2})');
    regexPattern = regexPattern.replaceAll('MM', r'(\d{1,2})');
    regexPattern = regexPattern.replaceAll('dd', r'(\d{1,2})');
    regexPattern = regexPattern.replaceAll('HH', r'(\d{1,2})');
    regexPattern = regexPattern.replaceAll('mm', r'(\d{1,2})');
    regexPattern = regexPattern.replaceAll('ss', r'(\d{1,2})');
    regexPattern = regexPattern.replaceAll('SSS', r'(\d{1,3})');
    regexPattern = regexPattern.replaceAll('M', r'(\d{1,2})');
    regexPattern = regexPattern.replaceAll('d', r'(\d{1,2})');
    regexPattern = regexPattern.replaceAll('H', r'(\d{1,2})');
    regexPattern = regexPattern.replaceAll('m', r'(\d{1,2})');
    regexPattern = regexPattern.replaceAll('s', r'(\d{1,2})');
    regexPattern = regexPattern.replaceAll('S', r'(\d{1,3})');
    regexPattern = regexPattern.replaceAll('Z', r'([+-]\d{2}:\d{2}|Z)');
    regexPattern = regexPattern.replaceAll('X', r'([+-]\d{2}:\d{2}|Z)');
    regexPattern = regexPattern.replaceAll(r'z', r'(\w+)');
    
    regexPattern = '^$regexPattern\$';
    
    try {
      final regex = RegExp(regexPattern);
      final match = regex.firstMatch(input);
      
      if (match == null) {
        throw InvalidFormatException('Input does not match pattern');
      }
      
      // Simple heuristic to extract values based on pattern order
      _extractValuesFromPattern(values);
      
      // Try ISO 8601 parsing as fallback
      if (input.contains('T') || input.contains('t')) {
        try {
          final dt = DateTime.parse(input);
          values['year'] = dt.year;
          values['month'] = dt.month;
          values['day'] = dt.day;
          values['hour'] = dt.hour;
          values['minute'] = dt.minute;
          values['second'] = dt.second;
          values['millisecond'] = dt.millisecond;
          return values;
        } catch (_) {
          // Continue with pattern parsing
        }
      }
      
      // Extract based on pattern structure
      int groupIndex = 1;
      String patternCopy = _pattern;
      
      while (groupIndex <= match.groupCount && patternCopy.isNotEmpty) {
        final value = match.group(groupIndex);
        if (value == null) break;
        
        if (patternCopy.startsWith('yyyy')) {
          values['year'] = int.parse(value);
          patternCopy = patternCopy.substring(4);
        } else if (patternCopy.startsWith('yy')) {
          final year = int.parse(value);
          values['year'] = year > 50 ? year + 1900 : year + 2000;
          patternCopy = patternCopy.substring(2);
        } else if (patternCopy.startsWith('MMMM')) {
          values['month'] = _parseMonthName(value);
          patternCopy = patternCopy.substring(4);
        } else if (patternCopy.startsWith('MMM')) {
          values['month'] = _parseMonthAbbr(value);
          patternCopy = patternCopy.substring(3);
        } else if (patternCopy.startsWith('MM')) {
          values['month'] = int.parse(value);
          patternCopy = patternCopy.substring(2);
        } else if (patternCopy.startsWith('dd')) {
          values['day'] = int.parse(value);
          patternCopy = patternCopy.substring(2);
        } else if (patternCopy.startsWith('HH')) {
          values['hour'] = int.parse(value);
          patternCopy = patternCopy.substring(2);
        } else if (patternCopy.startsWith('mm')) {
          values['minute'] = int.parse(value);
          patternCopy = patternCopy.substring(2);
        } else if (patternCopy.startsWith('ss')) {
          values['second'] = int.parse(value);
          patternCopy = patternCopy.substring(2);
        } else if (patternCopy.startsWith('SSS')) {
          values['millisecond'] = int.parse(value);
          patternCopy = patternCopy.substring(3);
        } else if (patternCopy.startsWith('M')) {
          values['month'] = int.parse(value);
          patternCopy = patternCopy.substring(1);
        } else if (patternCopy.startsWith('d')) {
          values['day'] = int.parse(value);
          patternCopy = patternCopy.substring(1);
        } else if (patternCopy.startsWith('H')) {
          values['hour'] = int.parse(value);
          patternCopy = patternCopy.substring(1);
        } else if (patternCopy.startsWith('m')) {
          values['minute'] = int.parse(value);
          patternCopy = patternCopy.substring(1);
        } else if (patternCopy.startsWith('s')) {
          values['second'] = int.parse(value);
          patternCopy = patternCopy.substring(1);
        } else if (patternCopy.startsWith('S')) {
          values['millisecond'] = int.parse(value);
          patternCopy = patternCopy.substring(1);
        } else if (patternCopy.startsWith('EEEE')) {
          // Day name - skip
          patternCopy = patternCopy.substring(4);
        } else if (patternCopy.startsWith('EEE')) {
          // Day name abbreviation - skip
          patternCopy = patternCopy.substring(3);
        } else if (patternCopy.startsWith('Z') || patternCopy.startsWith('X')) {
          // Timezone - skip
          patternCopy = patternCopy.substring(1);
        } else if (patternCopy.startsWith('z')) {
          // Timezone abbreviation - skip
          patternCopy = patternCopy.substring(1);
        } else {
          // Skip non-pattern character
          patternCopy = patternCopy.substring(1);
        }
        
        groupIndex++;
      }
    } catch (e) {
      throw InvalidFormatException('Failed to parse: $input');
    }
    
    return values;
  }

  void _extractValuesFromPattern(Map<String, dynamic> values) {
    // This is a helper method that can be extended
  }

  /// Replace pattern while preserving literals.
  String _replacePattern(String text, String pattern, String replacement) => text.replaceAll(pattern, replacement);

  // Helper methods for month/day names

  Map<String, int> _buildMonthNameMap() {
    return {
      'January': 1, 'February': 2, 'March': 3, 'April': 4, 'May': 5, 'June': 6,
      'July': 7, 'August': 8, 'September': 9, 'October': 10, 'November': 11, 'December': 12,
    };
  }

  Map<String, int> _buildDayNameMap() {
    return {
      'Monday': 1, 'Tuesday': 2, 'Wednesday': 3, 'Thursday': 4,
      'Friday': 5, 'Saturday': 6, 'Sunday': 7,
    };
  }

  String _getFullMonthName(int month) {
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return month >= 1 && month <= 12 ? months[month] : '';
  }

  String _getMonthAbbr(int month) {
    const abbr = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return month >= 1 && month <= 12 ? abbr[month] : '';
  }

  String _getFullDayName(int dayOfWeek) {
    const days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return dayOfWeek >= 1 && dayOfWeek <= 7 ? days[dayOfWeek] : '';
  }

  String _getDayAbbr(int dayOfWeek) {
    const abbr = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return dayOfWeek >= 1 && dayOfWeek <= 7 ? abbr[dayOfWeek] : '';
  }

  int _parseMonthName(String name) => _buildMonthNameMap()[name] ?? 1;

  int _parseMonthAbbr(String abbr) {
    final map = _buildMonthNameMap();
    for (final entry in map.entries) {
      if (entry.key.startsWith(abbr)) return entry.value;
    }
    return 1;
  }

  String _getTimezoneName(LocalDateTime dateTime, ZonedDateTime? zoned) => zoned?.zone.id ?? (_zone?.id ?? 'UTC');

  String _getTimezoneAbbr(LocalDateTime dateTime, ZonedDateTime? zoned) {
    if (zoned != null) {
      // Return abbreviation based on zone
      final zoneId = zoned.zone.id;
      if (zoneId.contains('New_York') || zoneId == 'EST' || zoneId == 'EDT') {
        return zoned.isDaylightSaving ? 'EDT' : 'EST';
      } else if (zoneId.contains('Los_Angeles') || zoneId == 'PST' || zoneId == 'PDT') {
        return zoned.isDaylightSaving ? 'PDT' : 'PST';
      } else if (zoneId.contains('London') || zoneId == 'GMT' || zoneId == 'BST') {
        return zoned.isDaylightSaving ? 'BST' : 'GMT';
      }
      return zoneId;
    }
    return _zone?.id ?? 'UTC';
  }

  String _getTimezoneOffset(ZonedDateTime? zoned) {
    if (zoned == null) return '';
    final offset = zoned.offset;
    if (offset == Duration.zero) return 'Z';
    final hours = offset.inHours.abs();
    final minutes = (offset.inMinutes.abs() % 60);
    final sign = offset.isNegative ? '-' : '+';
    return '$sign${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  String _getIsoTimezoneOffset(ZonedDateTime? zoned) => _getTimezoneOffset(zoned);

  /// {@template format_date_time_method}
  /// Formats a standard Dart [DateTime] object according to the pattern.
  ///
  /// This method converts the Dart DateTime to a LocalDateTime and formats it.
  /// If the DateTime has timezone information, it will be used if the formatter
  /// includes timezone patterns.
  ///
  /// Example:
  /// ```dart
  /// final formatter = DateTimeFormatter.ofPattern('yyyy-MM-dd HH:mm:ss');
  /// final now = DateTime.now();
  /// print(formatter.formatDateTime(now)); // 2024-06-27 14:30:45
  /// 
  /// final formatterWithZone = DateTimeFormatter.ofPattern('yyyy-MM-dd HH:mm:ss Z');
  /// final utcNow = DateTime.now().toUtc();
  /// print(formatterWithZone.formatDateTime(utcNow)); // 2024-06-27 18:30:45 +0000
  /// ```
  /// {@endtemplate}
  String formatDateTime(DateTime dateTime) {
    final localDateTime = LocalDateTime.of(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
      dateTime.millisecond,
    );
    
    // Create a ZonedDateTime if we have timezone information and pattern includes timezone
    ZonedDateTime? zoned;
    if (_pattern.contains('Z') || _pattern.contains('z') || _pattern.contains('X')) {
      final zone = _zone ?? (dateTime.isUtc ? ZoneId.UTC : ZoneId.systemDefault());
      zoned = ZonedDateTime.of(localDateTime, zone);
    }
    
    return _format(localDateTime, zoned);
  }

  /// {@template format_zoned_date_time_method}
  /// Formats a [ZonedDateTime] object according to the pattern.
  ///
  /// This method includes timezone information in the output if the pattern
  /// contains timezone specifiers (Z, z, X).
  ///
  /// Example:
  /// ```dart
  /// final formatter = DateTimeFormatter.ofPattern('yyyy-MM-dd HH:mm:ss Z');
  /// final zoned = ZonedDateTime.now(ZoneId.of('America/New_York'));
  /// print(formatter.format(zoned)); // 2024-06-27 10:30:45 -0400
  /// 
  /// final formatterWithName = DateTimeFormatter.ofPattern('EEE, dd MMM yyyy HH:mm:ss zzz');
  /// print(formatterWithName.format(zoned)); // Thu, 27 Jun 2024 10:30:45 EDT
  /// ```
  /// {@endtemplate}
  String format(ZonedDateTime zonedDateTime) => _format(zonedDateTime.localDateTime, zonedDateTime);

  /// {@template format_local_date_time_method}
  /// Formats a [LocalDateTime] object according to the pattern.
  ///
  /// This is a convenience method that provides a more intuitive name
  /// for formatting LocalDateTime objects.
  ///
  /// Example:
  /// ```dart
  /// final formatter = DateTimeFormatter.ofPattern('EEEE, MMMM d, yyyy HH:mm:ss');
  /// final localDateTime = LocalDateTime.of(2024, 6, 27, 14, 30, 45);
  /// print(formatter.formatLocalDateTime(localDateTime)); // Thursday, June 27, 2024 14:30:45
  /// ```
  /// {@endtemplate}
  String formatLocalDateTime(LocalDateTime localDateTime) => _format(localDateTime, null);

  // Predefined formatters

  /// RFC 1123 formatter: "EEE, dd MMM yyyy HH:mm:ss zzz"
  /// 
  /// {@macro date_time_formatter}
  static DateTimeFormatter getRfc1123DateTime() {
    return DateTimeFormatter.ofPattern('EEE, dd MMM yyyy HH:mm:ss zzz', Locale('en', 'US'), ZoneId.GMT);
  }

  /// ISO 8601 formatter: "yyyy-MM-dd'T'HH:mm:ss"
  /// 
  /// {@macro date_time_formatter}
  static DateTimeFormatter getIso8601DateTime() => DateTimeFormatter.ofPattern('yyyy-MM-ddTHH:mm:ss', Locale('en', 'US'));

  /// ISO 8601 with timezone: "yyyy-MM-dd'T'HH:mm:ssZ"
  /// 
  /// {@macro date_time_formatter}
  static DateTimeFormatter getIso8601DateTimeWithZone() {
    return DateTimeFormatter.ofPattern('yyyy-MM-ddTHH:mm:ssZ', Locale('en', 'US'));
  }

  /// Date only: "yyyy-MM-dd"
  /// 
  /// {@macro date_time_formatter}
  static DateTimeFormatter getBasicIsoDate() => DateTimeFormatter.ofPattern('yyyy-MM-dd', Locale('en', 'US'));

  /// Time only: "HH:mm:ss"
  /// 
  /// {@macro date_time_formatter}
  static DateTimeFormatter getBasicIsoTime() => DateTimeFormatter.ofPattern('HH:mm:ss', Locale('en', 'US'));

  /// HTTP header date formatter
  /// 
  /// {@macro date_time_formatter}
  static DateTimeFormatter getHttpHeaderFormatter() {
    return DateTimeFormatter.ofPattern('EEE, dd MMM yyyy HH:mm:ss Z', Locale('en', 'US'), ZoneId.GMT);
  }

  @override
  String toString() => 'DateTimeFormatter(pattern=$_pattern, locale=${_locale.getLanguageTag()})';
}
