# jetleaf_data

**Enterprise Data Access & Object-Relational/Document Mapping for Dart** — the
Jetleaf persistence layer, architecturally benchmarked against Spring Data.

- Declarative repositories with **dynamic query derivation** (`findByEmail`,
  `findByAgeGreaterThanEqualAndActiveTrue`, …)
- Full CRUD, paging and sorting, batch operations
- **Dialect-agnostic**: PostgreSQL, MySQL/MariaDB, SQLite, MongoDB, with a
  registry for custom engines
- **Optimistic locking** via `@Version`, **auditing** via `@CreatedDate` /
  `@LastModifiedDate`
- **Declarative transactions** — `@Transactional` with Spring propagation and
  isolation semantics, bound to Dart zones
- **Schema migration** — versioned migrations with checksums + DDL generation
  from entity metadata

> Package status: `2.1.0` — full feature parity with the design in
> `roadmap/jetleaf_data.md`, minus live-database integration tests (requires
> Dockerized PostgreSQL/MongoDB; the driver abstraction and SQL rendering are
> unit-tested exhaustively instead).

---

## Quick start

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

### 2. Build a repository

```dart
import 'package:jetleaf_data/jetleaf_data.dart';

final factory = RepositoryFactorySupport(
  client: myDatabaseClient,          // your driver, or a pool (see below)
  dialect: const PostgreSqlDialect(),
);

final users = factory.createSimple<User, int>();
```

Or directly:

```dart
final repo = SimpleJetleafRepository<User, int>(
  EntityMetadataRegistry.instance.get<User>(),
  client,
  const PostgreSqlDialect(),
);
```

### 3. Use it

```dart
await repo.save(User()..email = 'ada@example.com'..firstName = 'Ada');

final ada = await repo.findById(1);
final actives = await repo.findAll();
final page = await repo.findPage(PageRequest(0, 20, Sort.by([SortOrder.asc('email')])));
```

---

## Derived query methods

Method names are parsed into a query tree and rendered per dialect:

```dart
final tree = PartTree.parse('findByAgeGreaterThanEqualAndActiveTrue', metadata: usersMetadata);
await repo.queryList(tree, [36]);
```

Full grammar:

| Feature | Example |
|---------|---------|
| Subjects | `find…`, `read…`, `get…`, `query…`, `count…`, `exists…`, `delete…`, `remove…` |
| Distinct | `findDistinctByLastName` |
| Limit | `findTopByLastName`, `findTop3By…`, `findFirstBy…`, `findTopOrderBy…` |
| Nested paths | `findByAddressCity` (through `@ManyToOne`/`@OneToOne`) |
| And / Or | `findByLastNameAndFirstName`, `findByLastNameOrActiveTrue` (And binds tighter) |
| Comparison | `Equals`, `Is`, `Not`, `IsNot`, `Like`, `NotLike`, `StartingWith`, `EndingWith`, `Containing`, `NotContaining`, `GreaterThan[Equal]`, `LessThan[Equal]`, `Before`, `After`, `Between`, `In`, `NotIn` |
| Boolean/Null | `True`, `False`, `IsNull`, `IsNotNull` |
| Case-insensitive | `findByEmailIgnoreCase`, `findByEmailStartingWithIgnoreCase` |
| Ordering | `findByLastNameOrderByCreatedAtDesc`, `…OrderByFirstNameAscLastNameDesc` |

### `@Query` — declared queries

```dart
@Query('SELECT * FROM users WHERE email_address = :email', nativeQuery: true)
Future<User?> findByEmailNative(@Param('email') String email);

// JQL — entity references are translated (table + alias substitution)
@Query('SELECT u FROM User u WHERE u.lastName = :name ORDER BY u.firstName')
Future<List<User>> findOrdered(@Param('name') String name);

@Modifying()
@Query('UPDATE User u SET u.active = :active WHERE u.email = :email')
Future<int> updateActive(@Param('active') bool active, @Param('email') String email);
```

### Dynamic proxies (no codegen)

```dart
final repo = RepositoryFactorySupport(client: client, dialect: dialect)
    .createDynamic<dynamic>(TestUserRepository);

await repo.findByEmail('ada@example.com');
await repo.countByActiveTrue();
```

