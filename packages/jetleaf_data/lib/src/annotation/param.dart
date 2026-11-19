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

/// {@template jetleaf_param_annotation}
/// Binds a repository method parameter to a **named query parameter** (`:name`)
/// inside a `@Query` statement.
///
/// ### Usage Example
/// ```dart
/// @Query('SELECT u FROM User u WHERE u.role = :role')
/// Future<List<User>> findByRole(@Param('role') String role);
/// ```
///
/// ### See Also
/// - [Query]
/// - [Modifying]
/// {@endtemplate}
@Target({TargetKind.parameter})
final class Param extends ReflectableAnnotation with EqualsAndHashCode {
  /// Reflective [Class] handle for [Param].
  static final Class<Param> CLASS = Class<Param>(null, PackageNames.DATA);

  /// The placeholder parameter name referenced in the query (`:name`).
  final String name;

  /// {@macro jetleaf_param_annotation}
  const Param(this.name);

  /// Returns the bound parameter name.
  String getName() => name;

  @override
  Type get annotationType => Param;

  @override
  List<Object?> equalizedProperties() => [name];
}
