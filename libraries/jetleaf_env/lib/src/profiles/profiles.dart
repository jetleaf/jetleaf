import '_profiles_parser.dart';

/// {@template profiles}
/// A profile predicate used by [Environment] to determine if given profile
/// expressions match the active/default profiles.
///
/// Example:
/// ```dart
/// final profiles = Profiles.of(['dev & !test']);
/// final matches = profiles.matches((p) => ['dev'].contains(p)); // true
/// ```
///
/// Expressions support:
/// - Logical NOT:    !profile
/// - Logical AND:    profile1 & profile2
/// - Logical OR:     profile1 | profile2
/// - Parentheses:    (profile1 & !profile2) | profile3
/// {@endtemplate}
abstract class Profiles {
  /// Evaluates the profile predicate against a profile tester function.
  ///
  /// [isProfileActive] returns true if a profile is considered active.
  ///
  /// Example:
  /// ```dart
  /// profiles.matches((p) => active.contains(p));
  /// ```
  bool matches(bool Function(String profile) isProfileActive);

  /// Factory method for parsing profile expressions into a [Profiles] instance.
  ///
  /// Returns a compound predicate that evaluates to true if the expression matches.
  static Profiles of(List<String> expressions) => ProfilesParser.parse(expressions);
}