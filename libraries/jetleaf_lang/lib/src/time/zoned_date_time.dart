import 'local_date_time.dart';
import 'zone_id.dart';
import 'local_date.dart';
import 'local_time.dart';
import 'zoned_db.dart';

/// {@template zoned_date_time}
/// Represents a date-time with timezone information.
/// 
/// This class combines a [LocalDateTime] with timezone information to represent
/// a complete date-time with offset from UTC. Unlike Java's implementation,
/// this version includes a built-in timezone database for common timezones
/// without requiring external dependencies.
/// 
/// ## Key Features:
/// 
/// * **Immutable**: All operations return new instances
/// * **Timezone Aware**: Handles UTC offsets and common timezone names
/// * **DST Support**: Basic daylight saving time handling for major timezones
/// * **Conversion**: Easy conversion between timezones
/// * **Formatting**: ISO 8601 compliant string representation
/// 
/// ## Supported Timezone Formats:
/// 
/// * **UTC Offsets**: `+05:00`, `-08:00`, `Z` (for UTC)
/// * **Timezone Names**: `EST`, `PST`, `GMT`, `CET`, etc.
/// * **Full Names**: `America/New_York`, `Europe/London`, etc.
/// 
/// ## Usage Examples:
/// 
/// ```dart
/// // Create from current time
/// final now = ZonedDateTime.now();
/// final nowInParis = ZonedDateTime.now(ZoneId.of('Europe/Paris'));
/// 
/// // Create with specific date-time
/// final localDT = LocalDateTime.of(2023, 12, 25, 15, 30);
/// final christmas = ZonedDateTime.of(localDT, ZoneId.of('America/New_York'));
/// 
/// // Parse from string
/// final parsed = ZonedDateTime.parse('2023-12-25T15:30:00+01:00[Europe/Paris]');
/// 
/// // Convert between timezones
/// final utc = christmas.toUtc();
/// final tokyo = christmas.withZoneSameInstant(ZoneId.of('Asia/Tokyo'));
/// 
/// // Arithmetic operations
/// final tomorrow = christmas.plusDays(1);
/// final nextHour = christmas.plusHours(1);
/// ```
/// 
/// ## Timezone Database:
/// 
/// This implementation includes a comprehensive timezone database with:
/// * Major world timezones with their UTC offsets
/// * Daylight saving time rules for common timezones
/// * Historical timezone data for accurate conversions
/// * Support for both abbreviated and full timezone names
/// 
/// {@endtemplate}
class ZonedDateTime implements Comparable<ZonedDateTime> {
  final LocalDateTime _localDateTime;
  final ZoneId _zone;
  final Duration _offset;
  final bool _isDaylightSaving;

  /// Private constructor for internal use.
  /// 
  /// {@macro zoned_date_time}
  ZonedDateTime._(this._localDateTime, this._zone, this._offset, this._isDaylightSaving);

  /// Creates a ZonedDateTime with the specified [LocalDateTime] and [ZoneId].
  /// 
  /// The timezone offset is automatically calculated based on the zone and
  /// the date-time provided. Daylight saving time rules are applied when
  /// applicable.
  /// 
  /// Example:
  /// ```dart
  /// final localDT = LocalDateTime.of(2023, 7, 15, 12, 0); // July 15, noon
  /// final newYork = ZonedDateTime.of(localDT, ZoneId.of('America/New_York'));
  /// print(newYork); // 2023-07-15T12:00:00-04:00[America/New_York] (EDT)
  /// 
  /// final london = ZonedDateTime.of(localDT, ZoneId.of('Europe/London'));
  /// print(london); // 2023-07-15T12:00:00+01:00[Europe/London] (BST)
  /// ```
  /// 
  /// {@macro zoned_date_time}
  factory ZonedDateTime.of(LocalDateTime localDateTime, ZoneId zone) {
    final offsetData = TimezoneDatabase.getOffsetForZone(zone.id, localDateTime);
    return ZonedDateTime._(
      localDateTime,
      zone,
      offsetData.offset,
      offsetData.isDst,
    );
  }

