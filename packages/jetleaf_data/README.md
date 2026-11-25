# 💾 Jetleaf Data — Data Access, Repositories & Mapping

[![pub package](https://img.shields.io/badge/version-2.1.0-blue)](https://pub.dev/packages/jetleaf_data)
[![License: Jetleaf](https://img.shields.io/badge/license-Jetleaf-green)](#license)
[![Dart SDK](https://img.shields.io/badge/sdk-%3E%3D3.9.0-blue)](https://dart.dev)

Enterprise data access and object-relational / document mapping for Dart — the
Jetleaf persistence layer.

## 📋 Overview

`jetleaf_data` provides a complete persistence toolkit:

- **Declarative repositories** — derive queries from method names (`findByEmail`, `findByAgeGreaterThanEqualAndActiveTrue`, …)
- **CRUD, paging and sorting** — with a typed `PageRequest` / `Sort` API
- **Dialect-agnostic SQL** — PostgreSQL, MySQL/MariaDB, SQLite and MongoDB, plus a registry for custom dialects
- **Declared queries** — `@Query` with native SQL or lightweight JQL, and `@Modifying` updates
- **Transactions** — `@Transactional` with propagation and isolation, bound to a Dart zone
- **Auditing & optimistic locking** — `@CreatedDate`, `@LastModifiedDate`, `@Version`
- **Migrations** — versioned migrations with checksums, plus DDL generation from entity metadata
- **Connection pooling** — bounded pools with checkout timeouts and idle validation
- **Type conversion** — built-in converters and a registry for your own

## 🚀 Quick Start

### Installation

```yaml
dependencies:
  jetleaf: ^2.1.0
  jetleaf_core: ^2.1.0
  jetleaf_data: ^2.1.0
```

You also supply a `DatabaseClient` (your driver, or a pool built around one).
The driver contract is dialect-agnostic, so the same repository code works
across SQL and document backends.

### 1. Define an entity

```dart
import 'package:jetleaf_data/jetleaf_data.dart';

@Entity()
@Table(name: 'users')
class User {
  @Id()
  @GeneratedValue(strategy: GenerationStrategy.autoIncrement)
  int? id;

  @Column(name: 'email_address', unique: true, nullable: false, length: 320)
  String? email;

  String? firstName;
  String? lastName;

  @Column(name: 'user_age')
  int? age;

  @Column(name: 'is_active')
  bool? active;

  @CreatedDate()
  DateTime? createdAt;

  @LastModifiedDate()
  DateTime? updatedAt;

  @Version()
  int? version;

  User();
}
```

Entities need a no-argument constructor and exactly one `@Id` field. Run
`jl build` so the reflection registry knows about them.

### 2. Create a repository

```dart
final factory = RepositoryFactorySupport(
  client: myDatabaseClient,          // or a DefaultConnectionPool
  dialect: const PostgreSqlDialect(),
);

final users = factory.createSimple<User, int>();
```

Or construct one directly:

```dart
final repo = SimpleJetleafRepository<User, int>(
  EntityMetadataRegistry.instance.get<User>(),
  client,
  const PostgreSqlDialect(),
);
```

### 3. Use it

```dart
await repo.save(User()
  ..email = 'ada@example.com'
  ..firstName = 'Ada');

final ada = await repo.findById(1);
final all = await repo.findAll();

final page = await repo.findPage(
  PageRequest(0, 20, Sort.by([SortOrder.asc('email')])),
);
print(page.getContent());
```

## 📚 Key Features

### 1. Derived queries

Method names are parsed into a query tree and rendered for the active dialect:

```dart
final tree = PartTree.parse(
  'findByAgeGreaterThanEqualAndActiveTrue',
  metadata: usersMetadata,
);
final matches = await repo.queryList(tree, [36]);
```

| Feature | Example |
| :--- | :--- |
| Subjects | `find…`, `read…`, `get…`, `query…`, `count…`, `exists…`, `delete…`, `remove…` |
| Distinct | `findDistinctByLastName` |
| Limit | `findTopByLastName`, `findTop3By…`, `findFirstBy…`, `findTopOrderBy…` |
| Nested paths | `findByAddressCity` (through `@ManyToOne` / `@OneToOne`) |
| And / Or | `findByLastNameAndFirstName`, `findByLastNameOrActiveTrue` (And binds tighter) |
| Comparison | `Equals`, `Is`, `Not`, `IsNot`, `Like`, `NotLike`, `StartingWith`, `EndingWith`, `Containing`, `NotContaining`, `GreaterThan[Equal]`, `LessThan[Equal]`, `Before`, `After`, `Between`, `In`, `NotIn` |
| Boolean / Null | `True`, `False`, `IsNull`, `IsNotNull` |
| Case-insensitive | `findByEmailIgnoreCase`, `findByEmailStartingWithIgnoreCase` |
| Ordering | `findByLastNameOrderByCreatedAtDesc`, `…OrderByFirstNameAscLastNameDesc` |

### 2. Declared queries

When a method name is not expressive enough, write the query:

```dart
@Query('SELECT * FROM users WHERE email_address = :email', nativeQuery: true)
Future<User?> findByEmailNative(@Param('email') String email);

// JQL — entity references are translated to tables and aliases.
@Query('SELECT u FROM User u WHERE u.lastName = :name ORDER BY u.firstName')
Future<List<User>> findOrdered(@Param('name') String name);

@Modifying()
@Query('UPDATE User u SET u.active = :active WHERE u.email = :email')
Future<int> updateActive(
  @Param('active') bool active,
  @Param('email') String email,
);
```

JQL is intentionally small: entity names map to tables, `alias.property` maps
to a quoted column, and bare property names map to quoted columns. Use native
queries for joins, functions or complex projections.

### 3. Dialects

| Dialect | Placeholders | Identifiers | Auto increment | `RETURNING` |
| :--- | :--- | :--- | :--- | :--- |
| `PostgreSqlDialect` | `$1, $2…` | `"users"` | `BIGSERIAL` | ✅ |
| `MySqlDialect` | `?` | `` `users` `` | `BIGINT AUTO_INCREMENT` | — |
| `SqliteDialect` | `?` | `"users"` | `INTEGER PRIMARY KEY AUTOINCREMENT` | ✅ |
| `MongoDialect` | — (BSON) | — | — | — |

Register your own dialect when you need one:

```dart
DialectRegistry.instance.register('cockroachdb', CockroachDbDialect.new);
final dialect = DialectRegistry.instance.forUrl('jdbc:postgresql://localhost/app');
```

Generate DDL straight from entity metadata:

```dart
final schema = SchemaGenerator(dialect);
print(schema.generateForType(User).statements.join(';\n'));
```

### 4. Connections and pooling

```dart
final pool = DefaultConnectionPool(
  clientFactory: () async => myDatabaseClient,
  configuration: const PoolConfiguration(
    maxConnections: 20,
    connectionTimeout: Duration(seconds: 10),
    validateOnCheckout: true,
  ),
);
```

Checkouts beyond capacity wait up to `connectionTimeout`; uncommitted
transactions are rolled back when a lease returns to the pool; idle connections
are validated with `SELECT 1` before re-use. Pass the pool wherever a
`DatabaseClient` is expected.

### 5. Transactions

```dart
@Transactional(
  propagation: Propagation.required,
  isolation: Isolation.readCommitted,
)
Future<Order> placeOrder(Cart cart) async {
  // repository calls here join one transaction
}
```

`TransactionalMethodInterceptor` is auto-registered by `DataAutoConfiguration`.
The manager is resolved at startup:

1. an explicit `PlatformTransactionManager` pod, if one exists;
2. otherwise a `DataSourceTransactionManager` built from the available `ConnectionFactory` pod;
3. otherwise the invocation fails fast with a descriptive `TransactionSystemException`.

Propagation values: `required`, `requiresNew`, `mandatory`, `supports`,
`notSupported`, `never`. The ambient transaction lives in a forked `Zone`, so
`requiresNew` truly suspends an outer transaction and rollback-only marks
propagate from joined participants to the outermost owner.

```dart
final manager = DataSourceTransactionManager(connectionPool);
```

### 6. Migrations

```dart
final runner = MigrationRunner(client, const PostgreSqlDialect());

await runner.migrate([
  SqlMigration(MigrationVersion.parse('V1__create_users'), [createUsersDdl]),
  SqlMigration(MigrationVersion.parse('V2__add_index'), [addIndexDdl]),
]);
```

- Bookkeeping table `jetleaf_schema_migrations` stores version, description, checksum and `applied_at`
- Pending migrations run in version order, each inside a transaction
- Checksum drift aborts the run with `MigrationException`
- Duplicate versions abort before anything is applied
- MongoDB is supported through the document client contract

### 7. Auditing and optimistic locking

```dart
class User {
  @Version() int? version;                  // incremented on every update
  @CreatedDate() DateTime? createdAt;       // stamped on insert
  @LastModifiedDate() DateTime? updatedAt;  // stamped on every save
}
```

A concurrent update on a stale entity throws `OptimisticLockException` when the
versioned update affects zero rows.

### 8. Type conversion

Built-in conversion covers `bool` ↔ `0/1`, `DateTime` ↔ ISO-8601 / epoch
milliseconds, `Enum` ↔ `String` (through the materialized registry) and
`int` ↔ `double`. Add your own:

```dart
TypeConverterRegistry.instance.register(EncryptedStringConverter());
```

### 9. Dynamic and custom repositories

Create a repository from an interface without writing an implementation:

```dart
final repo = RepositoryFactorySupport(client: client, dialect: dialect)
    .createDynamic<dynamic>(TestUserRepository);

await repo.findByEmail('ada@example.com');
await repo.countByActiveTrue();
```

Dynamic proxies route through `noSuchMethod`, so use `dynamic` call sites,
`jl build`-generated AOT proxies, or subclass `SimpleJetleafRepository` for a
statically-typed repository.

Supply your own base implementation when every repository needs shared behavior:

```dart
final repo = RepositoryFactorySupport(
  client: client,
  dialect: dialect,
  baseImplementation: (metadata, client, dialect, converters) =>
      CompanyRepository(metadata, client, dialect),
).createSimple<User, int>();
```

## 🎯 Common Patterns

### Pattern 1: Transactional service

```dart
@Service()
class UserService {
  final SimpleJetleafRepository<User, int> _users;

  UserService(this._users);

  @Transactional()
  Future<User> register(String email) =>
      _users.save(User()..email = email);
}
```

Method-level interception is provided by `DataAutoConfiguration`; make sure the
service is a pod and run `jl build`.

### Pattern 2: Paginated listing

```dart
final page = await users.findPage(
  PageRequest(2, 25, Sort.by([SortOrder.desc('createdAt')])),
);
final rows = page.getContent();
final total = page.getTotalElements();
```

### Pattern 3: Per-environment dialect

```dart
final dialect = DialectRegistry.instance.forUrl(environment['DATABASE_URL']!);
final factory = RepositoryFactorySupport(client: client, dialect: dialect);
```

Keep repositories independent of the concrete database by injecting the
dialect and client as pods.

### Pattern 4: Schema at startup

```dart
final synchronizer = AutoSchemaSynchronizer(client: client, dialect: dialect);
await synchronizer.synchronize([User, Order]);
```

Use migrations for production and schema synchronization for development or
tests.

## ⚠️ Common Issues

| Issue | Cause | Solution |
| :--- | :--- | :--- |
| `NoSuchMethodError` on a repository call | Dynamic proxy used through a statically typed interface | Use `dynamic`, generate AOT proxies with `jl build`, or subclass `SimpleJetleafRepository` |
| Entity fields are null after loading | Missing no-argument constructor or class unknown to the registry | Add `User();` and run `jl build` (or `jl build --test`) |
| `OptimisticLockException` on save | Stale `@Version` value | Reload the entity and retry the update |
| `NoSuchPodDefinitionException` for a transaction manager | No transaction manager or `ConnectionFactory` pod | Declare a `PlatformTransactionManager` / `DataSourceTransactionManager` pod |
| `@Query` method is treated as a derived query | Missing `@Query` metadata in the registry | Run `jl build` and verify the method annotation is present |
| `@Query` with `Page` / `Slice` return fails | Not supported | Query a list and build a page from it |
| Nested derived property does not join | Only to-one associations are supported | Model the path with `@ManyToOne` / `@OneToOne`, or write a native query |
| Custom dialect not found | Dialect was never registered | Call `DialectRegistry.instance.register(...)` before creating the factory |
| No database driver available | Only the driver contract ships here | Provide a `DatabaseClient` implementation (see `test/support/fake_database_client.dart` for an example) |

## 📋 Best Practices

### ✅ DO

- Annotate one `@Id` field and keep a no-argument constructor on every entity
- Run `jl build` after changing entities, repositories or `@Query` methods
- Use `@Transactional` at the service boundary, not on individual repository calls
- Inject the dialect and client so the same repository works across environments
- Version production schema changes and let checksum drift fail loudly
- Store auditing fields and `@Version` on entities that need history or concurrency safety

### ❌ DON'T

- Put business logic in repository interfaces — use a service pod
- Rely on implicit joins through collections in derived method names
- Use native SQL in JQL syntax — set `nativeQuery: true`
- Reuse a stale entity across transactions and expect the version to match
- Register the same dialect twice with different implementations
- Assume auditing writes are batched — they are applied per row

## 🧪 Testing

```bash
# generate the reflection registry (required for entity tests)
dart run jetleaf_tools build --test

dart test
dart test test/smoke_test.dart
```

The suite fakes the driver (`test/support/fake_database_client.dart`), so no
running database is needed; SQL generation is verified statement by statement.

## 📦 Dependencies

- **`jetleaf_core`** — IoC container, annotations and exception types
- **`meta`** — annotations
- **`jetleaf_tools`** (dev) — `jl build` / `jl build --test` for reflection metadata

## 📄 License

This package is part of the Jetleaf Framework. See LICENSE in the root directory.

## 🔗 Related Packages

- **`jetleaf`** — Framework bootstrap and lifecycle
- **`jetleaf_core`** — Dependency injection and pod management
- **`jetson`** — JSON serialization
- **`jetleaf_validation`** — Validate entity inputs before persistence

## 📞 Support

For issues, questions, or contributions, visit:

- [GitHub Issues](https://github.com/jetleaf/jetleaf/issues)
- [Documentation](https://jetleaf.hapnium.com/docs/data)
- [Community Forum](https://forum.jetleaf.hapnium.com)

---

**Created with ❤️ by [Hapnium](https://hapnium.com)**