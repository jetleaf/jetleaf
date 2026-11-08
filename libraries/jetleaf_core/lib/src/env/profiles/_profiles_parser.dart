import '../exceptions.dart';
import 'profiles.dart';

/// {@template profiles_parser}
/// Parses one or more profile expressions into a [Profiles] implementation.
///
/// Profile expressions allow developers to define environment-based
/// conditions using logical operators. The resulting [Profiles] instance
/// can then be queried to determine if a given set of active profiles
/// satisfies any of the defined conditions.
///
/// Supported operators:
/// - `&` (AND): Both expressions must evaluate to `true`.
/// - `|` (OR): At least one expression must evaluate to `true`.
/// - `!` (NOT): Inverts the result of the expression.
/// - Parentheses `(...)`: Groups expressions and controls precedence.
///
/// Example:
/// ```dart
/// final profiles = ProfilesParser.parse(['dev & !prod', 'test | staging']);
/// final isMatch = profiles.matches((name) => ['dev'].contains(name));
/// // isMatch == true
/// ```
///
/// {@endtemplate}
class ProfilesParser {
  /// {@macro profiles_parser}
  ///
  /// Takes a list of raw [expressions], parses each into an internal
  /// expression tree, and returns a [_CompositeProfiles] instance that
  /// can be queried with [Profiles.matches].
  ///
  /// - [expressions]: A list of logical profile expressions as strings.
  /// - Returns: A [Profiles] implementation that encapsulates all the
  ///   given expressions.
  /// - Throws: [EnvironmentParsingException] if any expression is invalid.
  static Profiles parse(List<String> expressions) {
    final parsed = expressions.map(_parseExpression).toList();
    return _CompositeProfiles(parsed);
  }

  /// Parses a single [expression] string into an internal expression tree.
  ///
  /// This method is used internally by [parse] to handle each individual
  /// expression string. Developers typically don’t call this directly.
  ///
  /// - [expression]: A string containing a logical profile expression.
  /// - Returns: An [_Expr] instance representing the parsed expression tree.
  /// - Throws: [EnvironmentParsingException] if parsing fails.
  static _Expr _parseExpression(String expression) => _ExprParser(expression).parse();
}

/// {@template expr}
/// Represents a logical expression in the profile system.
///
/// Expressions are building blocks that can be combined into complex
/// conditions. Each expression implements [eval], which computes its
/// value against a provided predicate function that reports whether
/// a profile is currently active.
///
/// Examples of expressions:
/// - A literal profile name, e.g. `"dev"`.
/// - A logical composition, e.g. `"dev & !prod"`.
/// {@endtemplate}
abstract class _Expr {
  /// {@macro expr}
  ///
  /// Evaluates this expression tree.
  ///
  /// - [isActive]: A function returning `true` if the given profile name
  ///   is currently active.
  /// - Returns: `true` if the expression evaluates successfully against
  ///   the active profiles; otherwise `false`.
  bool eval(bool Function(String) isActive);
}

/// {@template composite_profiles}
/// A composite [Profiles] implementation backed by a list of [_Expr] trees.
/// 
/// This class implements the [Profiles] interface and evaluates multiple
/// expressions in sequence. It returns `true` if **any** of the contained
/// expressions evaluates to `true` when matched against the active profiles.
/// 
/// This implements a logical OR relationship between the different expressions
/// in the list.
/// {@endtemplate}
class _CompositeProfiles implements Profiles {
  /// The list of parsed expression trees that define this profile set.
  final List<_Expr> expressions;

  /// {@macro composite_profiles}
  ///
  /// - [expressions]: A list of logical expression trees created by
  ///   [ProfilesParser].
  _CompositeProfiles(this.expressions);

  @override
  bool matches(bool Function(String) isProfileActive) {
    for (final expr in expressions) {
      if (expr.eval(isProfileActive)) return true;
    }
    return false;
  }
}

/// {@template expr_parser}
/// A recursive descent parser for logical profile expressions.
/// 
/// This parser implements a recursive descent parsing algorithm to convert
/// profile expression strings into expression trees ([_Expr] objects).
/// 
/// Supports the following operations in order of precedence (highest to lowest):
/// - NOT: `!a`
/// - Grouping: `(a | b) & c`
/// - AND: `a & b` (left-associative)
/// - OR: `a | b` (left-associative)
/// 
/// The grammar for expressions is:
/// - expression → or
/// - or → and ('|' and)*
/// - and → unary ('&' unary)*  
/// - unary → '!' unary | '(' expression ')' | literal
/// - literal → [a-zA-Z_][a-zA-Z0-9_]*
/// {@endtemplate}
class _ExprParser {
  /// The raw input expression string.
  final String source;

