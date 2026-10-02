import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../dependencies/exceptions.dart'; // Update path as needed

void main() {
  group('BigInteger', () {
    test('constructors and toString', () {
      expect(BigInteger('12345678901234567890').toString(), '12345678901234567890');
      expect(BigInteger.fromInt(42).toString(), '42');
      expect(BigInteger.fromBigInt(BigInt.from(99)).toString(), '99');
    });

    test('arithmetic operations', () {
      final a = BigInteger('100');
      final b = BigInteger('25');

      expect((a + b).toString(), '125');
      expect((a - b).toString(), '75');
      expect((a * b).toString(), '2500');
      expect((a ~/ b).toString(), '4');
      expect((a % b).toString(), '0');
    });

    test('bitwise operations', () {
      final a = BigInteger('12'); // 1100
      final b = BigInteger('10'); // 1010

      expect((a & b).toString(), '8');
      expect((a | b).toString(), '14');
      expect((a ^ b).toString(), '6');
      expect((~a).toString(), (-13).toString());
      expect((a << 2).toString(), '48');
      expect((a >> 2).toString(), '3');
    });

    test('comparison and equality', () {
      final a = BigInteger('123');
      final b = BigInteger('123');
      final c = BigInteger('456');

      expect(a == b, isTrue);
      expect(a == c, isFalse);
      expect(a < c, isTrue);
      expect(c > a, isTrue);
      expect(a.compareTo(b), 0);
      expect(a.compareTo(c), lessThan(0));
    });

    test('pow and mod operations', () {
      final base = BigInteger('2');
      final exp = 10;

      expect(base.pow(exp).toString(), '1024');

      final mod = BigInteger('17');
      final result = base.modPow(BigInteger.fromInt(5), mod);
      expect(result.toString(), '15');

      final inv = BigInteger('3').modInverse(BigInteger('11'));
      expect(inv.toString(), '4');
    });

    test('gcd and abs', () {
      final a = BigInteger('-36');
      final b = BigInteger('60');

      expect(a.gcd(b).toString(), '12');
      expect(a.abs().toString(), '36');
    });

    test('isProbablePrime basic test', () {
      expect(BigInteger('2').isProbablePrime(), isTrue);
      expect(BigInteger('3').isProbablePrime(), isTrue);
      expect(BigInteger('4').isProbablePrime(), isFalse);
      expect(BigInteger('29').isProbablePrime(), isTrue);
    });

    test('conversion methods', () {
      final n = BigInteger('255');

      expect(n.toInt(), 255);
      expect(n.toDouble(), 255.0);
      expect(n.toRadixString(16), 'ff');
    });

    test('constants', () {
      expect(BigInteger.ZERO.toString(), '0');
      expect(BigInteger.ONE.toString(), '1');
      expect(BigInteger.TWO.toString(), '2');
      expect(BigInteger.TEN.toString(), '10');
    });

    test('throws on negative exponent in pow', () {
      expect(() => BigInteger('2').pow(-1), throwsInvalidArgumentException);
    });
  });
}