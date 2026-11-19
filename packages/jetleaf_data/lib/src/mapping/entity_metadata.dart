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

import 'column_metadata.dart';
import 'entity_index.dart';
import 'relationship_metadata.dart';

export 'entity_index.dart';

/// {@template jetleaf_entity_metadata}
/// Complete, immutable reflective descriptor for a persistent `@Entity` class
/// of type [T].
///
/// Built once per entity type by `EntityMetadataBuilder` and cached in
/// `EntityMetadataRegistry`. Provides dialects, schema generators, row mappers,
/// and repository executors with uniform access to table coordinates, column
/// mappings, relationships, indexes, and reflective field accessors.
///
/// ### Features
/// - Resolves primary key ([getIdColumn]), optimistic lock version
///   ([getVersionColumn]), and auditing columns ([getCreatedDateColumn],
///   [getLastModifiedDateColumn], [getCreatedByColumn],
///   [getLastModifiedByColumn]).
/// - Pre-computes insertable ([getInsertColumns]), updatable
///   ([getUpdateColumns]), and selectable ([getSelectColumns]) column lists.
/// - Instantiates new entities via [newInstance] and reads/writes attributes
///   reflectively via [readAttribute] and [writeAttribute].
///
/// ### See Also
/// - [ColumnMetadata]
/// - [RelationshipMetadata]
/// - [EntityIndex]
/// - `EntityMetadataBuilder`
/// - `EntityMetadataRegistry`
/// {@endtemplate}
@Generic(EntityMetadata)
final class EntityMetadata<T> with EqualsAndHashCode {
  /// Reflective [Class] handle for [EntityMetadata].
  static final Class<EntityMetadata> CLASS =
      Class<EntityMetadata>(null, PackageNames.DATA);

  final Class<T> _entityClass;
  final Type _entityType;
  final String _simpleName;
  final String _tableName;
  final String? _catalog;
  final String? _schema;
  final List<ColumnMetadata> _columns;
  final List<RelationshipMetadata> _relationships;
  final List<EntityIndex> _indexes;
  final Map<String, Field> _fields;

  /// {@macro jetleaf_entity_metadata}
  EntityMetadata({
    required Class<T> entityClass,
    required Type entityType,
    required String simpleName,
    required String tableName,
    String? catalog,
    String? schema,
    required List<ColumnMetadata> columns,
    required List<RelationshipMetadata> relationships,
    required List<EntityIndex> indexes,
    required Map<String, Field> fields,
  })  : _entityClass = entityClass,
        _entityType = entityType,
        _simpleName = simpleName,
        _tableName = tableName,
        _catalog = catalog,
        _schema = schema,
        _columns = List.unmodifiable(columns),
        _relationships = List.unmodifiable(relationships),
        _indexes = List.unmodifiable(indexes),
        _fields = Map.unmodifiable(fields);

  /// Returns the reflective [Class] handle for the entity type [T].
  Class<T> getEntityClass() => _entityClass;

  /// Returns the Dart runtime [Type] of the entity.
  Type getEntityType() => _entityType;

  /// Returns the unqualified simple name of the entity class.
  String getSimpleName() => _simpleName;

  /// Returns the physical table or collection name.
  String getTableName() => _tableName;

  /// Returns the database catalog qualifier, if configured.
  String? getCatalog() => _catalog;

  /// Returns the database schema qualifier, if configured.
  String? getSchema() => _schema;

  /// Returns an unmodifiable list of all mapped [ColumnMetadata] entries.
  List<ColumnMetadata> getColumns() => _columns;

  /// Returns an unmodifiable list of all mapped [RelationshipMetadata] entries.
  List<RelationshipMetadata> getRelationships() => _relationships;

  /// Returns an unmodifiable list of all declared [EntityIndex] entries.
  List<EntityIndex> getIndexes() => _indexes;

  /// Returns an unmodifiable map of reflective [Field] handles keyed by
  /// property name.
  Map<String, Field> getFields() => _fields;

  /// Returns the primary key (`@Id`) [ColumnMetadata], or `null` if none.
  ColumnMetadata? getIdColumn() {
    for (final column in _columns) {
      if (column.isId()) {
        return column;
      }
    }
    return null;
  }

  /// Returns the optimistic lock version (`@DataVersion`) [ColumnMetadata],
  /// or `null` if none.
  ColumnMetadata? getVersionColumn() {
    for (final column in _columns) {
      if (column.isVersion()) {
        return column;
      }
    }
    return null;
  }

