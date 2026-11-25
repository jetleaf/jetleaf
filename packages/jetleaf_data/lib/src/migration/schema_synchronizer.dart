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
import 'package:jetleaf_core/logging.dart';

import '../dialect/database_dialect.dart';
import '../dialect/sql_dialect.dart';
import '../driver/connection_factory.dart';
import '../driver/database_client.dart';
import '../exception/data_access_exception.dart';
import '../mapping/default_entity_metadata_registry.dart';
import '../mapping/entity_metadata.dart';
import '../mapping/entity_metadata_registry.dart';

/// {@template jetleaf_ddl_auto_mode}
/// Controls how [AutoSchemaSynchronizer] synchronizes `@Entity` models with
/// the database schema during application startup, hot reload, or restart.
///
/// Configured via the `jetleaf.data.ddl-auto` environment property:
/// - [none] — disables automatic DDL synchronization
/// - [validate] — verifies all `@Entity` tables and columns exist; throws
///   [MigrationException] on mismatch
/// - [update] — creates missing tables/indexes and issues `ALTER TABLE ... ADD
///   COLUMN` for new entity fields (default when a data source is configured)
/// - [create] — drops and recreates all entity tables on startup
/// - [createDrop] — creates tables on startup and drops them on shutdown
///
/// ### Usage Example
/// ```dart
/// final mode = DdlAutoMode.parse('update');
/// final synchronizer = AutoSchemaSynchronizer(
///   client: databaseClient,
///   dialect: const PostgreSqlDialect(),
///   mode: mode,
/// );
/// ```
/// {@endtemplate}
enum DdlAutoMode {
  /// Disables automatic schema synchronization.
  none,

  /// Validates that all mapped tables and columns exist without modifying DDL.
  validate,

  /// Creates missing tables/indexes and adds newly introduced entity columns.
  update,

  /// Drops existing entity tables and recreates them on startup.
  create,

  /// Drops and recreates entity tables on startup, then drops them on shutdown.
  createDrop;

  /// {@template jetleaf_ddl_auto_mode_parse}
  /// Parses a [DdlAutoMode] from a configuration string (e.g. `'update'`,
  /// `'create-drop'`, `'validate'`, `'create'`, or `'none'`).
  ///
  /// Throws a [MigrationException] if [value] does not match any supported mode.
  /// {@endtemplate}
  static DdlAutoMode parse(String value) {
    return switch (value.trim().toLowerCase()) {
      'none' => DdlAutoMode.none,
      'validate' => DdlAutoMode.validate,
      'update' => DdlAutoMode.update,
      'create' => DdlAutoMode.create,
      'create-drop' || 'createdrop' => DdlAutoMode.createDrop,
      _ => throw MigrationException(
          'Unsupported jetleaf.data.ddl-auto value "$value" — expected one of: none, validate, update, create, create-drop',
        ),
    };
  }
}

/// {@template jetleaf_schema_synchronization_result}
/// Immutable summary of DDL actions executed by
/// [AutoSchemaSynchronizer.synchronize].
///
/// Captures the tables created ([getTablesCreated]), columns added via
/// `ALTER TABLE` ([getColumnsAdded]), indexes created ([getIndexesCreated]),
/// tables dropped ([getTablesDropped]), and the full list of executed SQL
/// statements ([getStatementsExecuted]).
///
/// ### Usage Example
/// ```dart
/// final result = await synchronizer.synchronize([User, Order]);
/// print('Created tables: ${result.getTablesCreated()}');
/// print('Added columns: ${result.getColumnsAdded()}');
/// ```
/// {@endtemplate}
final class SchemaSynchronizationResult with EqualsAndHashCode {
  /// Reflective [Class] handle for [SchemaSynchronizationResult].
  static final Class<SchemaSynchronizationResult> CLASS = Class<SchemaSynchronizationResult>(null, PackageNames.DATA);

  /// Physical table names created during synchronization.
  final List<String> _tablesCreated;

  /// `table.column` identifiers added via `ALTER TABLE ... ADD COLUMN`.
  final List<String> _columnsAdded;

  /// Physical index names created during synchronization.
  final List<String> _indexesCreated;

  /// Physical table names dropped prior to recreation.
  final List<String> _tablesDropped;

  /// Ordered list of DDL statements executed during synchronization.
  final List<String> _statementsExecuted;

  /// {@macro jetleaf_schema_synchronization_result}
  SchemaSynchronizationResult({
    List<String> tablesCreated = const [],
    List<String> columnsAdded = const [],
    List<String> indexesCreated = const [],
    List<String> tablesDropped = const [],
    List<String> statementsExecuted = const [],
  })  : _tablesCreated = List.unmodifiable(tablesCreated),
        _columnsAdded = List.unmodifiable(columnsAdded),
        _indexesCreated = List.unmodifiable(indexesCreated),
        _tablesDropped = List.unmodifiable(tablesDropped),
        _statementsExecuted = List.unmodifiable(statementsExecuted);

