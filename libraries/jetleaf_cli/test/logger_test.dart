import 'package:jetleaf_cli/src/common/logger.dart';
import 'package:test/test.dart';

void main() {
  group('CliLogger', () {
    late CliLogger logger;

    setUp(() {
      logger = CliLogger('TEST');
    });

    test('should create with name', () {
      expect(logger.name, equals('TEST'));
    });

    test('should have info method', () {
      // Should not throw
      logger.info('Test info message');
    });

    test('should have warn method', () {
      // Should not throw
      logger.warn('Test warn message');
    });

    test('should have error method', () {
      // Should not throw (outputs to stderr)
      logger.error('Test error message');
    });

    test('should have space method', () {
      // Should not throw
      logger.space();
    });

    test('should have onInfo adapter', () {
      logger.onInfo('adapter info', true);
      logger.onInfo('adapter info', false);
    });

    test('should have onWarn adapter', () {
      logger.onWarn('adapter warn', true);
    });

    test('should have onError adapter', () {
      logger.onError('adapter error', true);
    });
  });

  group('CliSession', () {
    late CliSession session;

    setUp(() {
      session = CliSession();
    });

    test('should create logger by name', () {
      final logger = session.get('MyComponent');
      expect(logger, isA<CliLogger>());
      expect(logger.name, equals('MyComponent'));
    });

    test('should create different loggers for different names', () {
      final logger1 = session.get('Component1');
      final logger2 = session.get('Component2');
      expect(logger1.name, isNot(equals(logger2.name)));
    });
  });

  group('cliSession global', () {
    test('should be a CliSession instance', () {
      expect(cliSession, isA<CliSession>());
    });

    test('should create loggers', () {
      final logger = cliSession.get('GlobalTest');
      expect(logger, isA<CliLogger>());
    });
  });
}
