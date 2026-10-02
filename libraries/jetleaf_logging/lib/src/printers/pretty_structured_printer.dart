import '../helpers/commons.dart';
import '../helpers/stack_trace_parser.dart';
import '../models/log_record.dart';
import '../core/log_printer.dart';
import '../models/log_config.dart';
import '../enums/log_step.dart';

/// {@template pretty_structured_printer}
/// A structured and visually aligned log printer designed for clear readability.
///
/// This printer uses iconography, spacing, and formatting to make logs easy to scan,
/// especially when scanning for fields like level, message, timestamp, and call stack.
///
/// ### Example Output:
/// ```
/// ┌──────────────────────────────────────────────────────────────────────────────
/// │ 📝 LEVEL     : INFO
/// │ 📅 TIMESTAMP : 2025-06-23 10:25:17.123
/// │ 🧩 MODULE    : AuthService
/// │ 🔍 MESSAGE   : Login succeeded
/// │ 📁 CALL STACK:
/// │    • #0 AuthService.login (auth_service.dart:42)
/// │    • #1 ...
/// └──────────────────────────────────────────────────────────────────────────────
/// ```
/// 
/// Controlled by [LogConfig] and [LogStep] ordering.
/// {@endtemplate}
final class PrettyStructuredPrinter extends LogPrinter {
  /// Total character width for the border line.
  final int lineLength;

  /// Configuration controlling visibility and format.
  final LogConfig config;

  /// Exclude paths from the stack trace.
  final List<String> excludePaths;

  /// {@macro pretty_structured_printer}
  PrettyStructuredPrinter({
    this.lineLength = 120,
    LogConfig? config,
    List<String>? excludePaths,
  }) : config = config ?? LogConfig(),
       excludePaths = excludePaths ?? StackTraceParser.defaultExcludePaths;

  final labelWidth = 16;
  String label(String text) => text.padRight(labelWidth);

  @override
  List<String> log(LogRecord record) {
    final color = levelColor(record.level);
    final buffer = <String>[];

    buffer.add(color('┌${'─' * (lineLength - 1)}'));
    
    for (final step in config.steps) {
      final content = getStepValue(step, record);
      if (content != null) {
        if (step == LogStep.STACKTRACE) {
          buffer.add(color('│ 📁 ${label("CALL STACK")}: '));
          final stackLines = extractStack(record.stackTrace, excludePaths);
          for (final line in stackLines) {
            buffer.add(color('│    • $line'));
          }
        } else {
          buffer.add(color('│ $content'));
        }
      }
    }

    buffer.add(color('└${'─' * (lineLength - 1)}'));
    return buffer;
  }

  @override
  String? getStepValue(LogStep step, LogRecord record) {
    switch (step) {
      case LogStep.TIMESTAMP:
        if (!config.showTimestamp) return null;
        final time = config.useHumanReadableTime 
            ? LogCommons.formatTimestamp(record.time, true)
            : record.time.toIso8601String();
        return '📅 ${label("TIMESTAMP")}: $time';
      case LogStep.DATE:
        if (!config.showDateOnly || !config.showTimestamp) return null;
        return '📅 ${label("DATE")}: ${record.time.toIso8601String().split('T')[0]}';
      case LogStep.LEVEL:
        if (!config.showLevel) return null;
        final emoji = config.showEmoji ? LogCommons.levelEmojis[record.level] ?? '📝' : '📝';
        return '$emoji ${label("LEVEL")}: ${record.level.name}';
      case LogStep.TAG:
        return (config.showTag && record.loggerName != null && record.loggerName!.isNotEmpty) 
            ? '🧩 ${label("MODULE")}: ${record.loggerName}' 
            : null;
      case LogStep.MESSAGE:
        return '🔍 ${label("MESSAGE")}: ${stringify(record.message)}';
      case LogStep.ERROR:
        return (record.error != null) ? '❌ ${label("ERROR")}: ${record.error}' : null;
      case LogStep.STACKTRACE:
        return null; // Handled separately
      case LogStep.THREAD:
        return config.showThread ? '🧵 ${label("THREAD")}: main' : null;
      case LogStep.LOCATION:
        if (!config.showLocation) return null;
        final location = record.location;
        return location != null ? '📍 ${label("LOCATION")}: $location' : null;
    }
  }
}