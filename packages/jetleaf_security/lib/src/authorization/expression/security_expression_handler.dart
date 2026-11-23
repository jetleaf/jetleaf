import '../expression_parser.dart';

/// {@template security_expression_handler}
/// Public entry point for compiling and evaluating security expressions.
///
/// The handler owns a [SecurityExpressionParser] and forwards each evaluation
/// to it. It is the collaborator injected into authorization components that
/// need expression support, so applications can swap parser behavior — for
/// example, a custom role prefix — in one place.
///
/// ### Contract and invariants
/// - [parser] is immutable after construction.
/// - Evaluation is stateless: the same handler may serve concurrent checks.
/// - A `true` result grants access; `false` denies it.
///
/// ### Example
/// ```dart
/// const handler = SecurityExpressionHandler(
///   parser: SecurityExpressionParser(rolePrefix: 'ROLE_'),
/// );
/// final granted = handler.evaluate(
///   "hasRole('ADMIN') and isAuthenticated()",
///   context,
/// );
/// ```
///
/// ### See also
/// - [SecurityExpressionParser]
/// - [SecurityExpressionContext]
/// {@endtemplate}
final class SecurityExpressionHandler {
  /// Parser used to tokenise and evaluate expressions.
  final SecurityExpressionParser parser;

  /// {@macro security_expression_handler}
  ///
  /// Creates a handler backed by [parser].
  ///
  /// ### Parameters
  /// - [parser]: the parser to use; defaults to a const
  ///   [SecurityExpressionParser] with the standard role prefix.
  const SecurityExpressionHandler({
    this.parser = const SecurityExpressionParser(),
  });

  /// {@template security_expression_handler_evaluate}
  /// Evaluates [expression] against [context].
  ///
  /// This is a thin delegation to [SecurityExpressionParser.evaluate]; all
  /// grammar rules, caching, and error behavior are defined there.
  ///
  /// ### Parameters
  /// - [expression]: the security expression to evaluate.
  /// - [context]: supplies authentication, arguments, return value, and role
  ///   hierarchy for the evaluation.
  ///
  /// ### Returns
  /// `true` when the expression grants access, `false` otherwise.
  ///
  /// ### Throws
  /// [FormatException] when the expression is malformed or invalid.
  ///
  /// ### Example
  /// ```dart
  /// final granted = handler.evaluate(
  ///   '#owner == authentication.name',
  ///   SecurityExpressionContext(
  ///     authentication: currentAuthentication,
  ///     arguments: {'owner': 'alice'},
  ///   ),
  /// );
  /// ```
  /// {@endtemplate}
  bool evaluate(String expression, SecurityExpressionContext context) => parser.evaluate(expression, context);
}
