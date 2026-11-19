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

/// {@template jetleaf_fetch_type}
/// Defines the **fetching strategy** for an entity association.
///
/// | Value | Behavior |
/// |-------|----------|
/// | [lazy] | Defers loading the association until explicitly requested |
/// | [eager] | Loads the association immediately alongside the owning entity |
/// {@endtemplate}
enum FetchType {
  /// Resolves the association lazily on demand.
  lazy,

  /// Resolves the association eagerly with the owning entity.
  eager,
}
