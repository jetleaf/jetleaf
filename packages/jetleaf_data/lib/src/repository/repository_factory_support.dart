// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
//
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'package:jetleaf_core/lang.dart';

import '../dialect/database_dialect.dart';
import '../dialect/dialect_registry.dart';
import '../driver/connection_pool.dart';
import '../driver/database_client.dart';
import '../driver/pooled_connection.dart';
import '../driver/query_result.dart';
import '../exception/data_access_exception.dart';
import '../mapping/auditor_aware.dart';
import '../mapping/default_entity_metadata_registry.dart';
import '../mapping/default_type_converter_registry.dart';
import '../mapping/entity_metadata.dart';
import '../mapping/entity_metadata_registry.dart';
import '../mapping/type_converter_registry.dart';
import 'internal/repository_proxy_generator.dart';
import 'internal/simple_jetleaf_repository.dart';

/// {@template jetleaf_repository_factory_support}
/// Factory wiring repositories to their persistence infrastructure.
///
/// ### Responsibilities
/// - Resolve the [DatabaseDialect] (explicit, or from the [DialectRegistry]).
/// - Resolve the entity [EntityMetadata] via [EntityMetadataRegistry].
/// - Create [SimpleJetleafRepository] instances (optionally via a custom
///   base implementation — see [getBaseImplementation]).
/// - Create [DynamicRepositoryProxy] proxies for `dynamic` call sites and
///   intercepted repository execution.
///
/// ### Usage Example
/// ```dart
/// final factory = RepositoryFactorySupport(
///   client: myDatabaseClient,
///   dialect: const PostgreSqlDialect(),
/// );
///
/// final users = factory.createSimple<User, String>();
/// final proxy = factory.createDynamic<dynamic>(UserRepository);
/// ```
/// {@endtemplate}
final class RepositoryFactorySupport with EqualsAndHashCode {
  /// Reflective class descriptor for [RepositoryFactorySupport].
  static final Class<RepositoryFactorySupport> CLASS =
      Class<RepositoryFactorySupport>(null, PackageNames.DATA);

  final DatabaseClient? _client;
  final ConnectionPool? _pool;
  final DatabaseDialect _dialect;
  final SimpleJetleafRepository<dynamic, Object?> Function(
    EntityMetadata<dynamic> metadata,
    DatabaseClient client,
    DatabaseDialect dialect,
    TypeConverterRegistry converters,
  )? _baseImplementation;
  final EntityMetadataRegistry _metadataRegistry;
  final DialectRegistry _dialectRegistry;
  final TypeConverterRegistry _converterRegistry;
  final AuditorAware<dynamic>? _auditorAware;

  final Map<Type, SimpleJetleafRepository<dynamic, Object?>> _repositoryCache = {};

  /// Returns the default dialect when none is configured — SQLite, the embedded
  /// zero-configuration option.
  static DatabaseDialect getDefaultDialect() =>
      DefaultDialectRegistry.getSharedInstance().getDialect('sqlite');

  /// {@macro jetleaf_repository_factory_support}
  RepositoryFactorySupport({
    DatabaseClient? client,
    ConnectionPool? pool,
    DatabaseDialect? dialect,
    SimpleJetleafRepository<dynamic, Object?> Function(
      EntityMetadata<dynamic> metadata,
      DatabaseClient client,
      DatabaseDialect dialect,
      TypeConverterRegistry converters,
    )? baseImplementation,
    EntityMetadataRegistry? metadataRegistry,
    DialectRegistry? dialectRegistry,
    TypeConverterRegistry? converterRegistry,
    AuditorAware<dynamic>? auditorAware,
  })  : _client = client,
        _pool = pool,
        _dialect = dialect ?? getDefaultDialect(),
        _baseImplementation = baseImplementation,
        _metadataRegistry =
            metadataRegistry ?? DefaultEntityMetadataRegistry.getSharedInstance(),
        _dialectRegistry =
            dialectRegistry ?? DefaultDialectRegistry.getSharedInstance(),
        _converterRegistry =
            converterRegistry ?? DefaultTypeConverterRegistry.getSharedInstance(),
        _auditorAware = auditorAware {
    if ((_client == null) == (_pool == null)) {
      throw IllegalArgumentException(
        'Exactly one of RepositoryFactorySupport.client and .pool must be provided',
      );
    }
  }

