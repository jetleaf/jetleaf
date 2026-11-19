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

import '../core/configurable_repository_context.dart';
import '../dialect/dialect_registry.dart';
import '../mapping/entity_metadata_registry.dart';
import '../mapping/type_converter_registry.dart';

/// {@template jetleaf_data_configurer}
/// Abstract extension point for customizing the JetLeaf Data subsystem at
/// application startup.
///
/// Applications or driver plugins implement or extend [DataConfigurer] and
/// register it as a pod to:
/// - Register custom [DatabaseDialect]s in the [DialectRegistry]
/// - Register custom [TypeConverter]s in the [TypeConverterRegistry]
/// - Pre-register or customize [EntityMetadata] in the [EntityMetadataRegistry]
/// - Customize the [ConfigurableRepositoryContext]
///
/// ### Usage Example
/// ```dart
/// @Service()
/// class CustomDataConfigurer extends DataConfigurer {
///   @override
///   void configureTypeConverters(TypeConverterRegistry registry) {
///     registry.register<Money, int>(const MoneyCentsConverter());
///   }
///
///   @override
///   void configureDialects(DialectRegistry registry) {
///     registry.register(const PostgreSqlDialect(), aliases: ['pg']);
///   }
/// }
/// ```
/// {@endtemplate}
abstract class DataConfigurer {
  /// Reflective class descriptor for [DataConfigurer].
  static final Class<DataConfigurer> CLASS =
      Class<DataConfigurer>(null, PackageNames.DATA);

  /// {@macro jetleaf_data_configurer}
  const DataConfigurer();

  /// Hook for registering or overriding database dialects in [registry].
  void configureDialects(DialectRegistry registry) {}

  /// Hook for registering custom attribute ↔ column type converters in [registry].
  void configureTypeConverters(TypeConverterRegistry registry) {}

  /// Hook for pre-registering or inspecting entity metadata in [registry].
  void configureEntityMetadata(EntityMetadataRegistry registry) {}

  /// Hook for customizing the [ConfigurableRepositoryContext].
  void configureRepositoryContext(ConfigurableRepositoryContext context) {}
}