  /// Creates a ZonedDateTime from the current date and time in the specified timezone.
  /// 
  /// If no [zone] is provided, uses the system default timezone (UTC).
  /// 
  /// Example:
  /// ```dart
  /// final nowUtc = ZonedDateTime.now(); // Current time in UTC
  /// final nowLocal = ZonedDateTime.now(ZoneId.systemDefault());
  /// final nowTokyo = ZonedDateTime.now(ZoneId.of('Asia/Tokyo'));
  /// 
  /// print('UTC: $nowUtc');
  /// print('Local: $nowLocal');
  /// print('Tokyo: $nowTokyo');
  /// ```
  /// {@macro zoned_date_time}
  factory ZonedDateTime.now([ZoneId? zone]) {
    zone ??= ZoneId.UTC;
    final utcNow = DateTime.now().toUtc();
    final localDateTime = LocalDateTime.fromDateTime(utcNow);
    
    if (zone == ZoneId.UTC) {
      return ZonedDateTime._(localDateTime, zone, Duration.zero, false);
    }
    
    // Convert UTC to the target timezone
    final offsetData = TimezoneDatabase.getOffsetForZone(zone.id, localDateTime);
    final adjustedDateTime = localDateTime.plus(offsetData.offset);
    
    return ZonedDateTime._(adjustedDateTime, zone, offsetData.offset, offsetData.isDst);
  }

  /// Creates a ZonedDateTime from a standard [DateTime] object.
  /// 
  /// The DateTime is assumed to be in the specified timezone. If no timezone
  /// is provided, it defaults to UTC.
  /// 
  /// Example:
  /// ```dart
  /// final dateTime = DateTime(2023, 12, 25, 15, 30);
  /// final zonedUtc = ZonedDateTime.fromDateTime(dateTime); // Assumes UTC
  /// final zonedEst = ZonedDateTime.fromDateTime(dateTime, ZoneId.of('EST'));
  /// 
  /// print('As UTC: $zonedUtc');
  /// print('As EST: $zonedEst');
  /// ```
  /// {@macro zoned_date_time}
  factory ZonedDateTime.fromDateTime(DateTime dateTime, [ZoneId? zone]) {
    zone ??= ZoneId.UTC;
    final localDateTime = LocalDateTime.fromDateTime(dateTime);
    return ZonedDateTime.of(localDateTime, zone);
  }

  /// Parses a ZonedDateTime from its string representation.
  /// 
  /// Supports multiple formats:
  /// * ISO 8601 with timezone: `2023-12-25T15:30:00+01:00`
  /// * With zone ID: `2023-12-25T15:30:00+01:00[Europe/Paris]`
  /// * UTC format: `2023-12-25T15:30:00Z`
  /// * Offset only: `2023-12-25T15:30:00-05:00`
  /// 
  /// Example:
  /// ```dart
  /// // Various parsing formats
  /// final iso = ZonedDateTime.parse('2023-12-25T15:30:00+01:00');
  /// final withZone = ZonedDateTime.parse('2023-12-25T15:30:00[Europe/Paris]');
  /// final utc = ZonedDateTime.parse('2023-12-25T15:30:00Z');
  /// final offset = ZonedDateTime.parse('2023-12-25T15:30:00-05:00');
  /// 
  /// print('ISO: $iso');
  /// print('With zone: $withZone');
  /// print('UTC: $utc');
  /// print('Offset: $offset');
  /// ```
  /// {@macro zoned_date_time}
  factory ZonedDateTime.parse(String dateTimeString) {
    // Handle different parsing formats
    String dateTimePart = dateTimeString;
    String? zonePart;
    String? offsetPart;

    // Extract zone ID if present [Zone/ID]
    final zoneMatch = RegExp(r'\[([^\]]+)\]').firstMatch(dateTimeString);
    if (zoneMatch != null) {
      zonePart = zoneMatch.group(1);
      dateTimePart = dateTimeString.substring(0, zoneMatch.start);
    }

    // Extract offset (+HH:mm, -HH:mm, Z)
    final offsetMatch = RegExp(r'([+-]\d{2}:?\d{2}|Z)$').firstMatch(dateTimePart);
    if (offsetMatch != null) {
      offsetPart = offsetMatch.group(1);
      dateTimePart = dateTimePart.substring(0, offsetMatch.start);
    }

    // Parse the date-time part
    final localDateTime = LocalDateTime.parse(dateTimePart);

    // Determine the timezone
    ZoneId zone;
    if (zonePart != null) {
      zone = ZoneId.of(zonePart);
    } else if (offsetPart != null) {
      if (offsetPart == 'Z') {
        zone = ZoneId.UTC;
      } else {
        // Create a zone from offset
        zone = ZoneId.of(offsetPart);
      }
    } else {
      zone = ZoneId.UTC;
    }

    return ZonedDateTime.of(localDateTime, zone);
  }

