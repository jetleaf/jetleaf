import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_scheduling/jetleaf_scheduling.dart';

void main() {
  group('CronTrigger', () {
    test('should create trigger with valid cron expression', () {
      final trigger = CronTrigger('0 0 * * * *', ZoneId.UTC);
      expect(trigger.getExpression(), equals('0 0 * * * *'));
      expect(trigger.getZone(), equals(ZoneId.UTC));
    });

    test('should create trigger from CronExpression', () {
      final cron = CronExpression('0 0 9 * * 1');
      final trigger = CronTrigger.fromExpression(cron, ZoneId.of('Europe/London'));
      expect(trigger.getExpression(), equals('0 0 9 * * 1'));
      expect(trigger.getZone(), equals(ZoneId.of('Europe/London')));
    });

    test('should throw InvalidCronExpressionException for invalid expression', () {
      expect(() => CronTrigger('invalid', ZoneId.UTC), throwsA(isA<InvalidCronExpressionException>()));
    });

    test('should compute next execution time', () {
      final trigger = CronTrigger('0 0 * * * *', ZoneId.UTC);
      final context = DefaultTaskExecutionContext();
      final nextTime = trigger.nextExecutionTime(context);
      expect(nextTime, isNotNull);
    });

    test('should implement equality', () {
      final trigger1 = CronTrigger('0 0 * * * *', ZoneId.UTC);
      final trigger2 = CronTrigger('0 0 * * * *', ZoneId.UTC);
      final trigger3 = CronTrigger('0 0 * * * 1', ZoneId.UTC);
      expect(trigger1, equals(trigger2));
      expect(trigger1 == trigger3, isFalse);
    });

    test('should have correct string representation', () {
      final trigger = CronTrigger('0 0 * * * *', ZoneId.UTC);
      expect(trigger.toString(), contains('CronTrigger'));
      expect(trigger.toString(), contains('0 0 * * * *'));
    });
  });

  group('CronExpression', () {
    test('should validate 6-field expressions', () {
      expect(() => CronExpression('* * * * * *'), returnsNormally);
      expect(() => CronExpression('0 0 0 1 1 0'), returnsNormally);
    });

    test('should reject expressions with wrong number of fields', () {
      expect(() => CronExpression('* * *'), throwsA(isA<InvalidCronExpressionException>()));
      expect(() => CronExpression(''), throwsA(isA<InvalidCronExpressionException>()));
    });

    test('should validate field ranges', () {
      expect(() => CronExpression('60 0 0 1 1 0'), throwsA(isA<InvalidCronExpressionException>()));
      expect(() => CronExpression('0 60 0 1 1 0'), throwsA(isA<InvalidCronExpressionException>()));
      expect(() => CronExpression('0 0 24 1 1 0'), throwsA(isA<InvalidCronExpressionException>()));
      expect(() => CronExpression('0 0 0 0 1 0'), throwsA(isA<InvalidCronExpressionException>()));
      expect(() => CronExpression('0 0 0 32 1 0'), throwsA(isA<InvalidCronExpressionException>()));
      expect(() => CronExpression('0 0 0 1 13 0'), throwsA(isA<InvalidCronExpressionException>()));
    });

    test('should support wildcard', () {
      expect(CronExpression('* * * * * *'), isA<CronExpression>());
    });

    test('should support step values', () {
      expect(CronExpression('0 */5 * * * *'), isA<CronExpression>());
      expect(CronExpression('0 */10 * * * *'), isA<CronExpression>());
      expect(CronExpression('0-30/5 * * * * *'), isA<CronExpression>());
    });

    test('should support ranges', () {
      expect(CronExpression('0 0 9-17 * * *'), isA<CronExpression>());
    });

    test('should support lists', () {
      expect(CronExpression('0 0,12 * * * *'), isA<CronExpression>());
    });

    test('should support question mark for day fields', () {
      // ? is only valid for day of month (position 3) and day of week (position 5)
      // Format: second minute hour dayOfMonth month dayOfWeek
      expect(CronExpression('0 0 0 * * ?'), isA<CronExpression>());
      expect(CronExpression('0 0 0 ? * *'), isA<CronExpression>());
    });

    test('should check validity statically', () {
      expect(CronExpression.isValid('* * * * * *'), isTrue);
      expect(CronExpression.isValid('invalid'), isFalse);
      expect(CronExpression.isValid(''), isFalse);
    });

    test('should compute next execution time', () {
      final cron = CronExpression('0 0 * * * *');
      final now = ZonedDateTime.now(ZoneId.UTC);
      final next = cron.nextExecution(now, ZoneId.UTC);
      expect(next, isNotNull);
      expect(next!.isAfter(now), isTrue);
    });

    test('should implement equality', () {
      final expr1 = CronExpression('0 0 * * * *');
      final expr2 = CronExpression('0 0 * * * *');
      final expr3 = CronExpression('0 0 * * * 1');
      expect(expr1, equals(expr2));
      expect(expr1 == expr3, isFalse);
    });
  });

  group('FixedRateTrigger', () {
    test('should create trigger with period', () {
      final trigger = FixedRateTrigger(Duration(seconds: 10), ZoneId.UTC);
      expect(trigger.period, equals(Duration(seconds: 10)));
      expect(trigger.getZone(), equals(ZoneId.UTC));
      expect(trigger.initialDelay, isNull);
    });

    test('should create trigger with initial delay', () {
      final trigger = FixedRateTrigger(Duration(seconds: 10), ZoneId.UTC, Duration(seconds: 5));
      expect(trigger.initialDelay, equals(Duration(seconds: 5)));
    });

    test('should compute next execution time without initial delay', () {
      final trigger = FixedRateTrigger(Duration(seconds: 10), ZoneId.UTC);
      final context = DefaultTaskExecutionContext();
      final nextTime = trigger.nextExecutionTime(context);
      expect(nextTime, isNotNull);
    });

    test('should compute next execution time with initial delay', () {
      final trigger = FixedRateTrigger(Duration(seconds: 10), ZoneId.UTC, Duration(seconds: 5));
      final context = DefaultTaskExecutionContext();
      final nextTime = trigger.nextExecutionTime(context);
      expect(nextTime, isNotNull);
    });

    test('should compute next execution after last scheduled time', () {
      final trigger = FixedRateTrigger(Duration(seconds: 10), ZoneId.UTC);
      final context = DefaultTaskExecutionContext();
      final scheduledTime = ZonedDateTime.now(ZoneId.UTC);
      context.recordScheduledExecution(scheduledTime);
      context.recordActualExecution(scheduledTime);
      context.recordCompletion(scheduledTime);
      final nextTime = trigger.nextExecutionTime(context);
      expect(nextTime, isNotNull);
      expect(nextTime!.toEpochMilli() - scheduledTime.toEpochMilli(), greaterThanOrEqualTo(10000));
    });

    test('should implement equality', () {
      final trigger1 = FixedRateTrigger(Duration(seconds: 10), ZoneId.UTC);
      final trigger2 = FixedRateTrigger(Duration(seconds: 10), ZoneId.UTC);
      final trigger3 = FixedRateTrigger(Duration(seconds: 20), ZoneId.UTC);
      expect(trigger1, equals(trigger2));
      expect(trigger1 == trigger3, isFalse);
    });

    test('should have correct string representation', () {
      final trigger = FixedRateTrigger(Duration(seconds: 10), ZoneId.UTC, Duration(seconds: 5));
      expect(trigger.toString(), contains('FixedRateTrigger'));
      expect(trigger.toString(), contains('0:00:10.000000'));
    });
  });

  group('FixedDelayTrigger', () {
    test('should create trigger with delay', () {
      final trigger = FixedDelayTrigger(Duration(seconds: 10), ZoneId.UTC);
      expect(trigger.delay, equals(Duration(seconds: 10)));
      expect(trigger.getZone(), equals(ZoneId.UTC));
      expect(trigger.initialDelay, isNull);
    });

    test('should create trigger with initial delay', () {
      final trigger = FixedDelayTrigger(Duration(seconds: 10), ZoneId.UTC, Duration(seconds: 5));
      expect(trigger.initialDelay, equals(Duration(seconds: 5)));
    });

    test('should compute next execution time without initial delay', () {
      final trigger = FixedDelayTrigger(Duration(seconds: 10), ZoneId.UTC);
      final context = DefaultTaskExecutionContext();
      final nextTime = trigger.nextExecutionTime(context);
      expect(nextTime, isNotNull);
    });

    test('should compute next execution after completion', () {
      final trigger = FixedDelayTrigger(Duration(seconds: 10), ZoneId.UTC);
      final context = DefaultTaskExecutionContext();
      final completionTime = ZonedDateTime.now(ZoneId.UTC);
      context.recordScheduledExecution(completionTime);
      context.recordActualExecution(completionTime);
      context.recordCompletion(completionTime);
      final nextTime = trigger.nextExecutionTime(context);
      expect(nextTime, isNotNull);
      expect(nextTime!.toEpochMilli() - completionTime.toEpochMilli(), greaterThanOrEqualTo(10000));
    });

    test('should implement equality', () {
      final trigger1 = FixedDelayTrigger(Duration(seconds: 10), ZoneId.UTC);
      final trigger2 = FixedDelayTrigger(Duration(seconds: 10), ZoneId.UTC);
      final trigger3 = FixedDelayTrigger(Duration(seconds: 20), ZoneId.UTC);
      expect(trigger1, equals(trigger2));
      expect(trigger1 == trigger3, isFalse);
    });

    test('should have correct string representation', () {
      final trigger = FixedDelayTrigger(Duration(seconds: 10), ZoneId.UTC, Duration(seconds: 5));
      expect(trigger.toString(), contains('FixedDelayTrigger'));
      expect(trigger.toString(), contains('0:00:10.000000'));
    });
  });

  group('PeriodicTrigger', () {
    test('should create trigger with period', () {
      final trigger = PeriodicTrigger(Duration(seconds: 30), ZoneId.UTC);
      expect(trigger.period, equals(Duration(seconds: 30)));
      expect(trigger.getZone(), equals(ZoneId.UTC));
    });

    test('should compute next execution time without last execution', () {
      final trigger = PeriodicTrigger(Duration(seconds: 30), ZoneId.UTC);
      final context = DefaultTaskExecutionContext();
      final nextTime = trigger.nextExecutionTime(context);
      expect(nextTime, isNotNull);
    });

    test('should compute next execution after last execution', () {
      final trigger = PeriodicTrigger(Duration(seconds: 30), ZoneId.UTC);
      final context = DefaultTaskExecutionContext();
      final lastExecution = ZonedDateTime.now(ZoneId.UTC);
      context.recordScheduledExecution(lastExecution);
      context.recordActualExecution(lastExecution);
      context.recordCompletion(lastExecution);
      final nextTime = trigger.nextExecutionTime(context);
      expect(nextTime, isNotNull);
      expect(nextTime!.toEpochMilli() - lastExecution.toEpochMilli(), greaterThanOrEqualTo(30000));
    });

    test('should implement equality', () {
      final trigger1 = PeriodicTrigger(Duration(seconds: 30), ZoneId.UTC);
      final trigger2 = PeriodicTrigger(Duration(seconds: 30), ZoneId.UTC);
      final trigger3 = PeriodicTrigger(Duration(seconds: 60), ZoneId.UTC);
      expect(trigger1, equals(trigger2));
      expect(trigger1 == trigger3, isFalse);
    });

    test('should have correct string representation', () {
      final trigger = PeriodicTrigger(Duration(seconds: 30), ZoneId.UTC);
      expect(trigger.toString(), contains('PeriodicTrigger'));
      expect(trigger.toString(), contains('0:00:30.000000'));
    });
  });

  group('TriggerBuilder', () {
    test('should build CronTrigger from expression', () {
      final builder = TriggerBuilder(expression: '0 0 * * * *', zone: 'UTC');
      expect(builder.getTrigger(), isA<CronTrigger>());
      expect(builder.getZone(), equals(ZoneId.UTC));
    });

    test('should build FixedRateTrigger', () {
      final builder = TriggerBuilder(fixedRate: Duration(seconds: 10), zone: 'UTC');
      expect(builder.getTrigger(), isA<FixedRateTrigger>());
    });

    test('should build FixedDelayTrigger', () {
      final builder = TriggerBuilder(fixedDelay: Duration(seconds: 10), zone: 'UTC');
      expect(builder.getTrigger(), isA<FixedDelayTrigger>());
    });

    test('should build PeriodicTrigger', () {
      final builder = TriggerBuilder(period: Duration(seconds: 30), zone: 'UTC');
      expect(builder.getTrigger(), isA<PeriodicTrigger>());
    });

    test('should throw SchedulerException when no trigger specified', () {
      expect(() => TriggerBuilder(), throwsA(isA<SchedulerException>()));
    });

    test('should support initial delay for fixed rate', () {
      final builder = TriggerBuilder(
        fixedRate: Duration(seconds: 10),
        delayPeriod: Duration(seconds: 5),
        zone: 'UTC',
      );
      final trigger = builder.getTrigger() as FixedRateTrigger;
      expect(trigger.initialDelay, equals(Duration(seconds: 5)));
    });

    test('should support initial delay for fixed delay', () {
      final builder = TriggerBuilder(
        fixedDelay: Duration(seconds: 10),
        delayPeriod: Duration(seconds: 5),
        zone: 'UTC',
      );
      final trigger = builder.getTrigger() as FixedDelayTrigger;
      expect(trigger.initialDelay, equals(Duration(seconds: 5)));
    });

    test('should compute next execution time', () {
      final builder = TriggerBuilder(fixedRate: Duration(seconds: 10), zone: 'UTC');
      final context = DefaultTaskExecutionContext();
      final nextTime = builder.nextExecutionTime(context);
      expect(nextTime, isNotNull);
    });

    test('should have correct string representation', () {
      final builder = TriggerBuilder(fixedRate: Duration(seconds: 10), zone: 'UTC');
      expect(builder.toString(), contains('TriggerBuilder'));
      expect(builder.toString(), contains('FixedRateTrigger'));
    });

    test('should implement equality', () {
      final builder1 = TriggerBuilder(fixedRate: Duration(seconds: 10), zone: 'UTC');
      final builder2 = TriggerBuilder(fixedRate: Duration(seconds: 10), zone: 'UTC');
      expect(builder1, equals(builder2));
    });
  });
}
