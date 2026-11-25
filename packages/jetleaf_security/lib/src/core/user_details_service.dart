import 'user_details.dart';

/// {@template user_details_service}
/// Core interface for components that load user-specific data during
/// authentication.
///
/// Implementations bridge the authentication layer to a user store. They are
/// expected to be stateless and safe for concurrent use; any caching policy is
/// an implementation detail.
///
/// ### Example
/// ```dart
/// final service = InMemoryUserDetailsManager(users);
/// final details = await service.loadUserByUsername(username);
/// ```
///
/// ### See also
/// - [UserDetails] — the value returned by a lookup.
/// {@endtemplate}
abstract interface class UserDetailsService {
  /// Locates the user identified by [username].
  ///
  /// ### Parameters
  /// - [username]: the login identifier to resolve.
  ///
  /// ### Returns
  /// The matching [UserDetails].
  ///
  /// ### Throws
  /// [UsernameNotFoundException] if no user could be found.
  Future<UserDetails> loadUserByUsername(String username);
}