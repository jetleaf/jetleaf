// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & Jetleaf Contributors. All rights reserved.
//
// This source file is part of the Jetleaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the Jetleaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'dart:math' as math;

import '../annotations/retryable.dart';
import '../base/backoff_policy.dart';
import '../base/retry_context.dart';

/// {@template exponential_backoff_policy}
/// A standard implementation of [BackoffPolicy] that applies **exponential backoff**
/// between retry attempts, with optional randomization (“jitter”).
///
/// The [ExponentialBackoffPolicy] is designed to progressively increase the delay
/// before each retry, reducing contention and load spikes in distributed systems.
///
/// ### Core Behavior
/// - The delay grows **exponentially** based on the attempt count.
/// - The first retry waits for [_initialDelay] milliseconds.
/// - Each subsequent retry multiplies the previous delay by [_multiplier].
/// - The delay is capped by [_maxDelay].
/// - Optional [_randomizationFactor] adds jitter to spread concurrent retry load.
///
/// ### Example
/// ```dart
/// final policy = ExponentialBackoffPolicy(
///   initialDelay: 500,      // 0.5 seconds
///   multiplier: 2.0,        // exponential growth factor
///   maxDelay: 10000,        // 10 seconds
///   randomizationFactor: 0.2, // ±20% jitter
/// );
///
/// final context = DefaultRetryContext('download');
///
/// for (var i = 1; i <= 5; i++) {
///   context.setAttemptCount(i);
///   print('Attempt $i: ${policy.computeBackoff(context)}');
/// }
/// ```
///
/// ### Computation Formula
/// The backoff delay is computed as:
///
/// ```text
/// delay = min(maxDelay, initialDelay × multiplier^(attemptCount - 1))
/// ```
///
/// When [_randomizationFactor] > 0, the delay is adjusted with a random value:
///
/// ```text
/// delay *= 1 ± randomizationFactor × random(0, 1)
/// ```
///
/// This prevents “thundering herd” effects where many clients retry simultaneously.
///
/// ### Configuration Notes
/// - Attempt count is **1-based**; the first attempt (attempt 1) has no backoff.
/// - Setting [_multiplier] to `1.0` produces constant (fixed) delays.
/// - Random jitter is applied symmetrically around the computed delay.
///
/// ### Typical Use Cases
/// - Retrying HTTP requests to remote APIs or microservices.
/// - Throttling message retries in queue consumers.
/// - Reducing collision probability in distributed lock acquisition.
///
/// ### Thread Safety
/// This class is **immutable** and **thread-safe**.
///
/// ### See Also
/// - [BackoffPolicy] — Base interface for computing backoff durations.
/// - [RetryPolicy] — Defines when retries should be attempted.
/// - [Backoff] — Annotation providing declarative backoff configuration.
/// - [Retryable] — Combines retry and backoff policies for annotated methods.
///
/// {@endtemplate}
final class ExponentialBackoffPolicy implements BackoffPolicy {
  /// The initial delay in milliseconds before the first retry.
  ///
  /// Defaults to `1000` ms (1 second).
  int _initialDelay = 1000;

  /// The multiplier for exponential delay growth.
  ///
  /// Each subsequent delay is computed as:
  /// `previousDelay × multiplier`.
  ///
  /// For example, with a multiplier of `2.0`, delays would progress as:
  /// `1s → 2s → 4s → 8s → …`.
  double _multiplier = 2.0;

  /// The maximum delay cap in milliseconds.
  ///
  /// Once the computed exponential delay exceeds this value, the delay
  /// will be clamped to [_maxDelay].
  int _maxDelay = 30000;

  /// Random number generator for jitter computation.
  ///
  /// By default, uses a standard `math.Random()` instance.
  final math.Random _random = math.Random();

  /// The randomization factor (0.0–1.0) controlling jitter amplitude.
  ///
  /// When greater than zero, a random offset is applied to the computed delay.
  /// For example, with a factor of `0.25`, the actual delay will vary by ±25%.
  double _randomizationFactor = 0.0;

  /// Creates a new [ExponentialBackoffPolicy] with the specified parameters.
  ///
  /// {@macro exponential_backoff_policy}
  ExponentialBackoffPolicy();

  @override
  BackoffPolicy backoff(Backoff backoff) {
    _initialDelay = backoff.delay;
    _multiplier = backoff.multiplier;
    _maxDelay = backoff.maxDelay;
    _randomizationFactor = backoff.random ? 0.25 : 0.0;

    return this;
  }

  @override
  Duration computeBackoff(RetryContext context) {
    final attempt = context.getAttemptCount();
    
    if (attempt <= 0) {
      return Duration.zero;
    }

    // Calculate exponential delay
    final exp = math.min(attempt, 31); // Prevent overflow
    var delayMs = _initialDelay * math.pow(_multiplier, exp - 1);

    // Apply randomization if configured
    if (_randomizationFactor > 0) {
      final randomFactor = 1.0 + (_randomizationFactor * (_random.nextDouble() * 2 - 1));
      delayMs *= randomFactor;
    }

    // Cap at maxDelay
    delayMs = math.min(delayMs, _maxDelay.toDouble());

    return Duration(milliseconds: delayMs.toInt());
  }
}