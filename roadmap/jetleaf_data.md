# `jetleaf_data`: Architectural Specification & Implementation Roadmap

> **Enterprise Data Access & Object-Relational/Document Mapping for Dart**  
> Status: Canonical Production Specification  
> Package: `packages/jetleaf_data`  
> Author: Evaristus Adimonyemma & Jetleaf Architecture Team  
> Architectural Benchmark: Spring Data (Commons / JPA / MongoDB / Redis)

---

## 1. Executive Summary & Core Philosophy

### 1.1 The Objective
`jetleaf_data` is the canonical persistence abstraction framework for the Jetleaf ecosystem. It provides Dart developers with an enterprise-grade data layer equivalent to **Spring Data**:
- **Declarative Repositories**: Data access without writing SQL or boilerplate queries.
- **Dynamic Query Method Derivation**: Methods such as `findByEmail(String email)` or `findByAgeGreaterThanEqualAndActiveTrue(int age)` are automatically parsed and translated into optimized queries.
- **Dialect Agnostic**: Seamlessly operates across **Relational SQL** (PostgreSQL, MySQL, SQLite, Oracle, CockroachDB) and **NoSQL/Document** databases (MongoDB, Redis, DynamoDB).
- **Declarative Transactions**: `@Transactional` method interception with full propagation and isolation semantics.
- **Enterprise Extensibility**: Built with strict Inversion of Control (IoC), allowing users to override dialects, type converters, connection pools, and repository base classes without modifying core framework code.

### 1.2 Separation of Concerns & DRY Principles
```
┌────────────────────────────────────────────────────────────────────────┐
│                        APPLICATION DOMAIN LAYER                        │
│                   Entities, DTOs, Business Services                    │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                     DECLARATIVE REPOSITORY API                         │
│         Repository<T, ID>, CrudRepository<T, ID>, Query Methods        │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                      QUERY ENGINE & AST PARSER                         │
│            Method Derivation, PartTree, Expression Evaluator           │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        DIALECT & MAPPING LAYER                         │
│   SQL Dialects (Postgres/MySQL/SQLite)  │ NoSQL Dialects (Mongo/Redis) │
│   Entity Metadata & Type Mappings      │ Schema Generators & DDL       │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                     DRIVER & CONNECTION POOL LAYER                     │
│      ConnectionFactory, ConnectionPool, PlatformTransactionManager     │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Package File Structure (`packages/jetleaf_data`)

```text
packages/jetleaf_data/
├── pubspec.yaml
├── README.md
├── CHANGELOG.md
├── lib/
│   ├── jetleaf_data.dart                 # Unified root export
│   └── src/
│       ├── annotation/                   # Domain & query annotations
│       │   ├── entity.dart
│       │   ├── table.dart
│       │   ├── id.dart
│       │   ├── generated_value.dart
│       │   ├── column.dart
│       │   ├── transient.dart
│       │   ├── index.dart
│       │   ├── relationships.dart        # @OneToOne, @OneToMany, @ManyToOne, @ManyToMany
│       │   ├── auditing.dart             # @CreatedDate, @LastModifiedDate, @Version
│       │   ├── query.dart                # @Query, @Param, @Modifying
│       │   └── transactional.dart        # @Transactional
│       ├── repository/                   # Repository contracts & runtime proxies
│       │   ├── repository.dart
│       │   ├── crud_repository.dart
│       │   ├── paging_and_sorting_repository.dart
│       │   ├── jetleaf_repository.dart
│       │   ├── repository_factory_support.dart
│       │   └── internal/
│       │       ├── repository_proxy_generator.dart
│       │       └── simple_jetleaf_repository.dart
│       ├── query/                        # Query derivation engine
│       │   ├── query_method.dart
│       │   ├── part_tree.dart            # Method name grammar parser
│       │   ├── part.dart
│       │   ├── query_criteria.dart
│       │   ├── parameter_binder.dart
│       │   ├── sort.dart
│       │   ├── pageable.dart
│       │   ├── page.dart
│       │   └── slice.dart
│       ├── dialect/                      # Database dialect abstraction
│       │   ├── database_dialect.dart
│       │   ├── sql_dialect.dart
│       │   ├── document_dialect.dart
│       │   ├── dialect_registry.dart
│       │   ├── postgres/
│       │   │   ├── postgres_dialect.dart
│       │   │   └── postgres_type_mapper.dart
│       │   ├── mysql/
│       │   │   ├── mysql_dialect.dart
│       │   │   └── mysql_type_mapper.dart
│       │   ├── sqlite/
│       │   │   ├── sqlite_dialect.dart
│       │   │   └── sqlite_type_mapper.dart
│       │   └── mongo/
│       │       ├── mongo_dialect.dart
│       │       └── mongo_type_mapper.dart
│       ├── mapping/                      # Entity reflection & metadata mapping
│       │   ├── entity_metadata.dart
│       │   ├── entity_metadata_builder.dart
│       │   ├── column_metadata.dart
│       │   ├── relationship_metadata.dart
│       │   └── type_converter.dart
│       ├── driver/                       # Driver abstraction & connection pooling
│       │   ├── connection_factory.dart
│       │   ├── connection_pool.dart
│       │   ├── pooled_connection.dart
│       │   ├── database_client.dart
│       │   ├── row_mapper.dart
│       │   └── query_result.dart
│       ├── transaction/                  # Declarative transaction management
│       │   ├── platform_transaction_manager.dart
│       │   ├── transaction_definition.dart
│       │   ├── transaction_status.dart
│       │   ├── default_transaction_definition.dart
│       │   ├── transaction_interceptor.dart
│       │   └── zone_transaction_holder.dart
│       └── migration/                    # Automatic schema migrations
│           ├── schema_generator.dart
│           ├── migration_runner.dart
│           └── migration_version.dart
└── test/
    ├── query/
    │   └── part_tree_test.dart
    ├── dialect/
    │   ├── postgres_dialect_test.dart
    │   └── sqlite_dialect_test.dart
    ├── repository/
    │   └── crud_repository_test.dart
    └── transaction/
        └── transactional_test.dart
