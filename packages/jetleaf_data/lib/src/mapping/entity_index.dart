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

/// {@template jetleaf_entity_index}
/// Immutable metadata descriptor representing a **physical database index**
/// declared on an `@Entity` via `@Index` or `@Indexes`.
///
/// ### Usage Example
/// ```dart
/// const index = EntityIndex(
///   name: 'idx_users_email',
///   columnList: 'email',
///   unique: true,
/// );
/// print(index.getName()); // "idx_users_email"
/// print(index.isUnique()); // true
/// ```
///
/// ### See Also
/// - `Index`
/// - `Indexes`
/// - `EntityMetadata`
/// {@endtemplate}
final class EntityIndex with EqualsAndHashCode {
  /// Reflective [Class] handle for [EntityIndex].
  static final Class<EntityIndex> CLASS = Class<EntityIndex>(null, PackageNames.DATA);

  final String _name;
  final String _columnList;
  final bool _unique;

  /// {@macro jetleaf_entity_index}
  const EntityIndex({
    required String name,
    required String columnList,
    bool unique = false,
  })  : _name = name,
        _columnList = columnList,
        _unique = unique;

  /// Returns the resolved physical index name.
  String getName() => _name;

  /// Returns the comma-separated column specification.
  String getColumnList() => _columnList;

  /// Returns `true` if the index enforces a `UNIQUE` constraint.
  bool isUnique() => _unique;

  @override
  List<Object?> equalizedProperties() => [_name, _columnList, _unique];
}
