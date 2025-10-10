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

import 'dart:async';

import 'package:jetleaf_lang/lang.dart';

/// {@template exception_handler}
/// A global uncaught exception handler for JetLeaf that integrates with Dart's [Zone] system.
///
/// This class provides:
/// - Thread-local tracking of uncaught exceptions
/// - Exit code registration for critical failures
/// - Filtering of already logged or known log-related exceptions
///
/// It ensures that only unhandled, significant exceptions are escalated to a parent handler
/// and optionally terminates the process via [System.exit].
///
/// ### Example
/// ```dart
/// void main() {
///   runZonedGuarded(() {
///     // Your JetLeaf app logic
///     throw Exception("Unexpected error");
///   }, ExceptionHandler.current.uncaughtException);
/// }
/// ```
/// {@endtemplate}
class ApplicationExceptionHandler {
  static final Set<String> _logConfigurationMessages = {
    "Logback configuration error detected",
    "Logging initialization failed",
    "Could not initialize logging",
  };

  int _exitCode = 0;
  final List<Throwable> _loggedExceptions = [];
  static final ApplicationExceptionHandler _default = ApplicationExceptionHandler();
  static final LocalThread<ApplicationExceptionHandler> _handlerLocal = LocalThread<ApplicationExceptionHandler>();

  final void Function(Object error, StackTrace stack)? _parentHandler;

  /// {@macro exception_handler}
  ///
  /// If a [_parentHandler] is passed, uncaught exceptions may be delegated to it.
  ApplicationExceptionHandler([this._parentHandler]);

  /// Registers an exception as already logged to avoid duplicate handling.
  ///
  /// ### Example
  /// ```dart
  /// final handler = JetLeafExceptionHandler.current;
  /// handler.registerLoggedException(someThrowable);
  /// ```
  void registerLoggedException(Throwable exception) {
    // avoid duplicates (linear scan but small list; if large, switch to HashSet with identity)
    if (!_loggedExceptions.contains(exception)) {
      _loggedExceptions.add(exception);
    }
  }

  /// Registers an exit code that will be used when an uncaught exception is encountered.
  ///
  /// ### Example
  /// ```dart
  /// JetLeafExceptionHandler.current.registerExitCode(1);
  /// ```
  void registerExitCode(int code) {
    _exitCode = code;
  }

  /// Returns the [ApplicationExceptionHandler] associated with the current isolate (thread-local).
  ///
  /// If none exists yet, it initializes a new one with [Zone.current.handleUncaughtError].
  ///
  /// ### Example
  /// ```dart
  /// JetLeafExceptionHandler handler = JetLeafExceptionHandler.current;
  /// ```
  static ApplicationExceptionHandler get current {
    ApplicationExceptionHandler? handler = _handlerLocal.get();
    if (handler == null) {
      handler = _handlerLocal.get() ?? _default;
      _handlerLocal.set(handler);
    }
    return handler;
  }

  /// Handles uncaught exceptions thrown within a Dart [Zone].
  ///
  /// Wraps Dart native [Exception], [Error], or other thrown objects into [Throwable],
  /// and checks whether they should be passed to the parent handler or suppressed.
  ///
  /// If an exit code was registered via [registerExitCode], it invokes [System.exit].
  ///
  /// ### Example (Used in `runZonedGuarded`)
  /// ```dart
  /// runZonedGuarded(() {
  ///   throw 'Critical error!';
  /// }, JetLeafExceptionHandler.current.uncaughtException);
  /// ```
  void uncaughtException(Object exception, StackTrace stackTrace) {
    Throwable? th;
    if (exception is Throwable) {
      th = exception;
    } else if (exception is Exception || exception is Error) {
      th = RuntimeException(exception.toString(), cause: exception, stackTrace: stackTrace);
    } else {
      th = RuntimeException('Unknown uncaught object thrown: $exception', stackTrace: stackTrace);
    }

    try {
      if (_shouldPassToParent(th) && _parentHandler != null) {
        _parentHandler(th, stackTrace);
      }
    } finally {
      _loggedExceptions.clear();
      if (_exitCode != 0) {
        System.exit(_exitCode);
      }
    }
  }

  /// Determines whether the error should be passed to the parent error handler.
  bool _shouldPassToParent(Throwable error) => _isLogConfigurationMessage(error) || !_isRegistered(error);

  /// Checks if the error message indicates a known log-related error.
  bool _isLogConfigurationMessage(Throwable ex) {
    // identity-based visited set to break cycles
    final visited = HashSet<Throwable>();
    Throwable? current = ex;

    while (current != null && visited.add(current)) {
      final message = current.getMessage();
      if (message.isNotEmpty) {
        for (final candidate in _logConfigurationMessages) {
          if (message.contains(candidate)) return true;
        }
      }
      final cause = current.getCause();
      current = (cause is Throwable) ? cause : null;
    }
    return false;
  }

  /// Recursively checks if the exception or its cause is already registered.
  bool _isRegistered(Throwable ex) {
    // Fast path
    if (_loggedExceptions.contains(ex)) return true;

    final visited = HashSet<Throwable>();
    Throwable? current = ex;

    while (current != null && visited.add(current)) {
      if (_loggedExceptions.contains(current)) return true;
      final cause = current.getCause();
      current = (cause is Throwable) ? cause : null;
    }
    return false;
  }
}