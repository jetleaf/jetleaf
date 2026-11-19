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

import '../annotation/cascade_type.dart';
import '../annotation/fetch_type.dart';
import 'relationship_type.dart';

export 'relationship_type.dart';

/// {@template jetleaf_relationship_metadata}
/// Immutable reflective descriptor for a single **entity association**
/// (`@OneToOne`, `@OneToMany`, `@ManyToOne`, or `@ManyToMany`).
///
/// Used by SQL dialects to plan implicit `INNER JOIN` clauses across nested
/// property paths (e.g. `findByProfileBioContaining`) and by document dialects
/// to resolve nested BSON dot-notation paths.
///
/// ### See Also
/// - [RelationshipType]
/// - `EntityMetadata`
/// {@endtemplate}
final class RelationshipMetadata with EqualsAndHashCode {
  /// Reflective [Class] handle for [RelationshipMetadata].
  static final Class<RelationshipMetadata> CLASS =
      Class<RelationshipMetadata>(null, PackageNames.DATA);

  final String _property;
  final Type _fieldType;
  final RelationshipType _type;
  final Type _targetEntity;
  final String? _mappedBy;
  final String? _joinColumn;
  final String? _joinTable;
  final String? _inverseJoinColumn;
  final List<CascadeType> _cascade;
  final FetchType _fetch;
  final bool _optional;

  /// {@macro jetleaf_relationship_metadata}
  const RelationshipMetadata({
    required String property,
    required Type fieldType,
    required RelationshipType type,
    required Type targetEntity,
    String? mappedBy,
    String? joinColumn,
    String? joinTable,
    String? inverseJoinColumn,
    List<CascadeType> cascade = const [],
    FetchType fetch = FetchType.lazy,
    bool optional = true,
  })  : _property = property,
        _fieldType = fieldType,
        _type = type,
        _targetEntity = targetEntity,
        _mappedBy = mappedBy,
        _joinColumn = joinColumn,
        _joinTable = joinTable,
        _inverseJoinColumn = inverseJoinColumn,
        _cascade = cascade,
        _fetch = fetch,
        _optional = optional;

  /// Returns the property (field) name on the owning entity.
  String getProperty() => _property;

  /// Returns the declared Dart [Type] of the field.
  Type getFieldType() => _fieldType;

  /// Returns the [RelationshipType] cardinality.
  RelationshipType getType() => _type;

  /// Returns the target entity [Type].
  Type getTargetEntity() => _targetEntity;

  /// Returns the inverse-side property owning the mapping, if any.
  String? getMappedBy() => _mappedBy;

  /// Returns the join column name on the owning table, if any.
  String? getJoinColumn() => _joinColumn;

  /// Returns the join table name for many-to-many associations, if any.
  String? getJoinTable() => _joinTable;

  /// Returns the target-side join column in the join table, if any.
  String? getInverseJoinColumn() => _inverseJoinColumn;

  /// Returns the configured [CascadeType] list.
  List<CascadeType> getCascade() => _cascade;

  /// Returns the configured [FetchType].
  FetchType getFetch() => _fetch;

  /// Returns `true` if the association is optional (nullable).
  bool isOptional() => _optional;

  /// Returns `true` if [CascadeType.all] or [type] is present in [getCascade].
  bool hasCascade(CascadeType type) =>
      _cascade.contains(CascadeType.all) || _cascade.contains(type);

  /// Returns `true` if this association is single-valued (`oneToOne` or `manyToOne`).
  bool isToOne() => _type.isToOne();

  /// Returns `true` if this association is collection-valued (`oneToMany` or `manyToMany`).
  bool isToMany() => _type.isToMany();

  @override
  List<Object?> equalizedProperties() => [
        _property,
        _fieldType,
        _type,
        _targetEntity,
        _mappedBy,
        _joinColumn,
        _joinTable,
        _inverseJoinColumn,
        _cascade,
        _fetch,
        _optional,
      ];
}
