import 'package:jetleaf_env/property.dart';
import 'package:test/test.dart';

void main() {
  group('JetleafProperty', () {
    test('stores key, value, and description', () {
      final prop = JetleafProperty.custom('server.port', 8080, 'The TCP port');
      expect(prop.key, equals('server.port'));
      expect(prop.value, equals(8080));
      expect(prop.description, equals('The TCP port'));
    });

    test('custom factory creates property without description', () {
      final prop = JetleafProperty.custom('server.port', 8080);
      expect(prop.key, equals('server.port'));
      expect(prop.value, equals(8080));
      expect(prop.description, isNull);
    });

    test('copyWith creates modified copy', () {
      final original = JetleafProperty.custom('server.port', 8080, 'Original');
      final copied = original.copyWith(value: 9090);

      expect(copied.key, equals('server.port'));
      expect(copied.value, equals(9090));
      expect(copied.description, equals('Original'));
    });

    test('copyWith with key changes key', () {
      final original = JetleafProperty.custom('old.key', 'value');
      final copied = original.copyWith(key: 'new.key');
      expect(copied.key, equals('new.key'));
    });

    test('equality based on key, value, description', () {
      final p1 = JetleafProperty.custom('key', 'value', 'desc');
      final p2 = JetleafProperty.custom('key', 'value', 'desc');
      expect(p1, equals(p2));
    });

    test('inequality when values differ', () {
      final p1 = JetleafProperty.custom('key', 'value1');
      final p2 = JetleafProperty.custom('key', 'value2');
      expect(p1, isNot(equals(p2)));
    });

    test('toString contains key and value', () {
      final prop = JetleafProperty.custom('server.port', 8080, 'Port');
      final str = prop.toString();
      expect(str, contains('server.port'));
      expect(str, contains('8080'));
    });
  });
}