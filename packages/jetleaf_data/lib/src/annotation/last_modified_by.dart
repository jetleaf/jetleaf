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

/// {@template jetleaf_last_modified_by_annotation}
/// Marks a field as the **last modifier principal identifier** of a persistent
/// entity.
///
/// When an `AuditorAware` pod is registered in the application context, fields
/// annotated with [LastModifiedBy] are automatically populated on insert and
/// updated on every save of an existing entity.
///
/// ### Usage Example
/// ```dart
/// @Entity()
/// class DocumentRecord {
///   @Id()
///   String? id;
///
///   @LastModifiedBy()
///   String? updatedBy;
/// }
/// ```
///
/// ### See Also
/// - [CreatedBy]
/// - [LastModifiedDate]
/// {@endtemplate}
@Target({TargetKind.field})
final class LastModifiedBy extends ReflectableAnnotation with EqualsAndHashCode {
  /// Reflective [Class] handle for [LastModifiedBy].
  static final Class<LastModifiedBy> CLASS = Class<LastModifiedBy>(null, PackageNames.DATA);

  /// {@macro jetleaf_last_modified_by_annotation}
  const LastModifiedBy();

  @override
  Type get annotationType => LastModifiedBy;

  @override
  List<Object?> equalizedProperties() => [LastModifiedBy];
}
