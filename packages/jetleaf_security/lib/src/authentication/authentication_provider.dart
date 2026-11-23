import '../core/authentication.dart';

/// {@template authentication_provider}
/// Contract for a component that can process one shape of [Authentication]
/// token.
///
/// A provider narrows the work of an [AuthenticationManager] to a single token
/// type. Managers consult [supports] first, then invoke [authenticate] only on
/// providers that claim the token. This keeps each credential mechanism —
/// username/password, token exchange, anonymous access — isolated behind one
/// consistent interface.
///
/// ### Contract
/// - [supports] inspects the concrete token instance, so implementations can
///   use Dart's `is` operator and accept subclasses naturally.
/// - [authenticate] returns `null` when the provider declines the token, and
///   otherwise follows the same success/failure rules as
///   [AuthenticationManager.authenticate].
/// - A supported token whose credentials are invalid must throw rather than
///   return `null`, so failures are never confused with "not applicable".
///
/// ### Example
/// ```dart
/// final class ApiKeyProvider implements AuthenticationProvider {
///   const ApiKeyProvider();
///
///   @override
///   bool supports(Authentication authentication) =>
///       authentication is ApiKeyToken;
///
///   @override
///   Future<Authentication?> authenticate(Authentication authentication) async {
///     if (authentication is! ApiKeyToken) return null;
///     // Verify the key, then return a trusted token.
///     return authenticatedTokenFor(authentication.principal);
///   }
/// }
/// ```
///
/// ### See also
/// - [AuthenticationManager]
/// - [ProviderManager]
/// - [DaoAuthenticationProvider]
/// {@endtemplate}
abstract interface class AuthenticationProvider {
  /// Performs authentication using the same contract as
  /// [AuthenticationManager.authenticate].
  ///
  /// ### Parameters
  /// - [authentication] — the token whose credentials should be verified.
  ///
  /// ### Returns
  /// A fully populated [Authentication] on success, or `null` if this provider
  /// does not support the supplied token. A supported token whose credentials
  /// are invalid must throw rather than return `null`.
  ///
  /// ### Throws
  /// An [AuthenticationException] when verification fails.
  Future<Authentication?> authenticate(Authentication authentication);

  /// Reports whether this provider can process [authentication].
  ///
  /// Managers call this predicate before invoking [authenticate]. Inspect the
  /// instance with `is` so that token subclasses are handled correctly.
  ///
  /// ### Parameters
  /// - [authentication] — the concrete token being offered.
  ///
  /// ### Returns
  /// `true` if [authenticate] should be called for this token.
  bool supports(Authentication authentication);
}