```

---

## 3. Domain Entity Modeling Specification

### 3.1 Annotations Definition

```dart
@Target({TargetKind.classType})
final class Entity extends ReflectableAnnotation {
  final String? tableName;
  const Entity({this.tableName});
}

@Target({TargetKind.field})
final class Id extends ReflectableAnnotation {
  const Id();
}

@Target({TargetKind.field})
final class GeneratedValue extends ReflectableAnnotation {
  final GenerationStrategy strategy;
  const GeneratedValue({this.strategy = GenerationStrategy.autoIncrement});
}

enum GenerationStrategy {
  autoIncrement,
  uuid,
  identity,
  snowflake,
}

@Target({TargetKind.field})
final class Column extends ReflectableAnnotation {
  final String? name;
  final bool nullable;
  final bool unique;
  final int? length;
  final String? columnDefinition; // Custom DDL override
  const Column({
    this.name,
    this.nullable = true,
    this.unique = false,
    this.length,
    this.columnDefinition,
  });
}
```

### 3.2 Relational Mapping & Auditing Annotations
- **Relationships**: `@OneToOne`, `@OneToMany`, `@ManyToOne`, `@ManyToMany` with cascade operations (`CascadeType.all`, `CascadeType.persist`, `CascadeType.remove`) and fetch strategies (`FetchType.lazy`, `FetchType.eager`).
- **Auditing**:
  - `@CreatedDate`: Automatically populated with creation timestamp.
  - `@LastModifiedDate`: Automatically updated on entity modification.
  - `@Version`: Optimistic locking integer tracking to prevent concurrent write collisions.

---

## 4. Repository Abstraction Hierarchy

```dart
/// Root marker interface for all Jetleaf repositories.
abstract interface class Repository<T, ID> {}

