import 'package:jetleaf_lang/lang.dart';

import '../enums/log_level.dart';
import 'log.dart';
import 'logging_listener.dart';

/// The log content.
/// 
/// This is a map of key-value pairs representing the log content.
typedef _LogFactoryContent = (String message, {Object? error, StackTrace? stacktrace});

/// The log details.
/// 
/// This is a map of key-value pairs representing the log details.
typedef _LogFactoryDetails = Map<DateTime, _LogFactoryContent>;

/// The log information.
/// 
/// This is a map of key-value pairs representing the log information.
typedef _LogFactoryMapping = Map<LogLevel, _LogFactoryDetails>;

/// The log entry.
/// 
/// This is a map of key-value pairs representing the log entry.
typedef _LogFactoryEntry = Map<String, _LogFactoryMapping>;

/// {@template logger_factory}
/// A base class for building structured logging mechanisms within Jet-based applications.
///
/// This class provides an in-memory logging facility with support for multiple [LogLevel]s.
/// Subclasses can extend this base to implement custom logging strategies (e.g., file, console, remote).
///
/// Each logger instance is tagged with a custom [tag] to allow filtering or identification in composite logs.
///
/// ### Usage
///
/// Extend this class to build a concrete logger:
/// ```dart
/// class ConsoleLogger extends LoggerFactory {
///   ConsoleLogger(String tag) : super(tag);
///
///   void flush() {
///     _logs.forEach((level, messages) {
///       for (final message in messages) {
///         print('[$tag][$level] $message');
///       }
///     });
///   }
/// }
/// ```
///
/// Then use:
/// ```dart
/// final logger = ConsoleLogger("MyService");
/// logger.add(LogLevel.info, "Service started.");
/// logger.add(LogLevel.error, "Something went wrong.");
/// logger.flush();
/// ```
///
/// {@endtemplate}
abstract class LogFactory with _LogProperty {
  /// A custom label or category used to identify the logger instance.
  ///
  /// Commonly used to associate logs with a specific class, service, or module.
  final String tag;

  /// Whether the logger can publish logs to the console.
  final bool canPublish;

  /// The [LogListener] to use for this factory.
  /// 
  /// Can be nullable
  LoggingListener? logListener;

  /// Global logging listener for all factories.
  static LoggingListener? _globalListener;

  /// Internal log storage mapping each [LogLevel] to a list of log messages.
  _LogFactoryMapping _logs;

  /// Internal log entry storage mapping each [tag] to a list of log messages.
  /// 
  /// Mostly used when combining multiple loggers, in order to keep track of logs per tags.
  _LogFactoryEntry _superEntry = {};

  /// Constructs the logger factory with the given [tag].
  ///
  /// Initializes an empty log store for all levels.
  /// 
  /// {@macro logger_factory}
  LogFactory(this.tag, {this.canPublish = true, this.logListener}) : _logs = {
    LogLevel.INFO: {},
    LogLevel.WARN: {},
    LogLevel.ERROR: {},
    LogLevel.DEBUG: {},
    LogLevel.FATAL: {},
    LogLevel.OFF: {},
    LogLevel.TRACE: {},
  };

  /// Returns a new [Log] instance for the given [type].
  /// 
  /// {@macro log}
  static Log getLog(Object type, {bool canPublish = true}) => Log(type.toString(), canPublish: canPublish);

  /// Assigns a global [LoggingListener] that applies to all `LogFactory` instances.
  static void setGlobalLoggingListener(LoggingListener listener) {
    _globalListener = listener;
  }

  /// Clears the global [LoggingListener].
  static void clearGlobalLoggingListener() {
    _globalListener = null;
  }

  /// Resolves the effective listener (instance > global > default).
  LoggingListener? _resolveListener() => logListener ?? _globalListener;

  /// Returns whether `INFO`-level logging is currently enabled.
  bool getIsInfoEnabled() => _resolveListener() != null && _isInfoEnabled(tag);

