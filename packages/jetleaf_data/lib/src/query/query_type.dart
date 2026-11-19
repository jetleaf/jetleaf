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

/// {@template jetleaf_query_type}
/// Classifies the **statement kind** of a `QueryCriteria`.
/// {@endtemplate}
enum QueryType {
  /// Row projection (`SELECT ...`).
  select,

  /// Count aggregation (`SELECT COUNT(...)`).
  count,

  /// Existence probe (`SELECT 1 ... LIMIT 1`).
  exists,

  /// Conditional deletion (`DELETE FROM ...`).
  delete,

  /// Conditional mutation (`UPDATE ...`).
  update,
}