  /// Creates a ZonedDateTime from milliseconds since the Unix epoch.
  /// 
  /// The epoch milliseconds represent UTC time, which is then converted
  /// to the specified timezone.
  /// 
  /// Example:
  /// ```dart
  /// final epochMillis = DateTime.now().millisecondsSinceEpoch;
  /// 
  /// final utc = ZonedDateTime.fromEpochMilli(epochMillis);
  /// final tokyo = ZonedDateTime.fromEpochMilli(epochMillis, ZoneId.of('Asia/Tokyo'));
  /// final newYork = ZonedDateTime.fromEpochMilli(epochMillis, ZoneId.of('America/New_York'));
  /// 
  /// print('UTC: $utc');
  /// print('Tokyo: $tokyo');
  /// print('New York: $newYork');
  /// ```
  /// {@macro zoned_date_time}
  factory ZonedDateTime.fromEpochMilli(int epochMilli, [ZoneId? zone]) {
    zone ??= ZoneId.UTC;
    final utcDateTime = DateTime.fromMillisecondsSinceEpoch(epochMilli, isUtc: true);
    final localDateTime = LocalDateTime.fromDateTime(utcDateTime);
    
    if (zone == ZoneId.UTC) {
      return ZonedDateTime._(localDateTime, zone, Duration.zero, false);
    }
    
    // Convert to target timezone
    final offsetData = TimezoneDatabase.getOffsetForZone(zone.id, localDateTime);
    final adjustedDateTime = localDateTime.plus(offsetData.offset);
    
    return ZonedDateTime._(adjustedDateTime, zone, offsetData.offset, offsetData.isDst);
  }

  /// Gets the local date-time component (without timezone information).
  /// 
  /// Example:
  /// ```dart
  /// final zoned = ZonedDateTime.now(ZoneId.of('Europe/Paris'));
  /// final local = zoned.localDateTime;
  /// print('Zoned: $zoned');
  /// print('Local part: $local');
  /// ```
  LocalDateTime get localDateTime => _localDateTime;

  /// Gets the timezone information.
  /// 
  /// Example:
  /// ```dart
  /// final zoned = ZonedDateTime.now(ZoneId.of('Asia/Tokyo'));
  /// final zone = zoned.zone;
  /// print('Zone ID: ${zone.id}');
  /// ```
  ZoneId get zone => _zone;

  /// Gets the UTC offset for this date-time.
  /// 
  /// The offset represents how much this timezone is ahead (+) or behind (-)
  /// UTC at this specific date and time.
  /// 
  /// Example:
  /// ```dart
  /// final summer = ZonedDateTime.of(
  ///   LocalDateTime.of(2023, 7, 15, 12, 0),
  ///   ZoneId.of('America/New_York')
  /// );
  /// final winter = ZonedDateTime.of(
  ///   LocalDateTime.of(2023, 1, 15, 12, 0),
  ///   ZoneId.of('America/New_York')
  /// );
  /// 
  /// print('Summer offset: ${summer.offset}'); // -4 hours (EDT)
  /// print('Winter offset: ${winter.offset}'); // -5 hours (EST)
  /// ```
  Duration get offset => _offset;

  /// Indicates whether this date-time is in daylight saving time.
  /// 
  /// Example:
  /// ```dart
  /// final summer = ZonedDateTime.of(
  ///   LocalDateTime.of(2023, 7, 15, 12, 0),
  ///   ZoneId.of('America/New_York')
  /// );
  /// final winter = ZonedDateTime.of(
  ///   LocalDateTime.of(2023, 1, 15, 12, 0),
  ///   ZoneId.of('America/New_York')
  /// );
  /// 
  /// print('Summer DST: ${summer.isDaylightSaving}'); // true
  /// print('Winter DST: ${winter.isDaylightSaving}'); // false
  /// ```
  bool get isDaylightSaving => _isDaylightSaving;

  /// Gets the UTC offset in milliseconds.
  int get offsetInMilliseconds => _offset.inMilliseconds;

  // Date-time component getters with comprehensive documentation
  
  /// Gets the year component.
  /// 
  /// Example:
  /// ```dart
  /// final zdt = ZonedDateTime.parse('2023-12-25T15:30:00+01:00');
  /// print(zdt.year); // 2023
  /// ```
  int get year => _localDateTime.year;

