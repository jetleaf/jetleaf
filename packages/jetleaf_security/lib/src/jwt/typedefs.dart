import 'jwt_claims_set.dart';

/// {@template claims_validator}
/// Evaluates an application-specific rule over decoded token claims.
///
/// The validator runs after signature verification and the built-in claim
/// checks. Returning `false` rejects the token.
/// {@endtemplate}
typedef ClaimsValidator = bool Function(JwtClaimsSet claims);