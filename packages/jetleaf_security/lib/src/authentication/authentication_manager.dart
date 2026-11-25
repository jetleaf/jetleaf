import '../core/authentication.dart';

/// {@template authentication_manager}
/// Contract for the component that processes an [Authentication] request.
///
/// An authentication manager is the entry point for verifying credentials. It
/// accepts a token that describes *who* claims to be calling, performs whatever
/// verification its strategy requires, and returns a new, fully populated token
/// whose authorities describe what that caller is allowed to do.
///
/// ### Contract
/// - [authenticate] returns a trusted [Authentication] object on success.
/// - It throws an [AuthenticationException] when the request cannot be
///   verified; it never signals failure by returning `null`.
/// - The returned token must be safe to hand to authorization code: its
///   [Authentication.isAuthenticated] flag is `true` and its authorities are
///   populated.
/// - Implementations must not mutate the supplied token; produce a fresh
///   result instead.
/// - Implementations should be safe to invoke concurrently for independent
///   requests.
///
/// ### Example
/// ```dart
/// Future<Authentication> signIn(String username, String password) async {
///   final attempt = UsernamePasswordAuthenticationToken.unauthenticated(
///     principal: username,
///     credentials: password,
///   );
///   return manager.authenticate(attempt);
/// }
/// ```
///
/// ### See also
/// - [AuthenticationProvider]
/// - [ProviderManager]
/// - [Authentication]
/// {@endtemplate}
abstract interface class AuthenticationManager {
  /// Attempts to authenticate [authentication].
  ///
  /// The supplied object is an authentication *request*: it carries the
  /// claimed principal and the credentials that are to be verified. On success
  /// a different, trusted object is returned; on failure an
  /// [AuthenticationException] is thrown.
  ///
  /// ### Parameters
  /// - [authentication] — the untrusted token to verify.
  ///
  /// ### Returns
  /// A future completing with a fully populated [Authentication], including
  /// its granted authorities.
  ///
  /// ### Throws
  /// [AuthenticationException] if the credentials are invalid, the account is
  /// in an unusable state, or no strategy can process the token.
  ///
  /// ### Example
  /// ```dart
  /// try {
  ///   final result = await manager.authenticate(attempt);
  ///   print('signed in as ${result.name}');
  /// } on AuthenticationException catch (e) {
  ///   print('sign-in failed: ${e.message}');
  /// }
  /// ```
  Future<Authentication> authenticate(Authentication authentication);
}