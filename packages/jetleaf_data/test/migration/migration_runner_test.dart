// test/migration/migration_runner_test.dart

import 'package:test/test.dart';
import 'package:jetleaf_data/jetleaf_data.dart';
import 'package:jetleaf_data/mongo.dart';
import 'package:jetleaf_data/sqlite.dart';

import '../support/ensure_registry.dart';
import '../support/fake_database_client.dart';
import '../support/test_entities.dart';

void main() {
  setUpAll(ensureAotRegistered);

  Migration createUsersTable() => SqlMigration(
        MigrationVersion.parse('V1__create_users'),
        const [
          'CREATE TABLE IF NOT EXISTS "users" ("id" INTEGER PRIMARY KEY AUTOINCREMENT, "email_address" TEXT UNIQUE NOT NULL)',
        ],
      );

  Migration addIndex() => SqlMigration(
        MigrationVersion.parse('V2__add_email_index'),
        const [
          'CREATE INDEX IF NOT EXISTS "idx_users_email" ON "users" ("email_address")',
        ],
      );

  Migration backfill() => SqlMigration(
        MigrationVersion.parse('V3__backfill'),
        const [
          "UPDATE users SET email_address = email_address WHERE 1 = 1",
        ],
      );

  group('MigrationVersion', () {
    test('parses plain dotted versions', () {
      final version = MigrationVersion.parse('2.1.3');
      expect(version.getSegments(), [2, 1, 3]);
      expect(version.getValue(), '2.1.3');
    });

    test('parses flyway-style versions', () {
      final version = MigrationVersion.parse('V3__add_unique_index');
      expect(version.getSegments(), [3]);
      expect(version.getDescription(), 'add unique index');
    });

    test('versions compare segment-wise numerically', () {
      expect(
        MigrationVersion.parse('1.9.0').compareTo(MigrationVersion.parse('1.10.0')),
        isNegative,
      );
      expect(
        MigrationVersion.parse('2').compareTo(MigrationVersion.parse('1.99.99')),
        isPositive,
      );
      expect(
        MigrationVersion.parse('1').compareTo(MigrationVersion.parse('1.0.0')),
        0,
      );
    });

    test('rejects malformed versions', () {
      expect(() => MigrationVersion.parse('V1__'), throwsA(isA<Exception>()));
      expect(() => MigrationVersion.parse('1.x.2'), throwsA(isA<Exception>()));
    });
  });

  group('SchemaGenerator', () {
    test('emits CREATE TABLE and CREATE INDEX for @Indexes', () {
      final dialect = const SqliteDialect();
      final generator = SchemaGenerator(dialect);
      final product = EntityMetadataRegistry.instance.get<TestProduct>();

      final result = generator.generateFor(product);

      expect(result.getStatements().first, contains('CREATE TABLE IF NOT EXISTS "products"'));
      expect(result.getStatements().any((sql) => sql.contains('idx_products_name')), isTrue);
      expect(
        result
            .getStatements()
            .any((sql) => sql.contains('CREATE UNIQUE INDEX') && sql.contains('idx_products_sku')),
        isTrue,
      );
    });
  });

  group('MigrationRunner', () {
    late FakeDatabaseClient client;
    late MigrationRunner runner;
    late List<Map<String, Object?>> bookkeeping;

    setUp(() {
      bookkeeping = [];
      client = FakeDatabaseClient();
      client.when((sql, params) {
        final normalized = sql
            .toLowerCase()
            .replaceAll('"', '')
            .replaceAll('\n', ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

        if (normalized.startsWith('select') &&
            normalized.contains('from jetleaf_schema_migrations')) {
          return QueryResult.fromRows(List<Map<String, Object?>>.from(bookkeeping));
        }

        if (normalized.startsWith('insert into jetleaf_schema_migrations')) {
          bookkeeping.add({
            'version': params[0],
            'description': params[1],
            'checksum': params[2],
            'applied_at': params[3],
          });
          return QueryResult.affected(1);
        }

        return null;
      });

      runner = MigrationRunner(client, const SqliteDialect());
    });

    test('applies pending migrations in version order and records them', () async {
      final result = await runner.migrate([backfill(), createUsersTable(), addIndex()]);

      expect(result.getApplied().map((version) => version.getValue()), ['1', '2', '3']);
      expect(result.getSkipped(), isEmpty);

      final recorded = client.recorded.map((statement) => statement.sql).toList();

      expect(
        recorded.first,
        contains('CREATE TABLE IF NOT EXISTS "jetleaf_schema_migrations"'),
      );
      expect(recorded.any((sql) => sql.contains('CREATE TABLE IF NOT EXISTS "users"')), isTrue);
      expect(recorded.any((sql) => sql.contains('"idx_users_email"')), isTrue);

      final bookkeepingInserts = recorded
          .where((sql) => sql.contains('INSERT INTO "jetleaf_schema_migrations"'))
          .toList();
      expect(bookkeepingInserts, hasLength(3));

      final usersIndex = recorded.indexWhere((sql) => sql.contains('"idx_users_email"'));
      final secondBookkeeping =
          recorded.indexWhere((sql) => sql.contains('INSERT INTO "jetleaf_schema_migrations"'));
      expect(secondBookkeeping, lessThan(usersIndex + 1));
    });

    test('already-applied migrations are skipped with matching checksums', () async {
      await runner.migrate([createUsersTable(), addIndex()]);

      client.recorded.clear();

      final second = await runner.migrate([createUsersTable(), addIndex()]);

      expect(second.getApplied(), isEmpty);
      expect(second.getSkipped().map((version) => version.getValue()), ['1', '2']);
      expect(
        client.recorded.any(
          (statement) => statement.sql.contains('CREATE TABLE IF NOT EXISTS "users"'),
        ),
        isFalse,
      );
    });

    test('checksum drift aborts with MigrationException', () async {
      await runner.migrate([createUsersTable()]);

      final tampered = SqlMigration(
        MigrationVersion.parse('V1__create_users'),
        const [
          'CREATE TABLE IF NOT EXISTS "users" ("id" INTEGER PRIMARY KEY AUTOINCREMENT, "email_address" TEXT UNIQUE NOT NULL, "extra" TEXT)',
        ],
      );

      await expectLater(
        () => runner.migrate([tampered]),
        throwsA(
          isA<MigrationException>().having(
            (e) => e.message,
            'message',
            contains('Checksum mismatch'),
          ),
        ),
      );
    });

    test('duplicate versions abort before applying anything', () async {
      await expectLater(
        () => runner.migrate([createUsersTable(), createUsersTable()]),
        throwsA(
          isA<MigrationException>().having(
            (e) => e.message,
            'message',
            contains('Duplicate'),
          ),
        ),
      );

      expect(client.recorded, isEmpty);
    });

    test('failing migration rolls back and throws MigrationException', () async {
      final failing = SqlMigration(
        MigrationVersion.parse('V1__boom'),
        const ['SELECT THIS IS NOT VALID SQL'],
      );

      client = FakeDatabaseClient();
      client.when((sql, params) {
        if (sql.contains('NOT VALID')) {
          throw StateError('syntax error near NOT');
        }

        return null;
      });
      runner = MigrationRunner(client, const SqliteDialect());

      await expectLater(
        () => runner.migrate([failing]),
        throwsA(
          isA<MigrationException>().having(
            (e) => e.message,
            'message',
            contains('Migration 1'),
          ),
        ),
      );

      expect(client.transactionRollbackCount, 1);
      expect(client.transactionCommitCount, 0);
    });

    test('mongo path records migrations through the document client', () async {
      final mongoClient = FakeDatabaseClient();
      final mongoRunner = MigrationRunner(mongoClient, const MongoDialect());

      final result = await mongoRunner.migrate([createUsersTable(), addIndex()]);

      expect(result.getApplied(), hasLength(2));
      expect(mongoClient.collections['jetleaf_schema_migrations'], hasLength(2));
      expect(
        mongoClient.collections['jetleaf_schema_migrations']!.map((doc) => doc['version']),
        containsAll(['1', '2']),
      );
    });
  });
}