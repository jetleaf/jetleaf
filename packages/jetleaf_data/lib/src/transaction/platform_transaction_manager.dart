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

import 'transaction_definition.dart';
import 'transaction_status.dart';

/// {@template jetleaf_platform_transaction_manager}
/// Central strategy interface in JetLeaf Data's transaction infrastructure.
///
/// Coordinates transaction creation, propagation, commitment, and rollback.
///
/// ### See Also
/// - [DataSourceTransactionManager]
/// - [TransactionDefinition]
/// - [TransactionStatus]
/// {@endtemplate}
abstract class PlatformTransactionManager with EqualsAndHashCode {
  /// Reflective [Class] handle for [PlatformTransactionManager].
  static final Class<PlatformTransactionManager> CLASS = Class<PlatformTransactionManager>(null, PackageNames.DATA);

  /// {@macro jetleaf_platform_transaction_manager}
  const PlatformTransactionManager();

  /// Returns a [TransactionStatus] for a new or existing transaction according
  /// to [definition].
  Future<TransactionStatus> getTransaction(TransactionDefinition? definition);

  /// Commits the transaction represented by [status], or rolls back if marked
  /// rollback-only.
  Future<void> commit(TransactionStatus status);

  /// Rolls back the transaction represented by [status], or marks the shared
  /// transaction rollback-only when participating in an outer transaction.
  Future<void> rollback(TransactionStatus status);

  @override
  List<Object?> equalizedProperties() => [runtimeType];
}