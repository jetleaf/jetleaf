import 'package:jetleaf_core/utils.dart' show ParserException;
import 'package:jetleaf_core/lang.dart' show IllegalArgumentException;
import 'password_encoder.dart';

/// {@template delegating_password_encoder}
/// Encodes with a default [PasswordEncoder] and prefixes stored hashes with an
/// `{id}` so verification can select the algorithm that created them.
///
/// The prefix makes stored hashes self-describing, which allows algorithms and
/// cost parameters to change over time without re-encoding every password at
/// once. New hashes always use [defaultId]; verification dispatches to the
/// encoder registered for the id found in the stored hash.
///
/// - The encoder map is copied into an unmodifiable view at construction.
/// - [defaultId] must be present in [encoders].
/// - Unprefixed hashes are accepted by default for legacy data.
///
/// ### Example
/// ```dart
/// final encoder = DelegatingPasswordEncoder('argon2id', {
///   'argon2id': Argon2idPasswordEncoder(),
///   'bcrypt': BCryptPasswordEncoder(),
/// });
/// final hash = encoder.encode('secret');
/// print(hash.startsWith('{argon2id}')); // true
/// ```
///
/// ### See also
/// - [PasswordEncoder] — the interface implemented by each delegate.
/// - [constantTimeEquals] — the comparison primitive used by delegates.
/// {@endtemplate}
final class DelegatingPasswordEncoder implements PasswordEncoder {
  /// Id used when encoding new passwords.
  final String defaultId;

  /// Available encoders keyed by id.
  final Map<String, PasswordEncoder> encoders;

  /// Whether a stored hash without an `{id}` prefix is accepted and verified
  /// with the default encoder. Defaults to `true`.
  final bool allowUnprefixedHashes;

  /// {@macro delegating_password_encoder}
  ///
  /// The [encoders] map must contain [defaultId]; otherwise construction fails.
  DelegatingPasswordEncoder(
    this.defaultId,
    Map<String, PasswordEncoder> encoders, {
    this.allowUnprefixedHashes = true,
  }) : encoders = Map.unmodifiable(encoders) {
    if (!this.encoders.containsKey(defaultId)) {
      throw IllegalArgumentException('defaultId: The default encoder id must be present in encoders (got $defaultId)');
    }
  }

  @override
  String encode(String rawPassword) =>
      '{$defaultId}${encoders[defaultId]!.encode(rawPassword)}';

  @override
  bool matches(String rawPassword, String encodedPassword) {
    final id = _extractId(encodedPassword);
    if (id == null) {
      if (!allowUnprefixedHashes) {
        throw ParserException('Password hash has no {id} prefix');
      }
      return encoders[defaultId]!.matches(rawPassword, encodedPassword);
    }

    final encoder = encoders[id];
    if (encoder == null) {
      throw IllegalArgumentException('There is no PasswordEncoder mapped for the id "$id"');
    }
    return encoder.matches(rawPassword, _stripPrefix(encodedPassword, id));
  }

  @override
  Future<String> encodeAsync(String rawPassword) async => '{$defaultId}${await encoders[defaultId]!.encodeAsync(rawPassword)}';

  @override
  Future<bool> matchesAsync(String rawPassword, String encodedPassword) async {
    final id = _extractId(encodedPassword);
    if (id == null) {
      if (!allowUnprefixedHashes) {
        throw ParserException('Password hash has no {id} prefix');
      }
      return encoders[defaultId]!.matchesAsync(rawPassword, encodedPassword);
    }

    final encoder = encoders[id];
    if (encoder == null) {
      throw IllegalArgumentException('There is no PasswordEncoder mapped for the id "$id"');
    }
    return encoder.matchesAsync(rawPassword, _stripPrefix(encodedPassword, id));
  }

  @override
  bool upgradeEncoding(String encodedPassword) {
    final id = _extractId(encodedPassword);
    if (id == null) return true;
    final encoder = encoders[id];
    if (encoder == null) {
      throw IllegalArgumentException('There is no PasswordEncoder mapped for the id "$id"');
    }
    return id != defaultId || encoder.upgradeEncoding(_stripPrefix(encodedPassword, id));
  }

  /// {@template delegating_password_encoder_extract_id}
  /// Reads the `{id}` prefix from a stored hash.
  ///
  /// ### Parameters
  /// - [encoded]: the stored hash.
  ///
  /// ### Returns
  /// The id between the braces, or `null` when the hash is unprefixed or the
  /// closing brace is missing.
  /// {@endtemplate}
  /// {@macro delegating_password_encoder}
  static String? _extractId(String encoded) {
    if (!encoded.startsWith('{')) return null;
    final end = encoded.indexOf('}');
    if (end < 0) return null;
    return encoded.substring(1, end);
  }

  /// {@template delegating_password_encoder_strip_prefix}
  /// Removes the `{id}` prefix so the remaining text can be passed to a
  /// specific delegate.
  ///
  /// ### Parameters
  /// - [encoded]: the stored hash.
  /// - [id]: the prefix id previously extracted from [encoded].
  ///
  /// ### Returns
  /// The hash text without its prefix.
  /// {@endtemplate}
  /// {@macro delegating_password_encoder}
  static String _stripPrefix(String encoded, String id) => encoded.substring(id.length + 2);
}
