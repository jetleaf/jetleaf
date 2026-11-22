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
import 'package:meta/meta_meta.dart';

/// {@template jetleaf_entity_annotation}
/// Marks a class as a **persistent domain entity** mapped to a relational
/// table or document store collection.
///
/// ### Features
/// - Identifies the class for metadata extraction by `EntityMetadataBuilder`.
/// - Participates in automatic DDL generation via `SchemaGenerator`.
/// - Supports optional explicit table/collection naming via [tableName].
///
/// ### Usage Example
/// ```dart
/// @Entity()
/// class User {
///   @Id()
///   String? id;
///
///   String? email;
/// }
/// ```
///
/// ### Design Notes
/// - Every `@Entity` class must declare an `@Id` field (directly or in a
///   superclass) and provide a zero-argument constructor for row hydration.
/// - Can be combined with `@Table` for catalog and schema placement.
///
/// ### See Also
/// - [Table]
/// - [Id]
/// - [Column]
/// {@endtemplate}
@Target({TargetKind.classType})
final class Entity extends ReflectableAnnotation with EqualsAndHashCode {
  /// Reflective [Class] handle for [Entity].
  static final Class<Entity> CLASS = Class<Entity>(null, PackageNames.DATA);

  /// Optional explicit table or collection name.
  final String? tableName;

  /// {@macro jetleaf_entity_annotation}
  const Entity({this.tableName});

  @override
  Type get annotationType => Entity;

  @override
  List<Object?> equalizedProperties() => [tableName];
}

/// {@template jetleaf_table_annotation}
/// Specifies the **physical table or collection placement** of an `@Entity`.
///
/// Complements [Entity] by carrying physical storage coordinates including
/// the table [name], database [catalog], and [schema].
///
/// ### Usage Example
/// ```dart
/// @Entity()
/// @Table(name: 'users', schema: 'public')
/// class User {
///   @Id()
///   String? id;
/// }
/// ```
///
/// ### See Also
/// - [Entity]
/// - [Index]
/// - [Indexes]
/// {@endtemplate}
@Target({TargetKind.classType})
final class Table extends ReflectableAnnotation with EqualsAndHashCode {
  /// Reflective [Class] handle for [Table].
  static final Class<Table> CLASS = Class<Table>(null, PackageNames.DATA);

  /// The physical table or collection name.
  final String? name;

  /// Optional database catalog qualifier.
  final String? catalog;

  /// Optional database schema qualifier.
  final String? schema;

  /// {@macro jetleaf_table_annotation}
  const Table({this.name, this.catalog, this.schema});

  @override
  Type get annotationType => Table;

  @override
  List<Object?> equalizedProperties() => [name, catalog, schema];
}

/// {@template jetleaf_column_annotation}
/// Maps an entity field to a **relational column** or **document property key**
/// and customizes its DDL constraints and write participation.
///
/// ### Features
/// - Overrides the physical column/key [name].
/// - Configures `NOT NULL` ([nullable]) and `UNIQUE` ([unique]) constraints.
/// - Configures string [length] and decimal [precision]/[scale].
/// - Supports custom SQL DDL overrides via [columnDefinition].
/// - Controls participation in `INSERT` ([insertable]) and `UPDATE` ([updatable])
///   statements.
///
/// ### Usage Example
/// ```dart
/// @Entity()
/// class User {
///   @Id()
///   String? id;
///
///   @Column(name: 'email_address', nullable: false, unique: true, length: 320)
///   String? email;
/// }
/// ```
///
/// ### See Also
/// - [Entity]
/// - [Transient]
/// {@endtemplate}
@Target({TargetKind.field})
final class Column extends ReflectableAnnotation with EqualsAndHashCode {
  /// Reflective [Class] handle for [Column].
  static final Class<Column> CLASS = Class<Column>(null, PackageNames.DATA);

  /// Physical column or document field name.
  final String? name;

  /// Whether the column permits `NULL` values.
  final bool nullable;

  /// Whether the column enforces a `UNIQUE` constraint.
  final bool unique;

  /// Maximum character length for variable-length string/binary columns.
  final int? length;

  /// Precision for numeric/decimal columns.
  final int? precision;

  /// Scale for numeric/decimal columns.
  final int? scale;

  /// Custom DDL fragment overriding standard type mapping.
  final String? columnDefinition;

  /// Whether the column is included in `INSERT` statements.
  final bool insertable;

  /// Whether the column is included in `UPDATE` statements.
  final bool updatable;

  /// {@macro jetleaf_column_annotation}
  const Column({
    this.name,
    this.nullable = true,
    this.unique = false,
    this.length,
    this.precision,
    this.scale,
    this.columnDefinition,
    this.insertable = true,
    this.updatable = true,
  });

  @override
  Type get annotationType => Column;

  @override
  List<Object?> equalizedProperties() => [
    name,
    nullable,
    unique,
    length,
    precision,
    scale,
    columnDefinition,
    insertable,
    updatable,
  ];
}

/// {@template jetleaf_transient_annotation}
/// Excludes a field from **entity persistence mapping**.
///
/// Fields annotated with [Transient] are ignored by `EntityMetadataBuilder`,
/// never read from or written to the database, and omitted from DDL schema
/// generation.
///
/// ### Usage Example
/// ```dart
/// @Entity()
/// class User {
///   @Id()
///   String? id;
///
///   @Transient()
///   String? temporaryToken;
/// }
/// ```
///
/// ### See Also
/// - [Entity]
/// - [Column]
/// {@endtemplate}
@Target({TargetKind.field})
final class Transient extends ReflectableAnnotation with EqualsAndHashCode {
  /// Reflective [Class] handle for [Transient].
  static final Class<Transient> CLASS = Class<Transient>(null, PackageNames.DATA);

  /// {@macro jetleaf_transient_annotation}
  const Transient();

  @override
  Type get annotationType => Transient;

  @override
  List<Object?> equalizedProperties() => [Transient];
}