  /// Returns whether `DEBUG`-level logging is currently enabled.
  bool getIsDebugEnabled() => _resolveListener() != null && _isDebugEnabled(tag);

  /// Returns whether `WARN`-level logging is currently enabled.
  bool getIsWarnEnabled() => _resolveListener() != null && _isWarnEnabled(tag);

  /// Returns whether `ERROR`-level logging is currently enabled.
  bool getIsErrorEnabled() => _resolveListener() != null && _isErrorEnabled(tag);

  /// Returns whether `FATAL`-level logging is currently enabled.
  bool getIsFatalEnabled() => _resolveListener() != null && _isFatalEnabled(tag);

  /// Returns whether `TRACE`-level logging is currently enabled.
  bool getIsTraceEnabled() => _resolveListener() != null && _isTraceEnabled(tag);

  void _log(LogLevel level, String message, {Object? error, StackTrace? stacktrace, String? dTag}) {
    final listener = _resolveListener();
    if (listener == null) return;

    if(getIsDebugEnabled() && level == LogLevel.DEBUG) {
      listener.onLog(level, message, tag: dTag ?? tag, error: error, stackTrace: stacktrace);
    }

    if(getIsInfoEnabled() && level == LogLevel.INFO) {
      listener.onLog(level, message, tag: dTag ?? tag, error: error, stackTrace: stacktrace);
    }

    if(getIsWarnEnabled() && level == LogLevel.WARN) {
      listener.onLog(level, message, tag: dTag ?? tag, error: error, stackTrace: stacktrace);
    }

    if(getIsErrorEnabled() && level == LogLevel.ERROR) {
      listener.onLog(level, message, tag: dTag ?? tag, error: error, stackTrace: stacktrace);
    }

    if(getIsFatalEnabled() && level == LogLevel.FATAL) {
      listener.onLog(level, message, tag: dTag ?? tag, error: error, stackTrace: stacktrace);
    }

    if(getIsTraceEnabled() && level == LogLevel.TRACE) {
      listener.onLog(level, message, tag: dTag ?? tag, error: error, stackTrace: stacktrace);
    }
  }

  /// Adds a [message] to the log buffer under the specified [level].
  ///
  /// If the level already contains entries, the new message is appended.
  ///
  /// Example:
  /// ```dart
  /// logger.add(LogLevel.debug, "Fetching user profile...");
  /// ```
  /// 
  /// If [canPublish] is true, the log is published to the console.
  /// 
  /// If [canPublish] is false, the log is stored in the internal log buffer.
  /// 
  /// {@macro logger_factory}
  void add(LogLevel level, String message, {Object? error, StackTrace? stacktrace}) {
    final timestamp = DateTime.now();

    if(canPublish) {
      _log(level, message, error: error, stacktrace: stacktrace);
    } else {
      _logs.update(
        level,
        (details) => details..add(timestamp, _prepareContent(message, error: error, stacktrace: stacktrace)),
        ifAbsent: () => {timestamp: _prepareContent(message, error: error, stacktrace: stacktrace)},
      );
    }
  }

  /// Prepares a log content.
  /// 
  /// This method takes a [message] and optional [error] and [stacktrace],
  /// and returns a map containing the log content.
  /// 
  /// {@macro logger_factory}
  _LogFactoryContent _prepareContent(String message, {Object? error, StackTrace? stacktrace}) {
    return (message, error: error, stacktrace: stacktrace);
  }

  /// Returns the log entry for the current logger.
  /// 
  /// This is mostly used when combining multiple loggers, in order to keep track of logs per tags. 
  /// 
  /// {@macro logger_factory}
  _LogFactoryEntry get entry => {tag: _logs};

