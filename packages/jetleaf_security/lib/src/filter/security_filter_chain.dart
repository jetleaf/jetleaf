import 'package:jetleaf_core/lang.dart';
import 'package:jetleaf_web/jetleaf_web.dart';

import 'security_filter.dart';

/// {@template request_matcher}
/// Strategy interface used by [SecurityFilterChain] to decide whether a chain
/// handles a given [ServerHttpRequest].
///
/// Matchers are predicates: they inspect method, path, headers or any other
/// request property and answer a single yes/no question. They are consulted in
/// chain selection order by `FilterChainProxy`.
///
/// ### Contract
/// - [matches] must be deterministic and free of side effects on the request.
/// - Implementations should be thread-safe because selection may happen
///   concurrently for different requests.
/// - A `true` result does not guarantee the request will be handled; it means
///   the chain is eligible.
///
/// ### Who implements this
/// [AnyRequestMatcher] and [PathPatternMatcher] are the built-in
/// implementations; applications may supply custom matchers for headers, IPs
/// or other attributes.
///
/// ### See also
/// - [AnyRequestMatcher]
/// - [PathPatternMatcher]
/// - [SecurityFilterChain]
/// {@endtemplate}
abstract interface class RequestMatcher {
  /// Returns `true` if this matcher matches [request].
  ///
  /// ### Parameters
  /// - [request]: The incoming [ServerHttpRequest] to evaluate.
  ///
  /// ### Returns
  /// `true` when the request satisfies the matcher's criteria.
  ///
  /// ### Example
  /// ```dart
  /// if (matcher.matches(request)) {
  ///   // this chain is eligible
  /// }
  /// ```
  bool matches(ServerHttpRequest request);
}

/// {@template any_request_matcher}
/// A [RequestMatcher] that matches every incoming request.
///
/// This is the default matcher for a [SecurityFilterChain], making it a
/// catch-all chain. Register more specific chains first when several chains
/// coexist.
///
/// ### Example
/// ```dart
/// const matcher = AnyRequestMatcher();
/// assert(matcher.matches(request));
/// ```
/// {@endtemplate}
class AnyRequestMatcher with EqualsAndHashCode implements RequestMatcher {
  /// {@macro any_request_matcher}
  const AnyRequestMatcher();

  /// Always returns `true`.
  ///
  /// ### Parameters
  /// - [request]: Ignored.
  ///
  /// ### Returns
  /// `true` for every request.
  @override
  bool matches(ServerHttpRequest request) => true;

  /// Contributes the runtime type to equality and hashing.
  ///
  /// ### Returns
  /// The ordered list of properties used by [EqualsAndHashCode].
  @override
  List<Object?> equalizedProperties() => [runtimeType];
}

/// {@template path_pattern_matcher}
/// Matches requests by Ant-style path pattern (for example `/api/**`,
/// `/admin/*`) and an optional HTTP method.
///
/// Patterns are compiled once at construction into a regular expression. A
/// single `*` matches characters within one path segment, `**` spans segments,
/// and `?` matches exactly one character.
///
/// ### Contract
/// - A null [method] matches any HTTP method.
/// - Method comparison is case-insensitive.
/// - The compiled pattern is anchored, so the whole path must match.
///
/// ### Example
/// ```dart
/// const matcher = PathPatternMatcher('/api/**', method: 'GET');
/// matcher.matches(request); // true only for GET under /api/
/// ```
/// {@endtemplate}
class PathPatternMatcher with EqualsAndHashCode implements RequestMatcher {
  /// Ant-style path pattern.
  final String pattern;

  /// Optional HTTP method name (for example `GET`, `POST`). Null matches any
  /// method.
  final String? method;

  /// {@template path_pattern_matcher.regex}
  /// Compiled regular expression equivalent of [pattern].
  /// {@endtemplate}
  final RegExp _regex;

  /// {@macro path_pattern_matcher}
  PathPatternMatcher(this.pattern, {this.method}) : _regex = _compileAnt(pattern);

  /// Returns whether [request]'s method and path satisfy this matcher.
  ///
  /// ### Parameters
  /// - [request]: The incoming [ServerHttpRequest] to evaluate.
  ///
  /// ### Returns
  /// `true` when the method matches (or is unrestricted) and the request path
  /// matches the compiled pattern.
  @override
  bool matches(ServerHttpRequest request) {
    if (method != null && request.getMethod().toString().toUpperCase() != method!.toUpperCase()) {
      return false;
    }
    final path = request.getRequestURI().path;
    return _regex.hasMatch(path);
  }

  /// Contributes the runtime type, [pattern] and [method] to equality and
  /// hashing.
  ///
  /// The compiled [_regex] is derived from [pattern] and is excluded.
  ///
  /// ### Returns
  /// The ordered list of properties used by [EqualsAndHashCode].
  @override
  List<Object?> equalizedProperties() => [runtimeType, pattern, method];

  /// {@template path_pattern_matcher.compile_ant}
  /// Compiles an Ant-style [pattern] into an anchored [RegExp].
  ///
  /// `**` becomes a segment-spanning wildcard, `*` a within-segment wildcard,
  /// and `?` a single-character wildcard; all other characters are escaped.
  ///
  /// ### Parameters
  /// - [pattern]: The Ant-style path pattern to translate.
  ///
  /// ### Returns
  /// An anchored regular expression matching the pattern.
  /// {@endtemplate}
  static RegExp _compileAnt(String pattern) {
    final escaped = StringBuffer('^');
    var i = 0;
    while (i < pattern.length) {
      if (i + 1 < pattern.length && pattern[i] == '*' && pattern[i + 1] == '*') {
        escaped.write('.*');
        i += 2;
        if (i < pattern.length && pattern[i] == '/') {
          escaped.write('/?');
          i++;
        }
      } else if (pattern[i] == '*') {
        escaped.write('[^/]*');
        i++;
      } else if (pattern[i] == '?') {
        escaped.write('[^/]');
        i++;
      } else {
        escaped.write(RegExp.escape(pattern[i]));
        i++;
      }
    }
    escaped.write(r'$');
    return RegExp(escaped.toString());
  }
}

