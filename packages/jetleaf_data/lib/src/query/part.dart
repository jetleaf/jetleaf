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

/// {@template jetleaf_part_operator}
/// Comparison and matching operators recognized by the `PartTree` method-name
/// query derivation grammar.
///
/// Operators are matched by suffix in descending keyword length order so
/// longer compound operators (such as `NotContaining` or `IsNotNull`) take
/// precedence over shorter suffixes (`Containing`, `IsNot`, `Is`).
/// {@endtemplate}
enum PartOperator {
  /// Equality comparison (`=` / `{ field: value }`).
  equals(['Equals', 'Is'], 1, 'equals'),

  /// Negated equality (`<>` / `$ne`).
  notEquals(['IsNot', 'Not'], 1, 'notEquals'),

  /// Pattern match (`LIKE` / `$regex`).
  like(['Like'], 1, 'like'),

  /// Negated pattern match (`NOT LIKE` / `$not: $regex`).
  notLike(['NotLike'], 1, 'notLike'),

  /// Prefix match (`LIKE 'value%'`).
  startingWith(['StartingWith'], 1, 'startingWith'),

  /// Suffix match (`LIKE '%value'`).
  endingWith(['EndingWith'], 1, 'endingWith'),

  /// Substring match (`LIKE '%value%'`).
  containing(['Containing'], 1, 'containing'),

  /// Negated substring match (`NOT LIKE '%value%'`).
  notContaining(['NotContaining'], 1, 'notContaining'),

  /// Strict greater-than comparison (`>` / `$gt`).
  greaterThan(['GreaterThan'], 1, 'greaterThan'),

  /// Greater-than-or-equal comparison (`>=` / `$gte`).
  greaterThanEqual(['GreaterThanEqual'], 1, 'greaterThanEqual'),

  /// Strict less-than comparison (`<` / `$lt`).
  lessThan(['LessThan'], 1, 'lessThan'),

  /// Less-than-or-equal comparison (`<=` / `$lte`).
  lessThanEqual(['LessThanEqual'], 1, 'lessThanEqual'),

  /// Temporal before comparison (`<` / `$lt`).
  before(['Before'], 1, 'before'),

  /// Temporal after comparison (`>` / `$gt`).
  after(['After'], 1, 'after'),

  /// Inclusive range comparison (`BETWEEN ? AND ?` / `$gte` + `$lte`).
  between(['Between'], 2, 'between'),

  /// Set membership (`IN (...)` / `$in`).
  in_(['In'], 1, 'in'),

  /// Negated set membership (`NOT IN (...)` / `$nin`).
  notIn(['NotIn'], 1, 'notIn'),

  /// Boolean true literal (`= TRUE` / `true`).
  isTrue(['True'], 0, 'isTrue'),

  /// Boolean false literal (`= FALSE` / `false`).
  isFalse(['False'], 0, 'isFalse'),

  /// Null check (`IS NULL` / `null`).
  isNull(['IsNull'], 0, 'isNull'),

  /// Non-null check (`IS NOT NULL` / `$ne: null`).
  isNotNull(['IsNotNull'], 0, 'isNotNull');

  final List<String> _keywords;
  final int _parameterCount;
  final String _operatorName;

  const PartOperator(this._keywords, this._parameterCount, this._operatorName);

  /// Returns all accepted method-name keyword suffixes for this operator.
  List<String> getKeywords() => _keywords;

  /// Returns the canonical (first) method-name keyword suffix.
  String getKeyword() => _keywords.first;

  /// Returns the number of method arguments consumed by this operator.
  int getParameterCount() => _parameterCount;

  /// Returns the symbolic name of this operator for diagnostics and logging.
  String getOperatorName() => _operatorName;

  /// Returns `true` if this operator belongs to the string pattern-matching
  /// family (`Like`, `NotLike`, `StartingWith`, `EndingWith`, `Containing`,
  /// `NotContaining`).
  bool isLikeFamily() =>
      this == like ||
      this == notLike ||
      this == startingWith ||
      this == endingWith ||
      this == containing ||
      this == notContaining;

  /// Returns `true` if this operator tests a boolean literal (`True` or `False`).
  bool isBooleanLiteral() => this == isTrue || this == isFalse;

  /// Returns `true` if this operator tests for `NULL` (`IsNull` or `IsNotNull`).
  bool isNullTest() => this == isNull || this == isNotNull;

  /// All `(keyword, operator)` pairs sorted by descending keyword length so
  /// longest suffixes match first during method name parsing.
  static final List<({String keyword, PartOperator operator})>
      byDescendingKeywordLength =
      List<({String keyword, PartOperator operator})>.unmodifiable(
    [
      for (final operator in PartOperator.values)
        for (final keyword in operator.getKeywords())
          (keyword: keyword, operator: operator),
    ]..sort((a, b) => b.keyword.length.compareTo(a.keyword.length)),
  );
}

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