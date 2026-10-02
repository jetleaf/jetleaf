// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & Jetleaf Contributors. All rights reserved.
//
// This source file is part of the Jetleaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the Jetleaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

/// {@template path_match}
/// Represents the result of matching a request path against a compiled
/// [PathPattern] in Jetleaf.
///
/// Contains information about whether the match succeeded, any extracted
/// path variables, the original path segments, and the pattern used.
///
/// ### Example
/// ```dart
/// final match = PathMatch(
///   matches: true,
///   variables: {'id': '42'},
///   segments: ['api', 'users', '42'],
///   path: '/api/users/42',
///   pattern: '/api/users/{id}',
/// );
///
/// if (match.matches) {
///   final userId = match.getVariable('id'); // '42'
/// }
/// ```
///
/// ### See also
/// - [PathPattern] — the pattern matched against.
/// - [PathPatternParser] — parser that produces [PathPattern]s.
/// {@endtemplate}
class PathMatch {
  /// Whether the path successfully matches the pattern.
  final bool matches;

  /// Map of extracted variable names to their values.
  ///
  /// For example, for pattern `/users/{id}`, this could be `{ 'id': '42' }`.
  final Map<String, String> variables;

  /// The raw segments of the matched path, split by `/`.
  final List<String> segments;

  /// The full path string that was matched.
  final String path;

  /// The pattern string that was matched against.
  final String pattern;

  /// Additional metadata associated with the match.
  ///
  /// Can be used for storing custom information during routing or matching.
  final Map<String, dynamic> metadata;

  /// Creates a new [PathMatch] result.
  /// 
  /// {@macro path_match}
  const PathMatch({
    required this.matches,
    required this.variables,
    required this.segments,
    required this.path,
    required this.pattern,
    this.metadata = const {},
  });

  /// Creates a [PathMatch] representing a failed match.
  ///
  /// ### Example
  /// ```dart
  /// final noMatch = PathMatch.noMatch('/api/users', '/api/accounts/{id}');
  /// ```
  /// 
  /// {@macro path_match}
  factory PathMatch.noMatch(String path, String pattern) => PathMatch(matches: false, variables: {}, segments: [], path: path, pattern: pattern);

  /// Get a variable value by name.
  String? getVariable(String name) => variables[name];

  /// Get all variable names.
  Iterable<String> getVariableNames() => variables.keys;

  @override
  String toString() => 'PathMatch(matches: $matches, variables: $variables, pattern: $pattern)';
}