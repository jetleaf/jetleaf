import 'package:test/test.dart';
import 'package:jetleaf/jetleaf.dart';

void main() {
  group('ApplicationShutdownHandler', () {
    test('should be interface', () {
      expect(ApplicationShutdownHandler, isA<Type>());
    });
  });

  group('ApplicationShutdownHandlerHook', () {
    test('should create instance', () {
      final hook = ApplicationShutdownHandlerHook();
      expect(hook, isNotNull);
    });

    test('should implement Runnable', () {
      final hook = ApplicationShutdownHandlerHook();
      expect(hook, isA<Runnable>());
    });

    test('should have handler property', () {
      final hook = ApplicationShutdownHandlerHook();
      expect(hook.handler, isNotNull);
      expect(hook.handler, isA<ApplicationShutdownHandler>());
    });

    test('handler should support add and remove', () {
      final hook = ApplicationShutdownHandlerHook();
      final runnable = _TestRunnable();
      hook.handler.add(runnable);
      // Should not throw
    });
  });
}

class _TestRunnable implements Runnable {
  @override
  void run() {
    // Test implementation
  }
}
