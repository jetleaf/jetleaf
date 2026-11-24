import 'package:jetleaf_core/logging.dart';
import 'package:jetleaf_core/printers.dart';
import 'package:test/test.dart';

import '_dependencies.dart';
import '../lang/meta/test_data.dart' show ensureTestAotRegisteredSync;

void main() {
  ensureTestAotRegisteredSync();
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