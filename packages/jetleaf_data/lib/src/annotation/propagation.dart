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

/// {@template jetleaf_propagation}
/// Defines **transaction propagation semantics** when a `@Transactional`
/// method is invoked inside or outside an ambient transaction.
///
/// | Value | Active Transaction Present | No Active Transaction |
/// |-------|----------------------------|-----------------------|
/// | [required] | Joins the active transaction | Starts a new transaction |
/// | [requiresNew] | Suspends the active transaction and starts a new one | Starts a new transaction |
/// | [mandatory] | Joins the active transaction | Throws `MandatoryTransactionException` |
/// | [supports] | Joins the active transaction | Executes non-transactionally |
/// | [notSupported] | Suspends the active transaction and executes non-transactionally | Executes non-transactionally |
/// | [never] | Throws `TransactionSystemException` | Executes non-transactionally |
/// {@endtemplate}
enum Propagation {
  /// Support a current transaction, create a new one if none exists.
  required,

  /// Create a new transaction, and suspend the current transaction if one exists.
  requiresNew,

  /// Support a current transaction, throw an exception if none exists.
  mandatory,

  /// Support a current transaction, execute non-transactionally if none exists.
  supports,

  /// Execute non-transactionally, suspend the current transaction if one exists.
  notSupported,

  /// Execute non-transactionally, throw an exception if a transaction exists.
  never,
}