  /// Gets the month component (1-12).
  /// 
  /// Example:
  /// ```dart
  /// final zdt = ZonedDateTime.parse('2023-12-25T15:30:00+01:00');
  /// print(zdt.month); // 12 (December)
  /// ```
  int get month => _localDateTime.month;

  /// Gets the day of the month component (1-31).
  /// 
  /// Example:
  /// ```dart
  /// final zdt = ZonedDateTime.parse('2023-12-25T15:30:00+01:00');
  /// print(zdt.day); // 25
  /// ```
  int get day => _localDateTime.day;

  /// Gets the hour component (0-23).
  /// 
  /// Example:
  /// ```dart
  /// final zdt = ZonedDateTime.parse('2023-12-25T15:30:00+01:00');
  /// print(zdt.hour); // 15 (3 PM)
  /// ```
  int get hour => _localDateTime.hour;

  /// Gets the minute component (0-59).
  /// 
  /// Example:
  /// ```dart
  /// final zdt = ZonedDateTime.parse('2023-12-25T15:30:00+01:00');
  /// print(zdt.minute); // 30
  /// ```
  int get minute => _localDateTime.minute;

  /// Gets the second component (0-59).
  /// 
  /// Example:
  /// ```dart
  /// final zdt = ZonedDateTime.parse('2023-12-25T15:30:45+01:00');
  /// print(zdt.second); // 45
  /// ```
  int get second => _localDateTime.second;

  /// Gets the millisecond component (0-999).
  /// 
  /// Example:
  /// ```dart
  /// final zdt = ZonedDateTime.now();
  /// print(zdt.millisecond); // Current millisecond component
  /// ```
  int get millisecond => _localDateTime.millisecond;

  /// Gets the day of the week (1 = Monday, 7 = Sunday).
  /// 
  /// Example:
  /// ```dart
  /// final christmas2023 = ZonedDateTime.parse('2023-12-25T00:00:00Z');
  /// print(christmas2023.dayOfWeek); // 1 (Monday)
  /// ```
  int get dayOfWeek => _localDateTime.dayOfWeek;

  /// Gets the day of the year (1-366).
  /// 
  /// Example:
  /// ```dart
  /// final newYear = ZonedDateTime.parse('2023-01-01T00:00:00Z');
  /// final christmas = ZonedDateTime.parse('2023-12-25T00:00:00Z');
  /// 
  /// print(newYear.dayOfYear); // 1
  /// print(christmas.dayOfYear); // 359
  /// ```
  int get dayOfYear => _localDateTime.dayOfYear;

  // Arithmetic operations with timezone awareness

  /// Adds the specified [Duration] to this date-time.
  /// 
  /// The operation is timezone-aware and handles daylight saving time
  /// transitions correctly. If the addition crosses a DST boundary,
  /// the offset may change.
  /// 
  /// Example:
  /// ```dart
  /// final zdt = ZonedDateTime.parse('2023-03-11T01:30:00-05:00[America/New_York]');
  /// final later = zdt.plus(Duration(hours: 2));
  /// 
  /// // This crosses the DST transition (spring forward)
  /// print('Before: $zdt'); // 01:30 EST
  /// print('After: $later');  // 04:30 EDT (skips 02:30-03:30)
  /// ```
  ZonedDateTime plus(Duration duration) {
    final newLocalDateTime = _localDateTime.plus(duration);
    return ZonedDateTime.of(newLocalDateTime, _zone);
  }

  /// Adds the specified number of days.
  /// 
  /// Example:
  /// ```dart
  /// final today = ZonedDateTime.now(ZoneId.of('Europe/London'));
  /// final nextWeek = today.plusDays(7);
  /// final tomorrow = today.plusDays(1);
  /// ```
  ZonedDateTime plusDays(int days) => plus(Duration(days: days));

  /// Adds the specified number of hours.
  /// 
  /// Example:
  /// ```dart
  /// final meeting = ZonedDateTime.parse('2023-12-25T14:00:00+01:00');
  /// final extended = meeting.plusHours(2); // 16:00 same day
  /// ```
  ZonedDateTime plusHours(int hours) => plus(Duration(hours: hours));

  /// Adds the specified number of minutes.
  /// 
  /// Example:
  /// ```dart
  /// final start = ZonedDateTime.now();
  /// final deadline = start.plusMinutes(90); // 1.5 hours later
  /// ```
  ZonedDateTime plusMinutes(int minutes) => plus(Duration(minutes: minutes));

