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

import 'connection_pool.dart';

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
  static final Class<ConfigurableConnectionPool> CLASS =
      Class<ConfigurableConnectionPool>(null, PackageNames.DATA);

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
