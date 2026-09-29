import 'package:jetleaf_logging/logging.dart';
import 'package:jetleaf_logging/printers.dart';
import 'package:test/test.dart';

import '_dependencies.dart';

void main() {
  group('PrefixPrinter', () {
    test('applies prefix and color', () {
      final printer = PrefixPrinter(
        config: defaultConfig(steps: [LogStep.LEVEL, LogStep.MESSAGE]),
      );

      final record = sampleRecord(level: LogLevel.WARN, message: 'Warning!');
      final result = printer.log(record).first;

      expect(result, contains('⚠️'));
      expect(result, contains('Warning!'));
    });
  });
}