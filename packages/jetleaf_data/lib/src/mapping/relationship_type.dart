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

/// {@template jetleaf_relationship_type}
/// Classifies the **cardinality** of an association between two persistent
/// entities.
/// {@endtemplate}
enum RelationshipType {
  /// `@OneToOne` association.
  oneToOne,

  /// `@OneToMany` association.
  oneToMany,

  /// `@ManyToOne` association.
  manyToOne,

  /// `@ManyToMany` association.
  manyToMany;

  /// Returns `true` if this relationship targets a single entity
  /// (`oneToOne` or `manyToOne`).
  bool isToOne() => this == oneToOne || this == manyToOne;

  /// Returns `true` if this relationship targets a collection of entities
  /// (`oneToMany` or `manyToMany`).
  bool isToMany() => !isToOne();
}