/// {@template security_filter_chain}
/// Ordered chain of [SecurityFilter] instances executed for requests matching
/// [requestMatcher].
///
/// The chain sorts its filters by [SecurityFilter.order] at construction and
/// wraps the downstream web filter chain in a virtual chain that advances one
/// filter at a time. If the matcher declines a request, the chain delegates
/// straight to the downstream filters.
///
/// ### Contract and ordering guarantees
/// - Filters always run in ascending [SecurityFilter.order].
/// - Each filter is invoked exactly once per request when the chain matches.
/// - The final element of the virtual chain is the web filter chain supplied to
///   [doFilter], so control returns to the application after all security
///   filters have run.
/// - Equality is based on matcher, filters and selection order.
///
/// ### See also
/// - [SecurityFilter]
/// - [RequestMatcher]
/// - `FilterChainProxy`
/// {@endtemplate}
class SecurityFilterChain with EqualsAndHashCode implements Filter {
  /// Matcher determining if this chain applies to an incoming request.
  final RequestMatcher requestMatcher;

  /// Ordered list of security filters executed by this chain.
  ///
  /// The list is sorted by [SecurityFilter.order] and made unmodifiable.
  final List<SecurityFilter> filters;

  /// Selection order when several chains are registered in a `FilterChainProxy`.
  /// Lower values are considered first.
  final int order;

  /// {@macro security_filter_chain}
  SecurityFilterChain({
    this.requestMatcher = const AnyRequestMatcher(),
    required List<SecurityFilter> filters,
    this.order = 0,
  }) : filters = List.unmodifiable([...filters]..sort((a, b) => a.order.compareTo(b.order)));

  /// Returns `true` if this chain handles [request].
  ///
  /// ### Parameters
  /// - [request]: The incoming [ServerHttpRequest].
  ///
  /// ### Returns
  /// The result of delegating to [requestMatcher].
  bool matches(ServerHttpRequest request) => requestMatcher.matches(request);

  /// Runs the ordered filters for [request] or forwards it when not matched.
  ///
  /// [request] and [response] are passed through every filter in order.
  /// [chain] is the downstream web filter chain: it becomes the terminal link
  /// of the internal virtual chain, reached only when every security filter has
  /// called `next`. A non-matching request goes straight to it.
  ///
  /// ### Parameters
  /// - [request]: The incoming [ServerHttpRequest].
  /// - [response]: The outgoing [ServerHttpResponse].
  /// - [chain]: The downstream web filter chain.
  ///
  /// ### Returns
  /// A [Future] that completes when the internal chain and downstream filters
  /// finish.
  ///
  /// ### Throws
  /// Propagates exceptions from any security filter, allowing outer exception
  /// translation to handle them.
  ///
  /// ### Example
  /// ```dart
  /// await chain.doFilter(request, response, webFilterChain);
  /// ```
  @override
  Future<void> doFilter(ServerHttpRequest request, ServerHttpResponse response, FilterChain chain) async {
    if (!matches(request)) {
      await chain.next(request, response);
      return;
    }
    final internalChain = _VirtualFilterChain(filters, chain);
    await internalChain.next(request, response);
  }

  /// Contributes the runtime type, matcher, filters and selection order to
  /// equality.
  ///
  /// ### Returns
  /// The ordered list of properties used by [EqualsAndHashCode].
  @override
  List<Object?> equalizedProperties() => [runtimeType, requestMatcher, filters, order];
}

/// {@template security_filter_chain.virtual_filter_chain}
/// Internal [FilterChain] that walks a chain's [SecurityFilter] list one element
/// at a time before handing off to the downstream web filter chain.
///
/// `_filters` holds the sorted security filters, `_downstream` is the web
/// filter chain, and `_index` tracks progress so each filter runs once per
/// request.
/// {@endtemplate}
class _VirtualFilterChain implements FilterChain {
  /// {@template security_filter_chain.virtual_filter_chain.filters}
  /// Ordered security filters still to be invoked.
  /// {@endtemplate}
  final List<SecurityFilter> _filters;

  /// {@template security_filter_chain.virtual_filter_chain.downstream}
  /// Web filter chain invoked after the last security filter.
  /// {@endtemplate}
  final FilterChain _downstream;

  /// {@template security_filter_chain.virtual_filter_chain.index}
  /// Index of the next security filter to run.
  /// {@endtemplate}
  int _index = 0;

  /// {@macro security_filter_chain.virtual_filter_chain}
  _VirtualFilterChain(this._filters, this._downstream);

  /// Runs the next security filter, or the downstream chain when none remain.
  ///
  /// ### Parameters
  /// - [request]: The incoming [ServerHttpRequest].
  /// - [response]: The outgoing [ServerHttpResponse].
  ///
  /// ### Returns
  /// A [Future] that completes after the invoked filter or downstream chain.
  @override
  Future<void> next(ServerHttpRequest request, ServerHttpResponse response) async {
    if (_index < _filters.length) {
      final current = _filters[_index++];
      await current.doFilter(request, response, this);
    } else {
      await _downstream.next(request, response);
    }
  }
}
