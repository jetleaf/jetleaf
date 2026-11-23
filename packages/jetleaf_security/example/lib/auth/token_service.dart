import 'package:jetleaf_security/jwt.dart';

/// Issues and refreshes demo JWTs using the stateless token engine.
final class TokenService {
  const TokenService(this._provider);

  final JwtTokenProvider _provider;

  /// Issues an access token and a refresh token for [subject].
  Map<String, Object?> issue({
    required String subject,
    required List<String> roles,
    required String organizationId,
  }) =>
      {
        'access_token': _provider.generateAccessToken(
          subject: subject,
          roles: roles,
          additionalClaims: {'organizationId': organizationId},
        ),
        'refresh_token': _provider.generateRefreshToken(subject: subject),
        'token_type': 'Bearer',
        'subject': subject,
      };

  /// Verifies a refresh token and issues a fresh access token.
  Future<Map<String, Object?>> refresh(String refreshToken) async {
    final claims = await _provider.verifyToken(refreshToken);
    final subject = claims.subject;
    if (subject == null) {
      throw ArgumentError('Refresh token has no subject');
    }
    final authorities = _provider.extractAuthorities(claims);
    return issue(
      subject: subject,
      roles: authorities.map((authority) => authority.authority).toList(),
      organizationId: claims.getClaim<String>('organizationId') ?? 'acme',
    );
  }
}
