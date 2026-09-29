/// {@template log_processor}
/// Contract for processing log messages at various [LogLevel]s.
///
/// A [LogProcessor] defines how log messages are formatted, enriched, and
/// dispatched (e.g., to console, files, remote servers).
///
/// Implementations can provide custom behaviors like:
/// - Writing structured logs (JSON, key-value, etc.)
/// - Filtering by tag or log level
/// - Forwarding to external logging services
///
/// Example:
/// ```dart
/// class ConsoleLogProcessor implements LogProcessor {
///   @override
///   void info(message, {String? tag, Object? error, StackTrace? stackTrace}) {
///     print('[INFO] $tag: $message');
///   }
///
///   @override
///   void error(message, {String? tag, Object? error, StackTrace? stackTrace}) {
///     print('[ERROR] $tag: $message');
///     if (error != null) print('Caused by: $error');
///     if (stackTrace != null) print(stackTrace);
///   }
///
///   // other levels...
/// }
/// ```
/// {@endtemplate}
abstract interface class LogProcessor {
  /// {@template log_info}
  /// Logs a message with [LogLevel.INFO].
  ///
  /// Use this for standard log messages confirming normal application behavior.
  ///
  /// Example:
  /// ```dart
  /// logger.info('Application started', tag: 'AppInit');
  /// ```
  ///
  /// - [message]: The log message or object to log.
  /// - [tag]: Optional string categorizing the log (e.g. 'DB', 'Auth').
  /// - [error]: An associated error or exception.
  /// - [stackTrace]: An optional stack trace for context.
  /// {@endtemplate}
  void info(dynamic message, {String? tag, Object? error, StackTrace? stackTrace});

  /// {@template log_warn}
  /// Logs a message with [LogLevel.WARN].
  ///
  /// Use this for **recoverable issues** that need attention but don’t halt execution.
  ///
  /// Example:
  /// ```dart
  /// logger.warn('Cache miss', tag: 'Cache');
  /// ```
  /// {@endtemplate}
  void warn(dynamic message, {String? tag, Object? error, StackTrace? stackTrace});

  /// {@template log_error}
  /// Logs a message with [LogLevel.ERROR].
  ///
  /// Use this for **unrecoverable failures** or serious issues.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   riskyOperation();
  /// } catch (e, st) {
  ///   logger.error('Operation failed', tag: 'Service', error: e, stackTrace: st);
  /// }
  /// ```
  /// {@endtemplate}
  void error(dynamic message, {String? tag, Object? error, StackTrace? stackTrace});

  /// {@template log_fatal}
  /// Logs a message with [LogLevel.FATAL].
  ///
  /// Use this for **critical system errors** that typically require immediate shutdown.
  ///
  /// Example:
  /// ```dart
  /// logger.fatal('Database corruption detected', tag: 'DB');
  /// ```
  /// {@endtemplate}
  void fatal(dynamic message, {String? tag, Object? error, StackTrace? stackTrace});

  /// {@template log_debug}
  /// Logs a message with [LogLevel.DEBUG].
  ///
  /// Use this for **detailed internal state logs**, useful during development or troubleshooting.
  ///
  /// Example:
  /// ```dart
  /// logger.debug('User object: $user', tag: 'Auth');
  /// ```
  /// {@endtemplate}
  void debug(dynamic message, {String? tag, Object? error, StackTrace? stackTrace});

  /// {@template log_trace}
  /// Logs a message with [LogLevel.TRACE].
  ///
  /// Use this for the **most fine-grained logging level**, helpful for tracing code paths
  /// or investigating rare edge cases.
  ///
  /// Example:
  /// ```dart
  /// logger.trace('Entering method process()', tag: 'Pipeline');
  /// ```
  /// {@endtemplate}
  void trace(dynamic message, {String? tag, Object? error, StackTrace? stackTrace});
}