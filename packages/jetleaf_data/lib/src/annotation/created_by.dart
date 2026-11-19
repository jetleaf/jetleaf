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

/// {@template jetleaf_created_by_annotation}
/// Marks a field as the **creator principal identifier** of a persistent entity.
///
/// When an `AuditorAware` pod is registered in the application context, fields
/// annotated with [CreatedBy] are automatically populated with the current
/// auditor when a new entity is inserted.
///
/// ### Features
/// - Decouples entity auditing from security libraries via `AuditorAware`.
/// - Preserves any explicitly assigned creator identifier on insert.
///
/// ### Usage Example
/// ```dart
/// @Entity()
/// class DocumentRecord {
///   @Id()
///   String? id;
///
///   @CreatedBy()
///   String? createdBy;
/// }
/// ```
///
/// ### See Also
/// - [LastModifiedBy]
/// - [CreatedDate]
/// {@endtemplate}
@Target({TargetKind.field})
final class CreatedBy extends ReflectableAnnotation with EqualsAndHashCode {
  /// Reflective [Class] handle for [CreatedBy].
  static final Class<CreatedBy> CLASS = Class<CreatedBy>(null, PackageNames.DATA);

  /// {@macro jetleaf_created_by_annotation}
  const CreatedBy();

  @override
  Type get annotationType => CreatedBy;

  @override
  List<Object?> equalizedProperties() => [CreatedBy];
}
