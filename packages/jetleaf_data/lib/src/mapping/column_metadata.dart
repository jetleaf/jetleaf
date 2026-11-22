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

import '../annotation/id.dart';

/// {@template jetleaf_column_metadata}
/// Immutable reflective descriptor for a single mapped **relational column**
/// or **document property key** on an `@Entity`.
///
/// Produced by `EntityMetadataBuilder` by inspecting field declarations,
/// `@Column`, `@Id`, `@GeneratedValue`, `@DataVersion`, `@CreatedDate`,
/// `@LastModifiedDate`, `@CreatedBy`, and `@LastModifiedBy` annotations,
/// together with the active `NamingStrategy`.
///
/// ### Features
/// - Tracks both the Dart [getProperty] name and physical [getName] column key.
/// - Exposes DDL attributes ([isNullable], [isUnique], [getLength],
///   [getPrecision], [getScale], [getColumnDefinition]).
/// - Identifies lifecycle semantics ([isId], [isGenerated],
///   [isDatabaseGenerated], [isVersion], [isCreatedDate], [isLastModifiedDate],
///   [isCreatedBy], [isLastModifiedBy]).
///
/// ### See Also
/// - `EntityMetadata`
/// - `EntityMetadataBuilder`
/// - `Column`
/// {@endtemplate}
final class ColumnMetadata with EqualsAndHashCode {
  /// Reflective [Class] handle for [ColumnMetadata].
  static final Class<ColumnMetadata> CLASS = Class<ColumnMetadata>(null, PackageNames.DATA);

  final String _name;
  final String _property;
  final Type _fieldType;
  final bool _nullable;
  final bool _unique;
  final int? _length;
  final int? _precision;
  final int? _scale;
  final String? _columnDefinition;
  final bool _insertable;
  final bool _updatable;
  final bool _isId;
  final bool _isGenerated;
  final GenerationStrategy? _generationStrategy;
  final bool _isVersion;
  final bool _isCreatedDate;
  final bool _isLastModifiedDate;
  final bool _isCreatedBy;
  final bool _isLastModifiedBy;

  /// {@macro jetleaf_column_metadata}
  const ColumnMetadata({
    required String name,
    required String property,
    required Type fieldType,
    bool nullable = true,
    bool unique = false,
    int? length,
    int? precision,
    int? scale,
    String? columnDefinition,
    bool insertable = true,
    bool updatable = true,
    bool isId = false,
    bool isGenerated = false,
    GenerationStrategy? generationStrategy,
    bool isVersion = false,
    bool isCreatedDate = false,
    bool isLastModifiedDate = false,
    bool isCreatedBy = false,
    bool isLastModifiedBy = false,
  })  : _name = name,
        _property = property,
        _fieldType = fieldType,
        _nullable = nullable,
        _unique = unique,
        _length = length,
        _precision = precision,
        _scale = scale,
        _columnDefinition = columnDefinition,
        _insertable = insertable,
        _updatable = updatable,
        _isId = isId,
        _isGenerated = isGenerated,
        _generationStrategy = generationStrategy,
        _isVersion = isVersion,
        _isCreatedDate = isCreatedDate,
        _isLastModifiedDate = isLastModifiedDate,
        _isCreatedBy = isCreatedBy,
        _isLastModifiedBy = isLastModifiedBy;

  /// Returns the physical column or document key name.
  String getName() => _name;

  /// Returns the Dart field/property name on the entity class.
  String getProperty() => _property;

  /// Returns the declared Dart [Type] of the field.
  Type getFieldType() => _fieldType;

  /// Returns `true` if the column allows `NULL` values.
  bool isNullable() => _nullable;

  /// Returns `true` if the column enforces a `UNIQUE` constraint.
  bool isUnique() => _unique;

  /// Returns the declared maximum string/binary length, if any.
  int? getLength() => _length;

  /// Returns the numeric precision, if any.
  int? getPrecision() => _precision;

  /// Returns the numeric scale, if any.
  int? getScale() => _scale;

  /// Returns the custom SQL column definition override, if any.
  String? getColumnDefinition() => _columnDefinition;

  /// Returns `true` if the column participates in `INSERT` statements.
  bool isInsertable() => _insertable;

  /// Returns `true` if the column participates in `UPDATE` statements.
  bool isUpdatable() => _updatable;

  /// Returns `true` if this column is the primary key (`@Id`).
  bool isId() => _isId;

  /// Returns `true` if this column's value is generated (`@GeneratedValue`).
  bool isGenerated() => _isGenerated;

  /// Returns the [GenerationStrategy] when [isGenerated] is `true`.
  GenerationStrategy? getGenerationStrategy() => _generationStrategy;

  /// Returns `true` if this column is the optimistic lock version (`@DataVersion`).
  bool isVersion() => _isVersion;

  /// Returns `true` if this column is the creation timestamp (`@CreatedDate`).
  bool isCreatedDate() => _isCreatedDate;

  /// Returns `true` if this column is the last-modified timestamp (`@LastModifiedDate`).
  bool isLastModifiedDate() => _isLastModifiedDate;

  /// Returns `true` if this column stores the creator principal (`@CreatedBy`).
  bool isCreatedBy() => _isCreatedBy;

  /// Returns `true` if this column stores the last-modifier principal (`@LastModifiedBy`).
  bool isLastModifiedBy() => _isLastModifiedBy;

  /// Returns `true` if the identifier is generated by the database engine
  /// (`GenerationStrategy.autoIncrement` or `GenerationStrategy.identity`).
  bool isDatabaseGenerated() =>
      _isGenerated && (_generationStrategy?.isDatabaseGenerated() ?? false);

  @override
  List<Object?> equalizedProperties() => [
    _name,
    _property,
    _fieldType,
    _nullable,
    _unique,
    _length,
    _precision,
    _scale,
    _columnDefinition,
    _insertable,
    _updatable,
    _isId,
    _isGenerated,
    _generationStrategy,
    _isVersion,
    _isCreatedDate,
    _isLastModifiedDate,
    _isCreatedBy,
    _isLastModifiedBy,
  ];
}