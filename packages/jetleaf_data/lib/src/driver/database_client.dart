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

import 'query_result.dart';

/// {@template jetleaf_database_client}
/// Low-level driver client abstraction bridging JetLeaf Data with concrete
/// relational SQL or NoSQL/document database drivers.
///
/// ### Capabilities
/// - **Relational SQL**: [query], [execute], [getLastInsertId].
/// - **Document Stores**: [insertDocument], [updateDocuments],
///   [deleteDocuments], [findDocuments], [countDocuments].
/// - **Transactions**: [beginTransaction], [commitTransaction],
///   [rollbackTransaction], [setReadOnly].
/// - **Lifecycle & Health**: [isValid], [close].
///
/// ### Usage Example
/// ```dart
/// final result = await client.query(
///   'SELECT id, email FROM users WHERE active = ?',
///   parameters: [true],
/// );
/// for (final row in result.getRows()) {
///   print(row['email']);
/// }
/// ```
///
/// ### See Also
/// - [QueryResult]
/// - `ConnectionFactory`
/// - `PooledConnection`
/// {@endtemplate}
abstract class DatabaseClient {
  /// Reflective [Class] handle for [DatabaseClient].
  static final Class<DatabaseClient> CLASS = Class<DatabaseClient>(null, PackageNames.DATA);

  /// {@macro jetleaf_database_client}
  const DatabaseClient();

  /// Returns `true` if this client supports executing SQL statements.
  bool supportsSql() => true;

  /// Returns `true` if this client supports document-store operations.
  bool supportsDocuments() => false;

  /// Checks whether this client connection is healthy and usable.
  ///
  /// Defaults to running `SELECT 1` for SQL clients and returning `true` for
  /// document clients; drivers may override with native ping commands.
  Future<bool> isValid([String validationQuery = 'SELECT 1']) async {
    try {
      if (supportsSql()) {
        await query(validationQuery);
      }
      return true;
    } on Object {
      return false;
    }
  }

  /// Executes a read or `RETURNING` SQL statement and returns a [QueryResult].
  Future<QueryResult> query(
    String sql, {
    List<Object?> parameters = const [],
  });

  /// Executes a mutation or DDL SQL statement and returns the affected row
  /// count.
  Future<int> execute(
    String sql, {
    List<Object?> parameters = const [],
  });

  /// Begins a database transaction on this connection.
  Future<void> beginTransaction() async {}

  /// Commits the active database transaction on this connection.
  Future<void> commitTransaction() async {}

  /// Rolls back the active database transaction on this connection.
  Future<void> rollbackTransaction() async {}

  /// Configures whether the current transaction or session is read-only.
  Future<void> setReadOnly(bool readOnly) async {}

  /// Returns the last auto-generated integer primary key produced on this
  /// connection, or `null` if not applicable.
  Future<int?> getLastInsertId() async => null;

  /// Alias for [getLastInsertId].
  Future<int?> lastInsertId() => getLastInsertId();

  /// Inserts [document] into [collection] and returns the stored document.
  Future<Map<String, Object?>> insertDocument(
    String collection,
    Map<String, Object?> document,
  ) {
    throw UnsupportedOperationException('$runtimeType does not support document operations');
  }

  /// Updates documents in [collection] matching [filter] with [update] and
  /// returns the modified document count.
  Future<int> updateDocuments(
    String collection,
    Map<String, Object?> filter,
    Map<String, Object?> update,
  ) {
    throw UnsupportedOperationException('$runtimeType does not support document operations');
  }

  /// Deletes documents in [collection] matching [filter] and returns the
  /// deleted document count.
  Future<int> deleteDocuments(
    String collection,
    Map<String, Object?> filter,
  ) {
    throw UnsupportedOperationException('$runtimeType does not support document operations');
  }

  /// Finds documents in [collection] matching [filter] with optional [sort],
  /// [limit], and [skip].
  Future<List<Map<String, Object?>>> findDocuments(
    String collection,
    Map<String, Object?> filter, {
    Map<String, Object?>? sort,
    int? limit,
    int? skip,
  }) {
    throw UnsupportedOperationException('$runtimeType does not support document operations');
  }

  /// Counts documents in [collection] matching [filter].
  Future<int> countDocuments(
    String collection,
    Map<String, Object?> filter,
  ) {
    throw UnsupportedOperationException('$runtimeType does not support document operations');
  }

  /// Closes this client and releases underlying physical resources.
  Future<void> close() async {}
}