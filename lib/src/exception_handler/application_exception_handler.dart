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

/// {@template application_exception_handler}
/// A global, thread-safe handler for uncaught exceptions in JetLeaf applications.
///
/// The [ApplicationExceptionHandler] is responsible for intercepting all uncaught
/// exceptions thrown during the execution of the application, either synchronously
/// or asynchronously (within [Zone]s). It ensures that exceptions are:
/// 
/// 1. **Wrapped consistently**: Non-[Throwable] objects (e.g., [Exception], [Error])
///    are wrapped into [RuntimeException] for uniform handling.
/// 2. **De-duplicated**: Exceptions are tracked internally to avoid logging the
///    same exception multiple times, including nested causes.
/// 3. **Delegated**: Optionally forwarded to a parent handler provided via the
///    constructor for integration with external logging or error handling frameworks.
/// 4. **Terminating gracefully**: Supports registering a custom exit code that
///    terminates the application when a critical exception occurs.
/// 5. **Recognized**: Known logging-related errors (see [_logConfigurationMessages])
///    are detected and treated specially.
///
/// Thread-local storage ([_handlerLocal]) ensures that each Dart isolate can
/// maintain its own handler, providing isolated exception handling per execution
/// context. Use [current] to access the handler in the current isolate.
///
/// ## Example Usage
/// ```dart
/// void main() {
///   final handler = ApplicationExceptionHandler.current;
///   
///   runZonedGuarded(() {
///     throw Exception("Something went wrong!");
///   }, handler.uncaughtException);
/// }
/// ```
///
/// References:
/// - [Throwable]: Base class for exceptions in JetLeaf.
/// - [RuntimeException]: Wrapper for non-Throwable objects.
/// - [Zone]: Dart class for asynchronous exception handling.
/// - [_logConfigurationMessages]: Recognized log configuration error messages.
/// {@endtemplate}
class ApplicationExceptionHandler {
  /// Known log-related error messages that should always be passed
  /// to the parent handler if present.
  ///
  /// These include:
  /// - "Logback configuration error detected"
  /// - "Logging initialization failed"
  /// - "Could not initialize logging"
  static final Set<String> _logConfigurationMessages = {
    "Logback configuration error detected",
    "Logging initialization failed",
    "Could not initialize logging",
  };

  /// Exit code to be used when the application terminates due to an uncaught exception.
  /// Defaults to 0 (no exit).
  int _exitCode = 0;

  /// List of exceptions that have already been handled/logged.
  ///
  /// Used to prevent repeated logging of the same exception, including nested causes.
  final List<Throwable> _loggedExceptions = [];

  /// Singleton default handler used if no thread-local handler exists.
  static final ApplicationExceptionHandler _default = ApplicationExceptionHandler();

  /// Thread-local storage for isolate-specific handlers.
  ///
  /// Each Dart isolate can have its own independent exception handler.
  static final LocalThread<ApplicationExceptionHandler> _handlerLocal = LocalThread<ApplicationExceptionHandler>();

  /// Optional parent handler for delegation of exceptions.
  ///
  /// If provided, uncaught exceptions may be forwarded to this handler
  /// after internal checks.
  final void Function(Object error, StackTrace stack)? _parentHandler;

  /// {@macro application_exception_handler}
  ///
  /// - [parentHandler]: Optional function that receives uncaught exceptions
  ///   after internal handling.
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