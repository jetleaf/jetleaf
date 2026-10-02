import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../dependencies/exceptions.dart';

void main() {
  group('ZonedDateTime', () {
    group('Creation and Parsing', () {
      test('should create ZonedDateTime with LocalDateTime and ZoneId', () {
        final localDT = LocalDateTime.of(2023, 12, 25, 15, 30, 0);
        final zoned = ZonedDateTime.of(localDT, ZoneId.of('America/New_York'));
        
        expect(zoned.year, equals(2023));
        expect(zoned.month, equals(12));
        expect(zoned.day, equals(25));
        expect(zoned.hour, equals(15));
        expect(zoned.minute, equals(30));
        expect(zoned.zone.id, equals('America/New_York'));
      });

      test('should create ZonedDateTime from current time', () {
        final nowUtc = ZonedDateTime.now();
        final nowNy = ZonedDateTime.now(ZoneId.of('America/New_York'));
        
        expect(nowUtc.zone, equals(ZoneId.UTC));
        expect(nowNy.zone.id, equals('America/New_York'));
        
        // Should be within reasonable time of each other
        final diff = (nowUtc.toEpochMilli() - nowNy.toEpochMilli()).abs();
        expect(diff, lessThan(1000)); // Within 1 second
      });

      test('should create ZonedDateTime from DateTime', () {
        final dateTime = DateTime(2023, 6, 15, 12, 30, 45);
        final zoned = ZonedDateTime.fromDateTime(dateTime, ZoneId.of('Europe/London'));
        
        expect(zoned.year, equals(2023));
        expect(zoned.month, equals(6));
        expect(zoned.day, equals(15));
        expect(zoned.hour, equals(12));
        expect(zoned.minute, equals(30));
        expect(zoned.second, equals(45));
        expect(zoned.zone.id, equals('Europe/London'));
      });

      test('should parse ZonedDateTime from various string formats', () {
        // ISO format with offset
        final iso = ZonedDateTime.parse('2023-12-25T15:30:00+01:00');
        expect(iso.year, equals(2023));
        expect(iso.hour, equals(15));
        expect(iso.offset, equals(Duration(hours: 1)));

        // With zone ID
        final withZone = ZonedDateTime.parse('2023-12-25T15:30:00+01:00[Europe/Paris]');
        expect(withZone.zone.id, equals('Europe/Paris'));

        // UTC format
        final utc = ZonedDateTime.parse('2023-12-25T15:30:00Z');
        expect(utc.zone, equals(ZoneId.UTC));
        expect(utc.offset, equals(Duration.zero));

        // Negative offset
        final negative = ZonedDateTime.parse('2023-12-25T15:30:00-05:00');
        expect(negative.offset, equals(Duration(hours: -5)));
      });

      test('should create ZonedDateTime from epoch milliseconds', () {
        final epochMillis = DateTime(2023, 12, 25, 20, 0).millisecondsSinceEpoch;
        
        final utc = ZonedDateTime.fromEpochMilli(epochMillis);
        final tokyo = ZonedDateTime.fromEpochMilli(epochMillis, ZoneId.of('Asia/Tokyo'));
        
        expect(utc.zone, equals(ZoneId.UTC));
        expect(tokyo.zone.id, equals('Asia/Tokyo'));
        
        // Should represent the same instant
        expect(utc.toEpochMilli(), equals(tokyo.toEpochMilli()));
      });
    });

    group('Timezone Handling', () {
      test('should handle major timezone offsets correctly', () {
        final localDT = LocalDateTime.of(2023, 7, 15, 12, 0); // Summer time
        
        final ny = ZonedDateTime.of(localDT, ZoneId.of('America/New_York'));
        final london = ZonedDateTime.of(localDT, ZoneId.of('Europe/London'));
        final tokyo = ZonedDateTime.of(localDT, ZoneId.of('Asia/Tokyo'));
        
        // Summer offsets (with DST where applicable)
        expect(ny.offset, equals(Duration(hours: -4))); // EDT
        expect(london.offset, equals(Duration(hours: 1))); // BST
        expect(tokyo.offset, equals(Duration(hours: 9))); // JST (no DST)
      });

      test('should handle daylight saving time transitions', () {
        // Summer time (DST active)
        final summer = ZonedDateTime.of(
          LocalDateTime.of(2023, 7, 15, 12, 0),
          ZoneId.of('America/New_York')
        );
        
        // Winter time (standard time)
        final winter = ZonedDateTime.of(
          LocalDateTime.of(2023, 1, 15, 12, 0),
          ZoneId.of('America/New_York')
        );
        
        expect(summer.offset, equals(Duration(hours: -4))); // EDT
        expect(winter.offset, equals(Duration(hours: -5))); // EST
        expect(summer.isDaylightSaving, isTrue);
        expect(winter.isDaylightSaving, isFalse);
      });

      test('should handle special timezone offsets', () {
        final localDT = LocalDateTime.of(2023, 7, 15, 12, 0);
        
        final india = ZonedDateTime.of(localDT, ZoneId.of('Asia/Kolkata'));
        expect(india.offset, equals(Duration(hours: 5, minutes: 30))); // +05:30
        
        final adelaide = ZonedDateTime.of(localDT, ZoneId.of('Australia/Adelaide'));
        expect(adelaide.offset, equals(Duration(hours: 9, minutes: 30))); // +9:30 ACDT
      });

      test('should handle direct offset zone IDs', () {
        final localDT = LocalDateTime.of(2023, 12, 25, 15, 30);
        
        final plus5 = ZonedDateTime.of(localDT, ZoneId.of('+05:00'));
        final minus8 = ZonedDateTime.of(localDT, ZoneId.of('-08:00'));
        
        expect(plus5.offset, equals(Duration(hours: 5)));
        expect(minus8.offset, equals(Duration(hours: -8)));
      });
    });

    group('ZoneId Integration', () {
      test('should work with all predefined ZoneId constants', () {
        final localDT = LocalDateTime.of(2023, 7, 15, 12, 0);
        
        // Test major timezone constants
        final newYork = ZonedDateTime.of(localDT, ZoneId.AMERICA_NEW_YORK);
        final london = ZonedDateTime.of(localDT, ZoneId.EUROPE_LONDON);
        final tokyo = ZonedDateTime.of(localDT, ZoneId.ASIA_TOKYO);
        final sydney = ZonedDateTime.of(localDT, ZoneId.AUSTRALIA_SYDNEY);
        
        expect(newYork.zone, equals(ZoneId.AMERICA_NEW_YORK));
        expect(london.zone, equals(ZoneId.EUROPE_LONDON));
        expect(tokyo.zone, equals(ZoneId.ASIA_TOKYO));
        expect(sydney.zone, equals(ZoneId.AUSTRALIA_SYDNEY));
        
        // Verify offsets are correct for summer time
        expect(newYork.offset, equals(Duration(hours: -4))); // EDT
        expect(london.offset, equals(Duration(hours: 1)));   // BST
        expect(tokyo.offset, equals(Duration(hours: 9)));    // JST
        expect(sydney.offset, equals(Duration(hours: 10)));  // AEDT
      });

      test('should handle all available zone IDs', () {
        final availableZones = ZoneId.getAvailableZoneIds();
        final localDT = LocalDateTime.of(2023, 6, 15, 12, 0);
        
        expect(availableZones.length, greaterThan(80)); // Should have many zones
        
        // Test that all available zones can create valid ZonedDateTime instances
        for (final zoneIdString in availableZones.take(10)) { // Test first 10 for performance
          final zoneId = ZoneId.of(zoneIdString);
          final zoned = ZonedDateTime.of(localDT, zoneId);
          
          expect(zoned.zone.id, equals(zoneIdString));
          expect(zoned.localDateTime, equals(localDT));
        }
      });

      test('should handle special offset timezones correctly', () {
        final localDT = LocalDateTime.of(2023, 7, 15, 12, 0);
        
        // Test India Standard Time (+05:30)
        final india = ZonedDateTime.of(localDT, ZoneId.ASIA_KOLKATA);
        expect(india.offset, equals(Duration(hours: 5, minutes: 30)));
        
        // Test Iran Standard Time (+03:30 standard, +04:30 DST)
        final iran = ZonedDateTime.of(localDT, ZoneId.ASIA_TEHRAN);
        expect(iran.offset, equals(Duration(hours: 3, minutes: 30))); // Summer time
        
        // Test Australia Adelaide (+09:30 standard, +10:30 DST)
        final adelaide = ZonedDateTime.of(localDT, ZoneId.AUSTRALIA_ADELAIDE);
        expect(adelaide.offset, equals(Duration(hours: 9, minutes: 30))); // Summer time
        
        // Test Nepal Time (+05:45)
        final nepal = ZonedDateTime.of(localDT, ZoneId.ASIA_KATHMANDU);
        expect(nepal.offset, equals(Duration(hours: 5, minutes: 45)));
      });

      test('should handle timezone constants equality correctly', () {
        final utc1 = ZoneId.UTC;
        final utc2 = ZoneId.of('UTC');
        final gmt = ZoneId.GMT;
        
        expect(utc1, equals(utc2));
        expect(utc1.id, equals(utc2.id));
        expect(utc1.normalized(), equals(gmt.normalized()));
        
        final ny1 = ZoneId.AMERICA_NEW_YORK;
        final ny2 = ZoneId.of('America/New_York');
        
        expect(ny1, equals(ny2));
        expect(ny1.hashCode, equals(ny2.hashCode));
      });

      test('should provide comprehensive timezone coverage', () {
        final availableZones = ZoneId.getAvailableZoneIds();
        
        // Check that major continents are represented
        final americaZones = availableZones.where((z) => z.startsWith('America/')).length;
        final europeZones = availableZones.where((z) => z.startsWith('Europe/')).length;
        final asiaZones = availableZones.where((z) => z.startsWith('Asia/')).length;
        final africaZones = availableZones.where((z) => z.startsWith('Africa/')).length;
        final australiaZones = availableZones.where((z) => z.startsWith('Australia/')).length;
        final pacificZones = availableZones.where((z) => z.startsWith('Pacific/')).length;
        
        expect(americaZones, greaterThan(10));
        expect(europeZones, greaterThan(10));
        expect(asiaZones, greaterThan(10));
        expect(africaZones, greaterThan(5));
        expect(australiaZones, greaterThan(3));
        expect(pacificZones, greaterThan(3));
        
        // Check that abbreviated forms are included
        expect(availableZones, contains('EST'));
        expect(availableZones, contains('PST'));
        expect(availableZones, contains('CET'));
        expect(availableZones, contains('GMT'));
        expect(availableZones, contains('UTC'));
      });

      test('should handle timezone database consistency', () {
        final localDT = LocalDateTime.of(2023, 1, 15, 12, 0); // Winter
        
        // Test that EST abbreviation and America/New_York give consistent results in winter
        final est = ZonedDateTime.of(localDT, ZoneId.EST);
        final nyWinter = ZonedDateTime.of(localDT, ZoneId.AMERICA_NEW_YORK);
        
        expect(est.offset, equals(Duration(hours: -5)));
        expect(nyWinter.offset, equals(Duration(hours: -5))); // EST in winter
        expect(nyWinter.isDaylightSaving, isFalse);
        
        // Test summer time
        final summerDT = LocalDateTime.of(2023, 7, 15, 12, 0);
        final nySummer = ZonedDateTime.of(summerDT, ZoneId.AMERICA_NEW_YORK);
        
        expect(nySummer.offset, equals(Duration(hours: -4))); // EDT in summer
        expect(nySummer.isDaylightSaving, isTrue);
      });
    });

    group('Timezone Conversion', () {
      test('should convert between timezones preserving instant', () {
        final original = ZonedDateTime.parse('2023-12-25T15:00:00-05:00[America/New_York]');
        
        final london = original.withZoneSameInstant(ZoneId.of('Europe/London'));
        final tokyo = original.withZoneSameInstant(ZoneId.of('Asia/Tokyo'));
        
        // Same instant, different local times
        expect(original.toEpochMilli(), equals(london.toEpochMilli()));
        expect(original.toEpochMilli(), equals(tokyo.toEpochMilli()));
        
        // Different local times
        expect(london.hour, equals(20)); // 5 hours ahead
        expect(tokyo.hour, equals(5)); // Next day, 14 hours ahead
      });

      test('should convert to UTC', () {
        final ny = ZonedDateTime.parse('2023-12-25T15:00:00-05:00[America/New_York]');
        final utc = ny.toUtc();
        
        expect(utc.zone, equals(ZoneId.UTC));
        expect(utc.hour, equals(20)); // 15:00 EST = 20:00 UTC
        expect(utc.toEpochMilli(), equals(ny.toEpochMilli()));
      });

      test('should change timezone keeping same local time', () {
        final original = ZonedDateTime.parse('2023-12-25T15:00:00-05:00[America/New_York]');
        final sameLocal = original.withZoneSameLocal(ZoneId.of('Europe/London'));
        
        // Same local time, different instant
        expect(sameLocal.hour, equals(15)); // Same hour
        expect(sameLocal.zone.id, equals('Europe/London'));
        expect(sameLocal.toEpochMilli(), isNot(equals(original.toEpochMilli())));
      });
    });

    group('Arithmetic Operations', () {
      test('should add and subtract durations', () {
        final start = ZonedDateTime.parse('2023-12-25T15:00:00+01:00[Europe/Paris]');
        
        final later = start.plus(Duration(hours: 3, minutes: 30));
        final earlier = start.minus(Duration(hours: 2));
        
        expect(later.hour, equals(18));
        expect(later.minute, equals(30));
        expect(earlier.hour, equals(13));
      });

      test('should add days, weeks, months, and years', () {
        final start = ZonedDateTime.parse('2023-01-15T12:00:00Z');
        
        final nextWeek = start.plusWeeks(1);
        final nextMonth = start.plusMonths(1);
        final nextYear = start.plusYears(1);
        
        expect(nextWeek.day, equals(22));
        expect(nextMonth.month, equals(2));
        expect(nextYear.year, equals(2024));
      });

      test('should handle month-end arithmetic correctly', () {
        final jan31 = ZonedDateTime.parse('2023-01-31T12:00:00Z');
        final feb = jan31.plusMonths(1);
        
        // Should adjust to Feb 28 (not Feb 31)
        expect(feb.month, equals(2));
        expect(feb.day, equals(28));
      });

      test('should handle leap year arithmetic', () {
        final leap = ZonedDateTime.parse('2020-02-29T12:00:00Z');
        final nextYear = leap.plusYears(1);
        
        // Should adjust to Feb 28 in non-leap year
        expect(nextYear.year, equals(2021));
        expect(nextYear.month, equals(2));
        expect(nextYear.day, equals(28));
      });
    });

    group('Comparison and Equality', () {
      test('should compare ZonedDateTime instances correctly', () {
        final earlier = ZonedDateTime.parse('2023-12-25T15:00:00Z');
        final later = ZonedDateTime.parse('2023-12-25T16:00:00Z');
        final same = ZonedDateTime.parse('2023-12-25T15:00:00Z');
        
        expect(earlier.compareTo(later), lessThan(0));
        expect(later.compareTo(earlier), greaterThan(0));
        expect(earlier.compareTo(same), equals(0));
        
        expect(earlier.isBefore(later), isTrue);
        expect(later.isAfter(earlier), isTrue);
        expect(earlier.isEqual(same), isTrue);
        expect(later.isAfter(earlier), isTrue);
        expect(earlier.isEqual(same), isTrue);
      });

      test('should handle equality across timezones', () {
        final ny = ZonedDateTime.parse('2023-12-25T15:00:00-05:00[America/New_York]');
        final utc = ZonedDateTime.parse('2023-12-25T20:00:00Z');
        
        // Same instant, different timezones
        expect(ny == utc, isTrue);
        expect(ny.isEqual(utc), isTrue);
        expect(ny.hashCode, equals(utc.hashCode));
      });

      test('should handle inequality correctly', () {
        final dt1 = ZonedDateTime.parse('2023-12-25T15:00:00Z');
        final dt2 = ZonedDateTime.parse('2023-12-25T15:01:00Z');
        
        expect(dt1 == dt2, isFalse);
        expect(dt1.hashCode, isNot(equals(dt2.hashCode)));
      });
    });

    group('Conversion Methods', () {
      test('should convert to DateTime', () {
        final zoned = ZonedDateTime.parse('2023-12-25T15:00:00-05:00');
        final dateTime = zoned.toDateTime();
        
        // Should be converted to UTC
        expect(dateTime.isUtc, isTrue);
        expect(dateTime.hour, equals(20)); // 15:00-05:00 = 20:00 UTC
      });

      test('should convert to epoch milliseconds', () {
        final zoned = ZonedDateTime.parse('2023-01-01T00:00:00Z');
        final epochMillis = zoned.toEpochMilli();
        
        final recreated = ZonedDateTime.fromEpochMilli(epochMillis);
        expect(recreated.isEqual(zoned), isTrue);
      });

      test('should extract date and time components', () {
        final zoned = ZonedDateTime.parse('2023-12-25T15:30:45Z');
        
        final date = zoned.toLocalDate();
        final time = zoned.toLocalTime();
        
        expect(date.year, equals(2023));
        expect(date.month, equals(12));
        expect(date.day, equals(25));
        
        expect(time.hour, equals(15));
        expect(time.minute, equals(30));
        expect(time.second, equals(45));
      });
    });

    group('String Representation', () {
      test('should format to string correctly', () {
        final zoned = ZonedDateTime.of(
          LocalDateTime.of(2023, 12, 25, 15, 30, 45),
          ZoneId.of('America/New_York')
        );
        
        final fullString = zoned.toString();
        final compactString = zoned.toStringCompact();
        
        expect(fullString, contains('2023-12-25T15:30:45'));
        expect(fullString, contains('[America/New_York]'));
        expect(compactString, isNot(contains('[America/New_York]')));
        expect(compactString, matches(RegExp(r'2023-12-25T15:30:45[+-]\d{2}:\d{2}')));
      });

      test('should format UTC offset correctly', () {
        final utc = ZonedDateTime.parse('2023-12-25T15:30:00Z');
        final positive = ZonedDateTime.parse('2023-12-25T15:30:00+05:30');
        final negative = ZonedDateTime.parse('2023-12-25T15:30:00-08:00');
        
        expect(utc.toStringCompact(), contains('Z'));
        expect(positive.toStringCompact(), contains('+05:30'));
        expect(negative.toStringCompact(), contains('-08:00'));
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle unknown timezones gracefully', () {
        final unknown = ZonedDateTime.of(
          LocalDateTime.of(2023, 12, 25, 15, 30),
          ZoneId.of('Unknown/Timezone')
        );
        
        // Should default to UTC
        expect(unknown.offset, equals(Duration.zero));
      });

      test('should handle DST transition edge cases', () {
        // Spring forward transition (2:00 AM becomes 3:00 AM)
        final springForward = ZonedDateTime.of(
          LocalDateTime.of(2023, 3, 12, 2, 30), // During "lost" hour
          ZoneId.of('America/New_York')
        );
        
        expect(springForward.isDaylightSaving, isTrue);
        expect(springForward.offset, equals(Duration(hours: -4))); // EDT
      });

      test('should handle year boundaries correctly', () {
        final newYear = ZonedDateTime.parse('2023-12-31T23:59:59Z');
        final nextYear = newYear.plusSeconds(1);
        
        expect(nextYear.year, equals(2024));
        expect(nextYear.month, equals(1));
        expect(nextYear.day, equals(1));
        expect(nextYear.hour, equals(0));
        expect(nextYear.minute, equals(0));
        expect(nextYear.second, equals(0));
      });

      test('should handle invalid parsing gracefully', () {
        expect(() => ZonedDateTime.parse('invalid-date'), throwsInvalidFormatException);
      });
    });

    group('Advanced Timezone Features', () {
      test('should handle abbreviated timezone names', () {
        final est = ZonedDateTime.of(
          LocalDateTime.of(2023, 1, 15, 12, 0),
          ZoneId.of('EST')
        );
        final pst = ZonedDateTime.of(
          LocalDateTime.of(2023, 7, 15, 12, 0),
          ZoneId.of('PST')
        );
        
        expect(est.offset, equals(Duration(hours: -5)));
        expect(pst.offset, equals(Duration(hours: -8)));
      });

      test('should preserve timezone information through arithmetic', () {
        final original = ZonedDateTime.parse('2023-12-25T15:00:00+09:00[Asia/Tokyo]');
        final later = original.plusHours(25); // Cross day boundary
        
        expect(later.zone.id, equals('Asia/Tokyo'));
        expect(later.offset, equals(Duration(hours: 9)));
        expect(later.day, equals(26));
        expect(later.hour, equals(16)); // 15 + 25 - 24
      });

      test('should handle timezone conversions with DST changes', () {
        // Create a time in winter (EST) and convert to summer equivalent
        final winter = ZonedDateTime.of(
          LocalDateTime.of(2023, 1, 15, 12, 0),
          ZoneId.of('America/New_York')
        );
        
        // Add 6 months to get to summer (EDT)
        final summer = winter.plusMonths(6);
        
        expect(winter.offset, equals(Duration(hours: -5))); // EST
        expect(summer.offset, equals(Duration(hours: -4))); // EDT
        expect(winter.isDaylightSaving, isFalse);
        expect(summer.isDaylightSaving, isTrue);
      });
    });

    group('Performance and Memory', () {
      test('should create instances efficiently', () {
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 1000; i++) {
          ZonedDateTime.now(ZoneId.of('America/New_York'));
        }
        
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should be fast
      });

      test('should handle large date arithmetic correctly', () {
        final base = ZonedDateTime.parse('2023-01-01T00:00:00Z');
        final future = base.plusDays(365 * 100); // 100 years
        
        expect(future.year, equals(2122));
        expect(future.month, equals(12));
        expect(future.day, equals(08));
      });
    });
  });
}
