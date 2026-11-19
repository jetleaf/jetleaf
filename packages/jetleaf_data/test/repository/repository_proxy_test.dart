// test/repository/repository_proxy_test.dart

import 'package:test/test.dart';
import 'package:jetleaf_core/lang.dart';
import 'package:jetleaf_data/jetleaf_data.dart';
import 'package:jetleaf_data/sqlite.dart';

import '../support/ensure_registry.dart';
import '../support/fake_database_client.dart';
import '../support/test_entities.dart';

abstract interface class TestUserRepository {
  Future<TestUser?> findById(int id);
  Future<List<TestUser>> findAll();
  Future<int> count();
  Future<bool> existsByEmail(String email);
  Future<TestUser?> findByEmail(String email);
  Future<TestUser?> findByEmailIgnoreCase(String email);
  Future<List<TestUser>> findByAgeGreaterThanEqual(int age);
  Future<List<TestUser>> findByLastNameIn(List<String> names);
  Future<List<TestUser>> findByLastNameOrderByFirstNameAsc(String lastName);
  Future<int> countByActiveTrue();
  Future<int> deleteByLastName(String lastName);
  Future<TestUser?> findTopByOrderByCreatedAtDesc();

  @Query('SELECT * FROM users WHERE email_address = :email', nativeQuery: true)
  Future<TestUser?> findByEmailNative(@Param('email') String email);

  @Query('SELECT u FROM TestUser u WHERE u.email = :email')
  Future<List<TestUser>> findByEmailJql(@Param('email') String email);

  @Query('SELECT u FROM TestUser u WHERE u.lastName = :lastName ORDER BY u.firstName ASC')
  Future<List<TestUser>> findOrderedJql(@Param('lastName') String lastName);

  @Modifying(clearAutomatically: true)
  @Query('UPDATE TestUser u SET u.active = :active WHERE u.email = :email')
  Future<int> updateActive(@Param('active') bool active, @Param('email') String email);
}

