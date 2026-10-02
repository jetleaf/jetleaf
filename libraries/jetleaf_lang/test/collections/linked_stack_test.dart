import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../dependencies/exceptions.dart';

void main() {
  group('LinkedStack', () {
    test('should create empty LinkedStack', () {
      final stack = LinkedStack<int>();
      expect(stack.empty(), isTrue);
      expect(stack.size(), equals(0));
    });

    test('should create LinkedStack from iterable', () {
      final stack = LinkedStack<int>.from([1, 2, 3]);
      expect(stack.length, equals(3));
      // Elements are pushed in order, so 3 is on top
      expect(stack.peek(), equals(3));
    });

    test('should push and pop elements', () {
      final stack = LinkedStack<String>();
      
      final pushed1 = stack.push('first');
      final pushed2 = stack.push('second');
      final pushed3 = stack.push('third');
      
      expect(pushed1, equals('first'));
      expect(pushed2, equals('second'));
      expect(pushed3, equals('third'));
      expect(stack.size(), equals(3));
      
      expect(stack.pop(), equals('third'));
      expect(stack.pop(), equals('second'));
      expect(stack.pop(), equals('first'));
      expect(stack.empty(), isTrue);
    });

    test('should peek at top element', () {
      final stack = LinkedStack<int>();
      
      expect(stack.peekOrNull(), isNull);
      
      stack.push(10);
      stack.push(20);
      stack.push(30);
      
      expect(stack.peek(), equals(30));
      expect(stack.peekOrNull(), equals(30));
      expect(stack.size(), equals(3)); // Element still there
      
      stack.pop();
      expect(stack.peek(), equals(20));
    });

    test('should handle null operations gracefully', () {
      final stack = LinkedStack<String>();
      
      expect(stack.popOrNull(), isNull);
      expect(stack.peekOrNull(), isNull);
      
      stack.push('item');
      expect(stack.popOrNull(), equals('item'));
      expect(stack.empty(), isTrue);
    });

    test('should search for elements', () {
      final stack = LinkedStack<String>();
      stack.push('bottom');
      stack.push('middle');
      stack.push('top');
      
      expect(stack.search('top'), equals(1));
      expect(stack.search('middle'), equals(2));
      expect(stack.search('bottom'), equals(3));
      expect(stack.search('missing'), equals(-1));
    });

    test('should handle empty stack operations', () {
      final stack = LinkedStack<int>();
      
      expect(stack.empty(), isTrue);
      expect(() => stack.pop(), throwsNoGuaranteeException);
      expect(() => stack.peek(), throwsNoGuaranteeException);
    });

    test('should work as List', () {
      final stack = LinkedStack<int>();
      
      stack.add(1);
      stack.add(2);
      // Note: LinkedStack insert is more complex due to linked structure
      
      expect(stack.toList(), equals([2, 1])); // LIFO order
      expect(stack[0], equals(2)); // Top element
      expect(stack[1], equals(1)); // Bottom element
      
      stack[0] = 20;
      expect(stack[0], equals(20));
      
      expect(stack.remove(20), isTrue);
      expect(stack.toList(), equals([1]));
    });

    test('should handle length operations', () {
      final stack = LinkedStack<int?>.from([1, 2, 3]);
      
      stack.length = 5;
      expect(stack.length, equals(5));
      expect(stack[0], isNull); // Top elements are null
      expect(stack[1], isNull);
      
      stack.length = 2;
      expect(stack.length, equals(2));
      
      stack.length = 0;
      expect(stack.empty(), isTrue);
    });

    test('should support iteration', () {
      final stack = LinkedStack<int>.from([1, 2, 3]);
      
      final elements = <int>[];
      for (final element in stack) {
        elements.add(element);
      }
      expect(elements, equals([3, 2, 1])); // Top to bottom
      
      final reversed = <int>[];
      final reverseIter = stack.reverseIterator;
      while (reverseIter.moveNext()) {
        reversed.add(reverseIter.current);
      }
      expect(reversed, equals([1, 2, 3])); // Bottom to top
    });

    test('should find elements', () {
      final stack = LinkedStack<String>.from(['a', 'b', 'c']);
      
      expect(stack.contains('b'), isTrue);
      expect(stack.contains('z'), isFalse);
    });

    test('should convert to array', () {
      final stack = LinkedStack<String>.from(['x', 'y', 'z']);
      final array = stack.toArray();
      
      expect(array, equals(['z', 'y', 'x'])); // Top to bottom order
      expect(array, isA<List<String>>());
    });

    test('should clone correctly', () {
      final original = LinkedStack<String>.from(['a', 'b', 'c']);
      final clone = original.clone();
      
      expect(clone.toList(), equals(original.toList()));
      expect(identical(clone, original), isFalse);
      
      clone.push('d');
      expect(original.size(), equals(3));
      expect(clone.size(), equals(4));
    });

    test('should clear all elements', () {
      final stack = LinkedStack<int>.from([1, 2, 3, 4, 5]);
      expect(stack.isNotEmpty, isTrue);
      
      stack.clear();
      expect(stack.empty(), isTrue);
      expect(stack.size(), equals(0));
    });

    test('should handle edge cases', () {
      final stack = LinkedStack<int>();
      
      expect(() => stack[0], throwsRangeError);
      expect(() => stack[-1], throwsRangeError);
      
      stack.push(42);
      expect(stack[0], equals(42));
      
      expect(() => stack[1], throwsRangeError);
    });

    test('should handle insert and remove operations', () {
      final stack = LinkedStack<int>.from([1, 2, 3]);
      
      // Insert at top (index 0)
      stack.insert(0, 0);
      expect(stack.peek(), equals(0));
      
      // Remove from top
      final removed = stack.removeAt(0);
      expect(removed, equals(0));
      expect(stack.peek(), equals(3));
    });
  });
}