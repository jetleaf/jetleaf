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

import 'generation_strategy.dart';

export 'generation_strategy.dart';

/// {@template jetleaf_generated_value_annotation}
/// Marks an `@Id` field as **automatically generated** by either the database
/// engine or the JetLeaf persistence runtime.
///
/// ### Usage Example
/// ```dart
/// @Entity()
/// class User {
///   @Id()
///   @GeneratedValue(strategy: GenerationStrategy.uuid)
///   String? id;
/// }
/// ```
///
/// ### See Also
/// - [Id]
/// - [GenerationStrategy]
/// {@endtemplate}
@Target({TargetKind.field})
final class GeneratedValue extends ReflectableAnnotation with EqualsAndHashCode {
  /// Reflective [Class] handle for [GeneratedValue].
  static final Class<GeneratedValue> CLASS = Class<GeneratedValue>(null, PackageNames.DATA);

  /// The identifier generation strategy.
  final GenerationStrategy strategy;

  /// {@macro jetleaf_generated_value_annotation}
  const GeneratedValue({this.strategy = GenerationStrategy.autoIncrement});

  /// Returns the configured [GenerationStrategy].
  GenerationStrategy getStrategy() => strategy;

  @override
  Type get annotationType => GeneratedValue;

  @override
  List<Object?> equalizedProperties() => [strategy];
}
