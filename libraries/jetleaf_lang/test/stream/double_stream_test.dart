import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

void main() {
  group('DoubleStream', () {
    test('filter + toList', () {
      final result = DoubleStream.of([1.1, 2.2, 3.3, 4.4])
          .filter((d) => d > 2.0)
          .toList();
      expect(result, equals([2.2, 3.3, 4.4]));
    });

    test('map', () {
      final result = DoubleStream.of([1.0, 2.0, 3.0])
          .map((d) => d * d)
          .toList();
      expect(result, equals([1.0, 4.0, 9.0]));
    });

    test('mapToInt', () {
      final result = DoubleStream.of([1.9, 2.1, 3.6])
          .mapToInt((d) => d.round())
          .toList();
      expect(result, equals([2, 2, 4]));
    });

    test('flatMap', () {
      final result = DoubleStream.of([1.0, 2.0])
          .flatMap((d) => DoubleStream.of([d, d * 2]))
          .toList();
      expect(result, equals([1.0, 2.0, 2.0, 4.0]));
    });

    test('distinct', () {
      final result = DoubleStream.of([1.1, 2.2, 1.1, 3.3])
          .distinct()
          .toList();
      expect(result, equals([1.1, 2.2, 3.3]));
    });

    test('sorted', () {
      final result = DoubleStream.of([4.4, 1.1, 3.3, 2.2])
          .sorted()
          .toList();
      expect(result, equals([1.1, 2.2, 3.3, 4.4]));
    });

    test('limit', () {
      final result = DoubleStream.of([1.0, 2.0, 3.0, 4.0])
          .limit(2)
          .toList();
      expect(result, equals([1.0, 2.0]));
    });

    test('skip', () {
      final result = DoubleStream.of([1.0, 2.0, 3.0, 4.0])
          .skip(2)
          .toList();
      expect(result, equals([3.0, 4.0]));
    });

    test('takeWhile', () {
      final result = DoubleStream.of([1.0, 2.0, 3.0, 1.0])
          .takeWhile((d) => d < 3.0)
          .toList();
      expect(result, equals([1.0, 2.0]));
    });

    test('dropWhile', () {
      final result = DoubleStream.of([1.0, 2.0, 3.0, 1.0])
          .dropWhile((d) => d < 3.0)
          .toList();
      expect(result, equals([3.0, 1.0]));
    });

    test('reduce', () {
      final result = DoubleStream.of([1.0, 2.0, 3.0])
          .reduce(0.0, (a, b) => a + b);
      expect(result, equals(6.0));
    });

    test('reduceOptional', () {
      final result = DoubleStream.of([1.0, 2.0, 3.0])
          .reduceOptional((a, b) => a + b);
      expect(result.isPresent(), isTrue);
      expect(result.get(), equals(6.0));
    });

    test('sum, min, max, count, average', () {
      final stream = DoubleStream.of([1.0, 2.0, 3.0]);
      expect(stream.sum(), equals(6.0));
      expect(stream.min().get(), equals(1.0));
      expect(stream.max().get(), equals(3.0));
      expect(stream.count(), equals(3));
      expect(stream.average().get(), equals(2.0));
    });

    test('anyMatch, allMatch, noneMatch', () {
      final stream = DoubleStream.of([1.0, 2.0, 3.0]);
      expect(stream.anyMatch((d) => d > 2.0), isTrue);
      expect(stream.allMatch((d) => d > 0), isTrue);
      expect(stream.noneMatch((d) => d < 0), isTrue);
    });

    test('findFirst, findAny', () {
      final stream = DoubleStream.of([5.0, 10.0, 15.0]);
      expect(stream.findFirst().get(), equals(5.0));
      expect(stream.findAny().isPresent(), isTrue);
    });

    test('forEach & forEachOrdered', () {
      final values = <double>[];
      DoubleStream.of([1.0, 2.0, 3.0]).forEach(values.add);
      expect(values, equals([1.0, 2.0, 3.0]));

      final ordered = <double>[];
      DoubleStream.of([1.0, 2.0, 3.0]).forEachOrdered(ordered.add);
      expect(ordered, equals([1.0, 2.0, 3.0]));
    });
  });
}