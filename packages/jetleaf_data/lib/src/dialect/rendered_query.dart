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

/// {@template jetleaf_rendered_query}
/// Immutable container holding the rendered output of a `DatabaseDialect` for
/// a `QueryCriteria`.
///
/// ### Features
/// - [getSql] — the SQL statement string (or a diagnostic shell string for
///   document dialects).
/// - [getParameters] — the ordered positional bind values.
/// - [getDocument] — the BSON filter/update document for document dialects.
///
/// ### See Also
/// - `DatabaseDialect`
/// - `QueryCriteria`
/// {@endtemplate}
final class RenderedQuery with EqualsAndHashCode {
  /// Reflective [Class] handle for [RenderedQuery].
  static final Class<RenderedQuery> CLASS =
      Class<RenderedQuery>(null, PackageNames.DATA);

  final String _sql;
  final List<Object?> _parameters;
  final Map<String, Object?>? _document;

  /// {@macro jetleaf_rendered_query}
  RenderedQuery({
    required String sql,
    List<Object?> parameters = const [],
    Map<String, Object?>? document,
  })  : _sql = sql,
        _parameters = List.unmodifiable(parameters),
        _document = document != null ? Map.unmodifiable(document) : null;

  /// Returns the rendered SQL statement (or diagnostic representation for
  /// document stores).
  String getSql() => _sql;

  /// Returns the ordered positional bind parameters.
  List<Object?> getParameters() => _parameters;

  /// Returns the rendered document filter, or `null` for relational dialects.
  Map<String, Object?>? getDocument() => _document;

  /// Returns `true` if positional bind parameters are present.
  bool hasParameters() => _parameters.isNotEmpty;

  /// Returns `true` if a document filter is present.
  bool hasDocument() => _document != null;

  @override
  List<Object?> equalizedProperties() => [_sql, _parameters, _document];

  @override
  String toString() => _sql;
}
