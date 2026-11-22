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

/// {@template jetleaf_index_annotation}
/// Declares a **database index** on one or more columns of an `@Entity` table
/// or collection.
///
/// Multiple indexes can be declared on a single entity using [Indexes].
///
/// ### Usage Example
/// ```dart
/// @Entity()
/// @Index(columnList: 'email', unique: true)
/// class User {
///   @Id()
///   String? id;
///
///   String? email;
/// }
/// ```
///
/// ### See Also
/// - [Indexes]
/// - [Table]
/// {@endtemplate}
@Target({TargetKind.classType})
final class Index extends ReflectableAnnotation with EqualsAndHashCode {
  /// Reflective [Class] handle for [Index].
  static final Class<Index> CLASS = Class<Index>(null, PackageNames.DATA);

  /// Optional explicit index name.
  final String? name;

  /// Comma-separated list of indexed columns (e.g. `'last_name, first_name DESC'`).
  final String columnList;

  /// Whether the index enforces uniqueness.
  final bool unique;

  /// {@macro jetleaf_index_annotation}
  const Index({this.name, required this.columnList, this.unique = false})
    : assert(columnList.length > 0, 'columnList must not be empty');

  /// Computes the effective index name for [tableName], deriving
  /// `idx_{table}_{columns}` when [name] is omitted.
  String getEffectiveName(String tableName) {
    final explicit = name;
    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }

    final normalized = columnList
      .split(',')
      .map((column) => column.trim().split(' ').first.trim())
      .where((column) => column.isNotEmpty)
      .join('_')
      .replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_')
      .toLowerCase();

    return 'idx_${tableName}_$normalized';
  }

  /// Alias for [getEffectiveName].
  String effectiveName(String tableName) => getEffectiveName(tableName);

  @override
  Type get annotationType => Index;

  @override
  List<Object?> equalizedProperties() => [name, columnList, unique];
}

/// {@template jetleaf_indexes_annotation}
/// Container annotation that declares multiple [Index] definitions on an
/// `@Entity` class.
///
/// ### Usage Example
/// ```dart
/// @Entity()
/// @Indexes([
///   Index(columnList: 'email', unique: true),
///   Index(name: 'idx_users_name', columnList: 'last_name, first_name'),
/// ])
/// class User {
///   @Id()
///   String? id;
/// }
/// ```
///
/// ### See Also
/// - [Index]
/// - [Entity]
/// {@endtemplate}
@Target({TargetKind.classType})
final class Indexes extends ReflectableAnnotation with EqualsAndHashCode {
  /// Reflective [Class] handle for [Indexes].
  static final Class<Indexes> CLASS = Class<Indexes>(null, PackageNames.DATA);

  /// The list of [Index] definitions declared on the entity.
  final List<Index> indexes;

  /// {@macro jetleaf_indexes_annotation}
  const Indexes(this.indexes);

  @override
  Type get annotationType => Indexes;

  @override
  List<Object?> equalizedProperties() => [indexes];
}