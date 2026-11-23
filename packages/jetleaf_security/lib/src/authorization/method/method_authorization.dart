import '../../core/typedefs.dart';
import 'package:jetleaf_core/intercept.dart';

import '../../core/authentication.dart';
import '../authorization_decision.dart';
import '../authorization_manager.dart';
import '../expression_parser.dart';
import '../role_hierarchy.dart';

/// {@template method_authorization_context}
/// Context passed to method authorization managers.
///
/// It carries the reflective [invocation] when available, the named method
/// [arguments] referenced by `#`-prefixed expression variables, and the
/// [returnObject] that only post-authorization managers receive.
///
/// ### Contract
/// - [invocation] may be `null` when the caller drives the invocation manually.
/// - [arguments] is keyed by source parameter name; an empty map means no
///   parameters can be referenced from the expression.
/// - [returnObject] is `null` during pre-authorization.
///
/// ### Example
/// ```dart
/// final context = MethodAuthorizationContext(
///   invocation: invocation,
///   arguments: {'userId': 'alice'},
/// );
/// ```
/// {@endtemplate}
final class MethodAuthorizationContext {
  /// The reflective invocation being authorized, when available.
  final MethodInvocation? invocation;

  /// Named method arguments, bound from reflection.
  final Map<String, Object?> arguments;

  /// Return value, available only to post-authorization managers.
  final Object? returnObject;

  /// {@macro method_authorization_context}
  ///
  /// Creates an immutable authorization context.
  ///
  /// ### Parameters
  /// - [invocation]: the method invocation, when the pipeline provides one.
  /// - [arguments]: named arguments exposed to the expression language.
  /// - [returnObject]: the guarded method's result for post-authorization.
  const MethodAuthorizationContext({
    this.invocation,
    this.arguments = const {},
    this.returnObject,
  });
}

/// {@template pre_authorize_authorization_manager}
/// Evaluates a `@PreAuthorize` expression before a method is invoked.
///
/// The expression is evaluated against the current authentication and the
/// named arguments in [MethodAuthorizationContext.arguments]. A `true` result
/// grants access; a denied [AuthorizationDecision] lets the caller abort the
/// invocation.
///
/// ### Contract and invariants
/// - [expression] is stored verbatim and parsed by the configured
///   [SecurityExpressionParser].
/// - No return object is supplied; `returnObject.*` is not meaningful here.
/// - A configured [RoleHierarchy] is forwarded to the expression context, so
///   `hasRole` and `hasAnyRole` see implied authorities.
/// - Malformed expressions propagate a [FormatException].
///
/// ### Example
/// ```dart
/// final manager = PreAuthorizeAuthorizationManager(
///   "hasRole('ADMIN') or #userId == authentication.name",
/// );
/// final decision = manager.check(() => authentication, context);
/// ```
/// {@endtemplate}
final class PreAuthorizeAuthorizationManager implements AuthorizationManager<MethodAuthorizationContext> {
  /// Expression source.
  final String expression;

  final SecurityExpressionParser _parser;
  final RoleHierarchy? _roleHierarchy;

  /// {@macro pre_authorize_authorization_manager}
  ///
  /// Creates a manager that evaluates [expression] before method execution.
  ///
  /// ### Parameters
  /// - [expression]: the `@PreAuthorize` expression text.
  /// - [parser]: parser instance; defaults to a const [SecurityExpressionParser].
  /// - [roleHierarchy]: optional rules for expanding implied authorities.
  PreAuthorizeAuthorizationManager(this.expression, {
    SecurityExpressionParser parser = const SecurityExpressionParser(),
    RoleHierarchy? roleHierarchy,
  })  : _parser = parser, _roleHierarchy = roleHierarchy;

  /// {@template pre_authorize_authorization_manager_check}
  /// Evaluates the pre-authorization expression.
  ///
  /// The authentication supplier is invoked to populate a
  /// [SecurityExpressionContext] together with the context's arguments and
  /// role hierarchy. The invocation itself and [MethodAuthorizationContext.returnObject]
  /// are not consulted.
  ///
  /// ### Parameters
  /// - [authentication]: supplier for the current [Authentication], or `null`.
  /// - [context]: the method authorization context with named arguments.
  ///
  /// ### Returns
  /// A granted [AuthorizationDecision] when the expression evaluates to `true`.
  ///
  /// ### Throws
  /// [FormatException] if the expression is malformed.
  /// {@endtemplate}
  @override
  AuthorizationDecision check(AuthenticationSupplier authentication, MethodAuthorizationContext context) {
    final granted = _parser.evaluate(
      expression,
      SecurityExpressionContext(
        authentication: authentication(),
        arguments: context.arguments,
        roleHierarchy: _roleHierarchy,
      ),
    );
    return AuthorizationDecision(granted);
  }
}

