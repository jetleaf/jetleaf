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

import '../mapping/entity_metadata.dart';
import '../paging/sort.dart';
import 'part_tree.dart';

/// {@template jetleaf_query_type}
/// Classifies the **statement kind** of a [QueryCriteria].
/// {@endtemplate}
enum QueryType {
  /// Row projection (`SELECT ...`).
  select,

  /// Count aggregation (`SELECT COUNT(...)`).
  count,

  /// Existence probe (`SELECT 1 ... LIMIT 1`).
  exists,

  /// Conditional deletion (`DELETE FROM ...`).
  delete,

  /// Conditional mutation (`UPDATE ...`).
  update,
}

/// {@template jetleaf_query_criteria}
/// Dialect-agnostic specification of a query against a persistent `@Entity`.
///
/// Combines the target [EntityMetadata], [QueryType], optional [Criterion]
/// predicate tree, ordered positional [getValues], named parameter bindings
/// ([getNamedValues]), [Sort] ordering, and [getLimit]/[getOffset] pagination
/// bounds.
///
/// ### See Also
/// - [QueryType]
/// - [Criterion]
/// - `DatabaseDialect`
/// {@endtemplate}
final class QueryCriteria with EqualsAndHashCode {
  /// Reflective [Class] handle for [QueryCriteria].
  static final Class<QueryCriteria> CLASS = Class<QueryCriteria>(null, PackageNames.DATA);

  final EntityMetadata<dynamic> _metadata;
  final QueryType _type;
  final Criterion? _predicate;
  final List<Object?> _values;
  final Sort _sort;
  final int? _limit;
  final int? _offset;
  final bool _distinct;
  final Map<String, Object?> _namedValues;

  /// {@macro jetleaf_query_criteria}
  QueryCriteria({
    required EntityMetadata<dynamic> metadata,
    required QueryType type,
    required Criterion? predicate,
    required List<Object?> values,
    Sort? sort,
    int? limit,
    int? offset,
    bool distinct = false,
    Map<String, Object?> namedValues = const {},
  })  : _metadata = metadata,
        _type = type,
        _predicate = predicate,
        _values = List.unmodifiable(values),
        _sort = sort ?? Sort.UNSORTED,
        _limit = limit,
        _offset = offset,
        _distinct = distinct,
        _namedValues = Map.unmodifiable(namedValues);

  /// Creates a `SELECT` [QueryCriteria].
  factory QueryCriteria.select({
    required EntityMetadata<dynamic> metadata,
    Criterion? predicate,
    List<Object?> values = const [],
    Sort? sort,
    int? limit,
    int? offset,
    bool distinct = false,
  }) => QueryCriteria(
    metadata: metadata,
    type: QueryType.select,
    predicate: predicate,
    values: values,
    sort: sort ?? Sort.UNSORTED,
    limit: limit,
    offset: offset,
    distinct: distinct,
  );

  /// Creates a `COUNT` [QueryCriteria].
  factory QueryCriteria.count({
    required EntityMetadata<dynamic> metadata,
    Criterion? predicate,
    List<Object?> values = const [],
  }) => QueryCriteria(
    metadata: metadata,
    type: QueryType.count,
    predicate: predicate,
    values: values,
  );

  /// Creates an `EXISTS` [QueryCriteria].
  factory QueryCriteria.exists({
    required EntityMetadata<dynamic> metadata,
    Criterion? predicate,
    List<Object?> values = const [],
  }) => QueryCriteria(
    metadata: metadata,
    type: QueryType.exists,
    predicate: predicate,
    values: values,
    limit: 1,
  );

  /// Creates a `DELETE` [QueryCriteria].
  factory QueryCriteria.delete({
    required EntityMetadata<dynamic> metadata,
    Criterion? predicate,
    List<Object?> values = const [],
  }) => QueryCriteria(
    metadata: metadata,
    type: QueryType.delete,
    predicate: predicate,
    values: values,
  );

  /// Creates a named-parameter [QueryCriteria].
  factory QueryCriteria.named({
    required EntityMetadata<dynamic> metadata,
    required QueryType type,
    required Map<String, Object?> namedValues,
    Sort? sort,
    int? limit,
    bool distinct = false,
  }) => QueryCriteria(
    metadata: metadata,
    type: type,
    predicate: null,
    values: const [],
    namedValues: namedValues,
    sort: sort ?? Sort.UNSORTED,
    limit: limit,
    distinct: distinct,
  );

  /// Returns the target [EntityMetadata].
  EntityMetadata<dynamic> getMetadata() => _metadata;

  /// Returns the [QueryType].
  QueryType getType() => _type;

  /// Returns the root [Criterion] predicate, or `null` when unconditional.
  Criterion? getPredicate() => _predicate;

  /// Returns the ordered positional bind values.
  List<Object?> getValues() => _values;

  /// Returns the [Sort] specification.
  Sort getSort() => _sort;

  /// Returns the maximum row limit, if bounded.
  int? getLimit() => _limit;

  /// Returns the row offset, if specified.
  int? getOffset() => _offset;

  /// Returns `true` if `DISTINCT` projection is requested.
  bool isDistinct() => _distinct;

  /// Returns the named parameter map for `@Query` statements.
  Map<String, Object?> getNamedValues() => _namedValues;

  /// Returns `true` if a non-null predicate is attached.
  bool hasPredicate() => _predicate != null;

  /// Returns a copy of this [QueryCriteria] with the specified fields updated.
  QueryCriteria copyWith({
    QueryType? type,
    Criterion? predicate,
    List<Object?>? values,
    Sort? sort,
    int? limit,
    int? offset,
    bool? distinct,
    Map<String, Object?>? namedValues,
  }) => QueryCriteria(
    metadata: _metadata,
    type: type ?? _type,
    predicate: predicate ?? _predicate,
    values: values ?? _values,
    sort: sort ?? _sort,
    limit: limit ?? _limit,
    offset: offset ?? _offset,
    distinct: distinct ?? _distinct,
    namedValues: namedValues ?? _namedValues,
  );

  @override
  List<Object?> equalizedProperties() => [
    _metadata.getTableName(),
    _type,
    _predicate,
    _values,
    _sort,
    _limit,
    _offset,
    _distinct,
    _namedValues,
  ];
}