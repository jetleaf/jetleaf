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

import 'dart:math';

import 'package:jetleaf_core/lang.dart';

import '../../annotation/id.dart';
import '../../dialect/database_dialect.dart';
import '../../dialect/document_dialect.dart';
import '../../dialect/sql_dialect.dart';
import '../../driver/database_client.dart';
import '../../driver/entity_row_mapper.dart';
import '../../exception/data_access_exception.dart';
import '../../mapping/auditor_aware.dart';
import '../../mapping/column_metadata.dart';
import '../../mapping/default_type_converter_registry.dart';
import '../../mapping/entity_metadata.dart';
import '../../mapping/type_converter_registry.dart';
import '../../paging/page.dart';
import '../../paging/pageable.dart';
import '../../paging/simple_page.dart';
import '../../paging/sort.dart';
import '../../query/part.dart';
import '../../query/part_tree.dart';
import '../../query/query_criteria.dart';
import '../../transaction/zone_transaction_holder.dart';
import '../jetleaf_repository.dart';

/// {@template jetleaf_simple_jetleaf_repository}
/// The default, fully-functional repository implementation extending
/// [JetleafRepository].
///
/// [SimpleJetleafRepository] is both a **ready-to-use implementation** and
/// the **extensibility seam**: applications subclass it to add company-wide
/// helpers (see `RepositoryFactorySupport` for plugging a custom base
/// implementation into repositories).
///
/// ### Execution Model
/// - When called inside a `@Transactional` boundary, all statements execute
///   on the ambient transaction's connection (zone-bound via
///   [ZoneTransactionHolder]).
/// - Otherwise each operation uses the [DatabaseClient] passed at construction.
///
/// ### Auditing & Optimistic Locking
/// - `@CreatedDate` and `@LastModifiedDate` fields are stamped automatically.
/// - `@CreatedBy` and `@LastModifiedBy` fields are populated via [AuditorAware]
///   when configured.
/// - `@DataVersion` fields are incremented on every update; the version
///   predicate guards concurrent writes ([OptimisticLockException] on mismatch).
/// {@endtemplate}
@Generic(SimpleJetleafRepository)
class SimpleJetleafRepository<T, ID> extends JetleafRepository<T, ID> {
  /// Reflective class descriptor for [SimpleJetleafRepository].
  static final Class<SimpleJetleafRepository> CLASS = Class<SimpleJetleafRepository>(null, PackageNames.DATA);

  final EntityMetadata<T> _metadata;
  final DatabaseClient _client;
  final DatabaseDialect _dialect;
  final TypeConverterRegistry _converters;
  final EntityRowMapper<T> _rowMapper;
  AuditorAware<dynamic>? _auditorAware;

  /// {@macro jetleaf_simple_jetleaf_repository}
  SimpleJetleafRepository(
    EntityMetadata<T> metadata,
    DatabaseClient client,
    DatabaseDialect dialect, {
    TypeConverterRegistry? converters,
    AuditorAware<dynamic>? auditorAware,
  })  : _metadata = metadata,
        _client = client,
        _dialect = dialect,
        _converters = converters ?? DefaultTypeConverterRegistry.getSharedInstance(),
        _auditorAware = auditorAware,
        _rowMapper = EntityRowMapper<T>(
          metadata,
          converters ?? DefaultTypeConverterRegistry.getSharedInstance(),
        );

  /// Returns the [EntityMetadata] managed by this repository.
  EntityMetadata<T> getMetadata() => _metadata;

  /// Returns the fallback [DatabaseClient] used when no ambient transaction is bound.
  DatabaseClient getClient() => _client;

  /// Returns the [DatabaseDialect] producing SQL or document queries.
  DatabaseDialect getDialect() => _dialect;

  /// Returns the [TypeConverterRegistry] used for attribute ↔ column conversion.
  TypeConverterRegistry getConverters() => _converters;

  /// Returns the optional [AuditorAware] provider for `@CreatedBy` / `@LastModifiedBy`.
  AuditorAware<dynamic>? getAuditorAware() => _auditorAware;

  /// Configures the [AuditorAware] provider for `@CreatedBy` / `@LastModifiedBy`.
  void setAuditorAware(AuditorAware<dynamic>? auditorAware) {
    _auditorAware = auditorAware;
  }

