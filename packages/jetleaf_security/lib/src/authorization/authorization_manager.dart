import '../core/typedefs.dart';
import 'package:jetleaf_web/jetleaf_web.dart';

import '../core/authentication.dart';
import 'authorization_decision.dart';

/// {@template request_authorization_context}
/// The context supplied to request-level authorization managers.
///
/// It bundles the incoming [ServerHttpRequest] with any URI template variables
/// extracted during path matching, giving rules access to both the request and
/// the route parameters that led to it.
///
/// ### Contract and invariants
/// - [request] is the request being authorized and is never `null`.
/// - [variables] defaults to an empty, unmodifiable map.
/// - Instances are immutable and safe to pass to several managers in sequence.
///
/// ### Example
/// ```dart
/// const context = RequestAuthorizationContext(request);
/// final decision = manager.check(() => currentAuthentication(), context);
/// ```
///
/// ### See also
/// - [AuthorizationManager]
/// {@endtemplate}
final class RequestAuthorizationContext {
  /// The request being authorized.
  final ServerHttpRequest request;

  /// Optional URI template variables extracted by path matching.
  final Map<String, String> variables;

  /// {@macro request_authorization_context}
  const RequestAuthorizationContext(this.request, {this.variables = const {}});
}

/// {@template authorization_manager}
/// A typed contract for deciding whether access should be granted.
///
/// An authorization manager evaluates a [context] of type `T` and returns an
/// [AuthorizationDecision]. The current authentication is supplied as a
/// zero-argument callback rather than as a value so it is resolved lazily: a
/// rule such as "permit all" never needs to read the security context.
///
/// ### Contract
/// - [check] must return an [AuthorizationDecision]; it never returns `null`.
/// - The authentication callback may return `null` for anonymous requests, and
///   managers must handle that case explicitly.
/// - Implementations must be deterministic for a given authentication and
///   context and safe to call concurrently.
/// - Implementations should avoid mutating [context] or the supplied
///   authentication object.
///
/// ### Example
/// ```dart
/// final class HasRoleManager
///     implements AuthorizationManager<RequestAuthorizationContext> {
///   const HasRoleManager(this.role);
///
///   final String role;
///
///   @override
///   AuthorizationDecision check(
///     AuthenticationSupplier authentication,
///     RequestAuthorizationContext context,
///   ) {
///     final principal = authentication();
///     if (principal == null) return AuthorizationDecision.denied;
///     final granted = principal.authorities.any((a) => a.authority == role);
///     return granted ? AuthorizationDecision.granted : AuthorizationDecision.denied;
///   }
/// }
/// ```
///
/// ### See also
/// - [AuthorizationDecision]
/// - [RequestAuthorizationContext]
/// - [AuthorizationManagers]
/// {@endtemplate}
abstract interface class AuthorizationManager<T> {
  /// Decides whether access is granted for [context].
  ///
  /// ### Parameters
  /// - [authentication] — a callback returning the current [Authentication], or
  ///   `null` for an anonymous request. It is invoked only when the rule needs
  ///   the identity.
  /// - [context] — the value being authorized, such as a
  ///   [RequestAuthorizationContext] or a method-invocation descriptor.
  ///
  /// ### Returns
  /// An [AuthorizationDecision] describing whether access is granted.
  ///
  /// ### Example
  /// ```dart
  /// final decision = manager.check(() => securityContext.authentication, context);
  /// if (!decision.isGranted) {
  ///   await entryPoint.commence(request, response, exception);
  /// }
  /// ```
  AuthorizationDecision check(AuthenticationSupplier authentication, T context);
}
