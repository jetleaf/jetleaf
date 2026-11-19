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

/// {@template jetleaf_pool_configuration}
/// Immutable configuration settings for a `ConnectionPool`.
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
/// - `ConnectionPool`
/// - `ConfigurableConnectionPool`
/// - `DefaultConnectionPool`
/// {@endtemplate}
final class PoolConfiguration with EqualsAndHashCode {
  /// Reflective [Class] handle for [PoolConfiguration].
  static final Class<PoolConfiguration> CLASS =
      Class<PoolConfiguration>(null, PackageNames.DATA);

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
  }) =>
      PoolConfiguration(
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
