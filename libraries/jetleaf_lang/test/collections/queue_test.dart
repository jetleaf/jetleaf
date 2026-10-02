import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../dependencies/exceptions.dart';

void main() {
  group('Queue', () {
    test('should create empty Queue', () {
      final queue = Queue<int>();
      expect(queue.isEmpty, isTrue);
      expect(queue.size(), equals(0));
    });

    test('should create Queue from iterable', () {
      final queue = Queue<int>.from([1, 2, 3]);
      expect(queue.length, equals(3));
      expect(queue[0], equals(1));
      expect(queue[1], equals(2));
      expect(queue[2], equals(3));
    });

    test('should offer and poll elements', () {
      final queue = Queue<String>();
      
      expect(queue.offer('first'), isTrue);
      expect(queue.offer('second'), isTrue);
      expect(queue.offer('third'), isTrue);
      expect(queue.size(), equals(3));
      
      expect(queue.poll(), equals('first'));
      expect(queue.poll(), equals('second'));
      expect(queue.poll(), equals('third'));
      expect(queue.poll(), isNull);
    });

    test('should peek at front element', () {
      final queue = Queue<int>();
      
      expect(queue.peek(), isNull);
      
      queue.offer(10);
      queue.offer(20);
      queue.offer(30);
      
      expect(queue.peek(), equals(10));
      expect(queue.size(), equals(3)); // Element still there
      
      queue.poll();
      expect(queue.peek(), equals(20));
    });

    test('should handle element operations', () {
      final queue = Queue<String>();
      
      expect(() => queue.element(), throwsInvalidArgumentException);
      expect(() => queue.removeElement(), throwsInvalidArgumentException);
      
      queue.offer('item');
      expect(queue.element(), equals('item'));
      expect(queue.removeElement(), equals('item'));
      expect(queue.isEmpty, isTrue);
    });

    test('should work as List', () {
      final queue = Queue<int>();
      
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

    test('should handle collection operations', () {
      final queue = Queue<String>.from(['a', 'b', 'c', 'd']);
      
      queue.retainAll(['a', 'c']);
      expect(queue.toList(), equals(['a', 'c']));
      
      queue.addAll(['e', 'f']);
      expect(queue.toList(), equals(['a', 'c', 'e', 'f']));
      
      queue.removeWhere((element) => element == 'c');
      expect(queue.toList(), equals(['a', 'e', 'f']));
    });

    test('should support iteration', () {
      final queue = Queue<int>.from([1, 2, 3]);
      
      final elements = <int>[];
      for (final element in queue) {
        elements.add(element);
      }
      expect(elements, equals([1, 2, 3]));
    });

    test('should find elements', () {
      final queue = Queue<String>.from(['a', 'b', 'c', 'b']);
      
      expect(queue.indexOf('b'), equals(1));
      expect(queue.lastIndexOf('b'), equals(3));
      expect(queue.contains('c'), isTrue);
      expect(queue.contains('z'), isFalse);
    });

    test('should handle sublist operations', () {
      final queue = Queue<int>.from([1, 2, 3, 4, 5]);
      
      final sub = queue.sublist(1, 4);
      expect(sub, equals([2, 3, 4]));
    });

    test('should sort elements', () {
      final queue = Queue<int>.from([3, 1, 4, 1, 5]);
      queue.sort();
      
      expect(queue.toList(), equals([1, 1, 3, 4, 5]));
    });

    test('should convert to array', () {
      final queue = Queue<String>.from(['x', 'y', 'z']);
      final array = queue.toArray();
      
      expect(array, equals(['x', 'y', 'z']));
      expect(array, isA<List<String>>());
    });

    test('should clone correctly', () {
      final original = Queue<String>.from(['a', 'b', 'c']);
      final clone = original.clone();
      
      expect(clone.toList(), equals(original.toList()));
      expect(identical(clone, original), isFalse);
      
      clone.offer('d');
      expect(original.size(), equals(3));
      expect(clone.size(), equals(4));
    });

    test('should clear all elements', () {
      final queue = Queue<int>.from([1, 2, 3, 4, 5]);
      expect(queue.isNotEmpty, isTrue);
      
      queue.clear();
      expect(queue.isEmpty, isTrue);
      expect(queue.size(), equals(0));
      
      queue.removeAll();
      expect(queue.isEmpty, isTrue);
    });

    test('should handle edge cases', () {
      final queue = Queue<int>();
      
      expect(() => queue.first, throwsNoGuaranteeException);
      expect(() => queue.last, throwsNoGuaranteeException);
      expect(() => queue.single, throwsNoGuaranteeException);
      
      queue.offer(42);
      expect(queue.first, equals(42));
      expect(queue.last, equals(42));
      expect(queue.single, equals(42));
    });
  });
}