  /// Returns the fixed [DatabaseClient], or `null` when configured with a pool.
  DatabaseClient? getClient() => _client;

  /// Returns the [ConnectionPool], or `null` when configured with a fixed client.
  ConnectionPool? getPool() => _pool;

  /// Returns the [DatabaseDialect] used to render SQL or document queries.
  DatabaseDialect getDialect() => _dialect;

  /// Returns the optional custom base repository constructor.
  SimpleJetleafRepository<dynamic, Object?> Function(
    EntityMetadata<dynamic> metadata,
    DatabaseClient client,
    DatabaseDialect dialect,
    TypeConverterRegistry converters,
  )? getBaseImplementation() => _baseImplementation;

  /// Returns the [EntityMetadataRegistry] consulted for entity mapping.
  EntityMetadataRegistry getMetadataRegistry() => _metadataRegistry;

  /// Returns the [DialectRegistry] consulted when resolving dialects by name.
  DialectRegistry getDialectRegistry() => _dialectRegistry;

  /// Returns the [TypeConverterRegistry] used for attribute ↔ column conversion.
  TypeConverterRegistry getTypeConverterRegistry() => _converterRegistry;

  /// Returns the optional [AuditorAware] provider for `@CreatedBy` / `@LastModifiedBy`.
  AuditorAware<dynamic>? getAuditorAware() => _auditorAware;

  /// Returns the effective [DatabaseClient] (wrapping the pool in a lazy-leasing
  /// client when configured with a [ConnectionPool]).
  DatabaseClient getEffectiveClient() {
    if (_client != null) {
      return _client;
    }

    return _PoolLeasingClient(_pool!);
  }

  /// Creates (or returns the cached) simple repository for entity [E] with
  /// identifier [I].
  SimpleJetleafRepository<E, I> createSimple<E, I>() {
    final cached = _repositoryCache[E];
    if (cached is SimpleJetleafRepository<E, I>) {
      return cached;
    }

    final metadata = _metadataRegistry.get<E>();
    final repository = _createBase<E, I>(
      metadata,
      getEffectiveClient(),
      _dialect,
      _converterRegistry,
    );
    _repositoryCache[E] = repository;
    return repository;
  }

  /// Creates a dynamic proxy for a `dynamic` repository call site of
  /// [repositoryContractType].
  R createDynamic<R>(Type repositoryContractType) {
    final entityType = _entityTypeOf(repositoryContractType);
    final metadata = _metadataRegistry.getForType(entityType);

    final proxy = DynamicRepositoryProxy(
      repositoryClass: Class.forName<dynamic>(repositoryContractType.toString()),
      metadata: metadata,
      client: getEffectiveClient(),
      dialect: _dialect,
      simple: _createBase<dynamic, Object?>(
        metadata,
        getEffectiveClient(),
        _dialect,
        _converterRegistry,
      ),
    );

    return proxy as R;
  }

  /// Convenience for creating (or retrieving from cache) a repository by raw
  /// [entityType].
  SimpleJetleafRepository<dynamic, Object?> createForType(Type entityType) {
    final cached = _repositoryCache[entityType];
    if (cached != null) {
      return cached;
    }

    final metadata = _metadataRegistry.getForType(entityType);
    final repo = _createBase<dynamic, Object?>(
      metadata,
      getEffectiveClient(),
      _dialect,
      _converterRegistry,
    );
    _repositoryCache[entityType] = repo;
    return repo;
  }

