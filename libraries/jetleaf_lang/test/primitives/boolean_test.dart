import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

void main() {
  group('Boolean', () {
    test('should create Boolean from bool values', () {
      final trueValue = Boolean(true);
      final falseValue = Boolean(false);
      
      expect(trueValue.value, isTrue);
      expect(falseValue.value, isFalse);
      expect(trueValue, equals(Boolean.TRUE));
      expect(falseValue, equals(Boolean.FALSE));
    });

    test('should parse Boolean from String', () {
      expect(Boolean.parseBoolean('true').value, isTrue);
      expect(Boolean.parseBoolean('TRUE').value, isTrue);
      expect(Boolean.parseBoolean('false').value, isFalse);
      expect(Boolean.parseBoolean('FALSE').value, isFalse);
      expect(Boolean.parseBoolean('anything').value, isFalse);
    });

    test('should compare Boolean values', () {
      expect(Boolean.TRUE.compareTo(Boolean.FALSE), equals(1));
      expect(Boolean.FALSE.compareTo(Boolean.TRUE), equals(-1));
      expect(Boolean.TRUE.compareTo(Boolean.TRUE), equals(0));
    });

    test('should perform logical operations', () {
      expect(Boolean.TRUE.and(Boolean.FALSE).value, isFalse);
      expect(Boolean.TRUE.or(Boolean.FALSE).value, isTrue);
      expect(Boolean.TRUE.xor(Boolean.FALSE).value, isTrue);
      expect(Boolean.TRUE.not().value, isFalse);
    });

    test('should convert to string', () {
      expect(Boolean.TRUE.toString(), equals('true'));
      expect(Boolean.FALSE.toString(), equals('false'));
    });

    test('should handle equality and hashCode', () {
      final true1 = Boolean.valueOf(true);
      final true2 = Boolean.valueOf(true);
      final false1 = Boolean.valueOf(false);
      
      expect(true1, equals(true2));
      expect(true1.hashCode, equals(true2.hashCode));
      expect(true1, isNot(equals(false1)));
    });
  });
}