  /// Returns the active [DatabaseClient] — ambient transaction connection if bound,
  /// otherwise the configured fallback client.
  DatabaseClient getActiveClient() => ZoneTransactionHolder.getCurrent()?.getConnection() ?? _client;

  // =========================================================================
  // CRUD
  // =========================================================================

  /// Reads the identifier of [entity].
  ID? readId(T entity) {
    final idColumn = _metadata.getIdColumn();
    if (idColumn == null) {
      return null;
    }

    final value = _metadata.readAttribute(entity, idColumn.getProperty());
    return value as ID?;
  }

  /// Reads the optimistic-lock version of [entity] (or `null` when unmapped).
  int? readVersion(T entity) {
    final version = _metadata.getVersionColumn();
    if (version == null) {
      return null;
    }

    final value = _metadata.readAttribute(entity, version.getProperty());
    return value as int?;
  }

  @override
  Future<S> save<S extends T>(S entity) async {
    final id = readId(entity);
    await _stampAuditing(entity, isNew: id == null);

    if (id == null) {
      return (await _insert(entity)) as S;
    }

    return (await _update(entity, id)) as S;
  }

  @override
  Future<List<S>> saveAll<S extends T>(Iterable<S> entities) async {
    final saved = <S>[];
    for (final entity in entities) {
      saved.add(await save<S>(entity));
    }

    return saved;
  }

  @override
  Future<void> flush() async {}

  @override
  Future<S> saveAndFlush<S extends T>(S entity) async {
    final saved = await save<S>(entity);
    await flush();
    return saved;
  }

  @override
  Future<List<S>> saveAllAndFlush<S extends T>(Iterable<S> entities) async {
    final saved = await saveAll<S>(entities);
    await flush();
    return saved;
  }

  Future<T> _insert(T entity) async {
    final idColumn = _metadata.getIdColumn();

    if (idColumn != null &&
        idColumn.isGenerated() &&
        !idColumn.isDatabaseGenerated()) {
      final generated = idColumn.getGenerationStrategy() == GenerationStrategy.uuid
          ? _uuid()
          : _snowflake();
      _metadata.writeAttribute(
        entity,
        idColumn.getProperty(),
        _convertIdValue(generated, idColumn.getFieldType()),
      );
    }

    final columns = _metadata.getInsertColumns();
    final values = columns
        .map(
          (column) => _converters.toColumn(
            _metadata.readAttribute(entity, column.getProperty()),
            column.getFieldType(),
          ),
        )
        .toList();
    final valuesMap = _valuesMap(columns, values);

    if (_dialect is DocumentDialect) {
      final inserted = await getActiveClient().insertDocument(
        _metadata.getTableName(),
        _dialect.buildInsertDocument(_metadata, valuesMap),
      );
      _hydrateGeneratedId(entity, inserted);
      return entity;
    }

    final sql = _dialect.buildInsertQuery(_metadata);
    final sqlDialect = _dialect is SqlDialect ? _dialect : null;
    if (sqlDialect != null && sqlDialect.supportsReturning()) {
      final result = await getActiveClient().query(sql, parameters: values);
      if (idColumn != null && result.getRows().isNotEmpty) {
        _hydrateGeneratedId(entity, result.getRows().first);
      }

      return entity;
    }

    await getActiveClient().execute(sql, parameters: values);
    final generated = await getActiveClient().lastInsertId();
    if (idColumn != null && idColumn.isDatabaseGenerated() && generated != null) {
      _metadata.writeAttribute(
        entity,
        idColumn.getProperty(),
        _convertIdValue(generated, idColumn.getFieldType()),
      );
    }

    return entity;
  }