  /// Adds all logs from the given [entry] to the internal super entry buffer.
  /// 
  /// This is mostly used when combining multiple loggers, in order to keep track of logs per tags. 
  /// 
  /// {@macro logger_factory}
  void addAll(_LogFactoryEntry entry) {
    _superEntry.addAll(entry);
  }

  /// Clears all logs from every [LogLevel].
  ///
  /// Useful for resetting the internal state or reusing the logger.
  ///
  /// Example:
  /// ```dart
  /// logger.clear(); // Empties all stored logs
  /// ```
  void clear() {
    _logs = {
      LogLevel.INFO: {},
      LogLevel.WARN: {},
      LogLevel.ERROR: {},
      LogLevel.DEBUG: {},
      LogLevel.FATAL: {},
      LogLevel.OFF: {},
      LogLevel.TRACE: {},
    };

    _superEntry = {};
  }

  /// Publishes all logs to the console.
  /// 
  /// This method iterates through all log levels and their associated messages,
  /// and publishes them to the console if [canPublish] is false.
  /// 
  /// Example:
  /// ```dart
  /// logger.publish();
  /// ```
  /// 
  /// This is mostly used when the extending class was initially created with [canPublish] set to false.
  void publish() {
    if(canPublish.isFalse) {
      if(_logs.isNotEmpty) {
        _logs.forEach((LogLevel level, _LogFactoryDetails details) {
          details.forEach((timestamp, content) {
            _log(level, getMessage(content), error: getError(content), stacktrace: getStackTrace(content));
          });
        });
      }

      if(_superEntry.isNotEmpty) {
        _superEntry.forEach((tag, details) {
          details.forEach((level, updates) {
            updates.forEach((timestamp, content) {
              _log(level, getMessage(content), dTag: tag, error: getError(content), stacktrace: getStackTrace(content));
            });
          });
        });
      }

      clear();
    }
  }

  /// Returns the message from the given [content].
  /// 
  /// {@macro logger_factory}
  String getMessage(_LogFactoryContent content) => content.$1;

  /// Returns the error from the given [content].
  /// 
  /// {@macro logger_factory}
  Object? getError(_LogFactoryContent content) => content.error;

  /// Returns the stack trace from the given [content].
  /// 
  /// {@macro logger_factory}
  StackTrace? getStackTrace(_LogFactoryContent content) => content.stacktrace;
}

