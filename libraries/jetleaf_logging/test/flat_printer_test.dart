import 'package:jetleaf_logging/logging.dart';
import 'package:jetleaf_logging/printers.dart';
import 'package:test/test.dart';

import '_dependencies.dart';

void main() {
  group('FlatPrinter', () {
    test('prints timestamp, level, and message', () {
      final printer = FlatPrinter(
        config: defaultConfig(steps: [LogStep.TIMESTAMP, LogStep.LEVEL, LogStep.MESSAGE]),
      );

      final record = sampleRecord();
      final result = printer.log(record).first;

      expect(result, contains(record.time.toIso8601String()));
      expect(result, contains('INFO'));
      expect(result, contains('Test log'));
    });

    test('omits tag when showTag is false', () {
      final printer = FlatPrinter(
        config: defaultConfig(steps: [LogStep.TAG, LogStep.MESSAGE], showTag: false),
      );

      final record = sampleRecord(tag: 'MyLogger');
      final result = printer.log(record).first;

      expect(result, isNot(contains('MyLogger')));
    });
  });

  group('FlatStructuredPrinter', () {
    test('prints main line and stack trace lines', () {
      final printer = FlatStructuredPrinter(
        config: defaultConfig(steps: [LogStep.MESSAGE, LogStep.STACKTRACE]),
      );

      final record = sampleRecord(
        message: 'error occurred',
        stackTrace: StackTrace.current,
      );

      final result = printer.log(record);
      expect(result.first, contains('error occurred'));
      expect(result.any((line) => line.trim().startsWith('↪')), isTrue);
    });
  });
}