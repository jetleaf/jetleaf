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

import 'package:jetleaf_core/intercept.dart';
import 'package:jetleaf_core/lang.dart';
import 'package:jetleaf_core/logging.dart';

import '../annotation/transactional.dart';
import '../exception/data_access_exception.dart';
import 'default_transaction_definition.dart';
import 'platform_transaction_manager.dart';
import 'zone_transaction_holder.dart';

/// {@template jetleaf_transactional_method_interceptor}
/// AOP [AroundMethodInterceptor] that enforces `@Transactional` boundaries on
/// intercepted pod methods.
///
/// ### Execution Lifecycle
/// 1. Resolves `@Transactional` metadata from the invoked method or its
///    declaring class.
/// 2. Acquires a `TransactionStatus` from the bound
///    [PlatformTransactionManager].
/// 3. Invokes `invocation.proceed()` inside a [Zone] bound to the transaction's
///    `TransactionContext`.
/// 4. Commits on normal return, or rolls back when a thrown exception/error
///    matches `rollbackFor` and is not excluded by `noRollbackFor`.
/// {@endtemplate}
final class TransactionalMethodInterceptor
    with EqualsAndHashCode
    implements AroundMethodInterceptor {
  /// Reflective [Class] handle for [TransactionalMethodInterceptor].
  static final Class<TransactionalMethodInterceptor> CLASS =
      Class<TransactionalMethodInterceptor>(null, PackageNames.DATA);

  /// Standard infrastructure pod name.
  static const String NAME = 'jetleaf.data.transactionalMethodInterceptor';

  PlatformTransactionManager? _transactionManager;
  final Log _logger = LogFactory.getLog('transactionalMethodInterceptor');

  /// {@macro jetleaf_transactional_method_interceptor}
  TransactionalMethodInterceptor([PlatformTransactionManager? manager])
      : _transactionManager = manager;

  /// Returns the bound [PlatformTransactionManager], or `null` if unbound.
  PlatformTransactionManager? getTransactionManager() => _transactionManager;

  /// Sets the [PlatformTransactionManager] used by this interceptor.
  void setTransactionManager(PlatformTransactionManager? manager) {
    _transactionManager = manager;
  }

  /// Binds [manager] to this interceptor (alias for [setTransactionManager]).
  void bind(PlatformTransactionManager manager) =>
      setTransactionManager(manager);

  @override
  bool canIntercept(Method method) {
    return method.getDirectAnnotation<Transactional>() != null ||
        method.getDeclaringClass().hasDirectAnnotation<Transactional>();
  }

  @override
  List<Object?> equalizedProperties() => [NAME, _transactionManager];

  @override
  Future<T?> aroundInvocation<T>(MethodInvocation<T> invocation) async {
    final annotation = _resolveAnnotation(invocation.getMethod());
    if (annotation == null) {
      return invocation.proceed();
    }

    final manager = _transactionManager;
    if (manager == null) {
      throw TransactionSystemException(
        '@Transactional found on ${invocation.getMethod().getName()} but no PlatformTransactionManager is registered — '
        'register one (e.g. DataSourceTransactionManager(connectionFactory)) to enable transactions',
      );
    }

    final definition = DefaultTransactionDefinition(
      propagation: annotation.getPropagation(),
      isolation: annotation.getIsolation(),
      timeoutSeconds: annotation.getTimeoutSeconds(),
      readOnly: annotation.isReadOnly(),
      rollbackFor: annotation.getRollbackFor(),
      noRollbackFor: annotation.getNoRollbackFor(),
      name:
          '${invocation.getTargetClass().getName()}#${invocation.getMethod().getName()}',
    );

    final status = await manager.getTransaction(definition);
    final context = status.getContext();

    try {
      final result = await ZoneTransactionHolder.run(
        context,
        () => invocation.proceed(),
      );
      await manager.commit(status);
      return result;
    } catch (error, stackTrace) {
      if (_shouldRollback(annotation, error)) {
        if (_logger.getIsDebugEnabled()) {
          _logger.debug(
            'Rolling back transaction for ${definition.getName()} due to $error',
          );
        }
        await manager.rollback(status);
      } else {
        await manager.commit(status);
      }

      if (error is Error) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      rethrow;
    }
  }

  Transactional? _resolveAnnotation(Method method) {
    return method.getDirectAnnotation<Transactional>() ??
        method.getDeclaringClass().getDirectAnnotation<Transactional>();
  }

  bool _shouldRollback(Transactional annotation, Object error) {
    final exempted = annotation
        .getNoRollbackFor()
        .any((type) => _matchesType(type, error));
    if (exempted) return false;

    return annotation
        .getRollbackFor()
        .any((type) => _matchesType(type, error));
  }

  bool _matchesType(ClassType<dynamic> classType, Object error) {
    var name = classType.name;
    if (name == null) {
      try {
        name = classType.getType().toString();
      } catch (_) {
        name = '';
      }
    }

    switch (name) {
      case 'Exception':
        return error is Exception;
      case 'Error':
        return error is Error;
      case 'Object':
      case 'dynamic':
        return true;
    }

    final current = error.runtimeType.toString().split('<').first;
    if (current == name.split('<').first) {
      return true;
    }

    try {
      return Class.forObject(error).isSubclassOf(classType.toClass());
    } catch (_) {
      return false;
    }
  }
}