  SimpleJetleafRepository<E, I> _createBase<E, I>(
    EntityMetadata<E> metadata,
    DatabaseClient client,
    DatabaseDialect dialect,
    TypeConverterRegistry converters,
  ) {
    final custom = _baseImplementation;
    if (custom != null) {
      final repo = custom(metadata, client, dialect, converters);
      if (_auditorAware != null && repo.getAuditorAware() == null) {
        repo.setAuditorAware(_auditorAware);
      }
      return repo as SimpleJetleafRepository<E, I>;
    }

    return SimpleJetleafRepository<E, I>(
      metadata,
      client,
      dialect,
      converters: converters,
      auditorAware: _auditorAware,
    );
  }

  Type _entityTypeOf(Type repositoryContractType) {
    try {
      final contract = Class.forName<dynamic>(repositoryContractType.toString());
      for (final argument in contract.getAllInterfaceArguments()) {
        final type = argument.getType();
        if (type != Object && type != dynamic) {
          return type;
        }
      }

      for (final argument in contract.getSuperClassArguments()) {
        final type = argument.getType();
        if (type != Object && type != dynamic) {
          return type;
        }
      }
    } catch (_) {
      // Not materialized or not generic — handled below.
    }

    throw EntityMappingException(
      'Cannot infer the entity type of $repositoryContractType — '
      'pass it explicitly via createSimple<Entity, Id>() instead',
    );
  }

  /// Drops all cached repositories.
  void clear() => _repositoryCache.clear();

  @override
  List<Object?> equalizedProperties() => [_client, _pool, _dialect, runtimeType];
}

/// {@template jetleaf_pool_leasing_client}
/// A [DatabaseClient] facade leasing one connection per operation from a
/// [ConnectionPool]. Used when repositories are configured with a pool rather
/// than a fixed client.
/// {@endtemplate}
final class _PoolLeasingClient extends DatabaseClient {
  final ConnectionPool _pool;

  _PoolLeasingClient(this._pool);

  Future<T> _withLease<T>(
    Future<T> Function(PooledConnection lease) body,
  ) async {
    final lease = await _pool.getConnection();
    try {
      return await body(lease);
    } finally {
      await lease.close();
    }
  }

  @override
  bool supportsDocuments() => true;

  @override
  bool supportsSql() => true;

  @override
  Future<QueryResult> query(
    String sql, {
    List<Object?> parameters = const [],
  }) =>
      _withLease((lease) => lease.query(sql, parameters: parameters));

  @override
  Future<int> execute(
    String sql, {
    List<Object?> parameters = const [],
  }) =>
      _withLease((lease) => lease.execute(sql, parameters: parameters));

  @override
  Future<void> beginTransaction() async {}

  @override
  Future<void> commitTransaction() async {}

  @override
  Future<void> rollbackTransaction() async {}

  @override
  Future<void> setReadOnly(bool readOnly) async {}

  @override
  Future<Map<String, Object?>> insertDocument(
    String collection,
    Map<String, Object?> document,
  ) =>
      _withLease((lease) => lease.insertDocument(collection, document));

  @override
  Future<int> updateDocuments(
    String collection,
    Map<String, Object?> filter,
    Map<String, Object?> update,
  ) =>
      _withLease((lease) => lease.updateDocuments(collection, filter, update));

  @override
  Future<int> deleteDocuments(
    String collection,
    Map<String, Object?> filter,
  ) =>
      _withLease((lease) => lease.deleteDocuments(collection, filter));

  @override
  Future<List<Map<String, Object?>>> findDocuments(
    String collection,
    Map<String, Object?> filter, {
    Map<String, Object?>? sort,
    int? limit,
    int? skip,
  }) =>
      _withLease(
        (lease) => lease.findDocuments(
          collection,
          filter,
          sort: sort,
          limit: limit,
          skip: skip,
        ),
      );

  @override
  Future<int> countDocuments(
    String collection,
    Map<String, Object?> filter,
  ) =>
      _withLease((lease) => lease.countDocuments(collection, filter));

  @override
  Future<int?> lastInsertId() => _withLease((lease) => lease.lastInsertId());
}