/// Generic CRUD operations.
abstract interface class CrudRepository<T, ID> implements Repository<T, ID> {
  Future<T> save(T entity);
  Future<List<T>> saveAll(Iterable<T> entities);
  Future<T?> findById(ID id);
  Future<bool> existsById(ID id);
  Future<List<T>> findAll();
  Future<List<T>> findAllById(Iterable<ID> ids);
  Future<int> count();
  Future<void> deleteById(ID id);
  Future<void> delete(T entity);
  Future<void> deleteAll(Iterable<T> entities);
}

/// Pagination and sorting extensions.
abstract interface class PagingAndSortingRepository<T, ID> 
    implements CrudRepository<T, ID> {
  Future<List<T>> findAllSorted(Sort sort);
  Future<Page<T>> findAllPaged(Pageable pageable);
}

/// Spring Data JPA equivalent providing batching and synchronization.
abstract interface class JetleafRepository<T, ID> 
    implements PagingAndSortingRepository<T, ID> {
  Future<void> flush();
  Future<T> saveAndFlush(T entity);
  Future<List<T>> saveAllAndFlush(Iterable<T> entities);
  Future<void> deleteAllInBatch(Iterable<T> entities);
}
```

---

## 5. Dynamic Query Derivation Engine (`PartTree`)

The query derivation engine parses method names at compile-time (via `jetleaf_tools` AST scanner) or dynamic proxy invocation, translating method signatures into a strongly-typed AST:

### 5.1 Grammar & Keywords
```
Prefixes:     findBy... | readBy... | queryBy... | countBy... | existsBy... | deleteBy...
Operators:    And, Or
Conditions:   Equals, IsNot, Like, StartingWith, EndingWith, Containing, 
              GreaterThan, GreaterThanEqual, LessThan, LessThanEqual, 
              Before, After, Between, In, NotIn, True, False, IsNull, IsNotNull
Sorting:      ...OrderBy[Property][Asc|Desc]
```

### 5.2 Method Derivation Examples
```dart
abstract interface class UserRepository extends JetleafRepository<User, String> {
  // Derives: SELECT * FROM users WHERE email = ? LIMIT 1
  Future<User?> findByEmail(String email);

  // Derives: SELECT * FROM users WHERE age >= ? AND is_active = true
  Future<List<User>> findByAgeGreaterThanEqualAndActiveTrue(int age);

  // Derives: SELECT * FROM users WHERE first_name LIKE ? ORDER BY created_at DESC
  Future<List<User>> findByFirstNameStartingWithOrderByCreatedAtDesc(String prefix);

  // Derives: SELECT COUNT(*) FROM users WHERE status IN (?)
  Future<int> countByStatusIn(List<String> statuses);

  // Derives: DELETE FROM users WHERE last_login < ?
  Future<int> deleteByLastLoginBefore(DateTime threshold);

  // Custom native or HQL/JQL query with named parameters
  @Query("SELECT u FROM User u WHERE u.role = :role AND u.creditScore > :score")
  Future<List<User>> findEligibleUsers(
    @Param("role") String role, 
    @Param("score") double score,
  );
}
```

---

## 6. Multi-Dialect Architecture (SQL & NoSQL)

### 6.1 The Dialect Abstraction
Every database engine implements the unified `DatabaseDialect` contract:

```dart
abstract interface class DatabaseDialect {
  String get name;
  bool get isRelational;

  String buildSelectQuery(QueryCriteria criteria);
  String buildInsertQuery(EntityMetadata metadata);
  String buildUpdateQuery(EntityMetadata metadata);
  String buildDeleteQuery(EntityMetadata metadata);
  String buildCreateTableQuery(EntityMetadata metadata);