Proxy caveats: dynamic proxies route through `noSuchMethod` — Dart cannot
implement unknown interfaces at runtime, so statically-typed repository
interfaces should use `jl build`-generated AOT proxies (or subclass
`SimpleJetleafRepository`, which is what the framework's own repositories do).

---

## Dialects

| Dialect | Placeholders | Identifiers | Auto increment | `RETURNING` |
|---------|-------------|-------------|----------------|-------------|
| `PostgreSqlDialect` | `$1, $2…` | `"users"` | `BIGSERIAL` | ✅ |
| `MySqlDialect` | `?` | `` `users` `` | `BIGINT AUTO_INCREMENT` | — |
| `SqliteDialect` | `?` | `"users"` | `INTEGER PRIMARY KEY AUTOINCREMENT` | ✅ |
| `MongoDialect` | — (BSON) | — | — | — |

```dart
DialectRegistry.instance.register('cockroachdb', CockroachDbDialect.new);
final dialect = DialectRegistry.instance.forUrl('jdbc:postgresql://localhost/app');
```

DDL for a mapped entity comes from metadata:

```dart
final schema = SchemaGenerator(dialect);
print(schema.generateForType(User).statements.join(';\n'));
```

## Connections & pooling

```dart
final pool = DefaultConnectionPool(
  clientFactory: () => myDatabaseClientFactory(),   // your driver
  configuration: const PoolConfiguration(
    maxConnections: 20,
    connectionTimeout: Duration(seconds: 10),
    validateOnCheckout: true,
  ),
);
```

Checkouts beyond capacity wait up to `connectionTimeout`; uncommitted
transactions are rolled back when a lease returns to the pool; idle
connections are validated with `SELECT 1` before re-use.

## Transactions

```dart
@Transactional(propagation: Propagation.required, isolation: Isolation.readCommitted)
Future<Order> placeOrder(Cart cart) => ...;
```

`@Transactional` is intercepted by `TransactionalMethodInterceptor` (auto-registered
by `DataAutoConfiguration`); the transaction manager resolves at startup:

1. an explicit `PlatformTransactionManager` pod if one exists,
2. else a `DataSourceTransactionManager` built from the available
   `ConnectionFactory` pod,
3. else invocations fail fast with a descriptive `TransactionSystemException`.

Propagation: `required`, `requiresNew`, `mandatory`, `supports`,
`notSupported`, `never` — the ambient transaction is bound to a forked
`Zone`, so `requiresNew` truly suspends the outer transaction and
rollback-only marks propagate from joined participants to the outermost
owner.

```dart
final manager = DataSourceTransactionManager(connectionPool);
```

## Migrations

```dart
final runner = MigrationRunner(client, const PostgreSqlDialect());
await runner.migrate([
  SqlMigration(MigrationVersion.parse('V1__create_users'), [createUsersDdl]),
  SqlMigration(MigrationVersion.parse('V2__add_index'), [addIndexDdl]),
]);
```

- Bookkeeping table `jetleaf_schema_migrations` (version, description,
  checksum, applied_at)
- Pending migrations apply in version order, each in a transaction
- Checksum drift aborts the run with `MigrationException`
- Duplicate versions abort before anything is applied
- MongoDB supported through the document client contract

## Auditing & optimistic locking

```dart
class User {
  @Version() int? version;             // incremented on every update
  @CreatedDate() DateTime? createdAt;  // stamped on insert
  @LastModifiedDate() DateTime? updatedAt; // stamped on every save
}
```

A concurrent update on a stale entity throws `OptimisticLockException`
(affected rows == 0 with a version predicate).

## Type conversion

`bool` ↔ `0/1`, `DateTime` ↔ ISO-8601 / epoch millis, `Enum` ↔ `String`
(round-trips through the materialized registry), `int` ↔ `double`. Custom
converters:

```dart
TypeConverterRegistry.instance.register(EncryptedStringConverter());
```

## Custom base repositories (spec §8.2)

```dart
final repo = RepositoryFactorySupport(
  client: client,
  dialect: dialect,
  baseImplementation: (metadata, client, dialect, converters) =>
      CompanyRepository(metadata, client, dialect),
).createSimple<User, int>();
```

## Entity requirements

- A **no-argument constructor** (rows are mapped via reflection)
- The entity class must be known to the reflection registry — run
  `jl build` (or `jl build --test` for tests), which is what the test suite
  here does
- `@Id` on exactly one field
- Relationship targets must be resolvable (`@OneToOne`/`@ManyToOne` chains
  for NESTED derived properties, to-one only)

## Testing

```bash
# generate the reflection registry (required for entity tests)
dart run jetleaf_tools build --test

dart test                  # everything
dart test test/smoke_test.dart
```

The suite fakes the driver (`test/support/fake_database_client.dart`) so no
database is needed; SQL generation is verified exactly, statement by statement.

## Known gaps (roadmap vs. shipped)

- **Live driver integrations** (postgres/mysql wire protocols, mongo_dart) —
  the driver abstraction is complete; concrete driver packages are a follow-up
  (`jetleaf_data_postgres`, …).
- **Compile-time AOT proxies** — dynamic proxy works for `dynamic` call
  sites; AOT proxies land with repository code generation in `jl build`.
- **Implicit joins for nested derived properties** work for to-one
  associations only (dot-notation for Mongo, `INNER JOIN` for SQL).
- **`@Query` with `Page`/`Slice` return** is not supported — derive a page
  from a list instead.
- **JQL** is intentionally "JQL-lite": entity names → tables, alias.property →
  alias."column", bare property names → quoted columns. No joins, no
  functions, no projections beyond column references.
- Auditing writes are per-row; no batch `INSERT` SQL assembly.

## See also

- `roadmap/jetleaf_data.md` — the canonical spec this implements
- `packages/jetleaf_data/test/` — 261 unit tests; `smoke_test.dart` is the fastest way to see the mapping layer in action
