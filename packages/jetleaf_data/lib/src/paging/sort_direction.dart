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

/// {@template sort_direction}
/// Represents the direction in which results should be sorted.
///
/// Commonly used for database queries, API filters, and collection
/// utilities that require specifying ascending or descending order.
/// {@endtemplate}
enum SortDirection {
  /// Sort values from smallest → largest (A → Z, 0 → 9).
  ASC,

  /// Sort values from largest → smallest (Z → A, 9 → 0).
  DESC;

  /// Returns `true` if this direction is ascending.
  bool isAscending() => equals(ASC);

  /// Returns `true` if this direction is descending.
  bool isDescending() => equals(DESC);

  /// Parses a string into a [SortDirection].
  ///
  /// The comparison is case-insensitive.
  static SortDirection fromString(String value) {
    return switch (value.toUpperCase()) {
      "ASC" => ASC,
      "DESC" => DESC,
      _ => throw IllegalStateException("Unknown value passed. Value must either be 'desc' or 'asc'."),
    };
  }
}
