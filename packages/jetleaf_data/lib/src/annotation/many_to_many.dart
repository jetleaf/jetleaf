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

import 'fetch_type.dart';
import 'relationship_annotation.dart';

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

  /// Returns the intermediate join table name, if specified.
  String? getJoinTable() => joinTable;

  /// Returns the target-side join column name, if specified.
  String? getInverseJoinColumn() => inverseJoinColumn;

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
