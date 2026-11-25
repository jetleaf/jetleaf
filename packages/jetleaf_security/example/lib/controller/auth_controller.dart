import 'package:jetleaf_core/annotation.dart';

import 'package:jetleaf_security/authentication.dart';
import 'package:jetleaf_security/core.dart';
import 'package:jetleaf_web/annotation.dart';

import '../auth/token_service.dart';

/// Token issuance and identity endpoints.
@RestController()
class AuthController {
  @Autowired()
  late final AuthenticationManager authenticationManager;

  @Autowired()
  late final TokenService tokenService;


  @PostMapping(path: '/api/auth/login')
  Future<Map<String, Object?>> login(
    @RequestParam(value: 'username') String username,
    @RequestParam(value: 'password') String password,
  ) async {
    final result = await authenticationManager.authenticate(
      UsernamePasswordAuthenticationToken.unauthenticated(
        principal: username,
        credentials: password,
      ),
    );
    final roles = result.authorities.map((authority) => authority.authority).toList();
    return tokenService.issue(
      subject: result.name,
      roles: roles,
      organizationId: _organizationFor(result.name),
    );
  }

  @PostMapping(path: '/api/auth/refresh')
  Future<Map<String, Object?>> refresh(
    @RequestParam(value: 'token') String token,
  ) =>
      tokenService.refresh(token);

  @GetMapping(path: '/api/auth/me')
  Future<Map<String, Object?>> me() async {
    final authentication = SecurityContextHolder.getContext().authentication;
    return {
      'name': authentication?.name,
      'authenticated': authentication?.isAuthenticated ?? false,
      'authorities': authentication?.authorities
              .map((authority) => authority.authority)
              .toList() ??
          const [],
    };
  }

  static String _organizationFor(String username) =>
      switch (username) {
        'bob' => 'beta',
        _ => 'acme',
      };
}