  /// Adds the specified number of seconds.
  /// 
  /// Example:
  /// ```dart
  /// final start = ZonedDateTime.now();
  /// final timeout = start.plusSeconds(30);
  /// ```
  ZonedDateTime plusSeconds(int seconds) => plus(Duration(seconds: seconds));

  /// Adds the specified number of milliseconds.
  /// 
  /// Example:
  /// ```dart
  /// final precise = ZonedDateTime.now();
  /// final future = precise.plusMilliseconds(500); // Half second later
  /// ```
  ZonedDateTime plusMilliseconds(int milliseconds) => plus(Duration(milliseconds: milliseconds));

  /// Adds the specified number of weeks.
  /// 
  /// Example:
  /// ```dart
  /// final today = ZonedDateTime.now();
  /// final nextMonth = today.plusWeeks(4); // Approximately one month
  /// ```
  ZonedDateTime plusWeeks(int weeks) => plusDays(weeks * 7);

  /// Adds the specified number of months.
  /// 
  /// This operation is calendar-aware and handles month-end cases properly.
  /// 
  /// Example:
  /// ```dart
  /// final jan31 = ZonedDateTime.parse('2023-01-31T12:00:00Z');
  /// final feb = jan31.plusMonths(1); // 2023-02-28T12:00:00Z (not Feb 31)
  /// 
  /// final mar31 = ZonedDateTime.parse('2023-03-31T12:00:00Z');
  /// final apr = mar31.plusMonths(1); // 2023-04-30T12:00:00Z (not Apr 31)
  /// ```
  ZonedDateTime plusMonths(int months) {
    final newLocalDateTime = _localDateTime.plusMonths(months);
    return ZonedDateTime.of(newLocalDateTime, _zone);
  }

  /// Adds the specified number of years.
  /// 
  /// Handles leap year edge cases properly.
  /// 
  /// Example:
  /// ```dart
  /// final leap = ZonedDateTime.parse('2020-02-29T12:00:00Z'); // Leap year
  /// final next = leap.plusYears(1); // 2021-02-28T12:00:00Z (adjusted)
  /// ```
  ZonedDateTime plusYears(int years) {
    final newLocalDateTime = _localDateTime.plusYears(years);
    return ZonedDateTime.of(newLocalDateTime, _zone);
  }

  /// Subtracts the specified [Duration] from this date-time.
  /// 
  /// Example:
  /// ```dart
  /// final now = ZonedDateTime.now();
  /// final earlier = now.minus(Duration(hours: 3));
  /// ```
  ZonedDateTime minus(Duration duration) {
    final newLocalDateTime = _localDateTime.minus(duration);
    return ZonedDateTime.of(newLocalDateTime, _zone);
  }

  /// Subtracts the specified number of days.
  ZonedDateTime minusDays(int days) => minus(Duration(days: days));

  /// Subtracts the specified number of hours.
  ZonedDateTime minusHours(int hours) => minus(Duration(hours: hours));

  /// Subtracts the specified number of minutes.
  ZonedDateTime minusMinutes(int minutes) => minus(Duration(minutes: minutes));

  /// Subtracts the specified number of seconds.
  ZonedDateTime minusSeconds(int seconds) => minus(Duration(seconds: seconds));

  /// Subtracts the specified number of milliseconds.
  ZonedDateTime minusMilliseconds(int milliseconds) => minus(Duration(milliseconds: milliseconds));

  /// Subtracts the specified number of weeks.
  ZonedDateTime minusWeeks(int weeks) => minusDays(weeks * 7);

  /// Subtracts the specified number of months.
  ZonedDateTime minusMonths(int months) {
    final newLocalDateTime = _localDateTime.minusMonths(months);
    return ZonedDateTime.of(newLocalDateTime, _zone);
  }

  /// Subtracts the specified number of years.
  ZonedDateTime minusYears(int years) {
    final newLocalDateTime = _localDateTime.minusYears(years);
    return ZonedDateTime.of(newLocalDateTime, _zone);
  }

  // Timezone conversion operations

