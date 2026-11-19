// test/query/parameter_binder_test.dart

import 'package:test/test.dart';
import 'package:jetleaf_core/lang.dart';
import 'package:jetleaf_data/jetleaf_data.dart';

import '../support/ensure_registry.dart';
import '../support/test_entities.dart';

void main() {
  setUpAll(ensureAotRegistered);

  late EntityMetadata<TestUser> users;
  final binder = ParameterBinder();

  setUpAll(() {
    users = EntityMetadataRegistry.instance.get<TestUser>();
  });

  group('derived query binding', () {
    test('equals binds one argument', () {
      final tree = PartTree.parse('findByEmail', metadata: users);
      final bound = binder.bindDerived(['ada@example.com'], tree, methodName: 'findByEmail');

      expect(bound.getPositional(), ['ada@example.com']);
      expect(bound.getPageable(), isNull);
      expect(bound.getSort(), isNull);
    });

    test('between binds two arguments', () {
      final tree = PartTree.parse('findByAgeBetween', metadata: users);
      final bound = binder.bindDerived([18, 65], tree, methodName: 'findByAgeBetween');

      expect(bound.getPositional(), [18, 65]);
    });

    test('IN requires an iterable argument', () {
      final tree = PartTree.parse('findByLastNameIn', metadata: users);
      expect(
        () => binder.bindDerived(['not-a-list'], tree, methodName: 'findByLastNameIn'),
        throwsA(isA<QueryDerivationException>()),
      );

      final bound = binder.bindDerived([
        ['Lovelace', 'Hopper'],
      ], tree, methodName: 'findByLastNameIn');
      expect(bound.getPositional(), [equals(['Lovelace', 'Hopper'])]);
    });

    test('IN expands scalars in iterables only once', () {
      final tree = PartTree.parse('findByLastNameIn', metadata: users);
      final bound = binder.bindDerived([
        ['Lovelace', 'Hopper', 'Turing'],
      ], tree, methodName: 'findByLastNameIn');

      expect(bound.getPositional(), [equals(['Lovelace', 'Hopper', 'Turing'])]);
    });

    test('literal operators consume no arguments', () {
      final tree = PartTree.parse('findByActiveTrue', metadata: users);
      final bound = binder.bindDerived(const [], tree, methodName: 'findByActiveTrue');

      expect(bound.getPositional(), isEmpty);
    });

    test('startingWith wraps in prefix wildcard', () {
      final tree = PartTree.parse('findByFirstNameStartingWith', metadata: users);
      final bound = binder.bindDerived(['Ada'], tree, methodName: 'findByFirstNameStartingWith');

      expect(bound.getPositional(), ['Ada%']);
    });

    test('endingWith wraps in suffix wildcard', () {
      final tree = PartTree.parse('findByFirstNameEndingWith', metadata: users);
      final bound = binder.bindDerived(['la'], tree, methodName: 'findByFirstNameEndingWith');

      expect(bound.getPositional(), ['%la']);
    });

    test('containing wraps both sides', () {
      final tree = PartTree.parse('findByFirstNameContaining', metadata: users);
      final bound = binder.bindDerived(['da'], tree, methodName: 'findByFirstNameContaining');

      expect(bound.getPositional(), ['%da%']);
    });

    test('like keeps the caller pattern', () {
      final tree = PartTree.parse('findByFirstNameLike', metadata: users);
      final bound = binder.bindDerived(['%ada%'], tree, methodName: 'findByFirstNameLike');

      expect(bound.getPositional(), ['%ada%']);
    });

    test('date values are converted to ISO strings', () {
      final tree = PartTree.parse('findByCreatedAtBefore', metadata: users);
      final when = DateTime.utc(2030, 5, 1, 12);
      final bound = binder.bindDerived([when], tree, methodName: 'findByCreatedAtBefore');

      expect(bound.getPositional().single, isA<String>());
      expect(bound.getPositional().single, contains('2030-05-01'));
    });

    test('pageable arguments are extracted, not bound', () {
      final tree = PartTree.parse('findByLastName', metadata: users);
      final pageable = PageRequest(0, 20, Sort.by([SortOrder.asc('email')]));
      final bound = binder.bindDerived(['Lovelace', pageable], tree, methodName: 'findByLastName');

      expect(bound.getPositional(), ['Lovelace']);
      expect(bound.getPageable(), pageable);
    });

    test('sort arguments are extracted, not bound', () {
      final tree = PartTree.parse('findByLastName', metadata: users);
      final sort = Sort.by([SortOrder.desc('age')]);
      final bound = binder.bindDerived(['Lovelace', sort], tree, methodName: 'findByLastName');

      expect(bound.getPositional(), ['Lovelace']);
      expect(bound.getSort(), sort);
    });

    test('too few arguments throws', () {
      final tree = PartTree.parse('findByAgeBetween', metadata: users);
      expect(
        () => binder.bindDerived([18], tree, methodName: 'findByAgeBetween'),
        throwsA(isA<QueryDerivationException>()),
      );
    });

    test('too many arguments throws', () {
      final tree = PartTree.parse('findByAgeBetween', metadata: users);
      expect(
        () => binder.bindDerived([18, 65, 99], tree, methodName: 'findByAgeBetween'),
        throwsA(isA<QueryDerivationException>()),
      );
    });
  });

  group('argument normalization', () {
    test('positional arguments map to declared order', () {
      final method = Class<_FakeRepository>().getMethod('findByEmailAndAge')!;
      final ordered = ParameterBinder.normalizeArguments(
        ['a@example.com', 36],
        const {},
        method,
        methodName: 'findByEmailAndAge',
      );

      expect(ordered, ['a@example.com', 36]);
    });

    test('named arguments map by declared name', () {
      final method = Class<_FakeRepository>().getMethod('findByEmailAndAgeNamed')!;
      final ordered = ParameterBinder.normalizeArguments(
        const [],
        {#age: 36, #email: 'a@example.com'},
        method,
        methodName: 'findByEmailAndAgeNamed',
      );

      expect(ordered, ['a@example.com', 36]);
    });

    test('mixed positional and named bind correctly', () {
      final method = Class<_FakeRepository>().getMethod('findByEmailAndAgeMixed')!;
      final ordered = ParameterBinder.normalizeArguments(
        ['a@example.com'],
        {#age: 36},
        method,
        methodName: 'findByEmailAndAgeMixed',
      );

      expect(ordered, ['a@example.com', 36]);
    });
  });
}

abstract class _FakeRepository {
  Future<List<dynamic>> findByEmailAndAge(String email, int age);

  Future<List<dynamic>> findByEmailAndAgeNamed({
    required String email,
    required int age,
  });

  Future<List<dynamic>> findByEmailAndAgeMixed(
    String email, {
    required int age,
  });
}
