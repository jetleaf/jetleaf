import 'package:jetleaf_lang/lang.dart';

/// Defines individual components (steps) that can be included in log output.
///
/// Used by log printers to control the composition of each log message.
/// Enables granular formatting such as showing only time, message, or level.
enum LogStep {
  /// Timestamp of the log, including date and time.
  TIMESTAMP,

  /// Only the date portion of the timestamp (useful when omitting time).
  DATE,

  /// Log level indicator (e.g., INFO, ERROR), optionally with emoji.
  LEVEL,

  /// Optional user-defined tag or logger name to identify the log source.
  TAG,

  /// Indicates the thread or isolate where the log originated.
  THREAD,

  /// Represents the code location where the log was triggered (if available).
  LOCATION,

  /// The main log message or content.
  MESSAGE,

  /// Any error object attached to the log event.
  ERROR,

  /// A stack trace, usually included when an error is present.
  STACKTRACE;

  /// Default ordering and selection of log steps used by printers unless overridden.
  static List<LogStep> get defaultSteps => [
    DATE,
    TIMESTAMP,
    TAG,
    LEVEL,
    MESSAGE,
    THREAD,
    LOCATION,
    ERROR,
    STACKTRACE,
  ];

  /// Converts a string value to its corresponding [LogStep].
  ///
  /// This method is case-insensitive and throws an [InvalidArgumentException]
  /// if the input string does not match any valid [LogStep].
  ///
  /// ### Example
  /// ```dart
  /// final step = LogStep.fromValue("timestamp");
  /// ```
  static LogStep fromValue(String value) {
    switch (value.toLowerCase()) {
      case "timestamp":
        return TIMESTAMP;
      case "date":
        return DATE;
      case "level":
        return LEVEL;
      case "tag":
        return TAG;
      case "thread":
        return THREAD;
      case "location":
        return LOCATION;
      case "message":
        return MESSAGE;
      case "error":
        return ERROR;
      case "stacktrace":
        return STACKTRACE;
      default:
        throw InvalidArgumentException("Invalid LogStep value: $value. Available values: ${LogStep.values.map((e) => e.name).join(", ")}");
    }
  }
}