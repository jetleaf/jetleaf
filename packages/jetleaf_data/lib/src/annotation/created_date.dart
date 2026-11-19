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

/// {@template jetleaf_created_date_annotation}
/// Marks a field as the **creation timestamp** of a persistent entity.
///
/// Fields annotated with [CreatedDate] are populated automatically by the
/// repository infrastructure when a new entity instance is inserted into the
/// underlying data store.
///
/// ### Features
/// - Automatically stamps `DateTime.now()` on initial entity persistence.
/// - Preserves any pre-populated value already set on the entity before insert.
/// - Remains untouched during subsequent `UPDATE` operations unless explicitly
///   modified by application code.
///
/// ### Usage Example
/// ```dart
/// @Entity()
/// class AuditRecord {
///   @Id()
///   String? id;
///
///   @CreatedDate()
///   DateTime? createdAt;
/// }
/// ```
///
/// ### Design Notes
/// - The target field should be declared as [DateTime] (typically nullable
///   `DateTime?` so it can be omitted prior to persistence).
/// - Registered with [TargetKind.field] for reflective field inspection.
///
/// ### See Also
/// - [LastModifiedDate]
/// - [CreatedBy]
/// - [DataVersion]
/// {@endtemplate}
@Target({TargetKind.field})
final class CreatedDate extends ReflectableAnnotation with EqualsAndHashCode {
  /// Reflective [Class] handle for [CreatedDate].
  static final Class<CreatedDate> CLASS = Class<CreatedDate>(null, PackageNames.DATA);

  /// {@macro jetleaf_created_date_annotation}
  const CreatedDate();

  @override
  Type get annotationType => CreatedDate;

  @override
  List<Object?> equalizedProperties() => [CreatedDate];
}