void main() {
  setUpAll(ensureAotRegistered);

  late EntityMetadata<TestUser> users;

  setUpAll(() {
    users = EntityMetadataRegistry.instance.get<TestUser>();
  });

  DynamicRepositoryProxy proxy(FakeDatabaseClient client) => DynamicRepositoryProxy(
        repositoryClass: Class<TestUserRepository>(),
        metadata: users,
        client: client,
        dialect: const SqliteDialect(),
      );

  Map<String, Object?> row(int id, {String email = 'ada@example.com', String? lastName}) => {
        'id': id,
        'email_address': email,
        'first_name': 'Ada',
        'last_name': lastName ?? 'Lovelace',
        'user_age': 36,
        'is_active': 1,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-02T00:00:00.000Z',
        'version': 1,
      };

  test('findById dispatches to the CRUD executor', () async {
    final client = FakeDatabaseClient(defaultRows: [row(7)]);
    final repo = proxy(client);

    final found = await (repo as dynamic).findById(7);

    expect(found, isNotNull);
    expect(client.recorded.single.sql, contains('SELECT'));
    expect(client.recorded.single.parameters, [7]);
  });

  test('findByEmail derives and executes a query', () async {
    final client = FakeDatabaseClient(defaultRows: [row(7)]);
    final repo = proxy(client);

    final found = await (repo as dynamic).findByEmail('ada@example.com');

    expect(found, isNotNull);
    expect(client.recorded.single.sql, contains('"email_address" = ?'));
    expect(client.recorded.single.parameters, ['ada@example.com']);
  });

  test('findByEmailIgnoreCase wraps LOWER() comparison', () async {
    final client = FakeDatabaseClient(defaultRows: [row(7)]);
    final repo = proxy(client);

    await (repo as dynamic).findByEmailIgnoreCase('ADA@EXAMPLE.COM');

    expect(client.recorded.single.sql, contains('LOWER("email_address") = LOWER(?)'));
  });

  test('findByAgeGreaterThanEqual binds a typed argument', () async {
    final client = FakeDatabaseClient(defaultRows: [row(7)]);
    final repo = proxy(client);

    await (repo as dynamic).findByAgeGreaterThanEqual(36);

    expect(client.recorded.single.sql, contains('"user_age" >= ?'));
    expect(client.recorded.single.parameters, [36]);
  });

  test('findByLastNameOrderByFirstNameAsc appends ORDER BY', () async {
    final client = FakeDatabaseClient(defaultRows: [row(7)]);
    final repo = proxy(client);

    await (repo as dynamic).findByLastNameOrderByFirstNameAsc('Lovelace');

    expect(client.recorded.single.sql, contains('ORDER BY "first_name" ASC'));
  });

  test('countByActiveTrue renders COUNT(*)', () async {
    final client = FakeDatabaseClient(defaultRows: [
      {'COUNT(*)': 42},
    ]);
    final repo = proxy(client);

    expect(await (repo as dynamic).countByActiveTrue(), 42);
  });

  test('deleteByLastName executes DELETE and returns affected rows', () async {
    final client = FakeDatabaseClient(defaultAffectedRows: 3);
    final repo = proxy(client);

    expect(await (repo as dynamic).deleteByLastName('Lovelace'), 3);
    expect(client.recorded.single.sql, contains('DELETE FROM "users" WHERE "last_name" = ?'));
  });

  test('@Query native query expands named parameters', () async {
    final client = FakeDatabaseClient(defaultRows: [row(7)]);
    final repo = proxy(client);

    final found = await (repo as dynamic).findByEmailNative('ada@example.com');

    expect(found, isNotNull);
    final statement = client.recorded.single;
    expect(statement.sql, 'SELECT * FROM users WHERE email_address = ?');
    expect(statement.parameters, ['ada@example.com']);
  });

  test('@Query JQL translates entity reference, alias qualifier and bare names', () async {
    final client = FakeDatabaseClient(defaultRows: [row(7)]);
    final repo = proxy(client);

    final rows = await (repo as dynamic).findByEmailJql('ada@example.com');

    expect(rows, hasLength(1));
    final statement = client.recorded.single;
    expect(
      statement.sql,
      'SELECT "id", "email_address", "first_name", "last_name", "user_age", "is_active", "created_at", "updated_at", "version" FROM "users" AS u WHERE u."email_address" = ?',
    );
    expect(statement.parameters, ['ada@example.com']);
  });

  test('@Query JQL with ORDER BY translates ordering', () async {
    final client = FakeDatabaseClient(defaultRows: [row(7)]);
    final repo = proxy(client);

    await (repo as dynamic).findOrderedJql('Lovelace');

    final statement = client.recorded.single;
    expect(statement.sql, contains('ORDER BY u."first_name" ASC'));
  });

  test('@Modifying @Query executes UPDATE and returns affected rows', () async {
    final client = FakeDatabaseClient(defaultAffectedRows: 2);
    final repo = proxy(client);

    final affected = await (repo as dynamic).updateActive(false, 'ada@example.com');

    expect(affected, 2);
    final statement = client.recorded.single;
    expect(
      statement.sql,
      contains('UPDATE "users" AS u SET u."is_active" = ? WHERE u."email_address" = ?'),
    );
    expect(statement.parameters, [0, 'ada@example.com']);
  });

  test('findTopByOrderByCreatedAtDesc limits to one row', () async {
    final client = FakeDatabaseClient(defaultRows: [row(7)]);
    final repo = proxy(client);

    await (repo as dynamic).findTopByOrderByCreatedAtDesc();

    expect(client.recorded.single.sql, contains('LIMIT 1'));
    expect(client.recorded.single.sql, contains('ORDER BY "created_at" DESC'));
  });

  test('toString is handled synchronously', () {
    final client = FakeDatabaseClient();
    final repo = proxy(client);

    expect(repo.toString(), contains('DynamicRepositoryProxy'));
  });

  test('unsupported method throws UnsupportedOperationException', () async {
    final client = FakeDatabaseClient();
    final repo = proxy(client);

    await expectLater(
      () => (repo as dynamic).frobnicate(),
      throwsA(isA<UnsupportedOperationException>()),
    );
  });
}
