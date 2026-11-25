import 'package:jetleaf_core/utils.dart' show ParserException;
import '../authentication/anonymous_authentication_token.dart';
import '../core/authentication.dart';
import '../core/granted_authority.dart';
import 'role_hierarchy.dart';
import 'expression/property_resolver.dart';

/// {@template security_expression_context}
/// Runtime evaluation context passed to [SecurityExpressionParser].
///
/// The context supplies everything an expression can read: the current
/// [authentication], named method [arguments], the [returnObject] of a
/// post-authorization check, and an optional [roleHierarchy] for expanding
/// implied authorities.
///
/// ### Contract
/// - All fields are immutable; create a new context for each evaluation.
/// - [authentication] may be `null`, which expressions treat as unauthenticated.
/// - [arguments] maps a bare name or a `#`-prefixed reference to its value.
/// - [returnObject] is normally `null` for pre-authorization expressions.
///
/// ### Example
/// ```dart
/// final context = SecurityExpressionContext(
///   authentication: currentAuthentication,
///   arguments: {'userId': 'alice'},
///   returnObject: report,
///   roleHierarchy: RoleHierarchy('ROLE_ADMIN > ROLE_USER'),
/// );
/// ```
/// {@endtemplate}
class SecurityExpressionContext {
  /// The current [Authentication] (or `null` if unauthenticated).
  final Authentication? authentication;

  /// Named method arguments accessible via `#argName` in expressions.
  final Map<String, Object?> arguments;

  /// Return value of the method (for `@PostAuthorize` expressions via `returnObject`).
  final Object? returnObject;

  /// Optional [RoleHierarchy] used to expand authorities.
  final RoleHierarchy? roleHierarchy;

  /// {@macro security_expression_context}
  ///
  /// Creates an immutable evaluation context.
  ///
  /// ### Parameters
  /// - [authentication]: the current authentication, or `null`.
  /// - [arguments]: named arguments keyed by their source parameter names.
  /// - [returnObject]: the value returned by the guarded method, when known.
  /// - [roleHierarchy]: rules for expanding reachable authorities.
  const SecurityExpressionContext({
    this.authentication,
    this.arguments = const {},
    this.returnObject,
    this.roleHierarchy,
  });
}

/// {@template security_expression_parser}
/// Evaluates the Jetleaf security expression language against a
/// [SecurityExpressionContext], returning `true` to grant access.
///
/// ### Expression grammar
///
/// - **Literals** — `true`, `false`, `null`, quoted strings (`'ADMIN'`,
///   `"users:write"`), and numeric values.
/// - **Authorization terminals** — `permitAll()`, `denyAll()`,
///   `isAuthenticated()`, `isAnonymous()`, `hasRole('ADMIN')`,
///   `hasAnyRole(['ADMIN', 'MOD'])`, `hasAuthority('users:write')`, and
///   `hasAnyAuthority(['users:read', 'users:write'])`. The first four may also
///   be written without parentheses (`permitAll`, `isAuthenticated`, …).
/// - **Value paths** — `#paramName` reads a named method argument;
///   `principal.organizationId` and `authentication.name` read from the current
///   [Authentication]; `authentication.principal` and
///   `authentication.isAuthenticated` expose its two core properties;
///   `returnObject.ownerId` reads from the guarded method's result. A bare
///   argument name also resolves from [SecurityExpressionContext.arguments].
///   Dot-separated segments are resolved through
///   `SecurityExpressionPropertyResolvers`.
/// - **Comparisons** — `==` and `!=` compare two values, for example
///   `#userId == authentication.name`.
/// - **Boolean operators** — `&&`, `and`, `||`, `or`, `!`, `not`, and
///   parentheses. Precedence, from tightest to loosest, is parentheses, unary
///   `!`/`not`, `&&`/`and`, then `||`/`or`; comparisons bind at the primary level.
/// - **Role handling** — `hasRole` and `hasAnyRole` prepend [rolePrefix]
///   (`ROLE_` by default) when the supplied name lacks it. When the context
///   carries a [RoleHierarchy], both role and authority checks consider every
///   reachable authority, not only those directly granted.
///
/// ### Examples
/// ```dart
/// // Allow admins or the owner of the requested record.
/// const expression = "hasRole('ADMIN') or #userId == authentication.name";
///
/// // Allow either of two roles.
/// const byRole = "hasAnyRole(['ADMIN', 'MOD'])";
///
/// // Combine an authority check with a sign-in requirement.
/// const combined = "isAuthenticated() && hasAuthority('users:write')";
///
/// // Post-authorization: the caller may only see their own report.
/// const post = 'returnObject.ownerId == authentication.name';
///
/// final parser = SecurityExpressionParser();
/// final granted = parser.evaluate(expression, context);
/// ```
///
/// ### Tokenization
/// Whitespace is ignored; quoted strings are consumed as a single token;
/// `&&`, `||`, `==`, and `!=` are recognized as two-character operators; and
/// `(`, `)`, `,`, `!`, `[`, and `]` are separate punctuation tokens. Token
/// lists are cached per `[rolePrefix|expression]` pair, so repeated checks of
/// the same rule do not re-tokenize it.
///
/// ### Errors
/// [FormatException] is thrown for unbalanced parentheses, missing operands,
/// unknown functions, incorrect function arity, non-boolean terminals, and
/// trailing tokens left after a complete expression.
/// {@endtemplate}
class SecurityExpressionParser {
  /// Role prefix used by `hasRole` / `hasAnyRole`. Defaults to `'ROLE_'`.
  ///
  /// A role name that already begins with this prefix is used unchanged.
  final String rolePrefix;

