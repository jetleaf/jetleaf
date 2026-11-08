import 'package:jetleaf_core/logging.dart';
import 'package:jetleaf_core/printers.dart';
import 'package:test/test.dart';

import '_dependencies.dart';

void main() {
  group('FmtPrinter', () {
    test('formats key-value pairs', () {
      final printer = FmtPrinter(
        config: defaultConfig(steps: [LogStep.LEVEL, LogStep.MESSAGE, LogStep.TIMESTAMP]),
      );

      final record = sampleRecord();
      final result = printer.log(record).first;

      expect(result, contains('level=info'));
      expect(result, contains('msg="Test log"'));
      expect(result, contains('time='));
    });
  });
}