  /// Tokenized representation of the input string.
  late final List<String> _tokens;

  /// Current index into the [_tokens] list.
  int _pos = 0;

  /// {@macro expr_parser}
  ///
  /// - [source]: The raw expression string to be parsed.
  /// - Initializes the internal token list for parsing.
  _ExprParser(this.source) {
    _tokens = _tokenize(source);
  }

  /// Parses the full expression from the input source.
  /// 
  /// This is the entry point for parsing and ensures that the entire
  /// input is consumed after parsing the main expression.
  /// 
  /// @return The root [_Expr] node of the parsed expression tree
  /// @throws EnvironmentParsingException If there are extra tokens after parsing
  _Expr parse() {
    final expr = _parseOr();
    if (_pos != _tokens.length) {
      throw EnvironmentParsingException('Unexpected token: ${_tokens[_pos]}');
    }
    return expr;
  }

  /// Parses OR expressions (lowest precedence).
  /// 
  /// OR expressions are left-associative and have the form:
  /// `expression | expression | expression...`
  /// 
  /// @return An [_Expr] representing the OR expression chain
  _Expr _parseOr() {
    var left = _parseAnd();
    while (_match('|')) {
      final right = _parseAnd();
      left = _OrExpr(left, right);
    }
    return left;
  }

  /// Parses AND expressions (medium precedence).
  /// 
  /// AND expressions are left-associative and have the form:
  /// `expression & expression & expression...`
  /// 
  /// @return An [_Expr] representing the AND expression chain
  _Expr _parseAnd() {
    var left = _parseUnary();
    while (_match('&')) {
      final right = _parseUnary();
      left = _AndExpr(left, right);
    }
    return left;
  }

  /// Parses unary expressions and grouping (highest precedence).
  /// 
  /// Handles:
  /// - NOT expressions: `!expression`
  /// - Grouped expressions: `(expression)`
  /// - Literal expressions: `profile_name`
  /// 
  /// @return An [_Expr] representing the unary expression or literal
  /// @throws EnvironmentParsingException If there's a missing closing parenthesis
  _Expr _parseUnary() {
    if (_match('!')) {
      return _NotExpr(_parseUnary());
    }
    if (_match('(')) {
      final expr = _parseOr();
      if (!_match(')')) {
        throw EnvironmentParsingException('Expected )');
      }
      return expr;
    }
    return _LiteralExpr(_next());
  }

  /// Checks if the current token matches the expected token and consumes it.
  /// 
  /// If the current token matches the expected value, advances the position
  /// and returns `true`. Otherwise, returns `false` without advancing.
  /// 
  /// @param expected The token to match against
  /// @return `true` if the token matches and was consumed, `false` otherwise
  bool _match(String expected) {
    if (_pos < _tokens.length && _tokens[_pos] == expected) {
      _pos++;
      return true;
    }
    return false;
  }

  /// Consumes and returns the next token from the token stream.
  /// 
  /// @return The next token as a String
  /// @throws EnvironmentParsingException If there are no more tokens
  String _next() {
    if (_pos >= _tokens.length) throw EnvironmentParsingException('Unexpected end of input');
    return _tokens[_pos++];
  }

  /// Tokenizes the source string into individual tokens.
  /// 
  /// Splits the input string into operators and literals. Operators
  /// are single characters from the set `()!&|`, while literals are
  /// sequences of characters between operators.
  /// 
  /// @param src The source string to tokenize
  /// @return A list of tokens as Strings
  List<String> _tokenize(String src) {
    final tokens = <String>[];
    final buffer = StringBuffer();
    for (int i = 0; i < src.length; i++) {
      final c = src[i];
      if ('()!&|'.contains(c)) {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString().trim());
          buffer.clear();
        }
        tokens.add(c);
      } else {
        buffer.write(c);
      }
    }
    if (buffer.isNotEmpty) {
      tokens.add(buffer.toString().trim());
    }
    return tokens.where((t) => t.isNotEmpty).toList();
  }
}

