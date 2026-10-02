import 'package:jetleaf_convert/convert.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

@JetleafTest()
void main() {
  final service = DefaultConversionService();

  group('DateTime Converters', () {
    test('DateTime to String conversion', () {
      final now = DateTime(2025, 8, 15, 10, 30, 45);
      final result = service.convert<String>(now, Class<String>());
      expect(result, contains('2025'));
      expect(result, contains('08'));
      expect(result, contains('15'));
      expect(result, contains('10:30:45'));
    });

    test('String to DateTime conversion', () {
      final isoString = '2025-01-01T10:30:00.000Z';
      final result = service.convert<DateTime>(isoString, Class<DateTime>());
      expect(result?.year, 2025);
      expect(result?.month, 1);
      expect(result?.day, 1);
      expect(result?.hour, 10);
      expect(result?.minute, 30);
    });

    test('String to DateTime conversion throws on invalid input', () {
      expect(() => service.convert<DateTime>('invalid-date', Class<DateTime>()), 
          throwsA(isA<ConversionFailedException>()));
    });

    test('DateTime to epoch milliseconds', () {
      final dateTime = DateTime.utc(2025, 1, 1, 10, 30, 45);
      final epochMs = service.convert<int>(dateTime, Class<int>());
      expect(epochMs, dateTime.millisecondsSinceEpoch);
    });

    test('Epoch milliseconds to DateTime', () {
      final epochMs = DateTime.utc(2025, 1, 1, 10, 30, 45).millisecondsSinceEpoch;
      final result = service.convert<DateTime>(epochMs, Class<DateTime>());
      expect(result?.year, 2025);
      expect(result?.month, 1);
      expect(result?.day, 1);
      expect(result?.hour, 11);
      expect(result?.minute, 30);
      expect(result?.second, 45);
    });
  });

  group('LocalDateTime Converters', () {
    test('LocalDateTime to String conversion', () {
      final localDateTime = LocalDateTime(LocalDate(2025, 8, 15), LocalTime(10, 30, 45));
      final result = service.convert<String>(localDateTime, Class<String>());
      expect(result, contains('2025-08-15'));
      expect(result, contains('10:30:45'));
    });

    test('String to LocalDateTime conversion', () {
      final result = service.convert<LocalDateTime>('2025-08-15T10:30:45', Class<LocalDateTime>());
      expect(result?.year, 2025);
      expect(result?.month, 8);
      expect(result?.day, 15);
      expect(result?.hour, 10);
      expect(result?.minute, 30);
      expect(result?.second, 45);
    });
  });

  group('LocalDate Converters', () {
    test('LocalDate to String conversion', () {
      final localDate = LocalDate(2025, 8, 15);
      final result = service.convert<String>(localDate, Class<String>());
      expect(result, '2025-08-15');
    });

    test('String to LocalDate conversion', () {
      final result = service.convert<LocalDate>('2025-08-15', Class<LocalDate>());
      expect(result?.year, 2025);
      expect(result?.month, 8);
      expect(result?.day, 15);
    });
  });

  group('LocalTime Converters', () {
    test('LocalTime to String conversion', () {
      final localTime = LocalTime(10, 30, 45, 123);
      final result = service.convert<String>(localTime, Class<String>());
      expect(result, contains('10:30:45.123'));
    });

    test('String to LocalTime conversion', () {
      final result = service.convert<LocalTime>('10:30:45.123', Class<LocalTime>());
      expect(result?.hour, 10);
      expect(result?.minute, 30);
      expect(result?.second, 45);
      expect(result?.millisecond, 123);
    });
  });

  group('ZoneId Converters', () {
    test('ZoneId to String conversion', () {
      final zoneId = ZoneId.of('America/New_York');
      final result = service.convert<String>(zoneId, Class<String>());
      expect(result, 'America/New_York');
    });

    test('String to ZoneId conversion', () {
      final result = service.convert<ZoneId>('America/New_York', Class<ZoneId>());
      expect(result?.id, 'America/New_York');
    });
  });

  group('ZonedDateTime Converters', () {
    test('ZonedDateTime to String conversion', () {
      final zonedDateTime = ZonedDateTime.of(
        LocalDateTime(LocalDate(2025, 8, 15), LocalTime(10, 30, 45)),
        ZoneId.of('America/New_York')
      );
      final result = service.convert<String>(zonedDateTime, Class<String>());
      expect(result, contains('2025-08-15'));
      expect(result, contains('10:30:45'));
      expect(result, contains('America/New_York'));
    });

    test('String to ZonedDateTime conversion', () {
      final result = service.convert<ZonedDateTime>(
        '2025-08-15T10:30:45-04:00[America/New_York]', 
        Class<ZonedDateTime>()
      );
      expect(result?.year, 2025);
      expect(result?.month, 8);
      expect(result?.day, 15);
      expect(result?.hour, 10);
      expect(result?.minute, 30);
      expect(result?.second, 45);
      expect(result?.zone.id, 'America/New_York');
    });
  });

  group('Duration Converters', () {
    test('Duration to String conversion', () {
      final duration = Duration(hours: 1, minutes: 30, seconds: 15, milliseconds: 500);
      final result = service.convert<String>(duration, Class<String>());
      expect(result, isNotEmpty);
      expect(result, contains('1:30:15.500'));
    });

    test('String to Duration conversion', () {
      final result = service.convert<Duration>('1:30:15.500', Class<Duration>());
      expect(result, Duration(hours: 1, minutes: 30, seconds: 15, milliseconds: 500));
    });

    test('String to Duration conversion throws on invalid input', () {
      expect(() => service.convert<Duration>('invalid-duration', Class<Duration>()), 
          throwsA(isA<ConversionFailedException>()));
    });

    test('Duration to milliseconds conversion', () {
      final duration = Duration(seconds: 5, milliseconds: 250);
      final result = service.convert<int>(duration, Class<int>());
      expect(result, 5250);
    });

    test('Milliseconds to Duration conversion', () {
      final result = service.convert<Duration>(5250, Class<Duration>());
      expect(result, Duration(seconds: 5, milliseconds: 250));
    });
  });

  group('Cross-type Conversions', () {
    test('DateTime to LocalDateTime conversion', () {
      final dateTime = DateTime(2025, 8, 15, 10, 30, 45, 123);
      final result = service.convert<LocalDateTime>(dateTime, Class<LocalDateTime>());
      expect(result?.year, 2025);
      expect(result?.month, 8);
      expect(result?.day, 15);
      expect(result?.hour, 10);
      expect(result?.minute, 30);
      expect(result?.second, 45);
      expect(result?.millisecond, 123);
    });

    test('LocalDateTime to DateTime conversion', () {
      final localDateTime = LocalDateTime(LocalDate(2025, 8, 15), LocalTime(10, 30, 45, 123));
      final result = service.convert<DateTime>(localDateTime, Class<DateTime>());
      expect(result?.year, 2025);
      expect(result?.month, 8);
      expect(result?.day, 15);
      expect(result?.hour, 10);
      expect(result?.minute, 30);
      expect(result?.second, 45);
      expect(result?.millisecond, 123);
    });

    test('DateTime to LocalDate conversion', () {
      final dateTime = DateTime(2025, 8, 15, 10, 30, 45);
      final result = service.convert<LocalDate>(dateTime, Class<LocalDate>());
      expect(result?.year, 2025);
      expect(result?.month, 8);
      expect(result?.day, 15);
    });

    test('LocalDate to DateTime conversion', () {
      final localDate = LocalDate(2025, 8, 15);
      final result = service.convert<DateTime>(localDate, Class<DateTime>());
      expect(result?.year, 2025);
      expect(result?.month, 8);
      expect(result?.day, 15);
      expect(result?.hour, 0);
      expect(result?.minute, 0);
      expect(result?.second, 0);
    });

    test('DateTime to LocalTime conversion', () {
      final dateTime = DateTime(2025, 8, 15, 10, 30, 45, 123);
      final result = service.convert<LocalTime>(dateTime, Class<LocalTime>());
      expect(result?.hour, 10);
      expect(result?.minute, 30);
      expect(result?.second, 45);
      expect(result?.millisecond, 123);
    });

    test('DateTime to ZonedDateTime conversion', () {
      final dateTime = DateTime(2025, 8, 15, 10, 30, 45);
      final result = service.convert<ZonedDateTime>(dateTime, Class<ZonedDateTime>());
      expect(result?.year, 2025);
      expect(result?.month, 8);
      expect(result?.day, 15);
      expect(result?.hour, 10);
      expect(result?.minute, 30);
      expect(result?.second, 45);
      expect(result?.zone, isNotNull);
    });

    test('ZonedDateTime to LocalDateTime conversion', () {
      final zonedDateTime = ZonedDateTime.of(
        LocalDateTime(LocalDate(2025, 8, 15), LocalTime(10, 30, 45)),
        ZoneId.of('America/New_York')
      );
      final result = service.convert<LocalDateTime>(zonedDateTime, Class<LocalDateTime>());
      expect(result?.year, 2025);
      expect(result?.month, 8);
      expect(result?.day, 15);
      expect(result?.hour, 10);
      expect(result?.minute, 30);
      expect(result?.second, 45);
    });

    test('ZonedDateTime to LocalDate conversion', () {
      final zonedDateTime = ZonedDateTime.of(
        LocalDateTime(LocalDate(2025, 8, 15), LocalTime(10, 30, 45)),
        ZoneId.of('America/New_York')
      );
      final result = service.convert<LocalDate>(zonedDateTime, Class<LocalDate>());
      expect(result?.year, 2025);
      expect(result?.month, 8);
      expect(result?.day, 15);
    });

    test('ZonedDateTime to LocalTime conversion', () {
      final zonedDateTime = ZonedDateTime.of(
        LocalDateTime(LocalDate(2025, 8, 15), LocalTime(10, 30, 45)),
        ZoneId.of('America/New_York')
      );
      final result = service.convert<LocalTime>(zonedDateTime, Class<LocalTime>());
      expect(result?.hour, 10);
      expect(result?.minute, 30);
      expect(result?.second, 45);
    });

    test('ZonedDateTime to ZoneId conversion', () {
      final zonedDateTime = ZonedDateTime.of(
        LocalDateTime(LocalDate(2025, 8, 15), LocalTime(10, 30, 45)),
        ZoneId.of('America/New_York')
      );
      final result = service.convert<ZoneId>(zonedDateTime, Class<ZoneId>());
      expect(result?.id, 'America/New_York');
    });
  });

  group('Edge Cases', () {
    test('Null input returns null', () {
      final result = service.convert<String>(null, Class<String>());
      expect(result, isNull);
    });

    test('Empty string to DateTime throws', () {
      expect(() => service.convert<DateTime>('', Class<DateTime>()), 
          throwsA(isA<ConversionFailedException>()));
    });

    test('Very large duration conversion', () {
      final duration = Duration(days: 365);
      final result = service.convert<int>(duration, Class<int>());
      expect(result, 365 * 24 * 60 * 60 * 1000);
    });

    test('Very old DateTime conversion', () {
      final oldDate = DateTime(1970, 1, 1);
      final result = service.convert<String>(oldDate, Class<String>());
      expect(result, contains('1970'));
    });

    test('Leap year date conversion', () {
      final leapDate = LocalDate(2024, 2, 29); // 2024 is a leap year
      final result = service.convert<String>(leapDate, Class<String>());
      expect(result, '2024-02-29');
    });
  });
}