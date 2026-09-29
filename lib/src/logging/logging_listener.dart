import 'dart:io';

import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_logging/logging.dart';
import 'package:jetleaf_lang/lang.dart';

import 'jetleaf_logging_property.dart';

/// {@template application_logging_listener}
/// Jetleaf's application-level [LoggingListener] implementation.
///
/// This listener acts as a bridge between the Jetleaf logging system and
/// the active [Environment]. It configures a [Logger] instance per
/// application or per log `tag`, using environment-driven settings from
/// [JetleafLoggingProperty].
///
/// Features:
/// - Creates a lazily-initialized [Logger] per tag.
/// - Applies formatting and output options (`pretty`, `flat`, `json`, etc.).
/// - Supports both global (`logging.level.all`) and tag-specific
///   (`logging.level.<tag>`) log levels.
/// - Filters log messages before delegating to the [Logger].
///
/// Example:
/// ```dart
/// final listener = ApplicationLoggingListener(MyApp, environment);
/// LoggingSystem.addListener(listener);
/// ```
/// {@endtemplate}
final class ApplicationLoggingListener implements LoggingListener {
  /// {@template application_logging_listener_application_class}
  /// Reference to the application's root class. Used to determine the default
  /// log tag when no explicit tag is provided.
  /// {@endtemplate}
  final Class<Object> _applicationClass;

  /// {@template application_logging_listener_loggers}
  /// Cache of loggers keyed by their tag or application name.
  ///
  /// Ensures that each tag has a lazily-initialized [Logger] instance.
  /// {@endtemplate}
  final Map<String, Logger> _loggers = {};

  /// {@template application_logging_listener_environment}
  /// Active environment from which logging configuration is read.
  /// May be `null` if no environment has been provided.
  /// {@endtemplate}
  final Environment? _environment;

  /// {@macro application_logging_listener}
  ///
  /// Creates an [ApplicationLoggingListener] bound to the given
  /// [_applicationClass] and [_environment].
  ApplicationLoggingListener(this._applicationClass, this._environment);

  @override
  void onLog(LogLevel level, message, {String? tag, Object? error, StackTrace? stackTrace}) async {
    final name = tag ?? _applicationClass.getName();
    final type = _getLogType(tag);
    final config = _getLogConfig(tag);
    final logger = _loggers[name] ?? Logger(name: name, type: type, config: config);
    final loggingFile = _get(_key(JetleafLoggingProperty.FILE, tag)) ?? _get(_key(JetleafLoggingProperty.FILE));
    final shouldLogToConsole = loggingFile == null || loggingFile.isEmpty;

    // 1. Get global level
    final gl = _getConfiguredLevel(null) ?? _getConfiguredLevel(tag);
    final isEnabled = _get(_key(JetleafLoggingProperty.ENABLED, tag))?.toBool() ?? _get(_key(JetleafLoggingProperty.ENABLED))?.toBool() ?? true;

    // 2. Check if this log should be printed
    final shouldLog = gl == null || gl.isEnabledFor(level);
    _loggers[name] = logger;

    // 3. Log if enabled
    if (shouldLog && isEnabled) {
      final record = LogRecord(
        level,
        message.toString(),
        loggerName: name.replaceAll("[", "").replaceAll("]", ""),
        error: error,
        stackTrace: stackTrace,
      );
      final printer = LogPrinter.get(type, config);
      final lines = printer.log(record);

      if(shouldLogToConsole) {
        for (final line in lines) {
          System.out.println(_getMsg(line, config));
        }
      } else {
        try {
          final logFile = File(loggingFile);

          // Ensure directory exists
          await logFile.parent.create(recursive: true);

          // Append each line to the file
          final sink = logFile.openWrite(mode: FileMode.append);
          for (final line in lines) {
            sink.writeln(_getMsg(line, config));
          }

          await sink.flush();
          await sink.close();
        } catch (e) {
          System.err.println("[LOG ERROR] Could not write log to file: $e");

          // Fallback to console if file write fails
          for (final line in lines) {
            System.out.println(_getMsg(line, config));
          }
        }
      }
    }
  }

  /// {@template application_logging_listener_getMsg}
  /// Prepares a log message string for output by applying
  /// [LogConfig] rules.
  ///
  /// If [LogConfig.showEmoji] is `false`, all emojis are removed from the
  /// message to ensure clean output in environments that may not support
  /// emojis.
  ///
  /// Example:
  /// ```dart
  /// final config = LogConfig(showEmoji: false);
  /// final msg = listener._getMsg("Hello 🌍", config);
  /// print(msg); // "Hello"
  /// ```
  /// {@endtemplate}
  String _getMsg(String msg, LogConfig config) {
    String output = msg;

    if (!config.showEmoji && output.containsEmoji) {
      output = output.removeEmojis();
    }

    return output;
  }