  /// Returns the table names created during synchronization.
  List<String> getTablesCreated() => _tablesCreated;

  /// Returns the `table.column` identifiers added via `ALTER TABLE`.
  List<String> getColumnsAdded() => _columnsAdded;

  /// Returns the index names created during synchronization.
  List<String> getIndexesCreated() => _indexesCreated;

  /// Returns the table names dropped during synchronization.
  List<String> getTablesDropped() => _tablesDropped;

  /// Returns all DDL statements executed during synchronization.
  List<String> getStatementsExecuted() => _statementsExecuted;

  @override
  List<Object?> equalizedProperties() => [
        _tablesCreated,
        _columnsAdded,
        _indexesCreated,
        _tablesDropped,
        _statementsExecuted,
      ];
}

/// {@template jetleaf_auto_schema_synchronizer}
/// Automatically synchronizes `@Entity` model definitions with the target
/// database schema on application startup, hot reload, or context restart.
///
/// Supports [DdlAutoMode.none], [DdlAutoMode.validate], [DdlAutoMode.update],
/// [DdlAutoMode.create], and [DdlAutoMode.createDrop] across relational
/// [SqlDialect] implementations.
///
/// ### Usage Example
/// ```dart
/// final synchronizer = AutoSchemaSynchronizer(
///   client: databaseClient,
///   dialect: const PostgreSqlDialect(),
///   mode: DdlAutoMode.update,
/// );
/// final result = await synchronizer.synchronize([User, Order]);
/// ```
///
/// ### See Also
/// - [DdlAutoMode]
/// - [SchemaSynchronizationResult]
/// - `SchemaGenerator`
/// {@endtemplate}
final class AutoSchemaSynchronizer with EqualsAndHashCode {
  /// Reflective [Class] handle for [AutoSchemaSynchronizer].
  static final Class<AutoSchemaSynchronizer> CLASS = Class<AutoSchemaSynchronizer>(null, PackageNames.DATA);

  /// Direct [DatabaseClient] used when no [ConnectionFactory] pool is supplied.
  final DatabaseClient? _client;

  /// [ConnectionFactory] used to lease and release connections per sync pass.
  final ConnectionFactory? _connectionFactory;

  /// Target [DatabaseDialect] used to render DDL and introspection queries.
  final DatabaseDialect _dialect;

  /// Registry used to resolve [EntityMetadata] for each `@Entity` type.
  final EntityMetadataRegistry _metadataRegistry;

  /// Configured synchronization mode controlling DDL execution behavior.
  final DdlAutoMode _mode;

  /// Logger for emitting schema migration diagnostics.
  final Log _logger = LogFactory.getLog(AutoSchemaSynchronizer);

  /// {@macro jetleaf_auto_schema_synchronizer}
  AutoSchemaSynchronizer({
    DatabaseClient? client,
    ConnectionFactory? connectionFactory,
    required DatabaseDialect dialect,
    EntityMetadataRegistry? metadataRegistry,
    DdlAutoMode mode = DdlAutoMode.update,
  })  : assert(client != null || connectionFactory != null, 'Either client or connectionFactory must be provided'),
        _client = client,
        _connectionFactory = connectionFactory,
        _dialect = dialect,
        _metadataRegistry = metadataRegistry ?? DefaultEntityMetadataRegistry.instance,
        _mode = mode;

  /// Returns the configured [DdlAutoMode].
  DdlAutoMode getMode() => _mode;

