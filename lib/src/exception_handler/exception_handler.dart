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

import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_logging/logging.dart';

import '../listener/run_listeners.dart';
import '../shutdown/application_shutdown_handler_hook.dart';
import '../jet_leaf_exception.dart';
import 'application_exception_handler.dart';

/// {@template exception_handler}
/// Responsible for handling exceptions thrown during the application lifecycle
/// (startup or runtime) in JetLeaf applications.
///
/// This class provides a unified mechanism for:
/// 1. Mapping exceptions to application exit codes.
/// 2. Notifying registered [ApplicationRunListeners] about failures.
/// 3. Reporting exceptions via [ExceptionReporter]s.
/// 4. Closing the [ConfigurableApplicationContext] safely.
/// 5. Returning a wrapped [RuntimeException] to maintain a consistent exception type.
///
/// Key behaviors:
/// - Ensures that exceptions are properly logged using [_logger].
/// - Avoids duplicate reporting by integrating with [ApplicationExceptionHandler].
/// - Supports recursive cause resolution for exit code generation via [ExitCodeGenerator].
///
/// ## Example
/// ```dart
/// final handler = ExceptionHandler(
///   logger,
///   shutdownHook,
///   [ConsoleExceptionReporter()],
///   [DefaultExitCodeExceptionHandler()],
/// );
///
/// try {
///   runApplication();
/// } catch (e, st) {
///   handler.handleRunFailure(context, e as Throwable, listeners);
/// }
/// ```
///
/// References:
/// - [ApplicationExceptionHandler]: Tracks logged exceptions and exit codes.
/// - [ConfigurableApplicationContext]: The application context that may be closed on failure.
/// - [ExceptionReporter]: Interface for reporting exceptions externally.
/// - [ExitCodeGenerator]: Interface for exceptions providing specific exit codes.
/// {@endtemplate}
final class ExceptionHandler {
  /// Logger used to output exception details and stack traces.
  final Log _logger;

  /// Manages application shutdown hooks and cleanup for failed contexts.
  final ApplicationShutdownHandlerHook _shutdownHook;

  /// A collection of reporters used to publish exception details to various targets.
  final List<ExceptionReporter> _exceptionReporters;

  /// A collection of handlers mapping exceptions to exit codes.
  final List<ExitCodeExceptionHandler> _exitCodeExceptionHandlers;

  /// {@macro exception_handler}
  ExceptionHandler(
    this._logger,
    this._shutdownHook,
    this._exceptionReporters,
    this._exitCodeExceptionHandlers,
  );

  /// Handles an exception that occurred during application startup or runtime.
  ///
  /// Responsibilities:
  /// - Maps the exception to an appropriate exit code via [_handleExitCode].
  /// - Notifies registered [ApplicationRunListeners] about the failure.
  /// - Reports the failure via [_reportFailure] using registered [ExceptionReporter]s.
  /// - Closes the [ConfigurableApplicationContext] safely if provided.
  /// - Returns a [RuntimeException] for consistent rethrowing.
  ///
  /// If the given [exception] is already a [JetLeafException], it is returned unchanged.
  /// Otherwise, it may be wrapped in an [IllegalStateException].
  ///
  /// References:
  /// - [_handleExitCode]
  /// - [_reportFailure]
  /// - [ApplicationRunListeners.onFailed]
  RuntimeException handleRunFailure(ConfigurableApplicationContext? context, Throwable exception, ApplicationRunListeners? listeners, StackTrace? st) {
    if (exception is JetLeafException) {
      return exception;
    }

    try {
      try {
        _handleExitCode(context, exception);
        if (listeners != null) {
          listeners.onFailed(context, exception);
        }
      } finally {
        _reportFailure(_exceptionReporters, exception);
        if (context != null) {
          context.close();
          _shutdownHook.unregisterFailedApplicationContext(context);
        }
      }
    } on Exception catch (ex) {
      if (_logger.getIsInfoEnabled()) {
        _logger.info("Unable to close ApplicationContext ${context?.getId()}", error: ex, stacktrace: st);
      }
    }

    return (exception is RuntimeException)
        ? exception
        : IllegalStateException(exception.toString(), cause: exception);
  }

