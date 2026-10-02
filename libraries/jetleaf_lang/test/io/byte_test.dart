import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../dependencies/exceptions.dart';

void main() {
  group('Byte', () {
    group('Construction', () {
      test('should create single byte from valid values', () {
        final b1 = Byte(127);
        final b2 = Byte(-128);
        final b3 = Byte(0);
        
        expect(b1.value, equals(127));
        expect(b2.value, equals(-128));
        expect(b3.value, equals(0));
        expect(b1.isSingleByte, isTrue);
      });

      test('should throw error for invalid single byte values', () {
        expect(() => Byte(128), throwsInvalidArgumentException);
        expect(() => Byte(-129), throwsInvalidArgumentException);
        expect(() => Byte(256), throwsInvalidArgumentException);
      });

      test('should create from list of bytes', () {
        final bytes = Byte.fromList([1, 2, 3, -1, -128, 127]);
        
        expect(bytes.length, equals(6));
        expect(bytes.toList(), equals([1, 2, 3, -1, -128, 127]));
        expect(bytes.isSingleByte, isFalse);
      });

      test('should create from unsigned list', () {
        final bytes = Byte.fromUnsignedList([255, 128, 0, 100]);
        
        expect(bytes.toList(), equals([-1, -128, 0, 100]));
        expect(bytes.toUnsignedList(), equals([255, 128, 0, 100]));
      });

      test('should create from string', () {
        final hello = Byte.fromString('Hello');
        
        expect(hello.length, equals(5));
        expect(hello.toString(), equals('Hello'));
        expect(hello.toList(), equals([72, 101, 108, 108, 111]));
      });

      test('should create from hex string', () {
        final hex1 = Byte.fromHexString('48656C6C6F');
        final hex2 = Byte.fromHexString('48 65 6C 6C 6F');
        final hex3 = Byte.fromHexString('FF00AB');
        
        expect(hex1.toString(), equals('Hello'));
        expect(hex2.toString(), equals('Hello'));
        expect(hex3.toList(), equals([-1, 0, -85]));
      });

      test('should create from Uint8List', () {
        final uint8List = Uint8List.fromList([255, 128, 0]);
        final bytes = Byte.fromUint8List(uint8List);
        
        expect(bytes.toList(), equals([-1, -128, 0]));
      });

      test('should create empty byte array', () {
        final empty = Byte.empty();
        
        expect(empty.isEmpty, isTrue);
        expect(empty.length, equals(0));
      });
    });

    group('Static Methods', () {
      test('should parse bytes from strings', () {
        final b1 = Byte.parseByte('42');
        final b2 = Byte.parseByte('FF', 16);
        final b3 = Byte.parseByte('1010', 2);
        final b4 = Byte.parseByte('-128');
        
        expect(b1.value, equals(42));
        expect(b2.value, equals(-1)); // 255 as signed byte
        expect(b3.value, equals(10));
        expect(b4.value, equals(-128));
      });

      test('should validate byte ranges', () {
        expect(Byte.isValidByte(127), isTrue);
        expect(Byte.isValidByte(128), isFalse);
        expect(Byte.isValidByte(-128), isTrue);
        expect(Byte.isValidByte(-129), isFalse);
        
        expect(Byte.isValidUnsignedByte(255), isTrue);
        expect(Byte.isValidUnsignedByte(256), isFalse);
        expect(Byte.isValidUnsignedByte(-1), isFalse);
      });

      test('should convert between signed and unsigned', () {
        expect(Byte.toSignedByte(100), equals(100));
        expect(Byte.toSignedByte(200), equals(-56));
        expect(Byte.toSignedByte(255), equals(-1));
        
        expect(Byte.toUnsignedByte(100), equals(100));
        expect(Byte.toUnsignedByte(-56), equals(200));
        expect(Byte.toUnsignedByte(-1), equals(255));
      });

      test('should calculate checksum', () {
        final checksum1 = Byte.calculateChecksum([1, 2, 3, 4]);
        final checksum2 = Byte.calculateChecksum([255, 255]);
        
        expect(checksum1, equals(10));
        expect(checksum2, equals(-2)); // 510 % 256 = 254 -> -2 as signed
      });

      test('should reverse bytes', () {
        final original = [1, 2, 3, 4];
        final reversed = Byte.reverseBytes(original);
        
        expect(reversed, equals([4, 3, 2, 1]));
      });
    });

    group('Single Byte Operations', () {
      test('should get unsigned representation', () {
        final b1 = Byte(100);
        final b2 = Byte(-56);
        
        expect(b1.toUnsigned(), equals(100));
        expect(b2.toUnsigned(), equals(200));
      });

      test('should get absolute value', () {
        final b1 = Byte(-42);
        final b2 = Byte(42);
        
        expect(b1.abs().value, equals(42));
        expect(b2.abs().value, equals(42));
      });

      test('should convert to different radix strings', () {
        final b = Byte(42);
        
        expect(b.toRadixString(16), equals('2a'));
        expect(b.toRadixString(2), equals('101010'));
        expect(b.toRadixString(8), equals('52'));
      });

      test('should handle arithmetic operations', () {
        final a = Byte(10);
        final b = Byte(20);
        
        expect((a + b).value, equals(30));
        expect((b - a).value, equals(10));
        expect((a * Byte(3)).value, equals(30));
        expect((b ~/ a).value, equals(2));
        expect((b % Byte(3)).value, equals(2));
        expect((-a).value, equals(-10));
      });

      test('should handle bitwise operations', () {
        final a = Byte(0x0F); // 00001111
        final b = Byte(0x33); // 00110011
        
        expect((a & b).value, equals(0x03)); // 00000011
        expect((a | b).value, equals(0x3F)); // 00111111
        expect((a ^ b).value, equals(0x3C)); // 00111100
        expect((~a).value, equals(-16)); // 11110000 as signed
      });

      test('should handle shift operations', () {
        final b = Byte(8); // 00001000
        
        expect((b << 1).value, equals(16)); // 00010000
        expect((b >> 1).value, equals(4));  // 00000100
      });
    });

    group('Array Operations', () {
      test('should convert to different formats', () {
        final bytes = Byte.fromList([100, -56, 0]);
        
        expect(bytes.toList(), equals([100, -56, 0]));
        expect(bytes.toUnsignedList(), equals([100, 200, 0]));
        expect(bytes.toHexString(), equals('64C800'));
        expect(bytes.toBinaryString(), equals('011001001100100000000000'));
      });

      test('should manipulate array contents', () {
        final bytes = Byte.fromList([1, 2, 3]);
        
        bytes.append(4);
        expect(bytes.toList(), equals([1, 2, 3, 4]));
        
        bytes.appendAll([5, 6]);
        expect(bytes.toList(), equals([1, 2, 3, 4, 5, 6]));
        
        bytes.insert(0, 0);
        expect(bytes.toList(), equals([0, 1, 2, 3, 4, 5, 6]));
        
        final removed = bytes.removeAt(0);
        expect(removed, equals(0));
        expect(bytes.toList(), equals([1, 2, 3, 4, 5, 6]));
      });

      test('should handle array indexing', () {
        final bytes = Byte.fromList([10, 20, 30]);
        
        expect(bytes[1], equals(20));
        
        bytes[1] = 25;
        expect(bytes[1], equals(25));
        expect(bytes.toList(), equals([10, 25, 30]));
      });

      test('should create subarrays', () {
        final bytes = Byte.fromList([1, 2, 3, 4, 5]);
        final sub = bytes.subBytes(1, 4);
        
        expect(sub.toList(), equals([2, 3, 4]));
      });

      test('should clear array', () {
        final bytes = Byte.fromList([1, 2, 3]);
        
        bytes.clear();
        expect(bytes.isEmpty, isTrue);
        expect(bytes.length, equals(0));
      });
    });

    group('Comparison and Equality', () {
      test('should compare single bytes', () {
        final a = Byte(10);
        final b = Byte(20);
        final c = Byte(10);
        
        expect(a.compareTo(b), lessThan(0));
        expect(b.compareTo(a), greaterThan(0));
        expect(a.compareTo(c), equals(0));
        
        expect(a < b, isTrue);
        expect(b > a, isTrue);
        expect(a <= c, isTrue);
        expect(a >= c, isTrue);
      });

      test('should compare byte arrays', () {
        final arr1 = Byte.fromList([1, 2, 3]);
        final arr2 = Byte.fromList([1, 2, 4]);
        final arr3 = Byte.fromList([1, 2, 3]);
        final arr4 = Byte.fromList([1, 2]);
        
        expect(arr1.compareTo(arr2), lessThan(0));
        expect(arr1.compareTo(arr3), equals(0));
        expect(arr1.compareTo(arr4), greaterThan(0)); // Longer array
      });

      test('should handle equality correctly', () {
        final a = Byte(42);
        final b = Byte(42);
        final c = Byte(43);
        
        expect(a == b, isTrue);
        expect(a == c, isFalse);
        expect(a.hashCode, equals(b.hashCode));
        
        final arr1 = Byte.fromList([1, 2, 3]);
        final arr2 = Byte.fromList([1, 2, 3]);
        final arr3 = Byte.fromList([1, 2, 4]);
        
        expect(arr1 == arr2, isTrue);
        expect(arr1 == arr3, isFalse);
        expect(arr1.hashCode, equals(arr2.hashCode));
      });
    });

    group('Error Handling', () {
      test('should throw errors for invalid operations on arrays', () {
        final bytes = Byte.fromList([1, 2, 3]);
        
        expect(() => bytes.value, throwsNoGuaranteeException);
        expect(() => bytes.toUnsigned(), throwsNoGuaranteeException);
        expect(() => bytes.abs(), throwsNoGuaranteeException);
        expect(() => bytes.toRadixString(16), throwsNoGuaranteeException);
        expect(() => bytes + Byte(1), throwsNoGuaranteeException);
        expect(() => bytes & Byte(1), throwsNoGuaranteeException);
      });

      test('should throw errors for invalid hex strings', () {
        expect(() => Byte.fromHexString('XYZ'), throwsInvalidFormatException);
        expect(() => Byte.fromHexString('ABC'), throwsInvalidFormatException); // Odd length
      });

      test('should throw errors for out-of-range values', () {
        expect(() => Byte.fromList([128]), throwsInvalidArgumentException);
        expect(() => Byte.fromUnsignedList([256]), throwsInvalidArgumentException);
        expect(() => Byte.toSignedByte(256), throwsInvalidArgumentException);
        expect(() => Byte.toUnsignedByte(128), throwsInvalidArgumentException);
      });

      test('should throw errors for invalid indices', () {
        final bytes = Byte.fromList([1, 2, 3]);
        
        expect(() => bytes[3], throwsRangeError);
        expect(() => bytes[-1], throwsRangeError);
        expect(() => bytes[3] = 4, throwsRangeError);
      });
    });

    group('Edge Cases', () {
      test('should handle empty arrays', () {
        final empty = Byte.empty();
        
        expect(empty.isEmpty, isTrue);
        expect(empty.toString(), equals(''));
        expect(empty.toHexString(), equals(''));
        expect(empty.toBinaryString(), equals(''));
      });

      test('should handle boundary values', () {
        final maxByte = Byte(Byte.MAX_VALUE);
        final minByte = Byte(Byte.MIN_VALUE);
        
        expect(maxByte.value, equals(127));
        expect(minByte.value, equals(-128));
        expect(maxByte.toUnsigned(), equals(127));
        expect(minByte.toUnsigned(), equals(128));
      });

      test('should handle string conversions with special characters', () {
        final bytes = Byte.fromString('\n\t\r');
        
        expect(bytes.length, equals(3));
        expect(bytes.toList(), equals([10, 9, 13])); // ASCII values
      });

      test('should handle arithmetic overflow', () {
        final maxByte = Byte(127);
        
        expect(() => maxByte + Byte(1), throwsInvalidArgumentException); // Would overflow
        expect(() => Byte(-128) - Byte(1), throwsInvalidArgumentException); // Would underflow
      });
    });

    group('Performance and Memory', () {
      test('should handle large byte arrays efficiently', () {
        final largeArray = List.generate(1000, (i) => (i % 256) - 128);
        final bytes = Byte.fromList(largeArray);
        
        expect(bytes.length, equals(1000));
        expect(bytes.toList().length, equals(1000));
      });

      test('should create independent copies', () {
        final original = Byte.fromList([1, 2, 3]);
        final copy = Byte.fromList(original.toList());
        
        copy.append(4);
        expect(original.length, equals(3));
        expect(copy.length, equals(4));
      });
    });
  });
}