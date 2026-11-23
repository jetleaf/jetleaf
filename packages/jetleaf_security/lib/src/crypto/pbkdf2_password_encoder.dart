import 'package:jetleaf_core/lang.dart' show IllegalArgumentException;
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';

import 'password_encoder.dart';

/// {@template pbkdf2_password_encoder}
/// [PasswordEncoder] implementation using PBKDF2 with HMAC-SHA256.
///
/// Produced and verified strings have the form:
/// `$pbkdf2-sha256$<iterations>$<salt_b64>$<hash_b64>`.
/// The iteration count and salt are stored alongside the hash, so each
/// password can keep the parameters it was created with.
///
/// - A fresh cryptographically random salt is generated for every [encode].
/// - [matches] caps the iteration count read from a stored hash with
///   [maxIterations] and compares results in constant time.
/// - The asynchronous variants run on another isolate via [Isolate.run].
///
/// ### Example
/// ```dart
/// final encoder = Pbkdf2PasswordEncoder(iterations: 310000);
/// final hash = await encoder.encodeAsync('correct horse');
/// assert(encoder.matches('correct horse', hash));
/// ```
///
/// ### See also
/// - [PasswordEncoder] — the contract being implemented.
/// - [constantTimeEquals] — the comparison used during verification.
/// {@endtemplate}
class Pbkdf2PasswordEncoder implements PasswordEncoder {
  /// Number of PBKDF2 iterations. Defaults to 310000, following current
  /// guidance for password hashing.
  final int iterations;

  /// Derived key length in bytes. Defaults to 32 (256 bits).
  final int hashLength;

  /// Salt length in bytes. Defaults to 16.
  final int saltLength;

  /// Upper bound accepted from a stored hash for iterations.
  final int maxIterations;

  final Random _random = Random.secure();

  /// {@macro pbkdf2_password_encoder}
  ///
  /// Throws [ArgumentError] when a length is below its minimum or when
  /// [iterations] exceeds [maxIterations].
  Pbkdf2PasswordEncoder({
    this.iterations = 310000,
    this.hashLength = 32,
    this.saltLength = 16,
    this.maxIterations = 10000000,
  }) {
    if (iterations < 1) {
      throw IllegalArgumentException('iterations: Must be at least 1 (got )');
    }
    if (hashLength < 16) {
      throw IllegalArgumentException('hashLength: Must be at least 16 (got )');
    }
    if (saltLength < 8) {
      throw IllegalArgumentException('saltLength: Must be at least 8 (got )');
    }
    if (iterations > maxIterations) {
      throw IllegalArgumentException('iterations: Exceeds maxIterations (got )');
    }
  }

  /// {@template pbkdf2_password_encoder_encode}
  /// Encodes a password into a PBKDF2 hash string.
  ///
  /// ### Parameters
  /// - [rawPassword]: the plaintext password to protect.
  ///
  /// ### Returns
  /// A string containing the iteration count, fresh salt, and derived hash.
  /// {@endtemplate}
  /// {@macro pbkdf2_password_encoder}
  @override
  String encode(String rawPassword) {
    final salt = Uint8List(saltLength);
    for (var i = 0; i < saltLength; i++) {
      salt[i] = _random.nextInt(256);
    }

    final hash = _derive(
      utf8.encode(rawPassword),
      salt,
      iterations: iterations,
      hashLength: hashLength,
    );

    return '\$pbkdf2-sha256\$$iterations\$${_encodeNoPad(salt)}\$${_encodeNoPad(hash)}';
  }

  /// {@template pbkdf2_password_encoder_matches}
  /// Verifies a plaintext password against a stored PBKDF2 hash.
  ///
  /// ### Parameters
  /// - [rawPassword]: the plaintext candidate.
  /// - [encodedPassword]: a previously stored hash string.
  ///
  /// ### Returns
  /// `false` for malformed input or an iteration count above [maxIterations];
  /// otherwise whether the candidate derives to the stored hash in constant
  /// time.
  /// {@endtemplate}
  /// {@macro pbkdf2_password_encoder}
  @override
  bool matches(String rawPassword, String encodedPassword) {
    final parts = encodedPassword.split('\$');
    if (parts.length != 5 || parts[0].isNotEmpty || parts[1] != 'pbkdf2-sha256') {
      return false;
    }
    final iter = int.tryParse(parts[2]);
    if (iter == null || iter < 1 || iter > maxIterations) {
      return false;
    }

    try {
      final salt = _decodeNoPad(parts[3]);
      final expected = _decodeNoPad(parts[4]);
      final actual = _derive(
        utf8.encode(rawPassword),
        salt,
        iterations: iter,
        hashLength: expected.length,
      );
      return constantTimeEquals(actual, expected);
    } catch (_) {
      return false;
    }
  }