/// {@template log_property}
/// A reusable mixin that provides a lightweight, string-based property
/// store for logging configuration and metadata in Jetleaf.
///
/// The [_LogProperty] mixin allows components in Jetleaf’s logging
/// subsystem to maintain per-tag log level and feature flags without
/// needing a centralized configuration object. Properties are stored
/// as simple key–value pairs and can be accessed or evaluated using
/// convenience methods.
///
/// ### Key Features
/// - Arbitrary string-based property storage.
/// - Built-in helpers for log-level and enablement checks:
///   - [getIsEnabled]
///   - [getIsDebugEnabled]
///   - [getIsWarnEnabled]
///   - [getIsErrorEnabled]
///   - [getIsFatalEnabled]
///   - [getIsTraceEnabled]
///
/// ### Example
/// ```dart
/// class MyLogger with LogProperty {
///   void log(String tag, String message) {
///     if (getIsDebugEnabled(tag)) {
///       print("[DEBUG][$tag] $message");
///     }
///   }
/// }
///
/// void main() {
///   final logger = MyLogger()
///     ..setProperty("logging.level.core", "debug")
///     ..setProperty("logging.enabled.core", "true");
///
///   logger.log("core", "Debugging initialized");
/// }
/// ```
/// {@endtemplate}
mixin class _LogProperty {
  /// {@template log_property.get_property}
  /// Retrieves the property value associated with [key].
  ///
  /// - Returns `null` if the property is undefined.
  ///
  /// Example:
  /// ```dart
  /// final level = logger.getProperty("logging.level.api");
  /// print("Log level: $level");
  /// ```
  /// {@endtemplate}
  String? getProperty(String key) => LogProperties.instance.getProperty(key);

  /// {@template log_property.get_is_enabled}
  /// Checks whether logging is enabled for a specific [tag].
  ///
  /// The corresponding property key is expected to follow the pattern:
  /// `"logging.enabled.<tag>"`.
  ///
  /// Example:
  /// ```dart
  /// if (logger._isEnabled("core")) {
  ///   print("Logging enabled for 'core'");
  /// }
  /// ```
  /// {@endtemplate}
  bool _isEnabled(String tag) => getProperty("logging.enabled.$tag")?.equalsIgnoreCase("true") ?? true;

  /// {@template log_property.get_is_debug_enabled}
  /// Returns `true` if the log level for the given [tag] equals `"debug"`.
  ///
  /// Example:
  /// ```dart
  /// if (logger._isDebugEnabled("network")) {
  ///   print("Network debugging active.");
  /// }
  /// ```
  /// {@endtemplate}
  bool _isDebugEnabled(String tag) => _isEnabled(tag) && (getProperty("logging.level.$tag")?.equalsIgnoreCase("debug") ?? true);

  /// {@template log_property.get_is_info_enabled}
  /// Returns `true` if the log level for the given [tag] equals `"info"`.
  ///
  /// Example:
  /// ```dart
  /// if (logger._isInfoEnabled("network")) {
  ///   print("Network info logging active.");
  /// }
  /// ```
  /// {@endtemplate}
  bool _isInfoEnabled(String tag) => _isEnabled(tag) && (getProperty("logging.level.$tag")?.equalsIgnoreCase("info") ?? true);

  /// {@template log_property.get_is_error_enabled}
  /// Returns `true` if the log level for the given [tag] equals `"error"`.
  ///
  /// Example:
  /// ```dart
  /// if (logger._isErrorEnabled("auth")) {
  ///   print("Auth error logging enabled.");
  /// }
  /// ```
  /// {@endtemplate}
  bool _isErrorEnabled(String tag) => _isEnabled(tag) && (getProperty("logging.level.$tag")?.equalsIgnoreCase("error") ?? true);

  /// {@template log_property.get_is_warn_enabled}
  /// Returns `true` if the log level for the given [tag] equals `"warn"`.
  ///
  /// Example:
  /// ```dart
  /// if (logger._isWarnEnabled("storage")) {
  ///   print("Storage warnings enabled.");
  /// }
  /// ```
  /// {@endtemplate}
  bool _isWarnEnabled(String tag) => _isEnabled(tag) && (getProperty("logging.level.$tag")?.equalsIgnoreCase("warn") ?? false);

  /// {@template log_property.get_is_fatal_enabled}
  /// Returns `true` if the log level for the given [tag] equals `"fatal"`.
  ///
  /// Example:
  /// ```dart
  /// if (logger._isFatalEnabled("core")) {
  ///   print("Fatal-level logging enabled.");
  /// }
  /// ```
  /// {@endtemplate}
  bool _isFatalEnabled(String tag) => _isEnabled(tag) && (getProperty("logging.level.$tag")?.equalsIgnoreCase("fatal") ?? false);

  /// {@template log_property.get_is_trace_enabled}
  /// Returns `true` if the log level for the given [tag] equals `"trace"`.
  ///
  /// Example:
  /// ```dart
  /// if (logger._isTraceEnabled("network")) {
  ///   print("Network trace logging active.");
  /// }
  /// ```
  /// {@endtemplate}
  bool _isTraceEnabled(String tag) => _isEnabled(tag) && (getProperty("logging.level.$tag")?.equalsIgnoreCase("trace") ?? false);
}