  /// {@template jetleaf_auto_schema_synchronizer_synchronize}
  /// Synchronizes the database schema for all [entityTypes] according to
  /// [getMode], creating missing tables/indexes, adding new entity columns, or
  /// validating existing schema structure.
  /// {@endtemplate}
  Future<SchemaSynchronizationResult> synchronize(Iterable<Type> entityTypes) async {
    if (_mode == DdlAutoMode.none) {
      return SchemaSynchronizationResult();
    }

    final dialect = _dialect;
    if (dialect is! SqlDialect) {
      return SchemaSynchronizationResult();
    }

    final types = entityTypes.toList(growable: false);
    if (types.isEmpty) {
      return SchemaSynchronizationResult();
    }

    return _withClient((client) async {
      final tablesCreated = <String>[];
      final columnsAdded = <String>[];
      final indexesCreated = <String>[];
      final tablesDropped = <String>[];
      final statements = <String>[];

      for (final entityType in types) {
        final metadata = _metadataRegistry.getForType(entityType);
        final tableName = metadata.getTableName();

        switch (_mode) {
          case DdlAutoMode.none:
            break;

          case DdlAutoMode.create:
          case DdlAutoMode.createDrop:
            final dropSql = dialect.buildDropTableQuery(metadata);
            await client.execute(dropSql);
            tablesDropped.add(tableName);
            statements.add(dropSql);

            await _createTableAndIndexes(client, dialect, metadata, tablesCreated, indexesCreated, statements);

          case DdlAutoMode.update:
            final existingColumns = await _inspectExistingColumns(client, dialect, metadata);
            if (existingColumns.isEmpty) {
              await _createTableAndIndexes(client, dialect, metadata, tablesCreated, indexesCreated, statements);
            } else {
              for (final column in metadata.getColumns()) {
                if (!existingColumns.contains(column.getName().toLowerCase())) {
                  final alterSql = dialect.buildAddColumnQuery(metadata, column);
                  await client.execute(alterSql);
                  columnsAdded.add('$tableName.${column.getName()}');
                  statements.add(alterSql);
                  if (_logger.getIsInfoEnabled()) {
                    _logger.info('Added column ${column.getName()} to table $tableName');
                  }
                }
              }

              for (final index in metadata.getIndexes()) {
                final indexSql = dialect.buildCreateIndexQuery(metadata, index);
                await client.execute(indexSql);
                indexesCreated.add(index.getName());
                statements.add(indexSql);
              }
            }

          case DdlAutoMode.validate:
            final existingColumns = await _inspectExistingColumns(client, dialect, metadata);
            if (existingColumns.isEmpty) {
              throw MigrationException('Schema validation failed: table "$tableName" does not exist');
            }
            for (final column in metadata.getColumns()) {
              if (!existingColumns.contains(column.getName().toLowerCase())) {
                throw MigrationException(
                  'Schema validation failed: column "${column.getName()}" missing on table "$tableName"',
                );
              }
            }
        }
      }

      return SchemaSynchronizationResult(
        tablesCreated: tablesCreated,
        columnsAdded: columnsAdded,
        indexesCreated: indexesCreated,
        tablesDropped: tablesDropped,
        statementsExecuted: statements,
      );
    });
  }

  /// {@template jetleaf_auto_schema_synchronizer_drop_all}
  /// Drops all tables corresponding to [entityTypes] in reverse registration
  /// order when [DdlAutoMode.createDrop] is active during context shutdown.
  /// {@endtemplate}
  Future<void> dropAll(Iterable<Type> entityTypes) async {
    final dialect = _dialect;
    if (dialect is! SqlDialect) {
      return;
    }

    final types = entityTypes.toList(growable: false);
    if (types.isEmpty) {
      return;
    }

    await _withClient((client) async {
      for (final entityType in types.reversed) {
        final metadata = _metadataRegistry.getForType(entityType);
        await client.execute(dialect.buildDropTableQuery(metadata));
      }
    });
  }

  /// {@template jetleaf_auto_schema_synchronizer_create_table_and_indexes}
  /// Executes `CREATE TABLE IF NOT EXISTS` followed by `CREATE INDEX`
  /// statements for [metadata] and records the executed DDL in the result
  /// accumulators.
  /// {@endtemplate}
  Future<void> _createTableAndIndexes(
    DatabaseClient client,
    SqlDialect dialect,
    EntityMetadata<dynamic> metadata,
    List<String> tablesCreated,
    List<String> indexesCreated,
    List<String> statements,
  ) async {
    final createSql = dialect.buildCreateTableQuery(metadata);
    await client.execute(createSql);
    tablesCreated.add(metadata.getTableName());
    statements.add(createSql);

    for (final index in metadata.getIndexes()) {
      final indexSql = dialect.buildCreateIndexQuery(metadata, index);
      await client.execute(indexSql);
      indexesCreated.add(index.getName());
      statements.add(indexSql);
    }
  }

  /// {@template jetleaf_auto_schema_synchronizer_inspect_existing_columns}
  /// Queries the target database via [SqlDialect.buildInspectColumnsQuery] and
  /// returns the lowercase set of existing column names for [metadata]'s table,
  /// or an empty set if the table does not yet exist.
  /// {@endtemplate}
  Future<Set<String>> _inspectExistingColumns(
    DatabaseClient client,
    SqlDialect dialect,
    EntityMetadata<dynamic> metadata,
  ) async {
    try {
      final result = await client.query(dialect.buildInspectColumnsQuery(metadata));
      final columns = <String>{};
      for (final row in result.getRows()) {
        final name = row['column_name'] ?? row['COLUMN_NAME'] ?? row['name'];
        if (name != null) {
          columns.add(name.toString().toLowerCase());
        }
      }
      return columns;
    } catch (_) {
      return const <String>{};
    }
  }

  /// {@template jetleaf_auto_schema_synchronizer_with_client}
  /// Executes [action] using the direct [_client] when provided, or leases and
  /// subsequently closes a connection from [_connectionFactory].
  /// {@endtemplate}
  Future<T> _withClient<T>(Future<T> Function(DatabaseClient client) action) async {
    final direct = _client;
    if (direct != null) {
      return action(direct);
    }
    final leased = await _connectionFactory!.getConnection();
    try {
      return await action(leased);
    } finally {
      await leased.close();
    }
  }

  @override
  List<Object?> equalizedProperties() => [_dialect, _metadataRegistry, _mode];
}