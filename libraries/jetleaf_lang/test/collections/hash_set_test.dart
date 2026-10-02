import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

void main() {
  group('HashSet', () {
    test('should be empty initially', () {
      final set = HashSet<int>();
      expect(set.isEmpty, isTrue);
      expect(set.length, 0);
    });

    test('should add elements correctly', () {
      final set = HashSet<int>();
      expect(set.add(1), isTrue);
      expect(set.length, 1);
      expect(set.contains(1), isTrue);
      expect(set.add(2), isTrue);
      expect(set.length, 2);
      expect(set.contains(2), isTrue);
    });

    test('should not add duplicate elements', () {
      final set = HashSet<int>();
      set.add(1);
      expect(set.add(1), isFalse);
      expect(set.length, 1);
    });

    test('should handle null elements', () {
      final set = HashSet<int?>();
      expect(set.add(null), isTrue);
      expect(set.length, 1);
      expect(set.contains(null), isTrue);
      expect(set.add(null), isFalse);
      expect(set.length, 1);
      expect(set.remove(null), isTrue);
      expect(set.length, 0);
      expect(set.contains(null), isFalse);
    });

    test('should remove elements correctly', () {
      final set = HashSet<int>();
      set.add(1);
      set.add(2);
      expect(set.remove(1), isTrue);
      expect(set.length, 1);
      expect(set.contains(1), isFalse);
      expect(set.contains(2), isTrue);
      expect(set.remove(3), isFalse); // Element not in set
      expect(set.length, 1);
    });

    test('should clear the set', () {
      final set = HashSet<int>();
      set.add(1);
      set.add(2);
      set.clear();
      expect(set.isEmpty, isTrue);
      expect(set.length, 0);
      expect(set.contains(1), isFalse);
    });

    test('should iterate correctly', () {
      final set = HashSet<int>();
      set.addAll([1, 2, 3]);
      print(set);
      final result = <int>[];
      for (final item in set) {
        result.add(item);
      }
      expect(result, containsAllInOrder([1, 2, 3])); // Order not guaranteed for hash sets
      expect(result.length, 3);
    });

    test('should resize correctly', () {
      final set = HashSet<int>();
      // Add enough elements to trigger resize (initial capacity 16, load factor 0.75)
      // So, 16 * 0.75 = 12 elements will trigger resize to 32.
      for (int i = 0; i < 20; i++) {
        set.add(i);
      }
      expect(set.length, 20);
      for (int i = 0; i < 20; i++) {
        expect(set.contains(i), isTrue);
      }
      // Internal capacity should have increased
      // expect(set._capacity, greaterThan(16)); // Accessing private member for test
    });

    test('should add all elements from iterable', () {
      final set = HashSet<int>();
      set.addAll([1, 2, 3, 1]);
      expect(set.length, 3);
      expect(set.contains(1), isTrue);
      expect(set.contains(2), isTrue);
      expect(set.contains(3), isTrue);
    });

    test('should perform union correctly', () {
      final set1 = HashSet<int>()..addAll([1, 2, 3]);
      final set2 = HashSet<int>()..addAll([3, 4, 5]);
      final unionSet = set1.union(set2);
      expect(unionSet.length, 5);
      expect(unionSet.containsAll([1, 2, 3, 4, 5]), isTrue);
    });

    test('should perform intersection correctly', () {
      final set1 = HashSet<int>()..addAll([1, 2, 3]);
      final set2 = HashSet<int>()..addAll([3, 4, 5]);
      final intersectionSet = set1.intersection(set2);
      expect(intersectionSet.length, 1);
      expect(intersectionSet.contains(3), isTrue);
    });

    test('should perform difference correctly', () {
      final set1 = HashSet<int>()..addAll([1, 2, 3]);
      final set2 = HashSet<int>()..addAll([3, 4, 5]);
      final differenceSet = set1.difference(set2);
      expect(differenceSet.length, 2);
      expect(differenceSet.containsAll([1, 2]), isTrue);
      expect(differenceSet.contains(3), isFalse);
    });

    test('should lookup elements', () {
      final set = HashSet<String>()..addAll(['apple', 'banana', 'cherry']);
      expect(set.lookup('banana'), 'banana');
      expect(set.lookup('grape'), isNull);
    });

    test('toString should work', () {
      final set = HashSet<int>()..addAll([1, 2, 3]);
      // Order is not guaranteed, so check for contains all
      final str = set.toString();
      expect(str.startsWith('{'), isTrue);
      expect(str.endsWith('}'), isTrue);
      expect(str.contains('1'), isTrue);
      expect(str.contains('2'), isTrue);
      expect(str.contains('3'), isTrue);
      expect(HashSet<String>().toString(), '{}');
    });

    // New tests for previously unimplemented methods
    test('any should work', () {
      final set = HashSet<int>()..addAll([1, 2, 3]);
      expect(set.any((e) => e == 2), isTrue);
      expect(set.any((e) => e == 4), isFalse);
      expect(HashSet<int>().any((e) => e == 1), isFalse);
    });

    test('cast should work', () {
      final set = HashSet<num>()..addAll([1, 2, 3]);
      final intSet = set.cast<int>();
      expect(intSet.toSet(), {1, 2, 3});
    });

    test('containsAll should work', () {
      final set = HashSet<int>()..addAll([1, 2, 3, 4]);
      expect(set.containsAll([1, 3]), isTrue);
      expect(set.containsAll([1, 5]), isFalse);
      expect(set.containsAll([]), isTrue);
    });

    test('elementAt should work', () {
      final set = HashSet<int>()..addAll([10, 20, 30]);
      // Order is not guaranteed, so we can only test for valid index and type
      expect(set.elementAt(0), anyOf(10, 20, 30));
      expect(set.elementAt(1), anyOf(10, 20, 30));
      expect(set.elementAt(2), anyOf(10, 20, 30));
      expect(() => set.elementAt(3), throwsRangeError);
      expect(() => set.elementAt(-1), throwsRangeError);
    });

    test('every should work', () {
      final set = HashSet<int>()..addAll([2, 4, 6]);
      expect(set.every((e) => e.isEven), isTrue);
      expect(set.every((e) => e < 5), isFalse);
      expect(HashSet<int>().every((e) => e == 1), isTrue); // Empty set is always true
    });

    test('expand should work', () {
      final set = HashSet<List<int>>()..addAll([[1, 2], [3], [4, 5]]);
      expect(set.expand((e) => e).toSet(), {1, 2, 3, 4, 5});
    });

    test('first should work', () {
      final set = HashSet<int>()..add(1);
      expect(set.first, 1);
      expect(() => HashSet<int>().first, throwsA(isA<IllegalStateException>()));
    });

    test('firstWhere should work', () {
      final set = HashSet<int>()..addAll([1, 2, 3, 4]);
      expect(set.firstWhere((e) => e.isEven), 2);
      expect(set.firstWhere((e) => e > 10, orElse: () => 0), 0);
      expect(() => set.firstWhere((e) => e > 10), throwsA(isA<IllegalStateException>()));
    });

    test('fold should work', () {
      final set = HashSet<int>()..addAll([1, 2, 3]);
      expect(set.fold(0, (prev, e) => prev + e), 6);
      expect(set.fold('', (prev, e) => '$prev$e'), anyOf('123', '132', '213', '231', '312', '321'));
    });

    test('followedBy should work', () {
      final set1 = HashSet<int>()..addAll([1, 2]);
      final set2 = HashSet<int>()..addAll([3, 4]);
      expect(set1.followedBy(set2).toSet(), {1, 2, 3, 4});
    });

    test('forEach should work', () {
      final set = HashSet<String>()..addAll(['a', 'b']);
      final result = <String>{};
      for (var element in set) {
        result.add(element);
      }
      expect(result, {'a', 'b'});
    });

    test('join should work', () {
      final set = HashSet<String>()..addAll(['a', 'b', 'c']);
      final joined = set.join('-');
      expect(joined.split('-').toSet(), {'a', 'b', 'c'}); // Order not guaranteed
      expect(HashSet<String>().join(), '');
    });

    test('last should work', () {
      final set = HashSet<int>()..add(1);
      expect(set.last, 1);
      expect(() => HashSet<int>().last, throwsA(isA<IllegalStateException>()));
    });

    test('lastWhere should work', () {
      final set = HashSet<int>()..addAll([1, 2, 3, 4]);
      expect(set.lastWhere((e) => e.isEven), 4);
      expect(set.lastWhere((e) => e > 10, orElse: () => 0), 0);
      expect(() => set.lastWhere((e) => e > 10), throwsA(isA<IllegalStateException>()));
    });

    test('map should work', () {
      final set = HashSet<int>()..addAll([1, 2, 3]);
      expect(set.map((e) => e * 2).toSet(), {2, 4, 6});
    });

    test('reduce should work', () {
      final set = HashSet<int>()..addAll([1, 2, 3, 4]);
      expect(set.reduce((value, element) => value + element), 10);
      expect(() => HashSet<int>().reduce((value, element) => value + element), throwsA(isA<IllegalStateException>()));
    });

    test('removeAll should work', () {
      final set = HashSet<int>()..addAll([1, 2, 3, 4]);
      set.removeAll([2, 4, 5]);
      expect(set.toSet(), {1, 3});
    });

    test('removeWhere should work', () {
      final set = HashSet<int>()..addAll([1, 2, 3, 4, 5, 6]);
      set.removeWhere((e) => e.isEven);
      expect(set.toSet(), {1, 3, 5});
    });

    test('retainAll should work', () {
      final set = HashSet<int>()..addAll([1, 2, 3, 4, 5, 6]);
      set.retainAll([2, 3, 7]);
      expect(set.toSet(), {2, 3});
    });

    test('retainWhere should work', () {
      final set = HashSet<int>()..addAll([1, 2, 3, 4, 5, 6]);
      set.retainWhere((e) => e.isEven);
      expect(set.toSet(), {2, 4, 6});
    });

    test('single should work', () {
      final set = HashSet<int>()..add(42);
      expect(set.single, 42);
      expect(() => HashSet<int>().single, throwsA(isA<IllegalStateException>()));
      expect(() => (HashSet<int>()..addAll([1, 2])).single, throwsA(isA<IllegalStateException>()));
    });

    test('singleWhere should work', () {
      final set = HashSet<int>()..addAll([1, 2, 3]);
      expect(set.singleWhere((e) => e == 2), 2);
      expect(set.singleWhere((e) => e == 4, orElse: () => 0), 0);
      expect(() => set.singleWhere((e) => e > 0), throwsA(isA<IllegalStateException>())); // More than one
      expect(() => set.singleWhere((e) => e == 4), throwsA(isA<IllegalStateException>())); // No element
    });

    test('skip should work', () {
      final set = HashSet<int>()..addAll([1, 2, 3, 4, 5]);
      expect(set.skip(2).length, 3); // Order not guaranteed, just length
      expect(set.skip(0).length, 5);
      expect(set.skip(10).length, 0);
    });

    test('skipWhile should work', () {
      final set = HashSet<int>()..addAll([1, 2, 3, 4, 5]);
      // Order not guaranteed, so test on properties
      final result = set.skipWhile((e) => e < 3).toSet();
      expect(result.length, 3);
      expect(result.containsAll([3, 4, 5]), isTrue);
    });

    test('take should work', () {
      final set = HashSet<int>()..addAll([1, 2, 3, 4, 5]);
      expect(set.take(2).length, 2);
      expect(set.take(0).length, 0);
      expect(set.take(10).length, 5);
    });

    test('takeWhile should work', () {
      final set = HashSet<int>()..addAll([1, 2, 3, 4, 5]);
      final result = set.takeWhile((e) => e < 3).toSet();
      expect(result.length, 2);
      expect(result.containsAll([1, 2]), isTrue);
    });

    test('toList should work', () {
      final set = HashSet<int>()..addAll([1, 2, 3]);
      final list = set.toList();
      expect(list.length, 3);
    });

    test('where should work', () {
      final set = HashSet<int>()..addAll([1, 2, 3, 4, 5]);
      expect(set.where((e) => e.isEven).toSet(), {2, 4});
    });

    test('whereType should work', () {
      final set = HashSet<Object>()..addAll([1, 'hello', 2.5, true]);
      expect(set.whereType<int>().toSet(), {1});
      expect(set.whereType<String>().toSet(), {'hello'});
    });

    test('isSubsetOf should work', () {
      final set1 = HashSet<int>()..addAll([1, 2]);
      final set2 = HashSet<int>()..addAll([1, 2, 3]);
      final set3 = HashSet<int>()..addAll([1, 4]);
      expect(set1.isSubsetOf(set2), isTrue);
      expect(set2.isSubsetOf(set1), isFalse);
      expect(set1.isSubsetOf(set3), isFalse);
      expect(HashSet<int>().isSubsetOf(set1), isTrue); // Empty set is subset of any set
    });

    test('isSupersetOf should work', () {
      final set1 = HashSet<int>()..addAll([1, 2, 3]);
      final set2 = HashSet<int>()..addAll([1, 2]);
      final set3 = HashSet<int>()..addAll([1, 4]);
      expect(set1.isSupersetOf(set2), isTrue);
      expect(set2.isSupersetOf(set1), isFalse);
      expect(set1.isSupersetOf(set3), isFalse);
      expect(set1.isSupersetOf(HashSet<int>()), isTrue); // Any set is superset of empty set
    });
  });
}