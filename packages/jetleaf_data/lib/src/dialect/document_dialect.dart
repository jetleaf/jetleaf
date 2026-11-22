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
import '../query/query_criteria.dart';
import 'database_dialect.dart';
import 'document_type_mapper.dart';

/// {@template jetleaf_document_dialect}
/// Abstract base class for **document-oriented NoSQL dialects** (MongoDB,
/// DocumentDB, DynamoDB, etc.).
///
/// Translates `QueryCriteria`, `Sort`, and `EntityMetadata` into structured
/// filter, sort, insert, and update documents consumed by `DatabaseClient`
/// document operations.
///
/// ### See Also
/// - [DatabaseDialect]
/// - [DocumentTypeMapper]
/// {@endtemplate}
abstract class DocumentDialect extends DatabaseDialect {
  /// Reflective [Class] handle for [DocumentDialect].
  static final Class<DocumentDialect> CLASS = Class<DocumentDialect>(null, PackageNames.DATA);

  /// {@macro jetleaf_document_dialect}
  const DocumentDialect();

  @override
  bool isRelational() => false;

  @override
  DocumentTypeMapper getTypeMapper();

  /// Builds the filter document for [criteria].
  Map<String, Object?> buildFilterDocument(QueryCriteria criteria);

  /// Builds the sort document (`{ field: 1 | -1 }`) for [sort] against
  /// [metadata].
  Map<String, Object?> buildSortDocument(Sort sort, EntityMetadata<dynamic> metadata);

  /// Builds the document payload to insert for [metadata] from column-keyed
  /// [values].
  Map<String, Object?> buildInsertDocument(EntityMetadata<dynamic> metadata, Map<String, Object?> values);

  /// Builds the update document (e.g. `{ '$set': values }`) for [metadata].
  Map<String, Object?> buildUpdateDocument(EntityMetadata<dynamic> metadata, Map<String, Object?> values);

  /// Builds the identifier (and optional optimistic-lock version) filter
  /// document for single-document update and delete operations.
  Map<String, Object?> buildIdFilter(
    EntityMetadata<dynamic> metadata,
    Object? idValue,
    Object? versionValue,
  );

  @override
  String buildDropTableQuery(EntityMetadata<dynamic> metadata) => 'db.${metadata.getTableName()}.drop()';

  /// Formats [document] as a human-readable diagnostic string for logging.
  static String formatDebugDocument(Object? document) => _renderDocument(document, 0);

  /// Alias for [formatDebugDocument].
  static String debugDocument(Object? document) => formatDebugDocument(document);

  static String _renderDocument(Object? value, int depth) {
    switch (value) {
      case null:
        return 'null';
      case Map<String, Object?> map:
        final entries = map.entries
            .map((entry) => '"${entry.key}": ${_renderDocument(entry.value, depth + 1)}')
            .join(', ');
        return '{ $entries }';
      case List<Object?> list:
        return '[ ${list.map((item) => _renderDocument(item, depth + 1)).join(', ')} ]';
      case DateTime dt:
        return 'ISODate("${dt.toUtc().toIso8601String()}")';
      case String s:
        return '"$s"';
      default:
        return '$value';
    }
  }
}