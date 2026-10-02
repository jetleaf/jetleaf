import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../dependencies/exceptions.dart';

void main() {
  group('LinkedQueue', () {
    test('should create empty LinkedQueue', () {
      final queue = LinkedQueue<int>();
      expect(queue.isEmpty, isTrue);
      expect(queue.size(), equals(0));
    });

    test('should create LinkedQueue from iterable', () {
      final queue = LinkedQueue<int>.from([1, 2, 3]);
      expect(queue.length, equals(3));
      expect(queue[0], equals(1));
      expect(queue[1], equals(2));
      expect(queue[2], equals(3));
    });

    test('should offer and poll elements', () {
      final queue = LinkedQueue<String>();
      
      expect(queue.offer('first'), isTrue);
      expect(queue.offer('second'), isTrue);
      expect(queue.offer('third'), isTrue);
      expect(queue.size(), equals(3));
      
      expect(queue.poll(), equals('first'));
      expect(queue.poll(), equals('second'));
      expect(queue.poll(), equals('third'));
      expect(queue.poll(), isNull);
    });

    test('should peek at elements', () {
      final queue = LinkedQueue<int>();
      
      expect(queue.peek(), isNull);
      expect(queue.peekFirst(), isNull);
      expect(queue.peekLast(), isNull);
      
      queue.offer(10);
      queue.offer(20);
      queue.offer(30);
      
      expect(queue.peek(), equals(10));
      expect(queue.peekFirst(), equals(10));
      expect(queue.peekLast(), equals(30));
      expect(queue.size(), equals(3)); // Elements still there
    });

    test('should handle element operations', () {
      final queue = LinkedQueue<String>();
      
      expect(() => queue.element(), throwsNoGuaranteeException);
      expect(() => queue.removeElement(), throwsNoGuaranteeException);
      
      queue.offer('item');
      expect(queue.element(), equals('item'));
      expect(queue.removeElement(), equals('item'));
      expect(queue.isEmpty, isTrue);
    });

    test('should handle deque operations', () {
      final queue = LinkedQueue<int>();
      
      queue.addFirst(2);
      queue.addFirst(1);
      queue.addLast(3);
      queue.addLast(4);
      
      expect(queue.toList(), equals([1, 2, 3, 4]));
      
      expect(queue.pollFirst(), equals(1));
      expect(queue.pollLast(), equals(4));
      expect(queue.toList(), equals([2, 3]));
    });

    test('should handle null operations gracefully', () {
      final queue = LinkedQueue<String>();
      
      expect(queue.pollFirst(), isNull);
      expect(queue.pollLast(), isNull);
      expect(queue.peekFirst(), isNull);
      expect(queue.peekLast(), isNull);
    });

    test('should work as List', () {
      final queue = LinkedQueue<int>();
      
      queue.add(1);
      queue.add(2);
      queue.insert(1, 10);
      
      expect(queue.toList(), equals([1, 10, 2]));
      expect(queue[1], equals(10));
      
      queue[1] = 20;
      expect(queue[1], equals(20));
      
      expect(queue.remove(20), isTrue);
      expect(queue.toList(), equals([1, 2]));
    });

    test('should handle length operations', () {
      final queue = LinkedQueue<int?>.from([1, 2, 3]);
      
      queue.length = 5;
      expect(queue.length, equals(5));
      expect(queue[3], isNull);
      expect(queue[4], isNull);
      
      queue.length = 2;
      expect(queue.length, equals(2));
      expect(queue.toList(), equals([1, 2]));
      
      queue.length = 0;
      expect(queue.isEmpty, isTrue);
    });

    test('should support iteration', () {
      final queue = LinkedQueue<int>.from([1, 2, 3]);
      
      final forward = <int>[];
      for (final element in queue) {
        forward.add(element);
      }
      expect(forward, equals([1, 2, 3]));
      
      final backward = <int>[];
      final reverseIter = queue.reverseIterator;
      while (reverseIter.moveNext()) {
        backward.add(reverseIter.current);
      }
      expect(backward, equals([3, 2, 1]));
    });

    test('should find elements', () {
      final queue = LinkedQueue<String>.from(['a', 'b', 'c', 'b']);
      
      expect(queue.contains('c'), isTrue);
      expect(queue.contains('z'), isFalse);
    });

    test('should convert to array', () {
      final queue = LinkedQueue<String>.from(['x', 'y', 'z']);
      final array = queue.toArray();
      
      expect(array, equals(['x', 'y', 'z']));
      expect(array, isA<List<String>>());
    });

    test('should clone correctly', () {
      final original = LinkedQueue<String>.from(['a', 'b', 'c']);
      final clone = original.clone();
      
      expect(clone.toList(), equals(original.toList()));
      expect(identical(clone, original), isFalse);
      
      clone.offer('d');
      expect(original.size(), equals(3));
      expect(clone.size(), equals(4));
    });

    test('should clear all elements', () {
      final queue = LinkedQueue<int>.from([1, 2, 3, 4, 5]);
      expect(queue.isNotEmpty, isTrue);
      
      queue.clear();
      expect(queue.isEmpty, isTrue);
      expect(queue.size(), equals(0));
    });

    test('should handle edge cases', () {
      final queue = LinkedQueue<int>();
      
      expect(() => queue[0], throwsRangeError);
      expect(() => queue[-1], throwsRangeError);
      
      queue.offer(42);
      expect(queue[0], equals(42));
      
      expect(() => queue[1], throwsRangeError);
    });

    test('should handle insert operations', () {
      final queue = LinkedQueue<int>.from([1, 3, 5]);
      
      queue.insert(0, 0); // Insert at beginning
      queue.insert(2, 2); // Insert in middle
      queue.insert(5, 6); // Insert at end
      
      expect(queue.toList(), equals([0, 1, 2, 3, 5, 6]));
    });
  });
}