import 'package:jetleaf_logging/logging.dart';
import 'package:jetleaf_logging/printers.dart';
import 'package:test/test.dart';

import '_dependencies.dart';

void main() {
  group('PrettyStructuredPrinter', () {
    test('prints boxed sections and stack trace', () {
      final printer = PrettyStructuredPrinter(
        config: defaultConfig(steps: [LogStep.LEVEL, LogStep.STACKTRACE]),
      );

      final record = sampleRecord(stackTrace: StackTrace.current);
      final output = printer.log(record);

      expect(output.any((line) => line.contains('INFO')), isTrue);
    });
  });

  group('PrettyPrinter', () {
    test('includes visual borders and sections', () {
      final printer = PrettyPrinter(
        config: defaultConfig(steps: [LogStep.MESSAGE, LogStep.ERROR]),
      );

      final record = sampleRecord(message: 'msg', error: 'exception');
      final output = printer.log(record);

      expect(output.any((line) => line.contains('┌')), isTrue);
      expect(output.any((line) => line.contains('❌ ERROR')), isTrue);
    });
  });
}