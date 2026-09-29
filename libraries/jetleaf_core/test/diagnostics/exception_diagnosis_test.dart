import 'package:jetleaf_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('ExceptionDiagnosis', () {
    test('stores cause, description, and action', () {
      final exception = FormatException('bad format');
      final diagnosis = ExceptionDiagnosis(
        cause: exception,
        description: 'Configuration file is malformed',
        action: 'Check the file format',
      );

      expect(diagnosis.cause, equals(exception));
      expect(diagnosis.getDescription(), equals('Configuration file is malformed'));
      expect(diagnosis.action, equals('Check the file format'));
    });

    test('description defaults to empty string', () {
      final diagnosis = ExceptionDiagnosis(cause: Exception('test'));
      expect(diagnosis.getDescription(), equals(''));
    });

    test('action is nullable', () {
      final diagnosis = ExceptionDiagnosis(cause: Exception('test'));
      expect(diagnosis.action, isNull);
    });
  });
}