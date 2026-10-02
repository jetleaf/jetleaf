import 'package:test/test.dart';
import 'package:jetleaf/jetleaf.dart';

void main() {
  group('ApplicationExceptionHandler', () {
    late ApplicationExceptionHandler handler;

    setUp(() {
      handler = ApplicationExceptionHandler();
    });

    test('should create with default constructor', () {
      expect(handler, isNotNull);
    });

    test('should create with parent handler', () {
      final handler = ApplicationExceptionHandler((error, stack) {});
      expect(handler, isNotNull);
    });

    test('should register logged exception', () {
      final exception = IllegalStateException('test');
      handler.registerLoggedException(exception);
      // Should not throw
    });

    test('should register exit code', () {
      handler.registerExitCode(1);
      // Should not throw
    });

    test('should get current handler', () {
      final current = ApplicationExceptionHandler.current;
      expect(current, isNotNull);
      expect(current, isA<ApplicationExceptionHandler>());
    });

    test('current should return same instance', () {
      final current1 = ApplicationExceptionHandler.current;
      final current2 = ApplicationExceptionHandler.current;
      expect(identical(current1, current2), isTrue);
    });

    test('should handle throwable in uncaughtException', () {
      final exception = IllegalStateException('test error');
      // Should not throw
      handler.uncaughtException(exception, StackTrace.current);
    });

    test('should handle non-throwable in uncaughtException', () {
      // Should wrap in RuntimeException
      handler.uncaughtException('string error', StackTrace.current);
    });

    test('should handle exception in uncaughtException', () {
      handler.uncaughtException(
        Exception('test exception'),
        StackTrace.current,
      );
    });

    test('should handle error in uncaughtException', () {
      handler.uncaughtException(
        StateError('test error'),
        StackTrace.current,
      );
    });

    test('should pass log config errors to parent', () {
      var parentCalled = false;
      final handler = ApplicationExceptionHandler((error, stack) {
        parentCalled = true;
      });
      final exception = IllegalStateException(
        'Logback configuration error detected',
      );
      handler.uncaughtException(exception, StackTrace.current);
      expect(parentCalled, isTrue);
    });

    test('should not pass non-config errors to parent if registered', () {
      var parentCalled = false;
      final handler = ApplicationExceptionHandler((error, stack) {
        parentCalled = true;
      });
      final exception = IllegalStateException('regular error');
      handler.registerLoggedException(exception);
      handler.uncaughtException(exception, StackTrace.current);
      expect(parentCalled, isFalse);
    });
  });
}
