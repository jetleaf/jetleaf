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

import '../annotation/transactional.dart';

/// {@template jetleaf_transaction_definition}
/// Contract describing the **propagation, isolation, timeout, read-only, and
/// rollback attributes** of a transaction.
///
/// ### See Also
/// - `DefaultTransactionDefinition`
/// - `PlatformTransactionManager`
/// - `TransactionStatus`
/// {@endtemplate}
abstract interface class TransactionDefinition {
  /// Reflective [Class] handle for [TransactionDefinition].
  static final Class<TransactionDefinition> CLASS = Class<TransactionDefinition>(null, PackageNames.DATA);

  /// Returns the [Propagation] behavior.
  Propagation getPropagation();

  /// Returns the [Isolation] level.
  Isolation getIsolation();

  /// Returns the transaction timeout in seconds.
  int getTimeoutSeconds();

  /// Returns `true` if the transaction is read-only.
  bool isReadOnly();

  /// Returns the throwable types that trigger a rollback.
  List<ClassType<dynamic>> getRollbackFor();

  /// Returns the throwable types exempt from triggering a rollback.
  List<ClassType<dynamic>> getNoRollbackFor();

  /// Returns the descriptive name of this transaction, if any.
  String? getName();
}