  /// Tokenised forms, compiled once per distinct expression.
  ///
  /// Cache keys combine [rolePrefix] and the expression source so changing the
  /// prefix cannot reuse tokens compiled under a different prefix.
  static final Map<String, List<String>> _tokenCache = {};

  /// {@macro security_expression_parser}
  ///
  /// Creates a parser with an optional custom [rolePrefix].
  ///
  /// ### Parameters
  /// - [rolePrefix]: prefix applied to bare role names; defaults to `'ROLE_'`.
  const SecurityExpressionParser({this.rolePrefix = 'ROLE_'});

  /// {@template security_expression_parser_evaluate}
  /// Evaluates [expression] against [context] and returns the boolean result.
  ///
  /// Tokens are taken from the shared cache when available and compiled with
  /// [_tokenize] otherwise. A fresh [_Parser] walks those tokens on every call,
  /// so evaluation is stateless even though tokenization is cached.
  ///
  /// ### Parameters
  /// - [expression]: the security expression to evaluate; see the class-level
  ///   grammar for supported syntax.
  /// - [context]: supplies authentication, arguments, return value, and role
  ///   hierarchy used by the expression.
  ///
  /// ### Returns
  /// `true` when the expression grants access, `false` otherwise.
  ///
  /// ### Throws
  /// [FormatException] when the expression is malformed, contains an unknown
  /// function, or leaves unconsumed trailing tokens.
  ///
  /// ### Example
  /// ```dart
  /// final parser = SecurityExpressionParser();
  /// final granted = parser.evaluate(
  ///   "hasRole('ADMIN') or #userId == authentication.name",
  ///   context,
  /// );
  /// ```
  /// {@endtemplate}
  bool evaluate(String expression, SecurityExpressionContext context) {
    final tokens = _tokenCache.putIfAbsent(
      '$rolePrefix|$expression',
      () => _tokenize(expression),
    );
    final parser = _Parser(tokens, context, rolePrefix);
    final result = parser.parseExpression();
    if (!parser.isAtEnd) {
      throw ParserException('Unexpected token "${parser.peek()}" in "$expression"');
    }
    return result;
  }

