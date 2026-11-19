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
import 'package:jetleaf_core/pod.dart';

import '../exception/data_access_exception.dart';
import 'configurable_connection_pool.dart';
import 'database_client.dart';
import 'pool_configuration.dart';
import 'pooled_connection.dart';

/// {@template jetleaf_default_connection_pool}
/// Default bounded implementation of [ConfigurableConnectionPool] with
/// waiter queueing, connection validation, automatic uncommitted transaction
/// rollback on lease release, and `DisposablePod` container lifecycle
/// integration.
///
/// ### Lifecycle & Contention Semantics
/// 1. Reuses validated idle connections in LIFO order.
/// 2. Opens new physical connections lazily up to [getMaxConnections].
/// 3. Queues callers in FIFO order when at capacity, timing out after
///    `PoolConfiguration.getConnectionTimeout()` with a
///    [CannotGetDatabaseConnectionException].
/// 4. Implements [DisposablePod] so the pool drains and closes cleanly when
///    the `ApplicationContext` shuts down.
///
/// ### See Also
/// - [ConnectionPool]
/// - [ConfigurableConnectionPool]
/// - [PoolConfiguration]
/// {@endtemplate}
final class DefaultConnectionPool
    with EqualsAndHashCode
    implements ConfigurableConnectionPool, DisposablePod {
  /// Reflective [Class] handle for [DefaultConnectionPool].
  static final Class<DefaultConnectionPool> CLASS =
      Class<DefaultConnectionPool>(null, PackageNames.DATA);

  final Future<DatabaseClient> Function() _clientFactory;
  PoolConfiguration _configuration;

  final List<_PoolEntry> _idle = [];
  final Set<PooledConnection> _active = {};
  final List<Completer<PooledConnection>> _waiters = [];

  bool _closed = false;

  /// {@macro jetleaf_default_connection_pool}
  DefaultConnectionPool({
    required Future<DatabaseClient> Function() clientFactory,
    PoolConfiguration? configuration,
  })  : _clientFactory = clientFactory,
        _configuration = configuration ?? const PoolConfiguration();

  @override
  String getPackageName() => PackageNames.DATA;

  @override
  PoolConfiguration getConfiguration() => _configuration;

  @override
  void setConfiguration(PoolConfiguration configuration) {
    _configuration = configuration;
  }

  @override
  void setMaxConnections(int maxConnections) {
    _configuration = _configuration.copyWith(maxConnections: maxConnections);
  }

  @override
  void setConnectionTimeout(Duration timeout) {
    _configuration = _configuration.copyWith(connectionTimeout: timeout);
  }

  @override
  void setValidateOnCheckout(bool validateOnCheckout) {
    _configuration =
        _configuration.copyWith(validateOnCheckout: validateOnCheckout);
  }

  @override
  int getMaxConnections() => _configuration.getMaxConnections();

  @override
  int getActiveCount() => _active.length;

  @override
  int getIdleCount() => _idle.length;

  @override
  int getLiveCount() => _active.length + _idle.length;

  @override
  bool isClosed() => _closed;

  @override
  Future<PooledConnection> getConnection() async {
    _checkClosed();

    // 1. Reuse an idle connection when available and valid.
    while (_idle.isNotEmpty) {
      final entry = _idle.removeLast();
      if (!entry.retired &&
          (!_configuration.shouldValidateOnCheckout() ||
              await _validateEntry(entry))) {
        final connection = _lease(entry);
        _active.add(connection);
        return connection;
      }

      await _destroyEntry(entry);
    }

    // 2. Open a new physical connection when below capacity.
    if (getLiveCount() < getMaxConnections()) {
      final entry = await _openEntry();
      final connection = _lease(entry);
      _active.add(connection);
      return connection;
    }

    // 3. Otherwise wait for an active lease to be released.
    return _awaitRelease();
  }

  Future<_PoolEntry> _openEntry() async {
    final client = await _clientFactory();
    return _PoolEntry(client);
  }

  Future<bool> _validateEntry(_PoolEntry entry) async {
    try {
      return await entry.client.isValid(_configuration.getValidationQuery());
    } on Object {
      return false;
    }
  }

  PooledConnection _lease(_PoolEntry entry) {
    late PooledConnection connection;
    connection = PooledConnection(
      entry.client,
      onClose: (lease, _) async {
        _active.remove(lease);
        await _releaseEntry(entry);
      },
    );
    return connection;
  }

  Future<PooledConnection> _awaitRelease() {
    final completer = Completer<PooledConnection>();
    _waiters.add(completer);

    final timeout = _configuration.getConnectionTimeout();
    return completer.future.timeout(
      timeout,
      onTimeout: () {
        _waiters.remove(completer);
        throw CannotGetDatabaseConnectionException(
          'Timed out after ${timeout.inSeconds}s waiting for a database connection',
        );
      },
    );
  }

  Future<void> _releaseEntry(_PoolEntry entry) async {
    while (_waiters.isNotEmpty) {
      final waiter = _waiters.removeAt(0);
      if (waiter.isCompleted) {
        continue;
      }

      final connection = _lease(entry);
      _active.add(connection);
      waiter.complete(connection);
      return;
    }

    if (_closed) {
      await _destroyEntry(entry);
      return;
    }

    _idle.add(entry);
  }

  Future<void> _destroyEntry(_PoolEntry entry) async {
    entry.retired = true;
    try {
      await entry.client.close();
    } on Object {
      // Best-effort close.
    }
  }

  void _checkClosed() {
    if (_closed) {
      throw CannotGetDatabaseConnectionException(
        'Connection pool has been closed',
      );
    }
  }

  @override
  Future<bool> validate() async {
    if (_closed) return false;

    var healthy = true;
    final survivors = <_PoolEntry>[];
    for (final entry in _idle) {
      if (await _validateEntry(entry)) {
        survivors.add(entry);
        continue;
      }
      healthy = false;
      await _destroyEntry(entry);
    }

    _idle
      ..clear()
      ..addAll(survivors);

    return healthy;
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;

    for (final waiter in _waiters) {
      if (!waiter.isCompleted) {
        waiter.completeError(
          CannotGetDatabaseConnectionException('Connection pool has been closed'),
        );
      }
    }
    _waiters.clear();

    for (final entry in _idle) {
      await _destroyEntry(entry);
    }
    _idle.clear();

    for (final connection in _active.toList()) {
      try {
        await connection.close();
      } on Object {
        // Ignore broken lease during shutdown.
      }
    }
    _active.clear();
  }

  @override
  Future<void> onDestroy() => close();

  @override
  List<Object?> equalizedProperties() => [_configuration, _closed, runtimeType];
}

final class _PoolEntry {
  final DatabaseClient client;
  bool retired = false;

  _PoolEntry(this.client);
}
