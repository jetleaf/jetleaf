import 'package:jetleaf_core/lang.dart' show IllegalArgumentException;
import 'exceptions.dart';
import 'user_details.dart';
import 'user_details_service.dart';

/// {@template in_memory_user_details_manager}
/// Non-persistent [UserDetailsService] backed by an in-memory map, suitable for
/// testing, demos, and lightweight deployments.
///
/// Usernames are matched case-insensitively by lower-casing the supplied key.
/// The backing map is not synchronized; populate it before publishing the
/// manager to concurrent request handlers, or guard external mutation.
///
/// ### Example
/// ```dart
/// final users = InMemoryUserDetailsManager([
///   SecurityUser.withRoles(username: 'alice', password: hash, roles: ['ADMIN']),
/// ]);
/// final alice = await users.loadUserByUsername('ALICE');
/// ```
///
/// ### See also
/// - [UserDetailsService] — the contract this manager fulfils.
/// {@endtemplate}
class InMemoryUserDetailsManager implements UserDetailsService {
  final Map<String, UserDetails> _users = {};

  /// {@macro in_memory_user_details_manager}
  ///
  /// Each supplied user is registered through [createUser], so a duplicate
  /// username in [users] is rejected immediately.
  InMemoryUserDetailsManager([Iterable<UserDetails> users = const []]) {
    for (final user in users) {
      createUser(user);
    }
  }

  /// Registers a new user.
  ///
  /// ### Parameters
  /// - [user]: the user to add; its username is the lookup key.
  ///
  /// ### Throws
  /// [ArgumentError] when a user with the same username already exists.
  void createUser(UserDetails user) {
    final key = user.username.toLowerCase();
    if (_users.containsKey(key)) {
      throw IllegalArgumentException('User "${user.username}" already exists.');
    }
    _users[key] = user;
  }

  /// Replaces an existing user.
  ///
  /// ### Parameters
  /// - [user]: the replacement, matched by username.
  ///
  /// ### Throws
  /// [UsernameNotFoundException] when no user with that username is registered.
  void updateUser(UserDetails user) {
    final key = user.username.toLowerCase();
    if (!_users.containsKey(key)) {
      throw UsernameNotFoundException('User "${user.username}" not found.');
    }
    _users[key] = user;
  }

  /// Removes a user by username.
  ///
  /// ### Parameters
  /// - [username]: the key to remove, matched case-insensitively. Unknown
  ///   usernames are ignored.
  void deleteUser(String username) {
    _users.remove(username.toLowerCase());
  }

  /// Returns whether a user with the given username exists.
  ///
  /// ### Parameters
  /// - [username]: the key to test, matched case-insensitively.
  ///
  /// ### Returns
  /// `true` when the user is registered.
  bool userExists(String username) => _users.containsKey(username.toLowerCase());

  @override
  Future<UserDetails> loadUserByUsername(String username) async {
    final user = _users[username.toLowerCase()];
    if (user == null) {
      throw UsernameNotFoundException('User "$username" not found.');
    }
    return user;
  }
}
