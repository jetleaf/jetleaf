// test/dialect/mysql_dialect_test.dart

import 'package:test/test.dart';
import 'package:jetleaf_data/jetleaf_data.dart';
import 'package:jetleaf_data/mysql.dart';

import '../support/ensure_registry.dart';
import '../support/test_entities.dart';

void main() {
  setUpAll(ensureAotRegistered);

  late EntityMetadata<TestUser> users;
  late MySqlDialect dialect;

  setUpAll(() {
    users = EntityMetadataRegistry.instance.get<TestUser>();
    dialect = const MySqlDialect();
  });

  test('placeholders are question marks', () {
    final criteria = QueryCriteria.select(
      metadata: users,
      predicate: PartCriterion(Part(property: 'email', operator_: PartOperator.equals)),
      values: ['ada@example.com'],
    );

    final rendered = dialect.renderQuery(criteria);
    expect(rendered.getSql(), contains('`email_address` = ?'));
  });

  test('identifiers use backticks', () {
    final sql = dialect.buildCreateTableQuery(users);
    expect(sql, contains('CREATE TABLE IF NOT EXISTS `users` ('));
    expect(sql, contains('`email_address` VARCHAR(320) NOT NULL UNIQUE'));
    expect(sql, contains('PRIMARY KEY (`id`)'));
  });

  test('auto increment uses BIGINT AUTO_INCREMENT without inline primary key', () {
    final sql = dialect.buildCreateTableQuery(users);
    expect(sql, contains('`id` BIGINT AUTO_INCREMENT'));
    expect(sql, contains('PRIMARY KEY (`id`)'));
  });

  test('insert has no RETURNING and excludes the auto increment id', () {
    final sql = dialect.buildInsertQuery(users);

    expect(sql, isNot(contains('RETURNING')));
    expect(sql, contains('INSERT INTO `users` (`email_address`'));
  });

  test('boolean maps to TINYINT(1)', () {
    final mapper = MySqlTypeMapper();
    final column = users.columnByProperty('active')!;
    expect(mapper.columnType(column), 'TINYINT(1)');
  });

  test('CREATE INDEX has no IF NOT EXISTS', () {
    final ddl = dialect.buildCreateIndexQuery(
      users,
      const EntityIndex(name: 'idx_users_email', columnList: 'email_address'),
    );

    expect(ddl, 'CREATE INDEX `idx_users_email` ON `users` (`email_address`)');
  });

  test('unbounded limit literal is the max bigint unsigned', () {
    expect(dialect.getUnboundedLimitLiteral(), '18446744073709551615');
  });

  test('ON DUPLICATE KEY UPDATE suffix renders', () {
    expect(
      dialect.upsertSuffix(['email_address']),
      ' ON DUPLICATE KEY UPDATE `email_address` = VALUES(`email_address`)',
    );
  });
}