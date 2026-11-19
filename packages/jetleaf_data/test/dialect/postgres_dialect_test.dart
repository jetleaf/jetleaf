// test/dialect/postgres_dialect_test.dart

import 'package:test/test.dart';
import 'package:jetleaf_data/jetleaf_data.dart';
import 'package:jetleaf_data/postgres.dart';

import '../support/ensure_registry.dart';
import '../support/test_entities.dart';

void main() {
  setUpAll(ensureAotRegistered);

  late EntityMetadata<TestUser> users;
  late EntityMetadata<TestOrder> orders;
  late EntityMetadata<TestUuidEntity> uuids;
  late PostgreSqlDialect dialect;

  setUpAll(() {
    users = EntityMetadataRegistry.instance.get<TestUser>();
    orders = EntityMetadataRegistry.instance.get<TestOrder>();
    uuids = EntityMetadataRegistry.instance.get<TestUuidEntity>();
    dialect = const PostgreSqlDialect();
  });

  group('SELECT rendering', () {
    test('full projection without predicate', () {
      final criteria = QueryCriteria.select(metadata: users);
      final rendered = dialect.renderQuery(criteria);

      expect(
        rendered.getSql(),
        'SELECT "id", "email_address", "first_name", "last_name", "user_age", "is_active", "created_at", "updated_at", "version" FROM "users"',
      );
      expect(rendered.getParameters(), isEmpty);
    });

    test('equality predicate uses numbered placeholders', () {
      final criteria = QueryCriteria.select(
        metadata: users,
        predicate: PartCriterion(Part(property: 'email', operator_: PartOperator.equals)),
        values: ['ada@example.com'],
      );

      final rendered = dialect.renderQuery(criteria);
      expect(rendered.getSql(), contains('WHERE "email_address" = \$1'));
      expect(rendered.getParameters(), ['ada@example.com']);
    });

    test('conjunction of gte and boolean-true', () {
      final criteria = QueryCriteria.select(
        metadata: users,
        predicate: CompositeCriterion.and([
          PartCriterion(Part(property: 'age', operator_: PartOperator.greaterThanEqual)),
          PartCriterion(Part(property: 'active', operator_: PartOperator.isTrue)),
        ]),
        values: [36],
      );

      final rendered = dialect.renderQuery(criteria);
      expect(rendered.getSql(), contains('("user_age" >= \$1 AND "is_active" = TRUE)'));
      expect(rendered.getParameters(), [36]);
    });

    test('disjunction renders parenthesized OR', () {
      final criteria = QueryCriteria.select(
        metadata: users,
        predicate: CompositeCriterion.or([
          PartCriterion(Part(property: 'email', operator_: PartOperator.equals)),
          PartCriterion(Part(property: 'lastName', operator_: PartOperator.equals)),
        ]),
        values: ['a@example.com', 'Lovelace'],
      );

      final rendered = dialect.renderQuery(criteria);
      expect(rendered.getSql(), contains('("email_address" = \$1 OR "last_name" = \$2)'));
      expect(rendered.getParameters(), ['a@example.com', 'Lovelace']);
    });

    test('BETWEEN expands to two placeholders', () {
      final criteria = QueryCriteria.select(
        metadata: users,
        predicate: PartCriterion(Part(property: 'age', operator_: PartOperator.between)),
        values: [18, 65],
      );

      final rendered = dialect.renderQuery(criteria);
      expect(rendered.getSql(), contains('"user_age" BETWEEN \$1 AND \$2'));
      expect(rendered.getParameters(), [18, 65]);
    });

    test('IN list expands to N placeholders and flattens values', () {
      final criteria = QueryCriteria.select(
        metadata: users,
        predicate: PartCriterion(Part(property: 'lastName', operator_: PartOperator.in_)),
        values: [
          ['Lovelace', 'Hopper', 'Turing'],
        ],
      );

      final rendered = dialect.renderQuery(criteria);
      expect(rendered.getSql(), contains('"last_name" IN (\$1, \$2, \$3)'));
      expect(rendered.getParameters(), ['Lovelace', 'Hopper', 'Turing']);
    });

    test('empty IN list renders a never-true predicate', () {
      final criteria = QueryCriteria.select(
        metadata: users,
        predicate: PartCriterion(Part(property: 'lastName', operator_: PartOperator.in_)),
        values: const [[]],
      );

      final rendered = dialect.renderQuery(criteria);
      expect(rendered.getSql(), contains('"last_name" IN (NULL)'));
      expect(rendered.getParameters(), isEmpty);
    });

    test('LIKE operators keep the pattern supplied by the caller', () {
      final criteria = QueryCriteria.select(
        metadata: users,
        predicate: PartCriterion(Part(property: 'firstName', operator_: PartOperator.like)),
        values: ['%Ada%'],
      );

      final rendered = dialect.renderQuery(criteria);
      expect(rendered.getSql(), contains('"first_name" LIKE \$1'));
      expect(rendered.getParameters(), ['%Ada%']);
    });

    test('IgnoreCase wraps both sides in LOWER()', () {
      final criteria = QueryCriteria.select(
        metadata: users,
        predicate: PartCriterion(
          Part(property: 'email', operator_: PartOperator.equals, ignoreCase: true),
        ),
        values: ['ADA@EXAMPLE.COM'],
      );

      final rendered = dialect.renderQuery(criteria);
      expect(rendered.getSql(), contains('LOWER("email_address") = LOWER(\$1)'));
    });

    test('IS NULL / IS NOT NULL consume no placeholder', () {
      final criteria = QueryCriteria.select(
        metadata: users,
        predicate: CompositeCriterion.and([
          PartCriterion(Part(property: 'email', operator_: PartOperator.isNotNull)),
          PartCriterion(Part(property: 'lastName', operator_: PartOperator.isNull)),
        ]),
      );

      final rendered = dialect.renderQuery(criteria);
      expect(rendered.getSql(), contains('"email_address" IS NOT NULL'));
      expect(rendered.getSql(), contains('"last_name" IS NULL'));
      expect(rendered.getParameters(), isEmpty);
    });

    test('ordering and pagination render', () {
      final criteria = QueryCriteria.select(
        metadata: users,
        sort: Sort.by([SortOrder.desc('createdAt'), SortOrder.asc('email')]),
        limit: 20,
        offset: 40,
      );

      final rendered = dialect.renderQuery(criteria);
      expect(rendered.getSql(), contains('ORDER BY "created_at" DESC, "email_address" ASC'));
      expect(rendered.getSql(), endsWith('LIMIT 20 OFFSET 40'));
    });

    test('count renders COUNT(*)', () {
      final criteria = QueryCriteria.count(
        metadata: users,
        predicate: PartCriterion(Part(property: 'active', operator_: PartOperator.isTrue)),
      );

      final rendered = dialect.renderQuery(criteria);
      expect(rendered.getSql(), contains('SELECT COUNT(*) FROM "users"'));
      expect(rendered.getSql(), contains('WHERE "is_active" = TRUE'));
    });

    test('exists renders SELECT 1 with LIMIT 1', () {
      final criteria = QueryCriteria.exists(metadata: users);

      final rendered = dialect.renderQuery(criteria);
      expect(rendered.getSql(), contains('SELECT 1 FROM "users"'));
      expect(rendered.getSql(), endsWith('LIMIT 1'));
    });

    test('distinct selects render DISTINCT', () {
      final criteria = QueryCriteria.select(metadata: users, distinct: true);

      final rendered = dialect.renderQuery(criteria);
      expect(rendered.getSql(), contains('SELECT DISTINCT'));
    });
  });

  group('INSERT rendering', () {
    test('auto-increment identifier is excluded and RETURNING is emitted', () {
      final sql = dialect.buildInsertQuery(users);

      expect(
        sql,
        contains(
          'INSERT INTO "users" ("email_address", "first_name", "last_name", "user_age", "is_active", "created_at", "updated_at", "version")',
        ),
      );
      expect(sql, contains('VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8)'));
      expect(sql, endsWith('RETURNING "id"'));
    });

    test('snowflake identifier is included in the insert', () {
      final sql = dialect.buildInsertQuery(orders);

      expect(sql, contains('"id"'));
      expect(sql, contains('"total_cents"'));
      expect(sql, endsWith('RETURNING "id"'));
    });

    test('uuid identifier is included in the insert', () {
      final sql = dialect.buildInsertQuery(uuids);

      expect(sql, contains('"id"'));
      expect(sql, contains('"label"'));
    });
  });

  group('UPDATE rendering', () {
    test('update includes version predicate when @DataVersion is mapped', () {
      final sql = dialect.buildUpdateQuery(users);

      expect(
        sql,
        contains(
          'UPDATE "users" SET "email_address" = \$1, "first_name" = \$2, "last_name" = \$3, "user_age" = \$4, "is_active" = \$5, "created_at" = \$6, "updated_at" = \$7, "version" = \$8 WHERE "id" = \$9 AND "version" = \$10',
        ),
      );
    });
  });

  group('DELETE rendering', () {
    test('delete by id includes version predicate', () {
      final sql = dialect.buildDeleteQuery(users);
      expect(sql, 'DELETE FROM "users" WHERE "id" = \$1 AND "version" = \$2');
    });
  });

  group('DDL rendering', () {
    test('CREATE TABLE IF NOT EXISTS with primary key', () {
      final ddl = dialect.buildCreateTableQuery(users);

      expect(ddl, contains('CREATE TABLE IF NOT EXISTS "users" ('));
      expect(ddl, contains('"id" BIGSERIAL'));
      expect(ddl, contains('"email_address" VARCHAR(320) NOT NULL UNIQUE'));
      expect(ddl, contains('PRIMARY KEY ("id")'));
    });

    test('CREATE INDEX statement', () {
      final ddl = dialect.buildCreateIndexQuery(
        users,
        users.getIndexes().isEmpty
            ? const EntityIndex(
                name: 'idx_users_email',
                columnList: 'email_address',
                unique: true,
              )
            : users.getIndexes().first,
      );

      expect(
        ddl,
        'CREATE UNIQUE INDEX IF NOT EXISTS "idx_users_email" ON "users" ("email_address")',
      );
    });

    test('DROP TABLE statement', () {
      expect(dialect.buildDropTableQuery(users), 'DROP TABLE IF EXISTS "users"');
    });
  });
}
