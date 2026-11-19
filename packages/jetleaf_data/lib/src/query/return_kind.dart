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

/// {@template jetleaf_return_kind}
/// Classifies the **return type shape** of a repository query method.
/// {@endtemplate}
enum ReturnKind {
  /// `Future<void>` — mutation with no result payload.
  void$,

  /// Single entity instance (`Future<T>` or `Future<T?>`).
  single,

  /// Collection of entities (`Future<List<T>>`, `Future<Iterable<T>>`, or
  /// `Future<Set<T>>`).
  collection,

  /// Paginated [Page] result (`Future<Page<T>>`).
  page,

  /// Paginated [Slice] result (`Future<Slice<T>>`).
  slice,

  /// Integer count (`Future<int>`).
  count,

  /// Boolean existence flag (`Future<bool>`).
  exists,

  /// Numeric scalar (`Future<num>`, `Future<double>`, `Future<BigInt>`).
  scalar,
}
