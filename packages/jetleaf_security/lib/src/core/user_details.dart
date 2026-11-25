import 'package:jetleaf_core/lang.dart' show EqualsAndHashCode;

import 'granted_authority.dart';
import 'simple_granted_authority.dart';

/// {@template user_details}
/// Provides the core user information needed for authentication and
/// authorization decisions.
///
/// Implementations expose the username and encoded password plus four account
/// flags. All four flags are positive: `true` means the account is usable.
/// Providers should reject a user when any flag is `false` rather than leaving
/// that decision to downstream authorization code.
///
/// ### See also
/// - [SecurityUser] — a ready-to-use implementation.
/// - [GrantedAuthority] — the permissions returned by [authorities].
/// {@endtemplate}
abstract interface class UserDetails {
  /// Returns the authorities granted to the user.
  ///
  /// ### Returns
  /// A non-null set of authorities; callers should treat it as read-only.
  Set<GrantedAuthority> get authorities;

  /// Returns the encoded password used to authenticate the user.
  ///
  /// ### Returns
  /// The hash, or `null` when the user cannot authenticate with a password.
  String? get password;

  /// Returns the username used to authenticate the user.
  ///
  /// ### Returns
  /// The unique login identifier.
  String get username;

  /// Indicates whether the user's account has not expired.
  ///
  /// ### Returns
  /// `true` when the account is still valid.
  bool get isAccountNonExpired;

  /// Indicates whether the user's account is unlocked.
  ///
  /// ### Returns
  /// `false` when the account has been locked.
  bool get isAccountNonLocked;

  /// Indicates whether the user's credentials have not expired.
  ///
  /// ### Returns
  /// `false` when a password change is required.
  bool get isCredentialsNonExpired;

  /// Indicates whether the user is enabled.
  ///
  /// ### Returns
  /// `false` when the account has been disabled.
  bool get isEnabled;
}

/// {@template security_user}
/// Default [UserDetails] implementation with immutable account state.
///
/// The [authorities] set is wrapped with [Set.unmodifiable] at construction
/// time. The password field remains mutable so a provider can migrate a hash
/// after a successful login, or a credential-clearing hook can drop it.
///
/// ### Example
/// ```dart
/// final user = SecurityUser.withRoles(
///   username: 'alice',
///   password: hash,
///   roles: ['ADMIN'],
/// );
/// print(user.authorities.first.authority); // ROLE_ADMIN
/// ```
///
/// ### See also
/// - [UserDetails] — the contract being implemented.
/// - [SimpleGrantedAuthority] — used to build the authority set.
/// {@endtemplate}
class SecurityUser with EqualsAndHashCode implements UserDetails {
  @override
  final String username;

  @override
  String? password;

  @override
  final Set<GrantedAuthority> authorities;

  @override
  final bool isAccountNonExpired;

  @override
  final bool isAccountNonLocked;

  @override
  final bool isCredentialsNonExpired;

  @override
  final bool isEnabled;

  /// {@macro security_user}
  ///
  /// [authorities] is defensively copied into an unmodifiable set.
  SecurityUser({
    required this.username,
    this.password,
    Set<GrantedAuthority> authorities = const {},
    this.isAccountNonExpired = true,
    this.isAccountNonLocked = true,
    this.isCredentialsNonExpired = true,
    this.isEnabled = true,
  }) : authorities = Set.unmodifiable(authorities);

  /// {@template security_user_with_roles}
  /// Creates a [SecurityUser] from role names and plain authority strings.
  ///
  /// Role names that do not already start with `ROLE_` are prefixed
  /// automatically; entries in [authorities] are used verbatim.
  ///
  /// ### Parameters
  /// - [username]: the login identifier.
  /// - [password]: the encoded password, if any.
  /// - [roles]: role names to prefix and grant.
  /// - [authorities]: fine-grained permissions to grant as-is.
  /// - [isAccountNonExpired], [isAccountNonLocked],
  ///   [isCredentialsNonExpired], [isEnabled]: account-state flags.
  ///
  /// ### Returns
  /// A user whose authority set contains both roles and permissions.
  /// {@endtemplate}
  /// {@macro security_user}
  factory SecurityUser.withRoles({
    required String username,
    String? password,
    List<String> roles = const [],
    List<String> authorities = const [],
    bool isAccountNonExpired = true,
    bool isAccountNonLocked = true,
    bool isCredentialsNonExpired = true,
    bool isEnabled = true,
  }) {
    final granted = <GrantedAuthority>{
      for (final role in roles) ...{
        SimpleGrantedAuthority(role.startsWith('ROLE_') ? role : 'ROLE_$role')
      },
      for (final auth in authorities) ...{
        SimpleGrantedAuthority(auth)
      },
    };
    return SecurityUser(
      username: username,
      password: password,
      authorities: granted,
      isAccountNonExpired: isAccountNonExpired,
      isAccountNonLocked: isAccountNonLocked,
      isCredentialsNonExpired: isCredentialsNonExpired,
      isEnabled: isEnabled,
    );
  }

  /// {@template security_user_copy_with}
  /// Returns a copy of this user with an updated password.
  ///
  /// ### Parameters
  /// - [password]: the replacement hash; when `null`, the current password is
  ///   retained.
  ///
  /// ### Returns
  /// A new [SecurityUser] with identical identity, authorities, and flags.
  /// {@endtemplate}
  /// {@macro security_user}
  SecurityUser copyWith({String? password}) => SecurityUser(
    username: username,
    password: password ?? this.password,
    authorities: authorities,
    isAccountNonExpired: isAccountNonExpired,
    isAccountNonLocked: isAccountNonLocked,
    isCredentialsNonExpired: isCredentialsNonExpired,
    isEnabled: isEnabled,
  );

  @override
  String toString() => 'SecurityUser(username: $username, enabled: $isEnabled, authorities: $authorities)';

  /// Contributes the immutable identity fields to equality and hashing.
  ///
  /// The mutable [password] is excluded because it is a credential, not part of
  /// the user's identity.
  ///
  /// ### Returns
  /// The ordered list of properties used by [EqualsAndHashCode].
  @override
  List<Object?> equalizedProperties() => [
    runtimeType,
    username,
    authorities,
    isAccountNonExpired,
    isAccountNonLocked,
    isCredentialsNonExpired,
    isEnabled,
  ];
}