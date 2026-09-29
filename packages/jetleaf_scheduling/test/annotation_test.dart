import 'package:test/test.dart';
import 'package:jetleaf_scheduling/jetleaf_scheduling.dart';

void main() {
  group('Scheduled Annotation', () {
    test('should create with cron expression', () {
      const scheduled = Scheduled(cron: '0 0 * * * *');
      expect(scheduled.cron, equals('0 0 * * * *'));
      expect(scheduled.type, isNull);
      expect(scheduled.fixedRate, isNull);
      expect(scheduled.fixedDelay, isNull);
      expect(scheduled.zone, isNull);
    });

    test('should create with fixed rate', () {
      const scheduled = Scheduled(fixedRate: Duration(seconds: 10));
      expect(scheduled.cron, isNull);
      expect(scheduled.fixedRate, equals(Duration(seconds: 10)));
    });

    test('should create with fixed delay', () {
      const scheduled = Scheduled(fixedDelay: Duration(seconds: 10));
      expect(scheduled.cron, isNull);
      expect(scheduled.fixedDelay, equals(Duration(seconds: 10)));
    });

    test('should create with cron type', () {
      const scheduled = Scheduled(type: CronType.EVERY_HOUR);
      expect(scheduled.cron, isNull);
      expect(scheduled.type, equals(CronType.EVERY_HOUR));
    });

    test('should create with zone', () {
      const scheduled = Scheduled(
        cron: '0 0 * * * *',
        zone: 'UTC',
      );
      expect(scheduled.zone, equals('UTC'));
    });

    test('should implement equality', () {
      const scheduled1 = Scheduled(cron: '0 0 * * * *');
      const scheduled2 = Scheduled(cron: '0 0 * * * *');
      const scheduled3 = Scheduled(cron: '0 0 * * * 1');
      expect(scheduled1, equals(scheduled2));
      expect(scheduled1 == scheduled3, isFalse);
    });

    test('should have correct annotationType', () {
      const scheduled = Scheduled();
      expect(scheduled.annotationType, equals(Scheduled));
    });

    test('should have correct toString', () {
      const scheduled = Scheduled(cron: '0 0 * * * *');
      expect(scheduled.toString(), contains('Scheduled'));
      expect(scheduled.toString(), contains('0 0 * * * *'));
    });
  });

  group('Cron Annotation', () {
    test('should create with expression', () {
      const cron = Cron(expression: '0 0 * * * *');
      expect(cron.expression, equals('0 0 * * * *'));
      expect(cron.type, isNull);
      expect(cron.zone, isNull);
    });

    test('should create with cron type', () {
      const cron = Cron(type: CronType.EVERY_HOUR);
      expect(cron.expression, isNull);
      expect(cron.type, equals(CronType.EVERY_HOUR));
    });

    test('should create with zone', () {
      const cron = Cron(expression: '0 0 * * * *', zone: 'UTC');
      expect(cron.zone, equals('UTC'));
    });

    test('should implement equality', () {
      const cron1 = Cron(expression: '0 0 * * * *');
      const cron2 = Cron(expression: '0 0 * * * *');
      const cron3 = Cron(expression: '0 0 * * * 1');
      expect(cron1, equals(cron2));
      expect(cron1 == cron3, isFalse);
    });

    test('should have correct annotationType', () {
      const cron = Cron();
      expect(cron.annotationType, equals(Cron));
    });

    test('should have correct toString', () {
      const cron = Cron(expression: '0 0 * * * *');
      expect(cron.toString(), contains('Cron'));
      expect(cron.toString(), contains('0 0 * * * *'));
    });
  });

  group('Periodic Annotation', () {
    test('should create with period', () {
      const periodic = Periodic(Duration(seconds: 30));
      expect(periodic.period, equals(Duration(seconds: 30)));
      expect(periodic.zone, isNull);
    });

    test('should create with zone', () {
      const periodic = Periodic(Duration(seconds: 30), zone: 'UTC');
      expect(periodic.zone, equals('UTC'));
    });

    test('should have correct annotationType', () {
      const periodic = Periodic(Duration(seconds: 30));
      expect(periodic.annotationType, equals(Periodic));
    });

    test('should have different period values', () {
      const periodic1 = Periodic(Duration(seconds: 30));
      const periodic2 = Periodic(Duration(seconds: 60));
      expect(periodic1.period, isNot(equals(periodic2.period)));
    });
  });

  group('CronType', () {
    test('should have correct expressions', () {
      expect(CronType.EVERY_SECOND.expression, equals('* * * * * *'));
      expect(CronType.EVERY_5_SECONDS.expression, equals('*/5 * * * * *'));
      expect(CronType.EVERY_10_SECONDS.expression, equals('*/10 * * * * *'));
      expect(CronType.EVERY_30_SECONDS.expression, equals('*/30 * * * * *'));
      expect(CronType.EVERY_MINUTE.expression, equals('0 * * * * *'));
      expect(CronType.EVERY_5_MINUTES.expression, equals('0 */5 * * * *'));
      expect(CronType.EVERY_10_MINUTES.expression, equals('0 */10 * * * *'));
      expect(CronType.EVERY_30_MINUTES.expression, equals('0 */30 * * * *'));
      expect(CronType.EVERY_HOUR.expression, equals('0 0 * * * *'));
      expect(CronType.EVERY_3_HOURS.expression, equals('0 0 */3 * * *'));
      expect(CronType.EVERY_6_HOURS.expression, equals('0 0 */6 * * *'));
      expect(CronType.EVERY_12_HOURS.expression, equals('0 0 */12 * * *'));
      expect(CronType.DAILY_AT_MIDNIGHT.expression, equals('0 0 0 * * *'));
      expect(CronType.DAILY_AT_NOON.expression, equals('0 0 12 * * *'));
      expect(CronType.DAILY_AT_6AM.expression, equals('0 0 6 * * *'));
      expect(CronType.DAILY_AT_6PM.expression, equals('0 0 18 * * *'));
      expect(CronType.WEEKDAYS_AT_9AM.expression, equals('0 0 9 * * 1-5'));
      expect(CronType.WEEKLY_ON_SATURDAY_MIDNIGHT.expression, equals('0 0 0 * * 6'));
      expect(CronType.WEEKLY_ON_SUNDAY_MIDNIGHT.expression, equals('0 0 0 * * 0'));
      expect(CronType.WEEKLY_ON_MONDAY_9AM.expression, equals('0 0 9 * * 1'));
      expect(CronType.MONTHLY_ON_FIRST_MIDNIGHT.expression, equals('0 0 0 1 * *'));
      expect(CronType.MONTHLY_ON_FIRST_9AM.expression, equals('0 0 9 1 * *'));
      expect(CronType.YEARLY_ON_JAN1_MIDNIGHT.expression, equals('0 0 0 1 1 *'));
    });

    test('should have all enum values', () {
      expect(CronType.values.length, equals(25));
    });
  });

  group('EnableScheduling', () {
    test('should create instance', () {
      const enable = EnableScheduling();
      expect(enable, isA<EnableScheduling>());
    });

    test('should have correct annotationType', () {
      const enable = EnableScheduling();
      expect(enable.annotationType, equals(EnableScheduling));
    });

    test('should have correct toString', () {
      const enable = EnableScheduling();
      expect(enable.toString(), contains('EnableScheduler'));
    });
  });
}
