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

import '../../exception/data_access_exception.dart';
import '../base_type_converter.dart';

/// {@template jetleaf_number_converter}
/// [TypeConverter] normalizing numeric representations ([int], [double], [num],
/// or numeric [String]) returned by database drivers into the declared field
/// type.
/// {@endtemplate}
final class NumberConverter extends BaseTypeConverter {
  /// Reflective [Class] handle for [NumberConverter].
  static final Class<NumberConverter> CLASS =
      Class<NumberConverter>(null, PackageNames.DATA);

  /// {@macro jetleaf_number_converter}
  const NumberConverter();

  @override
  bool canConvertToColumn(Type attributeType) =>
      attributeType == int || attributeType == double || attributeType == num;

  @override
  Object? toColumn(Object? value) => value;

  @override
  Object? fromColumn(Object? value, Type attributeType) {
    if (value == null) return null;

    if (value is num) {
      if (attributeType == int && value is double) return value.toInt();
      if (attributeType == double && value is int) return value.toDouble();
      return value;
    }

    if (value is String) {
      if (attributeType == int) {
        return int.tryParse(value) ?? double.tryParse(value)?.toInt();
      }
      if (attributeType == double) {
        return double.tryParse(value);
      }
      return num.tryParse(value);
    }

    throw EntityMappingException(
      'Cannot map value $value (${value.runtimeType}) to $attributeType',
    );
  }
}
