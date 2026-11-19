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

/// {@template jetleaf_part_subject}
/// Classifies the **query verb prefix** of a derived repository method name.
/// {@endtemplate}
enum PartSubject {
  /// `find…` — projects matching entities.
  find,

  /// `read…` — alias of [find].
  read,

  /// `get…` — alias of [find].
  get,

  /// `query…` — alias of [find].
  query,

  /// `count…` — returns the count of matching entities.
  count,

  /// `exists…` — returns `true` when at least one entity matches.
  exists,

  /// `delete…` — deletes matching entities.
  delete,

  /// `remove…` — alias of [delete].
  remove;

  /// Returns `true` if this subject represents a `COUNT` query.
  bool isCount() => this == count;

  /// Returns `true` if this subject represents an `EXISTS` probe.
  bool isExists() => this == exists;

  /// Returns `true` if this subject represents a `DELETE` operation.
  bool isDelete() => this == delete || this == remove;

  /// Returns `true` if this subject represents a `SELECT` projection.
  bool isSelect() => !isCount() && !isExists() && !isDelete();
}
