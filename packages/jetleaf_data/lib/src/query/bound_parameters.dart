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

import '../paging/pageable.dart';
import '../paging/sort.dart';

/// {@template jetleaf_bound_parameters}
/// Immutable container holding the bound arguments for a repository query
/// execution, including positional bind values, named `:param` bindings, and
/// extracted [Pageable] or [Sort] arguments.
/// {@endtemplate}
final class BoundParameters with EqualsAndHashCode {
  /// Reflective [Class] handle for [BoundParameters].
  static final Class<BoundParameters> CLASS =
      Class<BoundParameters>(null, PackageNames.DATA);

  /// Empty parameter bindings constant.
  static const BoundParameters empty = BoundParameters(
    positional: [],
    named: {},
  );

  final List<Object?> _positional;
  final Map<String, Object?> _named;
  final Pageable? _pageable;
  final Sort? _sort;

  /// {@macro jetleaf_bound_parameters}
  const BoundParameters({
    required List<Object?> positional,
    required Map<String, Object?> named,
    Pageable? pageable,
    Sort? sort,
  })  : _positional = positional,
        _named = named,
        _pageable = pageable,
        _sort = sort;

  /// Returns the ordered positional bind values.
  List<Object?> getPositional() => _positional;

  /// Returns the named parameter bindings (`:name`).
  Map<String, Object?> getNamed() => _named;

  /// Returns the extracted [Pageable] argument, if provided.
  Pageable? getPageable() => _pageable;

  /// Returns the extracted [Sort] argument, if provided.
  Sort? getSort() => _sort;

  @override
  List<Object?> equalizedProperties() => [
        _positional,
        _named,
        _pageable,
        _sort,
      ];
}
