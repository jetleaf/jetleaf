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

import 'default_transaction_status.dart';
import 'transaction_context.dart';
import 'transaction_definition.dart';

export 'default_transaction_status.dart';
export 'transaction_context.dart';

/// {@template jetleaf_transaction_status}
/// Represents the runtime execution status of a transactional participant.
///
/// ### See Also
/// - [DefaultTransactionStatus]
/// - [TransactionContext]
/// - [TransactionDefinition]
/// {@endtemplate}
abstract interface class TransactionStatus {
  /// Reflective [Class] handle for [TransactionStatus].
  static final Class<TransactionStatus> CLASS =
      Class<TransactionStatus>(null, PackageNames.DATA);

  /// Returns the [TransactionDefinition] governing this participant.
  TransactionDefinition getDefinition();

  /// Returns `true` if this participant started a new physical transaction.
  bool isNewTransaction();

  /// Returns `true` if the underlying transaction is marked rollback-only.
  bool isRollbackOnly();

  /// Marks the underlying transaction as rollback-only.
  void setRollbackOnly();

  /// Returns `true` if this transaction status has completed (committed or
  /// rolled back).
  bool isCompleted();

  /// Returns the shared [TransactionContext], or `null` when executing
  /// non-transactionally (`Propagation.supports` / `Propagation.notSupported`).
  TransactionContext? getContext();
}