  /// {@template security_expression_parser_tokenize}
  /// Splits the raw [input] into the tokens consumed by [_Parser].
  ///
  /// Whitespace is skipped. Multi-character operators (`&&`, `||`, `==`, `!=`)
  /// stay intact, quoted strings become one token including their quotes, and
  /// `(`, `)`, `,`, `!`, `[`, `]` are emitted individually. Every other run of
  /// characters becomes a single word, number, or dotted value path.
  ///
  /// ### Parameters
  /// - [input]: the raw expression source.
  ///
  /// ### Returns
  /// An ordered list of tokens; an empty expression yields an empty list.
  /// {@endtemplate}
  static List<String> _tokenize(String input) {
    final tokens = <String>[];
    var i = 0;
    while (i < input.length) {
      final ch = input[i];
      if (ch.trim().isEmpty) {
        i++;
        continue;
      }
      if (ch == '(' || ch == ')' || ch == ',' || ch == '!' || ch == '[' || ch == ']') {
        if (ch == '!' && i + 1 < input.length && input[i + 1] == '=') {
          tokens.add('!=');
          i += 2;
        } else {
          tokens.add(ch);
          i++;
        }
        continue;
      }
      if (i + 1 < input.length) {
        final two = input.substring(i, i + 2);
        if (two == '&&' || two == '||' || two == '==') {
          tokens.add(two);
          i += 2;
          continue;
        }
      }
      if (ch == '\'' || ch == '"') {
        final quote = ch;
        final sb = StringBuffer(quote);
        i++;
        while (i < input.length && input[i] != quote) {
          sb.write(input[i]);
          i++;
        }
        if (i < input.length) {
          sb.write(quote);
          i++;
        }
        tokens.add(sb.toString());
        continue;
      }
      final start = i;
      while (i < input.length) {
        final c = input[i];
        if (c.trim().isEmpty ||
            c == '(' ||
            c == ')' ||
            c == ',' ||
            c == '!' ||
            c == '[' ||
            c == ']' ||
            c == '&' ||
            c == '|' ||
            c == '=') {
          break;
        }
        i++;
      }
      tokens.add(input.substring(start, i));
    }
    return tokens;
  }
}

/// {@template _parser}
/// Recursive-descent reader for a token list produced by
/// [SecurityExpressionParser._tokenize].
///
/// One instance is created per [SecurityExpressionParser.evaluate] call. It
/// holds a cursor into [_tokens], the evaluation [_ctx], and the active
/// [_rolePrefix]; grammar rules are implemented by the `_parse*` methods from
/// loosest to tightest binding: expression → or → and → unary → primary.
///
/// ### Contract
/// - Every successful parse consumes exactly one boolean expression.
/// - Malformed input is reported with [FormatException].
/// - Property access outside the evaluation roots is delegated to
///   `SecurityExpressionPropertyResolvers`.
/// {@endtemplate}
class _Parser {
  /// The immutable token stream being parsed.
  final List<String> _tokens;

  /// Context supplying authentication, arguments, return value, and hierarchy.
  final SecurityExpressionContext _ctx;

  /// Prefix applied to bare role names in role checks.
  final String _rolePrefix;

  /// Cursor index of the next token to read.
  int _pos = 0;

  /// {@macro _parser}
  ///
  /// Creates a reader over [tokens] using [ctx] and [rolePrefix].
  ///
  /// ### Parameters
  /// - [tokens]: tokenized expression source.
  /// - [ctx]: the evaluation context.
  /// - [rolePrefix]: prefix used to normalize role names.
  _Parser(this._tokens, this._ctx, this._rolePrefix);

  /// {@template _parser_is_at_end}
  /// Whether every token has been consumed.
  ///
  /// ### Returns
  /// `true` when [_pos] has reached the end of [_tokens].
  /// {@endtemplate}
  bool get isAtEnd => _pos >= _tokens.length;

  /// {@template _parser_peek}
  /// Returns the next token without advancing the cursor.
  ///
  /// ### Returns
  /// The token at [_pos]. Callers must check [isAtEnd] first.
  /// {@endtemplate}
  String peek() => _tokens[_pos];

  /// {@template _parser_advance}
  /// Returns the next token and advances the cursor by one.
  ///
  /// ### Returns
  /// The token that was at [_pos] before the advance.
  /// {@endtemplate}
  String advance() => _tokens[_pos++];

  /// {@template _parser_match}
  /// Consumes the next token when it equals [expected].
  ///
  /// ### Parameters
  /// - [expected]: the exact token to compare against.
  ///
  /// ### Returns
  /// `true` if the token matched and was consumed; `false` otherwise.
  /// {@endtemplate}
  bool _match(String expected) {
    if (!isAtEnd && _tokens[_pos] == expected) {
      _pos++;
      return true;
    }
    return false;
  }

  /// {@template _parser_match_keyword}
  /// Consumes the next token when its lowercased form equals [kw].
  ///
  /// This makes word operators such as `and`, `or`, and `not` case-insensitive.
  ///
  /// ### Parameters
  /// - [kw]: the lowercase keyword to match.
  ///
  /// ### Returns
  /// `true` if the token matched and was consumed; `false` otherwise.
  /// {@endtemplate}
  bool _matchKeyword(String kw) {
    if (!isAtEnd && _tokens[_pos].toLowerCase() == kw) {
      _pos++;
      return true;
    }
    return false;
  }