  Future<T> _update(T entity, ID id) async {
    final version = _metadata.getVersionColumn();
    final previousVersion = version != null ? readVersion(entity) : null;

    if (version != null) {
      _metadata.writeAttribute(
        entity,
        version.getProperty(),
        (previousVersion ?? 0) + 1,
      );
    }

    final lastModified = _metadata.getLastModifiedDateColumn();
    if (lastModified != null) {
      _metadata.writeAttribute(entity, lastModified.getProperty(), DateTime.now());
    }

    final columns = _metadata.getUpdateColumns();
    final values = columns
        .map(
          (column) => _converters.toColumn(
            _metadata.readAttribute(entity, column.getProperty()),
            column.getFieldType(),
          ),
        )
        .toList();

    if (_dialect is DocumentDialect) {
      final document = Map<String, Object?>.from(_valuesMap(columns, values));
      final filter = _dialect.buildIdFilter(
        _metadata,
        _columnValue(id, getIdColumnFieldType()),
        previousVersion,
      );
      final affected = await getActiveClient().updateDocuments(
        _metadata.getTableName(),
        filter,
        {'\$set': document},
      );
      if (affected == 0) {
        throw _optimisticLockFailure(id);
      }

      return entity;
    }

    final parameters = <Object?>[
      ...values,
      _converters.toColumn(id, getIdColumnFieldType()),
    ];
    if (version != null) {
      parameters.add(previousVersion);
    }

    final affected = await getActiveClient().execute(
      _dialect.buildUpdateQuery(_metadata),
      parameters: parameters,
    );
    if (affected == 0 && version != null) {
      throw _optimisticLockFailure(id);
    }

    return entity;
  }

  OptimisticLockException _optimisticLockFailure(Object? id) =>
      OptimisticLockException(
        '${_metadata.getSimpleName()}#$id could not be updated — the row was modified concurrently (or no longer exists)',
      );

  @override
  Future<T?> findById(ID id) async {
    final idProperty = _metadata.getIdColumn()?.getProperty();
    if (idProperty == null) {
      throw EntityMappingException(
        '${_metadata.getSimpleName()} has no @Id column',
        entityType: T,
      );
    }

    final criteria = QueryCriteria.select(
      metadata: _metadata,
      predicate: PartCriterion(
        Part(property: idProperty, operator_: PartOperator.equals),
      ),
      values: [_converters.toColumn(id, getIdColumnFieldType())],
      limit: 1,
    );

    final rows = await _fetchRows(criteria);
    if (rows.isEmpty) {
      return null;
    }

    return rows.first;
  }

