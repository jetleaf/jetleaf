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

import '../annotation/auditing.dart';
import '../annotation/column.dart';
import '../annotation/entity.dart';
import '../annotation/generated_value.dart';
import '../annotation/id.dart';
import '../annotation/index.dart';
import '../annotation/relationships.dart';
import '../annotation/table.dart';
import '../annotation/transient.dart';
import '../exception/data_access_exception.dart';
import 'column_metadata.dart';
import 'entity_metadata.dart';
import 'entity_metadata_registry.dart';
import 'naming_strategy.dart';
import 'relationship_metadata.dart';

export 'default_entity_metadata_registry.dart';
export 'entity_metadata_registry.dart';

/// {@template jetleaf_entity_metadata_builder}
/// Reflective builder that constructs [EntityMetadata] descriptors from
/// `@Entity`-annotated classes.
///
/// ### Responsibilities
/// 1. Validates the presence of `@Entity` on the target class.
/// 2. Resolves the physical table/collection name (`@Table.getName()` >
///    `@Entity.getTableName()` > [NamingStrategy.classToTableName]).
/// 3. Walks the class hierarchy to map non-static, non-const, non-`@Transient`
///    fields to [ColumnMetadata] or [RelationshipMetadata].
/// 4. Collects `@Index` and `@Indexes` declarations into [EntityIndex] items.
/// 5. Verifies that at least one `@Id` column is declared.
///
/// ### See Also
/// - [EntityMetadata]
/// - [EntityMetadataRegistry]
/// - [NamingStrategy]
/// {@endtemplate}
final class EntityMetadataBuilder with EqualsAndHashCode {
  /// Reflective [Class] handle for [EntityMetadataBuilder].
  static final Class<EntityMetadataBuilder> CLASS =
      Class<EntityMetadataBuilder>(null, PackageNames.DATA);

  final NamingStrategy _namingStrategy;

  /// {@macro jetleaf_entity_metadata_builder}
  const EntityMetadataBuilder({
    NamingStrategy namingStrategy = NamingStrategy.snakeCase,
  }) : _namingStrategy = namingStrategy;

  /// Returns the configured [NamingStrategy].
  NamingStrategy getNamingStrategy() => _namingStrategy;

  /// Builds the [EntityMetadata] for [entityClass].
  EntityMetadata<T> build<T>(Class<T> entityClass) {
    final simpleName = entityClass.getSimpleName();

    final entity = entityClass.getDirectAnnotation<Entity>();
    if (entity == null) {
      throw EntityMappingException(
        '$simpleName is not annotated with @Entity — cannot build EntityMetadata',
        entityType: T,
      );
    }

    final table = entityClass.getDirectAnnotation<Table>();
    final tableName = table?.getName() ??
        entity.getTableName() ??
        _namingStrategy.classToTableName(simpleName);

    final columns = <ColumnMetadata>[];
    final relationships = <RelationshipMetadata>[];
    final fields = <String, Field>{};

    for (final field in _walkFields(entityClass)) {
      final fieldName = field.getName();

      if (field.isStatic() || field.isConst()) {
        continue;
      }

      if (field.hasDirectAnnotation<Transient>()) {
        continue;
      }

      final relationship = _buildRelationship(field);
      if (relationship != null) {
        relationships.add(relationship);
        continue;
      }

      fields[fieldName] = field;
      columns.add(_buildColumn(field, _namingStrategy));
    }

    final indexes = <EntityIndex>[];
    final index = entityClass.getDirectAnnotation<Index>();
    if (index != null) {
      indexes.add(
        EntityIndex(
          name: index.getEffectiveName(tableName),
          columnList: index.getColumnList(),
          unique: index.isUnique(),
        ),
      );
    }

    final grouped = entityClass.getDirectAnnotation<Indexes>();
    if (grouped != null) {
      for (final entry in grouped.getIndexes()) {
        indexes.add(
          EntityIndex(
            name: entry.getEffectiveName(tableName),
            columnList: entry.getColumnList(),
            unique: entry.isUnique(),
          ),
        );
      }
    }

    if (!columns.any((column) => column.isId())) {
      throw EntityMappingException(
        '$simpleName has no @Id field — every entity must declare an identifier',
        entityType: T,
      );
    }

    return EntityMetadata<T>(
      entityClass: entityClass,
      entityType: T,
      simpleName: simpleName,
      tableName: tableName,
      catalog: table?.getCatalog(),
      schema: table?.getSchema(),
      columns: columns,
      relationships: relationships,
      indexes: indexes,
      fields: fields,
    );
  }

  /// Builds the [EntityMetadata] for generic entity type [T].
  EntityMetadata<T> buildForType<T>() => build<T>(Class<T>());

  Iterable<Field> _walkFields<T>(Class<T> entityClass) sync* {
    final visited = <String>{};
    Class? current = entityClass;

    while (current != null) {
      if (current.getSimpleName() == 'Object') {
        break;
      }

      for (final field in current.getFields()) {
        final name = field.getName();
        if (visited.add(name)) {
          yield field;
        }
      }

      current = current.getSuperClass();
    }
  }

