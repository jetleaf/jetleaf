import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../dependencies/exceptions.dart';

void main() {
  group('BigDecimal Tests', () {
    test('constructor from string', () {
      BigDecimal a = BigDecimal("123.456");
      expect(a.toString(), equals("123.456"));
      expect(a.scale, equals(3));
    });

    test('constructor from integer string', () {
      BigDecimal a = BigDecimal("123");
      expect(a.toString(), equals("123"));
      expect(a.scale, equals(0));
    });

    test('fromDouble constructor', () {
      BigDecimal a = BigDecimal.fromDouble(123.456);
      expect(a.toString(), equals("123.456"));
    });

    test('fromInt constructor', () {
      BigDecimal a = BigDecimal.fromInt(123);
      expect(a.toString(), equals("123"));
    });

    test('addition', () {
      BigDecimal a = BigDecimal("123.45");
      BigDecimal b = BigDecimal("67.89");
      BigDecimal result = a + b;
      expect(result.toString(), equals("191.34"));
    });

    test('subtraction', () {
      BigDecimal a = BigDecimal("123.45");
      BigDecimal b = BigDecimal("67.89");
      BigDecimal result = a - b;
      expect(result.toString(), equals("55.56"));
    });

    test('multiplication', () {
      BigDecimal a = BigDecimal("12.34");
      BigDecimal b = BigDecimal("5.6");
      BigDecimal result = a * b;
      expect(result.toString(), equals("69.104"));
    });

    test('division', () {
      BigDecimal a = BigDecimal("10.0");
      BigDecimal b = BigDecimal("3.0");
      BigDecimal result = a.divide(b, 2);
      expect(result.toString(), equals("3.33"));
    });

    test('setScale', () {
      BigDecimal a = BigDecimal("123.456");
      BigDecimal rounded = a.setScale(2);
      expect(rounded.toString(), equals("123.46"));
    });

    test('setScale increase', () {
      BigDecimal a = BigDecimal("123.45");
      BigDecimal extended = a.setScale(4);
      expect(extended.toString(), equals("123.4500"));
    });

    test('comparison', () {
      BigDecimal a = BigDecimal("123.45");
      BigDecimal b = BigDecimal("123.46");
      BigDecimal c = BigDecimal("123.45");
      
      expect(a < b, isTrue);
      expect(a > b, isFalse);
      expect(a == c, isTrue);
      expect(a.compareTo(b), lessThan(0));
      expect(a.compareTo(c), equals(0));
    });

    test('abs and negation', () {
      BigDecimal positive = BigDecimal("123.45");
      BigDecimal negative = BigDecimal("-123.45");
      
      expect(negative.abs().toString(), equals("123.45"));
      expect((-positive).toString(), equals("-123.45"));
    });

    test('precision', () {
      BigDecimal a = BigDecimal("123.456");
      expect(a.precision, equals(6));
      
      BigDecimal b = BigDecimal("-123.456");
      expect(b.precision, equals(6));
    });

    test('constants', () {
      expect(BigDecimal.ZERO.toString(), equals("0"));
      expect(BigDecimal.ONE.toString(), equals("1"));
      expect(BigDecimal.TEN.toString(), equals("10"));
    });

    test('toDouble conversion', () {
      BigDecimal a = BigDecimal("123.456");
      expect(a.toDouble(), closeTo(123.456, 0.001));
    });

    test('division by zero', () {
      BigDecimal a = BigDecimal("10");
      BigDecimal zero = BigDecimal.ZERO;
      expect(() => a.divide(zero), throwsInvalidArgumentException);
    });

    test('equality and hashCode', () {
      BigDecimal a = BigDecimal("123.45");
      BigDecimal b = BigDecimal("123.45");
      BigDecimal c = BigDecimal("123.46");
      
      expect(a == b, isTrue);
      expect(a == c, isFalse);
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
