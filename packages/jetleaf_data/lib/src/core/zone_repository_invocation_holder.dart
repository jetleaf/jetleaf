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

import 'package:jetleaf_core/intercept.dart';
import 'package:jetleaf_core/lang.dart';

/// {@template jetleaf_zone_repository_invocation_holder}
/// Zone-local holder for the currently intercepted repository [MethodInvocation].
///
/// When a method on a `@Repository`-annotated class is intercepted by
/// `RepositoryMethodInterceptor`, the active [MethodInvocation] is bound into
/// a child [Zone] via [runWithInvocation]. That allows helper methods on
/// `Repository` (such as `query<U>()`, `queryList<U>()`, `queryIterable<U>()`)
/// and `DefaultRepositoryExecutor` to inspect the currently executing
/// repository method (its name, annotations, and arguments) and derive or
/// execute the corresponding query automatically.
/// {@endtemplate}
final class ZoneRepositoryInvocationHolder {
  /// Reflective class descriptor for [ZoneRepositoryInvocationHolder].
  static final Class<ZoneRepositoryInvocationHolder> CLASS = Class<ZoneRepositoryInvocationHolder>(null, PackageNames.DATA);

  static final Object _zoneKey = Object();

  const ZoneRepositoryInvocationHolder._();

  /// Returns the [MethodInvocation] bound in the current [Zone], or `null` if
  /// execution is outside an intercepted repository method.
  static MethodInvocation<dynamic>? getCurrent() => Zone.current[_zoneKey] as MethodInvocation<dynamic>?;

  /// Returns `true` when a repository [MethodInvocation] is active in the
  /// current [Zone].
  static bool hasActiveInvocation() => getCurrent() != null;

  /// Executes [action] inside a child [Zone] with [invocation] bound as the
  /// active repository method invocation.
  static R runWithInvocation<R>(MethodInvocation<dynamic> invocation, R Function() action) {
    return runZoned(action, zoneValues: {_zoneKey: invocation});
  }
}