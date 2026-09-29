import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_scheduling/jetleaf_scheduling.dart';

void main() {
  group('SimpleScheduledTask', () {
    test('should create task with name and trigger', () {
      final trigger = FixedRateTrigger(Duration(seconds: 10), ZoneId.UTC);
      final task = SimpleScheduledTask(() {}, trigger, 'testTask');
      expect(task.getName(), equals('testTask'));
      expect(task.getTrigger(), equals(trigger));
      expect(task.getZone(), equals(ZoneId.UTC));
    });

    test('should not be canceled initially', () {
      final trigger = FixedRateTrigger(Duration(seconds: 10), ZoneId.UTC);
      final task = SimpleScheduledTask(() {}, trigger, 'testTask');
      expect(task.getIsCanceled(), isFalse);
    });

    test('should not be executing initially', () {
      final trigger = FixedRateTrigger(Duration(seconds: 10), ZoneId.UTC);
      final task = SimpleScheduledTask(() {}, trigger, 'testTask');
      expect(task.getIsExecuting(), isFalse);
    });

    test('should have zero execution count initially', () {
      final trigger = FixedRateTrigger(Duration(seconds: 10), ZoneId.UTC);
      final task = SimpleScheduledTask(() {}, trigger, 'testTask');
      expect(task.getExecutionCount(), equals(0));
    });

    test('should have null last execution time initially', () {
      final trigger = FixedRateTrigger(Duration(seconds: 10), ZoneId.UTC);
      final task = SimpleScheduledTask(() {}, trigger, 'testTask');
      expect(task.getLastExecutionTime(), isNull);
    });

    test('should have execution context', () {
      final trigger = FixedRateTrigger(Duration(seconds: 10), ZoneId.UTC);
      final task = SimpleScheduledTask(() {}, trigger, 'testTask');
      expect(task.getExecutionContext(), isA<TaskExecutionContext>());
    });

    test('should cancel task', () async {
      final trigger = FixedRateTrigger(Duration(seconds: 10), ZoneId.UTC);
      final task = SimpleScheduledTask(() {}, trigger, 'testTask');
      final result = await task.cancel();
      expect(result, isTrue);
      expect(task.getIsCanceled(), isTrue);
    });

    test('should return false when canceling already canceled task', () async {
      final trigger = FixedRateTrigger(Duration(seconds: 10), ZoneId.UTC);
      final task = SimpleScheduledTask(() {}, trigger, 'testTask');
      await task.cancel();
      final result = await task.cancel();
      expect(result, isFalse);
    });

    test('should implement equality', () {
      final trigger1 = FixedRateTrigger(Duration(seconds: 10), ZoneId.UTC);
      final trigger2 = FixedRateTrigger(Duration(seconds: 10), ZoneId.UTC);
      final task1 = SimpleScheduledTask(() {}, trigger1, 'testTask');
      final task2 = SimpleScheduledTask(() {}, trigger2, 'testTask');
      expect(task1, equals(task2));
    });

    test('should have correct string representation', () {
      final trigger = FixedRateTrigger(Duration(seconds: 10), ZoneId.UTC);
      final task = SimpleScheduledTask(() {}, trigger, 'testTask');
      final str = task.toString();
      expect(str, contains('SimpleScheduledTask'));
      expect(str, contains('testTask'));
      expect(str, contains('canceled: false'));
      expect(str, contains('executing: false'));
    });
  });
}