/// {@template log_properties}
/// A small, thread-safe global registry for logging configuration
/// and diagnostic properties within Jetleaf.
///
/// This singleton provides a shared key–value map that holds global
/// logging flags, level definitions, and environment metadata.  
/// Instances of [_LogProperty] and other Jetleaf logging utilities
/// consult this registry to resolve effective configuration values.
///
/// ### Key Features
/// - Stores arbitrary string-based configuration properties.
/// - Provides bulk and single property setters with overwrite control.
/// - Offers flag evaluation via [getFlag].
/// - Exposes an immutable view of all stored properties with [asMap].
///
/// ### Usage
/// ```dart
/// // Setting global log properties:
/// LogProperties.instance.setProperty("logging.level.core", "debug");
/// LogProperties.instance.setProperty("logging.enabled.core", "true");
///
/// // Reading from within a LogProperty mixin:
/// final global = LogProperties.instance;
/// print(global.getFlag("logging.enabled.core")); // true
/// ```
/// {@endtemplate}
final class LogProperties {
  /// Private constructor for singleton initialization.
  LogProperties._();

  /// {@template log_properties.instance}
  /// The singleton instance of [LogProperties].
  ///
  /// Example:
  /// ```dart
  /// final props = LogProperties.instance;
  /// props.setProperty("logging.level.api", "warn");
  /// ```
  /// {@endtemplate}
  static final LogProperties _inst = LogProperties._();

  /// {@template log_properties.instance}
  /// The singleton instance of [LogProperties].
  ///
  /// Example:
  /// ```dart
  /// final props = LogProperties.instance;
  /// props.setProperty("logging.level.api", "warn");
  /// ```
  /// {@endtemplate}
  static LogProperties get instance => _inst;

  /// Internal map holding all registered global log properties.
  final Map<String, String> _props = {};

  /// {@template log_properties.set_property}
  /// Sets a single property identified by [key] to the specified [value].
  ///
  /// If [overwrite] is `false`, existing values for the same key are preserved.
  ///
  /// Example:
  /// ```dart
  /// LogProperties.instance.setProperty("logging.level.core", "info");
  /// ```
  /// {@endtemplate}
  void setProperty(String key, String value, {bool overwrite = true}) {
    if (!overwrite && _props.containsKey(key)) return;
    _props[key] = value;
  }

  /// {@template log_properties.set_properties}
  /// Performs a bulk update of properties using a [map] of key–value pairs.
  ///
  /// - If [overwrite] is `false`, existing properties are not replaced.
  /// - This is a convenient way to inject a batch of configuration settings.
  ///
  /// Example:
  /// ```dart
  /// LogProperties.instance.setProperties({
  ///   "logging.level.core": "debug",
  ///   "logging.level.network": "warn",
  /// });
  /// ```
  /// {@endtemplate}
  void setProperties(Map<String, String> map, {bool overwrite = true}) {
    for (final e in map.entries) {
      setProperty(e.key, e.value, overwrite: overwrite);
    }
  }

  /// {@template log_properties.get_property}
  /// Retrieves the string value for the given [key].
  ///
  /// Returns `null` if the property does not exist.
  ///
  /// Example:
  /// ```dart
  /// final level = LogProperties.instance.getProperty("logging.level.core");
  /// print(level); // e.g. "debug"
  /// ```
  /// {@endtemplate}
  String? getProperty(String key) => _props[key];

  /// {@template log_properties.as_map}
  /// Returns an immutable snapshot of all stored log properties.
  ///
  /// The returned map is unmodifiable and reflects the current state of
  /// global logging configuration.
  ///
  /// Example:
  /// ```dart
  /// final allProps = LogProperties.instance.asMap();
  /// print(allProps);
  /// ```
  /// {@endtemplate}
  Map<String, String> asMap() => Map.unmodifiable(_props);

  /// {@template log_properties.clear}
  /// Clears all global logging properties.
  ///
  /// Useful for resetting configuration between tests or environments.
  ///
  /// Example:
  /// ```dart
  /// LogProperties.instance.clear();
  /// ```
  /// {@endtemplate}
  void clear() => _props.clear();
}