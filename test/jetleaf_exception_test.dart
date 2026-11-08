import 'package:test/test.dart';
import 'package:jetleaf/jetleaf.dart';

void main() {
  group('JetleafException', () {
    test('should create with null context', () {
      final exception = JetleafException(null);
      expect(exception, isNotNull);
      expect(exception, isA<RuntimeException>());
    });

    test('should return null application context', () {
      final exception = JetleafException(null);
      expect(exception.getApplicationContext(), isNull);
    });

    test('should have correct message', () {
      final exception = JetleafException(null);
      expect(exception.getMessage(), contains('abandoned'));
    });

    test('should be a RuntimeException', () {
      final exception = JetleafException(null);
      expect(exception, isA<RuntimeException>());
    });

    test('should be throwable', () {
      final exception = JetleafException(null);
      expect(exception, isA<Throwable>());
    });
  });
}
