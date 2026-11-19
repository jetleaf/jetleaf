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

import 'configurable_connection_pool.dart';
import 'connection_factory.dart';
import 'default_connection_pool.dart';
import 'pool_configuration.dart';

export 'configurable_connection_pool.dart';
export 'default_connection_pool.dart';
export 'pool_configuration.dart';

/// {@template jetleaf_connection_pool}
/// Contract for a bounded, introspectable database [ConnectionFactory] pool.
///
/// Provides explicit methods to inspect pool capacity and utilization
/// ([getMaxConnections], [getActiveCount], [getIdleCount], [getLiveCount],
/// [isClosed]) and to proactively validate idle connections ([validate]).
///
/// ### Usage Example
/// ```dart
/// final pool = DefaultConnectionPool(
///   clientFactory: () async => MyDatabaseClient(),
///   configuration: const PoolConfiguration(maxConnections: 20),
/// );
///
/// print(pool.getMaxConnections()); // 20
/// print(pool.getActiveCount()); // 0
/// ```
///
/// ### See Also
/// - [ConfigurableConnectionPool]
/// - [DefaultConnectionPool]
/// - [PoolConfiguration]
/// - [ConnectionFactory]
/// {@endtemplate}
abstract interface class ConnectionPool implements ConnectionFactory {
  /// Reflective [Class] handle for [ConnectionPool].
  static final Class<ConnectionPool> CLASS =
      Class<ConnectionPool>(null, PackageNames.DATA);

  /// Returns the configured maximum number of connections.
  @override
  int getMaxConnections();

  /// Returns the number of connections currently leased out to callers.
  int getActiveCount();

  /// Returns the number of connections currently sitting idle in the pool.
  int getIdleCount();

  /// Returns the total number of live physical connections
  /// (`getActiveCount() + getIdleCount()`).
  int getLiveCount();

  /// Returns `true` if this pool has been closed.
  bool isClosed();

  /// Validates all currently idle connections, discarding any unhealthy ones.
  ///
  /// Returns `true` if all idle connections passed validation, or `false` if
  /// the pool is closed or at least one broken connection was evicted.
  Future<bool> validate();
}
