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

/// {@template jetleaf_modifying_annotation}
/// Marks a `@Query` repository method as a **data-modifying statement**
/// (`UPDATE`, `DELETE`, or `INSERT`).
///
/// Modifying queries execute via `DatabaseClient.execute` and return either
/// the affected row count (`Future<int>`) or `Future<void>`.
///
/// ### Usage Example
/// ```dart
/// @Modifying()
/// @Query('UPDATE User u SET u.active = false WHERE u.age < :minAge')
/// Future<int> deactivateUnderage(@Param('minAge') int minAge);
/// ```
///
/// ### See Also
/// - [Query]
/// - [Param]
/// {@endtemplate}
@Target({TargetKind.method})
final class Modifying extends ReflectableAnnotation with EqualsAndHashCode {
  /// Reflective [Class] handle for [Modifying].
  static final Class<Modifying> CLASS = Class<Modifying>(null, PackageNames.DATA);

  /// Whether the persistence context should be cleared automatically after
  /// executing the modifying statement.
  final bool clearAutomatically;

  /// {@macro jetleaf_modifying_annotation}
  const Modifying({this.clearAutomatically = false});

  /// Returns `true` if the persistence context should be cleared after
  /// execution.
  bool shouldClearAutomatically() => clearAutomatically;

  @override
  Type get annotationType => Modifying;

  @override
  List<Object?> equalizedProperties() => [clearAutomatically];
}
