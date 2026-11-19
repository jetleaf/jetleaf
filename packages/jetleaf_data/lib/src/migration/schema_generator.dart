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
import 'schema_generation_result.dart';

export 'schema_generation_result.dart';

/// {@template jetleaf_schema_generator}
/// Generates DDL statements (`CREATE TABLE`, `CREATE INDEX`) from
/// [EntityMetadata] descriptors using a target [DatabaseDialect].
/// {@endtemplate}
final class SchemaGenerator with EqualsAndHashCode {
  /// Reflective [Class] handle for [SchemaGenerator].
  static final Class<SchemaGenerator> CLASS =
      Class<SchemaGenerator>(null, PackageNames.DATA);

  final DatabaseDialect _dialect;
  final EntityMetadataRegistry _metadataRegistry;

  /// {@macro jetleaf_schema_generator}
  SchemaGenerator(
    this._dialect, {
    EntityMetadataRegistry? metadataRegistry,
  }) : _metadataRegistry =
            metadataRegistry ?? DefaultEntityMetadataRegistry.instance;

  /// Returns the [DatabaseDialect] used to render DDL statements.
  DatabaseDialect getDialect() => _dialect;

  /// Returns the [EntityMetadataRegistry] used to resolve entity metadata.
  EntityMetadataRegistry getMetadataRegistry() => _metadataRegistry;

  /// Generates DDL statements for [entityType].
  SchemaGenerationResult generateForType(Type entityType) =>
      generateFor(_metadataRegistry.getForType(entityType));

  /// Generates DDL statements for [metadata].
  SchemaGenerationResult generateFor(EntityMetadata<dynamic> metadata) {
    final statements = <String>[
      _dialect.buildCreateTableQuery(metadata),
      for (final index in metadata.getIndexes())
        _dialect.buildCreateIndexQuery(metadata, index),
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
