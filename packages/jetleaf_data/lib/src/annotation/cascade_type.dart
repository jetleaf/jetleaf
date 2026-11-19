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

/// {@template jetleaf_cascade_type}
/// Defines the **cascade operations** propagated from an owning entity to its
/// associated target entities.
///
/// | Value | Behavior |
/// |-------|----------|
/// | [all] | Propagates all persistence operations (`persist` and `remove`) |
/// | [persist] | Saving the owning entity also saves associated child entities |
/// | [remove] | Deleting the owning entity also deletes associated child entities |
/// {@endtemplate}
enum CascadeType {
  /// Propagates all persistence operations.
  all,

  /// Propagates `save`/`insert` operations.
  persist,

  /// Propagates `delete` operations.
  remove,
}
