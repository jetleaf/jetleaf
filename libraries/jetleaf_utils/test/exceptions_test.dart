import 'package:jetleaf_utils/jetleaf_utils.dart';
import 'package:test/test.dart';

void main() {
  group('PlaceholderResolutionException', () {
    test('stores reason and placeholder', () {
      final ex = PlaceholderResolutionException('Unresolvable', 'my.key');
      expect(ex.reason, 'Unresolvable');
      expect(ex.placeholder, 'my.key');
      expect(ex.values, isEmpty);
    });

    test('stores value in chain', () {
      final ex = PlaceholderResolutionException('Unresolvable', 'my.key', 'fallback');
      expect(ex.values, ['fallback']);
    });

    test('withValue adds to chain', () {
      final ex1 = PlaceholderResolutionException('Unresolvable', 'my.key', 'val1');
      final ex2 = ex1.withValue('val2');
      expect(ex2.values, ['val1', 'val2']);
      expect(ex2.placeholder, 'my.key');
      expect(ex2.reason, 'Unresolvable');
    });

    test('message includes reason', () {
      final ex = PlaceholderResolutionException('Unresolvable', 'my.key');
      expect(ex.message, contains('Unresolvable'));
    });

    test('message includes value chain when present', () {
      final ex = PlaceholderResolutionException('Unresolvable', 'my.key', 'val1');
      expect(ex.message, contains('Unresolvable'));
    });
  });

  group('ParserException', () {
    test('stores message', () {
      final ex = ParserException('Failed to parse');
      expect(ex.message, 'Failed to parse');
    });

    test('stores cause', () {
      final cause = FormatException('bad format');
      final ex = ParserException('Failed to parse', cause: cause);
      expect(ex.message, 'Failed to parse');
    });
  });
}
