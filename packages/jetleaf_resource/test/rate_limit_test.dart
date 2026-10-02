import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_resource/jetleaf_resource.dart';

void main() {
  group('SimpleRateLimitEntry', () {
    late SimpleRateLimitEntry entry;

    setUp(() {
      entry = SimpleRateLimitEntry('user:123', Duration(minutes: 1), ZoneId.UTC);
    });

    test('should return correct window key', () {
      expect(entry.getWindowKey(), equals('user:123'));
    });

    test('should return correct window duration', () {
      expect(entry.getWindowDuration(), equals(Duration(minutes: 1)));
    });

    test('should initialize with zero count', () {
      expect(entry.getCount(), equals(0));
    });

    test('should increment count', () {
      entry.increment();
      expect(entry.getCount(), equals(1));
      entry.increment();
      expect(entry.getCount(), equals(2));
    });

    test('should decrement count', () {
      entry.increment();
      entry.increment();
      final newCount = entry.decrement();
      expect(newCount, equals(1));
      expect(entry.getCount(), equals(1));
    });

    test('should not decrement below zero', () {
      final newCount = entry.decrement();
      expect(newCount, equals(0));
      expect(entry.getCount(), equals(0));
    });

    test('should reset count and timestamps', () {
      entry.increment();
      entry.increment();
      entry.reset();
      expect(entry.getCount(), equals(0));
    });

    test('should not be expired initially', () {
      expect(entry.isExpired(), isFalse);
    });

    test('should return reset time in the future', () {
      final resetTime = entry.getResetTime();
      final now = ZonedDateTime.now(ZoneId.UTC);
      expect(resetTime.compareTo(now) >= 0, isTrue);
    });

    test('should return timestamp', () {
      final timestamp = entry.getTimeStamp();
      expect(timestamp, isNotNull);
    });

    test('should return seconds until reset', () {
      final seconds = entry.secondsUntilReset();
      expect(seconds, greaterThanOrEqualTo(0));
      expect(seconds, lessThanOrEqualTo(60));
    });

    test('should return retry after', () {
      final retryAfter = entry.getRetryAfter();
      expect(retryAfter, isNotNull);
    });
  });

  group('RateLimitResult', () {
    test('should create with required parameters', () {
      final now = ZonedDateTime.now(ZoneId.UTC);
      final result = RateLimitResult(
        identifier: 'user:42',
        limitName: 'apiLimit',
        currentCount: 5,
        limit: 10,
        window: Duration(minutes: 1),
        resetTime: now,
        retryAfter: Duration(seconds: 30),
        zoneId: ZoneId.UTC,
      );

      expect(result.identifier, equals('user:42'));
      expect(result.limitName, equals('apiLimit'));
      expect(result.currentCount, equals(5));
      expect(result.limit, equals(10));
      expect(result.window, equals(Duration(minutes: 1)));
      expect(result.zoneId, equals(ZoneId.UTC));
    });

    test('should calculate remaining count', () {
      final now = ZonedDateTime.now(ZoneId.UTC);
      final result = RateLimitResult(
        identifier: 'user:42',
        limitName: 'apiLimit',
        currentCount: 3,
        limit: 10,
        window: Duration(minutes: 1),
        resetTime: now,
        retryAfter: Duration(seconds: 30),
        zoneId: ZoneId.UTC,
      );
      expect(result.remainingCount, equals(7));
    });

    test('should return allowed when under limit', () {
      final now = ZonedDateTime.now(ZoneId.UTC);
      final result = RateLimitResult(
        identifier: 'user:42',
        limitName: 'apiLimit',
        currentCount: 5,
        limit: 10,
        window: Duration(minutes: 1),
        resetTime: now,
        retryAfter: Duration(seconds: 30),
        zoneId: ZoneId.UTC,
      );
      expect(result.allowed, isTrue);
    });

    test('should return not allowed when at limit', () {
      final now = ZonedDateTime.now(ZoneId.UTC);
      final result = RateLimitResult(
        identifier: 'user:42',
        limitName: 'apiLimit',
        currentCount: 10,
        limit: 10,
        window: Duration(minutes: 1),
        resetTime: now,
        retryAfter: Duration(seconds: 30),
        zoneId: ZoneId.UTC,
      );
      expect(result.allowed, isFalse);
    });

    test('should return not allowed when over limit', () {
      final now = ZonedDateTime.now(ZoneId.UTC);
      final result = RateLimitResult(
        identifier: 'user:42',
        limitName: 'apiLimit',
        currentCount: 15,
        limit: 10,
        window: Duration(minutes: 1),
        resetTime: now,
        retryAfter: Duration(seconds: 30),
        zoneId: ZoneId.UTC,
      );
      expect(result.allowed, isFalse);
    });
  });

  group('RateLimitExceededException', () {
    test('should create with all parameters', () {
      final now = ZonedDateTime.now(ZoneId.UTC);
      final exception = RateLimitExceededException(
        identifier: 'user:42',
        limitName: 'apiLimit',
        currentCount: 15,
        limit: 10,
        window: Duration(minutes: 1),
        resetTime: now,
        retryAfter: Duration(seconds: 30),
        zoneId: ZoneId.UTC,
      );

      expect(exception.identifier, equals('user:42'));
      expect(exception.limitName, equals('apiLimit'));
      expect(exception.currentCount, equals(15));
      expect(exception.limit, equals(10));
    });

    test('should calculate remaining as zero when over limit', () {
      final now = ZonedDateTime.now(ZoneId.UTC);
      final exception = RateLimitExceededException(
        identifier: 'user:42',
        limitName: 'apiLimit',
        currentCount: 15,
        limit: 10,
        window: Duration(minutes: 1),
        resetTime: now,
        retryAfter: Duration(seconds: 30),
        zoneId: ZoneId.UTC,
      );
      expect(exception.remaining, equals(0));
    });

    test('should calculate usage ratio', () {
      final now = ZonedDateTime.now(ZoneId.UTC);
      final exception = RateLimitExceededException(
        identifier: 'user:42',
        limitName: 'apiLimit',
        currentCount: 8,
        limit: 10,
        window: Duration(minutes: 1),
        resetTime: now,
        retryAfter: Duration(seconds: 30),
        zoneId: ZoneId.UTC,
      );
      expect(exception.usageRatio, equals(0.8));
    });

    test('should return isFullyExhausted when remaining is zero', () {
      final now = ZonedDateTime.now(ZoneId.UTC);
      final exception = RateLimitExceededException(
        identifier: 'user:42',
        limitName: 'apiLimit',
        currentCount: 10,
        limit: 10,
        window: Duration(minutes: 1),
        resetTime: now,
        retryAfter: Duration(seconds: 30),
        zoneId: ZoneId.UTC,
      );
      expect(exception.isFullyExhausted, isTrue);
    });

    test('should return map representation', () {
      final now = ZonedDateTime.now(ZoneId.UTC);
      final exception = RateLimitExceededException(
        identifier: 'user:42',
        limitName: 'apiLimit',
        currentCount: 10,
        limit: 10,
        window: Duration(minutes: 1),
        resetTime: now,
        retryAfter: Duration(seconds: 30),
        zoneId: ZoneId.UTC,
      );
      final map = exception.toMap();
      expect(map['identifier'], equals('user:42'));
      expect(map['limit_name'], equals('apiLimit'));
      expect(map['current_count'], equals(10));
      expect(map['limit'], equals(10));
      expect(map['remaining'], equals(0));
      expect(map['is_fully_exhausted'], isTrue);
    });

    test('should return HTTP headers', () {
      final now = ZonedDateTime.now(ZoneId.UTC);
      final exception = RateLimitExceededException(
        identifier: 'user:42',
        limitName: 'apiLimit',
        currentCount: 10,
        limit: 10,
        window: Duration(minutes: 1),
        resetTime: now,
        retryAfter: Duration(seconds: 30),
        zoneId: ZoneId.UTC,
      );
      final headers = exception.toHttpHeaders();
      expect(headers['X-RateLimit-Limit'], equals('10'));
      expect(headers['X-RateLimit-Remaining'], equals('0'));
      expect(headers['Retry-After'], equals('30'));
      expect(headers['X-RateLimit-Name'], equals('apiLimit'));
      expect(headers['X-RateLimit-Window'], equals('60'));
    });

    test('should have message', () {
      final now = ZonedDateTime.now(ZoneId.UTC);
      final exception = RateLimitExceededException(
        identifier: 'user:42',
        limitName: 'apiLimit',
        currentCount: 10,
        limit: 10,
        window: Duration(minutes: 1),
        resetTime: now,
        retryAfter: Duration(seconds: 30),
        zoneId: ZoneId.UTC,
      );
      expect(exception.message, isNotEmpty);
      expect(exception.message, contains('user:42'));
      expect(exception.message, contains('apiLimit'));
    });

    test('should create from RateLimitResult', () {
      final now = ZonedDateTime.now(ZoneId.UTC);
      final result = RateLimitResult(
        identifier: 'user:42',
        limitName: 'apiLimit',
        currentCount: 10,
        limit: 10,
        window: Duration(minutes: 1),
        resetTime: now,
        retryAfter: Duration(seconds: 30),
        zoneId: ZoneId.UTC,
      );
      final exception = RateLimitExceededException.result(result);
      expect(exception.identifier, equals('user:42'));
      expect(exception.limitName, equals('apiLimit'));
      expect(exception.currentCount, equals(10));
      expect(exception.limit, equals(10));
    });
  });
}
