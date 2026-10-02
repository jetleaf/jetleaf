import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

void main() {
  group('GenericStream Tests', () {
    test('of() and toList()', () {
      final stream = GenericStream.of([1, 2, 3]);
      expect(stream.toList(), [1, 2, 3]);
    });

    test('empty()', () {
      final stream = GenericStream.empty();
      expect(stream.count(), 0);
    });

    test('ofSingle()', () {
      final stream = GenericStream.ofSingle(42);
      expect(stream.toList(), [42]);
    });

    test('filter()', () {
      final stream = GenericStream.of([1, 2, 3, 4])
          .filter((e) => e % 2 == 0);
      expect(stream.toList(), [2, 4]);
    });

    test('map()', () {
      final stream = GenericStream.of(['a', 'bb', 'ccc'])
          .map((e) => e.length);
      expect(stream.toList(), [1, 2, 3]);
    });

    test('flatMap()', () {
      final stream = GenericStream.of(['a,b', 'c'])
          .flatMap((e) => GenericStream.of(e.split(',')));
      expect(stream.toList(), ['a', 'b', 'c']);
    });

    test('distinct()', () {
      final stream = GenericStream.of([1, 2, 2, 3, 3, 3])
          .distinct();
      expect(stream.toList(), [1, 2, 3]);
    });

    test('sorted()', () {
      final stream = GenericStream.of([3, 1, 2])
          .sorted();
      expect(stream.toList(), [1, 2, 3]);
    });

    test('limit()', () {
      final stream = GenericStream.of([1, 2, 3, 4, 5])
          .limit(3);
      expect(stream.toList(), [1, 2, 3]);
    });

    test('skip()', () {
      final stream = GenericStream.of([1, 2, 3, 4, 5])
          .skip(2);
      expect(stream.toList(), [3, 4, 5]);
    });

    test('reduce()', () {
      final stream = GenericStream.of([1, 2, 3]);
      final result = stream.reduce(0, (a, b) => a + b);
      expect(result, 6);
    });

    test('reduceOptional()', () {
      final stream = GenericStream.of([4, 1, 6]);
      final result = stream.reduceOptional((a, b) => a > b ? a : b);
      expect(result.get(), 6);
    });

    test('min() and max()', () {
      final stream = GenericStream.of([5, 2, 8, 1]);
      expect(stream.min().get(), 1);
      expect(stream.max().get(), 8);
    });

    test('findFirst()', () {
      final stream = GenericStream.of([7, 8, 9]);
      expect(stream.findFirst().get(), 7);
    });

    test('findAny()', () {
      final stream = GenericStream.of([7, 8, 9]);
      expect(stream.findAny().isPresent(), true);
    });

    test('anyMatch() / allMatch() / noneMatch()', () {
      final stream = GenericStream.of([1, 2, 3, 4]);
      expect(stream.anyMatch((e) => e > 3), true);
      expect(stream.allMatch((e) => e > 0), true);
      expect(stream.noneMatch((e) => e < 0), true);
    });

    test('toSet()', () {
      final stream = GenericStream.of([1, 2, 2, 3]);
      expect(stream.toSet(), {1, 2, 3});
    });

    test('collect() with joining', () {
      final stream = GenericStream.of(['a', 'b', 'c']);
      final result = stream.collectFrom(Collectors.joining('-'));
      expect(result, 'a-b-c');
    });
  });
}