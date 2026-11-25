import 'package:jetleaf_security/jetleaf_security.dart';
import 'package:test/test.dart';

/// Red-phase tests for defects 1, 13 and 14 in the rewrite specification.
class _SubclassedToken extends UsernamePasswordAuthenticationToken {
  _SubclassedToken.unauthenticated({required super.principal, required super.credentials})
      : super.unauthenticated();
}

class _StubEncoder implements PasswordEncoder {
  @override
  String encode(String rawPassword) => 'stub:$rawPassword';

  @override
  bool matches(String rawPassword, String encodedPassword) =>
      encodedPassword == 'stub:$rawPassword';

  @override
  bool upgradeEncoding(String encodedPassword) => false;

  @override
  Future<String> encodeAsync(String rawPassword) async => encode(rawPassword);

  @override
  Future<bool> matchesAsync(String rawPassword, String encodedPassword) async =>
      matches(rawPassword, encodedPassword);
}

class _StubUserDetailsService implements UserDetailsService {
  UserDetails? _user;

  void createUser(UserDetails user) => _user = user;

  @override
  Future<UserDetails> loadUserByUsername(String username) async {
    if (_user?.username == username) return _user!;
    throw UsernameNotFoundException(username);
  }
}

void main() {
  group('Authentication defects (red phase)', () {
    test('an unauthenticated token cannot be promoted via the setter', () {
      final token = UsernamePasswordAuthenticationToken.unauthenticated(
        principal: 'alice',
        credentials: 'secret',
      );

      expect(token.isAuthenticated, isFalse);
      expect(() => token.isAuthenticated = true, throwsA(anything));
    });

    test('providers support subclasses of their token type', () {
      final provider = DaoAuthenticationProvider(
        userDetailsService: _StubUserDetailsService(),
        passwordEncoder: _StubEncoder(),
      );

      expect(
        provider.supports(
          _SubclassedToken.unauthenticated(principal: 'alice', credentials: 'secret'),
        ),
        isTrue,
      );
    });

    test('a provider does not leak the raw password in its result', () async {
      final user = SecurityUser(
        username: 'alice',
        password: 'stub:secret',
        authorities: {SimpleGrantedAuthority('ROLE_USER')},
      );
      final service = _StubUserDetailsService()..createUser(user);
      final provider = DaoAuthenticationProvider(
        userDetailsService: service,
        passwordEncoder: _StubEncoder(),
      );

      final result = await provider.authenticate(
        UsernamePasswordAuthenticationToken.unauthenticated(
          principal: 'alice',
          credentials: 'secret',
        ),
      );

      expect(result, isNotNull);
      expect(result!.credentials, isNull,
          reason: 'A raw password must never leave the provider');
    });
  });
}