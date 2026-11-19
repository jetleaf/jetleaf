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
