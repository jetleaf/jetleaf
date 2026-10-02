import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../dependencies/exceptions.dart';

void main() {
  group('Stack', () {
    test('should create empty Stack', () {
      final stack = Stack<int>();
      expect(stack.empty(), isTrue);
      expect(stack.length, equals(0));
    });

    test('should create Stack from iterable', () {
      final stack = Stack<int>.from([1, 2, 3]);
      expect(stack.length, equals(3));
      expect(stack[0], equals(1));
      expect(stack[1], equals(2));
      expect(stack[2], equals(3));
    });

    test('should push and pop elements', () {
      final stack = Stack<String>();
      
      final pushed1 = stack.push('first');
      final pushed2 = stack.push('second');
      final pushed3 = stack.push('third');
      
      expect(pushed1, equals('first'));
      expect(pushed2, equals('second'));
      expect(pushed3, equals('third'));
      expect(stack.length, equals(3));
      
      expect(stack.pop(), equals('third'));
      expect(stack.pop(), equals('second'));
      expect(stack.pop(), equals('first'));
      expect(stack.empty(), isTrue);
    });

    test('should peek at top element', () {
      final stack = Stack<int>();
      
      stack.push(10);
      stack.push(20);
      stack.push(30);
      
      expect(stack.peek(), equals(30));
      expect(stack.length, equals(3)); // Element still there
      
      stack.pop();
      expect(stack.peek(), equals(20));
    });

    test('should search for elements', () {
      final stack = Stack<String>();
      stack.push('bottom');
      stack.push('middle');
      stack.push('top');
      
      expect(stack.search('top'), equals(1));
      expect(stack.search('middle'), equals(2));
      expect(stack.search('bottom'), equals(3));
      expect(stack.search('missing'), equals(-1));
    });

    test('should handle empty stack operations', () {
      final stack = Stack<int>();
      
      expect(stack.empty(), isTrue);
      expect(() => stack.pop(), throwsInvalidArgumentException);
      expect(() => stack.peek(), throwsInvalidArgumentException);
    });

    test('should work as List', () {
      final stack = Stack<int>();
      
      stack.add(1);
      stack.add(2);
      stack.insert(1, 10);
      
      expect(stack.toList(), equals([1, 10, 2]));
      expect(stack[1], equals(10));
      
      stack[1] = 20;
      expect(stack[1], equals(20));
      
      expect(stack.remove(20), isTrue);
      expect(stack.toList(), equals([1, 2]));
    });

    test('should handle capacity operations', () {
      final stack = Stack<String>("");
      
      stack.ensureCapacity(10);
      expect(stack.capacity, greaterThanOrEqualTo(0));
      
      stack.addAll(['a', 'b', 'c']);
      stack.trimToSize(); // Should not throw
    });

    test('should support iteration', () {
      final stack = Stack<int>.from([1, 2, 3]);
      
      final elements = <int>[];
      for (final element in stack) {
        elements.add(element);
      }
      expect(elements, equals([1, 2, 3]));
      
      final reversed = <int>[];
      final reverseIter = stack.reverseIterator;
      while (reverseIter.moveNext()) {
        reversed.add(reverseIter.current);
      }
      expect(reversed, equals([3, 2, 1]));
    });

    test('should find elements', () {
      final stack = Stack<String>.from(['a', 'b', 'c', 'b']);
      
      expect(stack.indexOf('b'), equals(1));
      expect(stack.lastIndexOf('b'), equals(3));
      expect(stack.contains('c'), isTrue);
      expect(stack.contains('z'), isFalse);
    });

    test('should handle sublist operations', () {
      final stack = Stack<int>.from([1, 2, 3, 4, 5]);
      
      final sub = stack.sublist(1, 4);
      expect(sub, equals([2, 3, 4]));
    });

    test('should sort elements', () {
      final stack = Stack<int>.from([3, 1, 4, 1, 5]);
      stack.sort();
      
      expect(stack.toList(), equals([1, 1, 3, 4, 5]));
    });

    test('should clone correctly', () {
      final original = Stack<String>.from(['a', 'b', 'c']);
      final clone = original.clone();
      
      expect(clone.toList(), equals(original.toList()));
      expect(identical(clone, original), isFalse);
      
      clone.push('d');
      expect(original.length, equals(3));
      expect(clone.length, equals(4));
    });

    test('should clear all elements', () {
      final stack = Stack<int>.from([1, 2, 3, 4, 5]);
      expect(stack.isNotEmpty, isTrue);
      
      stack.clear();
      expect(stack.empty(), isTrue);
      expect(stack.length, equals(0));
    });

    test('should handle edge cases', () {
      final stack = Stack<int>();
      
      expect(() => stack.first, throwsNoGuaranteeException);
      expect(() => stack.last, throwsNoGuaranteeException);
      expect(() => stack.single, throwsNoGuaranteeException);
      
      stack.push(42);
      expect(stack.first, equals(42));
      expect(stack.last, equals(42));
      expect(stack.single, equals(42));
    });
  });
}