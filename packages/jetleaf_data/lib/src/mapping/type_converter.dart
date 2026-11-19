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

import 'base_type_converter.dart';
import 'default_type_converter_registry.dart';
import 'type_converter_registry.dart';

export 'base_type_converter.dart';
export 'converters/bool_type_converter.dart';
export 'converters/date_time_type_converter.dart';
export 'converters/enum_type_converter.dart';
export 'converters/identity_type_converter.dart';
export 'converters/number_type_converter.dart';
export 'default_type_converter_registry.dart';
export 'type_converter_registry.dart';

/// {@template jetleaf_type_converter}
/// Contract for bidirectional conversion between **Dart entity attribute
/// values** and **database column or document representations**.
///
/// ### See Also
/// - [BaseTypeConverter]
/// - [TypeConverterRegistry]
/// - [DefaultTypeConverterRegistry]
/// {@endtemplate}
abstract interface class TypeConverter {
  /// Reflective [Class] handle for [TypeConverter].
  static final Class<TypeConverter> CLASS =
      Class<TypeConverter>(null, PackageNames.DATA);

  /// Returns `true` if this converter supports serializing [attributeType]
  /// into a database column/document value.
  bool canConvertToColumn(Type attributeType);

  /// Returns `true` if this converter supports deserializing a database
  /// column/document value into [attributeType].
  bool canConvertFromColumn(Type attributeType);

  /// Converts an entity attribute [value] into its database representation.
  Object? toColumn(Object? value);

  /// Converts a database column/document [value] into the target
  /// [attributeType].
  Object? fromColumn(Object? value, Type attributeType);
}
