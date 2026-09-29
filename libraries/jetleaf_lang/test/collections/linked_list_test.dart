import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../dependencies/exceptions.dart';

void main() {
  group('LinkedList', () {
    test('should be empty initially', () {
      final list = LinkedList<int>();
      expect(list.isEmpty, isTrue);
      expect(list.length, 0);
    });

    test('should add elements correctly', () {
      final list = LinkedList<int>();
      list.add(1);
      expect(list.length, 1);
      expect(list.first, 1);
      expect(list.last, 1);
      list.add(2);
      expect(list.length, 2);
      expect(list.first, 1);
      expect(list.last, 2);
    });

    test('should add all elements correctly', () {
      final list = LinkedList<int>();
      list.addAll([1, 2, 3]);
      expect(list.length, 3);
      expect(list[0], 1);
      expect(list[1], 2);
      expect(list[2], 3);
    });

    test('should access elements by index', () {
      final list = LinkedList<String>();
      list.addAll(['a', 'b', 'c']);
      expect(list[0], 'a');
      expect(list[1], 'b');
      expect(list[2], 'c');
      expect(() => list[3], throwsRangeError);
      expect(() => list[-1], throwsRangeError);
    });

    test('should update elements by index', () {
      final list = LinkedList<String>();
      list.addAll(['a', 'b', 'c']);
      list[1] = 'x';
      expect(list[0], 'a');
      expect(list[1], 'x');
      expect(list[2], 'c');
    });

    test('should remove elements by value', () {
      final list = LinkedList<int>();
      list.addAll([1, 2, 3, 2, 4]);
      expect(list.remove(2), isTrue); // Removes first 2
      expect(list.toList(), [1, 3, 2, 4]);
      expect(list.length, 4);
      expect(list.remove(5), isFalse); // Not found
      expect(list.remove(2), isTrue); // Removes second 2
      expect(list.toList(), [1, 3, 4]);
      expect(list.length, 3);
      expect(list.remove(1), isTrue); // Removes head
      expect(list.toList(), [3, 4]);
      expect(list.remove(4), isTrue); // Removes tail
      expect(list.toList(), [3]);
      expect(list.remove(3), isTrue); // Removes last element
      expect(list.isEmpty, isTrue);
    });

    test('should remove elements by index', () {
      final list = LinkedList<int>();
      list.addAll([10, 20, 30, 40, 50]);
      expect(list.removeAt(0), 10); // Remove head
      expect(list.toList(), [20, 30, 40, 50]);
      expect(list.length, 4);
      expect(list.removeAt(2), 40); // Remove middle
      expect(list.toList(), [20, 30, 50]);
      expect(list.length, 3);
      expect(list.removeAt(2), 50); // Remove tail
      expect(list.toList(), [20, 30]);
      expect(list.length, 2);
      expect(() => list.removeAt(2), throwsRangeError);
    });

    test('should clear the list', () {
      final list = LinkedList<int>();
      list.addAll([1, 2, 3]);
      list.clear();
      expect(list.isEmpty, isTrue);
      expect(list.length, 0);
    });

    test('should iterate correctly', () {
      final list = LinkedList<int>();
      list.addAll([1, 2, 3]);
      final result = <int>[];
      for (final item in list) {
        result.add(item);
      }
      expect(result, [1, 2, 3]);
    });

    test('should check for containment', () {
      final list = LinkedList<String>();
      list.addAll(['apple', 'banana', 'cherry']);
      expect(list.contains('banana'), isTrue);
      expect(list.contains('grape'), isFalse);
      expect(list.contains(""), isFalse);
    });

    test('should find index of element', () {
      final list = LinkedList<int>();
      list.addAll([10, 20, 30, 20, 40]);
      expect(list.indexOf(20), 1);
      expect(list.indexOf(20, 2), 3); // Start search from index 2
      expect(list.indexOf(50), -1);
      expect(list.indexOf(10, 1), -1); // Start search from index 1, 10 is at 0
    });

    test('should find last index of element', () {
      final list = LinkedList<int>();
      list.addAll([10, 20, 30, 20, 40]);
      expect(list.lastIndexOf(20), 3);
      expect(list.lastIndexOf(20, 2), 1); // Start search from index 2 (backwards)
      expect(list.lastIndexOf(50), -1);
      expect(list.lastIndexOf(10, 0), 0);
    });

    test('should handle length setter for truncation', () {
      final list = LinkedList<int>();
      list.addAll([1, 2, 3, 4, 5]);
      list.length = 3;
      expect(list.toList(), [1, 2, 3]);
      expect(list.length, 3);
      list.length = 0;
      expect(list.isEmpty, isTrue);
    });

    test('should throw for length setter extending non-nullable list', () {
      final list = LinkedList<int>();
      list.add(1);
      expect(() => list.length = 3, throwsUnsupportedError);
    });

    test('should handle length setter for extending nullable list', () {
      final list = LinkedList<int?>();
      list.add(1);
      list.length = 3;
      expect(list.toList(), [1, null, null]);
      expect(list.length, 3);
    });

    test('should insert element at index', () {
      final list = LinkedList<int>();
      list.addAll([1, 2, 3]);
      list.insert(1, 99);
      expect(list.toList(), [1, 99, 2, 3]);
      expect(list.length, 4);
      list.insert(0, 0);
      expect(list.toList(), [0, 1, 99, 2, 3]);
      list.insert(5, 100);
      expect(list.toList(), [0, 1, 99, 2, 3, 100]);
    });

    test('should insert all elements at index', () {
      final list = LinkedList<int>();
      list.addAll([1, 2, 3]);
      list.insertAll(1, [97, 98, 99]);
      expect(list.toList(), [1, 97, 98, 99, 2, 3]);
      expect(list.length, 6);
      list.insertAll(0, [0, -1]);
      expect(list.toList(), [0, -1, 1, 97, 98, 99, 2, 3]);
      list.insertAll(8, [100, 101]);
      expect(list.toList(), [0, -1, 1, 97, 98, 99, 2, 3, 100, 101]);
    });

    test('should return reversed iterable', () {
      final list = LinkedList<int>();
      list.addAll([1, 2, 3]);
      expect(list.reversed.toList(), [3, 2, 1]);
      expect(LinkedList<int>().reversed.toList(), []);
    });

    test('should convert to list', () {
      final list = LinkedList<int>();
      list.addAll([1, 2, 3]);
      expect(list.toList(), [1, 2, 3]);
    });

    test('should convert to set', () {
      final list = LinkedList<int>();
      list.addAll([1, 2, 2, 3]);
      expect(list.toSet(), {1, 2, 3});
    });

    test('should implement operator +', () {
      final list1 = LinkedList<int>()..addAll([1, 2]);
      final list2 = LinkedList<int>()..addAll([3, 4]);
      final combined = list1 + list2;
      expect(combined.toList(), [1, 2, 3, 4]);
    });

    test('should get range', () {
      final list = LinkedList<int>()..addAll([1, 2, 3, 4, 5]);
      expect(list.getRange(1, 4).toList(), [2, 3, 4]);
      expect(list.getRange(0, 5).toList(), [1, 2, 3, 4, 5]);
      expect(list.getRange(2, 2).toList(), []);
      expect(() => list.getRange(-1, 2), throwsRangeError);
      expect(() => list.getRange(1, 6), throwsRangeError);
    });

    test('should set all elements in range', () {
      final list = LinkedList<int>()..addAll([1, 2, 3, 4, 5]);
      list.setAll(1, [9, 8]);
      expect(list.toList(), [1, 9, 8, 4, 5]);
      list.setAll(3, [7, 6]);
      expect(list.toList(), [1, 9, 8, 7, 6]);
      expect(() => list.setAll(0, [1, 2, 3, 4, 5, 6]), throwsRangeError); // Iterable too long
    });

    test('should fill range', () {
      final list = LinkedList<int>()..addAll([1, 2, 3, 4, 5]);
      list.fillRange(1, 4, 0);
      expect(list.toList(), [1, 0, 0, 0, 5]);
      list.fillRange(0, 1, 9);
      expect(list.toList(), [9, 0, 0, 0, 5]);
      list.fillRange(4, 5, 10);
      expect(list.toList(), [9, 0, 0, 0, 10]);
      expect(() => list.fillRange(0, 6, 1), throwsRangeError);
    });

    test('should replace range', () {
      final list = LinkedList<int>()..addAll([1, 2, 3, 4, 5]);
      list.replaceRange(1, 4, [9, 8, 7]);
      expect(list.toList(), [1, 9, 8, 7, 5]);
      list.replaceRange(0, 1, [0]);
      expect(list.toList(), [0, 9, 8, 7, 5]);
      list.replaceRange(2, 4, []); // Remove elements
      expect(list.toList(), [0, 9, 5]);
      list.replaceRange(3, 3, [10, 11]); // Insert elements
      expect(list.toList(), [0, 9, 5, 10, 11]);
    });

    test('should remove elements where test is true', () {
      final list = LinkedList<int>()..addAll([1, 2, 3, 4, 5, 6]);
      list.removeWhere((e) => e.isEven);
      expect(list.toList(), [1, 3, 5]);
      list.removeWhere((e) => e > 10);
      expect(list.toList(), [1, 3, 5]);
    });

    test('should retain elements where test is true', () {
      final list = LinkedList<int>()..addAll([1, 2, 3, 4, 5, 6]);
      list.retainWhere((e) => e.isEven);
      expect(list.toList(), [2, 4, 6]);
      list.retainWhere((e) => e > 10);
      expect(list.toList(), []);
    });

    test('should return sublist', () {
      final list = LinkedList<int>()..addAll([1, 2, 3, 4, 5]);
      expect(list.sublist(1, 4).toList(), [2, 3, 4]);
      expect(list.sublist(0, 5).toList(), [1, 2, 3, 4, 5]);
      expect(list.sublist(2, 2).toList(), []);
      expect(() => list.sublist(-1, 2), throwsRangeError);
      expect(() => list.sublist(1, 6), throwsRangeError);
    });

    test('should convert to map', () {
      final list = LinkedList<String>()..addAll(['a', 'b', 'c']);
      expect(list.asMap(), {0: 'a', 1: 'b', 2: 'c'});
      expect(LinkedList<int>().asMap(), {});
    });

    test('should shuffle (inefficiently)', () {
      final list = LinkedList<int>()..addAll([1, 2, 3, 4, 5]);
      final original = list.toList();
      list.shuffle();
      expect(list.length, original.length);
      expect(list.toSet(), original.toSet()); // Same elements
      // Cannot guarantee order, but it should be different most of the time
      // expect(list.toList(), isNot(equals(original))); // This can fail rarely
    });

    test('should sort (inefficiently)', () {
      final list = LinkedList<int>()..addAll([5, 2, 4, 1, 3]);
      list.sort();
      expect(list.toList(), [1, 2, 3, 4, 5]);
      list.sort((a, b) => b.compareTo(a));
      expect(list.toList(), [5, 4, 3, 2, 1]);
    });

    test('toString should work', () {
      final list = LinkedList<int>()..addAll([1, 2, 3]);
      expect(list.toString(), '[1, 2, 3]');
      expect(LinkedList<String>().toString(), '[]');
    });

    // New tests for previously unimplemented methods
    test('any should work', () {
      final list = LinkedList<int>()..addAll([1, 2, 3]);
      expect(list.any((e) => e == 2), isTrue);
      expect(list.any((e) => e == 4), isFalse);
      expect(LinkedList<int>().any((e) => e == 1), isFalse);
    });

    test('cast should work', () {
      final list = LinkedList<num>()..addAll([1, 2, 3]);
      final intList = list.cast<int>();
      expect(intList.toList(), [1, 2, 3]);
    });

    test('every should work', () {
      final list = LinkedList<int>()..addAll([2, 4, 6]);
      expect(list.every((e) => e.isEven), isTrue);
      expect(list.every((e) => e < 5), isFalse);
      expect(LinkedList<int>().every((e) => e == 1), isTrue); // Empty list is always true
    });

    test('expand should work', () {
      final list = LinkedList<List<int>>()..addAll([[1, 2], [3], [4, 5]]);
      expect(list.expand((e) => e).toList(), [1, 2, 3, 4, 5]);
    });

    test('firstWhere should work', () {
      final list = LinkedList<int>()..addAll([1, 2, 3, 4]);
      expect(list.firstWhere((e) => e.isEven), 2);
      expect(list.firstWhere((e) => e > 10, orElse: () => 0), 0);
      expect(() => list.firstWhere((e) => e > 10), throwsA(isA<InvalidArgumentException>()));
    });

    test('fold should work', () {
      final list = LinkedList<int>()..addAll([1, 2, 3]);
      expect(list.fold(0, (prev, e) => prev + e), 6);
      expect(list.fold('', (prev, e) => '$prev$e'), '123');
    });

    test('followedBy should work', () {
      final list1 = LinkedList<int>()..addAll([1, 2]);
      final list2 = LinkedList<int>()..addAll([3, 4]);
      expect(list1.followedBy(list2).toList(), [1, 2, 3, 4]);
    });

    test('indexWhere should work', () {
      final list = LinkedList<int>()..addAll([10, 20, 30, 20, 40]);
      expect(list.indexWhere((e) => e == 20), 1);
      expect(list.indexWhere((e) => e == 20, 2), 3);
      expect(list.indexWhere((e) => e == 50), -1);
    });

    test('join should work', () {
      final list = LinkedList<String>()..addAll(['a', 'b', 'c']);
      expect(list.join('-'), 'a-b-c');
      expect(list.join(), 'abc');
      expect(LinkedList<String>().join(), '');
    });

    test('lastIndexWhere should work', () {
      final list = LinkedList<int>()..addAll([10, 20, 30, 20, 40]);
      expect(list.lastIndexWhere((e) => e == 20), 3);
      expect(list.lastIndexWhere((e) => e == 20, 2), 1);
      expect(list.lastIndexWhere((e) => e == 50), -1);
    });

    test('lastWhere should work', () {
      final list = LinkedList<int>()..addAll([1, 2, 3, 4]);
      expect(list.lastWhere((e) => e.isEven), 4);
      expect(list.lastWhere((e) => e > 10, orElse: () => 0), 0);
      expect(() => list.lastWhere((e) => e > 10), throwsA(isA<InvalidArgumentException>()));
    });

    test('map should work', () {
      final list = LinkedList<int>()..addAll([1, 2, 3]);
      expect(list.map((e) => e * 2).toList(), [2, 4, 6]);
    });

    test('reduce should work', () {
      final list = LinkedList<int>()..addAll([1, 2, 3, 4]);
      expect(list.reduce((value, element) => value + element), 10);
      expect(() => LinkedList<int>().reduce((value, element) => value + element), throwsA(isA<InvalidArgumentException>()));
    });

    test('removeRange should work', () {
      final list = LinkedList<int>()..addAll([1, 2, 3, 4, 5]);
      list.removeRange(1, 4);
      expect(list.toList(), [1, 5]);
      list.removeRange(0, 0);
      expect(list.toList(), [1, 5]);
      list.removeRange(0, 2);
      expect(list.toList(), []);
    });

    test('setRange should work', () {
      final list = LinkedList<int>()..addAll([1, 2, 3, 4, 5]);
      list.setRange(1, 4, [9, 8, 7]);
      expect(list.toList(), [1, 9, 8, 7, 5]);
      list.setRange(0, 1, [0]);
      expect(list.toList(), [0, 9, 8, 7, 5]);
      list.setRange(2, 4, [10, 11, 12], 1); // Skip 1 element from iterable
      expect(list.toList(), [0, 9, 11, 12, 5]);
      expect(() => list.setRange(0, 2, [1, 2, 3]), throwsInvalidArgumentException); // Iterable too long
    });

    test('singleWhere should work', () {
      final list = LinkedList<int>()..addAll([1, 2, 3]);
      expect(list.singleWhere((e) => e == 2), 2);
      expect(list.singleWhere((e) => e == 4, orElse: () => 0), 0);
      expect(() => list.singleWhere((e) => e > 0), throwsA(isA<InvalidArgumentException>())); // More than one
      expect(() => list.singleWhere((e) => e == 4), throwsA(isA<InvalidArgumentException>())); // No element
    });

    test('skip should work', () {
      final list = LinkedList<int>()..addAll([1, 2, 3, 4, 5]);
      expect(list.skip(2).toList(), [3, 4, 5]);
      expect(list.skip(0).toList(), [1, 2, 3, 4, 5]);
      expect(list.skip(10).toList(), []);
    });

    test('skipWhile should work', () {
      final list = LinkedList<int>()..addAll([1, 2, 3, 4, 5]);
      expect(list.skipWhile((e) => e < 3).toList(), [3, 4, 5]);
      expect(list.skipWhile((e) => e < 10).toList(), []);
      expect(list.skipWhile((e) => e > 10).toList(), [1, 2, 3, 4, 5]);
    });

    test('take should work', () {
      final list = LinkedList<int>()..addAll([1, 2, 3, 4, 5]);
      expect(list.take(2).toList(), [1, 2]);
      expect(list.take(0).toList(), []);
      expect(list.take(10).toList(), [1, 2, 3, 4, 5]);
    });

    test('takeWhile should work', () {
      final list = LinkedList<int>()..addAll([1, 2, 3, 4, 5]);
      expect(list.takeWhile((e) => e < 3).toList(), [1, 2]);
      expect(list.takeWhile((e) => e < 0).toList(), []);
      expect(list.takeWhile((e) => e < 10).toList(), [1, 2, 3, 4, 5]);
    });

    test('where should work', () {
      final list = LinkedList<int>()..addAll([1, 2, 3, 4, 5]);
      expect(list.where((e) => e.isEven).toList(), [2, 4]);
      expect(list.where((e) => e > 10).toList(), []);
    });

    test('whereType should work', () {
      final list = LinkedList<Object>()..addAll([1, 'hello', 2.5, true]);
      expect(list.whereType<int>().toList(), [1]);
      expect(list.whereType<String>().toList(), ['hello']);
      expect(list.whereType<double>().toList(), [2.5]);
      expect(list.whereType<bool>().toList(), [true]);
      expect(list.whereType<List>().toList(), []);
    });

    test('first setter should work', () {
      final list = LinkedList<int>()..addAll([1, 2, 3]);
      list.first = 10;
      expect(list.toList(), [10, 2, 3]);
      expect(() => LinkedList<int>().first = 1, throwsA(isA<InvalidArgumentException>()));
    });

    test('last setter should work', () {
      final list = LinkedList<int>()..addAll([1, 2, 3]);
      list.last = 30;
      expect(list.toList(), [1, 2, 30]);
      expect(() => LinkedList<int>().last = 1, throwsA(isA<InvalidArgumentException>()));
    });
  });
}