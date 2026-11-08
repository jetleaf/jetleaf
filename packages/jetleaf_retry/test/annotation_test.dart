import 'package:test/test.dart';
import 'package:jetleaf_retry/jetleaf_retry.dart';

void main() {
  group('Backoff', () {
    test('should create with default values', () {
      const backoff = Backoff();
      expect(backoff.delay, equals(1000));
      expect(backoff.multiplier, equals(2.0));
      expect(backoff.maxDelay, equals(30000));
      expect(backoff.random, isFalse);
    });

    test('should create with custom values', () {
      const backoff = Backoff(
        delay: 500,
        multiplier: 3.0,
        maxDelay: 60000,
        random: true,
      );
      expect(backoff.delay, equals(500));
      expect(backoff.multiplier, equals(3.0));
      expect(backoff.maxDelay, equals(60000));
      expect(backoff.random, isTrue);
    });

    test('should implement equality', () {
      const backoff1 = Backoff(delay: 500);
      const backoff2 = Backoff(delay: 500);
      const backoff3 = Backoff(delay: 1000);
      expect(backoff1, equals(backoff2));
      expect(backoff1 == backoff3, isFalse);
    });
  });

  group('Retryable', () {
    test('should create with default values', () {
      const retryable = Retryable();
      expect(retryable.maxAttempts, equals(3));
      expect(retryable.backoff, isA<Backoff>());
      expect(retryable.retryFor, isEmpty);
      expect(retryable.noRetryFor, isEmpty);
      expect(retryable.label, isNull);
      expect(retryable.listeners, isEmpty);
    });

    test('should create with custom values', () {
      const retryable = Retryable(
        maxAttempts: 5,
        backoff: Backoff(delay: 2000),
        retryFor: ['TimeoutException'],
        noRetryFor: ['FormatException'],
        label: 'myRetry',
        listeners: ['MyListener'],
      );
      expect(retryable.maxAttempts, equals(5));
      expect(retryable.backoff.delay, equals(2000));
      expect(retryable.retryFor, equals(['TimeoutException']));
      expect(retryable.noRetryFor, equals(['FormatException']));
      expect(retryable.label, equals('myRetry'));
      expect(retryable.listeners, equals(['MyListener']));
    });

    test('should have correct annotationType', () {
      const retryable = Retryable();
      expect(retryable.annotationType, equals(Retryable));
    });

    test('should implement equality', () {
      const r1 = Retryable(maxAttempts: 3);
      const r2 = Retryable(maxAttempts: 3);
      const r3 = Retryable(maxAttempts: 5);
      expect(r1, equals(r2));
      expect(r1 == r3, isFalse);
    });

    test('should have correct string representation', () {
      const retryable = Retryable(maxAttempts: 5, label: 'test');
      expect(retryable.toString(), contains('Retryable'));
    });
  });

  group('Recover', () {
    test('should create with default values', () {
      const recover = Recover();
      expect(recover.label, isNull);
    });

    test('should create with label', () {
      const recover = Recover(label: 'myRecovery');
      expect(recover.label, equals('myRecovery'));
    });

    test('should have correct annotationType', () {
      const recover = Recover();
      expect(recover.annotationType, equals(Recover));
    });

    test('should implement equality', () {
      const r1 = Recover(label: 'test');
      const r2 = Recover(label: 'test');
      const r3 = Recover(label: 'other');
      expect(r1, equals(r2));
      expect(r1 == r3, isFalse);
    });

    test('should have correct string representation', () {
      const recover = Recover(label: 'myRecovery');
      expect(recover.toString(), contains('Recover'));
    });
  });
}
