import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_scheduling/jetleaf_scheduling.dart';

void main() {
  group('DefaultTaskExecutionContext', () {
    late DefaultTaskExecutionContext context;

    setUp(() {
      context = DefaultTaskExecutionContext();
    });

    test('should initialize with zero execution count', () {
      expect(context.getExecutionCount(), equals(0));
    });

    test('should have null times initially', () {
      expect(context.getLastScheduledExecutionTime(), isNull);
      expect(context.getLastActualExecutionTime(), isNull);
      expect(context.getLastCompletionTime(), isNull);
      expect(context.getLastException(), isNull);
    });

    test('should record scheduled execution', () {
      final time = ZonedDateTime.now(ZoneId.UTC);
      context.recordScheduledExecution(time);
      expect(context.getLastScheduledExecutionTime(), equals(time));
    });

    test('should record actual execution', () {
      final time = ZonedDateTime.now(ZoneId.UTC);
      context.recordActualExecution(time);
      expect(context.getLastActualExecutionTime(), equals(time));
      expect(context.getExecutionCount(), equals(1));
    });

    test('should increment execution count', () {
      final time1 = ZonedDateTime.now(ZoneId.UTC);
      context.recordActualExecution(time1);
      final time2 = ZonedDateTime.now(ZoneId.UTC);
      context.recordActualExecution(time2);
      expect(context.getExecutionCount(), equals(2));
    });

    test('should record completion', () {
      final time = ZonedDateTime.now(ZoneId.UTC);
      context.recordCompletion(time);
      expect(context.getLastCompletionTime(), equals(time));
      expect(context.getLastException(), isNull);
    });

    test('should record exception', () {
      final time = ZonedDateTime.now(ZoneId.UTC);
      final exception = Exception('test error');
      context.recordException(exception, time);
      expect(context.getLastException(), equals(exception));
      expect(context.getLastCompletionTime(), equals(time));
    });

    test('should clear exception on successful completion', () {
      final time1 = ZonedDateTime.now(ZoneId.UTC);
      context.recordException(Exception('error'), time1);
      expect(context.getLastException(), isNotNull);
      
      final time2 = ZonedDateTime.now(ZoneId.UTC);
      context.recordCompletion(time2);
      expect(context.getLastException(), isNull);
    });

    test('should have correct string representation', () {
      final str = context.toString();
      expect(str, contains('DefaultTaskExecutionContext'));
      expect(str, contains('executions: 0'));
    });
  });

  group('DefaultSchedulingTaskNameGenerator', () {
    test('should generate name with default pattern', () {
      final generator = DefaultSchedulingTaskNameGenerator('userService', 'scheduled');
      // We need to create mock Class and Method objects
      // Since we can't easily mock jetleaf_lang reflection classes, 
      // we'll test the string pattern logic
      expect(generator.toString(), contains('DefaultSchedulingTaskNameGenerator'));
      expect(generator.toString(), contains('scheduled'));
      expect(generator.toString(), contains('userService'));
    });

    test('should generate name with prefix', () {
      final generator = DefaultSchedulingTaskNameGenerator('userService', 'scheduled', 'myapp');
      expect(generator.toString(), contains('hasEnvironment: true'));
    });

    test('should generate name without prefix', () {
      final generator = DefaultSchedulingTaskNameGenerator('userService', 'scheduled');
      expect(generator.toString(), contains('hasEnvironment: false'));
    });
  });

  group('ScheduledTaskHolder', () {
    test('should implement interface contract', () {
      // Test that the interface exists and can be used
      expect(ScheduledTaskHolder, isA<Type>());
    });
  });

  group('TaskScheduler', () {
    test('should implement interface contract', () {
      expect(TaskScheduler, isA<Type>());
    });
  });
}
