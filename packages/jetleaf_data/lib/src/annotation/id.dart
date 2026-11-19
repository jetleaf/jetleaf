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

/// {@template jetleaf_id_annotation}
/// Marks a field as the **primary key identifier** of an `@Entity`.
///
/// Every persistent entity must declare an `@Id` field (either directly or
/// inherited from a superclass). When paired with `@GeneratedValue`, the
/// identifier value is automatically generated for newly inserted entities.
///
/// ### Usage Example
/// ```dart
/// @Entity()
/// class User {
///   @Id()
///   String? id;
/// }
/// ```
///
/// ### See Also
/// - [GeneratedValue]
/// - [Entity]
/// {@endtemplate}
@Target({TargetKind.field})
final class Id extends ReflectableAnnotation with EqualsAndHashCode {
  /// Reflective [Class] handle for [Id].
  static final Class<Id> CLASS = Class<Id>(null, PackageNames.DATA);

  /// {@macro jetleaf_id_annotation}
  const Id();

  @override
  Type get annotationType => Id;

  @override
  List<Object?> equalizedProperties() => [Id];
}
