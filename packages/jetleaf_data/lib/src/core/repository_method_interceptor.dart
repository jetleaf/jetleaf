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

import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/intercept.dart';
import 'package:jetleaf_core/lang.dart';

import '../../annotation.dart';
import '../event/repository_event.dart';
import 'repository_definition.dart';
import 'zone_repository_invocation_holder.dart';

/// {@template jetleaf_repository_method_interceptor}
/// A **method interceptor** for repository classes annotated with [Repository].
///
/// This interceptor hooks into repository method executions:
/// - Emits [InterceptedRepositoryMethodEvent] via the application event bus
///   before method execution.
/// - Binds the active [MethodInvocation] into [ZoneRepositoryInvocationHolder]
///   so `Repository.query()` / `DefaultRepositoryExecutor` can inspect the
///   reflected method and arguments for derived and `@Query`-annotated methods.
/// {@endtemplate}
abstract class RepositoryMethodInterceptor
    implements MethodInterceptor, MethodBeforeInterceptor, AroundMethodInterceptor {
  /// Reflective class descriptor for [RepositoryMethodInterceptor].
  static final Class<RepositoryMethodInterceptor> CLASS =
      Class<RepositoryMethodInterceptor>(null, PackageNames.DATA);

  /// Determines if the given [method] can be intercepted.
  ///
  /// Returns `true` if the declaring class of the method is annotated with [Repository].
  @override
  bool canIntercept(Method method) =>
      method.getDeclaringClass().hasDirectAnnotation<Repository>();

  @override
  FutureOr<void> beforeInvocation<T>(MethodInvocation<T> invocation) async {
    final definition = getDefinition(invocation.getMethod());
    if (definition == null) {
      return;
    }

    final eventBus = getEventBus();
    await eventBus.onEvent(
      InterceptedRepositoryMethodEvent(definition, invocation, DateTime.now()),
    );
  }

  @override
  Future<T?> aroundInvocation<T>(MethodInvocation<T> invocation) async {
    return ZoneRepositoryInvocationHolder.runWithInvocation(
      invocation,
      () async => await invocation.proceed(),
    );
  }

  /// Returns the repository-method definition associated with the given [method].
  RepositoryDefinition? getDefinition(Method method);

  /// Returns the application's event bus used to publish repository-related events.
  ApplicationEventBus getEventBus();
}
