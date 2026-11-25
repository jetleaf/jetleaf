import 'typedefs.dart';
import '../core/typedefs.dart';
import '../core/authentication.dart';
import 'authorization_decision.dart';
import 'authorization_manager.dart';
import 'expression_parser.dart';
import 'role_hierarchy.dart';

/// {@template expression_authorization_manager}
/// Bridges an expression string into the [AuthorizationManager] contract.
///
/// This is the adapter behind the `access(String expression)` form of the
/// security DSL. The [expression] is supplied once at configuration time and
/// evaluated on every [check] against a [SecurityExpressionContext] produced by
/// the configured context factory.
///
/// Typed terminals such as `AuthorityAuthorizationManager.hasRole` are
/// preferred for simple rules; this manager is intended for custom expressions
/// and for annotation-driven method security, where the rule arrives as text.
///
/// ### Contract and invariants
/// - [expression] is retained for diagnostics and is evaluated as written.
/// - The default context factory resolves the authentication lazily and
///   provides no method arguments or return object.
/// - Supply `contextFactory` to expose named arguments, a return object, or a
///   role hierarchy to the expression.
/// - A `true` evaluation yields a granted [AuthorizationDecision]; `false`
///   yields a denied one.
/// - Malformed expressions propagate the [FormatException] raised by
///   [SecurityExpressionParser.evaluate].
///
/// ### Example
/// ```dart
/// final manager = ExpressionAuthorizationManager<RequestAuthorizationContext>(
///   "hasRole('ADMIN') or #userId == authentication.name",
///   contextFactory: (authentication, context) => SecurityExpressionContext(
///     authentication: authentication(),
///     arguments: {'userId': context.request.getParameters()['userId']},
///   ),
/// );
/// final decision = manager.check(() => currentAuthentication, context);
/// ```
/// {@endtemplate}
final class ExpressionAuthorizationManager<T> implements AuthorizationManager<T> {
  /// Source expression, retained for diagnostics.
  final String expression;

  /// Parser that tokenizes and evaluates [expression].
  final SecurityExpressionParser _parser;

  /// Factory that builds the evaluation context for each [check].
  ///
  /// It receives the lazy authentication supplier and the caller's context so
  /// it can expose both to the expression language.
  final ExpressionContextFactory<T>? _contextFactory;

  /// Optional hierarchy used when evaluating role checks.
  final RoleHierarchy? roleHierarchy;

  /// Returns a copy of this manager using [hierarchy] for role expansion.
  ExpressionAuthorizationManager<T> withRoleHierarchy(RoleHierarchy hierarchy) => ExpressionAuthorizationManager<T>(
    expression,
    parser: _parser,
    contextFactory: _contextFactory,
    roleHierarchy: hierarchy,
  );

  /// {@macro expression_authorization_manager}
  ///
  /// Creates a manager that evaluates [expression].
  ///
  /// ### Parameters
  /// - [expression]: the security expression to evaluate.
  /// - [parser]: parser instance; defaults to a const [SecurityExpressionParser].
  /// - [contextFactory]: builds a [SecurityExpressionContext] from the
  ///   authentication supplier and caller context. Defaults to a context that
  ///   resolves the authentication and nothing else.
  ExpressionAuthorizationManager(this.expression, {
    SecurityExpressionParser parser = const SecurityExpressionParser(),
    ExpressionContextFactory<T>? contextFactory,
    this.roleHierarchy,
  })  : _parser = parser,
        _contextFactory = contextFactory;

  /// {@template expression_authorization_manager_check}
  /// Evaluates [expression] against the current context.
  ///
  /// The context is created on each call, so changes to the authentication or
  /// caller context are visible to subsequent checks. The [authentication]
  /// supplier is invoked only when the context factory reads it.
  ///
  /// ### Parameters
  /// - [authentication]: supplier for the current [Authentication], or `null`
  ///   when no authentication is present.
  /// - [context]: caller-supplied context forwarded to the context factory.
  ///
  /// ### Returns
  /// An [AuthorizationDecision] whose `isGranted` is the boolean result of
  /// evaluating [expression] against the supplied context.
  ///
  /// ### Throws
  /// [FormatException] if [expression] is malformed or uses an unknown function.
  ///
  /// ### Example
  /// ```dart
  /// final decision = manager.check(
  ///   () => SecurityContextHolder.getContext().authentication,
  ///   requestContext,
  /// );
  /// ```
  /// {@endtemplate}
  @override
  AuthorizationDecision check(AuthenticationSupplier authentication, T context) {
    final evaluationContext = _contextFactory?.call(authentication, context) ??
        SecurityExpressionContext(
          authentication: authentication(),
          roleHierarchy: roleHierarchy,
        );
    final decision = _parser.evaluate(expression, evaluationContext);
    return AuthorizationDecision(decision);
  }
}