  /// {@template _parser_parse_expression}
  /// Parses the outermost grammar rule, an `or` expression.
  ///
  /// ### Returns
  /// The boolean value of the complete expression.
  /// {@endtemplate}
  bool parseExpression() => _parseOr();

  /// {@template _parser_parse_or}
  /// Parses `or` / `||` chains at the loosest precedence level.
  ///
  /// Operands are [_parseAnd] expressions; evaluation short-circuits at the
  /// Dart `||` operator level.
  ///
  /// ### Returns
  /// The combined boolean result.
  /// {@endtemplate}
  bool _parseOr() {
    var left = _parseAnd();
    while (_match('||') || _matchKeyword('or')) {
      final right = _parseAnd();
      left = left || right;
    }
    return left;
  }

  /// {@template _parser_parse_and}
  /// Parses `and` / `&&` chains, binding tighter than [_parseOr].
  ///
  /// Operands are [_parseUnary] expressions; evaluation short-circuits at the
  /// Dart `&&` operator level.
  ///
  /// ### Returns
  /// The combined boolean result.
  /// {@endtemplate}
  bool _parseAnd() {
    var left = _parseUnary();
    while (_match('&&') || _matchKeyword('and')) {
      final right = _parseUnary();
      left = left && right;
    }
    return left;
  }

  /// {@template _parser_parse_unary}
  /// Parses a leading `!` or `not`, or falls through to [_parsePrimary].
  ///
  /// Unary operators may be nested, so `!!permitAll()` is valid and equivalent
  /// to `permitAll()`.
  ///
  /// ### Returns
  /// The negated operand, or the primary value when no operator is present.
  /// {@endtemplate}
  bool _parseUnary() {
    if (_match('!') || _matchKeyword('not')) {
      return !_parseUnary();
    }
    return _parsePrimary();
  }

  /// {@template _parser_parse_primary}
  /// Parses the smallest unit: parentheses, literals, calls, keywords, or a
  /// comparison.
  ///
  /// A token followed by `(` is treated as a function call whose arguments are
  /// read by [_parseArguments] and dispatched to [_evalFunction]. Tokens such
  /// as `permitAll`, `denyAll`, `isAuthenticated`, and `isAnonymous` also work
  /// without parentheses. A comparison (`==` or `!=`) resolves both operands
  /// through [_resolveValue]. Any other token must resolve to a [bool].
  ///
  /// ### Returns
  /// The boolean value of the primary expression.
  ///
  /// ### Throws
  /// [FormatException] for an unclosed parenthesis, a missing right-hand
  /// operand, an invalid terminal, or a missing `)` after a call.
  /// {@endtemplate}
  bool _parsePrimary() {
    if (_match('(')) {
      final val = parseExpression();
      if (!_match(')')) {
        throw ParserException('Missing closing parenthesis in security expression');
      }
      return val;
    }

    if (isAtEnd) {
      throw ParserException('Unexpected end of security expression');
    }

    final token = advance();
    if (token == 'true') return true;
    if (token == 'false') return false;

    // Function call: name(arg1, arg2, ...)
    if (!isAtEnd && peek() == '(') {
      advance(); // consume '('
      final args = _parseArguments();
      if (!_match(')')) {
        throw ParserException('Missing ")" after $token(');
      }
      return _evalFunction(token, args);
    }

    // Bare keywords without ()
    switch (token) {
      case 'permitAll':
        return true;
      case 'denyAll':
        return false;
      case 'isAuthenticated':
        return _isAuthenticated();
      case 'isAnonymous':
        return _isAnonymous();
    }

    // Comparison: lhs == rhs or lhs != rhs
    if (!isAtEnd && (peek() == '==' || peek() == '!=')) {
      final op = advance();
      if (isAtEnd) {
        throw ParserException('Expected right-hand operand after "$op"');
      }
      final rhsToken = advance();
      final lhsVal = _resolveValue(token);
      final rhsVal = _resolveValue(rhsToken);
      return op == '==' ? lhsVal == rhsVal : lhsVal != rhsVal;
    }

    final resolved = _resolveValue(token);
    if (resolved is bool) return resolved;
    throw ParserException('Invalid security expression token "$token"');
  }

