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

import 'index.dart';

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

  /// Returns the list of [Index] definitions.
  List<Index> getIndexes() => indexes;

  @override
  Type get annotationType => Indexes;

  @override
  List<Object?> equalizedProperties() => [indexes];
}
