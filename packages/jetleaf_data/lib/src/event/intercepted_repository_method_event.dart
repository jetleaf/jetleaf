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

import 'repository_event.dart';

/// {@template jetleaf_intercepted_repository_method_event}
/// Event triggered when a **repository method is intercepted** by JetLeaf’s
/// method interception system.
///
/// Encapsulates a [MethodInvocation] to provide access to the intercepted call.
///
/// ### Usage Example
/// ```dart
/// final event = InterceptedRepositoryMethodEvent(myRepoDef, invocation, DateTime.now());
/// final invocation = event.getInvocation();
/// ```
/// {@endtemplate}
@Generic(InterceptedRepositoryMethodEvent)
final class InterceptedRepositoryMethodEvent<T> extends RepositoryEvent {
  /// Reflective class descriptor for [InterceptedRepositoryMethodEvent].
  static final Class<InterceptedRepositoryMethodEvent> CLASS =
      Class<InterceptedRepositoryMethodEvent>(null, PackageNames.DATA);

  /// The intercepted method invocation.
  final MethodInvocation<T> _invocation;

  /// {@macro jetleaf_intercepted_repository_method_event}
  const InterceptedRepositoryMethodEvent(super.source, this._invocation, super.timestamp);

  /// Returns the [MethodInvocation] associated with this intercepted event.
  MethodInvocation<T> getInvocation() => _invocation;
}
