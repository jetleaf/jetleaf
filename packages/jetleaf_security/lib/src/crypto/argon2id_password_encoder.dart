import 'package:jetleaf_core/lang.dart' show IllegalArgumentException;
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/argon2.dart';

import 'password_encoder.dart';

/// {@template argon2id_password_encoder}
/// [PasswordEncoder] implementation that derives hashes with Argon2id.
///
/// Produced and verified hashes use the PHC string format:
/// `$argon2id$v=19$m=<memory>,t=<iterations>,p=<parallelism>$<salt>$<hash>`.
/// All parameters required for verification are embedded in the string, so no
/// separate database columns are needed.
///
/// - A fresh cryptographically random salt is generated for every [encode].
/// - Stored hashes are bounds-checked before any derivation work is performed,
///   preventing a hostile hash from requesting excessive memory or time.
/// - Verification uses a constant-time comparison through [constantTimeEquals].
/// - The asynchronous variants run on another isolate via [Isolate.run].
///
/// ### Example
/// ```dart
/// final encoder = Argon2idPasswordEncoder(memoryKiB: 65536);
/// final hash = await encoder.encodeAsync('correct horse');
/// assert(encoder.matches('correct horse', hash));
/// ```
///
/// ### See also
/// - [PasswordEncoder] — the contract being implemented.
/// - [constantTimeEquals] — the comparison used during verification.
/// {@endtemplate}
class Argon2idPasswordEncoder implements PasswordEncoder {
  /// Salt length in bytes.
  final int saltLength;

  /// Derived hash length in bytes.
  final int hashLength;

  /// Degree of parallelism (lanes).
  final int parallelism;

  /// Memory cost in KiB. Defaults to 65536 KiB (64 MiB).
  final int memoryKiB;

  /// Number of iterations (time cost).
  final int iterations;

  /// Upper bound accepted from a stored hash for memory cost (KiB).
  final int maxMemoryKiB;

  /// Upper bound accepted from a stored hash for iterations.
  final int maxIterations;

  /// Upper bound accepted from a stored hash for parallelism.
  final int maxParallelism;

  final Random _random = Random.secure();

  /// {@macro argon2id_password_encoder}
  ///
  /// Throws [ArgumentError] when a cost parameter is below its minimum or when
  /// configured costs exceed the accepted maxima.
  Argon2idPasswordEncoder({
    this.saltLength = 16,
    this.hashLength = 32,
    this.parallelism = 1,
    this.memoryKiB = 65536,
    this.iterations = 3,
    this.maxMemoryKiB = 1048576,
    this.maxIterations = 10,
    this.maxParallelism = 16,
  }) {
    if (saltLength < 8) {
      throw IllegalArgumentException('saltLength: Must be at least 8 bytes (got )');
    }
    if (hashLength < 4) {
      throw IllegalArgumentException('hashLength: Must be at least 4 bytes (got )');
    }
    if (parallelism < 1) {
      throw IllegalArgumentException('parallelism: Must be at least 1 (got )');
    }
    if (memoryKiB < 8 * parallelism) {
      throw IllegalArgumentException('memoryKiB: Must be at least 8 * parallelism KiB (got )');
    }
    if (iterations < 1) {
      throw IllegalArgumentException('iterations: Must be at least 1 (got )');
    }
    if (memoryKiB > maxMemoryKiB || iterations > maxIterations || parallelism > maxParallelism) {
      throw IllegalArgumentException('Configured Argon2id parameters exceed the accepted bounds');
    }
  }

  /// {@template argon2id_password_encoder_encode}
  /// Encodes a password into a PHC-formatted Argon2id hash.
  ///
  /// ### Parameters
  /// - [rawPassword]: the plaintext password to protect.
  ///
  /// ### Returns
  /// A string containing the version, cost parameters, fresh salt, and hash.
  /// {@endtemplate}
  /// {@macro argon2id_password_encoder}
  @override
  String encode(String rawPassword) {
    final salt = Uint8List(saltLength);
    for (var i = 0; i < saltLength; i++) {
      salt[i] = _random.nextInt(256);
    }

    final hash = _derive(
      utf8.encode(rawPassword),
      salt,
      hashLength: hashLength,
      iterations: iterations,
      memoryKiB: memoryKiB,
      parallelism: parallelism,
    );

    final saltB64 = _encodeNoPad(salt);
    final hashB64 = _encodeNoPad(hash);
    return '\$argon2id\$v=19\$m=$memoryKiB,t=$iterations,p=$parallelism\$$saltB64\$$hashB64';
  }

