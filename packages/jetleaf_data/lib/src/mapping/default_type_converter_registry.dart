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

import 'built_in_type_converters.dart';
import 'type_converter.dart';
import 'type_converter_registry.dart';

/// {@template jetleaf_default_type_converter_registry}
/// Default synchronized implementation of [ConfigurableTypeConverterRegistry]
/// backed by an ordered priority list of [TypeConverter] instances.
///
/// ### Usage Example
/// ```dart
/// final registry = DefaultTypeConverterRegistry.defaults();
/// final isoString = registry.toColumn(DateTime.now(), DateTime);
/// ```
/// {@endtemplate}
final class DefaultTypeConverterRegistry with EqualsAndHashCode implements ConfigurableTypeConverterRegistry {
  /// Reflective [Class] handle for [DefaultTypeConverterRegistry].
  static final Class<DefaultTypeConverterRegistry> CLASS = Class<DefaultTypeConverterRegistry>(null, PackageNames.DATA);

  /// Process-wide shared default registry instance.
  static final DefaultTypeConverterRegistry instance = DefaultTypeConverterRegistry.defaults();

  /// Returns the process-wide shared default registry instance.
  static DefaultTypeConverterRegistry getSharedInstance() => instance;

  final List<TypeConverter> _converters;

  /// {@macro jetleaf_default_type_converter_registry}
  DefaultTypeConverterRegistry([List<TypeConverter> converters = const []])
      : _converters = List.of(converters);

  /// Creates a registry pre-populated with the built-in converters
  /// ([BoolConverter], [DateTimeConverter], [EnumConverter], [NumberConverter],
  /// and [IdentityConverter]).
  factory DefaultTypeConverterRegistry.defaults() => DefaultTypeConverterRegistry([
    const BoolConverter(),
    const DateTimeConverter(),
    const EnumConverter(),
    const NumberConverter(),
    const IdentityConverter(),
  ]);

  @override
  List<TypeConverter> getConverters() => synchronized(_converters, () => List.unmodifiable(_converters));

  @override
  void register(TypeConverter converter, {bool append = false}) {
    synchronized(_converters, () {
      if (append) {
        _converters.add(converter);
      } else {
        _converters.insert(0, converter);
      }
    });
  }

  @override
  void clear() {
    synchronized(_converters, _converters.clear);
  }

  @override
  Object? toColumn(Object? value, Type attributeType) {
    if (value == null) return null;

    return synchronized(_converters, () {
      for (final converter in _converters) {
        if (converter.canConvertToColumn(attributeType)) {
          return converter.toColumn(value);
        }
      }
      return value;
    });
  }

  @override
  Object? fromColumn(Object? value, Type attributeType) {
    if (value == null) return null;

    return synchronized(_converters, () {
      for (final converter in _converters) {
        if (converter.canConvertFromColumn(attributeType)) {
          return converter.fromColumn(value, attributeType);
        }
      }
      return value;
    });
  }

  @override
  List<Object?> equalizedProperties() => [_converters, runtimeType];
}