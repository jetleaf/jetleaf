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

/// {@template jetleaf_default_transaction_status}
/// Default implementation of [TransactionStatus].
/// {@endtemplate}
final class DefaultTransactionStatus with EqualsAndHashCode implements TransactionStatus {
  /// Reflective [Class] handle for [DefaultTransactionStatus].
  static final Class<DefaultTransactionStatus> CLASS =  Class<DefaultTransactionStatus>(null, PackageNames.DATA);

  final TransactionDefinition _definition;
  final TransactionContext? _context;
  final bool _newTransaction;
  bool _completed = false;

  /// {@macro jetleaf_default_transaction_status}
  DefaultTransactionStatus({
    required TransactionDefinition definition,
    required TransactionContext? context,
    required bool newTransaction,
  })  : _definition = definition,
        _context = context,
        _newTransaction = newTransaction;

  /// Creates an unbound [DefaultTransactionStatus] for non-transactional
  /// execution boundaries (`Propagation.supports`, `Propagation.notSupported`,
  /// `Propagation.never`).
  DefaultTransactionStatus.unbound(this._definition)
    : _context = null,
      _newTransaction = false;

  @override
  TransactionDefinition getDefinition() => _definition;

  @override
  bool isNewTransaction() => _newTransaction;

  @override
  bool isRollbackOnly() => _context?.isRollbackOnly() ?? false;

  @override
  void setRollbackOnly() => _context?.setRollbackOnly(true);

  @override
  bool isCompleted() => _completed;

  /// Marks this status as completed.
  void markCompleted() => _completed = true;

  @override
  TransactionContext? getContext() => _context;

  @override
  List<Object?> equalizedProperties() => [
    _definition,
    _context,
    _newTransaction,
    _completed,
  ];
}