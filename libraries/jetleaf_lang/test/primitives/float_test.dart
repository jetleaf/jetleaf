import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../dependencies/exceptions.dart';

void main() {
  group('Float class', () {
    test('value getter returns correct value', () {
      expect(Float(3.14).value, 3.14);
    });

    test('parseFloat parses valid strings', () {
      expect(Float.parseFloat("2.718").value, closeTo(2.718, 1e-10));
    });

    test('parseFloat throws on invalid string', () {
      expect(() => Float.parseFloat("invalid"), throwsInvalidFormatException);
    });

    test('valueOf returns correct Float instance', () {
      expect(Float.valueOf(1.23).value, 1.23);
    });

    test('valueOfString returns correct Float from string', () {
      expect(Float.valueOfString("1.5").value, 1.5);
    });

    test('max returns the greater of two numbers', () {
      expect(Float.max(3.0, 2.0), 3.0);
    });

    test('min returns the smaller of two numbers', () {
      expect(Float.min(3.0, 2.0), 2.0);
    });

    test('special number properties', () {
      expect(Float(double.nan).isNaN, isTrue);
      expect(Float(double.infinity).isInfinite, isTrue);
      expect(Float(10.0).isFinite, isTrue);
      expect(Float(-5.0).isNegative, isTrue);
    });

    test('abs returns absolute value', () {
      expect(Float(-9.1).abs(), Float(9.1));
    });

    test('ceil returns next higher integer', () {
      expect(Float(2.1).ceil(), Float(3.0));
    });

    test('floor returns next lower integer', () {
      expect(Float(2.9).floor(), Float(2.0));
    });

    test('round returns closest integer', () {
      expect(Float(2.5).round(), Float(3.0));
      expect(Float(2.4).round(), Float(2.0));
    });

    test('truncate returns truncated value', () {
      expect(Float(3.7).truncate(), Float(3.0));
    });

    test('compareTo returns correct ordering', () {
      expect(Float(1.0).compareTo(Float(2.0)), lessThan(0));
      expect(Float(2.0).compareTo(Float(1.0)), greaterThan(0));
      expect(Float(2.0).compareTo(Float(2.0)), equals(0));
    });

    test('equality and hashCode work correctly', () {
      final a = Float(1.0);
      final b = Float(1.0);
      final c = Float(2.0);
      expect(a == b, isTrue);
      expect(a == c, isFalse);
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString returns correct string', () {
      expect(Float(3.14).toString(), '3.14');
    });

    test('toInt returns truncated integer', () {
      expect(Float(3.99).toInt(), 3);
    });

    group('arithmetic operators', () {
      final a = Float(5.0);
      final b = Float(2.0);

      test('+', () => expect(a + b, Float(7.0)));
      test('-', () => expect(a - b, Float(3.0)));
      test('*', () => expect(a * b, Float(10.0)));
      test('/', () => expect(a / b, Float(2.5)));
      test('%', () => expect(a % b, Float(1.0)));
      test('unary -', () => expect(-a, Float(-5.0)));
    });

    group('comparison operators', () {
      final a = Float(1.0);
      final b = Float(2.0);
      final c = Float(1.0);

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