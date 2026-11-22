// test/query/part_tree_test.dart

import 'package:test/test.dart';
import 'package:jetleaf_data/jetleaf_data.dart';

import '../support/ensure_registry.dart';
import '../support/test_entities.dart';

void main() {
  setUpAll(ensureAotRegistered);

  late EntityMetadata<TestUser> users;
  late EntityMetadata<TestAccount> accounts;

  setUpAll(() {
    users = EntityMetadataRegistry.instance.get<TestUser>();
    accounts = EntityMetadataRegistry.instance.get<TestAccount>();
  });

  PartTree parse(String method) => PartTree.parse(method, metadata: users);

  group('subjects', () {
    test('find is recognized', () => expect(parse('findByEmail').getSubject(), PartSubject.find));
    test('read is recognized', () => expect(parse('readByEmail').getSubject(), PartSubject.read));
    test('get is recognized', () => expect(parse('getByEmail').getSubject(), PartSubject.get));
    test('query is recognized', () => expect(parse('queryByEmail').getSubject(), PartSubject.query));
    test('count is recognized', () => expect(parse('countByEmail').getSubject(), PartSubject.count));
    test('exists is recognized', () => expect(parse('existsByEmail').getSubject(), PartSubject.exists));
    test('delete is recognized', () => expect(parse('deleteByLastName').getSubject(), PartSubject.delete));
    test('remove is recognized', () => expect(parse('removeByLastName').getSubject(), PartSubject.remove));
    test('findAll without predicate parses', () {
      final tree = parse('findAll');
      expect(tree.getPredicate(), isNull);
      expect(tree.isSelect(), isTrue);
    });
    test('countAll without predicate parses', () {
      final tree = parse('countAll');
      expect(tree.isCount(), isTrue);
      expect(tree.getParameterCount(), 0);
    });
    test('unknown subject throws', () {
      expect(() => parse('frobnicateByEmail'), throwsA(isA<QueryDerivationException>()));
    });
    test('find distinct flips the distinct flag', () {
      final tree = parse('findDistinctByLastName');
      expect(tree.isDistinct(), isTrue);
      expect(tree.getParts().single.getProperty(), 'lastName');
    });
    test('exists maps to isExists', () => expect(parse('existsByEmail').isExists(), isTrue));
    test('delete maps to isDelete', () => expect(parse('deleteByEmail').isDelete(), isTrue));
    test('count maps to isCount', () => expect(parse('countByEmail').isCount(), isTrue));
  });

  group('first/top limits', () {
    test('findTopBy limits to 1', () => expect(parse('findTopByLastName').getLimit(), 1));
    test('findFirstBy limits to 1', () => expect(parse('findFirstByLastName').getLimit(), 1));
    test('findTop3By limits to 3', () => expect(parse('findTop3ByLastName').getLimit(), 3));
    test('findFirst10By limits to 10', () => expect(parse('findFirst10ByLastName').getLimit(), 10));
    test('findTopBy with predicate keeps it', () {
      final tree = parse('findTopByLastName');
      expect(tree.getParts().single.getProperty(), 'lastName');
      expect(tree.getLimit(), 1);
    });
    test('findDistinctTopBy combines flags', () {
      final tree = parse('findDistinctTopByLastName');
      expect(tree.isDistinct(), isTrue);
      expect(tree.getLimit(), 1);
    });
    test('findTop0By throws', () {
      expect(() => parse('findTop0ByLastName'), throwsA(isA<QueryDerivationException>()));
    });
  });

  group('comparison operators', () {
    test('default operator is equals', () {
      final part = parse('findByEmail').getParts().single;
      expect(part.getOperator(), PartOperator.equals);
      expect(part.getParameterCount(), 1);
    });

    test('Is is equals', () => expect(parse('findByEmailIs').getParts().single.getOperator(), PartOperator.equals));
    test('Equals is equals', () => expect(parse('findByEmailEquals').getParts().single.getOperator(), PartOperator.equals));
    test('IsNot is notEquals', () => expect(parse('findByEmailIsNot').getParts().single.getOperator(), PartOperator.notEquals));
    test('Not is notEquals', () => expect(parse('findByEmailNot').getParts().single.getOperator(), PartOperator.notEquals));
    test('GreaterThan', () => expect(parse('findByAgeGreaterThan').getParts().single.getOperator(), PartOperator.greaterThan));
    test('GreaterThanEqual', () => expect(parse('findByAgeGreaterThanEqual').getParts().single.getOperator(), PartOperator.greaterThanEqual));
    test('LessThan', () => expect(parse('findByAgeLessThan').getParts().single.getOperator(), PartOperator.lessThan));
    test('LessThanEqual', () => expect(parse('findByAgeLessThanEqual').getParts().single.getOperator(), PartOperator.lessThanEqual));
    test('Before', () => expect(parse('findByCreatedAtBefore').getParts().single.getOperator(), PartOperator.before));
    test('After', () => expect(parse('findByCreatedAtAfter').getParts().single.getOperator(), PartOperator.after));
    test('Between consumes two parameters', () {
      final part = parse('findByAgeBetween').getParts().single;
      expect(part.getOperator(), PartOperator.between);
      expect(part.getParameterCount(), 2);
    });
    test('In', () => expect(parse('findByLastNameIn').getParts().single.getOperator(), PartOperator.in_));
    test('NotIn', () => expect(parse('findByLastNameNotIn').getParts().single.getOperator(), PartOperator.notIn));
    test('Like', () => expect(parse('findByEmailLike').getParts().single.getOperator(), PartOperator.like));
    test('NotLike', () => expect(parse('findByEmailNotLike').getParts().single.getOperator(), PartOperator.notLike));
    test('StartingWith', () => expect(parse('findByFirstNameStartingWith').getParts().single.getOperator(), PartOperator.startingWith));
    test('EndingWith', () => expect(parse('findByFirstNameEndingWith').getParts().single.getOperator(), PartOperator.endingWith));
    test('Containing', () => expect(parse('findByFirstNameContaining').getParts().single.getOperator(), PartOperator.containing));
    test('NotContaining', () => expect(parse('findByFirstNameNotContaining').getParts().single.getOperator(), PartOperator.notContaining));
    test('True consumes no parameter', () => expect(parse('findByActiveTrue').getParts().single.getOperator(), PartOperator.isTrue));
    test('False consumes no parameter', () => expect(parse('findByActiveFalse').getParts().single.getOperator(), PartOperator.isFalse));
    test('IsNull consumes no parameter', () => expect(parse('findByEmailIsNull').getParts().single.getOperator(), PartOperator.isNull));
    test('IsNotNull consumes no parameter', () => expect(parse('findByEmailIsNotNull').getParts().single.getOperator(), PartOperator.isNotNull));
    test('parameter count for the tree sums up', () {
      final tree = parse('findByEmailAndAgeBetween');
      expect(tree.getParameterCount(), 3);
    });
  });

  group('IgnoreCase modifier', () {
    test('applies to equals', () => expect(parse('findByEmailIgnoreCase').getParts().single.isIgnoreCase(), isTrue));
    test('applies to like operators', () => expect(parse('findByEmailStartingWithIgnoreCase').getParts().single.isIgnoreCase(), isTrue));
    test('applies to notEquals', () => expect(parse('findByEmailNotIgnoreCase').getParts().single.isIgnoreCase(), isTrue));
    test('rejected on non-string operators', () {
      expect(() => parse('findByAgeGreaterThanIgnoreCase'), throwsA(isA<QueryDerivationException>()));
    });
    test('rejected on boolean literal operators', () {
      expect(() => parse('findByActiveTrueIgnoreCase'), throwsA(isA<QueryDerivationException>()));
    });
  });

  group('and/or precedence and nesting', () {
    test('single And group', () {
      final tree = parse('findByLastNameAndFirstName');
      expect(tree.getPredicate(), isA<CompositeCriterion>());
      expect(tree.getParts().map((p) => p.getProperty()), ['lastName', 'firstName']);
      expect((tree.getPredicate()! as CompositeCriterion).isOr(), isFalse);
    });

    test('single Or group', () {
      final tree = parse('findByLastNameOrEmail');
      expect((tree.getPredicate()! as CompositeCriterion).isOr(), isTrue);
      expect(tree.getParts().map((p) => p.getProperty()), ['lastName', 'email']);
    });

    test('and binds tighter than or: A or B and C → A or (B and C)', () {
      final tree = parse('findByLastNameOrEmailAndAge');
      final root = tree.getPredicate()! as CompositeCriterion;
      expect(root.isOr(), isTrue);
      expect(root.getChildren(), hasLength(2));
      expect(root.getChildren()[0], isA<PartCriterion>());
      expect((root.getChildren()[0] as PartCriterion).getPart().getProperty(), 'lastName');
      final nested = root.getChildren()[1] as CompositeCriterion;
      expect(nested.isOr(), isFalse);
      expect(
        nested.getChildren().map((c) => (c as PartCriterion).getPart().getProperty()),
        ['email', 'age'],
      );
    });

    test('mixed boolean chains flatten in order', () {
      final tree = parse('findByActiveTrueOrAgeGreaterThanEqualAndLastNameOrFirstName');
      final root = tree.getPredicate()! as CompositeCriterion;
      expect(root.isOr(), isTrue);
      expect(root.getChildren(), hasLength(3));
      expect(
        (root.getChildren()[1] as CompositeCriterion)
            .getChildren()
            .map((c) => (c as PartCriterion).getPart().getProperty()),
        ['age', 'lastName'],
      );
    });

    test('and of ors keeps ors as children', () {
      final tree = parse('findByAgeGreaterThanAndActiveTrueOrLastNameAndFirstName');
      final root = tree.getPredicate()! as CompositeCriterion;
      expect(root.isOr(), isTrue);
      expect(root.getChildren().length, 2);
    });
  });

  group('nested property paths', () {
    test('profile bio resolves through one-to-one', () {
      final tree = PartTree.parse('findByProfileBio', metadata: accounts);
      expect(tree.getParts().single.getProperty(), 'profile.bio');
    });

    test('profile bio equals renders with .path', () {
      final tree = PartTree.parse('findByProfileBioStartingWith', metadata: accounts);
      expect(tree.getParts().single.getProperty(), 'profile.bio');
      expect(tree.getParts().single.getOperator(), PartOperator.startingWith);
    });

    test('order-by navigates relationships', () {
      final tree = PartTree.parse('findAllOrderByProfileBioDesc', metadata: accounts);
      expect(tree.getSort().getFor('profile.bio')?.getDirection(), SortDirection.DESC);
    });
  });

  group('ordering', () {
    test('order by with direction', () {
      final tree = parse('findByLastNameOrderByCreatedAtDesc');
      expect(tree.getSort().getFor('createdAt')?.getDirection(), SortDirection.DESC);
    });

    test('multiple ordering clauses keep source order', () {
      final tree = parse('findByLastNameOrderByCreatedAtDescFirstNameAsc');
      final orders = tree.getSort().toList();
      expect(orders.map((o) => o.getProperty()), ['createdAt', 'firstName']);
      expect(orders.map((o) => o.getDirection()), [SortDirection.DESC, SortDirection.ASC]);
    });

    test('default direction is ascending', () {
      final tree = parse('findByLastNameOrderByCreatedAt');
      expect(tree.getSort().getFor('createdAt')?.getDirection(), SortDirection.ASC);
    });

    test('ordering without a predicate works', () {
      final tree = parse('findAllOrderByCreatedAtDesc');
      expect(tree.getPredicate(), isNull);
      expect(tree.getSort().getFor('createdAt')?.getDirection(), SortDirection.DESC);
    });

    test('unknown ordering property throws', () {
      expect(() => parse('findByLastNameOrderByFrobnicateDesc'), throwsA(isA<QueryDerivationException>()));
    });

    test('unresolvable property in predicate throws', () {
      expect(() => parse('findByFrobnicateWidget'), throwsA(isA<QueryDerivationException>()));
    });
  });

  group('malformed methods', () {
    test('empty predicate after By throws', () {
      expect(() => parse('findBy'), throwsA(isA<QueryDerivationException>()));
    });

    test('dangling And throws', () {
      expect(() => parse('findByAgeGreaterThanAnd'), throwsA(isA<QueryDerivationException>()));
    });

    test('dangling Or throws', () {
      expect(() => parse('findByAgeGreaterThanOr'), throwsA(isA<QueryDerivationException>()));
    });

    test('leading And throws', () {
      expect(() => parse('findByAndAgeGreaterThan'), throwsA(isA<QueryDerivationException>()));
    });
  });

  group('serialization', () {
    test('parsed trees round-trip their operand count deterministically', () {
      final tree = parse('findByEmailAndAgeBetween');
      expect(tree.getParameterCount(), 3);
      expect(tree.getParts(), hasLength(2));
      expect(tree.getParts()[1].getParameterCount(), 2);
    });

    test('equal trees for equal method names', () {
      expect(parse('findByEmail'), parse('findByEmail'));
      expect(parse('findByEmail') == parse('findByLastName'), isFalse);
    });
  });
}