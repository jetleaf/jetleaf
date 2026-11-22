// test/dialect/sqlite_dialect_test.dart

import 'package:test/test.dart';
import 'package:jetleaf_data/jetleaf_data.dart';
import 'package:jetleaf_data/sqlite.dart';

import '../support/ensure_registry.dart';
import '../support/test_entities.dart';

void main() {
  setUpAll(ensureAotRegistered);

  late EntityMetadata<TestUser> users;
  late EntityMetadata<TestUuidEntity> uuids;
  late SqliteDialect dialect;

  setUpAll(() {
    users = EntityMetadataRegistry.instance.get<TestUser>();
    uuids = EntityMetadataRegistry.instance.get<TestUuidEntity>();
    dialect = const SqliteDialect();
  });

  test('placeholders are question marks and identifiers are double-quoted', () {
    final criteria = QueryCriteria.select(
      metadata: users,
      predicate: PartCriterion(Part(property: 'email', operator_: PartOperator.equals)),
      values: ['ada@example.com'],
    );

    final rendered = dialect.renderQuery(criteria);
    expect(rendered.getSql(), contains('"email_address" = ?'));
  });

  test('auto increment id is INTEGER PRIMARY KEY AUTOINCREMENT with no separate PRIMARY KEY', () {
    final sql = dialect.buildCreateTableQuery(users);

    expect(sql, contains('"id" INTEGER PRIMARY KEY AUTOINCREMENT'));
    expect(sql.contains('PRIMARY KEY ("id")'), isFalse);
  });

  test('RETURNING is supported for INSERT', () {
    expect(dialect.buildInsertQuery(users), endsWith('RETURNING "id"'));
  });

  test('CREATE INDEX IF NOT EXISTS is supported', () {
    final ddl = dialect.buildCreateIndexQuery(
      users,
      const EntityIndex(name: 'idx_users_email', columnList: 'email_address'),
    );

    expect(ddl, 'CREATE INDEX IF NOT EXISTS "idx_users_email" ON "users" ("email_address")');
  });

  test('bool maps to INTEGER', () {
    final mapper = SqliteTypeMapper();
    expect(mapper.columnType(users.columnByProperty('active')!), 'INTEGER');
    expect(mapper.columnType(users.columnByProperty('email')!), 'TEXT');
    expect(mapper.columnType(users.columnByProperty('age')!), 'INTEGER');
  });

  test('uuid identifiers are stored as TEXT', () {
    final sql = dialect.buildCreateTableQuery(uuids);
    expect(sql, contains('"id" VARCHAR(36)'));
    expect(sql, contains('"label" TEXT'));
  });
}