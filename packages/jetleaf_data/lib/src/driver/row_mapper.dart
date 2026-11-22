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

/// {@template jetleaf_row_mapper}
/// Strategy interface for mapping a single database row or document
/// (`Map<String, Object?>`) into a domain object of type [T].
///
/// ### See Also
/// - [EntityRowMapper]
/// - `QueryResult`
/// {@endtemplate}
@Generic(RowMapper)
abstract interface class RowMapper<T> {
  /// Reflective [Class] handle for [RowMapper].
  static final Class<RowMapper> CLASS = Class<RowMapper>(null, PackageNames.DATA);

  /// Maps [row] into a domain instance of type [T].
  T mapRow(Map<String, Object?> row);
}