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

import 'modifying.dart';
import 'param.dart';

export 'modifying.dart';
export 'param.dart';

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

  /// Returns the declared query statement.
  String getValue() => value;

  /// Returns `true` if [value] is a native query.
  bool isNativeQuery() => nativeQuery;

  @override
  Type get annotationType => Query;

  @override
  List<Object?> equalizedProperties() => [value, nativeQuery];
}
