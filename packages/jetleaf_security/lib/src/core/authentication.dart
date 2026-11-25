import 'package:jetleaf_core/lang.dart' show IllegalArgumentException;
import 'granted_authority.dart';

/// {@template authentication}
/// Represents an authentication request, or the authenticated principal that
/// remains after the request has been verified.
///
/// An [Authentication] carries the identity being checked ([principal]), the
/// proof supplied with the request ([credentials]), the [authorities] the
/// principal is allowed to exercise, and optional request-scoped [details].
///
/// Trust is deliberately one-way:
///
/// - Only named factory constructors on concrete implementations may create a
///   token whose [isAuthenticated] is `true`.
/// - The [isAuthenticated] setter is revoke-only; assigning `true` is rejected
///   by [checkAuthenticationRevocation] with an [ArgumentError].
/// - [eraseCredentials] gives implementations a hook for dropping sensitive
///   data once verification has finished.
///
/// Implementations should be immutable value objects so a token can be shared
/// across request-scoped zones without extra synchronization.
///
/// ### Example
/// ```dart
/// void describe(Authentication authentication) {
///   print('${authentication.name}: authenticated=${authentication.isAuthenticated}');
///   for (final authority in authentication.authorities) {
///     print('  - ${authority.authority}');
///   }
/// }
/// ```
///
/// ### See also
/// - [GrantedAuthority] — the individual permissions held by a principal.
/// - [checkAuthenticationRevocation] — the shared trust guard used by implementations.
/// {@endtemplate}
abstract interface class Authentication {
  /// The identity of the principal being authenticated (e.g. a username or a
  /// user-details object).
  ///
  /// ### Returns
  /// The principal object, or `null` when no identity has been established.
  Object? get principal;

  /// The credentials that prove the principal is correct (e.g. a password or
  /// bearer token).
  ///
  /// ### Returns
  /// The raw credentials, or `null` once they have been erased.
  Object? get credentials;

  /// The immutable set of authorities granted to the principal.
  ///
  /// ### Returns
  /// A non-null set; callers must not attempt to mutate it.
  Set<GrantedAuthority> get authorities;

  /// Additional details about the authentication request (e.g. an IP address
  /// or session identifier).
  ///
  /// ### Returns
  /// An implementation-defined detail object, or `null` when unavailable.
  Object? get details;

  /// Whether the credentials have been verified and the token is trusted.
  ///
  /// ### Returns
  /// `true` only for tokens produced by an authenticated factory constructor.
  bool get isAuthenticated;

  /// Revokes trust on this token.
  ///
  /// Implementations must reject any attempt to grant trust through this
  /// setter; trust can only be established at construction time.
  ///
  /// ### Parameters
  /// - [value]: must be `false`. Passing `true` is an error.
  ///
  /// ### Throws
  /// [ArgumentError] when [value] is `true`.
  set isAuthenticated(bool value);

  /// Returns the display name of this principal, or an empty string when the
  /// principal is `null`.
  ///
  /// ### Returns
  /// [principal]'s string representation, or `''`.
  String get name => principal?.toString() ?? '';

  /// Clears sensitive credentials from memory once authentication completes.
  ///
  /// The default implementation is a no-op; implementations that hold a
  /// password or token should override it and null out their credential field.
  void eraseCredentials() {}
}

/// {@template check_authentication_revocation}
/// Shared guard that rejects attempts to grant trust through a setter.
///
/// Concrete [Authentication] implementations call this from their
/// `isAuthenticated` setter so the "construct trusted, revoke later" rule is
/// enforced consistently across every token type.
///
/// ### Parameters
/// - [value]: the requested authentication flag; only `false` is permitted.
///
/// ### Throws
/// [ArgumentError] when [value] is `true`.
///
/// ### Example
/// ```dart
/// set isAuthenticated(bool value) {
///   checkAuthenticationRevocation(value);
///   _authenticated = value;
/// }
/// ```
/// {@endtemplate}
void checkAuthenticationRevocation(bool value) {
  if (value) {
    throw IllegalArgumentException(
      'isAuthenticated: Trust cannot be granted through the setter; '
      'use an authenticated factory constructor',
    );
  }
}