  SqlTypeMapper get typeMapper;
}
```

### 6.2 Relational Dialects
- **`PostgreSqlDialect`**: Generates parameterized queries using `$1, $2, ...`, supports `RETURNING *`, JSONB operators, and UUID types.
- **`MySqlDialect`**: Generates parameterized queries using `?`, supports backtick escaping, `AUTO_INCREMENT`, and `ON DUPLICATE KEY UPDATE`.
- **`SqliteDialect`**: Optimized for embedded usage, in-memory testing, and mobile Flutter clients.

### 6.3 Document & Key-Value Dialects
- **`MongoDialect`**: Translates criteria into MongoDB BSON filter documents:
  ```json
  { "age": { "$gte": 21 }, "active": true }
  ```
- **`RedisDialect`**: Maps entities to Redis Hashes with secondary indices for indexed properties.

---

## 7. Declarative Transaction Management (`@Transactional`)

### 7.1 Architecture & Propagation
`jetleaf_data` provides AOP-based transaction interceptors:

```dart
@Target({TargetKind.method, TargetKind.classType})
final class Transactional extends ReflectableAnnotation {
  final Propagation propagation;
  final Isolation isolation;
  final int timeoutSeconds;
  final bool readOnly;
  final List<Type> rollbackFor;
  final List<Type> noRollbackFor;

  const Transactional({
    this.propagation = Propagation.required,
    this.isolation = Isolation.readCommitted,
    this.timeoutSeconds = 30,
    this.readOnly = false,
    this.rollbackFor = const [Exception],
    this.noRollbackFor = const [],
  });
}

enum Propagation {
  required,
  requiresNew,
  mandatory,
  supports,
  notSupported,
  never,
}

enum Isolation {
  readUncommitted,
  readCommitted,
  repeatableRead,
  serializable,
}
```

### 7.2 Isolate Zone Binding
Dart isolates do not share global thread-local state. Jetleaf binds active database connections and transactions to Dart's **`Zone`**:

```dart
final connection = Zone.current[#_currentJetleafTransaction] as PooledConnection?;
```
When a `@Transactional` method is entered:
1. `PlatformTransactionManager` checks the active zone connection.
2. Applies propagation rules (e.g. `requiresNew` suspends the outer transaction and creates a new zone).
3. If an unhandled exception matches `rollbackFor`, invokes `connection.rollback()`.
4. If execution succeeds, invokes `connection.commit()`.

---

## 8. Extensibility: Overriding Built-In Implementations

### 8.1 Custom Dialect Override
Users can implement custom database support without forking Jetleaf:

```dart
@Configuration()
final class CustomDatabaseConfig {
  @Pod()
  DatabaseDialect customDialect() {
    return CockroachDbDialect(); // Custom user-defined dialect
  }

  @Pod()
  ConnectionPool customPool() {
    return CustomEnterprisePool(maxConnections: 100);
  }
}
```

### 8.2 Custom Repository Base Implementation
Users can add company-wide helper methods to all repositories:

```dart
abstract interface class BaseCompanyRepository<T, ID> implements JetleafRepository<T, ID> {
  Future<void> softDelete(ID id);
}

final class BaseCompanyRepositoryImpl<T, ID> extends SimpleJetleafRepository<T, ID> 
    implements BaseCompanyRepository<T, ID> {
  BaseCompanyRepositoryImpl(super.metadata, super.client);

  @override
  Future<void> softDelete(ID id) async {
    await client.execute(
      "UPDATE ${metadata.tableName} SET is_deleted = true WHERE id = ?",
      [id],
    );
  }
}
```

---

## 9. Verification & Testing Strategy

1. **PartTree Parser Tests**: 50+ unit tests verifying method name tokenization, precedence of `And`/`Or`, and operator derivation.
2. **Dialect Generation Tests**: Validate exact SQL string generation against PostgreSQL, MySQL, and SQLite dialect specifications.
3. **Transaction Rollback Integration Tests**: Verify rollback on checked exceptions and successful commit on clean exit.
4. **Multi-Driver Test Harness**: Run automated integration tests against real Dockerized PostgreSQL and MongoDB containers using Testcontainers.
