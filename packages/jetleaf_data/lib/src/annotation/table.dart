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

/// {@template jetleaf_table_annotation}
/// Specifies the **physical table or collection placement** of an `@Entity`.
///
/// Complements [Entity] by carrying physical storage coordinates including
/// the table [name], database [catalog], and [schema].
///
/// ### Usage Example
/// ```dart
/// @Entity()
/// @Table(name: 'users', schema: 'public')
/// class User {
///   @Id()
///   String? id;
/// }
/// ```
///
/// ### See Also
/// - [Entity]
/// - [Index]
/// - [Indexes]
/// {@endtemplate}
@Target({TargetKind.classType})
final class Table extends ReflectableAnnotation with EqualsAndHashCode {
  /// Reflective [Class] handle for [Table].
  static final Class<Table> CLASS = Class<Table>(null, PackageNames.DATA);

  /// The physical table or collection name.
  final String? name;

  /// Optional database catalog qualifier.
  final String? catalog;

  /// Optional database schema qualifier.
  final String? schema;

  /// {@macro jetleaf_table_annotation}
  const Table({this.name, this.catalog, this.schema});

  /// Returns the physical table or collection name, if specified.
  String? getName() => name;

  /// Returns the database catalog qualifier, if specified.
  String? getCatalog() => catalog;

  /// Returns the database schema qualifier, if specified.
  String? getSchema() => schema;

  @override
  Type get annotationType => Table;

  @override
  List<Object?> equalizedProperties() => [name, catalog, schema];
}
