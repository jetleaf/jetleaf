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

/// 🔌 **JetLeaf Data Driver & Connection Pooling Library**
///
/// Exposes low-level database connectivity contracts and pooling primitives:
/// - [DatabaseClient] & [QueryResult] — dialect-agnostic SQL & document execution
/// - [ConnectionFactory], [ConnectionPool], [ConfigurableConnectionPool],
///   [DefaultConnectionPool], [PoolConfiguration], and [PooledConnection]
/// - [RowMapper] & [EntityRowMapper] — reflective hydration of rows/documents
///
/// ### Usage Example
/// ```dart
/// import 'package:jetleaf_data/driver.dart';
///
/// final pool = DefaultConnectionPool(
///   clientFactory: () async => myDatabaseClient,
///   configuration: const PoolConfiguration(maxConnections: 16),
/// );
/// final conn = await pool.getConnection();
/// ```
library;

export 'src/driver/connection_factory.dart';
export 'src/driver/connection_pool.dart';
export 'src/driver/database_client.dart';
export 'src/driver/default_connection_pool.dart';
export 'src/driver/entity_row_mapper.dart';
export 'src/driver/pooled_connection.dart';
export 'src/driver/query_result.dart';
export 'src/driver/row_mapper.dart';