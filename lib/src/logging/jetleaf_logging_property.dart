/// {@template jetleaf_logging_property}
/// Defines all Jetleaf framework logging-related configuration keys.
///
/// These are plain string constants representing logging configuration
/// keys that can be resolved from the [Environment] or [JetleafProperties].
///
/// Example configuration:
/// ```yaml
/// logging:
///   type: pretty
///   level: info
///   show:
///     timestamp: true
///     thread: false
/// ```
/// {@endtemplate}
abstract final class JetleafLoggingProperty {
  /// The logging output format.
  ///
  /// Supported values:
  /// - `pretty` → colorful, human-readable logs
  /// - `flat`   → plain, minimal logs
  /// - `json`   → structured JSON logs
  static const String TYPE = "logging.type";

  /// The minimum log level to output.
  ///
  /// Supported values: `all`, `trace`, `debug`, `info`, `warn`, `error`, `off`.
  static const String LEVEL = "logging.level";

  /// Defines the order of log parts (steps).
  ///
  /// Example:
  /// `timestamp, level, tag, message, thread, location, error, stacktrace, date`
  static const String STEPS = "logging.steps";

  /// Whether to show a timestamp in logs.
  static const String SHOW_TIMESTAMP = "logging.show.timestamp";

  /// Whether to show only the time (HH:mm:ss) in logs.
  static const String SHOW_TIME_ONLY = "logging.show.time-only";

  /// Whether to show only the date (yyyy-MM-dd) in logs.
  static const String SHOW_DATE_ONLY = "logging.show.date-only";

  /// Whether to show the log level (INFO, WARN, ERROR, etc).
  static const String SHOW_LEVEL = "logging.show.level";

  /// Whether to show a tag (e.g., component name).
  static const String SHOW_TAG = "logging.show.tag";

  /// Whether to include the thread ID in the log output.
  static const String SHOW_THREAD = "logging.show.thread";

  /// Whether to show the source code location (file:line).
  static const String SHOW_LOCATION = "logging.show.location";

  /// Whether to use emojis for log levels.
  ///
  /// Example: ❌ for ERROR, ⚠️ for WARN.
  static const String SHOW_EMOJI = "logging.show.emoji";

  /// Whether to format timestamps in human-readable style.
  ///
  /// Example: `5 seconds ago` instead of `2025-08-27 14:35:02`.
  static const String USE_HUMAN_READABLE_TIME = "logging.use-human-readable-time";

  /// Path to a log file.
  ///
  /// If non-empty, logs will be written to this file instead of
  /// (or in addition to) console output.
  static const String FILE = "logging.file";

  /// Whether to enable logging for this tag.
  static const String ENABLED = "logging.enabled";
}