/// {@template post_authorize_authorization_manager}
/// Evaluates a `@PostAuthorize` expression against the method's return value.
///
/// In addition to the authentication and named arguments, the expression sees
/// [MethodAuthorizationContext.returnObject], so rules such as
/// `returnObject.ownerId == authentication.name` can guard the result itself.
///
/// ### Contract and invariants
/// - [expression] is stored verbatim and parsed by the configured
///   [SecurityExpressionParser].
/// - A `null` return object is exposed as `null`; paths through it resolve to
///   `null` rather than throwing.
/// - A configured [RoleHierarchy] is forwarded to the expression context.
/// - Malformed expressions propagate a [FormatException].
///
/// ### Example
/// ```dart
/// final manager = PostAuthorizeAuthorizationManager(
///   'returnObject.ownerId == authentication.name',
/// );
/// final decision = manager.check(() => authentication, context);
/// ```
/// {@endtemplate}
final class PostAuthorizeAuthorizationManager implements AuthorizationManager<MethodAuthorizationContext> {
  /// Expression source.
  final String expression;

  final SecurityExpressionParser _parser;
  final RoleHierarchy? _roleHierarchy;

  /// {@macro post_authorize_authorization_manager}
  ///
  /// Creates a manager that evaluates [expression] after method execution.
  ///
  /// ### Parameters
  /// - [expression]: the `@PostAuthorize` expression text.
  /// - [parser]: parser instance; defaults to a const [SecurityExpressionParser].
  /// - [roleHierarchy]: optional rules for expanding implied authorities.
  PostAuthorizeAuthorizationManager(this.expression, {
    SecurityExpressionParser parser = const SecurityExpressionParser(),
    RoleHierarchy? roleHierarchy,
  })  : _parser = parser, _roleHierarchy = roleHierarchy;

  /// {@template post_authorize_authorization_manager_check}
  /// Evaluates the post-authorization expression against the returned value.
  ///
  /// The context's return object is passed to [SecurityExpressionContext],
  /// making `returnObject.*` paths available alongside arguments and the
  /// authentication.
  ///
  /// ### Parameters
  /// - [authentication]: supplier for the current [Authentication], or `null`.
  /// - [context]: the method authorization context, including the return value.
  ///
  /// ### Returns
  /// A granted [AuthorizationDecision] when the expression evaluates to `true`.
  ///
  /// ### Throws
  /// [FormatException] if the expression is malformed.
  /// {@endtemplate}
  @override
  AuthorizationDecision check(AuthenticationSupplier authentication, MethodAuthorizationContext context) {
    final granted = _parser.evaluate(
      expression,
      SecurityExpressionContext(
        authentication: authentication(),
        arguments: context.arguments,
        returnObject: context.returnObject,
        roleHierarchy: _roleHierarchy,
      ),
    );
    return AuthorizationDecision(granted);
  }
}

