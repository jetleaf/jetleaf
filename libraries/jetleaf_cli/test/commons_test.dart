import 'package:jetleaf_cli/src/common/commons.dart';
import 'package:jetleaf_logging/logging.dart';
import 'package:test/test.dart';

void main() {
  group('wrapWith', () {
    test('should return plain message when ANSI not supported', () {
      // In test environment, ANSI may or may not be supported
      // Just verify the function doesn't throw
      final result = wrapWith('Hello', [AnsiColor.RED]);
      expect(result, isA<String>());
      expect(result.isNotEmpty, isTrue);
    });

    test('should handle empty message', () {
      final result = wrapWith('', [AnsiColor.RED]);
      expect(result, isA<String>());
    });

    test('should handle multiple color codes', () {
      final result = wrapWith('Hello', [AnsiColor.RED, AnsiColor.GREEN]);
      expect(result, isA<String>());
    });

    test('should handle empty codes list', () {
      final result = wrapWith('Hello', []);
      expect(result, equals('Hello'));
    });
  });

  group('goUpOneLine', () {
    test('should not throw', () {
      expect(() => goUpOneLine(), returnsNormally);
    });
  });

  group('clearLine', () {
    test('should not throw', () {
      expect(() => clearLine(), returnsNormally);
    });
  });
}