  /// {@template pbkdf2_password_encoder_upgrade_encoding}
  /// Reports whether a stored hash uses fewer iterations than this encoder.
  ///
  /// ### Parameters
  /// - [encodedPassword]: the stored hash string.
  ///
  /// ### Returns
  /// `true` for malformed hashes and hashes with a lower iteration count.
  /// {@endtemplate}
  /// {@macro pbkdf2_password_encoder}
  @override
  bool upgradeEncoding(String encodedPassword) {
    final parts = encodedPassword.split('\$');
    if (parts.length != 5 || parts[1] != 'pbkdf2-sha256') {
      return true;
    }
    final iter = int.tryParse(parts[2]);
    return iter == null || iter < iterations;
  }

  /// {@template pbkdf2_password_encoder_encode_async}
  /// Encodes a password on a background isolate.
  ///
  /// ### Parameters
  /// - [rawPassword]: the plaintext password to protect.
  ///
  /// ### Returns
  /// The same hash format produced by [encode].
  /// {@endtemplate}
  /// {@macro pbkdf2_password_encoder}
  @override
  Future<String> encodeAsync(String rawPassword) => Isolate.run(() {
    final encoder = Pbkdf2PasswordEncoder(
      iterations: iterations,
      hashLength: hashLength,
      saltLength: saltLength,
    );
    return encoder.encode(rawPassword);
  });

  /// {@template pbkdf2_password_encoder_matches_async}
  /// Verifies a password on a background isolate.
  ///
  /// ### Parameters
  /// - [rawPassword]: the plaintext candidate.
  /// - [encodedPassword]: a previously stored hash string.
  ///
  /// ### Returns
  /// Whether the candidate matches, computed by [matches] on the isolate.
  /// {@endtemplate}
  /// {@macro pbkdf2_password_encoder}
  @override
  Future<bool> matchesAsync(String rawPassword, String encodedPassword) => Isolate.run(() {
    final encoder = Pbkdf2PasswordEncoder(maxIterations: maxIterations);
    return encoder.matches(rawPassword, encodedPassword);
  });

  /// {@template pbkdf2_password_encoder_derive}
  /// Derives key bytes with PBKDF2-HMAC-SHA256.
  ///
  /// ### Parameters
  /// - [passwordBytes]: the UTF-8 encoded password.
  /// - [salt]: the salt to mix into the derivation.
  /// - [iterations]: the number of PBKDF2 rounds.
  /// - [hashLength]: desired output length in bytes.
  ///
  /// ### Returns
  /// The derived key bytes.
  /// {@endtemplate}
  /// {@macro pbkdf2_password_encoder}
  Uint8List _derive(
    Uint8List passwordBytes,
    Uint8List salt, {
    required int iterations,
    required int hashLength,
  }) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    derivator.init(Pbkdf2Parameters(salt, iterations, hashLength));
    return derivator.process(passwordBytes);
  }

  /// {@template pbkdf2_password_encoder_encode_no_pad}
  /// Encodes bytes as unpadded base64 for the hash string format.
  ///
  /// ### Parameters
  /// - [bytes]: the bytes to encode.
  ///
  /// ### Returns
  /// A base64 string with all `=` padding characters removed.
  /// {@endtemplate}
  /// {@macro pbkdf2_password_encoder}
  static String _encodeNoPad(Uint8List bytes) => base64Encode(bytes).replaceAll('=', '');

  /// {@template pbkdf2_password_encoder_decode_no_pad}
  /// Decodes an unpadded base64 segment from a hash string.
  ///
  /// ### Parameters
  /// - [input]: the base64 text without padding.
  ///
  /// ### Returns
  /// The decoded bytes.
  /// {@endtemplate}
  /// {@macro pbkdf2_password_encoder}
  static Uint8List _decodeNoPad(String input) {
    final mod = input.length % 4;
    final padded = mod == 0 ? input : input + ('=' * (4 - mod));
    return base64Decode(padded);
  }
}
