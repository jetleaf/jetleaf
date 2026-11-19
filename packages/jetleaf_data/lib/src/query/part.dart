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

import 'part_operator.dart';

export 'part_operator.dart';

/// {@template jetleaf_part}
/// Represents a single atomic predicate clause in a derived repository query
/// method name (for example, `AgeGreaterThanEqual` or `EmailIgnoreCase`).
///
/// Couples a resolved entity [getProperty] path (including nested paths such as
/// `profile.bio`) with a [PartOperator] and an optional case-insensitivity
/// flag ([isIgnoreCase]).
///
/// ### See Also
/// - [PartOperator]
/// - `PartTree`
/// {@endtemplate}
final class Part with EqualsAndHashCode {
  /// Reflective [Class] handle for [Part].
  static final Class<Part> CLASS = Class<Part>(null, PackageNames.DATA);

  final String _property;
  final PartOperator _operator;
  final bool _ignoreCase;

  /// {@macro jetleaf_part}
  const Part({
    required String property,
    PartOperator? operator,
    PartOperator? operator_,
    bool ignoreCase = false,
  })  : _property = property,
        _operator = operator ?? operator_ ?? PartOperator.equals,
        _ignoreCase = ignoreCase;

  /// Returns the resolved dotted property path (e.g. `'email'` or
  /// `'profile.bio'`).
  String getProperty() => _property;

  /// Returns the [PartOperator] applied to [getProperty].
  PartOperator getOperator() => _operator;

  /// Returns `true` if string comparisons for this part should ignore case.
  bool isIgnoreCase() => _ignoreCase;

  /// Returns the number of method arguments consumed by this part.
  int getParameterCount() => _operator.getParameterCount();

  @override
  List<Object?> equalizedProperties() => [_property, _operator, _ignoreCase];

  @override
  String toString() => _ignoreCase
      ? '$_property ${_operator.getOperatorName()} (ignoreCase)'
      : '$_property ${_operator.getOperatorName()}';
}
