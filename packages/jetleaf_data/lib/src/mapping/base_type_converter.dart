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

/// {@template jetleaf_base_type_converter}
/// Abstract skeletal implementation of [TypeConverter] for symmetric converters
/// that handle the same [Type] in both directions.
/// {@endtemplate}
abstract class BaseTypeConverter with EqualsAndHashCode implements TypeConverter {
  /// {@macro jetleaf_base_type_converter}
  const BaseTypeConverter();

  @override
  bool canConvertToColumn(Type attributeType);

  @override
  bool canConvertFromColumn(Type attributeType) =>
      canConvertToColumn(attributeType);

  @override
  List<Object?> equalizedProperties() => [runtimeType];
}