  /// {@template _parser_parse_arguments}
  /// Reads a comma-separated argument list. A bracketed argument
  /// (`['A', 'B']`) contributes several scalar values, which is how
  /// `hasAnyRole(['A','B'])` is expressed.
  ///
  /// Quotes are stripped from each value. A missing closing bracket is
  /// tolerated so a partially written expression can still be diagnosed by the
  /// caller's trailing-token check.
  ///
  /// ### Returns
  /// The flattened, unquoted argument values in source order.
  /// {@endtemplate}
  List<String> _parseArguments() {
    final args = <String>[];
    while (!isAtEnd && peek() != ')') {
      if (_match('[')) {
        while (!isAtEnd && peek() != ']') {
          args.add(_stripQuotes(advance()));
          if (!_match(',')) break;
        }
        _match(']');
      } else {
        args.add(_stripQuotes(advance()));
      }
      if (!_match(',')) break;
    }
    return args;
  }

  /// {@template _parser_eval_function}
  /// Dispatches a parsed call to the matching authorization terminal.
  ///
  /// Supported names are `permitAll`, `denyAll`, `isAuthenticated`,
  /// `isAnonymous`, `hasRole`, `hasAnyRole`, `hasAuthority`, and
  /// `hasAnyAuthority`. Role names are normalized with [_normalizeRole]; all
  /// authority checks ultimately run through [_hasAnyAuthority].
  ///
  /// ### Parameters
  /// - [name]: the function token as written in the expression.
  /// - [args]: already unquoted argument values.
  ///
  /// ### Returns
  /// The boolean result of the terminal.
  ///
  /// ### Throws
  /// [FormatException] for an unknown function or an incorrect argument count.
  /// {@endtemplate}
  bool _evalFunction(String name, List<String> args) {
    switch (name) {
      case 'permitAll':
        return true;
      case 'denyAll':
        return false;
      case 'isAuthenticated':
        return _isAuthenticated();
      case 'isAnonymous':
        return _isAnonymous();
      case 'hasRole':
        if (args.length != 1) {
          throw ParserException('hasRole expects 1 argument, got ${args.length}');
        }
        return _hasAnyAuthority([_normalizeRole(args.first)]);
      case 'hasAnyRole':
        return _hasAnyAuthority(args.map(_normalizeRole));
      case 'hasAuthority':
        if (args.length != 1) {
          throw ParserException('hasAuthority expects 1 argument, got ${args.length}');
        }
        return _hasAnyAuthority([args.first]);
      case 'hasAnyAuthority':
        return _hasAnyAuthority(args);
      default:
        throw ParserException('Unknown security expression function "$name"');
    }
  }

  /// {@template _parser_normalize_role}
  /// Adds [_rolePrefix] to [role] unless it is already prefixed.
  ///
  /// ### Parameters
  /// - [role]: the role name supplied to `hasRole` or `hasAnyRole`.
  ///
  /// ### Returns
  /// A prefixed role authority suitable for comparison with granted authorities.
  /// {@endtemplate}
  String _normalizeRole(String role) => role.startsWith(_rolePrefix) ? role : '$_rolePrefix$role';

  /// {@template _parser_is_authenticated}
  /// Reports whether the context holds a real, signed-in principal.
  ///
  /// ### Returns
  /// `true` when an authentication exists, is marked authenticated, and is not
  /// an [AnonymousAuthenticationToken].
  /// {@endtemplate}
  bool _isAuthenticated() {
    final auth = _ctx.authentication;
    return auth != null && auth.isAuthenticated && auth is! AnonymousAuthenticationToken;
  }

  /// {@template _parser_is_anonymous}
  /// Reports whether the context has no authentication or an anonymous one.
  ///
  /// ### Returns
  /// `true` when [SecurityExpressionContext.authentication] is `null` or an
  /// [AnonymousAuthenticationToken].
  /// {@endtemplate}
  bool _isAnonymous() {
    final auth = _ctx.authentication;
    return auth == null || auth is AnonymousAuthenticationToken;
  }

  /// {@template _parser_has_any_authority}
  /// Grants when at least one required authority is held by the principal.
  ///
  /// When the context supplies a role hierarchy, the principal's authorities
  /// are expanded through it before comparison. An unauthenticated principal
  /// never matches.
  ///
  /// ### Parameters
  /// - [requiredAuthorities]: exact authority strings to look for.
  ///
  /// ### Returns
  /// `true` when any required authority is reachable from the principal.
  /// {@endtemplate}
  bool _hasAnyAuthority(Iterable<String> requiredAuthorities) {
    final auth = _ctx.authentication;
    if (auth == null || !auth.isAuthenticated) {
      return false;
    }

    final Iterable<GrantedAuthority> effective = _ctx.roleHierarchy != null
        ? _ctx.roleHierarchy!.getReachableGrantedAuthorities(auth.authorities)
        : auth.authorities;

    final grantedSet = effective.map((a) => a.authority).toSet();
    for (final req in requiredAuthorities) {
      if (grantedSet.contains(req)) {
        return true;
      }
    }
    return false;
  }

