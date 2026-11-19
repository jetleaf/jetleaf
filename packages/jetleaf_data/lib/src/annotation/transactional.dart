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

import 'isolation.dart';
import 'propagation.dart';

export 'isolation.dart';
export 'propagation.dart';

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

  /// Returns the configured [Propagation] rule.
  Propagation getPropagation() => propagation;

  /// Returns the configured [Isolation] level.
  Isolation getIsolation() => isolation;

  /// Returns the configured timeout in seconds.
  int getTimeoutSeconds() => timeoutSeconds;

  /// Returns `true` if the transaction is read-only.
  bool isReadOnly() => readOnly;

  /// Returns the list of throwable types that trigger a rollback.
  List<ClassType<dynamic>> getRollbackFor() => rollbackFor;

  /// Returns the list of throwable types exempt from rollback.
  List<ClassType<dynamic>> getNoRollbackFor() => noRollbackFor;

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
