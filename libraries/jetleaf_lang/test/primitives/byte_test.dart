import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../dependencies/exceptions.dart';

void main() {
  group('Byte Tests', () {
    test('constructor and value access', () {
      Byte b = Byte(127);
      expect(b.value, equals(127));
    });

    test('constructor validation', () {
      expect(() => Byte(128), throwsInvalidArgumentException);
      expect(() => Byte(-129), throwsInvalidArgumentException);
      expect(() => Byte(127), returnsNormally);
      expect(() => Byte(-128), returnsNormally);
    });

    test('constants', () {
      expect(Byte.MAX_VALUE, equals(127));
      expect(Byte.MIN_VALUE, equals(-128));
    });

    test('parseByte', () {
      expect(Byte.parseByte("42").value, equals(42));
      expect(Byte.parseByte("7F", 16).value, equals(127));
      expect(Byte.parseByte("1111111", 2).value, equals(127));
    });

    test('valueOf', () {
      Byte b = Byte.valueOf(100);
      expect(b.value, equals(100));
    });

    test('toUnsigned', () {
      Byte positive = Byte(127);
      Byte negative = Byte(-1);
      
      expect(positive.toUnsigned(), equals(127));
      expect(negative.toUnsigned(), equals(255));
    });

    test('arithmetic operations', () {
      Byte a = Byte(10);
      Byte b = Byte(5);
      
      expect((a + b).value, equals(15));
      expect((a - b).value, equals(5));
      expect((a * b).value, equals(50));
      expect((a ~/ b).value, equals(2));
    });

    test('comparison operations', () {
      Byte a = Byte(10);
      Byte b = Byte(5);
      
      expect(a > b, isTrue);
      expect(a < b, isFalse);
      expect(a.compareTo(b), equals(1));
    });

    test('bitwise operations', () {
      Byte a = Byte(12); // 00001100
      Byte b = Byte(10); // 00001010
      
      expect((a & b).value, equals(8)); // 00001000
      expect((a | b).value, equals(14)); // 00001110
      expect((a ^ b).value, equals(6)); // 00000110
    });

    test('abs method', () {
      Byte negative = Byte(-42);
      Byte positive = Byte(42);
      
      expect(negative.abs().value, equals(42));
      expect(positive.abs().value, equals(42));
    });

    test('toString methods', () {
      Byte b = Byte(65); // 'A'
      expect(b.toString(), equals('A'));
      expect(Byte(15).toRadixString(16), equals('f'));
    });

    test('equality and hashCode', () {
      Byte a = Byte(42);
      Byte b = Byte(42);
      Byte c = Byte(43);
      
      expect(a == b, isTrue);
      expect(a == c, isFalse);
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
