import 'package:jetleaf_core/lang.dart' show EqualsAndHashCode;

/// {@template authorization_decision}
/// An immutable record describing the outcome of an authorization check.
///
/// AuthorizationDecision is the single value type returned by authorization
/// managers. It carries only the grant flag, keeping decisions cheap to create
/// and safe to share; the two canonical instances cover the common cases.
///
/// ### Contract and invariants
/// - [isGranted] is fixed at construction and never changes.
/// - [granted] and [denied] are shared constants for the two possible outcomes.
/// - Instances are safe to cache or compare by identity when using the constants.
///
/// ### Example
/// ```dart
/// AuthorizationDecision decide(bool allowed) =>
///     allowed ? AuthorizationDecision.granted : AuthorizationDecision.denied;
///
/// print(decide(true).isGranted); // true
/// ```
///
/// ### See also
/// - [AuthorizationManager]
/// {@endtemplate}
final class AuthorizationDecision with EqualsAndHashCode {
  /// Whether access is granted.
  final bool isGranted;

  /// {@macro authorization_decision}
  const AuthorizationDecision(this.isGranted);

  /// Grants access.
  static const AuthorizationDecision granted = AuthorizationDecision(true);

  /// Denies access.
  static const AuthorizationDecision denied = AuthorizationDecision(false);

  @override
  String toString() => 'AuthorizationDecision(isGranted: $isGranted)';

  /// Contributes the runtime type and [isGranted] to equality and hashing.
  ///
  /// ### Returns
  /// The ordered list of properties used by [EqualsAndHashCode].
  @override
  List<Object?> equalizedProperties() => [runtimeType, isGranted];
}
