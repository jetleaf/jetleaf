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

/// {@template jetleaf_sql_parameter_style}
/// Defines the **parameter placeholder syntax** emitted by a `SqlDialect`.
/// {@endtemplate}
enum SqlParameterStyle {
  /// Positional question-mark placeholders (`?`), used by MySQL, MariaDB, and
  /// SQLite.
  questionMark,

  /// 1-based dollar-numbered placeholders (`$1, $2, ...`), used by PostgreSQL
  /// and CockroachDB.
  dollarNumbered,
}
