import 'package:jetleaf_core/lang.dart' show IllegalStateException;
import 'dart:async';

import 'security_context.dart';

/// {@template security_context_holder}
/// Associates a [SecurityContext] with the current asynchronous execution flow
/// using a forked [Zone], so concurrent requests on one isolate never share
/// mutable security state.
///
/// There is deliberately no process-global fallback: [getContext] outside a
/// bound zone returns a fresh empty context. The only way to bind a context is
/// [runWithContext], and [setContext] refuses to mutate a context that was not
/// bound explicitly.
///
/// ### Zone-safety
/// - Each request should run inside its own [runWithContext] scope.
/// - The binding is restored automatically when the zone exits.
/// - [clearContext] is safe outside a zone, where it becomes a no-op.
///
/// ### Example
/// ```dart
/// SecurityContextHolder.runWithContext(() async {
///   SecurityContextHolder.setContext(SecurityContext(token));
///   final current = SecurityContextHolder.getContext();
///   assert(current.authentication == token);
/// });
/// ```
///
/// ### See also
/// - [SecurityContext] — the value stored in the zone.
/// {@endtemplate}
abstract final class SecurityContextHolder {
  /// Private zone key used to store the context.
  static const Symbol _contextKey = #jetleafSecurityContext;

  /// {@macro security_context_holder}
  const SecurityContextHolder._();

  /// Returns the [SecurityContext] bound to the current [Zone].
  ///
  /// ### Returns
  /// The bound context, or a fresh empty context when called outside a
  /// [runWithContext] scope. The returned fallback is not installed in the
  /// zone, so each unbound call gets its own instance.
  static SecurityContext getContext() {
    final value = Zone.current[_contextKey];
    return value is SecurityContext ? value : SecurityContext();
  }

  /// Whether a security context is bound to the current zone.
  ///
  /// ### Returns
  /// `true` only when the current zone was created by [runWithContext].
  static bool hasContext() => Zone.current[_contextKey] is SecurityContext;

  /// Executes [fn] in a forked zone bound to a context.
  ///
  /// ### Parameters
  /// - [fn]: the body to execute; asynchronous work it starts inherits the
  ///   binding.
  /// - [context]: the context to bind, or `null` to bind a fresh empty one.
  ///
  /// ### Returns
  /// Whatever [fn] returns. The previous zone binding is restored afterwards.
  ///
  /// ### Example
  /// ```dart
  /// await SecurityContextHolder.runWithContext(() => handler(request));
  /// ```
  static R runWithContext<R>(R Function() fn, [SecurityContext? context]) {
    return runZoned(fn, zoneValues: {_contextKey: context ?? SecurityContext()});
  }

  /// Replaces the authentication of the currently bound context.
  ///
  /// ### Parameters
  /// - [context]: the context whose authentication is copied into the bound
  ///   instance; other state on the bound context is left untouched.
  ///
  /// ### Throws
  /// [StateError] when called outside a zone created by [runWithContext].
  static void setContext(SecurityContext context) {
    final value = Zone.current[_contextKey];
    if (value is! SecurityContext) {
      throw IllegalStateException('No security context is bound to the current zone');
    }
    
    value.authentication = context.authentication;
  }

  /// Clears the authentication of the currently bound context.
  ///
  /// Safe to call outside a zone: it becomes a no-op.
  static void clearContext() {
    final value = Zone.current[_contextKey];
    if (value is SecurityContext) {
      value.authentication = null;
    }
  }

  /// Creates a new empty [SecurityContext].
  ///
  /// ### Returns
  /// A context with no authentication; callers may bind it with
  /// [runWithContext].
  static SecurityContext createEmptyContext() => SecurityContext();
}
