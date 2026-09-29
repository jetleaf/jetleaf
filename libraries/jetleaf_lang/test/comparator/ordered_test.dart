import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

void main() {
  group('Ordered precedence tests', () {
    test('HIGHEST_PRECEDENCE should be greater than any lower number', () {
      final values = [
        Ordered.HIGHEST_PRECEDENCE,
        Ordered.HIGHEST_PRECEDENCE - 1,
        0,
        -10,
        Ordered.LOWEST_PRECEDENCE
      ];

      final sorted = List<int>.from(values)..sort((a, b) => b.compareTo(a));

      expect(sorted.first, equals(Ordered.HIGHEST_PRECEDENCE),
          reason: 'HIGHEST_PRECEDENCE should be first when sorted descending');
    });

    test('LOWEST_PRECEDENCE should be less than any higher number', () {
      final values = [
        Ordered.HIGHEST_PRECEDENCE,
        Ordered.LOWEST_PRECEDENCE + 1,
        0,
        -10,
        Ordered.LOWEST_PRECEDENCE
      ];

      final sorted = List<int>.from(values)..sort((a, b) => a.compareTo(b));

      expect(sorted.first, equals(Ordered.LOWEST_PRECEDENCE),
          reason: 'LOWEST_PRECEDENCE should be first when sorted ascending');
    });

    test('Arithmetic around HIGHEST_PRECEDENCE behaves correctly', () {
      expect(Ordered.HIGHEST_PRECEDENCE - 1, lessThan(Ordered.HIGHEST_PRECEDENCE),
          reason: 'Subtracting 1 from HIGHEST_PRECEDENCE should reduce its value');
    });

    test('Arithmetic around LOWEST_PRECEDENCE behaves correctly', () {
      expect(Ordered.LOWEST_PRECEDENCE + 1, greaterThan(Ordered.LOWEST_PRECEDENCE),
          reason: 'Adding 1 to LOWEST_PRECEDENCE should increase its value');
    });

    test('Range consistency', () {
      expect(Ordered.HIGHEST_PRECEDENCE, greaterThan(Ordered.LOWEST_PRECEDENCE),
          reason: 'HIGHEST_PRECEDENCE must be greater than LOWEST_PRECEDENCE');
    });
  });
}