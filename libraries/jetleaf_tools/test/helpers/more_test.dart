import 'package:jetleaf_core/lang.dart';
import 'package:test/test.dart';

class MoreUser with EqualsAndHashCode {
  final String id;
  final String? name;

  MoreUser(this.id, this.name);

  @override
  List<Object?> equalizedProperties() => [id, name];
}

void main() {
  group('EqualsAndHashCode (MoreUser basics)', () {
    test('two identical objects are equal', () {
      final a = MoreUser('1', 'Alice');
      final b = MoreUser('1', 'Alice');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a.toString(), contains('MoreUser'));
    });

    test('different property makes objects unequal', () {
      final a = MoreUser('1', 'Alice');
      final b = MoreUser('1', 'Bob');

      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('null properties are respected', () {
      final a = MoreUser('1', null);
      final b = MoreUser('1', null);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}