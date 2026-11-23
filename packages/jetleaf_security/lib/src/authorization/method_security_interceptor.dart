import 'typedefs.dart';
import '../core/exceptions.dart';
import '../core/security_context_holder.dart';
import '../annotation/security_annotations.dart';
import 'authorization_manager.dart';
import 'expression/security_expression_handler.dart';
import 'method/method_authorization.dart';
import 'role_hierarchy.dart';

/// {@template method_security_interceptor}
/// A compatibility facade that runs method authorization checks around a
/// caller-supplied invocation.
///
/// [intercept] evaluates pre-authorization rules, invokes the supplied
/// function, and then evaluates post-authorization rules against its result.
/// Every rule is resolved through the same [AuthorizationManager]
/// implementations used by the dedicated interceptor pods, so there is a
/// single policy engine behind both entry points.
///
/// Use the `AuthorizationManagerBeforeMethodInterceptor` and
/// `AuthorizationManagerAfterMethodInterceptor` pods when the invocation flows
/// through the interception pipeline; this class is convenient when the caller
/// drives the invocation itself, such as in tests or manual wrappers.
///
/// ### Contract and invariants
/// - Rules are read from [annotations]; unsupported annotation types are skipped.
/// - A denied rule throws [AccessDeniedException] and prevents the invocation
///   from continuing (or, for post-authorization, from returning its result).
/// - [expressionHandler] supplies the parser used for expression-based rules.
/// - [roleHierarchy], when set, is applied to every authority-based rule.
/// - The current authentication is read from [SecurityContextHolder].
///
/// ### Example
/// ```dart
/// final interceptor = MethodSecurityInterceptor(
///   roleHierarchy: RoleHierarchy('ROLE_ADMIN > ROLE_USER'),
/// );
///
/// final result = await interceptor.intercept(
///   annotations: [PreAuthorize("hasRole('ADMIN') or #id == authentication.name")],
///   arguments: {'id': 'alice'},
///   invocation: () => fetchReport('alice'),
/// );
/// ```
/// {@endtemplate}
class MethodSecurityInterceptor {
  /// Expression parser used for `@PreAuthorize` and `@PostAuthorize`.
  final SecurityExpressionHandler expressionHandler;

  /// Optional [RoleHierarchy] applied to authority checks.
  final RoleHierarchy? roleHierarchy;

  /// {@macro method_security_interceptor}
  ///
  /// Creates a facade with an optional expression handler and role hierarchy.
  ///
  /// ### Parameters
  /// - [expressionHandler]: handler whose parser evaluates expression rules;
  ///   defaults to a const [SecurityExpressionHandler].
  /// - [roleHierarchy]: rules for expanding implied authorities.
  const MethodSecurityInterceptor({
    SecurityExpressionHandler? expressionHandler,
    this.roleHierarchy,
  }) : expressionHandler = expressionHandler ?? const SecurityExpressionHandler();

  /// {@template method_security_interceptor_intercept}
  /// Runs pre-authorization, invokes [invocation], then runs post-authorization.
  ///
  /// The invocation is never started when a pre-authorization rule denies
  /// access. A post-authorization denial propagates as an error instead of the
  /// computed result.
  ///
  /// ### Parameters
  /// - [annotations]: security annotations to evaluate, in order.
  /// - [invocation]: deferred function producing the method result.
  /// - [arguments]: named method arguments exposed to expressions.
  ///
  /// ### Returns
  /// The value produced by [invocation], after all rules have passed.
  ///
  /// ### Throws
  /// [AccessDeniedException] if any pre- or post-authorization rule denies.
  ///
  /// ### Example
  /// ```dart
  /// final value = await interceptor.intercept(
  ///   annotations: [PreAuthorize("hasAuthority('reports:read')")],
  ///   invocation: () async => loadReports(),
  /// );
  /// ```
  /// {@endtemplate}
  Future<T> intercept<T>({
    required List<Object> annotations,
    required MethodInvocationSupplier<T> invocation,
    Map<String, Object?> arguments = const {},
  }) async {
    checkPreAuthorization(annotations, arguments: arguments);
    final result = await invocation();
    checkPostAuthorization(annotations, returnObject: result, arguments: arguments);
    return result;
  }

