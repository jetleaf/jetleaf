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

/// {@template jetleaf_date_time_converter}
/// [TypeConverter] mapping Dart [DateTime] attributes to UTC ISO-8601 strings
/// and restoring them from [DateTime], epoch milliseconds [int], or ISO-8601
/// [String].
/// {@endtemplate}
final class DateTimeConverter extends BaseTypeConverter {
  /// Reflective [Class] handle for [DateTimeConverter].
  static final Class<DateTimeConverter> CLASS =
      Class<DateTimeConverter>(null, PackageNames.DATA);

  /// {@macro jetleaf_date_time_converter}
  const DateTimeConverter();

  @override
  bool canConvertToColumn(Type attributeType) => attributeType == DateTime;

  @override
  Object? toColumn(Object? value) {
    if (value == null) return null;
    if (value is! DateTime) {
      throw EntityMappingException(
        'DateTimeConverter can only write DateTime, got ${value.runtimeType}',
      );
    }
    return value.toUtc().toIso8601String();
  }

  @override
  Object? fromColumn(Object? value, Type attributeType) {
    return switch (value) {
      null => null,
      DateTime dt => dt.toLocal(),
      int millis =>
        DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal(),
      String s when s.isEmpty => null,
      String s => _parse(s),
      _ => throw EntityMappingException(
          'Cannot map value $value (${value.runtimeType}) to DateTime',
        ),
    };
  }

  static DateTime _parse(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;

    final millis = int.tryParse(value);
    if (millis != null) {
      return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal();
    }

    throw EntityMappingException('Cannot parse "$value" as a DateTime');
  }
}
