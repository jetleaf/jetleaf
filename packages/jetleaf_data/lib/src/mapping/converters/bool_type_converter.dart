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

/// {@template jetleaf_bool_converter}
/// [TypeConverter] mapping Dart [bool] attributes to `1`/`0` integer values
/// and restoring them from `bool`, `int` (`0`/`1`), or `String`
/// (`'true'`, `'1'`, `'t'`, `'yes'`).
/// {@endtemplate}
final class BoolConverter extends BaseTypeConverter {
  /// Reflective [Class] handle for [BoolConverter].
  static final Class<BoolConverter> CLASS =
      Class<BoolConverter>(null, PackageNames.DATA);

  /// {@macro jetleaf_bool_converter}
  const BoolConverter();

  @override
  bool canConvertToColumn(Type attributeType) => attributeType == bool;

  @override
  Object? toColumn(Object? value) {
    if (value == null) return null;
    return value == true ? 1 : 0;
  }

  @override
  Object? fromColumn(Object? value, Type attributeType) {
    return switch (value) {
      null => null,
      bool b => b,
      int i => i != 0,
      String s => s.toLowerCase() == 'true' ||
          s == '1' ||
          s.toLowerCase() == 't' ||
          s.toLowerCase() == 'yes',
      _ => throw EntityMappingException(
          'Cannot map value $value (${value.runtimeType}) to bool',
        ),
    };
  }
}
