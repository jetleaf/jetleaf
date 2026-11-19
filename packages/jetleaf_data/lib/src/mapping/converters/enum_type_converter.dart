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

/// {@template jetleaf_enum_converter}
/// [TypeConverter] mapping Dart [Enum] values to their constant name [String]
/// and restoring them via JetLeaf's materialized reflection registry.
/// {@endtemplate}
final class EnumConverter extends BaseTypeConverter {
  /// Reflective [Class] handle for [EnumConverter].
  static final Class<EnumConverter> CLASS =
      Class<EnumConverter>(null, PackageNames.DATA);

  static final Map<Type, bool> _enumCache = <Type, bool>{};

  /// {@macro jetleaf_enum_converter}
  const EnumConverter();

  @override
  bool canConvertToColumn(Type attributeType) => _isEnumType(attributeType);

  @override
  Object? toColumn(Object? value) {
    if (value == null) return null;
    if (value is! Enum) {
      throw EntityMappingException(
        'EnumConverter can only write Enum, got ${value.runtimeType}',
      );
    }
    return value.name;
  }

  @override
  Object? fromColumn(Object? value, Type attributeType) {
    if (value == null) return null;
    if (value.runtimeType == attributeType) return value;

    final name = value.toString();
    final directResolved =
        MaterializedLibrary.resolveEnumValue('$attributeType.$name') ??
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

    throw EntityMappingException(
      'Cannot map "$name" to enum $attributeType — ensure the enum is registered with `jl build`',
    );
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
