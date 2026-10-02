import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

void main() {
  group('Collectors', () {
    test('toList collects elements to list', () {
      final collector = Collectors.toList<int>();
      final list = [1, 2, 3];
      final result = list.fold(collector.supplier(), (acc, e) {
        collector.accumulator(acc, e);
        return acc;
      });
      expect(collector.finisher(result), equals([1, 2, 3]));
    });

    test('toSet collects elements to set', () {
      final collector = Collectors.toSet<int>();
      final list = [1, 2, 2, 3];
      final result = list.fold(collector.supplier(), (acc, e) {
        collector.accumulator(acc, e);
        return acc;
      });
      expect(collector.finisher(result), equals({1, 2, 3}));
    });

    test('toMap collects elements to map', () {
      final collector = Collectors.toMap<int, String, String>(
        (e) => 'k$e',
        (e) => 'v$e',
      );
      final result = [1, 2].fold(collector.supplier(), (acc, e) {
        collector.accumulator(acc, e);
        return acc;
      });
      expect(collector.finisher(result), equals({'k1': 'v1', 'k2': 'v2'}));
    });

    test('joining concatenates strings', () {
      final collector = Collectors.joining<String>(', ', '[', ']');
      final list = ['a', 'b', 'c'];
      final result = list.fold(collector.supplier(), (acc, e) {
        collector.accumulator(acc, e);
        return acc;
      });
      expect(collector.finisher(result), equals('[a, b, c]'));
    });

    test('summingInt sums integers', () {
      final collector = Collectors.summingInt<int>((e) => e);
      final result = [1, 2, 3].fold(collector.supplier(), (acc, e) {
        collector.accumulator(acc, e);
        return acc;
      });
      expect(collector.finisher(result), equals(6));
    });

    test('summingDouble sums doubles', () {
      final collector = Collectors.summingDouble<double>((e) => e);
      final result = [1.5, 2.5].fold(collector.supplier(), (acc, e) {
        collector.accumulator(acc, e);
        return acc;
      });
      expect(collector.finisher(result), closeTo(4.0, 1e-9));
    });

    test('groupingBy groups by key', () {
      final collector = Collectors.groupingBy<String, int>((e) => e.length);
      final result = ['a', 'bb', 'c'].fold(collector.supplier(), (acc, e) {
        collector.accumulator(acc, e);
        return acc;
      });
      expect(collector.finisher(result), equals({1: ['a', 'c'], 2: ['bb']}));
    });

    test('partitioningBy partitions by predicate', () {
      final collector = Collectors.partitioningBy<int>((e) => e % 2 == 0);
      final result = [1, 2, 3, 4].fold(collector.supplier(), (acc, e) {
        collector.accumulator(acc, e);
        return acc;
      });
      expect(collector.finisher(result), equals({true: [2, 4], false: [1, 3]}));
    });

    test('averagingInt computes average', () {
      final collector = Collectors.averagingInt<int>((e) => e);
      final result = [1, 2, 3].fold(collector.supplier(), (acc, e) {
        collector.accumulator(acc, e);
        return acc;
      });
      expect(collector.finisher(result), closeTo(2.0, 1e-9));
    });

    test('averagingDouble computes average', () {
      final collector = Collectors.averagingDouble<double>((e) => e);
      final result = [1.0, 2.0, 3.0].fold(collector.supplier(), (acc, e) {
        collector.accumulator(acc, e);
        return acc;
      });
      expect(collector.finisher(result), closeTo(2.0, 1e-9));
    });

    test('summarizingInt returns correct stats', () {
      final collector = Collectors.summarizingInt<int>((e) => e);
      final result = [3, 1, 4].fold(collector.supplier(), (acc, e) {
        collector.accumulator(acc, e);
        return acc;
      });
      final stats = collector.finisher(result);
      expect(stats.sum, equals(8));
      expect(stats.count, equals(3));
      expect(stats.min, equals(1));
      expect(stats.max, equals(4));
      expect(stats.average, closeTo(2.666, 1e-3));
    });

    test('summarizingDouble returns correct stats', () {
      final collector = Collectors.summarizingDouble<double>((e) => e);
      final result = [1.5, 2.5, 3.0].fold(collector.supplier(), (acc, e) {
        collector.accumulator(acc, e);
        return acc;
      });
      final stats = collector.finisher(result);
      expect(stats.sum, closeTo(7.0, 1e-9));
      expect(stats.count, equals(3));
      expect(stats.min, closeTo(1.5, 1e-9));
      expect(stats.max, closeTo(3.0, 1e-9));
      expect(stats.average, closeTo(7.0 / 3.0, 1e-9));
    });
  });
}