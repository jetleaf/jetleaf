import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../dependencies/exceptions.dart';

void main() {
  group('Double class', () {
    test('value getter returns the correct value', () {
      expect(Double(3.14).value, 3.14);
    });

    test('parseDouble parses valid strings', () {
      expect(Double.parseDouble("2.718").value, closeTo(2.718, 1e-10));
    });

    test('parseDouble throws on invalid input', () {
      expect(() => Double.parseDouble("abc"), throwsInvalidFormatException);
    });

    test('valueOf returns correct instance', () {
      final d = Double.valueOf(1.618);
      expect(d.value, 1.618);
    });

    test('valueOfString delegates to parseDouble', () {
      final d = Double.valueOfString("1.618");
      expect(d.value, 1.618);
    });

    test('max returns larger value', () {
      expect(Double.max(2.0, 3.0), 3.0);
      expect(Double.max(5.5, 5.0), 5.5);
    });

    test('min returns smaller value', () {
      expect(Double.min(2.0, 3.0), 2.0);
      expect(Double.min(5.5, 5.0), 5.0);
    });

    test('isNaN, isInfinite, isFinite, isNegative', () {
      expect(Double(double.nan).isNaN, isTrue);
      expect(Double(double.infinity).isInfinite, isTrue);
      expect(Double(42.0).isFinite, isTrue);
      expect(Double(-5.0).isNegative, isTrue);
    });

    test('abs returns absolute value', () {
      expect(Double(-7.1).abs(), Double(7.1));
    });

    test('ceil returns ceiling value', () {
      expect(Double(2.1).ceil(), Double(3.0));
    });

    test('floor returns floor value', () {
      expect(Double(2.9).floor(), Double(2.0));
    });

    test('round returns nearest int value', () {
      expect(Double(2.5).round(), Double(3.0));
      expect(Double(2.4).round(), Double(2.0));
    });

    test('truncate returns truncated value', () {
      expect(Double(2.9).truncate(), Double(2.0));
      expect(Double(-2.9).truncate(), Double(-2.0));
    });

    test('compareTo works as expected', () {
      expect(Double(2.0).compareTo(Double(3.0)), lessThan(0));
      expect(Double(3.0).compareTo(Double(2.0)), greaterThan(0));
      expect(Double(2.0).compareTo(Double(2.0)), equals(0));
    });

    test('equality and hashCode', () {
      final a = Double(1.0);
      final b = Double(1.0);
      final c = Double(2.0);

      expect(a == b, isTrue);
      expect(a == c, isFalse);
      expect(a.hashCode, b.hashCode);
    });

    test('toString returns correct string', () {
      expect(Double(3.14).toString(), '3.14');
    });

    test('toInt returns truncated int', () {
      expect(Double(3.99).toInt(), 3);
    });

    group('arithmetic operators', () {
      final a = Double(2.0);
      final b = Double(3.0);

      test('+', () => expect(a + b, Double(5.0)));
      test('-', () => expect(b - a, Double(1.0)));
      test('*', () => expect(a * b, Double(6.0)));
      test('/', () => expect(b / a, Double(1.5)));
      test('%', () => expect(b % a, Double(1.0)));
      test('unary -', () => expect(-a, Double(-2.0)));
    });

    group('comparison operators', () {
      final a = Double(2.0);
      final b = Double(3.0);
      final c = Double(2.0);

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