import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

void main() {
  group('StringBuilder', () {
    test('should create empty StringBuilder', () {
      final sb = StringBuilder();
      expect(sb.isEmpty(), isTrue);
      expect(sb.length(), equals(0));
      expect(sb.toString(), equals(''));
    });

    test('should create StringBuilder with initial content', () {
      final sb = StringBuilder.withContent('hello');
      expect(sb.length(), equals(5));
      expect(sb.toString(), equals('hello'));
    });

    test('should append various types', () {
      final sb = StringBuilder();
      sb.append('hello')
        .append(' ')
        .append(42)
        .append(' ')
        .append(true);
      
      expect(sb.toString(), equals('hello 42 true'));
    });

    test('should append characters', () {
      final sb = StringBuilder();
      sb.appendChar('H')
        .appendChar('i')
        .appendCharCode(33); // !
      
      expect(sb.toString(), equals('Hi!'));
    });

    test('should append lines', () {
      final sb = StringBuilder();
      sb.appendLine('Line 1')
        .appendLine('Line 2')
        .appendLine();
      
      expect(sb.toString(), equals('Line 1\nLine 2\n\n'));
    });

    test('should insert at specific positions', () {
      final sb = StringBuilder.withContent('Hello World');
      sb.insert(6, 'Beautiful ');
      
      expect(sb.toString(), equals('Hello Beautiful World'));
    });

    test('should delete ranges and characters', () {
      final sb = StringBuilder.withContent('Hello World');
      sb.delete(5, 6); // Remove space
      
      expect(sb.toString(), equals('HelloWorld'));
      
      sb.deleteCharAt(5); // Remove 'W'
      expect(sb.toString(), equals('Helloorld'));
    });

    test('should replace ranges', () {
      final sb = StringBuilder.withContent('Hello World');
      sb.replace(6, 11, 'Dart');
      
      expect(sb.toString(), equals('Hello Dart'));
    });

    test('should reverse content', () {
      final sb = StringBuilder.withContent('Hello');
      sb.reverse();
      
      expect(sb.toString(), equals('olleH'));
    });

    test('should access and modify characters', () {
      final sb = StringBuilder.withContent('Hello');
      
      expect(sb.charAt(0), equals('H'));
      expect(sb.charAt(4), equals('o'));
      
      sb.setCharAt(0, 'h');
      expect(sb.toString(), equals('hello'));
    });

    test('should find substrings', () {
      final sb = StringBuilder.withContent('Hello World Hello');
      
      expect(sb.indexOf('Hello'), equals(0));
      expect(sb.indexOf('Hello', 1), equals(12));
      expect(sb.lastIndexOf('Hello'), equals(12));
      expect(sb.indexOf('xyz'), equals(-1));
    });

    test('should handle substrings', () {
      final sb = StringBuilder.withContent('Hello World');
      
      expect(sb.substring(0, 5), equals('Hello'));
      expect(sb.substring(6), equals('World'));
    });

    test('should manage length', () {
      final sb = StringBuilder.withContent('Hello');
      expect(sb.length(), equals(5));
      
      sb.setLength(3);
      expect(sb.toString(), equals('Hel'));
      
      sb.setLength(7);
      expect(sb.length(), equals(7));
    });

    test('should clear content', () {
      final sb = StringBuilder.withContent('Hello World');
      sb.clear();
      
      expect(sb.isEmpty(), isTrue);
      expect(sb.length(), equals(0));
      expect(sb.toString(), equals(''));
    });

    test('should handle capacity operations', () {
      final sb = StringBuilder();
      sb.ensureCapacity(100); // Should not throw
      sb.trimToSize(); // Should not throw
      
      expect(sb.capacity, equals(sb.length()));
    });

    test('should handle equality', () {
      final sb1 = StringBuilder.withContent('Hello');
      final sb2 = StringBuilder.withContent('Hello');
      final sb3 = StringBuilder.withContent('World');
      
      expect(sb1, equals(sb2));
      expect(sb1.hashCode, equals(sb2.hashCode));
      expect(sb1, isNot(equals(sb3)));
    });

    test('should append all with separator', () {
      final sb = StringBuilder();
      sb.appendAll(['a', 'b', 'c'], ', ');
      
      expect(sb.toString(), equals('a, b, c'));
    });
  });
}