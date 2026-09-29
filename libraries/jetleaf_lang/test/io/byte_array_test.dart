import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../dependencies/exceptions.dart';

void main() {
  group('ByteArray', () {
    test('creates from string and converts back', () {
      final b = ByteArray.fromString('Hello');
      expect(b.toStringAsChars(), 'Hello');
    });

    test('creates from list and copies correctly', () {
      final b = ByteArray.fromList([72, 101, 108]);
      final copy = b.copy();
      expect(copy.toList(), [72, 101, 108]);
    });

    test('copy with range', () {
      final b = ByteArray.fromList([1, 2, 3, 4]);
      final partial = b.copy(1, 3);
      expect(partial.toList(), [2, 3]);
    });

    test('set and get with bounds and value check', () {
      final b = ByteArray(3);
      b.set(0, 255);
      expect(b.get(0), 255);
      expect(() => b.set(1, -1), throwsInvalidArgumentException);
      expect(() => b.set(1, 300), throwsInvalidArgumentException);
    });

    test('filled constructor validates range', () {
      final b = ByteArray.filled(4, 16);
      expect(b.toList(), everyElement(16));
      expect(() => ByteArray.filled(3, -5), throwsInvalidArgumentException);
    });

    test('copyTo copies correct bytes', () {
      final src = ByteArray.fromList([1, 2, 3]);
      final dest = ByteArray(3);
      src.copyTo(0, dest, 0, 3);
      expect(dest.toList(), [1, 2, 3]);
    });

    test('subArray returns correct slice', () {
      final b = ByteArray.fromList([0, 1, 2, 3, 4]);
      final sub = b.subArray(1, 4);
      expect(sub.toList(), [1, 2, 3]);
    });

    test('fill replaces bytes with correct value', () {
      final b = ByteArray(5);
      b.fill(42);
      expect(b.toList(), everyElement(42));
      expect(() => b.fill(-1), throwsInvalidArgumentException);
    });

    test('reverse and sort', () {
      final b = ByteArray.fromList([3, 2, 1]);
      b.reverse();
      expect(b.toList(), [1, 2, 3]);
      b.sort();
      expect(b.toList(), [1, 2, 3]);
    });

    test('indexOf and lastIndexOf', () {
      final b = ByteArray.fromList([10, 20, 30, 10, 40]);
      expect(b.indexOf(10), 0);
      expect(b.lastIndexOf(10), 3);
      expect(b.indexOf(99), -1);
    });

    test('contains returns true if value exists', () {
      final b = ByteArray.fromList([1, 2, 3]);
      expect(b.contains(2), isTrue);
      expect(b.contains(4), isFalse);
    });

    test('toUint8List and fromUint8List', () {
      final b = ByteArray.fromList([1, 2, 3]);
      final u8 = b.toUint8List();
      expect(u8, isA<Uint8List>());
      final fromU8 = ByteArray.fromUint8List(u8);
      expect(fromU8, b);
    });

    test('hex encoding and decoding', () {
      final b = ByteArray.fromString('Hi');
      final hex = b.toHexString();
      final fromHex = ByteArray.fromHexString(hex);
      expect(fromHex.toList(), b.toList());
      expect(() => ByteArray.fromHexString('abc'), throwsInvalidArgumentException);
    });

    test('concat combines two ByteArrays', () {
      final a = ByteArray.fromList([1, 2]);
      final b = ByteArray.fromList([3, 4]);
      final c = a.concat(b);
      expect(c.toList(), [1, 2, 3, 4]);
    });

    test('operator [] and []= work', () {
      final b = ByteArray.filled(2, 0);
      b[0] = 100;
      expect(b[0], 100);
    });

    test('operator + (concatenation)', () {
      final a = ByteArray.fromList([1]);
      final b = ByteArray.fromList([2]);
      final c = a + b;
      expect(c.toList(), [1, 2]);
    });

    test('equality and hashCode', () {
      final a = ByteArray.fromList([1, 2, 3]);
      final b = ByteArray.fromList([1, 2, 3]);
      final c = ByteArray.fromList([3, 2, 1]);
      expect(a == b, isTrue);
      expect(a == c, isFalse);
      expect(a.hashCode, b.hashCode);
    });

    test('compare and equals (static)', () {
      final a = ByteArray.fromList([1, 2, 3]);
      final b = ByteArray.fromList([1, 2, 3]);
      final c = ByteArray.fromList([1, 2, 4]);
      expect(ByteArray.compare(a, b), 0);
      expect(ByteArray.compare(a, c) < 0, isTrue);
      expect(ByteArray.equals(a, b), isTrue);
      expect(ByteArray.equals(a, c), isFalse);
    });

    test('toString uses printable characters or hex', () {
      final ascii = ByteArray.fromString('ABC');
      final nonAscii = ByteArray.fromList([0, 255]);
      expect(ascii.toString(), contains('ABC'));
      expect(nonAscii.toString(), contains('ByteArray(['));
    });
  });
}