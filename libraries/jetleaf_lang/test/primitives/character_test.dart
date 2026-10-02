import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../dependencies/exceptions.dart';

void main() {
  group('Character constructor', () {
    test('throws exception on empty string', () {
      expect(() => Character(''), throwsInvalidArgumentException);
    });

    test('throws exception on multiple characters', () {
      expect(() => Character('ab'), throwsInvalidArgumentException);
    });

    test('accepts single character', () {
      final c = Character('x');
      expect(c.value, 'x');
    });
  });

  group('Character.valueOf', () {
    test('returns equivalent Character', () {
      final c = Character.valueOf('a');
      expect(c, Character('a'));
    });
  });

  group('Character properties and methods', () {
    final upper = Character('A');
    final lower = Character('b');
    final digit = Character('5');
    final whitespace = Character(' ');
    final other = Character('@');

    test('codePoint returns correct value', () {
      expect(upper.codePoint, equals('A'.codeUnitAt(0)));
    });

    test('isDigit', () {
      expect(digit.isDigit(), isTrue);
      expect(upper.isDigit(), isFalse);
    });

    test('isLetter', () {
      expect(upper.isLetter(), isTrue);
      expect(lower.isLetter(), isTrue);
      expect(digit.isLetter(), isFalse);
    });

    test('isLetterOrDigit', () {
      expect(upper.isLetterOrDigit(), isTrue);
      expect(digit.isLetterOrDigit(), isTrue);
      expect(other.isLetterOrDigit(), isFalse);
    });

    test('isUpperCase', () {
      expect(upper.isUpperCase(), isTrue);
      expect(lower.isUpperCase(), isFalse);
    });

    test('isLowerCase', () {
      expect(lower.isLowerCase(), isTrue);
      expect(upper.isLowerCase(), isFalse);
    });

    test('isWhitespace', () {
      expect(whitespace.isWhitespace(), isTrue);
      expect(upper.isWhitespace(), isFalse);
    });

    test('toUpperCase', () {
      expect(lower.toUpperCase(), Character('B'));
      expect(upper.toUpperCase(), Character('A'));
    });

    test('toLowerCase', () {
      expect(upper.toLowerCase(), Character('a'));
      expect(lower.toLowerCase(), Character('b'));
    });

    test('compareTo', () {
      expect(Character('a').compareTo(Character('b')), lessThan(0));
      expect(Character('b').compareTo(Character('a')), greaterThan(0));
      expect(Character('c').compareTo(Character('c')), equals(0));
    });

    test('equality and hashCode', () {
      final a1 = Character('a');
      final a2 = Character('a');
      final b = Character('b');

      expect(a1 == a2, isTrue);
      expect(a1 == b, isFalse);
      expect(a1.hashCode, equals(a2.hashCode));
    });

    test('toString returns correct character', () {
      expect(Character('z').toString(), 'z');
    });
  });
}