  @override
  Future<T?> findByProperty(
    String property, [
    bool ignoreCase = false,
    Object? value,
  ]) async {
    final column = _metadata.getColumnByProperty(property);
    if (column == null) {
      return null;
    }

    final criteria = QueryCriteria.select(
      metadata: _metadata,
      predicate: PartCriterion(
        Part(
          property: property,
          operator_: value == null ? PartOperator.isNotNull : PartOperator.equals,
          ignoreCase: ignoreCase,
        ),
      ),
      values: value == null
          ? const []
          : [_converters.toColumn(value, column.getFieldType())],
      limit: 1,
    );

    final rows = await _fetchRows(criteria);
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Future<List<T>> findAll() async {
    final criteria = QueryCriteria.select(metadata: _metadata);
    return _fetchRows(criteria);
  }

  @override
  Future<List<T>> findAllById(Iterable<ID> ids) async {
    final idList = ids.toList(growable: false);
    if (idList.isEmpty) {
      return [];
    }

    final idProperty = _metadata.getIdColumn()?.getProperty();
    if (idProperty == null) {
      return [];
    }

    final criteria = QueryCriteria.select(
      metadata: _metadata,
      predicate: PartCriterion(
        Part(property: idProperty, operator_: PartOperator.in_),
      ),
      values: [
        idList
            .map((id) => _converters.toColumn(id, getIdColumnFieldType()))
            .toList(growable: false),
      ],
    );

    return _fetchRows(criteria);
  }

  @override
  Future<int> getCount() async => count();

  @override
  Future<int> count() async =>
      countByCriteria(QueryCriteria.count(metadata: _metadata));

  @override
  Future<bool> existsById(ID id) async {
    final found = await findById(id);
    return found != null;
  }

  @override
  Future<List<T>> findAllSorted(Sort sort) async {
    final criteria = QueryCriteria.select(metadata: _metadata, sort: sort);
    return _fetchRows(criteria);
  }

  @override
  Future<Page<T>> findPage(Pageable pageable) async {
    final contentCriteria = QueryCriteria.select(
      metadata: _metadata,
      sort: pageable.getSort(),
      limit: pageable.isPaged() ? pageable.getPageSize() : null,
      offset: pageable.isPaged() ? pageable.getOffset() : null,
    );

    final countCriteria = QueryCriteria.count(metadata: _metadata);

    final rows = await _fetchRows(contentCriteria);
    final total = await countByCriteria(countCriteria);

    return SimplePage<T>(rows, pageable, total);
  }

  @override
  Future<void> deleteById(ID id) async {
    final entity = await findById(id);
    if (entity == null) {
      return;
    }

    await delete(entity);
  }

  @override
  Future<void> delete(T entity) async {
    final id = readId(entity);
    if (id == null) {
      throw EntityMappingException(
        'Cannot delete ${_metadata.getSimpleName()} without an identifier',
        entityType: T,
      );
    }

    final version = _metadata.getVersionColumn();
    final rawVersion =
        version != null ? _metadata.readAttribute(entity, version.getProperty()) : null;

    if (_dialect is DocumentDialect) {
      final filter = _dialect.buildIdFilter(
        _metadata,
        _converters.toColumn(id, getIdColumnFieldType()),
        rawVersion,
      );
      final affected = await getActiveClient().deleteDocuments(
        _metadata.getTableName(),
        filter,
      );
      if (affected == 0 && rawVersion != null) {
        throw _optimisticLockFailure(id);
      }

      return;
    }

    final parameters = <Object?>[_converters.toColumn(id, getIdColumnFieldType())];
    if (version != null) {
      parameters.add(rawVersion);
    }

    final affected = await getActiveClient().execute(
      _dialect.buildDeleteQuery(_metadata),
      parameters: parameters,
    );
    if (affected == 0 && rawVersion != null) {
      throw _optimisticLockFailure(id);
    }
  }

  @override
  Future<void> deleteAllById(Iterable<ID> ids) async {
    final idList = ids.toList(growable: false);
    if (idList.isEmpty) {
      return;
    }
    await _deleteAllByIds(idList);
  }

  @override
  Future<void> deleteAllByEntities(Iterable<T> entities) async {
    for (final entity in entities) {
      await delete(entity);
    }
  }

  @override
  Future<void> deleteAll([Iterable<T>? entities]) async {
    if (entities != null) {
      await deleteAllByEntities(entities);
      return;
    }
    await deleteAllRecords();
  }

  @override
  Future<void> deleteAllInBatch(Iterable<T> entities) async {
    final ids = entities.map(readId).whereType<ID>().toList(growable: false);
    if (ids.isEmpty) {
      return;
    }

    await _deleteAllByIds(ids);
  }

  /// Deletes every row in the table.
  Future<void> deleteAllRecords() async {
    if (_dialect is DocumentDialect) {
      await getActiveClient().deleteDocuments(_metadata.getTableName(), {});
      return;
    }

    await getActiveClient().execute(
      'DELETE FROM ${(_dialect as SqlDialect).qualifiedTable(_metadata)}',
    );
  }

  Future<void> _deleteAllByIds(List<ID> ids) async {
    if (_dialect is DocumentDialect) {
      final filter = {
        _metadata.getIdColumn()!.getName(): {
          '\$in': ids
              .map((id) => _converters.toColumn(id, getIdColumnFieldType()))
              .toList(),
        },
      };
      await getActiveClient().deleteDocuments(_metadata.getTableName(), filter);
      return;
    }

    final idColumn = _metadata.getIdColumn()!;
    final sqlDialect = _dialect as SqlDialect;
    final qualified = sqlDialect.qualifiedTable(_metadata);
    final idRef = sqlDialect.escapeIdentifier(idColumn.getName());
    final parameters =
        ids.map((id) => _converters.toColumn(id, getIdColumnFieldType())).toList();

    var statement =
        'DELETE FROM $qualified WHERE $idRef IN (${ids.map((_) => '?').join(', ')})';
    if (sqlDialect.getParameterStyle() == SqlParameterStyle.dollarNumbered) {
      var index = 0;
      statement =
          statement.replaceAllMapped(RegExp(r'\?'), (_) => '\$${++index}');
    }

    await getActiveClient().execute(statement, parameters: parameters);
  }

  // =========================================================================
  // Derived-query execution (shared with DynamicRepositoryProxy)
  // =========================================================================

  /// Executes a derived [tree] with ordered [values] and maps rows to entities.
  Future<List<T>> executeQueryList(
    PartTree tree,
    List<Object?> values, {
    Sort? sort,
    Pageable? pageable,
  }) async {
    final criteria = _buildCriteria(QueryType.select, tree, values, sort, pageable);
    return _fetchRows(criteria);
  }

  /// Executes a derived [tree] expecting at most one row.
  Future<T?> executeQueryOne(PartTree tree, List<Object?> values) async {
    final criteria = _buildCriteria(QueryType.select, tree, values, null, null)
        .copyWith(limit: 2);
    final rows = await _fetchRows(criteria);

    if (rows.length > 1) {
      throw IncorrectResultSizeDataAccessException(
        'Expected at most one ${_metadata.getSimpleName()}, got ${rows.length}',
        1,
        rows.length,
      );
    }

    return rows.isEmpty ? null : rows.first;
  }

  /// Executes a derived count [tree].
  Future<int> executeQueryCount(PartTree tree, List<Object?> values) async {
    final criteria = _buildCriteria(QueryType.count, tree, values, null, null);
    return countByCriteria(criteria);
  }

  /// Executes a derived exists [tree].
  Future<bool> executeQueryExists(PartTree tree, List<Object?> values) async {
    final criteria = _buildCriteria(QueryType.exists, tree, values, null, null);
    final rows = await _fetchRows(criteria);
    return rows.isNotEmpty;
  }

  /// Executes a derived delete [tree]. Returns the affected row count.
  Future<int> executeQueryDelete(PartTree tree, List<Object?> values) async {
    final criteria = _buildCriteria(QueryType.delete, tree, values, null, null);

    if (_dialect is DocumentDialect) {
      final filter = _dialect.buildFilterDocument(criteria);
      return getActiveClient().deleteDocuments(_metadata.getTableName(), filter);
    }

    final rendered = (_dialect as SqlDialect).renderQuery(criteria);
    return getActiveClient().execute(
      rendered.getSql(),
      parameters: rendered.getParameters(),
    );
  }

  QueryCriteria _buildCriteria(
    QueryType type,
    PartTree tree,
    List<Object?> values,
    Sort? sort,
    Pageable? pageable,
  ) {
    final effectiveSort = pageable?.getSort().isSorted() ?? false
        ? pageable!.getSort()
        : (sort ?? tree.getSort());

    return QueryCriteria(
      metadata: _metadata,
      type: type,
      predicate: tree.getPredicate(),
      values: values,
      sort: type == QueryType.select ? effectiveSort : Sort.UNSORTED,
      limit: pageable?.isPaged() ?? false
          ? pageable!.getPageSize()
          : tree.getLimit(),
      offset: pageable?.isPaged() ?? false ? pageable!.getOffset() : null,
      distinct: tree.isDistinct() && type == QueryType.select,
    );
  }

  /// Counts rows matching [criteria].
  Future<int> countByCriteria(QueryCriteria criteria) async {
    if (_dialect is DocumentDialect) {
      final filter = _dialect.buildFilterDocument(criteria);
      return getActiveClient().countDocuments(_metadata.getTableName(), filter);
    }

    final rendered = (_dialect as SqlDialect).renderQuery(criteria);
    final result = await getActiveClient().query(
      rendered.getSql(),
      parameters: rendered.getParameters(),
    );
    if (result.getRows().isEmpty) {
      return 0;
    }

    final firstRow = result.getRows().first;
    final value = firstRow.values.first;
    return (value as num?)?.toInt() ?? 0;
  }

  // =========================================================================
  // Internals
  // =========================================================================

  Future<List<T>> _fetchRows(QueryCriteria criteria) async {
    if (_dialect is DocumentDialect) {
      final sort = criteria.getSort().isSorted()
          ? _dialect.buildSortDocument(criteria.getSort(), _metadata)
          : null;
      final documents = await getActiveClient().findDocuments(
        _metadata.getTableName(),
        _dialect.buildFilterDocument(criteria),
        sort: sort,
        limit: criteria.getLimit(),
        skip: criteria.getOffset(),
      );

      return [
        for (final document in documents)
          _rowMapper.mapRow(_fromDocument(document)),
      ];
    }

    final rendered = (_dialect as SqlDialect).renderQuery(criteria);
    final result = await getActiveClient().query(
      rendered.getSql(),
      parameters: rendered.getParameters(),
    );
    return [
      for (final row in result.getRows()) _rowMapper.mapRow(row),
    ];
  }

  Map<String, Object?> _valuesMap(
    List<ColumnMetadata> columns,
    List<Object?> values,
  ) {
    final map = <String, Object?>{};
    for (var i = 0; i < columns.length && i < values.length; i++) {
      map[columns[i].getName()] = values[i];
    }

    return map;
  }

  Map<String, Object?> _fromDocument(Map<String, Object?> document) =>
      Map<String, Object?>.from(document);

  /// Applies `@CreatedDate`, `@LastModifiedDate`, `@CreatedBy`, `@LastModifiedBy`,
  /// and initial `@DataVersion` stamping.
  Future<void> _stampAuditing(T entity, {required bool isNew}) async {
    final now = DateTime.now();

    final created = _metadata.getCreatedDateColumn();
    if (isNew && created != null) {
      final existing = _metadata.readAttribute(entity, created.getProperty());
      if (existing == null) {
        _metadata.writeAttribute(entity, created.getProperty(), now);
      }
    }

    final modified = _metadata.getLastModifiedDateColumn();
    if (modified != null) {
      _metadata.writeAttribute(entity, modified.getProperty(), now);
    }

    final createdBy = _metadata.getCreatedByColumn();
    final modifiedBy = _metadata.getLastModifiedByColumn();
    if (_auditorAware != null && (createdBy != null || modifiedBy != null)) {
      final auditor = await _auditorAware!.getCurrentAuditor();
      if (auditor != null) {
        if (isNew && createdBy != null) {
          final existing = _metadata.readAttribute(entity, createdBy.getProperty());
          if (existing == null) {
            _metadata.writeAttribute(entity, createdBy.getProperty(), auditor);
          }
        }
        if (modifiedBy != null) {
          _metadata.writeAttribute(entity, modifiedBy.getProperty(), auditor);
        }
      }
    }

    final version = _metadata.getVersionColumn();
    if (isNew &&
        version != null &&
        _metadata.readAttribute(entity, version.getProperty()) == null) {
      _metadata.writeAttribute(entity, version.getProperty(), 0);
    }
  }

  void _hydrateGeneratedId(T entity, Map<String, Object?> row) {
    final idColumn = _metadata.getIdColumn();
    if (idColumn == null) {
      return;
    }

    final candidate = row[idColumn.getName()] ?? row['id'] ?? row['_id'];
    if (candidate == null) {
      return;
    }

    _metadata.writeAttribute(
      entity,
      idColumn.getProperty(),
      _converters.fromColumn(candidate, idColumn.getFieldType()),
    );
  }

  /// Returns the Dart field type of the `@Id` column (defaults to `String`).
  Type getIdColumnFieldType() =>
      _metadata.getIdColumn()?.getFieldType() ?? String;

  Object? _columnValue(Object? value, Type fieldType) =>
      value == null ? null : _converters.toColumn(value, fieldType);

  Object? _convertIdValue(Object generated, Type fieldType) {
    if (fieldType == int && generated is String) {
      return int.tryParse(generated) ?? generated;
    }

    return generated;
  }

  // =========================================================================
  // ID generators
  // =========================================================================

  static final Random _random = Random.secure();
  static int _snowflakeSequence = 0;

  String _uuid() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final buffer = StringBuffer();
    for (var i = 0; i < bytes.length; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) {
        buffer.write('-');
      }

      buffer.write(bytes[i].toRadixString(16).padLeft(2, '0'));
    }

    return buffer.toString();
  }

  int _snowflake() {
    final millis = DateTime.now().millisecondsSinceEpoch;
    _snowflakeSequence = (_snowflakeSequence + 1) & 0xfff;
    final shard = _random.nextInt(1024);

    return (millis << 22) | (shard << 12) | _snowflakeSequence;
  }
}