  /// {@template argon2id_password_encoder_matches}
  /// Verifies a plaintext password against a stored PHC hash.
  ///
  /// Malformed hashes and hashes whose parameters exceed the configured bounds
  /// are rejected before derivation, and return `false`.
  ///
  /// ### Parameters
  /// - [rawPassword]: the plaintext candidate.
  /// - [encodedPassword]: a previously stored PHC hash.
  ///
  /// ### Returns
  /// `true` only when the derived bytes match the stored hash in constant time.
  /// {@endtemplate}
  /// {@macro argon2id_password_encoder}
  @override
  bool matches(String rawPassword, String encodedPassword) {
    final parsed = _parsePhc(encodedPassword);
    if (parsed == null || !_withinBounds(parsed)) {
      return false;
    }

    final derived = _derive(
      utf8.encode(rawPassword),
      parsed.salt,
      hashLength: parsed.hash.length,
      iterations: parsed.iterations,
      memoryKiB: parsed.memoryKiB,
      parallelism: parsed.parallelism,
      version: parsed.version,
    );

    return constantTimeEquals(derived, parsed.hash);
  }

  /// {@template argon2id_password_encoder_upgrade_encoding}
  /// Reports whether a stored hash uses weaker parameters than this encoder.
  ///
  /// ### Parameters
  /// - [encodedPassword]: the stored PHC hash.
  ///
  /// ### Returns
  /// `true` for unparseable hashes or hashes with lower memory, iteration,
  /// parallelism, or hash-length settings than the configured defaults.
  /// {@endtemplate}
  /// {@macro argon2id_password_encoder}
  @override
  bool upgradeEncoding(String encodedPassword) {
    final parsed = _parsePhc(encodedPassword);
    if (parsed == null) {
      return true;
    }
    return parsed.memoryKiB < memoryKiB ||
        parsed.iterations < iterations ||
        parsed.parallelism < parallelism ||
        parsed.hash.length < hashLength;
  }

  /// {@template argon2id_password_encoder_within_bounds}
  /// Rejects hostile stored hashes before any derivation work is performed.
  ///
  /// ### Parameters
  /// - [parsed]: the decoded fields of a stored PHC hash.
  ///
  /// ### Returns
  /// `true` when the version and all cost and length fields are acceptable.
  /// {@endtemplate}
  /// {@macro argon2id_password_encoder}
  bool _withinBounds(_ParsedArgon2 parsed) =>
      parsed.version == Argon2Parameters.ARGON2_VERSION_13 &&
      parsed.memoryKiB >= 8 * parsed.parallelism &&
      parsed.memoryKiB <= maxMemoryKiB &&
      parsed.iterations >= 1 &&
      parsed.iterations <= maxIterations &&
      parsed.parallelism >= 1 &&
      parsed.parallelism <= maxParallelism &&
      parsed.hash.length >= hashLength &&
      parsed.hash.length <= 1024 &&
      parsed.salt.length >= 8 &&
      parsed.salt.length <= 1024;

  /// {@template argon2id_password_encoder_encode_async}
  /// Encodes a password on a background isolate.
  ///
  /// ### Parameters
  /// - [rawPassword]: the plaintext password to protect.
  ///
  /// ### Returns
  /// The same PHC string format produced by [encode].
  /// {@endtemplate}
  /// {@macro argon2id_password_encoder}
  @override
  Future<String> encodeAsync(String rawPassword) => Isolate.run(() {
    final encoder = Argon2idPasswordEncoder(
      saltLength: saltLength,
      hashLength: hashLength,
      parallelism: parallelism,
      memoryKiB: memoryKiB,
      iterations: iterations,
    );
    return encoder.encode(rawPassword);
  });

  /// {@template argon2id_password_encoder_matches_async}
  /// Verifies a password on a background isolate.
  ///
  /// ### Parameters
  /// - [rawPassword]: the plaintext candidate.
  /// - [encodedPassword]: a previously stored PHC hash.
  ///
  /// ### Returns
  /// Whether the candidate matches, computed by [matches] on the isolate.
  /// {@endtemplate}
  /// {@macro argon2id_password_encoder}
  @override
  Future<bool> matchesAsync(String rawPassword, String encodedPassword) => Isolate.run(() {
    final encoder = Argon2idPasswordEncoder(
      maxMemoryKiB: maxMemoryKiB,
      maxIterations: maxIterations,
      maxParallelism: maxParallelism,
    );
    return encoder.matches(rawPassword, encodedPassword);
  });

