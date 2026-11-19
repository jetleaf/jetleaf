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

import 'package:jetleaf_core/core.dart' hide Repository;
import 'package:jetleaf_core/lang.dart';
import 'package:jetleaf_core/logging.dart';
import 'package:jetleaf_core/pod.dart';

import '../driver/connection_factory.dart';
import '../transaction/platform_transaction_manager.dart';
import '../transaction/transaction_interceptor.dart';

/// {@template jetleaf_transaction_manager_binder}
/// Infrastructure pod that activates the [TransactionalMethodInterceptor].
///
/// On application-context ready:
/// 1. If a [PlatformTransactionManager] pod exists, bind it.
/// 2. Else, if a [ConnectionFactory] pod exists, bind an implicit
///    [DataSourceTransactionManager] built from it.
/// 3. Otherwise the interceptor stays unbound — invoking a `@Transactional`
///    method then fails with a clear `TransactionSystemException`.
/// {@endtemplate}
final class TransactionManagerBinder
    with EqualsAndHashCode
    implements ApplicationContextAware, InitializingPod {
  /// Reflective class descriptor for [TransactionManagerBinder].
  static final Class<TransactionManagerBinder> CLASS =
      Class<TransactionManagerBinder>(null, PackageNames.DATA);

  ApplicationContext? _context;

  /// Logger used for startup diagnostics.
  final Log _logger = LogFactory.getLog("transactionManagerBinder");

  /// {@macro jetleaf_transaction_manager_binder}
  TransactionManagerBinder();

  @override
  String getPackageName() => PackageNames.DATA;

  @override
  List<Object?> equalizedProperties() => [runtimeType];

  @override
  Future<void> onReady() async {
    final context = _context;
    if (context == null) {
      return;
    }

    PlatformTransactionManager? manager;
    if (await context.containsType(PlatformTransactionManager.CLASS)) {
      manager = await context.get(PlatformTransactionManager.CLASS);
      _logger.info(
        "Bound TransactionalMethodInterceptor to the registered PlatformTransactionManager ${manager.runtimeType}",
      );
    } else if (await context.containsType(ConnectionFactory.CLASS)) {
      final factory = await context.get(ConnectionFactory.CLASS);
      manager = DataSourceTransactionManager(factory);
      _logger.info(
        "No PlatformTransactionManager found — created DataSourceTransactionManager from ConnectionFactory ${factory.runtimeType}",
      );
    }

    if (manager == null) {
      _logger.info(
        "No PlatformTransactionManager or ConnectionFactory pod found — @Transactional methods will fail with TransactionSystemException",
      );
      return;
    }

    if (await context.containsType(TransactionalMethodInterceptor.CLASS)) {
      final interceptor = await context.get(TransactionalMethodInterceptor.CLASS);
      interceptor.bind(manager);
    }
  }

  @override
  void setApplicationContext(ApplicationContext applicationContext) {
    _context = applicationContext;
  }
}
