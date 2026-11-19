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
import 'rendered_query.dart';

export 'rendered_query.dart';

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
  static final Class<DatabaseDialect> CLASS =
      Class<DatabaseDialect>(null, PackageNames.DATA);

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
  String buildSelectQuery(QueryCriteria criteria) =>
      renderQuery(criteria).getSql();

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
  String buildCreateIndexQuery(
    EntityMetadata<dynamic> metadata,
    EntityIndex index,
  );

  /// Renders a `DROP TABLE IF EXISTS` (or collection drop) statement for
  /// [metadata].
  String buildDropTableQuery(EntityMetadata<dynamic> metadata);

  @override
  List<Object?> equalizedProperties() => [getName(), isRelational()];
}
