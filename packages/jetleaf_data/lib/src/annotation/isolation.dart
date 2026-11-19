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

/// {@template jetleaf_isolation}
/// Defines the **SQL transaction isolation level** requested for a
/// `@Transactional` execution boundary.
///
/// | Level | Dirty Reads | Non-Repeatable Reads | Phantom Reads |
/// |-------|-------------|----------------------|---------------|
/// | [readUncommitted] | Allowed | Allowed | Allowed |
/// | [readCommitted] | Prevented | Allowed | Allowed |
/// | [repeatableRead] | Prevented | Prevented | Allowed |
/// | [serializable] | Prevented | Prevented | Prevented |
/// {@endtemplate}
enum Isolation {
  /// Allows dirty reads, non-repeatable reads, and phantom reads.
  readUncommitted,

  /// Prevents dirty reads; default for most relational engines.
  readCommitted,

  /// Prevents dirty reads and non-repeatable reads.
  repeatableRead,

  /// Prevents dirty reads, non-repeatable reads, and phantom reads.
  serializable,
}
