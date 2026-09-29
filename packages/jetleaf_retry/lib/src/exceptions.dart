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

import 'package:jetleaf_lang/lang.dart';

import 'base/retry_context.dart';

/// {@template retry_exhausted_exception}
/// Exception thrown when all retry attempts for a [Retryable] operation
/// have been exhausted without success.
///
/// This indicates that the configured [RetryPolicy] has reached its maximum
/// number of retry attempts (or other terminal condition), and the operation
/// could not be successfully completed even after applying the associated
/// [BackoffPolicy].
///
/// ### Typical Causes
/// - Persistent network or I/O failures.
/// - Non-recoverable exceptions not handled by a [Recover] method.
/// - Misconfiguration of retry limits or transient exception types.
///
/// ### Structure
/// This exception provides detailed diagnostic context:
/// - The **original exception** that caused the final failure ([cause])
/// - The **retry context** ([RetryContext]) containing attempt count,
///   last exception, and policy data.
///
/// ### Example
/// ```dart
/// try {
///   await retryExecutor.execute(() => httpClient.get('/resource'));
/// } on RetryExhaustedException catch (ex) {
///   logger.error('Retry failed after ${ex.context.getAttemptCount()} attempts', error: ex.cause);
/// }
/// ```
///
/// ### Notes
/// This exception is typically thrown internally by Jetleaf’s resilience
/// subsystem and propagated to the caller when recovery is not possible.
/// {@endtemplate}
final class RetryExhaustedException extends RuntimeException {
  /// The retry context associated with the failed operation.
  ///
  /// Contains metadata such as:
  /// - The total number of attempts made.
  /// - The most recent exception.
  /// - Any contextual attributes set during retry processing.
  final RetryContext context;

  /// {@macro retry_exhausted_exception}
  RetryExhaustedException(super.message, this.context, {super.cause});

  @override
  String toString() {
    return 'RetryExhaustedException: $message\n'
        'Attempts: ${context.getAttemptCount()}\n'
        'Last exception: $cause';
  }
}