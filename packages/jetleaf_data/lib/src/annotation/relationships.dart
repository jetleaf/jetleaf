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

/// {@template jetleaf_cascade_type}
/// Defines the **cascade operations** propagated from an owning entity to its
/// associated target entities.
///
/// | Value | Behavior |
/// |-------|----------|
/// | [all] | Propagates all persistence operations (`persist` and `remove`) |
/// | [persist] | Saving the owning entity also saves associated child entities |
/// | [remove] | Deleting the owning entity also deletes associated child entities |
/// {@endtemplate}
enum CascadeType {
  /// Propagates all persistence operations.
  all,

  /// Propagates `save`/`insert` operations.
  persist,

  /// Propagates `delete` operations.
  remove,
}

/// {@template jetleaf_fetch_type}
/// Defines the **fetching strategy** for an entity association.
///
/// | Value | Behavior |
/// |-------|----------|
/// | [lazy] | Defers loading the association until explicitly requested |
/// | [eager] | Loads the association immediately alongside the owning entity |
/// {@endtemplate}
enum FetchType {
  /// Resolves the association lazily on demand.
  lazy,

  /// Resolves the association eagerly with the owning entity.
  eager,
}

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

  /// Returns `true` when [CascadeType.all] or [type] is present in [cascade].
  bool hasCascade(CascadeType type) => cascade.contains(CascadeType.all) || cascade.contains(type);
}

/// {@template jetleaf_one_to_one_annotation}
/// Declares a **one-to-one** association between two persistent entities.
///
/// ### Usage Example
/// ```dart
/// @Entity()
/// class User {
///   @Id()
///   String? id;
///
///   @OneToOne(targetEntity: ClassType<Profile>(), joinColumn: 'profile_id')
///   Profile? profile;
/// }
/// ```
///
/// ### See Also
/// - [RelationshipAnnotation]
/// - [ManyToOne]
/// {@endtemplate}
@Target({TargetKind.field})
final class OneToOne extends RelationshipAnnotation {
  /// Reflective [Class] handle for [OneToOne].
  static final Class<OneToOne> CLASS = Class<OneToOne>(null, PackageNames.DATA);

  /// Whether the association may be `null`.
  final bool optional;

  /// {@macro jetleaf_one_to_one_annotation}
  const OneToOne({
    super.targetEntity,
    super.mappedBy,
    super.cascade,
    super.fetch,
    super.joinColumn,
    this.optional = true,
  });

  @override
  Type get annotationType => OneToOne;

  @override
  List<Object?> equalizedProperties() => [
    targetEntity,
    mappedBy,
    cascade,
    fetch,
    joinColumn,
    optional,
  ];
}

/// {@template jetleaf_one_to_many_annotation}
/// Declares a **one-to-many** collection association from an owning entity to
/// multiple child entities.
///
/// ### Usage Example
/// ```dart
/// @Entity()
/// class Customer {
///   @Id()
///   String? id;
///
///   @OneToMany(targetEntity: ClassType<Order>(), mappedBy: 'customer')
///   List<Order> orders = [];
/// }
/// ```
///
/// ### See Also
/// - [ManyToOne]
/// - [RelationshipAnnotation]
/// {@endtemplate}
@Target({TargetKind.field})
final class OneToMany extends RelationshipAnnotation {
  /// Reflective [Class] handle for [OneToMany].
  static final Class<OneToMany> CLASS = Class<OneToMany>(null, PackageNames.DATA);

  /// {@macro jetleaf_one_to_many_annotation}
  const OneToMany({
    super.targetEntity,
    super.mappedBy,
    super.cascade,
    super.fetch = FetchType.lazy,
    super.joinColumn,
  });

  @override
  Type get annotationType => OneToMany;

  @override
  List<Object?> equalizedProperties() => [
    targetEntity,
    mappedBy,
    cascade,
    fetch,
    joinColumn,
  ];
}

/// {@template jetleaf_many_to_one_annotation}
/// Declares a **many-to-one** association from child entities to a single
/// parent entity.
///
/// ### Usage Example
/// ```dart
/// @Entity()
/// class Order {
///   @Id()
///   String? id;
///
///   @ManyToOne(targetEntity: ClassType<Customer>(), joinColumn: 'customer_id')
///   Customer? customer;
/// }
/// ```
///
/// ### See Also
/// - [OneToMany]
/// - [RelationshipAnnotation]
/// {@endtemplate}
@Target({TargetKind.field})
final class ManyToOne extends RelationshipAnnotation {
  /// Reflective [Class] handle for [ManyToOne].
  static final Class<ManyToOne> CLASS = Class<ManyToOne>(null, PackageNames.DATA);

  /// Whether the association may be `null`.
  final bool optional;

  /// {@macro jetleaf_many_to_one_annotation}
  const ManyToOne({
    super.targetEntity,
    super.mappedBy,
    super.cascade = const [],
    super.fetch = FetchType.eager,
    super.joinColumn,
    this.optional = true,
  });

  @override
  Type get annotationType => ManyToOne;

  @override
  List<Object?> equalizedProperties() => [
    targetEntity,
    mappedBy,
    cascade,
    fetch,
    joinColumn,
    optional,
  ];
}

/// {@template jetleaf_many_to_many_annotation}
/// Declares a **many-to-many** association backed by a join table.
///
/// ### Usage Example
/// ```dart
/// @Entity()
/// class User {
///   @Id()
///   String? id;
///
///   @ManyToMany(
///     targetEntity: ClassType<Role>(),
///     joinTable: 'user_roles',
///     joinColumn: 'user_id',
///     inverseJoinColumn: 'role_id',
///   )
///   List<Role> roles = [];
/// }
/// ```
///
/// ### See Also
/// - [RelationshipAnnotation]
/// {@endtemplate}
@Target({TargetKind.field})
final class ManyToMany extends RelationshipAnnotation {
  /// Reflective [Class] handle for [ManyToMany].
  static final Class<ManyToMany> CLASS = Class<ManyToMany>(null, PackageNames.DATA);

  /// Name of the intermediate join table.
  final String? joinTable;

  /// Foreign key column in the join table referencing the target entity.
  final String? inverseJoinColumn;

  /// {@macro jetleaf_many_to_many_annotation}
  const ManyToMany({
    super.targetEntity,
    super.mappedBy,
    super.cascade = const [],
    super.fetch = FetchType.lazy,
    super.joinColumn,
    this.joinTable,
    this.inverseJoinColumn,
  });

  @override
  Type get annotationType => ManyToMany;

  @override
  List<Object?> equalizedProperties() => [
    targetEntity,
    mappedBy,
    cascade,
    fetch,
    joinColumn,
    joinTable,
    inverseJoinColumn,
  ];
}