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
import 'package:meta/meta_meta.dart';

/// {@template jetleaf_isolation}
/// Defines the **SQL transaction isolation level** requested for a
/// `@Transactional` execution boundary.
///
/// | Level | Dirty Reads | Non-Repeatable Reads | Phantom Reads |
/// |-------|-------------|----------------------|---------------|
/// | [readUncommitted] | Allowed | Allowed | Allowed |
/// | [readCommitted] | Prevented | Allowed | Allowed |
/// | [repeatableRead] | Prevented | Prevented | Allowed |
/// | [serializable] | Prevented | Prevented | Prevented |
/// {@endtemplate}
enum Isolation {
  /// Allows dirty reads, non-repeatable reads, and phantom reads.
  readUncommitted,

  /// Prevents dirty reads; default for most relational engines.
  readCommitted,

  /// Prevents dirty reads and non-repeatable reads.
  repeatableRead,

  /// Prevents dirty reads, non-repeatable reads, and phantom reads.
  serializable,
}

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

/// {@template jetleaf_transactional_annotation}
/// Declares **transactional execution semantics** on a method or all methods
/// of a class.
///
/// Intercepted by `TransactionalMethodInterceptor`, which coordinates with the
/// active `PlatformTransactionManager` to bind a connection to the current
/// Dart `Zone`, commit on clean exit, and roll back when an uncaught throwable
/// matches [rollbackFor] (and is not excluded by [noRollbackFor]).
///
/// ### Usage Example
/// ```dart
/// @Service()
/// class TransferService {
///   @Transactional(propagation: Propagation.required, isolation: Isolation.serializable)
///   Future<void> transfer(String fromId, String toId, int amount) async {
///     // Executed atomically within a single transaction
///   }
/// }
/// ```
///
/// ### See Also
/// - [Propagation]
/// - [Isolation]
/// {@endtemplate}
@Target({TargetKind.method, TargetKind.classType})
final class Transactional extends ReflectableAnnotation with EqualsAndHashCode {
  /// Reflective [Class] handle for [Transactional].
  static final Class<Transactional> CLASS = Class<Transactional>(null, PackageNames.DATA);

  /// The transaction propagation behavior.
  final Propagation propagation;

  /// The transaction isolation level.
  final Isolation isolation;

  /// Transaction timeout in seconds.
  final int timeoutSeconds;

  /// Whether the transaction is effectively read-only.
  final bool readOnly;

  /// Throwable types that trigger a transaction rollback.
  final List<ClassType<dynamic>> rollbackFor;

  /// Throwable types that must not trigger a transaction rollback.
  final List<ClassType<dynamic>> noRollbackFor;

  /// {@macro jetleaf_transactional_annotation}
  const Transactional({
    this.propagation = Propagation.required,
    this.isolation = Isolation.readCommitted,
    this.timeoutSeconds = 30,
    this.readOnly = false,
    this.rollbackFor = const [ClassType<Exception>(), ClassType<Error>()],
    this.noRollbackFor = const [],
  });

  @override
  Type get annotationType => Transactional;

  @override
  List<Object?> equalizedProperties() => [
    propagation,
    isolation,
    timeoutSeconds,
    readOnly,
    rollbackFor,
    noRollbackFor,
  ];
}