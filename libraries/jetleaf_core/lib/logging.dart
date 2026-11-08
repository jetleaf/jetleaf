/// 📝 **Jetleaf Logging System**
///
/// This library provides the core logging infrastructure for the Jetleaf
/// framework, including log levels, formatting, configuration models,
/// output handling, and extensible logging pipelines.
///
/// It serves as the public entry point to Jetleaf's logging API.
library;

import 'src/logging/enums/log_level.dart';
import 'src/logging/enums/log_type.dart';
import 'src/logging/core/log_printer.dart';
import 'src/logging/core/log_processor.dart';
import 'src/logging/core/logging_listener.dart';
import 'src/logging/models/log_config.dart';

/// ENUMS & Interfaces exported for external use.
export 'src/logging/enums/log_level.dart';
export 'src/logging/enums/log_step.dart';
export 'src/logging/enums/log_type.dart';

export 'src/logging/ansi/ansi_color.dart';
export 'src/logging/ansi/ansi_output.dart';

export 'src/logging/models/log_config.dart';
export 'src/logging/models/log_record.dart';

export 'src/logging/core/log_printer.dart';
export 'src/logging/core/logging_listener.dart';

export 'src/logging/core/log_factory.dart';
export 'src/logging/core/log.dart';

export 'src/logging/helpers/commons.dart';

/// {@template logger}
/// A flexible and extensible logging interface.
///
/// The [Logger] class provides structured and leveled logging functionality
/// across your application. It wraps a [LoggingListener] that handles
/// how logs are processed and output—making it customizable through the strategy pattern.
///
/// This class offers six common logging levels:
/// - [info] – General operational messages.
/// - [debug] – Development and debugging messages.
/// - [trace] – Fine-grained, low-level application traces.
/// - [warn] – Warning messages about unexpected conditions.
/// - [error] – Errors that occurred during execution.
/// - [fatal] – Critical errors that may require immediate attention.
///
/// ### Example:
/// ```dart
/// console.info('Server started');
/// console.error('Unexpected error occurred', error: e, stackTrace: s);
/// ```
/// 
/// {@endtemplate}
class Logger implements LogProcessor {
  /// The current log listener responsible for handling the log output logic.
  ///
  /// You can override this with a custom [LoggingListener] via [addListener()]
  /// to modify how logs are formatted or where they are sent (e.g., file, console, remote server).
  late LoggingListener listener;

  /// {@macro logger}
  Logger({
    LogLevel level = LogLevel.INFO,
    LogPrinter? printer,
    LogType type = LogType.SIMPLE,
    void Function(String)? output,
    String name = "",
    LogConfig? config,
    LoggingListener? listener,
  }) : listener = listener ?? DefaultLoggingListener(
    level: level,
    printer: printer,
    type: type,
    output: output,
    name: name,
    config: config,
  );

  /// Replaces the current [LoggingListener] with a custom implementation.
  ///
  /// Useful if you want to change the output format, destination,
  /// or add logic like filtering or buffering logs.
  ///
  /// Example:
  /// ```dart
  /// console.addListener(MyCustomListener());
  /// ```
  void addListener(LoggingListener listener) {
    this.listener = listener;
  }

  @override
  void info(dynamic message, {String? tag, Object? error, StackTrace? stackTrace}) {
    listener.onLog(LogLevel.INFO, message, error: error, stackTrace: stackTrace, tag: tag);
  }

  @override
  void warn(dynamic message, {String? tag, Object? error, StackTrace? stackTrace}) {
    listener.onLog(LogLevel.WARN, message, error: error, stackTrace: stackTrace, tag: tag);
  }

  @override
  void error(dynamic message, {String? tag, Object? error, StackTrace? stackTrace}) {
    listener.onLog(LogLevel.ERROR, message, error: error, stackTrace: stackTrace, tag: tag);
  }

  @override
  void fatal(dynamic message, {String? tag, Object? error, StackTrace? stackTrace}) {
    listener.onLog(LogLevel.FATAL, message, error: error, stackTrace: stackTrace, tag: tag);
  }

  @override
  void debug(dynamic message, {String? tag, Object? error, StackTrace? stackTrace}) {
    listener.onLog(LogLevel.DEBUG, message, error: error, stackTrace: stackTrace, tag: tag);
  }

  @override
  void trace(dynamic message, {String? tag, Object? error, StackTrace? stackTrace}) {
    listener.onLog(LogLevel.TRACE, message, error: error, stackTrace: stackTrace, tag: tag);
  }

  /// Logs a message with a specified log level.
  ///
  /// Use this for logging messages with a specific log level.
  void log(dynamic message, {String? tag, Object? error, StackTrace? stackTrace, LogLevel level = LogLevel.INFO}) {
    listener.onLog(level, message, error: error, stackTrace: stackTrace, tag: tag);
  }
}

/// Global singleton logger instance for convenience.
///
/// Use `console` for quick access without instantiating [Tracing] manually.
///
/// Example:
/// ```dart
/// console.debug('Hello from global logger');
/// ```
final console = Logger();
