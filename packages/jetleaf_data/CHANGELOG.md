# Changelog

## 2.2.0 — 2026-11-18

**Full implementation of `roadmap/jetleaf_data.md`** — the persistence layer is
now feature-complete (263 unit tests passing).

### Refactored

- **Enterprise JetLeaf API alignment**: Replaced Dart property getters/setters with explicit method-style APIs (e.g. `getMaxConnections()`, `getActiveCount()`, `getIdleCount()`), separated abstract and configurable classes into dedicated files, and added full `{@template}` / `{@macro}` Dartdoc documentation.
- **Annotation naming**: Renamed `@Version` to `@DataVersion` in `auditing.dart` to avoid collision with `Version` in `jetleaf_core`.
- **Removed `annotation_reader.dart` workaround**: Now relies directly on `jetleaf_core`'s reified generic type resolution (`TypeReifier`).

### New

- **Entity mapping** — `@Entity`, `@Table`, `@Id`, `@GeneratedValue`
  (`autoIncrement`/`identity`/`uuid`/`snowflake`), `@Column`
  (name/nullable/unique/length/precision/scale/columnDefinition/insertable/updatable),
  `@Transient`, `@Index`/`@Indexes`, `@OneToOne`, `@OneToMany`, `@ManyToOne`,
  `@ManyToMany` (cascade + fetch + join columns), `@CreatedDate`,
  `@LastModifiedDate`, `@Version` — all reflection-driven via `EntityMetadata`.
- **Query derivation** — `PartTree` parser: `findBy…`, `countBy…`, `existsBy…`,
  `deleteBy…` with `And`/`Or`, nested property paths (`profile.bio`), `OrderBy`,
  `Top`/`First<N>`, `Distinct`, `IgnoreCase`, operator aliases (`Is`, `IsNot`).
- **Dialects** — PostgreSQL (`$n`, `RETURNING`), MySQL/MariaDB (backticks,
  `AUTO_INCREMENT`, upsert suffix), SQLite (embedded), MongoDB (BSON filters,
  `$regex` escaping, `$and`/`$or` deep-merge) + `DialectRegistry` with URL
  inference and custom-dialect registration.
- **Schema migration** — `SqlMigration`/`MigrationRunner` with versioned
  migrations, checksums, drift detection and rollback; `SchemaGenerator` for
  DDL from entity metadata (`CREATE TABLE`, `CREATE INDEX`).
- **Transactions** — `@Transactional` AOP interceptor (Spring propagation and
  isolation semantics), `PlatformTransactionManager`/`DataSourceTransactionManager`,
  zone-bound ambient transactions with rollback-only propagation, read-only
  hints, `rollbackFor`/`noRollbackFor` (both Dart throwable roots, `Exception`
  and `Error`, roll back by default).
- **Repository runtime** — `JetleafRepository` interface,
  `SimpleJetleafRepository` (CRUD, batching, derived queries, auditing,
  optimistic locking), `RepositoryFactorySupport` (custom base hook),
  `DynamicRepositoryProxy` for `dynamic` call sites.
- **Driver abstraction** — `DatabaseClient`, `ConnectionFactory`,
  `ConnectionPool`, `DefaultConnectionPool` (bounded, validated, FIFO wake-up),
  `PooledConnection` (rolls back uncommitted transactions on lease return),
  `RowMapper`/`EntityRowMapper` (row → entity mapping).
- **`TypeConverterRegistry`** — `bool` ↔ `0/1`, `DateTime` ↔ ISO-8601/millis,
  `Enum` ↔ `String`, `int` ↔ `double`; extensible for encrypted/JSON attributes.
- **Exceptions** — `DataAccessException` hierarchy (`OptimisticLockException`,
  `EntityNotFoundException`, `DuplicateKeyException`, `MandatoryTransactionException`,
  `MigrationException`, `QueryDerivationException`, …).

### Existing scaffolding kept and hardened

- `Repository`/`CrudRepository`/`ListCrudRepository`/`PagingAndSortRepository`
  kept for backwards compatibility; the new hierarchy composes them.
- Fixed pre-existing defects found while building: `Sort.UNSORTED` infinite
  recursion, `AbstractPageRequest` asserting page numbers `> 0` (zero-based
  pages rejected), ambiguous `Repository` imports in package sources.
- `DataAutoConfiguration` registers the dialect registry and the transactional
  interceptor + manager binder (`TransactionManagerBinder` auto-binds an
  explicit `PlatformTransactionManager` pod or an implicit
  `DataSourceTransactionManager` from `ConnectionFactory`).

### Notes

- `jetleaf_data` does **not** depend on `jetleaf_security` — the modules are
  independent; security is not a prerequisite.
- `jl build` from `pub-cache` is stale for this workspace; use
  `dart run jetleaf_tools build --test` to generate the reflection registry.