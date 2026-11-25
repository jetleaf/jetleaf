import 'argon2id_password_encoder.dart';
import 'bcrypt_password_encoder.dart';
import 'delegating_password_encoder.dart';
import 'pbkdf2_password_encoder.dart';

/// {@template password_encoder_factories}
/// Factory utility that assembles the standard [DelegatingPasswordEncoder].
///
/// The returned encoder writes Argon2id hashes and can still verify BCrypt and
/// PBKDF2 hashes from existing stores, so applications can migrate algorithms
/// without a coordinated data rewrite.
///
/// - [argon2Id], [bcryptId], and [pbkdf2Id] are the supported hash prefixes.
/// - This utility has no state and is safe to call from any zone.
///
/// ### Example
/// ```dart
/// final PasswordEncoder encoder =
///     PasswordEncoderFactories.createDelegatingPasswordEncoder();
/// final hash = encoder.encode('correct horse battery staple');
/// ```
///
/// ### See also
/// - [DelegatingPasswordEncoder] — the encoder instance that is returned.
/// {@endtemplate}
abstract final class PasswordEncoderFactories {
  /// Id used for the recommended default, Argon2id.
  static const String argon2Id = 'argon2id';

  /// Id used for BCrypt hashes.
  static const String bcryptId = 'bcrypt';

  /// Id used for PBKDF2 hashes.
  static const String pbkdf2Id = 'pbkdf2';

  /// {@macro password_encoder_factories}
  const PasswordEncoderFactories._();

  /// Creates a delegating encoder with Argon2id as the default.
  ///
  /// ### Returns
  /// A [DelegatingPasswordEncoder] whose delegates cover Argon2id, BCrypt, and
  /// PBKDF2 hashes. Newly encoded passwords always use Argon2id.
  ///
  /// ### Example
  /// ```dart
  /// final encoder = PasswordEncoderFactories.createDelegatingPasswordEncoder();
  /// assert(encoder.matches('secret', encoder.encode('secret')));
  /// ```
  static DelegatingPasswordEncoder createDelegatingPasswordEncoder() => DelegatingPasswordEncoder(argon2Id, {
    argon2Id: Argon2idPasswordEncoder(),
    bcryptId: BCryptPasswordEncoder(),
    pbkdf2Id: Pbkdf2PasswordEncoder(),
  });
}