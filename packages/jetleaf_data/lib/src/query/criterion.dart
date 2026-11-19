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

import 'package:jetleaf_core/lang.dart';

import 'part.dart';

/// {@template jetleaf_criterion}
/// Sealed AST node representing a boolean predicate tree produced by
/// `PartTree`.
///
/// The grammar models a disjunction (`Or`) of conjunctions (`And`) of leaf
/// [PartCriterion] nodes, ensuring `And` binds more tightly than `Or`.
/// {@endtemplate}
sealed class Criterion with EqualsAndHashCode {
  /// {@macro jetleaf_criterion}
  const Criterion();

  /// Returns a depth-first iterable of all leaf [Part] nodes in parameter
  /// binding order.
  Iterable<Part> getParts() sync* {
    switch (this) {
      case PartCriterion():
        yield (this as PartCriterion).getPart();
      case CompositeCriterion():
        for (final child in (this as CompositeCriterion).getChildren()) {
          yield* child.getParts();
        }
    }
  }
}

/// {@template jetleaf_part_criterion}
/// Leaf [Criterion] wrapping a single [Part].
/// {@endtemplate}
final class PartCriterion extends Criterion {
  /// Reflective [Class] handle for [PartCriterion].
  static final Class<PartCriterion> CLASS =
      Class<PartCriterion>(null, PackageNames.DATA);

  final Part _part;

  /// {@macro jetleaf_part_criterion}
  const PartCriterion(this._part);

  /// Returns the wrapped [Part].
  Part getPart() => _part;

  @override
  List<Object?> equalizedProperties() => [_part];

  @override
  String toString() => _part.toString();
}

/// {@template jetleaf_composite_criterion}
/// Composite [Criterion] combining child criteria with boolean `AND` or `OR`.
/// {@endtemplate}
final class CompositeCriterion extends Criterion {
  /// Reflective [Class] handle for [CompositeCriterion].
  static final Class<CompositeCriterion> CLASS =
      Class<CompositeCriterion>(null, PackageNames.DATA);

  final bool _isOr;
  final List<Criterion> _children;

  /// {@macro jetleaf_composite_criterion}
  const CompositeCriterion({
    required bool isOr,
    required List<Criterion> children,
  })  : _isOr = isOr,
        _children = children;

  /// Creates an `AND` conjunction of [children].
  factory CompositeCriterion.and(List<Criterion> children) =>
      CompositeCriterion(isOr: false, children: List.unmodifiable(children));

  /// Creates an `OR` disjunction of [children].
  factory CompositeCriterion.or(List<Criterion> children) =>
      CompositeCriterion(isOr: true, children: List.unmodifiable(children));

  /// Returns `true` if this node is an `OR` disjunction, or `false` for `AND`.
  bool isOr() => _isOr;

  /// Returns `true` if this node is an `AND` conjunction.
  bool isAnd() => !_isOr;

  /// Returns the ordered child [Criterion] nodes.
  List<Criterion> getChildren() => _children;

  @override
  List<Object?> equalizedProperties() => [_isOr, _children];

  @override
  String toString() =>
      '(${_children.map((c) => c.toString()).join(_isOr ? ' OR ' : ' AND ')})';
}
