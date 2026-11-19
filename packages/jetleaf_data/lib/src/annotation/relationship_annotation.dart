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

import 'cascade_type.dart';
import 'fetch_type.dart';

/// {@template jetleaf_relationship_annotation}
/// Abstract base class for all **entity relationship annotations**
/// (`@OneToOne`, `@OneToMany`, `@ManyToOne`, and `@ManyToMany`).
///
/// Encapsulates shared association metadata including [targetEntity],
/// inverse-side [mappedBy] property, [cascade] rules, [fetch] strategy, and
/// [joinColumn] name.
///
/// ### See Also
/// - [OneToOne]
/// - [OneToMany]
/// - [ManyToOne]
/// - [ManyToMany]
/// {@endtemplate}
abstract class RelationshipAnnotation extends ReflectableAnnotation with EqualsAndHashCode {
  /// The target entity [ClassType]. When omitted, the field's declared type
  /// (or generic element type for collections) is used.
  final ClassType<dynamic>? targetEntity;

  /// The property name on the inverse side of the relationship that owns the
  /// foreign key mapping.
  final String? mappedBy;

  /// Cascade operations propagated to the target entity.
  final List<CascadeType> cascade;

  /// Fetch strategy for loading the association.
  final FetchType fetch;

  /// Physical join column name on the owning table.
  final String? joinColumn;

  /// {@macro jetleaf_relationship_annotation}
  const RelationshipAnnotation({
    this.targetEntity,
    this.mappedBy,
    this.cascade = const [],
    this.fetch = FetchType.lazy,
    this.joinColumn,
  });

  /// Returns the target entity [ClassType], if explicitly declared.
  ClassType<dynamic>? getTargetEntity() => targetEntity;

  /// Returns the inverse-side owning property name, if declared.
  String? getMappedBy() => mappedBy;

  /// Returns the configured [CascadeType] list.
  List<CascadeType> getCascade() => cascade;

  /// Returns the configured [FetchType].
  FetchType getFetch() => fetch;

  /// Returns the physical join column name, if declared.
  String? getJoinColumn() => joinColumn;

  /// Returns `true` when [CascadeType.all] or [type] is present in [cascade].
  bool hasCascade(CascadeType type) =>
      cascade.contains(CascadeType.all) || cascade.contains(type);
}
