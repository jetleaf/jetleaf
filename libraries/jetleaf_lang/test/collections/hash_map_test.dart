import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../dependencies/exceptions.dart';

void main() {
  group('HashMap', () {
    test('should be empty initially', () {
      final map = HashMap<String, int>();
      expect(map.isEmpty, isTrue);
      expect(map.length, 0);
    });

    test('should add and retrieve elements correctly', () {
      final map = HashMap<String, int>();
      map['one'] = 1;
      expect(map.length, 1);
      expect(map['one'], 1);
      map['two'] = 2;
      expect(map.length, 2);
      expect(map['two'], 2);
      expect(map['three'], isNull);
    });

    test('should update existing elements', () {
      final map = HashMap<String, int>();
      map['one'] = 1;
      map['one'] = 10;
      expect(map.length, 1);
      expect(map['one'], 10);
    });

    test('should handle null keys and values', () {
      final map = HashMap<String?, int?>();
      map[null] = 100;
      expect(map.length, 1);
      expect(map[null], 100);
      map['key_with_null_value'] = null;
      expect(map.length, 2);
      expect(map['key_with_null_value'], isNull);
      expect(map.containsKey(null), isTrue);
      expect(map.containsValue(null), isTrue);
      expect(map.remove(null), 100);
      expect(map.length, 1);
      expect(map.containsKey(null), isFalse);
    });

    test('should remove elements correctly', () {
      final map = HashMap<String, int>();
      map['one'] = 1;
      map['two'] = 2;
      expect(map.remove('one'), 1);
      expect(map.length, 1);
      expect(map.containsKey('one'), isFalse);
      expect(map.containsKey('two'), isTrue);
      expect(map.remove('three'), isNull); // Key not in map
      expect(map.length, 1);
    });

    test('should clear the map', () {
      final map = HashMap<String, int>();
      map['one'] = 1;
      map['two'] = 2;
      map.clear();
      expect(map.isEmpty, isTrue);
      expect(map.length, 0);
      expect(map.containsKey('one'), isFalse);
    });

    test('should check for key containment', () {
      final map = HashMap<String, int>();
      map['apple'] = 1;
      expect(map.containsKey('apple'), isTrue);
      expect(map.containsKey('banana'), isFalse);
    });

    test('should check for value containment', () {
      final map = HashMap<String, int>();
      map['apple'] = 1;
      map['banana'] = 2;
      expect(map.containsValue(1), isTrue);
      expect(map.containsValue(3), isFalse);
    });

    test('should iterate keys correctly', () {
      final map = HashMap<String, int>();
      map['a'] = 1;
      map['b'] = 2;
      map['c'] = 3;
      final keys = map.keys.toList();
      expect(keys.length, 3);
      expect(keys, unorderedMatches(['a', 'b', 'c'])); // Order not guaranteed
    });

    test('should iterate values correctly', () {
      final map = HashMap<String, int>();
      map['a'] = 1;
      map['b'] = 2;
      map['c'] = 3;
      final values = map.values.toList();
      expect(values.length, 3);
    });

    test('should iterate with forEach', () {
      final map = HashMap<String, int>();
      map['a'] = 1;
      map['b'] = 2;
      final result = <String, int>{};
      map.forEach((key, value) {
        result[key] = value;
      });
      expect(result, {'a': 1, 'b': 2});
    });

    test('should resize correctly', () {
      final map = HashMap<int, String>();
      // Add enough elements to trigger resize (initial capacity 16, load factor 0.75)
      // So, 16 * 0.75 = 12 elements will trigger resize to 32.
      for (int i = 0; i < 20; i++) {
        map[i] = 'value_$i';
      }
      expect(map.length, 20);
      for (int i = 0; i < 20; i++) {
        expect(map.containsKey(i), isTrue);
        expect(map[i], 'value_$i');
      }
      // Internal capacity should have increased
      // expect(map._capacity, greaterThan(16)); // Accessing private member for test
    });

    test('should add all from another map', () {
      final map1 = HashMap<String, int>()..addAll({'a': 1, 'b': 2});
      final map2 = HashMap<String, int>()..addAll({'b': 20, 'c': 3});
      map1.addAll(map2);
      expect(map1.length, 3);
      expect(map1['a'], 1);
      expect(map1['b'], 20); // Value updated
      expect(map1['c'], 3);
    });

    test('should map to new map with different types', () {
      final map = HashMap<String, int>()..addAll({'a': 1, 'b': 2});
      final newMap = map.map((key, value) => MapEntry(key.toUpperCase(), value * 10));
      expect(newMap.length, 2);
      expect(newMap['A'], 10);
      expect(newMap['B'], 20);
      expect(newMap.containsKey('a'), isFalse);
    });

    test('toString should work', () {
      final map = HashMap<String, int>()..addAll({'a': 1, 'b': 2});
      // Order is not guaranteed, so check for contains all
      final str = map.toString();
      expect(str.startsWith('{'), isTrue);
      expect(str.endsWith('}'), isTrue);
      expect(str.contains('a: 1'), isTrue);
      expect(str.contains('b: 2'), isTrue);
      expect(HashMap<String, int>().toString(), '{}');
    });

    // New tests for previously unimplemented methods
    test('addEntries should work', () {
      final map = HashMap<String, int>();
      map.addEntries([MapEntry('a', 1), MapEntry('b', 2)]);
      expect(map.length, 2);
      expect(map['a'], 1);
      expect(map['b'], 2);
      map.addEntries([MapEntry('b', 20), MapEntry('c', 3)]); // Update 'b', add 'c'
      expect(map.length, 3);
      expect(map['b'], 20);
      expect(map['c'], 3);
    });

    test('entries should work', () {
      final map = HashMap<String, int>()..addAll({'a': 1, 'b': 2});
      final entries = map.entries.toList();
      expect(entries.length, 2);
      expect(entries.map((e) => e.key), containsAll(['a', 'b']));
      expect(entries.map((e) => e.value), containsAll([1, 2]));
    });

    test('putIfAbsent should work', () {
      final map = HashMap<String, int>();
      expect(map.putIfAbsent('a', () => 1), 1);
      expect(map.length, 1);
      expect(map['a'], 1);
      expect(map.putIfAbsent('a', () => 100), 1); // Should return existing value
      expect(map.length, 1);
      expect(map['a'], 1);
    });

    test('removeWhere should work', () {
      final map = HashMap<String, int>()..addAll({'a': 1, 'b': 2, 'c': 3, 'd': 4});
      map.removeWhere((key, value) => value.isEven);
      expect(map.length, 2);
      expect(map.containsKey('a'), isTrue);
      expect(map.containsKey('c'), isTrue);
      expect(map.containsKey('b'), isFalse);
      expect(map.containsKey('d'), isFalse);
    });

    test('update should work', () {
      final map = HashMap<String, int>()..addAll({'a': 1, 'b': 2});
      expect(map.update('a', (value) => value * 10), 10);
      expect(map['a'], 10);
      expect(map.update('c', (value) => value * 10, ifAbsent: () => 30), 30);
      expect(map['c'], 30);
      expect(() => map.update('d', (value) => value * 10), throwsInvalidArgumentException); // No key, no ifAbsent
    });

    test('updateAll should work', () {
      final map = HashMap<String, int>()..addAll({'a': 1, 'b': 2, 'c': 3});
      map.updateAll((key, value) => value * 10);
      expect(map['a'], 10);
      expect(map['b'], 20);
      expect(map['c'], 30);
    });
  });
}
