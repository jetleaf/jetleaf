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

import '../base_type_converter.dart';

/// {@template jetleaf_identity_converter}
/// Fallback [TypeConverter] that passes attribute and column values through
/// unchanged when no specialized converter matches.
/// {@endtemplate}
final class IdentityConverter extends BaseTypeConverter {
  /// Reflective [Class] handle for [IdentityConverter].
  static final Class<IdentityConverter> CLASS =
      Class<IdentityConverter>(null, PackageNames.DATA);

  /// {@macro jetleaf_identity_converter}
  const IdentityConverter();

  @override
  bool canConvertToColumn(Type attributeType) => true;

  @override
  Object? toColumn(Object? value) => value;

  @override
  Object? fromColumn(Object? value, Type attributeType) => value;
}
