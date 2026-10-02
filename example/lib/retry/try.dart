import 'dart:async';
// import 'dart:math';

import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_retry/jetleaf_retry.dart';
import 'package:jetleaf_web/jetleaf_web.dart';

@Service()
@RequiredAll()
class RetryTestService {
  final RestClient rest;

  // int _attemptCount = 0;

  RetryTestService(this.rest);

  // ─────────────────────────────────────────────────────────────
  // Example: Retryable GET request
  // ─────────────────────────────────────────────────────────────
  @Retryable(
    maxAttempts: 5,
    backoff: Backoff(delay: 500, multiplier: 2.0, maxDelay: 5000),
    retryFor: [Exception],
    label: 'ping-server',
  )
  Future<void> pingServerWithRetry() async {
    // _attemptCount++;
    // print('⏰ [RetryTestService] Attempt $_attemptCount: pingServerWithRetry()');

    // // Fail the first 3 attempts intentionally
    // if (_attemptCount <= 3) {
    //   print('❌ [pingServerWithRetry] Simulated failure on attempt $_attemptCount');
    //   throw Exception('Simulated failure on attempt $_attemptCount');
    // }

    // // 4th attempt onwards succeeds
    // final response = await rest
    //     .get()
    //     .uri('https://httpbin.org/get', query: {'retry': 'true'})
    //     .execute((resp) async => resp.getBody().readAsString());

    // print('✅ [pingServerWithRetry] Success on attempt $_attemptCount, response: $response');
  }

  // ─────────────────────────────────────────────────────────────
  // Recovery method for pingServerWithRetry
  // ─────────────────────────────────────────────────────────────
  @Recover(label: 'ping-server')
  Future<void> pingServerRecovery(Exception e) async {
    // print('⚠️ [RetryTestService] Recovery triggered for pingServerWithRetry: $e');
    // // Optionally, fallback to cache, log, or alert
    // await Future.delayed(Duration(milliseconds: 200));
    // print('✅ [pingServerRecovery] Fallback logic completed');
  }

  // ─────────────────────────────────────────────────────────────
  // Example: Retryable POST request with payload
  // ─────────────────────────────────────────────────────────────
  @Retryable(
    maxAttempts: 3,
    backoff: Backoff(delay: 1000, multiplier: 1.5, maxDelay: 3000),
    retryFor: [Exception],
    label: 'heartbeat',
  )
  Future<void> sendHeartbeatWithRetry() async {
    // print('⏰ [RetryTestService] Sending heartbeat with retry');

    // if (Random().nextBool()) {
    //   print('❌ [sendHeartbeatWithRetry] Simulated transient failure');
    //   throw Exception('Transient failure for retry demonstration');
    // }

    // final body = {
    //   'service': 'RetryTestService',
    //   'timestamp': DateTime.now().toIso8601String(),
    //   'status': 'alive'
    // };

    // final response = await rest
    //     .post()
    //     .uri('https://httpbin.org/post')
    //     .body(body)
    //     .execute((resp) async => resp.getBody().readAsString());

    // print('✅ [sendHeartbeatWithRetry] Response: $response');
  }

  // ─────────────────────────────────────────────────────────────
  // Optional recovery for heartbeat
  // ─────────────────────────────────────────────────────────────
  @Recover(label: 'heartbeat')
  Future<void> heartbeatRecovery(Exception e) async {
    // print('⚠️ [RetryTestService] Recovery triggered for sendHeartbeatWithRetry: $e');
    // await Future.delayed(Duration(milliseconds: 200));
    // print('✅ [heartbeatRecovery] Fallback completed');
  }
}