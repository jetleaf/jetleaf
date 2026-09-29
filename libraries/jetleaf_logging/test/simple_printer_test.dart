import 'package:jetleaf_logging/logging.dart';
import 'package:jetleaf_logging/printers.dart';
import 'package:test/test.dart';

import '_dependencies.dart';

void main() {
  group('SimplePrinter', () {
    test('formats basic output', () {
      final printer = SimplePrinter(
        config: defaultConfig(steps: [LogStep.LEVEL, LogStep.MESSAGE]),
      );

      final record = sampleRecord(level: LogLevel.ERROR, message: 'Oops!');
      final result = printer.log(record).first;

      expect(result, contains('[E]'));
      expect(result, contains('Oops!'));
    });
  });
}