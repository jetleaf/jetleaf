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

import 'relationship_annotation.dart';

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

  /// Returns `true` if the association is optional (nullable).
  bool isOptional() => optional;

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
