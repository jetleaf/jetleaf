import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_retry/jetleaf_retry.dart';

void main() {
  group('RetryExhaustedException', () {
    test('should create with message and context', () {
      final context = SimpleRetryContext('testOp');
      context.registerException(Exception('fail1'));
      context.registerException(Exception('fail2'));

      final exception = RetryExhaustedException('Retries exhausted', context);
      expect(exception.message, equals('Retries exhausted'));
      expect(exception.context, equals(context));
      expect(exception.cause, isNull);
    });

    test('should create with message, context, and cause', () {
      final context = SimpleRetryContext();
      final cause = Exception('root cause');
      final exception = RetryExhaustedException('Failed', context, cause: cause);
      expect(exception.message, equals('Failed'));
      expect(exception.context, equals(context));
      expect(exception.cause, equals(cause));
    });

    test('should be a RuntimeException', () {
      final context = SimpleRetryContext();
      final exception = RetryExhaustedException('Error', context);
      expect(exception, isA<RuntimeException>());
    });

    test('should have correct string representation', () {
      final context = SimpleRetryContext();
      context.registerException(Exception('last error'));
      final exception = RetryExhaustedException('Retries exhausted', context, cause: Exception('root'));
      final str = exception.toString();
      expect(str, contains('RetryExhaustedException'));
      expect(str, contains('Retries exhausted'));
      expect(str, contains('Attempts: 1'));
    });

    test('should preserve context attempt count', () {
      final context = SimpleRetryContext();
      for (var i = 0; i < 5; i++) {
        context.registerException(Exception('error $i'));
      }
      final exception = RetryExhaustedException('Exhausted', context);
      expect(exception.context.getAttemptCount(), equals(5));
    });
  });
}
