import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../dependencies/exceptions.dart';

void main() {
  group('Long class', () {
    test('value getter returns correct value', () {
      expect(Long(123456789).value, equals(123456789));
    });

    test('parseLong parses valid string', () {
      expect(Long.parseLong("987654321").value, equals(987654321));
    });

    test('parseLong throws on invalid string', () {
      expect(() => Long.parseLong("notanumber"), throwsInvalidFormatException);
    });

    test('parseLong with radix', () {
      expect(Long.parseLong("ff", 16).value, equals(255));
    });

    test('valueOf returns correct Long', () {
      expect(Long.valueOf(1000), equals(Long(1000)));
    });

    test('valueOfString returns correct Long', () {
      expect(Long.valueOfString("42").value, equals(42));
    });

    test('valueOfString with radix', () {
      expect(Long.valueOfString("1010", 2).value, equals(10));
    });

    test('max returns larger int', () {
      expect(Long.max(10, 20), equals(20));
    });

    test('min returns smaller int', () {
      expect(Long.min(10, 20), equals(10));
    });

    test('abs returns positive Long', () {
      expect(Long(-500).abs(), equals(Long(500)));
    });

    test('compareTo returns correct ordering', () {
      expect(Long(5).compareTo(Long(10)), lessThan(0));
      expect(Long(10).compareTo(Long(5)), greaterThan(0));
      expect(Long(10).compareTo(Long(10)), equals(0));
    });

    test('equality and hashCode', () {
      final a = Long(999);
      final b = Long(999);
      final c = Long(1000);
      expect(a == b, isTrue);
      expect(a == c, isFalse);
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString returns string representation', () {
      expect(Long(12345).toString(), equals("12345"));
    });

    test('toRadixString works with and without radix', () {
      final long = Long(255);
      expect(long.toRadixString(), equals("255"));
      expect(long.toRadixString(16), equals("ff"));
      expect(long.toRadixString(2), equals("11111111"));
    });

    test('toDouble converts to double', () {
      expect(Long(100).toDouble(), equals(100.0));
    });

    test('isEven and isOdd', () {
      expect(Long(10).isEven, isTrue);
      expect(Long(11).isOdd, isTrue);
    });

    test('isNegative works correctly', () {
      expect(Long(-1).isNegative, isTrue);
      expect(Long(1).isNegative, isFalse);
    });

    group('arithmetic operators', () {
      final a = Long(20);
      final b = Long(5);

      test('+', () => expect(a + b, Long(25)));
      test('-', () => expect(a - b, Long(15)));
      test('*', () => expect(a * b, Long(100)));
      test('~/', () => expect(a ~/ b, Long(4)));
      test('%', () => expect(a % b, Long(0)));
      test('unary -', () => expect(-a, Long(-20)));
    });

    group('comparison operators', () {
      final a = Long(10);
      final b = Long(20);
      final c = Long(10);

      test('<', () => expect(a < b, isTrue));
      test('<=', () {
        expect(a <= b, isTrue);
        expect(a <= c, isTrue);
      });
      test('>', () => expect(b > a, isTrue));
      test('>=', () {
        expect(b >= a, isTrue);
        expect(a >= c, isTrue);
      });
    });

    group('bitwise operators', () {
      final a = Long(12); // 0b1100
      final b = Long(10); // 0b1010

      test('&', () => expect(a & b, Long(8)));   // 0b1000
      test('|', () => expect(a | b, Long(14)));  // 0b1110
      test('^', () => expect(a ^ b, Long(6)));   // 0b0110
      test('~', () => expect(~a, Long(~12)));    // -13
      test('<<', () => expect(a << 2, Long(48))); // 12 << 2 = 48
      test('>>', () => expect(a >> 2, Long(3)));  // 12 >> 2 = 3
    });
  });
}