  /// Returns the `@CreatedDate` [ColumnMetadata], or `null` if none.
  ColumnMetadata? getCreatedDateColumn() {
    for (final column in _columns) {
      if (column.isCreatedDate()) {
        return column;
      }
    }
    return null;
  }

  /// Returns the `@LastModifiedDate` [ColumnMetadata], or `null` if none.
  ColumnMetadata? getLastModifiedDateColumn() {
    for (final column in _columns) {
      if (column.isLastModifiedDate()) {
        return column;
      }
    }
    return null;
  }

  /// Returns the `@CreatedBy` [ColumnMetadata], or `null` if none.
  ColumnMetadata? getCreatedByColumn() {
    for (final column in _columns) {
      if (column.isCreatedBy()) {
        return column;
      }
    }
    return null;
  }

  /// Returns the `@LastModifiedBy` [ColumnMetadata], or `null` if none.
  ColumnMetadata? getLastModifiedByColumn() {
    for (final column in _columns) {
      if (column.isLastModifiedBy()) {
        return column;
      }
    }
    return null;
  }

  /// Returns the ordered list of columns participating in `INSERT` statements
  /// (excluding non-insertable and database-generated `@Id` columns).
  List<ColumnMetadata> getInsertColumns() {
    final result = <ColumnMetadata>[];
    for (final column in _columns) {
      if (!column.isInsertable()) continue;
      if (column.isId() && column.isDatabaseGenerated()) continue;
      result.add(column);
    }
    return result;
  }

  /// Returns the ordered list of columns participating in `UPDATE` statements
  /// (excluding non-updatable and `@Id` columns).
  List<ColumnMetadata> getUpdateColumns() {
    final result = <ColumnMetadata>[];
    for (final column in _columns) {
      if (!column.isUpdatable()) continue;
      if (column.isId()) continue;
      result.add(column);
    }
    return result;
  }

  /// Returns all columns eligible for `SELECT` projections.
  List<ColumnMetadata> getSelectColumns() => _columns;

  /// Looks up a [ColumnMetadata] by its Dart entity [property] name.
  ColumnMetadata? getColumnByProperty(String property) {
    for (final column in _columns) {
      if (column.getProperty() == property) {
        return column;
      }
    }
    return null;
  }

  /// Alias for [getColumnByProperty].
  ColumnMetadata? columnByProperty(String property) =>
      getColumnByProperty(property);

  /// Looks up a [ColumnMetadata] by its physical column [name]
  /// (case-insensitive).
  ColumnMetadata? getColumnByName(String name) {
    final lower = name.toLowerCase();
    for (final column in _columns) {
      if (column.getName().toLowerCase() == lower) {
        return column;
      }
    }
    return null;
  }

  /// Alias for [getColumnByName].
  ColumnMetadata? columnByName(String name) => getColumnByName(name);

  /// Looks up a [RelationshipMetadata] by its Dart entity [property] name.
  RelationshipMetadata? getRelationshipByProperty(String property) {
    for (final relationship in _relationships) {
      if (relationship.getProperty() == property) {
        return relationship;
      }
    }
    return null;
  }

  /// Alias for [getRelationshipByProperty].
  RelationshipMetadata? relationshipByProperty(String property) =>
      getRelationshipByProperty(property);

  /// Returns the qualified table name (`catalog.schema.table` or `schema.table`
  /// when qualifiers are present).
  String getQualifiedTableName() {
    final buffer = StringBuffer();
    if (_catalog != null) {
      buffer.write('$_catalog.');
    }
    if (_schema != null) {
      buffer.write('$_schema.');
    }
    buffer.write(_tableName);
    return buffer.toString();
  }

  /// Instantiates a new entity instance using its default zero-argument
  /// constructor.
  T newInstance() => _entityClass.newInstance();

  /// Reads the attribute value for [property] from [instance].
  Object? readAttribute(T instance, String property) =>
      _fields[property]?.getValue(instance);

  /// Writes [value] to the attribute [property] on [instance].
  void writeAttribute(T instance, String property, Object? value) {
    final field = _fields[property];
    if (field == null) {
      throw IllegalArgumentException(
        'Property "$property" is not mapped on $_simpleName',
      );
    }
    field.setValue(instance, value);
  }

  @override
  List<Object?> equalizedProperties() => [
        _entityType,
        _tableName,
        _columns,
        _relationships,
        _indexes,
      ];
}
