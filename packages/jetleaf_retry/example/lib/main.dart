// ignore_for_file: avoid_print

import 'dart:async';

import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_retry/jetleaf_retry.dart';

class UnstablePaymentService implements RetryCallback<String> {
  int attempts = 0;

  @override
  FutureOr<String> execute(RetryContext context) {
    attempts++;
    print('  [Attempt $attempts] Processing payment transaction...');
    if (attempts < 2) {
      throw TimeoutException('Gateway timeout on attempt $attempts');
    }
    return 'SUCCESS_TX_98765';
  }

  @override
  void setApplicationEventBus(ApplicationEventBus eventBus) {}
}

class PaymentFallbackRecovery implements RecoveryCallback<String> {
  @override
  FutureOr<String> recover(RetryContext context) {
    print('  [Fallback] All retries exhausted. Routing to offline queue.');
    return 'QUEUED_FOR_OFFLINE_PROCESSING';
  }
}

void main() async {
  print('========================================================');
  print('  🍃 Jetleaf Retry 2.0.0 Resilience Showcase');
  print('========================================================\n');

  // 1. Exponential Backoff Policy
  print('[1] Exponential Backoff Calculation:');
  final backoffPolicy = ExponentialBackoffPolicy();
  const backoffConfig = Backoff(delay: 50, multiplier: 2.0, maxDelay: 500);
  backoffPolicy.backoff(backoffConfig);

  final retryContext = SimpleRetryContext();
  for (var i = 1; i <= 3; i++) {
    final delay = backoffPolicy.computeBackoff(retryContext);
    print('  Calculated Backoff Delay (Attempt $i): ${delay.inMilliseconds} ms');
    retryContext.registerException(TimeoutException('Transient failure'));
  }

  // 2. Retry Execution with Automatic Transient Recovery
  print('\n[2] Executing Transient Operation with RetryExecutor:');
  final stats = InMemoryStatistics();
  final fixedBackoff = FixedBackoffPolicy();
  fixedBackoff.backoff(const Backoff(delay: 20));

  final executor = DefaultRetryExecutor()
    ..withRetryPolicy(SimpleRetryPolicy())
    ..withBackoffPolicy(fixedBackoff)
    ..withStatistics(stats);

  final paymentService = UnstablePaymentService();
  final result = await executor.execute<String>(
    paymentService,
    PaymentFallbackRecovery(),
    SimpleRetryContext(),
  );

  print('Transaction Result: $result');
  print('Retry Statistics: Started=${stats.getStartedCount()}, Success=${stats.getSuccessCount()}');

  print('\n========================================================');
  print('  ✅ Jetleaf Retry Example executed successfully!');
  print('========================================================');
}
