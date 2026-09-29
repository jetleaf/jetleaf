import 'package:jetleaf_logging/logging.dart';
import 'package:jetleaf_logging/printers.dart';
import 'package:test/test.dart';

import 'flat_printer_test.dart' as flat_printer_test;
import 'fmt_printer_test.dart' as fmt_printer_test;
import 'hybrid_printer_test.dart' as hybrid_printer_test;
import 'simple_printer_test.dart' as simple_printer_test;
import 'prefix_printer_test.dart' as prefix_printer_test;
import 'pretty_printer_test.dart' as pretty_printer_test;

void main() => group('Logger Tests', () {
  test('should create logger with default settings', () {
    final logger = Logger();
    expect(logger.listener.runtimeType, equals(DefaultLoggingListener));
    expect(logger.listener, isA<LoggingListener>());
  });

  test('should respect log levels', () {
    final messages = <String>[];
    final logger = Logger(
      level: LogLevel.WARN,
      output: (msg) => messages.add(msg),
    );

    logger.debug('debug message');
    logger.info('info message');
    logger.warn('warning message');

    expect(messages.length, greaterThan(0));
    expect(messages.any((msg) => msg.contains('warning')), isTrue);
  });

  test('should format messages with different printers', () {
    final messages = <String>[];
    
    // Test SimplePrinter
    final simpleLogger = Logger(
      printer: SimplePrinter(),
      output: (msg) => messages.add(msg),
    );
    simpleLogger.info('test message');
    
    expect(messages.isNotEmpty, isTrue);
    expect(messages.first, contains('[I]'));
  });

  test('should handle console-style logging', () {
    // This test just ensures the console methods don't throw
    expect(() => console.log('test'), returnsNormally);
    expect(() => console.info('test'), returnsNormally);
    expect(() => console.warn('test'), returnsNormally);
    expect(() => console.error('test'), returnsNormally);
  });

  group('Logger Level Tests', () {
    test('should compare levels correctly', () {
      expect(LogLevel.DEBUG.isEnabledFor(LogLevel.INFO), isFalse);
      expect(LogLevel.INFO.isEnabledFor(LogLevel.DEBUG), isTrue);
      expect(LogLevel.ERROR.isEnabledFor(LogLevel.ERROR), isTrue);
    });
  });

  group('Logger Printer Tests', () {
    flat_printer_test.main();
    fmt_printer_test.main();
    hybrid_printer_test.main();
    simple_printer_test.main();
    prefix_printer_test.main();
    pretty_printer_test.main();
  });
});