  /// {@template _parser_resolve_value}
  /// Turns a value token into the object it denotes.
  ///
  /// Quoted literals become strings, `null`/`true`/`false` become their Dart
  /// equivalents, numeric tokens become [num] values, `#name` reads from
  /// [SecurityExpressionContext.arguments], and dotted roots resolve against
  /// `authentication`, `principal`, `returnObject`, or a named argument. A
  /// dotted tail is walked with [_resolvePath]. Unrecognized bare tokens are
  /// returned as strings.
  ///
  /// ### Parameters
  /// - [token]: the raw token to interpret.
  ///
  /// ### Returns
  /// The resolved value, possibly `null` when a path cannot be followed.
  /// {@endtemplate}
  Object? _resolveValue(String token) {
    if ((token.startsWith("'") && token.endsWith("'")) || (token.startsWith('"') && token.endsWith('"'))) {
      return _stripQuotes(token);
    }
    if (token == 'null') return null;
    if (token == 'true') return true;
    if (token == 'false') return false;
    final numVal = num.tryParse(token);
    if (numVal != null) return numVal;

    if (token.startsWith('#')) {
      return _resolvePath(_ctx.arguments[token.substring(1)], const []);
    }

    final parts = token.split('.');
    final root = parts.first;
    final tail = parts.sublist(1);

    if (root == 'authentication') {
      return _resolveAuthenticationPath(tail);
    }
    if (root == 'principal') {
      return _resolvePath(_ctx.authentication?.principal, tail);
    }
    if (root == 'returnObject') {
      return _resolvePath(_ctx.returnObject, tail);
    }

    if (_ctx.arguments.containsKey(root)) {
      return _resolvePath(_ctx.arguments[root], tail);
    }

    return token;
  }

  /// {@template _parser_resolve_authentication_path}
  /// Resolves a dotted path rooted at the current authentication.
  ///
  /// Supported segments are `name`, `principal`, and `isAuthenticated`; a
  /// `principal` segment may be followed by further property access.
  ///
  /// ### Parameters
  /// - [path]: the segments following `authentication`.
  ///
  /// ### Returns
  /// The resolved value, the whole [Authentication] for an empty path, or
  /// `null` when no authentication exists or the segment is unknown.
  /// {@endtemplate}
  Object? _resolveAuthenticationPath(List<String> path) {
    final auth = _ctx.authentication;
    if (auth == null) return null;
    if (path.isEmpty) return auth;
    switch (path.first) {
      case 'name':
        return auth.name;
      case 'principal':
        return _resolvePath(auth.principal, path.sublist(1));
      case 'isAuthenticated':
        return auth.isAuthenticated;
      default:
        return null;
    }
  }

  /// {@template _parser_resolve_path}
  /// Walks a dot-separated property path starting at [target].
  ///
  /// Each segment is resolved with `SecurityExpressionPropertyResolvers`. The
  /// first `null` encountered ends the walk and yields `null`.
  ///
  /// ### Parameters
  /// - [target]: the root object, which may be `null`.
  /// - [path]: property names to resolve in order.
  ///
  /// ### Returns
  /// The value at the end of the path, or `null` if the path cannot be followed.
  /// {@endtemplate}
  Object? _resolvePath(Object? target, List<String> path) {
    var current = target;
    for (final segment in path) {
      if (current == null) return null;
      current = SecurityExpressionPropertyResolvers.resolve(current, segment);
    }
    return current;
  }

  /// {@template _parser_strip_quotes}
  /// Removes a matching pair of single or double quotes from [s].
  ///
  /// ### Parameters
  /// - [s]: a possibly quoted token.
  ///
  /// ### Returns
  /// The unquoted text, or [s] unchanged when it is not quoted.
  /// {@endtemplate}
  static String _stripQuotes(String s) {
    if (s.length >= 2 && ((s.startsWith("'") && s.endsWith("'")) || (s.startsWith('"') && s.endsWith('"')))) {
      return s.substring(1, s.length - 1);
    }
    return s;
  }
}