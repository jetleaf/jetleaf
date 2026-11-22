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

import 'dart:async';

import 'package:jetleaf_core/lang.dart';

import 'database_client.dart';
import 'query_result.dart';

/// {@template jetleaf_pooled_connection}
/// A leased [DatabaseClient] connection checkout managed by a
/// `ConnectionFactory` or `ConnectionPool`.
///
/// Forwards all operations to [getDelegate] while active and returns the
/// underlying connection to the pool when [close] is invoked. If a transaction
/// remains uncommitted when [close] is called, [PooledConnection]
/// automatically rolls it back before returning the connection to the pool.
///
/// ### See Also
/// - [DatabaseClient]
/// - `ConnectionPool`
/// {@endtemplate}
final class PooledConnection extends DatabaseClient {
  /// Reflective [Class] handle for [PooledConnection].
  static final Class<PooledConnection> CLASS = Class<PooledConnection>(null, PackageNames.DATA);

  final DatabaseClient _delegate;
  final FutureOr<void> Function(PooledConnection connection, bool wasInTransaction)?
      _onClose;

  bool _inTransaction = false;
  bool _closed = false;

  /// {@macro jetleaf_pooled_connection}
  PooledConnection(
    this._delegate, {
    FutureOr<void> Function(PooledConnection connection, bool wasInTransaction)? onClose,
  }) : _onClose = onClose;

  /// Returns the underlying physical [DatabaseClient] delegate.
  DatabaseClient getDelegate() => _delegate;

  /// Returns `true` if this lease is still open.
  bool isOpen() => !_closed;

  /// Returns `true` if this lease has been closed and returned to the pool.
  bool isClosed() => _closed;

  /// Returns `true` if a transaction is currently active on this lease.
  bool isInTransaction() => _inTransaction;

  /// Marks this lease as having an active transaction.
  void markTransactionStarted() => _inTransaction = true;

  /// Marks the transaction on this lease as completed.
  void markTransactionEnded() => _inTransaction = false;

  @override
  bool supportsSql() => _delegate.supportsSql();

  @override
  bool supportsDocuments() => _delegate.supportsDocuments();

  @override
  Future<bool> isValid([String validationQuery = 'SELECT 1']) {
    _checkOpen();
    return _delegate.isValid(validationQuery);
  }

  @override
  Future<QueryResult> query(
    String sql, {
    List<Object?> parameters = const [],
  }) {
    _checkOpen();
    return _delegate.query(sql, parameters: parameters);
  }

  @override
  Future<int> execute(
    String sql, {
    List<Object?> parameters = const [],
  }) {
    _checkOpen();
    return _delegate.execute(sql, parameters: parameters);
  }

  @override
  Future<void> beginTransaction() {
    _checkOpen();
    return _delegate.beginTransaction().then((_) => markTransactionStarted());
  }

  @override
  Future<void> commitTransaction() async {
    _checkOpen();
    await _delegate.commitTransaction();
    markTransactionEnded();
  }

  @override
  Future<void> rollbackTransaction() async {
    _checkOpen();
    await _delegate.rollbackTransaction();
    markTransactionEnded();
  }

  @override
  Future<void> setReadOnly(bool readOnly) {
    _checkOpen();
    return _delegate.setReadOnly(readOnly);
  }

  @override
  Future<Map<String, Object?>> insertDocument(
    String collection,
    Map<String, Object?> document,
  ) {
    _checkOpen();
    return _delegate.insertDocument(collection, document);
  }

  @override
  Future<int> updateDocuments(
    String collection,
    Map<String, Object?> filter,
    Map<String, Object?> update,
  ) {
    _checkOpen();
    return _delegate.updateDocuments(collection, filter, update);
  }

  @override
  Future<int> deleteDocuments(
    String collection,
    Map<String, Object?> filter,
  ) {
    _checkOpen();
    return _delegate.deleteDocuments(collection, filter);
  }

  @override
  Future<List<Map<String, Object?>>> findDocuments(
    String collection,
    Map<String, Object?> filter, {
    Map<String, Object?>? sort,
    int? limit,
    int? skip,
  }) {
    _checkOpen();
    return _delegate.findDocuments(
      collection,
      filter,
      sort: sort,
      limit: limit,
      skip: skip,
    );
  }

  @override
  Future<int> countDocuments(
    String collection,
    Map<String, Object?> filter,
  ) {
    _checkOpen();
    return _delegate.countDocuments(collection, filter);
  }

  @override
  Future<int?> getLastInsertId() {
    _checkOpen();
    return _delegate.getLastInsertId();
  }

  @override
  Future<void> close() async {
    if (_closed) return;

    final wasInTransaction = _inTransaction;
    if (_inTransaction) {
      try {
        await _delegate.rollbackTransaction();
      } on Object {
        // Best-effort rollback before returning to pool.
      }
      _inTransaction = false;
    }

    _closed = true;
    await _onClose?.call(this, wasInTransaction);
  }

  void _checkOpen() {
    if (_closed) {
      throw StateError(
        'This PooledConnection has been returned to the pool and is no longer usable',
      );
    }
  }
}