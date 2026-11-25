/// 🔐 **Jetleaf Security Cryptography Subsystem**
///
/// This library contains the password-hashing contracts, concrete key
/// derivation implementations, and an id-prefixed delegating encoder that
/// allows algorithms to evolve without invalidating stored hashes.
///
/// - **Contract:** synchronous and isolate-backed hashing and verification.
/// - **Algorithms:** Argon2id, BCrypt, and PBKDF2-HMAC-SHA256 encoders.
/// - **Migration:** self-describing `{id}` prefixes and upgrade detection.
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### 📜 Contracts & Utilities
/// - [PasswordEncoder] — the interface implemented by every encoder.
/// - [constantTimeEquals] — timing-safe comparison used during verification.
///
/// ### 🧮 Concrete Algorithms
/// - [Argon2idPasswordEncoder] — memory-hard Argon2id hashing with bounded parameters.
/// - [BCryptPasswordEncoder] — BCrypt hashing with a configurable cost factor.
/// - [Pbkdf2PasswordEncoder] — PBKDF2-HMAC-SHA256 hashing with bounded iterations.
///
/// ### 🔄 Migration Support
/// - [DelegatingPasswordEncoder] — routes each stored hash to its matching encoder by id.
/// - [PasswordEncoderFactories] — builds a ready-made delegating encoder with Argon2id as the default.
///
/// ---
///
/// ## 🎯 Usage Example
///
/// ```dart
/// import 'package:jetleaf_security/crypto.dart';
///
/// Future<void> main() async {
///   final PasswordEncoder encoder =
///       PasswordEncoderFactories.createDelegatingPasswordEncoder();
///
///   final hash = await encoder.encodeAsync('correct horse battery staple');
///   print(await encoder.matchesAsync('correct horse battery staple', hash)); // true
///
///   if (encoder.upgradeEncoding(hash)) {
///     final upgraded = await encoder.encodeAsync('correct horse battery staple');
///     // Persist the new hash, replacing the old one.
///   }
/// }
/// ```
library;

export 'src/crypto/argon2id_password_encoder.dart';
export 'src/crypto/bcrypt_password_encoder.dart';
export 'src/crypto/delegating_password_encoder.dart';
export 'src/crypto/password_encoder.dart';
export 'src/crypto/password_encoder_factories.dart';
export 'src/crypto/pbkdf2_password_encoder.dart';