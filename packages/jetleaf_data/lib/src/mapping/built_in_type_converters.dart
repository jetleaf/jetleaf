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

import '../exception/data_access_exception.dart';
import 'type_converter.dart';

/// {@template jetleaf_bool_converter}
/// [TypeConverter] mapping Dart [bool] attributes to `1`/`0` integer values
/// and restoring them from `bool`, `int` (`0`/`1`), or `String`
/// (`'true'`, `'1'`, `'t'`, `'yes'`).
/// {@endtemplate}
final class BoolConverter extends BaseTypeConverter {
  /// Reflective [Class] handle for [BoolConverter].
  static final Class<BoolConverter> CLASS = Class<BoolConverter>(null, PackageNames.DATA);

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
      _ => throw EntityMappingException('Cannot map value $value (${value.runtimeType}) to bool'),
    };
  }
}

/// {@template jetleaf_date_time_converter}
/// [TypeConverter] mapping Dart [DateTime] attributes to UTC ISO-8601 strings
/// and restoring them from [DateTime], epoch milliseconds [int], or ISO-8601
/// [String].
/// {@endtemplate}
final class DateTimeConverter extends BaseTypeConverter {
  /// Reflective [Class] handle for [DateTimeConverter].
  static final Class<DateTimeConverter> CLASS = Class<DateTimeConverter>(null, PackageNames.DATA);

  /// {@macro jetleaf_date_time_converter}
  const DateTimeConverter();

  @override
  bool canConvertToColumn(Type attributeType) => attributeType == DateTime;

  @override
  Object? toColumn(Object? value) {
    if (value == null) return null;
    if (value is! DateTime) {
      throw EntityMappingException('DateTimeConverter can only write DateTime, got ${value.runtimeType}');
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
      _ => throw EntityMappingException('Cannot map value $value (${value.runtimeType}) to DateTime'),
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

/// {@template jetleaf_enum_converter}
/// [TypeConverter] mapping Dart [Enum] values to their constant name [String]
/// and restoring them via JetLeaf's materialized reflection registry.
/// {@endtemplate}
final class EnumConverter extends BaseTypeConverter {
  /// Reflective [Class] handle for [EnumConverter].
  static final Class<EnumConverter> CLASS = Class<EnumConverter>(null, PackageNames.DATA);

  static final Map<Type, bool> _enumCache = <Type, bool>{};

  /// {@macro jetleaf_enum_converter}
  const EnumConverter();

  @override
  bool canConvertToColumn(Type attributeType) => _isEnumType(attributeType);

  @override
  Object? toColumn(Object? value) {
    if (value == null) return null;
    if (value is! Enum) {
      throw EntityMappingException('EnumConverter can only write Enum, got ${value.runtimeType}');
    }
    return value.name;
  }

  @override
  Object? fromColumn(Object? value, Type attributeType) {
    if (value == null) return null;
    if (value.runtimeType == attributeType) return value;

    final name = value.toString();
    final directResolved = MaterializedLibrary.resolveEnumValue('$attributeType.$name') ??
      MaterializedLibrary.constructByName('$attributeType.$name');
    if (directResolved != null) {
      return directResolved;
    }

    try {
      final classRef = Class.forName<Enum>(attributeType.toString());
      for (final entry in classRef.getEnumValues()) {
        if (entry.getName() == name) {
          return entry.getValue();
        }
      }
    } on Object {
      // Fall through to descriptive mapping exception.
    }

    throw EntityMappingException('Cannot map "$name" to enum $attributeType — ensure the enum is registered with `jl build`');
  }

  static bool _isEnumType(Type type) {
    if (type == Enum) return true;
    return _enumCache.putIfAbsent(type, () => _checkEnum(type));
  }

  static bool _checkEnum(Type type) {
    try {
      return Class.forName<Enum>(type.toString()).isEnum();
    } catch (_) {
      return false;
    }
  }
}

/// {@template jetleaf_identity_converter}
/// Fallback [TypeConverter] that passes attribute and column values through
/// unchanged when no specialized converter matches.
/// {@endtemplate}
final class IdentityConverter extends BaseTypeConverter {
  /// Reflective [Class] handle for [IdentityConverter].
  static final Class<IdentityConverter> CLASS = Class<IdentityConverter>(null, PackageNames.DATA);

  /// {@macro jetleaf_identity_converter}
  const IdentityConverter();

  @override
  bool canConvertToColumn(Type attributeType) => true;

  @override
  Object? toColumn(Object? value) => value;

  @override
  Object? fromColumn(Object? value, Type attributeType) => value;
}

/// {@template jetleaf_number_converter}
/// [TypeConverter] normalizing numeric representations ([int], [double], [num],
/// or numeric [String]) returned by database drivers into the declared field
/// type.
/// {@endtemplate}
final class NumberConverter extends BaseTypeConverter {
  /// Reflective [Class] handle for [NumberConverter].
  static final Class<NumberConverter> CLASS = Class<NumberConverter>(null, PackageNames.DATA);

  /// {@macro jetleaf_number_converter}
  const NumberConverter();

  @override
  bool canConvertToColumn(Type attributeType) => attributeType == int || attributeType == double || attributeType == num;

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

    throw EntityMappingException('Cannot map value $value (${value.runtimeType}) to $attributeType');
  }
}