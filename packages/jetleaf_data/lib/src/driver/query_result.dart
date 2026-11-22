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

/// {@template jetleaf_query_result}
/// Immutable container representing the materialized result of a database
/// query or mutation statement.
///
/// ### Features
/// - [getRows] — result rows represented as column-name to value maps.
/// - [getAffectedRows] — number of rows modified by an `INSERT`, `UPDATE`, or
///   `DELETE` statement.
/// - [getTotalRows] — optional total count reported by the driver.
/// - Convenience accessors: [isEmpty], [isNotEmpty], [getLength], [getFirst],
///   and [getSingle].
///
/// ### See Also
/// - `DatabaseClient`
/// - `RowMapper`
/// {@endtemplate}
final class QueryResult with EqualsAndHashCode {
  /// Reflective [Class] handle for [QueryResult].
  static final Class<QueryResult> CLASS = Class<QueryResult>(null, PackageNames.DATA);

  /// Shared empty [QueryResult] constant.
  static const QueryResult empty = QueryResult();

  final List<Map<String, Object?>> _rows;
  final int _affectedRows;
  final int? _totalRows;

  /// {@macro jetleaf_query_result}
  const QueryResult({
    List<Map<String, Object?>> rows = const [],
    int affectedRows = 0,
    int? totalRows,
  })  : _rows = rows,
        _affectedRows = affectedRows,
        _totalRows = totalRows;

  /// Creates a [QueryResult] wrapping [rows].
  factory QueryResult.fromRows(List<Map<String, Object?>> rows) => QueryResult(
    rows: List.unmodifiable(rows),
    affectedRows: rows.length,
  );

  /// Creates a [QueryResult] reporting [affectedRows] modified rows.
  factory QueryResult.affected(int affectedRows) => QueryResult(
    affectedRows: affectedRows,
    totalRows: affectedRows,
  );

  /// Returns the result rows.
  List<Map<String, Object?>> getRows() => _rows;

  /// Returns the number of rows affected by a mutation statement.
  int getAffectedRows() => _affectedRows;

  /// Returns the reported total row count, if available.
  int? getTotalRows() => _totalRows;

  /// Returns `true` if no rows were returned.
  bool isEmpty() => _rows.isEmpty;

  /// Returns `true` if at least one row was returned.
  bool isNotEmpty() => _rows.isNotEmpty;

  /// Returns the number of rows in [getRows].
  int getLength() => _rows.length;

  /// Returns the first row, or `null` if [isEmpty] is `true`.
  Map<String, Object?>? getFirst() => _rows.isEmpty ? null : _rows.first;

  /// Returns the single row, or `null` if [isEmpty] is `true`.
  ///
  /// Throws [IllegalStateException] if more than one row is present.
  Map<String, Object?>? getSingle() {
    if (_rows.length > 1) {
      throw IllegalStateException('Expected a single row, got ${_rows.length}');
    }
    return _rows.isEmpty ? null : _rows.single;
  }

  @override
  List<Object?> equalizedProperties() => [_rows, _affectedRows, _totalRows];
}