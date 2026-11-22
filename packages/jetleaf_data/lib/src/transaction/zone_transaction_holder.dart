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

import 'dart:async';

import 'package:jetleaf_core/lang.dart';

import 'transaction_status.dart';

/// {@template jetleaf_zone_transaction_holder}
/// Zone-scoped holder for the **ambient [TransactionContext]**.
///
/// Binds active database transactions to Dart's [Zone] hierarchy so concurrent
/// asynchronous operations within the same isolate remain completely isolated,
/// and `Propagation.requiresNew` / `Propagation.notSupported` can suspend or
/// shadow outer transactions by forking a child [Zone].
/// {@endtemplate}
final class ZoneTransactionHolder {
  /// Reflective [Class] handle for [ZoneTransactionHolder].
  static final Class<ZoneTransactionHolder> CLASS = Class<ZoneTransactionHolder>(null, PackageNames.DATA);

  static const Symbol _transactionKey = #jetleaf_zone_transaction;

  const ZoneTransactionHolder._();

  /// Returns the [TransactionContext] bound to the current [Zone], or `null`
  /// when no transaction is active.
  static TransactionContext? getCurrent() => Zone.current[_transactionKey] as TransactionContext?;

  /// Returns `true` if a [TransactionContext] is bound to the current [Zone].
  static bool hasActiveTransaction() => getCurrent() != null;

  /// Executes [body] inside a forked [Zone] bound to [context] (or shadowing
  /// any outer transaction when [context] is `null`).
  static Future<T> run<T>(TransactionContext? context, Future<T> Function() body) {
    return Zone.current.fork(zoneValues: {_transactionKey: context}).run(body);
  }

  /// Executes [body] inside a forked [Zone] with no active transaction.
  static Future<T> runWithout<T>(Future<T> Function() body) => run(null, body);

  /// Synchronous variant of [run].
  static T runSync<T>(TransactionContext? context, T Function() body) {
    return Zone.current.fork(zoneValues: {_transactionKey: context}).run(body);
  }
}