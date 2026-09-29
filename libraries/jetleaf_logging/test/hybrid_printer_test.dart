import 'package:jetleaf_logging/logging.dart';
import 'package:jetleaf_logging/printers.dart';
import 'package:test/test.dart';

import '_dependencies.dart';

void main() {
  group('HybridPrinter', () {
    test('uses simple printer for DEBUG', () {
      final printer = HybridPrinter();

      final debugRecord = sampleRecord(level: LogLevel.DEBUG, message: 'debug');
      final result = printer.log(debugRecord).first;

      expect(result.toLowerCase(), contains('debug'));
    });

    test('uses pretty printer for INFO', () {
      final printer = HybridPrinter();

      final infoRecord = sampleRecord(level: LogLevel.INFO, message: 'info');
      final result = printer.log(infoRecord);

      expect(result.length, greaterThan(1)); // PrettyPrinter uses box borders
    });
  });
}