  ColumnMetadata _buildColumn(Field field, NamingStrategy namingStrategy) {
    final fieldName = field.getName();
    final column = field.getDirectAnnotation<Column>();
    final id = field.getDirectAnnotation<Id>();
    final generatedValue = field.getDirectAnnotation<GeneratedValue>();
    final version = field.getDirectAnnotation<DataVersion>();
    final createdDate = field.getDirectAnnotation<CreatedDate>();
    final lastModifiedDate = field.getDirectAnnotation<LastModifiedDate>();
    final createdBy = field.getDirectAnnotation<CreatedBy>();
    final lastModifiedBy = field.getDirectAnnotation<LastModifiedBy>();

    return ColumnMetadata(
      name: column?.getName() ?? namingStrategy.fieldToColumnName(fieldName),
      property: fieldName,
      fieldType: field.getType(),
      nullable: column?.isNullable() ?? true,
      unique: column?.isUnique() ?? false,
      length: column?.getLength(),
      precision: column?.getPrecision(),
      scale: column?.getScale(),
      columnDefinition: column?.getColumnDefinition(),
      insertable: column?.isInsertable() ?? true,
      updatable: column?.isUpdatable() ?? true,
      isId: id != null,
      isGenerated: generatedValue != null,
      generationStrategy: generatedValue?.getStrategy(),
      isVersion: version != null,
      isCreatedDate: createdDate != null,
      isLastModifiedDate: lastModifiedDate != null,
      isCreatedBy: createdBy != null,
      isLastModifiedBy: lastModifiedBy != null,
    );
  }

  RelationshipMetadata? _buildRelationship(Field field) {
    final fieldName = field.getName();
    final fieldType = field.getType();

    final oneToOne = field.getDirectAnnotation<OneToOne>();
    if (oneToOne != null) {
      return RelationshipMetadata(
        property: fieldName,
        fieldType: fieldType,
        type: RelationshipType.oneToOne,
        targetEntity: _resolveTarget(
              oneToOne.getTargetEntity(),
              field,
              relationshipName: 'oneToOne',
            ) ??
            fieldType,
        mappedBy: oneToOne.getMappedBy(),
        joinColumn: oneToOne.getJoinColumn(),
        cascade: oneToOne.getCascade(),
        fetch: oneToOne.getFetch(),
        optional: oneToOne.isOptional(),
      );
    }

    final oneToMany = field.getDirectAnnotation<OneToMany>();
    if (oneToMany != null) {
      return RelationshipMetadata(
        property: fieldName,
        fieldType: fieldType,
        type: RelationshipType.oneToMany,
        targetEntity: _resolveTarget(
          oneToMany.getTargetEntity(),
          field,
          relationshipName: 'oneToMany',
          required: true,
        )!,
        mappedBy: oneToMany.getMappedBy(),
        joinColumn: oneToMany.getJoinColumn(),
        cascade: oneToMany.getCascade(),
        fetch: oneToMany.getFetch(),
      );
    }

    final manyToOne = field.getDirectAnnotation<ManyToOne>();
    if (manyToOne != null) {
      return RelationshipMetadata(
        property: fieldName,
        fieldType: fieldType,
        type: RelationshipType.manyToOne,
        targetEntity: _resolveTarget(
              manyToOne.getTargetEntity(),
              field,
              relationshipName: 'manyToOne',
            ) ??
            fieldType,
        mappedBy: manyToOne.getMappedBy(),
        joinColumn: manyToOne.getJoinColumn(),
        cascade: manyToOne.getCascade(),
        fetch: manyToOne.getFetch(),
        optional: manyToOne.isOptional(),
      );
    }

    final manyToMany = field.getDirectAnnotation<ManyToMany>();
    if (manyToMany != null) {
      return RelationshipMetadata(
        property: fieldName,
        fieldType: fieldType,
        type: RelationshipType.manyToMany,
        targetEntity: _resolveTarget(
          manyToMany.getTargetEntity(),
          field,
          relationshipName: 'manyToMany',
          required: true,
        )!,
        mappedBy: manyToMany.getMappedBy(),
        joinColumn: manyToMany.getJoinColumn(),
        joinTable: manyToMany.getJoinTable(),
        inverseJoinColumn: manyToMany.getInverseJoinColumn(),
        cascade: manyToMany.getCascade(),
        fetch: manyToMany.getFetch(),
      );
    }

    return null;
  }

  Type? _resolveTarget(
    ClassType<dynamic>? explicit,
    Field field, {
    required String relationshipName,
    bool required = false,
  }) {
    if (explicit != null) {
      try {
        return explicit.toClass().getType();
      } catch (_) {
        final typeName = explicit.name ?? explicit.toString();
        return Class.forName<dynamic>(typeName).getType();
      }
    }

    if (relationshipName.toLowerCase().endsWith('many')) {
      final generic = _genericTarget(field);
      if (generic != null) {
        return generic;
      }

      if (required) {
        throw EntityMappingException(
          'Cannot infer the target entity of ${field.getName()} — declare the collection with a generic type or pass ClassType<...>()',
        );
      }

      return null;
    }

    return field.getType();
  }

  Type? _genericTarget(Field field) {
    try {
      final link =
          (field.getDeclaration() as FieldDeclaration).getLinkDeclaration();
      final args = link.getTypeArguments();
      if (args.isEmpty) {
        return null;
      }

      return args.first.getType();
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> equalizedProperties() => [_namingStrategy];
}
