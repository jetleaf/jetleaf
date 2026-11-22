// test/dialect/mongo_dialect_test.dart

import 'package:test/test.dart';
import 'package:jetleaf_data/jetleaf_data.dart';
import 'package:jetleaf_data/mongo.dart';

import '../support/ensure_registry.dart';
import '../support/test_entities.dart';

void main() {
  setUpAll(ensureAotRegistered);

  late EntityMetadata<TestUser> users;
  late MongoDialect dialect;

  setUpAll(() {
    users = EntityMetadataRegistry.instance.get<TestUser>();
    dialect = const MongoDialect();
  });

  group('filter rendering', () {
    test('empty criteria renders an empty filter', () {
      final criteria = QueryCriteria.select(metadata: users);
      expect(dialect.buildFilterDocument(criteria), isEmpty);
    });

    test('equality renders {field: value}', () {
      final criteria = QueryCriteria.select(
        metadata: users,
        predicate: PartCriterion(Part(property: 'email', operator_: PartOperator.equals)),
        values: ['ada@example.com'],
      );

      expect(dialect.buildFilterDocument(criteria), {'email_address': 'ada@example.com'});
    });

    test('gte/active conjunction renders a flat document', () {
      final criteria = QueryCriteria.select(
        metadata: users,
        predicate: CompositeCriterion.and([
          PartCriterion(Part(property: 'age', operator_: PartOperator.greaterThanEqual)),
          PartCriterion(Part(property: 'active', operator_: PartOperator.isTrue)),
        ]),
        values: [36],
      );

      expect(dialect.buildFilterDocument(criteria), {
        'user_age': {'\$gte': 36},
        'is_active': true,
      });
    });

    test('disjunction wraps in \$or', () {
      final criteria = QueryCriteria.select(
        metadata: users,
        predicate: CompositeCriterion.or([
          PartCriterion(Part(property: 'email', operator_: PartOperator.equals)),
          PartCriterion(Part(property: 'lastName', operator_: PartOperator.equals)),
        ]),
        values: ['a@example.com', 'Lovelace'],
      );

      expect(dialect.buildFilterDocument(criteria), {
        '\$or': [
          {'email_address': 'a@example.com'},
          {'last_name': 'Lovelace'},
        ],
      });
    });

    test('between renders \$gte/\$lte', () {
      final criteria = QueryCriteria.select(
        metadata: users,
        predicate: PartCriterion(Part(property: 'age', operator_: PartOperator.between)),
        values: [18, 65],
      );

      expect(dialect.buildFilterDocument(criteria), {
        'user_age': {'\$gte': 18, '\$lte': 65},
      });
    });

    test('in renders \$in', () {
      final criteria = QueryCriteria.select(
        metadata: users,
        predicate: PartCriterion(Part(property: 'lastName', operator_: PartOperator.in_)),
        values: [
          ['Lovelace', 'Hopper'],
        ],
      );

      expect(dialect.buildFilterDocument(criteria), {
        'last_name': {
          '\$in': ['Lovelace', 'Hopper'],
        },
      });
    });

    test('startingWith anchors a case-insensitive regex', () {
      final criteria = QueryCriteria.select(
        metadata: users,
        predicate: PartCriterion(
          Part(property: 'firstName', operator_: PartOperator.startingWith, ignoreCase: true),
        ),
        values: ['Ada'],
      );

      expect(dialect.buildFilterDocument(criteria), {
        'first_name': {'\$regex': '^Ada', '\$options': 'i'},
      });
    });

    test('containing wraps with substring regex and escapes regex chars', () {
      final criteria = QueryCriteria.select(
        metadata: users,
        predicate: PartCriterion(Part(property: 'email', operator_: PartOperator.containing)),
        values: ['ada.lovelace'],
      );

      expect(dialect.buildFilterDocument(criteria), {
        'email_address': {'\$regex': 'ada\\.lovelace'},
      });
    });

    test('isNull and isNotNull render null comparisons', () {
      final criteria = QueryCriteria.select(
        metadata: users,
        predicate: CompositeCriterion.and([
          PartCriterion(Part(property: 'email', operator_: PartOperator.isNull)),
          PartCriterion(Part(property: 'lastName', operator_: PartOperator.isNotNull)),
        ]),
      );

      expect(dialect.buildFilterDocument(criteria), {
        'email_address': null,
        'last_name': {'\$ne': null},
      });
    });
  });

  group('sort and render', () {
    test('sort document uses 1/-1 directions', () {
      final sort = Sort.by([SortOrder.desc('createdAt'), SortOrder.asc('email')]);
      expect(dialect.buildSortDocument(sort, users), {'created_at': -1, 'email_address': 1});
    });

    test('renderQuery produces a debug find() string and the filter document', () {
      final criteria = QueryCriteria.select(
        metadata: users,
        predicate: PartCriterion(Part(property: 'active', operator_: PartOperator.isTrue)),
        sort: Sort.by([SortOrder.asc('email')]),
        limit: 5,
      );

      final rendered = dialect.renderQuery(criteria);
      expect(rendered.getDocument(), {'is_active': true});
      expect(rendered.getSql(), contains('db.users.find'));
    });

    test('count renders countDocuments debug form', () {
      final criteria = QueryCriteria.count(
        metadata: users,
        predicate: PartCriterion(Part(property: 'active', operator_: PartOperator.isTrue)),
      );

      final rendered = dialect.renderQuery(criteria);
      expect(rendered.getSql(), startsWith('db.users.countDocuments'));
      expect(rendered.getDocument(), {'is_active': true});
    });
  });

  group('DDL debug renderings', () {
    test('createTable is a no-op debug string', () {
      expect(dialect.buildCreateTableQuery(users), 'db.createCollection("users")');
    });

    test('createIndex renders db.collection.createIndex', () {
      final ddl = dialect.buildCreateIndexQuery(
        users,
        const EntityIndex(name: 'idx_users_email', columnList: 'email_address', unique: true),
      );

      expect(ddl, contains('createIndex'));
      expect(ddl, contains('idx_users_email'));
      expect(ddl, contains('unique: true'));
    });
  });
}