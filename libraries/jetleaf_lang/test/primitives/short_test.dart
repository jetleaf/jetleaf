import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../dependencies/exceptions.dart';

void main() {
  group('Short', () {
    test('valid constructor', () {
      expect(Short(0).value, equals(0));
      expect(Short(Short.MIN_VALUE).value, equals(-32768));
      expect(Short(Short.MAX_VALUE).value, equals(32767));
    });

    test('throws on value out of range', () {
      expect(() => Short(Short.MIN_VALUE - 1), throwsInvalidArgumentException);
      expect(() => Short(Short.MAX_VALUE + 1), throwsInvalidArgumentException);
    });

    test('parseShort with default radix', () {
      expect(Short.parseShort("123").value, equals(123));
    });

    test('parseShort with radix', () {
      expect(Short.parseShort("7B", 16).value, equals(123));
    });

    test('parseShort throws on out-of-range value', () {
      expect(() => Short.parseShort("40000"), throwsInvalidArgumentException);
    });

    test('valueOf returns correct instance', () {
      expect(Short.valueOf(123), equals(Short(123)));
    });

    test('toUnsigned for positive and negative values', () {
      expect(Short(12345).toUnsigned(), equals(12345));
      expect(Short(-1).toUnsigned(), equals(65535));
      expect(Short(-32768).toUnsigned(), equals(32768));
    });

    test('abs returns absolute value', () {
      expect(Short(-123).abs(), equals(Short(123)));
      expect(Short(123).abs(), equals(Short(123)));
    });

    test('compareTo behaves correctly', () {
      expect(Short(5).compareTo(Short(10)), lessThan(0));
      expect(Short(10).compareTo(Short(5)), greaterThan(0));
      expect(Short(10).compareTo(Short(10)), equals(0));
    });

    test('== and hashCode', () {
      final a = Short(999);
      final b = Short(999);
      final c = Short(-999);
      expect(a == b, isTrue);
      expect(a == c, isFalse);
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString returns correct string', () {
      expect(Short(321).toString(), equals("321"));
    });

    group('Arithmetic operators', () {
      final a = Short(100);
      final b = Short(200);

      test('+', () => expect(a + b, Short(300)));
      test('-', () => expect(a - b, Short(-100)));
      test('*', () => expect(a * b, Short(20000)));
      test('~/', () => expect(a ~/ b, Short(0)));
      test('%', () => expect(a % b, Short(100)));
      test('unary -', () => expect(-a, Short(-100)));
    });

    group('Comparison operators', () {
      final a = Short(123);
      final b = Short(456);
      final c = Short(123);

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
  });
}