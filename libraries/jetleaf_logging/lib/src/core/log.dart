import '../enums/log_level.dart';
import 'log_factory.dart';

/// {@template log}
/// A convenient logging utility built on top of [LogFactory].
///
/// The `Log` class provides a simplified and readable interface for
/// logging messages at various log levels such as info, warning, error,
/// debug, fatal, and trace. It is typically used throughout the Jetleaf
/// framework to emit consistent and structured log output.
///
/// ### Example:
/// ```dart
/// final log = Log('MyComponent');
///
/// log.info('Application started.');
/// log.error('Something went wrong.', error: exception, stacktrace: stack);
/// log.debug('Debugging some internal state...');
/// ```
///
/// The `tag` passed to the constructor is used to identify the origin
/// of log messages, such as a class or module name.
///
/// This class is `final`, so it cannot be extended.
/// {@endtemplate}
final class Log extends LogFactory {
  /// {@macro log}
  Log(super.tag, {super.canPublish = true});

  /// {@template log.info}
  /// Logs a message at the `INFO` level.
  ///
  /// Typically used for general application flow messages.
  ///
  /// ### Example:
  /// ```dart
  /// log.info('Server started successfully.');
  /// ```
  /// {@endtemplate}
  void info(String message, {Object? error, StackTrace? stacktrace}) {
    add(LogLevel.INFO, message, error: error, stacktrace: stacktrace);
  }

  /// {@template log.warn}
  /// Logs a message at the `WARN` level.
  ///
  /// Typically used to indicate a potential problem that is non-fatal.
  ///
  /// ### Example:
  /// ```dart
  /// log.warn('Disk space is running low.');
  /// ```
  /// {@endtemplate}
  void warn(String message, {Object? error, StackTrace? stacktrace}) {
    add(LogLevel.WARN, message, error: error, stacktrace: stacktrace);
  }

  /// {@template log.error}
  /// Logs a message at the `ERROR` level.
  ///
  /// Used when an operation fails but the app can still continue.
  ///
  /// ### Example:
  /// ```dart
  /// log.error('Failed to load configuration file.', error: e, stacktrace: s);
  /// ```
  /// {@endtemplate}
  void error(String message, {Object? error, StackTrace? stacktrace}) {
    add(LogLevel.ERROR, message, error: error, stacktrace: stacktrace);
  }

  /// {@template log.debug}
  /// Logs a message at the `DEBUG` level.
  ///
  /// Used for debugging during development or diagnostics.
  ///
  /// ### Example:
  /// ```dart
  /// log.debug('User data: $user');
  /// ```
  /// {@endtemplate}
  void debug(String message, {Object? error, StackTrace? stacktrace}) {
    add(LogLevel.DEBUG, message, error: error, stacktrace: stacktrace);
  }

  /// {@template log.fatal}
  /// Logs a message at the `FATAL` level.
  ///
  /// Used when a critical error occurs and the system may not recover.
  ///
  /// ### Example:
  /// ```dart
  /// log.fatal('Unrecoverable system failure.', error: err, stacktrace: st);
  /// ```
  /// {@endtemplate}
  void fatal(String message, {Object? error, StackTrace? stacktrace}) {
    add(LogLevel.FATAL, message, error: error, stacktrace: stacktrace);
  }

  /// {@template log.trace}
  /// Logs a message at the `TRACE` level.
  ///
  /// Useful for very fine-grained logging of program execution.
  ///
  /// ### Example:
  /// ```dart
  /// log.trace('Entering middleware layer...');
  /// ```
  /// {@endtemplate}
  void trace(String message, {Object? error, StackTrace? stacktrace}) {
    add(LogLevel.TRACE, message, error: error, stacktrace: stacktrace);
  }
}