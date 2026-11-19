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

import 'pooled_connection.dart';

/// {@template jetleaf_connection_factory}
/// Contract for acquiring [PooledConnection] instances on demand.
///
/// Implemented by connection pools (such as `DefaultConnectionPool`) and
/// driver-backed data sources.
///
/// ### See Also
/// - `ConnectionPool`
/// - [PooledConnection]
/// {@endtemplate}
abstract interface class ConnectionFactory {
  /// Reflective [Class] handle for [ConnectionFactory].
  static final Class<ConnectionFactory> CLASS =
      Class<ConnectionFactory>(null, PackageNames.DATA);

  /// Acquires a [PooledConnection], waiting up to the configured timeout when
  /// the underlying pool is at capacity.
  Future<PooledConnection> getConnection();

  /// Closes this factory and releases all underlying connections.
  Future<void> close();

  /// Returns the maximum number of connections this factory will open, or
  /// `null` if unbounded.
  int? getMaxConnections();
}