  /// {@template argon2id_password_encoder_derive}
  /// Runs the Argon2id key derivation for the supplied parameters.
  ///
  /// ### Parameters
  /// - [passwordBytes]: the UTF-8 encoded password.
  /// - [salt]: the salt to mix into the derivation.
  /// - [hashLength]: desired output length in bytes.
  /// - [iterations]: time cost.
  /// - [memoryKiB]: memory cost in KiB.
  /// - [parallelism]: number of lanes.
  /// - [version]: the Argon2 version to use.
  ///
  /// ### Returns
  /// The derived key bytes.
  /// {@endtemplate}
  /// {@macro argon2id_password_encoder}
  Uint8List _derive(
    Uint8List passwordBytes,
    Uint8List salt, {
    required int hashLength,
    required int iterations,
    required int memoryKiB,
    required int parallelism,
    int version = Argon2Parameters.ARGON2_VERSION_13,
  }) {
    final params = Argon2Parameters(
      Argon2Parameters.ARGON2_id,
      salt,
      desiredKeyLength: hashLength,
      iterations: iterations,
      memory: memoryKiB,
      lanes: parallelism,
      version: version,
    );
    final generator = Argon2BytesGenerator()..init(params);
    return generator.process(passwordBytes);
  }

  /// {@template argon2id_password_encoder_encode_no_pad}
  /// Encodes bytes as unpadded base64 for the PHC string format.
  ///
  /// ### Parameters
  /// - [bytes]: the bytes to encode.
  ///
  /// ### Returns
  /// A base64 string with all `=` padding characters removed.
  /// {@endtemplate}
  /// {@macro argon2id_password_encoder}
  static String _encodeNoPad(Uint8List bytes) => base64Encode(bytes).replaceAll('=', '');

  /// {@template argon2id_password_encoder_decode_no_pad}
  /// Decodes an unpadded base64 segment from a PHC string.
  ///
  /// ### Parameters
  /// - [input]: the base64 text without padding.
  ///
  /// ### Returns
  /// The decoded bytes.
  /// {@endtemplate}
  /// {@macro argon2id_password_encoder}
  static Uint8List _decodeNoPad(String input) {
    final mod = input.length % 4;
    final padded = mod == 0 ? input : input + ('=' * (4 - mod));
    return base64Decode(padded);
  }

  /// {@template argon2id_password_encoder_parse_phc}
  /// Parses a PHC-formatted Argon2id hash into its component fields.
  ///
  /// ### Parameters
  /// - [encoded]: the stored hash string.
  ///
  /// ### Returns
  /// A [_ParsedArgon2] with the version, cost parameters, salt, and hash, or
  /// `null` when the format is invalid or the base64 segments cannot decode.
  /// {@endtemplate}
  /// {@macro argon2id_password_encoder}
  static _ParsedArgon2? _parsePhc(String encoded) {
    // Format: $argon2id$v=19$m=65536,t=3,p=1$salt$hash
    final parts = encoded.split('\$');
    if (parts.length != 6 || parts[0].isNotEmpty || parts[1] != 'argon2id') {
      return null;
    }
    if (!parts[2].startsWith('v=')) {
      return null;
    }
    final version = int.tryParse(parts[2].substring(2));
    if (version == null) {
      return null;
    }

    int? memory;
    int? iterations;
    int? parallelism;
    for (final param in parts[3].split(',')) {
      final kv = param.split('=');
      if (kv.length != 2) return null;
      final val = int.tryParse(kv[1]);
      if (val == null) return null;
      switch (kv[0]) {
        case 'm':
          memory = val;
        case 't':
          iterations = val;
        case 'p':
          parallelism = val;
        default:
          return null;
      }
    }
    if (memory == null || iterations == null || parallelism == null) {
      return null;
    }

    try {
      final salt = _decodeNoPad(parts[4]);
      final hash = _decodeNoPad(parts[5]);
      return _ParsedArgon2(
        version: version,
        memoryKiB: memory,
        iterations: iterations,
        parallelism: parallelism,
        salt: salt,
        hash: hash,
      );
    } catch (_) {
      return null;
    }
  }
}

/// {@template parsed_argon2}
/// Decoded fields of a stored Argon2id PHC hash.
///
/// Instances are created only when a stored hash string parses successfully,
/// and are used for bounds checking and derivation.
/// {@endtemplate}
class _ParsedArgon2 {
  /// Argon2 version encoded in the hash.
  final int version;

  /// Memory cost in KiB encoded in the hash.
  final int memoryKiB;

  /// Time cost encoded in the hash.
  final int iterations;

  /// Lane count encoded in the hash.
  final int parallelism;

  /// Salt bytes decoded from the hash.
  final Uint8List salt;

  /// Derived hash bytes decoded from the hash.
  final Uint8List hash;

  /// {@macro parsed_argon2}
  _ParsedArgon2({
    required this.version,
    required this.memoryKiB,
    required this.iterations,
    required this.parallelism,
    required this.salt,
    required this.hash,
  });
}
