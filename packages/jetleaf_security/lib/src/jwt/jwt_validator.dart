import 'typedefs.dart';
// ignore_for_file: use_super_parameters

import '../core/exceptions.dart';
import 'jwt_claims_set.dart';

/// {@template jwt_validation_exception}
/// Thrown when a decoded JWT fails claim validation.
///
/// This signal is distinct from a signature failure: it means the token was
/// cryptographically valid but one or more of its claims did not satisfy the
/// configured policy.
///
/// - Carries the name of the failing check in its message for diagnosis.
/// - Is thrown only after signature verification, never instead of it.
/// - Extends [AuthenticationException] so callers can handle all token
///   rejections through one hierarchy.
/// {@endtemplate}
class JwtValidationException extends AuthenticationException {
  /// {@macro jwt_validation_exception}
  JwtValidationException(String message, [Object? cause]) : super(message, cause);
}

/// {@template jwt_validator}
/// Validates a decoded [JwtClaimsSet] against an explicit security policy.
///
/// All checks run in one predictable pipeline: expiration, not-before,
/// issued-at, issuer, audience, and finally the optional custom predicate.
/// Every timestamp check shares a single [clockSkew] value so the verifier and
/// issuer are judged against one consistent tolerance.
///
/// - **Fail-closed defaults:** a token without `exp` is rejected unless
///   [requireExpiration] is explicitly set to `false`; a token with no matching
///   audience is rejected whenever [expectedAudiences] is non-empty.
/// - **Clock skew:** [clockSkew] widens both sides of the timestamp window —
///   `exp` is honored until `exp + skew`, while `nbf` and `iat` are accepted
///   from `time - skew`. This absorbs small clock drift between hosts.
/// - **Issuer and audience are exact matches:** no prefix or suffix matching is
///   performed, and a token must carry at least one of the expected audiences.
/// - **Custom policy:** [customValidator] is the last gate and may inspect any
///   claim; returning `false` rejects the token.
///
/// ### See also
/// - [JwtClaimsSet] — the claims container being validated.
///
/// ### Example
/// ```dart
/// final validator = JwtValidator(
///   expectedIssuer: 'https://issuer.example.com',
///   expectedAudience: 'orders-api',
///   clockSkew: const Duration(seconds: 30),
/// );
/// validator.validate(claims); // throws JwtValidationException on failure
/// ```
/// {@endtemplate}
class JwtValidator {
  /// Expected `iss` claim, enforced when non-null.
  final String? expectedIssuer;

  /// Expected `aud` values; a token must contain at least one of them.
  final List<String> expectedAudiences;

  /// Tolerance shared by all timestamp comparisons.
  final Duration clockSkew;

  /// Whether a token without `exp` is rejected. Defaults to `true`.
  final bool requireExpiration;

  /// Optional final predicate invoked with the validated claims.
  final ClaimsValidator? customValidator;

  /// {@macro jwt_validator}
  ///
  /// ### Parameters
  /// - [expectedIssuer] — exact issuer URI to require, or `null` to skip the
  ///   issuer check.
  /// - [expectedAudience] — convenience form for a single required audience.
  /// - [expectedAudiences] — list of accepted audiences; takes precedence over
  ///   [expectedAudience] when supplied.
  /// - [clockSkew] — tolerance for `exp`, `nbf`, and `iat` checks.
  /// - [requireExpiration] — reject tokens that omit `exp` when `true`.
  /// - [customValidator] — final application-specific predicate.
  JwtValidator({
    this.expectedIssuer,
    String? expectedAudience,
    List<String>? expectedAudiences,
    this.clockSkew = const Duration(seconds: 30),
    this.requireExpiration = true,
    this.customValidator,
  }) : expectedAudiences = expectedAudiences ?? (expectedAudience == null ? const [] : [expectedAudience]);

  /// The first expected audience, or `null` when no audience is configured.
  ///
  /// Provided for callers that only ever configure a single audience.
  String? get expectedAudience => expectedAudiences.isEmpty ? null : expectedAudiences.first;

  /// {@template jwt_validator.validate}
  /// Validates [claims], throwing [JwtValidationException] on the first failure.
  ///
  /// Checks are applied in this order:
  ///
  /// 1. `exp` presence (when [requireExpiration]) and expiry, with [clockSkew]
  ///    granted to the token.
  /// 2. `nbf`, rejecting a token whose not-before time is still in the future
  ///    after subtracting [clockSkew] from the reference time.
  /// 3. `iat`, rejecting a token issued in the future beyond [clockSkew].
  /// 4. `iss`, requiring an exact match with [expectedIssuer] when configured.
  /// 5. `aud`, requiring at least one intersection with [expectedAudiences]
  ///    when configured.
  /// 6. [customValidator], when supplied, as the final gate.
  ///
  /// ### Parameters
  /// - [claims] — decoded claims from a token whose signature was already
  ///   verified. Claim validation never substitutes for signature verification.
  /// - [now] — reference instant; defaults to the current UTC time. Passing an
  ///   explicit instant makes validation deterministic in tests.
  ///
  /// ### Throws
  /// [JwtValidationException] with a message describing the failed check.
  ///
  /// ### Example
  /// ```dart
  /// validator.validate(claims, now: DateTime.parse('2026-01-01T00:00:00Z'));
  /// ```
  /// {@endtemplate}
  void validate(JwtClaimsSet claims, {DateTime? now}) {
    final reference = now ?? DateTime.now().toUtc();

    final exp = claims.expiresAt;
    if (exp == null && requireExpiration) {
      throw JwtValidationException('JWT token is missing the exp claim');
    }
    if (exp != null && exp.add(clockSkew).isBefore(reference)) {
      throw JwtValidationException('JWT token has expired');
    }

    final nbf = claims.notBefore;
    if (nbf != null && nbf.subtract(clockSkew).isAfter(reference)) {
      throw JwtValidationException('JWT token is not yet valid');
    }

    final iat = claims.issuedAt;
    if (iat != null && iat.subtract(clockSkew).isAfter(reference)) {
      throw JwtValidationException('JWT token has a future iat claim');
    }

    if (expectedIssuer != null && claims.issuer != expectedIssuer) {
      throw JwtValidationException('Invalid JWT issuer: expected "$expectedIssuer", got "${claims.issuer}"');
    }

    if (expectedAudiences.isNotEmpty) {
      final audiences = claims.audience;
      if (!expectedAudiences.any(audiences.contains)) {
        throw JwtValidationException('Invalid JWT audience: expected one of $expectedAudiences');
      }
    }

    if (customValidator != null && !customValidator!(claims)) {
      throw JwtValidationException('JWT failed custom validation');
    }
  }
}
