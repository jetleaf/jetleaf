import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../dependencies/exceptions.dart';

void main() {
  group('NumberUtils', () {
    group('STANDARD_NUMBER_TYPES', () {
      test('contains all standard number types', () {
        expect(NumberUtils.STANDARD_NUMBER_TYPES.length, equals(12));
        expect(NumberUtils.STANDARD_NUMBER_TYPES, contains(Class<Byte>()));
        expect(NumberUtils.STANDARD_NUMBER_TYPES, contains(Class<Short>()));
        expect(NumberUtils.STANDARD_NUMBER_TYPES.any((c) => c == Class<int>()), isTrue);
        expect(NumberUtils.STANDARD_NUMBER_TYPES.any((c) => c == Class<double>()), isTrue);
        expect(NumberUtils.STANDARD_NUMBER_TYPES.any((c) => c == Class<num>()), isTrue);
        expect(NumberUtils.STANDARD_NUMBER_TYPES.any((c) => c == Class<BigInt>()), isTrue);
      });
    });

    group('convertNumberToTargetClass', () {
      test('converts int to Byte', () {
        final result = NumberUtils.convertNumberToTargetClass(42, Class<Byte>());
        expect(result, isA<Byte>());
        expect((result).value, equals(42));
      });

      test('converts int to Short', () {
        final result = NumberUtils.convertNumberToTargetClass(1000, Class<Short>());
        expect(result, isA<Short>());
        expect((result).value, equals(1000));
      });

      test('converts int to Integer', () {
        final result = NumberUtils.convertNumberToTargetClass(12345, Class<Integer>());
        expect(result, isA<Integer>());
        expect((result).value, equals(12345));
      });

      test('converts int to Long', () {
        final result = NumberUtils.convertNumberToTargetClass(999999, Class<Long>());
        expect(result, isA<Long>());
        expect((result).value, equals(999999));
      });

      test('converts int to BigInteger', () {
        final result = NumberUtils.convertNumberToTargetClass(42, Class<BigInteger>());
        expect(result, isA<BigInteger>());
        expect((result).toInt(), equals(42));
      });

      test('converts int to Float', () {
        final result = NumberUtils.convertNumberToTargetClass(42, Class<Float>());
        expect(result, isA<Float>());
        expect((result).value, equals(42.0));
      });

      test('converts int to Double', () {
        final result = NumberUtils.convertNumberToTargetClass(42, Class<Double>());
        expect(result, isA<Double>());
        expect((result).value, equals(42.0));
      });

      test('converts int to BigDecimal', () {
        final result = NumberUtils.convertNumberToTargetClass(42, Class<BigDecimal>());
        expect(result, isA<BigDecimal>());
        expect((result).toString(), equals('42'));
      });

      test('converts int to int', () {
        final result = NumberUtils.convertNumberToTargetClass(42, Class<int>());
        expect(result, equals(42));
      });

      test('converts int to double', () {
        final result = NumberUtils.convertNumberToTargetClass(42, Class<double>());
        expect(result, equals(42.0));
      });

      test('converts int to num', () {
        final result = NumberUtils.convertNumberToTargetClass(42, Class<num>());
        expect(result, equals(42));
      });

      test('converts int to BigInt', () {
        final result = NumberUtils.convertNumberToTargetClass(42, Class<BigInt>());
        expect(result, equals(BigInt.from(42)));
      });

      test('converts double to Float', () {
        final result = NumberUtils.convertNumberToTargetClass(3.14, Class<Float>());
        expect(result, isA<Float>());
        expect((result).value, closeTo(3.14, 0.001));
      });

      test('converts double to Double', () {
        final result = NumberUtils.convertNumberToTargetClass(3.14, Class<Double>());
        expect(result, isA<Double>());
        expect((result).value, equals(3.14));
      });

      test('converts double to BigDecimal', () {
        final result = NumberUtils.convertNumberToTargetClass(3.14, Class<BigDecimal>());
        expect(result, isA<BigDecimal>());
      });

      test('throws on unsupported target class', () {
        expect(
          () => NumberUtils.convertNumberToTargetClass(42, Class<String>()),
          throwsIllegalArgumentException,
        );
      });
    });

    group('parseNumber', () {
      test('parses decimal string to Integer', () {
        final result = NumberUtils.parseNumber('123', Class<Integer>());
        expect(result, isA<Integer>());
        expect((result).value, equals(123));
      });

      test('parses hex string to Integer', () {
        final result = NumberUtils.parseNumber('0xFF', Class<Integer>());
        expect(result, isA<Integer>());
        expect((result).value, equals(255));
      });

      test('parses hex string with # to Integer', () {
        final result = NumberUtils.parseNumber('#FF', Class<Integer>());
        expect(result, isA<Integer>());
        expect((result).value, equals(255));
      });

      test('parses decimal string to Long', () {
        final result = NumberUtils.parseNumber('999999', Class<Long>());
        expect(result, isA<Long>());
        expect((result).value, equals(999999));
      });

      test('parses hex string to Long', () {
        final result = NumberUtils.parseNumber('0xFF', Class<Long>());
        expect(result, isA<Long>());
        expect((result).value, equals(255));
      });

      test('parses decimal string to BigInteger', () {
        final result = NumberUtils.parseNumber('12345678901234567890', Class<BigInteger>());
        expect(result, isA<BigInteger>());
        expect((result).toString(), equals('12345678901234567890'));
      });

      test('parses hex string to BigInteger', () {
        final result = NumberUtils.parseNumber('0xFF', Class<BigInteger>());
        expect(result, isA<BigInteger>());
        expect((result).toInt(), equals(255));
      });

      test('parses octal string to BigInteger', () {
        final result = NumberUtils.parseNumber('077', Class<BigInteger>());
        expect(result, isA<BigInteger>());
        expect((result).toInt(), equals(63));
      });

      test('parses string to Float', () {
        final result = NumberUtils.parseNumber('3.14', Class<Float>());
        expect(result, isA<Float>());
        expect((result).value, closeTo(3.14, 0.001));
      });

      test('parses string to Double', () {
        final result = NumberUtils.parseNumber('3.14', Class<Double>());
        expect(result, isA<Double>());
        expect((result).value, equals(3.14));
      });

      test('parses string to BigDecimal', () {
        final result = NumberUtils.parseNumber('3.14', Class<BigDecimal>());
        expect(result, isA<BigDecimal>());
        expect((result).toString(), equals('3.14'));
      });

      test('parses string to int', () {
        final result = NumberUtils.parseNumber('42', Class<int>());
        expect(result, equals(42));
      });

      test('parses string to double', () {
        final result = NumberUtils.parseNumber('3.14', Class<double>());
        expect(result, equals(3.14));
      });

      test('parses string to num', () {
        final result = NumberUtils.parseNumber('42', Class<num>());
        expect(result, equals(42));
      });

      test('parses string to BigInt', () {
        final result = NumberUtils.parseNumber('12345678901234567890', Class<BigInt>());
        expect(result, equals(BigInt.parse('12345678901234567890')));
      });

      test('parses hex string to BigInt', () {
        final result = NumberUtils.parseNumber('0xFF', Class<BigInt>());
        expect(result, equals(BigInt.from(255)));
      });

      test('trims whitespace from input', () {
        final result = NumberUtils.parseNumber('  42  ', Class<int>());
        expect(result, equals(42));
      });

      test('parses negative hex to Long', () {
        final result = NumberUtils.parseNumber('-0xFF', Class<Long>());
        expect(result, isA<Long>());
        expect((result).value, equals(-255));
      });

      test('throws on unsupported target class', () {
        expect(
          () => NumberUtils.parseNumber('42', Class<String>()),
          throwsIllegalArgumentException,
        );
      });
    });
  });
}