/// {@template literal_expr}
/// **Literal expression node**
///
/// Represents a single, literal profile name in the expression tree.
/// This is always a *leaf node* in the AST and corresponds directly to
/// a profile string token parsed by [_ExprParser].
///
/// Evaluation:
/// - Calls the provided `isActive` predicate with [name].
/// - Returns `true` if that profile is currently active, otherwise `false`.
///
/// Example:
/// ```dart
/// final expr = _LiteralExpr('dev');
/// final result = expr.eval((profile) => profile == 'dev'); // true
/// ```
///
/// Notes:
/// - Profile names are case-sensitive unless your predicate enforces
///   its own normalization.
/// - Literal nodes cannot be empty; attempting to construct one with an
///   empty string is a parsing error.
/// {@endtemplate}
class _LiteralExpr extends _Expr {
  /// The profile name represented by this literal node.
  final String name;

  /// {@macro literal_expr}
  _LiteralExpr(this.name);

  @override
  bool eval(bool Function(String) isActive) => isActive(name);
}

/// {@template not_expr}
/// **Logical NOT expression node**
///
/// Represents the unary `!` operator. Negates the result of its
/// [expr] subexpression.
///
/// Evaluation:
/// - Calls [expr].eval(isActive).
/// - Returns the boolean negation of that value.
///
/// Example:
/// ```dart
/// final expr = _NotExpr(_LiteralExpr('prod'));
/// final result = expr.eval((profile) => profile == 'prod'); // false
/// ```
///
/// Truth table:
/// | subexpr | result |
/// |---------|--------|
/// | true    | false  |
/// | false   | true   |
///
/// Notes:
/// - Multiple NOTs can be chained: `!!a` parses as `_NotExpr(_NotExpr(a))`.
/// - Since it’s right-associative, `!a & b` parses as `(_NotExpr(a)) & b`.
/// {@endtemplate}
class _NotExpr extends _Expr {
  /// The subexpression whose value will be inverted.
  final _Expr expr;

  /// {@macro not_expr}
  _NotExpr(this.expr);

  @override
  bool eval(bool Function(String) isActive) => !expr.eval(isActive);
}

/// {@template and_expr}
/// **Logical AND expression node**
///
/// Represents the binary `&` operator. Combines [left] and [right]
/// subexpressions and evaluates to `true` only if *both* evaluate to `true`.
///
/// Evaluation:
/// - Short-circuiting: if [left] evaluates to `false`, [right] is not
///   evaluated.
/// - Otherwise, evaluates [right] and returns `true` only if both are `true`.
///
/// Example:
/// ```dart
/// final expr = _AndExpr(_LiteralExpr('dev'), _NotExpr(_LiteralExpr('prod')));
/// final result = expr.eval((p) => p == 'dev'); // true
/// ```
///
/// Truth table:
/// | left  | right | result |
/// |-------|-------|--------|
/// | true  | true  | true   |
/// | true  | false | false  |
/// | false | true  | false  |
/// | false | false | false  |
///
/// Notes:
/// - Associative: `(a & b) & c` is equivalent to `a & (b & c)`.
/// - Higher precedence than OR, lower than NOT.
/// {@endtemplate}
class _AndExpr extends _Expr {
  /// The left-hand subexpression in the AND operation.
  final _Expr left;

  /// The right-hand subexpression in the AND operation.
  final _Expr right;

  /// {@macro and_expr}
  _AndExpr(this.left, this.right);

  @override
  bool eval(bool Function(String) isActive) => left.eval(isActive) && right.eval(isActive);
}

/// {@template or_expr}
/// **Logical OR expression node**
///
/// Represents the binary `|` operator. Combines [left] and [right]
/// subexpressions and evaluates to `true` if *either* evaluates to `true`.
///
/// Evaluation:
/// - Short-circuiting: if [left] evaluates to `true`, [right] is not
///   evaluated.
/// - Otherwise, evaluates [right].
///
/// Example:
/// ```dart
/// final expr = _OrExpr(_LiteralExpr('test'), _LiteralExpr('staging'));
/// final result = expr.eval((p) => p == 'staging'); // true
/// ```
///
/// Truth table:
/// | left  | right | result |
/// |-------|-------|--------|
/// | true  | true  | true   |
/// | true  | false | true   |
/// | false | true  | true   |
/// | false | false | false  |
///
/// Notes:
/// - Associative: `(a | b) | c` is equivalent to `a | (b | c)`.
/// - Lowest precedence among the logical operators.
/// {@endtemplate}
class _OrExpr extends _Expr {
  /// The left-hand subexpression in the OR operation.
  final _Expr left;

  /// The right-hand subexpression in the OR operation.
  final _Expr right;

  /// {@macro or_expr}
  _OrExpr(this.left, this.right);

  @override
  bool eval(bool Function(String) isActive) => left.eval(isActive) || right.eval(isActive);
}