  /// Maps an exception to an exit code and publishes an [ExitCodeEvent].
  ///
  /// If the exit code is non-zero:
  /// - An [ExitCodeEvent] is published to the [ConfigurableApplicationContext]
  /// - The current [ApplicationExceptionHandler] is notified
  void _handleExitCode(ConfigurableApplicationContext? context, Throwable exception) {
    int exitCode = _getExitCodeFromException(context, exception);
    if (exitCode != 0) {
      if (context != null) {
        context.publishEvent(ExitCodeEvent(context, exitCode));
      }

      final handler = ApplicationExceptionHandler.current;
      handler.registerExitCode(exitCode);
    }
  }

  /// Resolves an exit code from the given [exception].
  ///
  /// Tries the following in order:
  /// 1. A mapped exit code from the current [ConfigurableApplicationContext]
  /// 2. An exit code from an [ExitCodeGenerator] exception (recursively)
  ///
  /// Returns `0` if no exit code can be determined.
  int _getExitCodeFromException(ConfigurableApplicationContext? context, Throwable exception) {
    int exitCode = _getExitCodeFromMappedException(context, exception);
    if (exitCode == 0) {
      exitCode = _getExitCodeFromExitCodeGeneratorException(exception);
    }

    return exitCode;
  }

  /// Attempts to resolve an exit code from mapped exception handlers.
  ///
  /// If the [context] is not running, returns `0`.
  int _getExitCodeFromMappedException(ConfigurableApplicationContext? context, Throwable exception) {
    if (context == null || !context.isRunning()) {
      return 0;
    }

    ExitCodeGenerators generators = ExitCodeGenerators();
    generators.addAll(exception, _exitCodeExceptionHandlers);

    return generators.getExitCode();
  }

  /// Attempts to resolve an exit code from exceptions that implement [ExitCodeGenerator].
  ///
  /// Recursively unwraps exception causes if necessary. Returns `0` if no
  /// exit code can be determined.
  int _getExitCodeFromExitCodeGeneratorException(Object? exception) {
    if (exception == null) return 0;

    final visited = Set<Object>.identity();
    Object? current = exception;

    while (current != null) {
      // If this object implements ExitCodeGenerator, return its code.
      if (current is ExitCodeGenerator) {
        try {
          return current.getExitCode();
        } catch (_) {
          // If calling getExitCode throws, treat it as not producing a code.
          return 0;
        }
      }

      // Detect cycles: if we've already seen this exact object, break out.
      if (!visited.add(current)) {
        // Cycle detected in the cause chain; bail out safely.
        return 0;
      }

      // Advance to the cause if available and of the expected Throwable type.
      if (current is Throwable) {
        final cause = current.getCause();
        // Defensive: if cause is same object, stop to avoid infinite loop.
        if (identical(cause, current)) return 0;
        current = cause;
      } else {
        // Not a Throwable with a cause; stop here.
        break;
      }
    }

    return 0;
  }

  /// Reports the given [failure] to all registered [ExceptionReporter]s.
  ///
  /// Behavior:
  /// - Iterates over reporters, allowing each to handle the exception
  /// - If a reporter successfully handles the exception, the failure is
  ///   registered as "logged" and no further reporting occurs
  /// - Logs the failure either via the [Log] or falls back to stdout
  ///
  /// Any exceptions thrown by reporters are swallowed so they do not interfere
  /// with handling of the original [failure].
  void _reportFailure(List<ExceptionReporter> exceptionReporters, Throwable failure) {
    try {
      exceptionReporters.process((reporter) {
        if (reporter.reportException(failure)) {
          _registerLoggedException(failure);
          return;
        }
      });
    } on Exception catch (_) {
      // Continue with normal handling of the original failure
    }

    if (!_logger.getIsErrorEnabled()) {
      System.out.println("Application run failed");
      failure.printStackTrace();
    } else {
      if (_logger.getIsErrorEnabled()) {
        _logger.error("Application run failed", error: failure);
      }
      _registerLoggedException(failure);
    }
  }

  /// Registers that the given [exception] has been logged.
  ///
  /// This prevents duplicate stack traces from being printed
  /// (e.g. by the default Dart runtime).
  void _registerLoggedException(Throwable exception) {
    ApplicationExceptionHandler handler = ApplicationExceptionHandler.current;
    handler.registerLoggedException(exception);
  }
}