  /// {@template method_security_interceptor_check_pre_authorization}
  /// Checks `@PreAuthorize`, `@Secured`, and `@RolesAllowed` annotations.
  ///
  /// Each recognized annotation is converted to its [AuthorizationManager] via
  /// [_preManagerFor] and checked against a [MethodAuthorizationContext] built
  /// from [arguments]. Unrecognized annotations are ignored.
  ///
  /// ### Parameters
  /// - [annotations]: annotations attached to the method being guarded.
  /// - [arguments]: named method arguments exposed to expressions.
  ///
  /// ### Returns
  /// `void`; completes normally only when every recognized rule grants access.
  ///
  /// ### Throws
  /// [AccessDeniedException] when a rule denies access.
  /// {@endtemplate}
  void checkPreAuthorization(List<Object> annotations, {
    Map<String, Object?> arguments = const {},
  }) {
    final authentication = SecurityContextHolder.getContext().authentication;
    final context = MethodAuthorizationContext(arguments: arguments);

    for (final annotation in annotations) {
      final manager = _preManagerFor(annotation);
      if (manager == null) continue;
      if (!manager.check(() => authentication, context).isGranted) {
        throw AccessDeniedException('Access denied by $annotation');
      }
    }
  }

  /// {@template method_security_interceptor_check_post_authorization}
  /// Checks `@PostAuthorize` annotations against [returnObject].
  ///
  /// A [MethodAuthorizationContext] carrying both the arguments and the result
  /// is built, so expressions may reference `returnObject.*` as well as
  /// `#argument` and `authentication.*`.
  ///
  /// ### Parameters
  /// - [annotations]: annotations attached to the method being guarded.
  /// - [returnObject]: the value returned by the guarded method.
  /// - [arguments]: named method arguments exposed to expressions.
  ///
  /// ### Returns
  /// `void`; completes normally only when every post-authorization rule grants.
  ///
  /// ### Throws
  /// [AccessDeniedException] when a rule denies access.
  /// {@endtemplate}
  void checkPostAuthorization(List<Object> annotations, {
    required Object? returnObject,
    Map<String, Object?> arguments = const {},
  }) {
    final authentication = SecurityContextHolder.getContext().authentication;
    final context = MethodAuthorizationContext(
      arguments: arguments,
      returnObject: returnObject,
    );

    for (final annotation in annotations) {
      if (annotation is! PostAuthorize) continue;
      final manager = PostAuthorizeAuthorizationManager(
        annotation.value,
        parser: expressionHandler.parser,
        roleHierarchy: roleHierarchy,
      );
      if (!manager.check(() => authentication, context).isGranted) {
        throw AccessDeniedException('Access denied by $annotation');
      }
    }
  }

  /// {@template method_security_interceptor_pre_manager_for}
  /// Maps a pre-authorization annotation to the manager that enforces it.
  ///
  /// `PreAuthorize` maps to [PreAuthorizeAuthorizationManager], `Secured` to
  /// [SecuredAuthorizationManager], and `RolesAllowed` to
  /// [Jsr250AuthorizationManager]. Expression rules use the configured
  /// [SecurityExpressionHandler] parser, and every manager receives the
  /// configured [roleHierarchy].
  ///
  /// ### Parameters
  /// - [annotation]: the annotation instance to classify.
  ///
  /// ### Returns
  /// The matching manager, or `null` when [annotation] is not a supported
  /// pre-authorization annotation.
  /// {@endtemplate}
  AuthorizationManager<MethodAuthorizationContext>? _preManagerFor(Object annotation) {
    if (annotation is PreAuthorize) {
      return PreAuthorizeAuthorizationManager(
        annotation.value,
        parser: expressionHandler.parser,
        roleHierarchy: roleHierarchy,
      );
    }
    if (annotation is Secured) {
      return SecuredAuthorizationManager(
        annotation.value,
        roleHierarchy: roleHierarchy,
      );
    }
    if (annotation is RolesAllowed) {
      return Jsr250AuthorizationManager(
        annotation.value,
        roleHierarchy: roleHierarchy,
      );
    }
    return null;
  }
}
