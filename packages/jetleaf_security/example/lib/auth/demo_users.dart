import 'package:jetleaf_security/core.dart';
import 'package:jetleaf_security/crypto.dart';

/// Demo user directory for the authentication endpoints.
final class DemoUsers {
  const DemoUsers._();

  /// Creates users whose passwords are hashed by the supplied encoder, which
  /// demonstrates the delegating encoder's `{id}` prefixes and matching.
  static List<UserDetails> create(PasswordEncoder encoder) => [
        SecurityUser(
          username: 'alice',
          password: encoder.encode('password'),
          authorities: {
            SimpleGrantedAuthority('ROLE_USER'),
            SimpleGrantedAuthority('ROLE_MEMBER'),
            SimpleGrantedAuthority('reports:read'),
          },
        ),
        SecurityUser(
          username: 'bob',
          password: encoder.encode('password'),
          authorities: {SimpleGrantedAuthority('ROLE_USER')},
        ),
        SecurityUser(
          username: 'admin',
          password: encoder.encode('password'),
          // Only ROLE_ADMIN is granted; ROLE_USER must come from the hierarchy.
          authorities: {SimpleGrantedAuthority('ROLE_ADMIN')},
        ),
        SecurityUser(
          username: 'locked',
          password: encoder.encode('password'),
          isAccountNonLocked: false,
          authorities: {SimpleGrantedAuthority('ROLE_USER')},
        ),
        SecurityUser(
          username: 'disabled',
          password: encoder.encode('password'),
          isEnabled: false,
          authorities: {SimpleGrantedAuthority('ROLE_USER')},
        ),
      ];
}