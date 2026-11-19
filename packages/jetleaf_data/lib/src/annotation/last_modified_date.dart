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

/// {@template jetleaf_last_modified_date_annotation}
/// Marks a field as the **last modification timestamp** of a persistent entity.
///
/// Fields annotated with [LastModifiedDate] are automatically updated with
/// `DateTime.now()` on both initial entity insertion and every subsequent
/// update executed through the repository layer.
///
/// ### Features
/// - Automatically populated on `INSERT` and refreshed on every `UPDATE`.
/// - Integrates with [TypeConverterRegistry] for seamless serialization to
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
