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

import 'type_converter.dart';

/// {@template jetleaf_type_converter_registry}
/// Read-only registry contract for resolving [TypeConverter] instances and
/// converting values between entity attributes and database columns/documents.
///
/// ### See Also
/// - [ConfigurableTypeConverterRegistry]
/// - [DefaultTypeConverterRegistry]
/// - [TypeConverter]
/// {@endtemplate}
abstract interface class TypeConverterRegistry {
  /// Reflective [Class] handle for [TypeConverterRegistry].
  static final Class<TypeConverterRegistry> CLASS =
      Class<TypeConverterRegistry>(null, PackageNames.DATA);

  /// Shared default [DefaultTypeConverterRegistry] instance.
  static final DefaultTypeConverterRegistry instance =
      DefaultTypeConverterRegistry.instance;

  /// Returns the shared default [DefaultTypeConverterRegistry] instance.
  static DefaultTypeConverterRegistry getSharedInstance() =>
      DefaultTypeConverterRegistry.getSharedInstance();

  /// Creates a new [DefaultTypeConverterRegistry] with [converters].
  factory TypeConverterRegistry([List<TypeConverter> converters]) =
      DefaultTypeConverterRegistry;

  /// Creates a new [DefaultTypeConverterRegistry] pre-populated with the
  /// built-in converter chain.
  factory TypeConverterRegistry.defaults() =
      DefaultTypeConverterRegistry.defaults;

  /// Returns an unmodifiable view of all registered [TypeConverter] instances
  /// in priority order.
  List<TypeConverter> getConverters();

  /// Registers [converter] in this registry.
  void register(TypeConverter converter, {bool append = false});

  /// Converts an entity attribute [value] of [attributeType] into its column
  /// or document representation.
  Object? toColumn(Object? value, Type attributeType);

  /// Converts a column or document [value] back into [attributeType].
  Object? fromColumn(Object? value, Type attributeType);
}

/// {@template jetleaf_configurable_type_converter_registry}
/// Configurable extension of [TypeConverterRegistry] allowing dynamic
/// registration and removal of [TypeConverter] instances.
/// {@endtemplate}
abstract interface class ConfigurableTypeConverterRegistry
    implements TypeConverterRegistry {
  /// Reflective [Class] handle for [ConfigurableTypeConverterRegistry].
  static final Class<ConfigurableTypeConverterRegistry> CLASS =
      Class<ConfigurableTypeConverterRegistry>(null, PackageNames.DATA);

  /// Removes all registered converters.
  void clear();
}
