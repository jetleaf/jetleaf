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
