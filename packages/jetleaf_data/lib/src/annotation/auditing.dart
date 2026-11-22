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

/// {@template jetleaf_last_modified_date_annotation}
/// Marks a field as the **last modification timestamp** of a persistent entity.
///
/// Fields annotated with [LastModifiedDate] are automatically updated with
/// `DateTime.now()` on both initial entity insertion and every subsequent
/// update executed through the repository layer.
///
/// ### Features
/// - Automatically populated on `INSERT` and refreshed on every `UPDATE`.
/// - Integrates with `TypeConverterRegistry` for seamless serialization to
///   SQL `TIMESTAMP` / `TEXT` or document `Date` representations.
///
/// ### Usage Example
/// ```dart
/// @Entity()
/// class User {
///   @Id()
///   String? id;
///
///   @CreatedDate()
///   DateTime? createdAt;
///
///   @LastModifiedDate()
///   DateTime? updatedAt;
/// }
/// ```
///
/// ### Design Notes
/// - The annotated field must be of type [DateTime].
///
/// ### See Also
/// - [CreatedDate]
/// - [LastModifiedBy]
/// - [DataVersion]
/// {@endtemplate}
@Target({TargetKind.field})
final class LastModifiedDate extends ReflectableAnnotation with EqualsAndHashCode {
  /// Reflective [Class] handle for [LastModifiedDate].
  static final Class<LastModifiedDate> CLASS = Class<LastModifiedDate>(null, PackageNames.DATA);

  /// {@macro jetleaf_last_modified_date_annotation}
  const LastModifiedDate();

  @override
  Type get annotationType => LastModifiedDate;

  @override
  List<Object?> equalizedProperties() => [LastModifiedDate];
}

/// {@template jetleaf_data_version_annotation}
/// Marks a field as the **optimistic lock version** of a persistent entity.
///
/// Named [DataVersion] to avoid symbol collisions with `Version` in
/// `jetleaf_core`. Every `UPDATE` or `DELETE` issued for an entity with a
/// [DataVersion] field appends `AND <version_column> = ?` to the statement
/// predicate and increments the version stored on the entity. When the
/// statement affects zero rows, an `OptimisticLockException` is thrown.
///
/// ### Features
/// - Initializes to `0` on insert when `null`.
/// - Automatically increments by `1` on each update.
/// - Guards against lost updates under concurrent transactions across both
///   SQL and document dialects.
///
/// ### Usage Example
/// ```dart
/// @Entity()
/// class Account {
///   @Id()
///   String? id;
///
///   @DataVersion()
///   int? version;
/// }
/// ```
///
/// ### Design Notes
/// - The annotated field must be of type [int].
///
/// ### See Also
/// - [CreatedDate]
/// - [LastModifiedDate]
/// {@endtemplate}
@Target({TargetKind.field})
final class DataVersion extends ReflectableAnnotation with EqualsAndHashCode {
  /// Reflective [Class] handle for [DataVersion].
  static final Class<DataVersion> CLASS = Class<DataVersion>(null, PackageNames.DATA);

  /// {@macro jetleaf_data_version_annotation}
  const DataVersion();

  @override
  Type get annotationType => DataVersion;

  @override
  List<Object?> equalizedProperties() => [DataVersion];
}