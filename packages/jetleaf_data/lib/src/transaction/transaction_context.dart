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

import '../driver/pooled_connection.dart';
import 'transaction_definition.dart';

/// {@template jetleaf_transaction_context}
/// Shared state of a single physical transaction bound to a Dart `Zone`.
///
/// All participants joining an active transaction share the same
/// [TransactionContext] instance, allowing inner participants to mark the
/// outer physical transaction as rollback-only via [setRollbackOnly].
///
/// ### See Also
/// - `TransactionStatus`
/// - `ZoneTransactionHolder`
/// {@endtemplate}
final class TransactionContext with EqualsAndHashCode {
  /// Reflective [Class] handle for [TransactionContext].
  static final Class<TransactionContext> CLASS =
      Class<TransactionContext>(null, PackageNames.DATA);

  final PooledConnection _connection;
  final TransactionDefinition _definition;
  bool _rollbackOnly = false;

  /// {@macro jetleaf_transaction_context}
  TransactionContext({
    required PooledConnection connection,
    required TransactionDefinition definition,
  })  : _connection = connection,
        _definition = definition;

  /// Returns the leased [PooledConnection] backing this transaction.
  PooledConnection getConnection() => _connection;

  /// Returns the [TransactionDefinition] that started this transaction.
  TransactionDefinition getDefinition() => _definition;

  /// Returns `true` if any participant has marked this transaction
  /// rollback-only.
  bool isRollbackOnly() => _rollbackOnly;

  /// Marks this physical transaction as rollback-only.
  void setRollbackOnly([bool rollbackOnly = true]) {
    _rollbackOnly = rollbackOnly;
  }

  @override
  List<Object?> equalizedProperties() => [
        _connection,
        _definition,
        _rollbackOnly,
      ];
}
