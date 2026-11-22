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
import '../query/query_criteria.dart';

/// {@template jetleaf_rendered_query}
/// Immutable container holding the rendered output of a [DatabaseDialect] for
/// a [QueryCriteria].
///
/// ### Features
/// - [getSql] — the SQL statement string (or a diagnostic shell string for
///   document dialects).
/// - [getParameters] — the ordered positional bind values.
/// - [getDocument] — the BSON filter/update document for document dialects.
///
/// ### See Also
/// - [DatabaseDialect]
/// - [QueryCriteria]
/// {@endtemplate}
final class RenderedQuery with EqualsAndHashCode {
  /// Reflective [Class] handle for [RenderedQuery].
  static final Class<RenderedQuery> CLASS = Class<RenderedQuery>(null, PackageNames.DATA);

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

/// {@template jetleaf_database_dialect}
/// Unified persistence dialect contract implemented by every relational SQL
/// and NoSQL/document database engine in JetLeaf Data.
///
/// A [DatabaseDialect] encapsulates all engine-specific query rendering,
/// identifier escaping, DDL statement generation, and type mapping without
/// holding stateful connection resources.
///
/// ### Extensibility
/// Custom dialects can be registered as `@Pod()` definitions in user
/// `@Configuration` classes or added to `ConfigurableDialectRegistry` via a
/// `DataConfigurer`:
/// ```dart
/// @Configuration()
/// final class CockroachDataConfig {
///   @Pod()
///   DatabaseDialect cockroachDialect() => const CockroachDbDialect();
/// }
/// ```
///
/// ### See Also
/// - `SqlDialect`
/// - `DocumentDialect`
/// - `DialectRegistry`
/// - [RenderedQuery]
/// {@endtemplate}
abstract class DatabaseDialect with EqualsAndHashCode {
  /// Reflective [Class] handle for [DatabaseDialect].
  static final Class<DatabaseDialect> CLASS = Class<DatabaseDialect>(null, PackageNames.DATA);

  /// {@macro jetleaf_database_dialect}
  const DatabaseDialect();

  /// Returns the canonical lowercase identifier of this dialect
  /// (e.g. `'postgresql'`, `'mysql'`, `'sqlite'`, `'mongodb'`).
  String getName();

  /// Returns `true` if this dialect targets a relational SQL database, or
  /// `false` for document/key-value stores.
  bool isRelational();

  /// Returns the engine-specific type mapper (`SqlTypeMapper` or
  /// `DocumentTypeMapper`).
  Object? getTypeMapper();

  /// Escapes a table, column, or alias [identifier] according to the target
  /// engine's quoting rules.
  String escapeIdentifier(String identifier);

  /// Renders [criteria] into an executable [RenderedQuery] containing the
  /// statement string, positional parameters, and/or document filter.
  RenderedQuery renderQuery(QueryCriteria criteria);

  /// Renders [criteria] into a SQL/query string.
  String buildSelectQuery(QueryCriteria criteria) => renderQuery(criteria).getSql();

  /// Renders an `INSERT` statement for [metadata].
  String buildInsertQuery(EntityMetadata<dynamic> metadata);

  /// Renders an `UPDATE` statement for [metadata].
  String buildUpdateQuery(EntityMetadata<dynamic> metadata);

  /// Renders a `DELETE` statement for [metadata].
  String buildDeleteQuery(EntityMetadata<dynamic> metadata);

  /// Renders a `CREATE TABLE IF NOT EXISTS` (or collection creation) statement
  /// for [metadata].
  String buildCreateTableQuery(EntityMetadata<dynamic> metadata);

  /// Renders a `CREATE [UNIQUE] INDEX` statement for [index] on [metadata].
  String buildCreateIndexQuery(EntityMetadata<dynamic> metadata, EntityIndex index);

  /// Renders a `DROP TABLE IF EXISTS` (or collection drop) statement for
  /// [metadata].
  String buildDropTableQuery(EntityMetadata<dynamic> metadata);

  @override
  List<Object?> equalizedProperties() => [getName(), isRelational()];
}