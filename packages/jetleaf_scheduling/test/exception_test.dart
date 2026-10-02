import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_scheduling/jetleaf_scheduling.dart';

void main() {
  group('SchedulerException', () {
    test('should create with message', () {
      final exception = SchedulerException('Test error');
      expect(exception.message, equals('Test error'));
      expect(exception.cause, isNull);
    });

    test('should create with message and cause', () {
      const cause = 'root cause';
      final exception = SchedulerException('Test error', cause: cause);
      expect(exception.message, equals('Test error'));
      expect(exception.cause, equals(cause));
    });

    test('should be a RuntimeException', () {
      final exception = SchedulerException('Test error');
      expect(exception, isA<RuntimeException>());
    });

    test('should have correct string representation', () {
      final exception = SchedulerException('Test error');
      expect(exception.toString(), contains('SchedulerException'));
      expect(exception.toString(), contains('Test error'));
    });
  });

  group('InvalidCronExpressionException', () {
    test('should create with message and expression', () {
      final exception = InvalidCronExpressionException('Invalid syntax', 'invalid * * *');
      expect(exception.message, equals('Invalid syntax'));
      expect(exception.expression, equals('invalid * * *'));
    });

    test('should be a SchedulerException', () {
      final exception = InvalidCronExpressionException('Invalid', '* * *');
      expect(exception, isA<SchedulerException>());
    });

    test('should have correct string representation', () {
      final exception = InvalidCronExpressionException('Invalid syntax', 'invalid * * *');
      expect(exception.toString(), contains('InvalidCronExpressionException'));
      expect(exception.toString(), contains('Invalid syntax'));
      expect(exception.toString(), contains('invalid * * *'));
    });

    test('should preserve expression in cause', () {
      const expression = '0 0 * * * * *';
      final exception = InvalidCronExpressionException('Too many fields', expression);
      expect(exception.cause, equals(expression));
    });
  });

  group('TaskExecutionException', () {
    test('should create with task name and message', () {
      final exception = TaskExecutionException('myTask', 'Execution failed');
      expect(exception.taskName, equals('myTask'));
      expect(exception.message, equals('Execution failed'));
      expect(exception.cause, isNull);
    });

    test('should create with task name, message, and cause', () {
      const cause = 'underlying error';
      final exception = TaskExecutionException('myTask', 'Execution failed', cause: cause);
      expect(exception.taskName, equals('myTask'));
      expect(exception.message, equals('Execution failed'));
      expect(exception.cause, equals(cause));
    });

    test('should be a SchedulerException', () {
      final exception = TaskExecutionException('myTask', 'Error');
      expect(exception, isA<SchedulerException>());
    });

    test('should have correct string representation', () {
      final exception = TaskExecutionException('myTask', 'Execution failed');
      expect(exception.toString(), contains('TaskExecutionException'));
      expect(exception.toString(), contains('myTask'));
      expect(exception.toString(), contains('Execution failed'));
    });

    test('should include cause in string representation when present', () {
      const cause = 'underlying error';
      final exception = TaskExecutionException('myTask', 'Execution failed', cause: cause);
      expect(exception.toString(), contains('underlying error'));
    });
  });
}
