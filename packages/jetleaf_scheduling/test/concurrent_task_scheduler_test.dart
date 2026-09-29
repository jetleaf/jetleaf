import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_scheduling/jetleaf_scheduling.dart';

void main() {
  group('ConcurrentTaskScheduler', () {
    late ConcurrentTaskScheduler scheduler;

    setUp(() {
      scheduler = ConcurrentTaskScheduler(
        maxConcurrency: 5,
        queueCapacity: 10,
      );
    });

    tearDown(() async {
      await scheduler.shutdown(true);
    });

    test('should create scheduler with default values', () {
      final defaultScheduler = ConcurrentTaskScheduler();
      expect(defaultScheduler.getActiveTaskCount(), equals(0));
      expect(defaultScheduler.getQueuedTaskCount(), equals(0));
      expect(defaultScheduler.getTotalTaskCount(), equals(0));
    });

    test('should create scheduler with custom values', () {
      expect(scheduler.getActiveTaskCount(), equals(0));
      expect(scheduler.getQueuedTaskCount(), equals(0));
      expect(scheduler.getTotalTaskCount(), equals(0));
    });

    test('should schedule task', () async {
      final trigger = FixedRateTrigger(Duration(seconds: 10), ZoneId.UTC);
      final task = await scheduler.schedule(() {}, trigger, 'testTask');
      expect(task, isA<ScheduledTask>());
      expect(task.getName(), equals('testTask'));
      expect(scheduler.getTotalTaskCount(), equals(1));
    });

    test('should schedule task at fixed rate', () async {
      final task = await scheduler.scheduleAtFixedRate(
        () {},
        Duration(seconds: 10),
        'testTask',
      );
      expect(task, isA<ScheduledTask>());
      expect(scheduler.getTotalTaskCount(), equals(1));
    });

    test('should schedule task with fixed delay', () async {
      final task = await scheduler.scheduleWithFixedDelay(
        () {},
        Duration(seconds: 10),
        'testTask',
      );
      expect(task, isA<ScheduledTask>());
      expect(scheduler.getTotalTaskCount(), equals(1));
    });

    test('should return existing task for duplicate name', () async {
      final trigger = FixedRateTrigger(Duration(seconds: 10), ZoneId.UTC);
      final task1 = await scheduler.schedule(() {}, trigger, 'testTask');
      final task2 = await scheduler.schedule(() {}, trigger, 'testTask');
      expect(task1, equals(task2));
      expect(scheduler.getTotalTaskCount(), equals(1));
    });

    test('should throw SchedulerException when scheduling after shutdown', () async {
      await scheduler.shutdown();
      expect(
        () => scheduler.schedule(
          () {},
          FixedRateTrigger(Duration(seconds: 10), ZoneId.UTC),
          'testTask',
        ),
        throwsA(isA<SchedulerException>()),
      );
    });

    test('should throw SchedulerException when scheduling at fixed rate after shutdown', () async {
      await scheduler.shutdown();
      expect(
        () => scheduler.scheduleAtFixedRate(() {}, Duration(seconds: 10), 'testTask'),
        throwsA(isA<SchedulerException>()),
      );
    });

    test('should throw SchedulerException when scheduling with fixed delay after shutdown', () async {
      await scheduler.shutdown();
      expect(
        () => scheduler.scheduleWithFixedDelay(() {}, Duration(seconds: 10), 'testTask'),
        throwsA(isA<SchedulerException>()),
      );
    });

    test('should shutdown gracefully', () async {
      await scheduler.shutdown();
      expect(scheduler.getTotalTaskCount(), equals(0));
    });

    test('should shutdown forcefully', () async {
      await scheduler.shutdown(true);
      expect(scheduler.getTotalTaskCount(), equals(0));
    });

    test('should be idempotent on multiple shutdowns', () async {
      await scheduler.shutdown();
      await scheduler.shutdown();
      await scheduler.shutdown(true);
      expect(scheduler.getTotalTaskCount(), equals(0));
    });
  });
}
