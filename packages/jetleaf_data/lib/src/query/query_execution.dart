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

/// {@template jetleaf_query_execution}
/// Identifies whether a repository query method is resolved via **method-name
/// derivation** (`PartTree`) or an explicit **`@Query` declaration**.
/// {@endtemplate}
enum QueryExecution {
  /// Query derived from the method name via `PartTree`.
  derived,

  /// Query explicitly declared via `@Query`.
  declared,
}
