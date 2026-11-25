import '../core/authentication.dart';
import '../core/exceptions.dart';
import '../core/user_details.dart';
import '../core/user_details_service.dart';
import '../crypto/password_encoder.dart';
import 'authentication_provider.dart';
import 'username_password_authentication_token.dart';

/// {@template dao_authentication_provider}
/// An [AuthenticationProvider] that verifies username/password tokens against a
/// user store and a password encoder.
///
/// The provider loads a [UserDetails] record by the principal's name, checks
/// that the account is usable, compares the presented password with the stored
/// hash, and finally produces an authenticated
/// [UsernamePasswordAuthenticationToken] carrying the account's authorities.
///
/// ### Contract and invariants
/// - Only [UsernamePasswordAuthenticationToken] instances are supported; other
///   token types yield `null`.
/// - A missing or empty raw password is rejected with [BadCredentialsException].
/// - Unknown usernames are masked as [BadCredentialsException] by default so
///   callers cannot enumerate accounts; set [hideUserNotFoundExceptions] to
///   `false` to surface [UsernameNotFoundException] instead.
/// - Locked, disabled, expired, or credential-expired accounts are rejected
///   before any password comparison takes place.
/// - The raw password is never attached to the returned token.
/// - The provider is stateless after construction and safe to share across
///   requests.
///
/// ### Example
/// ```dart
/// final provider = DaoAuthenticationProvider(
///   userDetailsService: myUserDetailsService,
///   passwordEncoder: myPasswordEncoder,
/// );
///
/// final attempt = UsernamePasswordAuthenticationToken.unauthenticated(
///   principal: 'alice',
///   credentials: 's3cret',
/// );
/// final result = await provider.authenticate(attempt);
/// ```
/// {@endtemplate}
class DaoAuthenticationProvider implements AuthenticationProvider {
  /// Service used to load [UserDetails] by username.
  final UserDetailsService userDetailsService;

  /// Encoder used to verify raw passwords against stored hashes.
  final PasswordEncoder passwordEncoder;

  /// Whether to mask [UsernameNotFoundException] as [BadCredentialsException]
  /// to prevent username enumeration. Defaults to `true`.
  final bool hideUserNotFoundExceptions;

  /// {@macro dao_authentication_provider}
  DaoAuthenticationProvider({
    required this.userDetailsService,
    required this.passwordEncoder,
    this.hideUserNotFoundExceptions = true,
  });

  /// Reports support for exactly [UsernamePasswordAuthenticationToken].
  ///
  /// ### Parameters
  /// - [authentication] — the token being offered.
  ///
  /// ### Returns
  /// `true` when [authentication] is a [UsernamePasswordAuthenticationToken],
  /// including subclasses of that token type.
  @override
  bool supports(Authentication authentication) =>
      authentication is UsernamePasswordAuthenticationToken;

  /// Verifies a username/password token and produces a trusted result.
  ///
  /// ### Parameters
  /// - [authentication] — the untrusted token whose credentials are checked.
  ///
  /// ### Returns
  /// A future completing with an authenticated
  /// [UsernamePasswordAuthenticationToken], or `null` if [authentication] is
  /// not a supported token type.
  ///
  /// ### Throws
  /// [BadCredentialsException] for missing credentials, unknown usernames (when
  /// masked), or a password mismatch; [UsernameNotFoundException] when masking
  /// is disabled; and the account-status exceptions described by
  /// [_checkAccountStatus].
  @override
  Future<Authentication?> authenticate(Authentication authentication) async {
    if (authentication is! UsernamePasswordAuthenticationToken) {
      return null;
    }

    final username = authentication.principal?.toString() ?? '';
    final rawPassword = authentication.credentials?.toString();

    if (rawPassword == null || rawPassword.isEmpty) {
      throw BadCredentialsException('Credentials must not be empty');
    }

    final UserDetails user;
    try {
      user = await userDetailsService.loadUserByUsername(username);
    } on UsernameNotFoundException {
      if (hideUserNotFoundExceptions) {
        throw BadCredentialsException('Invalid username or password');
      }
      rethrow;
    }

    _checkAccountStatus(user);

    final encodedPassword = user.password;
    if (encodedPassword == null || !passwordEncoder.matches(rawPassword, encodedPassword)) {
      throw BadCredentialsException('Invalid username or password');
    }

    return UsernamePasswordAuthenticationToken.authenticated(
      principal: user,
      // Never let the raw password leave the provider. ProviderManager also
      // erases credentials as a defence in depth.
      credentials: null,
      authorities: user.authorities,
      details: authentication.details,
    );
  }

  /// {@template dao_authentication_provider._check_account_status}
  /// Verifies that [user] is in a state that permits authentication.
  ///
  /// Checks run in a fixed order — locked, disabled, account expired, then
  /// credentials expired — so the most actionable status wins when several
  /// conditions apply. The password is not compared unless every check passes.
  ///
  /// ### Parameters
  /// - [user] — the loaded account details to inspect.
  ///
  /// ### Throws
  /// [LockedException], [DisabledException], [AccountExpiredException], or
  /// [CredentialsExpiredException] when the corresponding flag is set.
  /// {@endtemplate}
  void _checkAccountStatus(UserDetails user) {
    if (!user.isAccountNonLocked) {
      throw LockedException();
    }
    if (!user.isEnabled) {
      throw DisabledException();
    }
    if (!user.isAccountNonExpired) {
      throw AccountExpiredException();
    }
    if (!user.isCredentialsNonExpired) {
      throw CredentialsExpiredException();
    }
  }
}