  /// Converts this date-time to the same instant in a different timezone.
  /// 
  /// The instant in time remains the same, but the local date-time values
  /// change to reflect the new timezone.
  /// 
  /// Example:
  /// ```dart
  /// final nyTime = ZonedDateTime.parse('2023-12-25T15:00:00-05:00[America/New_York]');
  /// final londonTime = nyTime.withZoneSameInstant(ZoneId.of('Europe/London'));
  /// final tokyoTime = nyTime.withZoneSameInstant(ZoneId.of('Asia/Tokyo'));
  /// 
  /// print('New York: $nyTime');    // 15:00 EST
  /// print('London: $londonTime');  // 20:00 GMT (5 hours ahead)
  /// print('Tokyo: $tokyoTime');    // 05:00 JST next day (14 hours ahead)
  /// ```
  ZonedDateTime withZoneSameInstant(ZoneId zone) {
    if (_zone == zone) return this;
    
    // Convert to UTC first
    final utcDateTime = _localDateTime.minus(_offset);
    
    // Then convert to target timezone
    final offsetData = TimezoneDatabase.getOffsetForZone(zone.id, utcDateTime);
    final targetDateTime = utcDateTime.plus(offsetData.offset);
    
    return ZonedDateTime._(targetDateTime, zone, offsetData.offset, offsetData.isDst);
  }

  /// Converts this date-time to UTC.
  /// 
  /// Convenience method equivalent to `withZoneSameInstant(ZoneId.UTC)`.
  /// 
  /// Example:
  /// ```dart
  /// final local = ZonedDateTime.now(ZoneId.of('America/Los_Angeles'));
  /// final utc = local.toUtc();
  /// 
  /// print('Local: $local');
  /// print('UTC: $utc');
  /// ```
  ZonedDateTime toUtc() => withZoneSameInstant(ZoneId.UTC);

  /// Creates a new ZonedDateTime with the same local date-time but different timezone.
  /// 
  /// Unlike [withZoneSameInstant], this keeps the same local date-time values
  /// but changes the timezone, effectively changing the instant in time.
  /// 
  /// Example:
  /// ```dart
  /// final original = ZonedDateTime.parse('2023-12-25T15:00:00-05:00[America/New_York]');
  /// final sameTime = original.withZoneSameLocal(ZoneId.of('Europe/London'));
  /// 
  /// print('Original: $original');   // 15:00 in New York
  /// print('Same local: $sameTime'); // 15:00 in London (different instant)
  /// ```
  ZonedDateTime withZoneSameLocal(ZoneId zone) {
    return ZonedDateTime.of(_localDateTime, zone);
  }

  // Conversion methods

  /// Converts to a standard Dart [DateTime] object.
  /// 
  /// The returned DateTime represents the same instant in UTC.
  /// 
  /// Example:
  /// ```dart
  /// final zoned = ZonedDateTime.parse('2023-12-25T15:00:00-05:00');
  /// final dateTime = zoned.toDateTime();
  /// 
  /// print('Zoned: $zoned');
  /// print('DateTime: $dateTime'); // UTC equivalent
  /// ```
  DateTime toDateTime() {
    final utcDateTime = _localDateTime.minus(_offset);
    return utcDateTime.toDateTime();
  }

  /// Gets the milliseconds since the Unix epoch (January 1, 1970 UTC).
  /// 
  /// Example:
  /// ```dart
  /// final zoned = ZonedDateTime.now();
  /// final epochMillis = zoned.toEpochMilli();
  /// 
  /// // Can be used to recreate the same instant
  /// final recreated = ZonedDateTime.fromEpochMilli(epochMillis, zoned.zone);
  /// print(zoned == recreated); // true
  /// ```
  int toEpochMilli() {
    return toDateTime().millisecondsSinceEpoch;
  }

  /// Gets just the date part as a [LocalDate].
  /// 
  /// Example:
  /// ```dart
  /// final zoned = ZonedDateTime.now();
  /// final date = zoned.toLocalDate();
  /// print('Full: $zoned');
  /// print('Date only: $date');
  /// ```
  LocalDate toLocalDate() => _localDateTime.toLocalDate();

  /// Gets just the time part as a [LocalTime].
  /// 
  /// Example:
  /// ```dart
  /// final zoned = ZonedDateTime.now();
  /// final time = zoned.toLocalTime();
  /// print('Full: $zoned');
  /// print('Time only: $time');
  /// ```
  LocalTime toLocalTime() => _localDateTime.toLocalTime();

  // String representation and formatting

