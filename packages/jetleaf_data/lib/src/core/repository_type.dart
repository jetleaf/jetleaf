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

/// {@template jetleaf_repository_definition_type}
/// Represents the different **repository implementation categories** used
/// in JetLeaf's repository architecture.
///
/// These types classify how a repository method is expected to behave,
/// which executor logic to apply, and how the framework should interpret
/// the method during interception, analysis, or code generation.
/// {@endtemplate}
enum RepositoryType {
  /// A user-defined method that does not map to any built-in
  /// repository behavior. Typical for derived queries or `@Query` definitions.
  CUSTOM,

  /// A simple repository method that does not involve CRUD or pageable semantics.
  BASE,

  /// Matches CRUD-style repository methods such as `findById`, `save`, or `delete`.
  CRUD,

  /// CRUD repository behavior with list-based return semantics (e.g., returning `List<T>`).
  LIST_CRUD,

  /// Repository methods supporting sorting or pagination.
  PAGEABLE,

  /// Pageable behavior but explicitly returning lists.
  LIST_PAGEABLE,
}
