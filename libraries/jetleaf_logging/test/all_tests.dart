import 'package:test/test.dart';

import 'logger_test.dart' as logger_test;
import 'flat_printer_test.dart' as flat_printer_test;
import 'fmt_printer_test.dart' as fmt_printer_test;
import 'simple_printer_test.dart' as simple_printer_test;
import 'pretty_printer_test.dart' as pretty_printer_test;
import 'hybrid_printer_test.dart' as hybrid_printer_test;
import 'prefix_printer_test.dart' as prefix_printer_test;

void main() {
  group('logger', () {
    logger_test.main();
  });
  group('flat_printer', () {
    flat_printer_test.main();
  });
  group('fmt_printer', () {
    fmt_printer_test.main();
  });
  group('simple_printer', () {
    simple_printer_test.main();
  });
  group('pretty_printer', () {
    pretty_printer_test.main();
  });
  group('hybrid_printer', () {
    hybrid_printer_test.main();
  });
  group('prefix_printer', () {
    prefix_printer_test.main();
  });
}