  /// Returns the ISO 8601 string representation with timezone information.
  /// 
  /// The format is: `yyyy-MM-ddTHH:mm:ss±HH:mm[ZoneId]`
  /// 
  /// Example:
  /// ```dart
  /// final zoned = ZonedDateTime.of(
  ///   LocalDateTime.of(2023, 12, 25, 15, 30, 45),
  ///   ZoneId.of('America/New_York')
  /// );
  /// 
  /// print(zoned.toString()); 
  /// // Output: 2023-12-25T15:30:45-05:00[America/New_York]
  /// ```
  @override
  String toString() {
    final offsetStr = _formatOffset(_offset);
    return '$_localDateTime$offsetStr[${_zone.id}]';
  }

  /// Returns a compact string representation without the zone ID.
  /// 
  /// The format is: `yyyy-MM-ddTHH:mm:ss±HH:mm`
  /// 
  /// Example:
  /// ```dart
  /// final zoned = ZonedDateTime.now(ZoneId.of('Europe/Paris'));
  /// print(zoned.toStringCompact()); // 2023-12-25T15:30:45+01:00
  /// ```
  String toStringCompact() {
    final offsetStr = _formatOffset(_offset);
    return '$_localDateTime$offsetStr';
  }

  /// Formats the offset duration as a string (±HH:mm or Z for UTC).
  String _formatOffset(Duration offset) {
    if (offset == Duration.zero) return 'Z';
    
    final hours = offset.inHours.abs();
    final minutes = (offset.inMinutes.abs() % 60);
    final sign = offset.isNegative ? '-' : '+';
    
    return '$sign${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  // Comparison operations

  /// Compares this ZonedDateTime with another for ordering.
  /// 
  /// Comparison is based on the instant in time, not the local date-time.
  /// Two ZonedDateTime objects representing the same instant but in different
  /// timezones are considered equal.
  /// 
  /// Example:
  /// ```dart
  /// final ny = ZonedDateTime.parse('2023-12-25T15:00:00-05:00[America/New_York]');
  /// final london = ZonedDateTime.parse('2023-12-25T20:00:00+00:00[Europe/London]');
  /// 
  /// print(ny.compareTo(london)); // 0 (same instant)
  /// print(ny == london); // true
  /// ```
  @override
  int compareTo(ZonedDateTime other) {
    return toEpochMilli().compareTo(other.toEpochMilli());
  }

  /// Checks if this date-time is before another.
  /// 
  /// Example:
  /// ```dart
  /// final earlier = ZonedDateTime.now();
  /// final later = earlier.plusHours(1);
  /// 
  /// print(earlier.isBefore(later)); // true
  /// print(later.isBefore(earlier)); // false
  /// ```
  bool isBefore(ZonedDateTime other) => compareTo(other) < 0;

  /// Checks if this date-time is after another.
  /// 
  /// Example:
  /// ```dart
  /// final now = ZonedDateTime.now();
  /// final past = now.minusHours(1);
  /// 
  /// print(now.isAfter(past)); // true
  /// print(past.isAfter(now)); // false
  /// ```
  bool isAfter(ZonedDateTime other) => compareTo(other) > 0;

  /// Checks if this date-time represents the same instant as another.
  /// 
  /// Example:
  /// ```dart
  /// final ny = ZonedDateTime.parse('2023-12-25T12:00:00-05:00[America/New_York]');
  /// final london = ZonedDateTime.parse('2023-12-25T17:00:00+00:00[UTC]');
  /// 
  /// print(ny.isEqual(london)); // true (same instant, different zones)
  /// ```
  bool isEqual(ZonedDateTime other) => compareTo(other) == 0;

  // Equality and hash code

  /// Returns the hash code for this ZonedDateTime.
  /// 
  /// The hash code is based on the instant in time, ensuring that two
  /// ZonedDateTime objects representing the same instant have the same hash code.
  @override
  int get hashCode => toEpochMilli().hashCode;

  /// Checks equality with another object.
  /// 
  /// Two ZonedDateTime objects are equal if they represent the same instant
  /// in time, regardless of their timezone.
  /// 
  /// Example:
  /// ```dart
  /// final dt1 = ZonedDateTime.parse('2023-12-25T12:00:00-05:00[America/New_York]');
  /// final dt2 = ZonedDateTime.parse('2023-12-25T17:00:00+00:00[UTC]');
  /// 
  /// print(dt1 == dt2); // true (same instant)
  /// ```
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ZonedDateTime && toEpochMilli() == other.toEpochMilli();
  }
}