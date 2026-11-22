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

/// {@template jetleaf_query_annotation}
/// Attaches an explicit **native SQL or JetLeaf Query Language (JQL) statement**
/// to a repository method.
///
/// ### Features
/// - When [nativeQuery] is `true`, [value] is sent directly to the underlying
///   driver with `:name` parameter expansion.
/// - When [nativeQuery] is `false` (default), [value] is translated from
///   entity-centric JQL into the target dialect's SQL using `EntityMetadata`.
///
/// ### Usage Example
/// ```dart
/// @Query('SELECT u FROM User u WHERE u.email = :email')
/// Future<User?> findByEmail(@Param('email') String email);
/// ```
///
/// ### See Also
/// - [Param]
/// - [Modifying]
/// {@endtemplate}
@Target({TargetKind.method})
final class Query extends ReflectableAnnotation with EqualsAndHashCode {
  /// Reflective [Class] handle for [Query].
  static final Class<Query> CLASS = Class<Query>(null, PackageNames.DATA);

  /// The JQL or native SQL query string.
  final String value;

  /// Whether [value] is a native SQL query (`true`) or JQL query (`false`).
  final bool nativeQuery;

  /// {@macro jetleaf_query_annotation}
  const Query(this.value, {this.nativeQuery = false});

  @override
  Type get annotationType => Query;

  @override
  List<Object?> equalizedProperties() => [value, nativeQuery];
}

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

  @override
  Type get annotationType => Modifying;

  @override
  List<Object?> equalizedProperties() => [clearAutomatically];
}

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

  @override
  Type get annotationType => Param;

  @override
  List<Object?> equalizedProperties() => [name];
}