import 'dart:async';

import 'package:test/test.dart';
import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_retry/jetleaf_retry.dart';

void main() {
  group('InMemoryStatistics', () {
    late InMemoryStatistics stats;

    setUp(() {
      stats = InMemoryStatistics();
    });

    test('should initialize with zero counts', () {
      expect(stats.getStartedCount(), equals(0));
      expect(stats.getSuccessCount(), equals(0));
      expect(stats.getExhaustedCount(), equals(0));
      expect(stats.getRecoveryCount(), equals(0));
    });

    test('should increment started count', () {
      stats.incrementStarted();
      expect(stats.getStartedCount(), equals(1));
      stats.incrementStarted();
      expect(stats.getStartedCount(), equals(2));
    });

    test('should increment success count', () {
      stats.incrementSuccess();
      expect(stats.getSuccessCount(), equals(1));
    });

    test('should increment exhausted count', () {
      stats.incrementExhausted();
      expect(stats.getExhaustedCount(), equals(1));
    });

    test('should increment recovery count', () {
      stats.incrementRecovery();
      expect(stats.getRecoveryCount(), equals(1));
    });

    test('should reset all counters', () {
      stats.incrementStarted();
      stats.incrementSuccess();
      stats.incrementExhausted();
      stats.incrementRecovery();
      stats.reset();
      expect(stats.getStartedCount(), equals(0));
      expect(stats.getSuccessCount(), equals(0));
      expect(stats.getExhaustedCount(), equals(0));
      expect(stats.getRecoveryCount(), equals(0));
    });

    test('should ignore count parameter in increment methods', () {
      stats.incrementStarted(5);
      expect(stats.getStartedCount(), equals(1));
      stats.incrementSuccess(10);
      expect(stats.getSuccessCount(), equals(1));
    });
  });

  group('SimpleRetryContext', () {
    test('should create without name', () {
      final context = SimpleRetryContext();
      expect(context.getName(), isNull);
      expect(context.getAttemptCount(), equals(0));
      expect(context.getLastException(), isNull);
    });

    test('should create with name', () {
      final context = SimpleRetryContext('myOperation');
      expect(context.getName(), equals('myOperation'));
    });

    test('should register exception and increment attempt count', () {
      final context = SimpleRetryContext();
      final exception = Exception('error 1');
      context.registerException(exception);
      expect(context.getAttemptCount(), equals(1));
      expect(context.getLastException(), equals(exception));
    });

    test('should track multiple exceptions', () {
      final context = SimpleRetryContext();
      final ex1 = Exception('error 1');
      final ex2 = Exception('error 2');
      context.registerException(ex1);
      context.registerException(ex2);
      expect(context.getAttemptCount(), equals(2));
      expect(context.getLastException(), equals(ex2));
    });

    test('should store and retrieve attributes', () {
      final context = SimpleRetryContext();
      context.setAttribute('key1', 'value1');
      context.setAttribute('key2', 42);
      expect(context.getAttribute('key1'), equals('value1'));
      expect(context.getAttribute('key2'), equals(42));
      expect(context.getAttribute('nonexistent'), isNull);
    });

    test('should overwrite attribute with same key', () {
      final context = SimpleRetryContext();
      context.setAttribute('key', 'value1');
      context.setAttribute('key', 'value2');
      expect(context.getAttribute('key'), equals('value2'));
    });
  });

  group('SimpleRetryPolicy', () {
    late SimpleRetryPolicy policy;

    setUp(() {
      policy = SimpleRetryPolicy();
    });

    test('should allow retry when under max attempts', () {
      final context = SimpleRetryContext();
      context.registerException(Exception('error'));
      expect(policy.canRetry(context), isTrue);
    });

    test('should not allow retry when at max attempts', () {
      final context = SimpleRetryContext();
      // Default maxAttempts is 3, so attempts 0, 1, 2 are allowed
      context.registerException(Exception('error 1')); // attempt 1
      context.registerException(Exception('error 2')); // attempt 2
      context.registerException(Exception('error 3')); // attempt 3
      expect(policy.canRetry(context), isFalse);
    });

    test('should configure from Retryable annotation', () {
      const retryable = Retryable(maxAttempts: 5);
      final result = policy.retryable(retryable);
      expect(result, equals(policy));
      // Now maxAttempts is 5, so 4 retries should be allowed
      final context = SimpleRetryContext();
      for (var i = 0; i < 4; i++) {
        context.registerException(Exception('error $i'));
      }
      expect(policy.canRetry(context), isTrue);
      context.registerException(Exception('error 4'));
      expect(policy.canRetry(context), isFalse);
    });

    test('should return false for shouldRetryForException when exhausted', () {
      final context = SimpleRetryContext();
      for (var i = 0; i < 3; i++) {
        context.registerException(Exception('error'));
      }
      expect(policy.shouldRetryForException(Exception('test'), context), isFalse);
    });

    test('should return false when retryableExceptions is empty', () {
      // When _retryableExceptions is empty, Set.any() returns false
      // This means shouldRetryForException returns false
      final context = SimpleRetryContext();
      context.registerException(Exception('error'));
      expect(policy.shouldRetryForException(Exception('test'), context), isFalse);
    });
  });

  group('FixedBackoffPolicy', () {
    test('should compute fixed backoff', () {
      final policy = FixedBackoffPolicy();
      const backoff = Backoff(delay: 2000);
      policy.backoff(backoff);
      final context = SimpleRetryContext();
      context.registerException(Exception('error'));
      expect(policy.computeBackoff(context), equals(Duration(milliseconds: 2000)));
    });

    test('should return same delay for all attempts', () {
      final policy = FixedBackoffPolicy();
      const backoff = Backoff(delay: 1000);
      policy.backoff(backoff);
      final context = SimpleRetryContext();
      final delay1 = policy.computeBackoff(context);
      context.registerException(Exception('error'));
      final delay2 = policy.computeBackoff(context);
      context.registerException(Exception('error'));
      final delay3 = policy.computeBackoff(context);
      expect(delay1, equals(delay2));
      expect(delay2, equals(delay3));
    });
  });

  group('ExponentialBackoffPolicy', () {
    test('should compute exponential backoff', () {
      final policy = ExponentialBackoffPolicy();
      const backoff = Backoff(delay: 1000, multiplier: 2.0, maxDelay: 30000, random: false);
      policy.backoff(backoff);
      final context = SimpleRetryContext();
      context.registerException(Exception('error')); // attempt 1
      final delay1 = policy.computeBackoff(context);
      expect(delay1.inMilliseconds, equals(1000));

      context.registerException(Exception('error')); // attempt 2
      final delay2 = policy.computeBackoff(context);
      expect(delay2.inMilliseconds, equals(2000));

      context.registerException(Exception('error')); // attempt 3
      final delay3 = policy.computeBackoff(context);
      expect(delay3.inMilliseconds, equals(4000));
    });

    test('should cap at maxDelay', () {
      final policy = ExponentialBackoffPolicy();
      const backoff = Backoff(delay: 1000, multiplier: 2.0, maxDelay: 5000, random: false);
      policy.backoff(backoff);
      final context = SimpleRetryContext();
      // Attempt 15 would be 1000 * 2^14 = 16,384,000 ms which exceeds maxDelay
      for (var i = 0; i < 15; i++) {
        context.registerException(Exception('error'));
      }
      final delay = policy.computeBackoff(context);
      expect(delay.inMilliseconds, lessThanOrEqualTo(5000));
    });

    test('should return Duration.zero for attempt 0', () {
      final policy = ExponentialBackoffPolicy();
      const backoff = Backoff(delay: 1000);
      policy.backoff(backoff);
      final context = SimpleRetryContext();
      // No exceptions registered, attempt count is 0
      final delay = policy.computeBackoff(context);
      expect(delay, equals(Duration.zero));
    });

    test('should apply randomization when random is true', () {
      final policy = ExponentialBackoffPolicy();
      const backoff = Backoff(delay: 1000, multiplier: 2.0, maxDelay: 30000, random: true);
      policy.backoff(backoff);
      final context = SimpleRetryContext();
      context.registerException(Exception('error'));
      // With randomization, delay should be within ±25% of 1000ms
      final delays = <int>{};
      for (var i = 0; i < 20; i++) {
        delays.add(policy.computeBackoff(context).inMilliseconds);
      }
      // Should have some variation (not all same value)
      expect(delays.length, greaterThan(1));
    });
  });

  group('DefaultRetryExecutor', () {
    late DefaultRetryExecutor executor;
    late SimpleRetryPolicy policy;
    late FixedBackoffPolicy backoffPolicy;
    late InMemoryStatistics statistics;

    setUp(() {
      policy = SimpleRetryPolicy();
      backoffPolicy = FixedBackoffPolicy();
      backoffPolicy.backoff(const Backoff(delay: 10)); // very fast for tests
      statistics = InMemoryStatistics();
      executor = DefaultRetryExecutor()
        ..withRetryPolicy(policy)
        ..withBackoffPolicy(backoffPolicy)
        ..withStatistics(statistics);
    });

    test('should execute successful callback', () async {
      final context = SimpleRetryContext();
      final callback = _SuccessfulCallback('result');
      final result = await executor.execute<String>(callback, null, context);
      expect(result, equals('result'));
      expect(statistics.getStartedCount(), equals(1));
      expect(statistics.getSuccessCount(), equals(1));
    });

    test('should throw RetryExhaustedException when retries exhausted', () async {
      final context = SimpleRetryContext();
      final callback = _AlwaysFailCallback();
      expect(
        () => executor.execute<String>(callback, null, context),
        throwsA(isA<RetryExhaustedException>()),
      );
      expect(statistics.getExhaustedCount(), equals(1));
    });

    test('should invoke recovery callback when retries exhausted', () async {
      final context = SimpleRetryContext();
      final callback = _AlwaysFailCallback();
      final recovery = _RecoveryCallback('fallback');
      final result = await executor.execute<String>(callback, recovery, context);
      expect(result, equals('fallback'));
      expect(statistics.getRecoveryCount(), equals(1));
    });

    test('should notify listeners on successful execution', () async {
      final context = SimpleRetryContext();
      final listener = _TestRetryListener();
      executor.withListeners([listener]);
      final callback = _SuccessfulCallback('result');
      await executor.execute<String>(callback, null, context);
      expect(listener.openCalled, isTrue);
      expect(listener.closeCalled, isTrue);
    });

    test('should notify listeners on exhausted retries', () async {
      final context = SimpleRetryContext();
      final listener = _TestRetryListener();
      executor.withListeners([listener]);
      final callback = _AlwaysFailCallback();
      try {
        await executor.execute<String>(callback, null, context);
      } catch (_) {}
      expect(listener.openCalled, isTrue);
      expect(listener.errorCalled, isTrue);
      expect(listener.closeCalled, isTrue);
    });

    test('should support fluent API', () {
      final executor2 = DefaultRetryExecutor()
        ..withRetryPolicy(SimpleRetryPolicy())
        ..withBackoffPolicy(FixedBackoffPolicy())
        ..withStatistics(InMemoryStatistics())
        ..withListeners([]);
      expect(executor2, isA<RetryExecutor>());
    });
  });
}

class _SuccessfulCallback implements RetryCallback<String> {
  final String _value;
  _SuccessfulCallback(this._value);

  @override
  FutureOr<String> execute(RetryContext context) => _value;

  @override
  void setApplicationEventBus(ApplicationEventBus eventBus) {}
}

class _AlwaysFailCallback implements RetryCallback<String> {
  @override
  FutureOr<String> execute(RetryContext context) {
    throw Exception('persistent error');
  }

  @override
  void setApplicationEventBus(ApplicationEventBus eventBus) {}
}

class _RecoveryCallback implements RecoveryCallback<String> {
  final String _fallback;
  _RecoveryCallback(this._fallback);

  @override
  FutureOr<String> recover(RetryContext context) => _fallback;
}

class _TestRetryListener implements RetryListener {
  bool openCalled = false;
  bool retryCalled = false;
  bool errorCalled = false;
  bool closeCalled = false;

  @override
  void onOpen(RetryContext context) => openCalled = true;

  @override
  void onRetry(RetryContext context) => retryCalled = true;

  @override
  void onError(RetryContext context, Exception exception) => errorCalled = true;

  @override
  void onClose(RetryContext context, Exception? lastException) => closeCalled = true;
}
