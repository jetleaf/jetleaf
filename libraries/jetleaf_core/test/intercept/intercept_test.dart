import 'package:jetleaf_core/intercept.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

void main() {
  group('SimpleMethodInvocation', () {
    test('proceed executes the request and caches result', () async {
      final targetClass = Class<String>();
      final method = targetClass.getMethod('compareTo')!;
      final invocation = SimpleMethodInvocation<String>(
        'hello',
        targetClass,
        method,
        null,
        () async => 'result',
      );

      expect(invocation.isInvoked(), isFalse);
      final result = await invocation.proceed();
      expect(result, equals('result'));
      expect(invocation.isInvoked(), isTrue);

      // Second call returns cached result without re-executing
      final result2 = await invocation.proceed();
      expect(result2, equals('result'));
    });

    test('hijack short-circuits and caches value', () async {
      final targetClass = Class<String>();
      final method = targetClass.getMethod('compareTo')!;
      var executed = false;
      final invocation = SimpleMethodInvocation<String>(
        'hello',
        targetClass,
        method,
        null,
        () async {
          executed = true;
          return 'result';
        },
      );

      await invocation.hijack('hijacked');
      expect(invocation.isInvoked(), isTrue);
      expect(executed, isFalse);

      final result = await invocation.proceed();
      expect(result, equals('hijacked'));
    });

    test('flush resets state', () async {
      final targetClass = Class<String>();
      final method = targetClass.getMethod('compareTo')!;
      final invocation = SimpleMethodInvocation<String>(
        'hello',
        targetClass,
        method,
        null,
        () async => 'result',
      );

      await invocation.proceed();
      expect(invocation.isInvoked(), isTrue);

      await invocation.flush();
      expect(invocation.isInvoked(), isFalse);
    });

  });

  group('Interceptable', () {
    test('delegates to support when set', () async {
      final service = _TestInterceptable();
      expect(service.support, isNull);

      // Without support, executes directly
      final result = await service.doSomething();
      expect(result, equals('direct'));
    });
  });

  group('InterceptorDependencyCycle', () {
    test('throws when fewer than 3 elements', () {
      expect(
        () => InterceptorDependencyCycle(['A', 'A']),
        throwsA(isA<IllegalArgumentException>()),
      );
    });

    test('throws when first != last', () {
      expect(
        () => InterceptorDependencyCycle(['A', 'B', 'C']),
        throwsA(isA<IllegalArgumentException>()),
      );
    });

    test('toString includes cycle path', () {
      final cycle = InterceptorDependencyCycle(['A', 'B', 'C', 'A']);
      expect(cycle.toString(), contains('A → B → C → A'));
    });
  });
}

class _TestInterceptable with Interceptable {
  Future<String> doSomething() {
    return when(() async => 'direct', this, 'doSomething');
  }
}