  /// {@template application_logging_listener_getLogType}
  /// Retrieves the [LogType] for the given [tag].
  ///
  /// If no type is configured, defaults to `"flat"`.
  ///
  /// Example:
  /// ```dart
  /// final type = listener._getLogType("server");
  /// print(type); // LogType.flat (if not overridden in config)
  /// ```
  /// {@endtemplate}
  LogType _getLogType(String? tag) {
    final type = _get(_key(JetleafLoggingProperty.TYPE, tag)) ?? _get(_key(JetleafLoggingProperty.TYPE)) ?? "flat";
    return LogType.fromString(type);
  }

  /// {@template application_logging_listener_getLogConfig}
  /// Builds a [LogConfig] for the given [tag], based on environment
  /// properties.
  ///
  /// Reads individual properties like:
  /// - `logging.show.timestamp`
  /// - `logging.show.level`
  /// - `logging.show.tag`
  /// - `logging.show.emoji`
  ///
  /// Falls back to default values when properties are not set.
  ///
  /// Example:
  /// ```dart
  /// final config = listener._getLogConfig("api");
  /// print(config.showLevel); // true/false depending on env
  /// ```
  /// {@endtemplate}
  LogConfig _getLogConfig(String? tag) => LogConfig(
    showTimestamp: (_get(_key(JetleafLoggingProperty.SHOW_TIMESTAMP, tag)) ?? _get(_key(JetleafLoggingProperty.SHOW_TIMESTAMP)))?.toBool() ?? false,
    showTimeOnly: (_get(_key(JetleafLoggingProperty.SHOW_TIME_ONLY, tag)) ?? _get(_key(JetleafLoggingProperty.SHOW_TIME_ONLY)))?.toBool() ?? false,
    showDateOnly: (_get(_key(JetleafLoggingProperty.SHOW_DATE_ONLY, tag)) ?? _get(_key(JetleafLoggingProperty.SHOW_DATE_ONLY)))?.toBool() ?? false,
    showLevel: (_get(_key(JetleafLoggingProperty.SHOW_LEVEL, tag)) ?? _get(_key(JetleafLoggingProperty.SHOW_LEVEL)))?.toBool() ?? false,
    showTag: (_get(_key(JetleafLoggingProperty.SHOW_TAG, tag)) ?? _get(_key(JetleafLoggingProperty.SHOW_TAG)))?.toBool() ?? false,
    showThread: (_get(_key(JetleafLoggingProperty.SHOW_THREAD, tag)) ?? _get(_key(JetleafLoggingProperty.SHOW_THREAD)))?.toBool() ?? false,
    useHumanReadableTime: (_get(_key(JetleafLoggingProperty.USE_HUMAN_READABLE_TIME, tag)) ?? _get(_key(JetleafLoggingProperty.USE_HUMAN_READABLE_TIME)))?.toBool() ?? false,
    showEmoji: (_get(_key(JetleafLoggingProperty.SHOW_EMOJI, tag)) ?? _get(_key(JetleafLoggingProperty.SHOW_EMOJI)))?.toBool() ?? false,
    showLocation: (_get(_key(JetleafLoggingProperty.SHOW_LOCATION, tag)) ?? _get(_key(JetleafLoggingProperty.SHOW_LOCATION)))?.toBool() ?? false,
    steps: (_get(_key(JetleafLoggingProperty.STEPS, tag)) ?? _get(_key(JetleafLoggingProperty.STEPS)))?.split(",").map((step) => LogStep.fromValue(step)).toList() ?? LogStep.defaultSteps,
  );

  /// {@template application_logging_listener_key}
  /// Creates a property key for the given [prefix] and optional [tag].
  ///
  /// - If [tag] is provided, the key is `"prefix.tag"`.
  /// - Otherwise, the key is just the [prefix].
  ///
  /// Example:
  /// ```dart
  /// final key = listener._key("logging.level", "api");
  /// print(key); // "logging.level.api"
  /// ```
  /// {@endtemplate}
  String _key(String prefix, [String? tag]) => tag != null ? "$prefix.$tag" : prefix;

  /// {@template application_logging_listener_get}
  /// Retrieves a property value from the [Environment].
  ///
  /// Returns `null` if the key is not found or if [_environment] is `null`.
  ///
  /// Example:
  /// ```dart
  /// final value = listener._get("logging.level.api");
  /// print(value); // e.g. "debug"
  /// ```
  /// {@endtemplate}
  String? _get(String key) => _environment?.getProperty(key);

  /// {@template application_logging_listener_getConfiguredLevel}
  /// Reads the configured [LogLevel] for the given [tag].
  ///
  /// - If `logging.level.<tag>` is not found, returns `null`.
  /// - Ignores values equal to `"all"`.
  /// - Catches parsing errors silently and returns `null`.
  ///
  /// Example:
  /// ```dart
  /// final level = listener._getConfiguredLevel("api");
  /// print(level); // LogLevel.debug (if configured)
  /// ```
  /// {@endtemplate}
  LogLevel? _getConfiguredLevel(String? tag) {
    if(tag != null) {
      try {
        final value = _get(_key(JetleafLoggingProperty.LEVEL, tag));

        if(value != null && !value.equalsIgnoreCase("all")) {
          return LogLevel.fromValue(value);
        }
      } catch (_) { }
    }

    return null;
  }
}