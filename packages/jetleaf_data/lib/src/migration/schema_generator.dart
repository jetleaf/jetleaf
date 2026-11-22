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
import '../mapping/default_entity_metadata_registry.dart';
import '../mapping/entity_metadata.dart';
import '../mapping/entity_metadata_registry.dart';

/// {@template jetleaf_schema_generation_result}
/// Immutable container holding the DDL statements generated for a single
/// `@Entity` by [SchemaGenerator].
/// {@endtemplate}
final class SchemaGenerationResult with EqualsAndHashCode {
  /// Reflective [Class] handle for [SchemaGenerationResult].
  static final Class<SchemaGenerationResult> CLASS = Class<SchemaGenerationResult>(null, PackageNames.DATA);

  final Type _entityType;
  final String _tableName;
  final List<String> _statements;

  /// {@macro jetleaf_schema_generation_result}
  SchemaGenerationResult({
    required Type entityType,
    required String tableName,
    required List<String> statements,
  })  : _entityType = entityType,
        _tableName = tableName,
        _statements = List.unmodifiable(statements);

  /// Returns the entity [Type] the DDL was generated for.
  Type getEntityType() => _entityType;

  /// Returns the physical table or collection name.
  String getTableName() => _tableName;

  /// Returns the ordered DDL statements (`CREATE TABLE`, `CREATE INDEX`, etc.).
  List<String> getStatements() => _statements;

  @override
  List<Object?> equalizedProperties() => [
    _entityType,
    _tableName,
    _statements,
  ];
}

/// {@template jetleaf_schema_generator}
/// Generates DDL statements (`CREATE TABLE`, `CREATE INDEX`) from
/// [EntityMetadata] descriptors using a target [DatabaseDialect].
///
/// ### Usage Example
/// ```dart
/// final generator = SchemaGenerator(const PostgreSqlDialect());
/// final result = generator.generateFor<User>();
/// for (final ddl in result.getStatements()) {
///   await client.execute(ddl);
/// }
/// ```
/// {@endtemplate}
final class SchemaGenerator with EqualsAndHashCode {
  /// Reflective [Class] handle for [SchemaGenerator].
  static final Class<SchemaGenerator> CLASS = Class<SchemaGenerator>(null, PackageNames.DATA);

  final DatabaseDialect _dialect;
  final EntityMetadataRegistry _metadataRegistry;

  /// {@macro jetleaf_schema_generator}
  SchemaGenerator(
    this._dialect, {
    EntityMetadataRegistry? metadataRegistry,
  }) : _metadataRegistry = metadataRegistry ?? DefaultEntityMetadataRegistry.instance;

  /// Returns the [DatabaseDialect] used to render DDL statements.
  DatabaseDialect getDialect() => _dialect;

  /// Returns the [EntityMetadataRegistry] used to resolve entity metadata.
  EntityMetadataRegistry getMetadataRegistry() => _metadataRegistry;

  /// Generates DDL statements for [entityType].
  SchemaGenerationResult generateForType(Type entityType) => generateFor(_metadataRegistry.getForType(entityType));

  /// Generates DDL statements for [metadata].
  SchemaGenerationResult generateFor(EntityMetadata<dynamic> metadata) {
    final statements = <String>[
      _dialect.buildCreateTableQuery(metadata),
      for (final index in metadata.getIndexes()) ...[
        _dialect.buildCreateIndexQuery(metadata, index)
      ],
    ];

    return SchemaGenerationResult(
      entityType: metadata.getEntityType(),
      tableName: metadata.getTableName(),
      statements: statements,
    );
  }

  /// Generates DDL statements for all [entityTypes].
  List<SchemaGenerationResult> generateForTypes(Iterable<Type> entityTypes) =>
      entityTypes.map(generateForType).toList(growable: false);

  @override
  List<Object?> equalizedProperties() => [_dialect, _metadataRegistry];
}