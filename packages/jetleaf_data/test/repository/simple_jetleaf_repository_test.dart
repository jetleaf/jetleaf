// test/repository/simple_jetleaf_repository_test.dart

import 'package:test/test.dart';
import 'package:jetleaf_data/jetleaf_data.dart';
import 'package:jetleaf_data/mongo.dart';
import 'package:jetleaf_data/mysql.dart';
import 'package:jetleaf_data/sqlite.dart';

import '../support/ensure_registry.dart';
import '../support/fake_database_client.dart';
import '../support/test_entities.dart';

class _UserClassRepository extends JetleafRepository<TestUser, int> {}

void main() {
  setUpAll(ensureAotRegistered);

  late EntityMetadata<TestUser> users;
  late EntityMetadata<TestProduct> products;
  late EntityMetadata<TestUuidEntity> uuids;

  setUpAll(() {
    users = EntityMetadataRegistry.instance.get<TestUser>();
    products = EntityMetadataRegistry.instance.get<TestProduct>();
    uuids = EntityMetadataRegistry.instance.get<TestUuidEntity>();
  });

  SimpleJetleafRepository<TestUser, int> userRepo(FakeDatabaseClient client) =>
      SimpleJetleafRepository<TestUser, int>(users, client, const SqliteDialect());

  TestUser ada({int? id, int? version, String? email}) => TestUser.withValues(
        id: id,
        email: email ?? 'ada@example.com',
        firstName: 'Ada',
        lastName: 'Lovelace',
        age: 36,
        active: true,
        createdAt: DateTime.utc(2024, 1, 1),
        version: version,
      );

  Map<String, Object?> adaRow({int? id, int? version}) => {
        'id': id ?? 1,
        'email_address': 'ada@example.com',
        'first_name': 'Ada',
        'last_name': 'Lovelace',
        'user_age': 36,
        'is_active': 1,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-02T00:00:00.000Z',
        'version': version ?? 1,
      };

  group('findById', () {
    test('emits a parameterized lookup and maps rows to entities', () async {
      final client = FakeDatabaseClient(defaultRows: [adaRow(id: 7)]);
      final repo = userRepo(client);

      final found = await repo.findById(7);

      expect(found, isNotNull);
      expect(found!.id, 7);
      expect(found.email, 'ada@example.com');
      expect(client.recorded.single.sql, contains('FROM "users"'));
      expect(client.recorded.single.sql, contains('"id" = ?'));
      expect(client.recorded.single.parameters, [7]);
    });

    test('returns null when no row matches', () async {
      final client = FakeDatabaseClient();
      final repo = userRepo(client);

      expect(await repo.findById(99), isNull);
    });
  });

  group('findAll / findAllById', () {
    test('findAll selects without predicate', () async {
      final client = FakeDatabaseClient(defaultRows: [adaRow(id: 1), adaRow(id: 2)]);
      final repo = userRepo(client);

      final all = await repo.findAll();
      expect(all, hasLength(2));
      expect(client.recorded.single.sql, isNot(contains('WHERE')));
    });

    test('findAllById expands IN lists', () async {
      final client = FakeDatabaseClient(defaultRows: [adaRow(id: 1)]);
      final repo = userRepo(client);

      await repo.findAllById([1, 2, 3]);
      expect(client.recorded.single.sql, contains('"id" IN (?, ?, ?)'));
      expect(client.recorded.single.parameters, [1, 2, 3]);
    });

    test('findAllById with empty iterable short-circuits', () async {
      final client = FakeDatabaseClient();
      final repo = userRepo(client);

      expect(await repo.findAllById([]), isEmpty);
      expect(client.recorded, isEmpty);
    });
  });

  group('save', () {
    test('autoincrement id hydrates from the RETURNING clause', () async {
      final client = FakeDatabaseClient();
      client.whenSqlContains('INSERT INTO', [
        {'id': 42},
      ]);
      final repo = userRepo(client);

      final saved = await repo.save(ada());

      expect(saved.id, 42);
      final insert = client.recorded.single;
      expect(insert.sql, contains('INSERT INTO "users"'));
      expect(insert.sql, contains('RETURNING "id"'));
      expect(insert.parameters, isNotEmpty);
    });

    test('autoincrement id hydrates from LastInsertId for dialects without RETURNING', () async {
      final client = FakeDatabaseClient(nextLastInsertId: 42);
      final repo = SimpleJetleafRepository<TestUser, int>(users, client, const MySqlDialect());

      final saved = await repo.save(ada());

      expect(saved.id, 42);
      final insert = client.recorded.single;
      expect(insert.sql, contains('INSERT INTO `users`'));
      expect(insert.sql, isNot(contains('RETURNING')));
    });

    test('insert applies auditing columns', () async {
      final client = FakeDatabaseClient(nextLastInsertId: 42);
      final repo = userRepo(client);

      final saved = await repo.save(ada());

      expect(saved.createdAt, isNotNull);
      expect(saved.updatedAt, isNotNull);
      expect(saved.version, 0);
    });

    test('uuid identifiers are framework-generated', () async {
      final uuidUsers = SimpleJetleafRepository<TestUuidEntity, String>(
        uuids,
        FakeDatabaseClient(),
        const SqliteDialect(),
      );

      final saved = await uuidUsers.save(TestUuidEntity()..label = 'x');

      expect(saved.id, isNotNull);
      expect(saved.id!.length, 36);
    });

    test('existing entities update with version predicate and increment', () async {
      final client = FakeDatabaseClient();
      final repo = userRepo(client);

      final saved = await repo.save(ada(id: 7, version: 3));

      expect(saved.version, 4);
      final update = client.recorded.single;
      expect(update.sql, contains('UPDATE "users"'));
      expect(update.sql, contains('WHERE "id" = ? AND "version" = ?'));
      expect(update.parameters.last, 3);
      expect(update.parameters[update.parameters.length - 2], 7);
    });

    test('update affecting zero rows throws OptimisticLockException', () async {
      final client = FakeDatabaseClient(defaultAffectedRows: 0);
      final repo = userRepo(client);

      await expectLater(
        () => repo.save(ada(id: 7, version: 3)),
        throwsA(isA<OptimisticLockException>()),
      );
    });

    test('enum attributes round-trip through the type converter', () async {
      final productRepo = SimpleJetleafRepository<TestProduct, int>(
        products,
        FakeDatabaseClient(defaultRows: [
          {'id': 1, 'name': 'Flux', 'status': 'active', 'sku': 'FX-1'},
        ]),
        const SqliteDialect(),
      );

      final found = await productRepo.findById(1);
      expect(found!.status, TestStatus.active);
    });

    test('saveAll iterates and returns saved entities', () async {
      final client = FakeDatabaseClient(nextLastInsertId: 1);
      final repo = userRepo(client);

      final saved = await repo.saveAll([ada(), ada(email: 'grace@example.com')]);

      expect(saved, hasLength(2));
      expect(client.recorded, hasLength(2));
    });
  });

  group('delete', () {
    test('deleteById fetches first, then deletes with version predicate', () async {
      final client = FakeDatabaseClient(defaultRows: [adaRow(id: 7, version: 3)]);
      final repo = userRepo(client);

      await repo.deleteById(7);

      expect(client.recorded, hasLength(2));
      expect(client.recorded[0].sql, contains('SELECT'));
      expect(client.recorded[1].sql, contains('DELETE FROM "users" WHERE "id" = ? AND "version" = ?'));
      expect(client.recorded[1].parameters, [7, 3]);
    });

    test('deleteById of missing entity is a no-op', () async {
      final client = FakeDatabaseClient();
      final repo = userRepo(client);

      await repo.deleteById(99);

      expect(client.recorded, hasLength(1));
      expect(client.recorded.single.sql, contains('SELECT'));
    });

    test('delete affecting zero rows with version throws OptimisticLockException', () async {
      final client = FakeDatabaseClient(
        defaultRows: [adaRow(id: 7, version: 3)],
        defaultAffectedRows: 0,
      );
      final repo = userRepo(client);

      await expectLater(
        () => repo.deleteById(7),
        throwsA(isA<OptimisticLockException>()),
      );
    });

    test('deleteAllInBatch expands IN list', () async {
      final client = FakeDatabaseClient();
      final repo = userRepo(client);

      await repo.deleteAllInBatch([ada(id: 1), ada(id: 2), ada(id: 3)]);

      expect(client.recorded.single.sql, contains('"id" IN (?, ?, ?)'));
      expect(client.recorded.single.parameters, [1, 2, 3]);
    });
  });

  group('count and exists', () {
    test('count renders COUNT(*) and unwraps the value', () async {
      final client = FakeDatabaseClient(defaultRows: [
        {'COUNT(*)': 137},
      ]);
      final repo = userRepo(client);

      expect(await repo.count(), 137);
      expect(client.recorded.single.sql, contains('COUNT(*)'));
    });

    test('existsById is true when a row is found', () async {
      final client = FakeDatabaseClient(defaultRows: [adaRow()]);
      final repo = userRepo(client);

      expect(await repo.existsById(1), isTrue);
    });

    test('existsById is false when nothing matches', () async {
      final client = FakeDatabaseClient();
      final repo = userRepo(client);

      expect(await repo.existsById(1), isFalse);
    });
  });

  group('paging', () {
    test('findPage runs a content and a count query', () async {
      final client = FakeDatabaseClient();
      client.whenSqlContains('COUNT(*)', [
        {'COUNT(*)': 137},
      ]);

      final repo = userRepo(client);
      client.defaultRows.addAll(List.generate(20, (i) => adaRow(id: i + 1)));

      final page = await repo.findPage(PageRequest(1, 20));

      expect(page.getContent(), hasLength(20));
      expect(page.getTotalElements(), 137);
      expect(page.getTotalPages(), 7);
      expect(page.getNumber(), 1);
      expect(page.getSize(), 20);

      final statements = client.recorded.map((statement) => statement.sql).toList();
      expect(
        statements.any((sql) => sql.contains('LIMIT 20') && sql.contains('OFFSET 20')),
        isTrue,
      );
      expect(statements.any((sql) => sql.contains('COUNT(*)')), isTrue);
    });

    test('findAllSorted applies ORDER BY', () async {
      final client = FakeDatabaseClient(defaultRows: [adaRow()]);
      final repo = userRepo(client);

      await repo.findAllSorted(Sort.by([SortOrder.desc('createdAt')]));

      expect(client.recorded.single.sql, contains('ORDER BY "created_at" DESC'));
    });
  });

  group('derived query execution', () {
    test('executeQueryList renders and binds predicate values', () async {
      final client = FakeDatabaseClient(defaultRows: [adaRow()]);
      final repo = userRepo(client);

      final tree = PartTree.parse('findByAgeGreaterThanEqualAndActiveTrue', metadata: users);
      final result = await repo.executeQueryList(tree, [36]);

      expect(result, hasLength(1));
      expect(client.recorded.single.sql, contains('("user_age" >= ? AND "is_active" = TRUE)'));
      expect(client.recorded.single.parameters, [36]);
    });

    test('executeQueryOne caps at two rows and throws when ambiguous', () async {
      final client = FakeDatabaseClient(defaultRows: [adaRow(id: 1), adaRow(id: 2)]);
      final repo = userRepo(client);

      final tree = PartTree.parse('findByLastName', metadata: users);
      await expectLater(
        () => repo.executeQueryOne(tree, ['Lovelace']),
        throwsA(isA<IncorrectResultSizeDataAccessException>()),
      );
    });

    test('executeQueryOne returns null when no rows match', () async {
      final client = FakeDatabaseClient();
      final repo = userRepo(client);

      final tree = PartTree.parse('findByEmail', metadata: users);
      expect(await repo.executeQueryOne(tree, ['ghost@example.com']), isNull);
    });

    test('executeQueryCount returns the aggregate', () async {
      final client = FakeDatabaseClient(defaultRows: [
        {'COUNT(*)': 42},
      ]);
      final repo = userRepo(client);

      final tree = PartTree.parse('countByActiveTrue', metadata: users);
      expect(await repo.executeQueryCount(tree, const []), 42);
    });

    test('executeQueryExists returns boolean', () async {
      final client = FakeDatabaseClient(defaultRows: [adaRow()]);
      final repo = userRepo(client);

      final tree = PartTree.parse('existsByEmail', metadata: users);
      expect(await repo.executeQueryExists(tree, ['ada@example.com']), isTrue);
    });

    test('executeQueryDelete executes the delete and reports affected rows', () async {
      final client = FakeDatabaseClient(defaultAffectedRows: 5);
      final repo = userRepo(client);

      final tree = PartTree.parse('deleteByLastName', metadata: users);
      expect(await repo.executeQueryDelete(tree, ['Lovelace']), 5);
      expect(client.recorded.single.sql, contains('DELETE FROM "users" WHERE "last_name" = ?'));
    });
  });

  group('DefaultRepositoryExecutor & JetleafRepository class hierarchy', () {
    test('class-based JetleafRepository delegates CRUD to DefaultRepositoryExecutor', () async {
      final client = FakeDatabaseClient(defaultRows: [adaRow(id: 7)]);
      final factory = RepositoryFactorySupport(
        client: client,
        dialect: const SqliteDialect(),
      );
      final classRepo = _UserClassRepository()..setExecutor(DefaultRepositoryExecutor(factory));

      final user = await classRepo.findById(7);
      expect(user, isNotNull);
      expect(user!.id, 7);

      final all = await classRepo.findAll();
      expect(all, hasLength(1));
    });
  });

  group('document dialect path', () {
    SimpleJetleafRepository<TestUser, int> mongoRepo(FakeDatabaseClient client) =>
        SimpleJetleafRepository<TestUser, int>(users, client, const MongoDialect());

    test('insertDocument stores the mapped document', () async {
      final client = FakeDatabaseClient();
      final repo = mongoRepo(client);

      final entity = ada();
      await repo.save(entity);

      expect(client.collections['users'], hasLength(1));
      expect(client.collections['users']!.single['email_address'], 'ada@example.com');
    });

    test('findById reads through the document client', () async {
      final client = FakeDatabaseClient();
      final repo = mongoRepo(client);

      client.collections['users'] = [
        {
          'id': 7,
          'email_address': 'ada@example.com',
          'first_name': 'Ada',
          'last_name': 'Lovelace',
          'user_age': 36,
          'is_active': true,
          'version': 1,
        },
      ];

      final found = await repo.findById(7);
      expect(found, isNotNull);
      expect(found!.email, 'ada@example.com');
      expect(found.active, isTrue);
    });

    test('countDocuments is used for count()', () async {
      final client = FakeDatabaseClient();
      final repo = mongoRepo(client);

      client.collections['users'] = [
        {'id': 1, 'email_address': 'a@example.com'},
        {'id': 2, 'email_address': 'b@example.com'},
      ];

      expect(await repo.count(), 2);
    });

    test('deleteById deletes through the document client', () async {
      final client = FakeDatabaseClient();
      final repo = mongoRepo(client);

      client.collections['users'] = [
        {'id': 7, 'email_address': 'ada@example.com'},
      ];

      await repo.deleteById(7);
      expect(client.collections['users'], isEmpty);
    });

    test('derived findByEmail renders a mongo filter', () async {
      final client = FakeDatabaseClient();
      final repo = mongoRepo(client);

      client.collections['users'] = [
        {'id': 1, 'email_address': 'ada@example.com'},
      ];

      final tree = PartTree.parse('findByEmail', metadata: users);
      final found = await repo.executeQueryList(tree, ['ada@example.com']);

      expect(found, hasLength(1));
      expect(client.recorded.map((statement) => statement.sql).join(), contains('find'));
    });
  });
}
