// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

/// {@template exception_reporter}
/// Signature for a function that reports a [Exception] and returns
/// a boolean indicating whether the exception was successfully handled.
///
/// This allows pluggable exception handlers in the JetLeaf framework.
///
/// Returns `true` if the exception was handled, `false` otherwise.
///
/// Example:
/// ```dart
/// final reporter = (Exception e) {
///   log.error('Exception occurred: $e');
///   return true; // handled
/// };
/// ```
/// {@endtemplate}
typedef ExceptionReporter = bool Function(Exception exception);

/// {@template exception_reporter_extension}
/// Extension on [ExceptionReporter] that adds a method-style
/// interface for reporting exceptions.
///
/// Allows invoking the function using `reporter.reportException(e)`
/// instead of `reporter(e)`.
///
/// Example:
/// ```dart
/// final reporter = (e) => print('Handled: $e');
/// reporter.reportException(Exception('Oops'));
/// ```
/// {@endtemplate}
extension ExceptionReporterExtension on ExceptionReporter {
  /// {@macro exception_reporter_extension}
  bool reportException(Exception exception) => this(exception);
}