/// {@template secured_authorization_manager}
/// Enforces `@Secured` declarations by matching granted authorities.
///
/// Access is granted when the authenticated principal holds at least one of
/// [authorities]. Exact authority strings are compared, so a role must be
/// spelled with its `ROLE_` prefix when that is how it is granted.
///
/// ### Contract and invariants
/// - A `null` or unauthenticated principal is always denied.
/// - An empty [authorities] list can never grant access.
/// - A configured [roleHierarchy] expands granted authorities before matching.
///
/// ### Example
/// ```dart
/// const manager = SecuredAuthorizationManager(['ROLE_ADMIN', 'reports:read']);
/// final decision = manager.check(() => authentication, context);
/// ```
/// {@endtemplate}
final class SecuredAuthorizationManager
    implements AuthorizationManager<MethodAuthorizationContext> {
  /// Required authorities (any match grants access).
  final List<String> authorities;

  /// Optional hierarchy used to expand granted authorities.
  final RoleHierarchy? roleHierarchy;

  /// {@macro secured_authorization_manager}
  ///
  /// Creates a manager requiring any of [authorities].
  ///
  /// ### Parameters
  /// - [authorities]: exact authority strings to accept.
  /// - [roleHierarchy]: optional rules for expanding implied authorities.
  const SecuredAuthorizationManager(this.authorities, {this.roleHierarchy});

  /// {@template secured_authorization_manager_check}
  /// Decides whether the principal holds at least one required authority.
  ///
  /// Authority expansion through [roleHierarchy] happens before comparison.
  /// Neither the invocation nor the return object is inspected.
  ///
  /// ### Parameters
  /// - [authentication]: supplier for the current [Authentication], or `null`.
  /// - [context]: the method authorization context; ignored by this manager.
  ///
  /// ### Returns
  /// A granted [AuthorizationDecision] on the first matching authority,
  /// otherwise a denied decision.
  /// {@endtemplate}
  @override
  AuthorizationDecision check(
    AuthenticationSupplier authentication,
    MethodAuthorizationContext context,
  ) {
    final auth = authentication();
    if (auth == null || !auth.isAuthenticated) {
      return AuthorizationDecision.denied;
    }
    final effective = roleHierarchy?.getReachableGrantedAuthorities(auth.authorities) ??
        auth.authorities;
    final granted = effective.map((a) => a.authority).toSet();
    return AuthorizationDecision(
      authorities.any((authority) => granted.contains(authority)),
    );
  }
}

/// {@template jsr250_authorization_manager}
/// Enforces `@RolesAllowed` declarations by comparing normalized role names.
///
/// Each configured role is normalized with the `ROLE_` prefix when it is not
/// already present, so callers may write either `ADMIN` or `ROLE_ADMIN`. Access
/// is granted when the principal holds at least one of the resulting role
/// authorities.
///
/// ### Contract and invariants
/// - A `null` or unauthenticated principal is always denied.
/// - An empty [roles] list can never grant access.
/// - A configured [roleHierarchy] expands granted authorities before matching.
///
/// ### Example
/// ```dart
/// const manager = Jsr250AuthorizationManager(['ADMIN', 'MODERATOR']);
/// final decision = manager.check(() => authentication, context);
/// ```
/// {@endtemplate}
final class Jsr250AuthorizationManager
    implements AuthorizationManager<MethodAuthorizationContext> {
  /// Allowed roles (any match grants access).
  final List<String> roles;

  /// Optional hierarchy used to expand granted authorities.
  final RoleHierarchy? roleHierarchy;

  /// {@macro jsr250_authorization_manager}
  ///
  /// Creates a manager requiring any of [roles].
  ///
  /// ### Parameters
  /// - [roles]: role names; a missing `ROLE_` prefix is added automatically.
  /// - [roleHierarchy]: optional rules for expanding implied authorities.
  const Jsr250AuthorizationManager(this.roles, {this.roleHierarchy});

  /// {@template jsr250_authorization_manager_check}
  /// Decides whether the principal holds at least one allowed role.
  ///
  /// Each configured name is normalized with `ROLE_` before comparison, and
  /// granted authorities are expanded through [roleHierarchy] when configured.
  ///
  /// ### Parameters
  /// - [authentication]: supplier for the current [Authentication], or `null`.
  /// - [context]: the method authorization context; ignored by this manager.
  ///
  /// ### Returns
  /// A granted [AuthorizationDecision] when any normalized role is held,
  /// otherwise a denied decision.
  /// {@endtemplate}
  @override
  AuthorizationDecision check(
    AuthenticationSupplier authentication,
    MethodAuthorizationContext context,
  ) {
    final auth = authentication();
    if (auth == null || !auth.isAuthenticated) {
      return AuthorizationDecision.denied;
    }
    final effective = roleHierarchy?.getReachableGrantedAuthorities(auth.authorities) ??
        auth.authorities;
    final granted = effective.map((a) => a.authority).toSet();
    return AuthorizationDecision(
      roles.any((role) {
        final normalized = role.startsWith('ROLE_') ? role : 'ROLE_$role';
        return granted.contains(normalized);
      }),
    );
  }
}
