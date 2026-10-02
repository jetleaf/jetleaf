import 'package:jetleaf_logging/logging.dart';

LogRecord sampleRecord({
  String message = "Test log",
  LogLevel level = LogLevel.INFO,
  DateTime? time,
  String? tag,
  dynamic error,
  StackTrace? stackTrace,
  String? location,
}) {
  return LogRecord(
    level,
    message,
    time: time ?? DateTime.utc(2025, 1, 1, 12, 0, 0),
    loggerName: tag,
    error: error,
    stackTrace: stackTrace,
  );
}

LogConfig defaultConfig({
  List<LogStep> steps = const [LogStep.TIMESTAMP, LogStep.LEVEL, LogStep.MESSAGE],
  bool showTag = false,
  bool showLevel = true,
  bool showTimestamp = true,
  bool useHumanReadableTime = false,
  bool showDateOnly = false,
}) {
  return LogConfig(
    steps: steps,
    showTag: showTag,
    showLevel: showLevel,
    showTimestamp: showTimestamp,
    useHumanReadableTime: useHumanReadableTime,
    showDateOnly: showDateOnly,
  );
}