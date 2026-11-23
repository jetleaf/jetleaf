import 'package:jetleaf_web/jetleaf_web.dart';

import '../core/typedefs.dart';
import 'expression_parser.dart';

/// {@template request_predicate}
/// Tests whether a request matches a configured rule or matcher.
/// {@endtemplate}
typedef RequestPredicate = bool Function(ServerHttpRequest request);

/// {@template expression_context_factory}
/// Builds the evaluation context for a security expression.
///
/// The factory receives the lazy [AuthenticationSupplier] and the caller's
/// context object, allowing expression rules to bind `#param` values or a
/// return object without duplicating context construction.
/// {@endtemplate}
typedef ExpressionContextFactory<T> = SecurityExpressionContext Function(
  AuthenticationSupplier authentication,
  T context,
);

/// {@template method_invocation_supplier}
/// Supplies the result of invoking a secured method.
///
/// Used by the compatibility facade so pre- and post-authorization checks can
/// share the same invocation contract without repeating the closure type.
/// {@endtemplate}
typedef MethodInvocationSupplier<T> = Future<T> Function();
