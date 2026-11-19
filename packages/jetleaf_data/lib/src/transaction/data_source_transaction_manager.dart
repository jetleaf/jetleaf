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

import '../annotation/propagation.dart';
import '../driver/connection_factory.dart';
import '../driver/pooled_connection.dart';
import '../exception/data_access_exception.dart';
import 'default_transaction_definition.dart';
import 'platform_transaction_manager.dart';
import 'transaction_definition.dart';
import 'transaction_status.dart';
import 'zone_transaction_holder.dart';

/// {@template jetleaf_data_source_transaction_manager}
/// [PlatformTransactionManager] implementation that manages transactions on
/// [PooledConnection] leases obtained from a [ConnectionFactory].
///
/// Supports all six Spring propagation behaviors (`required`, `requiresNew`,
/// `mandatory`, `supports`, `notSupported`, `never`) and rollback-only
/// propagation across nested participants.
/// {@endtemplate}
final class DataSourceTransactionManager extends PlatformTransactionManager {
  /// Reflective [Class] handle for [DataSourceTransactionManager].
  static final Class<DataSourceTransactionManager> CLASS =
      Class<DataSourceTransactionManager>(null, PackageNames.DATA);

  final ConnectionFactory _factory;
  final Future<void> Function(PooledConnection connection)?
      _onConnectionAcquired;

  /// {@macro jetleaf_data_source_transaction_manager}
  const DataSourceTransactionManager(
    this._factory, {
    Future<void> Function(PooledConnection connection)? onConnectionAcquired,
  }) : _onConnectionAcquired = onConnectionAcquired;

  /// Returns the [ConnectionFactory] backing this transaction manager.
  ConnectionFactory getConnectionFactory() => _factory;

  @override
  Future<TransactionStatus> getTransaction(
    TransactionDefinition? definition,
  ) async {
    final def = definition ?? const DefaultTransactionDefinition();
    final existing = ZoneTransactionHolder.getCurrent();

    switch (def.getPropagation()) {
      case Propagation.mandatory:
        if (existing == null) {
          throw MandatoryTransactionException(
            'No transaction is active — Propagation.mandatory requires one',
          );
        }
        return DefaultTransactionStatus(
          definition: def,
          context: existing,
          newTransaction: false,
        );

      case Propagation.required:
        if (existing != null) {
          return DefaultTransactionStatus(
            definition: def,
            context: existing,
            newTransaction: false,
          );
        }
        return _startNew(def);

      case Propagation.requiresNew:
        return _startNew(def);

      case Propagation.supports:
        if (existing != null) {
          return DefaultTransactionStatus(
            definition: def,
            context: existing,
            newTransaction: false,
          );
        }
        return DefaultTransactionStatus.unbound(def);

      case Propagation.notSupported:
        return DefaultTransactionStatus.unbound(def);

      case Propagation.never:
        if (existing != null) {
          throw TransactionSystemException(
            'A transaction is active — Propagation.never forbids one',
          );
        }
        return DefaultTransactionStatus.unbound(def);
    }
  }

  Future<TransactionStatus> _startNew(TransactionDefinition def) async {
    final connection = await _factory.getConnection();
    final hook = _onConnectionAcquired;
    if (hook != null) {
      await hook(connection);
    }

    try {
      await connection.beginTransaction();
      await connection.setReadOnly(def.isReadOnly());
    } on Object {
      await _releaseQuietly(connection);
      rethrow;
    }

    final context = TransactionContext(
      connection: connection,
      definition: def,
    );
    return DefaultTransactionStatus(
      definition: def,
      context: context,
      newTransaction: true,
    );
  }

  @override
  Future<void> commit(TransactionStatus status) async {
    final defaultStatus = status as DefaultTransactionStatus;
    final context = defaultStatus.getContext();

    if (!defaultStatus.isNewTransaction() || context == null) {
      return;
    }

    try {
      if (context.isRollbackOnly()) {
        await context.getConnection().rollbackTransaction();
        return;
      }

      await context.getConnection().commitTransaction();
    } finally {
      defaultStatus.markCompleted();
      await _releaseQuietly(context.getConnection());
    }
  }

  @override
  Future<void> rollback(TransactionStatus status) async {
    final defaultStatus = status as DefaultTransactionStatus;
    final context = defaultStatus.getContext();

    if (context == null) {
      return;
    }

    if (!defaultStatus.isNewTransaction()) {
      context.setRollbackOnly(true);
      defaultStatus.markCompleted();
      return;
    }

    try {
      await context.getConnection().rollbackTransaction();
    } finally {
      defaultStatus.markCompleted();
      await _releaseQuietly(context.getConnection());
    }
  }

  Future<void> _releaseQuietly(PooledConnection connection) async {
    try {
      await connection.close();
    } on Object {
      // Best-effort release.
    }
  }

  @override
  List<Object?> equalizedProperties() => [_factory, runtimeType];
}
