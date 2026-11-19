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

  /// Returns `true` if the association is optional (nullable).
  bool isOptional() => optional;

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
