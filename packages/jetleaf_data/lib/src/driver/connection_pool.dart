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

import 'connection_factory.dart';

/// {@template jetleaf_pool_configuration}
/// Immutable configuration settings for a [ConnectionPool].
///
/// ### Settings
/// - [getMaxConnections] — maximum concurrent physical connections (default: `10`).
/// - [getConnectionTimeout] — maximum wait duration when checking out a
///   connection from an exhausted pool (default: `30s`).
/// - [shouldValidateOnCheckout] — whether idle connections are validated before
///   checkout (default: `true`).
/// - [getValidationQuery] — probe query executed for SQL validation
///   (default: `'SELECT 1'`).
///
/// ### See Also
/// - [ConnectionPool]
/// - `ConfigurableConnectionPool`
/// - `DefaultConnectionPool`
/// {@endtemplate}
final class PoolConfiguration with EqualsAndHashCode {
  /// Reflective [Class] handle for [PoolConfiguration].
  static final Class<PoolConfiguration> CLASS = Class<PoolConfiguration>(null, PackageNames.DATA);

  final int _maxConnections;
  final Duration _connectionTimeout;
  final bool _validateOnCheckout;
  final String _validationQuery;

  /// {@macro jetleaf_pool_configuration}
  const PoolConfiguration({
    int maxConnections = 10,
    Duration connectionTimeout = const Duration(seconds: 30),
    bool validateOnCheckout = true,
    String validationQuery = 'SELECT 1',
  })  : _maxConnections = maxConnections,
        _connectionTimeout = connectionTimeout,
        _validateOnCheckout = validateOnCheckout,
        _validationQuery = validationQuery;

  /// Returns the maximum number of physical connections the pool may open.
  int getMaxConnections() => _maxConnections;

  /// Returns the maximum wait duration before a connection checkout times out.
  Duration getConnectionTimeout() => _connectionTimeout;

  /// Returns `true` if idle connections are validated prior to checkout.
  bool shouldValidateOnCheckout() => _validateOnCheckout;

  /// Returns the SQL probe query used to validate idle connections.
  String getValidationQuery() => _validationQuery;

  /// Returns a new [PoolConfiguration] with updated settings.
  PoolConfiguration copyWith({
    int? maxConnections,
    Duration? connectionTimeout,
    bool? validateOnCheckout,
    String? validationQuery,
  }) => PoolConfiguration(
    maxConnections: maxConnections ?? _maxConnections,
    connectionTimeout: connectionTimeout ?? _connectionTimeout,
    validateOnCheckout: validateOnCheckout ?? _validateOnCheckout,
    validationQuery: validationQuery ?? _validationQuery,
  );

  @override
  List<Object?> equalizedProperties() => [
    _maxConnections,
    _connectionTimeout,
    _validateOnCheckout,
    _validationQuery,
  ];
}

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
  static final Class<ConnectionPool> CLASS = Class<ConnectionPool>(null, PackageNames.DATA);

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

/// {@template jetleaf_configurable_connection_pool}
/// Configurable extension of [ConnectionPool] allowing runtime adjustment of
/// pool sizing, checkout timeouts, and validation behavior.
///
/// ### See Also
/// - [ConnectionPool]
/// - [PoolConfiguration]
/// - `DefaultConnectionPool`
/// {@endtemplate}
abstract interface class ConfigurableConnectionPool implements ConnectionPool {
  /// Reflective [Class] handle for [ConfigurableConnectionPool].
  static final Class<ConfigurableConnectionPool> CLASS = Class<ConfigurableConnectionPool>(null, PackageNames.DATA);

  /// Returns the active [PoolConfiguration].
  PoolConfiguration getConfiguration();

  /// Replaces the active [PoolConfiguration].
  void setConfiguration(PoolConfiguration configuration);

  /// Sets the maximum number of connections allowed in the pool.
  void setMaxConnections(int maxConnections);

  /// Sets the maximum duration to wait when checking out a connection.
  void setConnectionTimeout(Duration timeout);

  /// Sets whether idle connections should be validated before checkout.
  void setValidateOnCheckout(bool validateOnCheckout);
}