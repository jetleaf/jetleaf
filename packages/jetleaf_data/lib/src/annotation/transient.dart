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

/// {@template jetleaf_transient_annotation}
/// Excludes a field from **entity persistence mapping**.
///
/// Fields annotated with [Transient] are ignored by `EntityMetadataBuilder`,
/// never read from or written to the database, and omitted from DDL schema
/// generation.
///
/// ### Usage Example
/// ```dart
/// @Entity()
/// class User {
///   @Id()
///   String? id;
///
///   @Transient()
///   String? temporaryToken;
/// }
/// ```
///
/// ### See Also
/// - [Entity]
/// - [Column]
/// {@endtemplate}
@Target({TargetKind.field})
final class Transient extends ReflectableAnnotation with EqualsAndHashCode {
  /// Reflective [Class] handle for [Transient].
  static final Class<Transient> CLASS = Class<Transient>(null, PackageNames.DATA);

  /// {@macro jetleaf_transient_annotation}
  const Transient();

  @override
  Type get annotationType => Transient;

  @override
  List<Object?> equalizedProperties() => [Transient];
}
