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

  /// Returns the explicit column name, or `null` if derived via naming strategy.
  String? getName() => name;

  /// Returns `true` if the column allows `NULL` values.
  bool isNullable() => nullable;

  /// Returns `true` if the column carries a `UNIQUE` constraint.
  bool isUnique() => unique;

  /// Returns the maximum character length, if configured.
  int? getLength() => length;

  /// Returns the decimal precision, if configured.
  int? getPrecision() => precision;

  /// Returns the decimal scale, if configured.
  int? getScale() => scale;

  /// Returns the custom SQL column definition override, if configured.
  String? getColumnDefinition() => columnDefinition;

  /// Returns `true` if the column participates in `INSERT` statements.
  bool isInsertable() => insertable;

  /// Returns `true` if the column participates in `UPDATE` statements.
  bool isUpdatable() => updatable;

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
