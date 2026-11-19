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

/// {@template jetleaf_entity_annotation}
/// Marks a class as a **persistent domain entity** mapped to a relational
/// table or document store collection.
///
/// ### Features
/// - Identifies the class for metadata extraction by `EntityMetadataBuilder`.
/// - Participates in automatic DDL generation via `SchemaGenerator`.
/// - Supports optional explicit table/collection naming via [tableName].
///
/// ### Usage Example
/// ```dart
/// @Entity()
/// class User {
///   @Id()
///   String? id;
///
///   String? email;
/// }
/// ```
///
/// ### Design Notes
/// - Every `@Entity` class must declare an `@Id` field (directly or in a
///   superclass) and provide a zero-argument constructor for row hydration.
/// - Can be combined with `@Table` for catalog and schema placement.
///
/// ### See Also
/// - [Table]
/// - [Id]
/// - [Column]
/// {@endtemplate}
@Target({TargetKind.classType})
final class Entity extends ReflectableAnnotation with EqualsAndHashCode {
  /// Reflective [Class] handle for [Entity].
  static final Class<Entity> CLASS = Class<Entity>(null, PackageNames.DATA);

  /// Optional explicit table or collection name.
  final String? tableName;

  /// {@macro jetleaf_entity_annotation}
  const Entity({this.tableName});

  /// Returns the explicit table or collection name, or `null` if the configured
  /// naming strategy should derive it from the class simple name.
  String? getTableName() => tableName;

  @override
  Type get annotationType => Entity;

  @override
  List<Object?> equalizedProperties() => [tableName];
}
