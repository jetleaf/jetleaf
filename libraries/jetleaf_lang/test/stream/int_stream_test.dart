import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

void main() {
  group('IntStream', () {
    test('of() creates stream and toList() works', () {
      final stream = IntStream.of([1, 2, 3]);
      expect(stream.toList(), equals([1, 2, 3]));
    });

    test('range() creates expected stream', () {
      final stream = IntStream.range(1, 4);
      expect(stream.toList(), equals([1, 2, 3]));
    });

    test('rangeClosed() includes end value', () {
      final stream = IntStream.rangeClosed(1, 3);
      expect(stream.toList(), equals([1, 2, 3]));
    });

    test('filter() removes unwanted values', () {
      final result = IntStream.of([1, 2, 3, 4]).filter((n) => n.isEven).toList();
      expect(result, equals([2, 4]));
    });

    test('map() applies transformation', () {
      final result = IntStream.of([1, 2, 3]).map((n) => n * 2).toList();
      expect(result, equals([2, 4, 6]));
    });

    test('flatMap() expands correctly', () {
      final result = IntStream.of([2, 3]).flatMap((n) => IntStream.range(0, n)).toList();
      expect(result, equals([0, 1, 0, 1, 2]));
    });

    test('distinct() removes duplicates', () {
      final result = IntStream.of([1, 2, 2, 3, 1]).distinct().toList();
      expect(result, unorderedEquals([1, 2, 3]));
    });

    test('sorted() returns ascending list', () {
      final result = IntStream.of([3, 1, 2]).sorted().toList();
      expect(result, equals([1, 2, 3]));
    });

    test('limit() restricts output', () {
      final result = IntStream.range(1, 10).limit(3).toList();
      expect(result, equals([1, 2, 3]));
    });

    test('skip() skips initial elements', () {
      final result = IntStream.range(1, 5).skip(2).toList();
      expect(result, equals([3, 4]));
    });

    test('takeWhile() works correctly', () {
      final result = IntStream.range(1, 6).takeWhile((n) => n < 4).toList();
      expect(result, equals([1, 2, 3]));
    });

    test('dropWhile() works correctly', () {
      final result = IntStream.range(1, 6).dropWhile((n) => n < 4).toList();
      expect(result, equals([4, 5]));
    });

    test('reduce() accumulates correctly', () {
      final sum = IntStream.of([1, 2, 3]).reduce(0, (a, b) => a + b);
      expect(sum, equals(6));
    });

    test('reduceOptional() returns Optional result', () {
      final opt = IntStream.of([4, 2, 9]).reduceOptional((a, b) => a > b ? a : b);
      expect(opt.isPresent(), isTrue);
      expect(opt.get(), equals(9));
    });

    test('sum() calculates correctly', () {
      final total = IntStream.of([1, 2, 3, 4]).sum();
      expect(total, equals(10));
    });

    test('min() and max() return correct values', () {
      expect(IntStream.of([5, 1, 3]).min().get(), equals(1));
      expect(IntStream.of([5, 1, 3]).max().get(), equals(5));
    });

    test('count() returns correct number', () {
      final count = IntStream.rangeClosed(1, 5).count();
      expect(count, equals(5));
    });

    test('average() returns correct mean', () {
      final avg = IntStream.of([1, 2, 3, 4]).average();
      expect(avg, closeTo(2.5, 0.0001));
    });

    test('anyMatch() detects matches', () {
      final result = IntStream.of([1, 3, 5]).anyMatch((n) => n.isEven);
      expect(result, isFalse);
    });

    test('allMatch() verifies all elements', () {
      final result = IntStream.of([2, 4, 6]).allMatch((n) => n.isEven);
      expect(result, isTrue);
    });

    test('noneMatch() detects lack of matches', () {
      final result = IntStream.of([1, 3, 5]).noneMatch((n) => n.isEven);
      expect(result, isTrue);
    });

    test('findFirst() and findAny() return correct Optional', () {
      final stream = IntStream.range(10, 15);
      expect(stream.findFirst().get(), equals(10));
      expect(stream.findAny().isPresent(), isTrue);
    });

    test('asDoubleStream() converts correctly', () {
      final doubles = IntStream.of([1, 2, 3]).asDoubleStream().toList();
      expect(doubles, equals([1.0, 2.0, 3.0]));
    });
  });
}