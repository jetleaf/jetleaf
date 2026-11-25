/// {@template password_encoder}
/// Service interface for encoding passwords and verifying raw passwords against
/// stored hashes.
///
/// Implementations perform a one-way transformation of a raw password and keep
/// the parameters needed to verify it inside the produced hash string. The
/// asynchronous variants exist so expensive key-derivation functions can run
/// on another isolate instead of blocking the request loop; implementations
/// that support this must override them, otherwise the default forwards to the
/// synchronous method.
///
/// ### Contract
/// - [encode] returns a self-describing hash; callers must store it verbatim.
/// - [matches] performs a constant-time comparison and must not throw for a
///   malformed stored hash — it should return `false`.
/// - [upgradeEncoding] reports whether a stored hash uses weaker parameters
///   than the encoder currently applies.
///
/// ### Implementations
/// - Argon2id, BCrypt, and PBKDF2 encoders provide concrete algorithms.
/// - A delegating encoder selects one of several algorithms by id.
///
/// ### Example
/// ```dart
/// final hash = await encoder.encodeAsync(rawPassword);
/// if (await encoder.matchesAsync(rawPassword, hash)) {
///   // credentials accepted
/// }
/// ```
///
/// ### See also
/// - [constantTimeEquals] — the shared comparison primitive.
/// {@endtemplate}
abstract interface class PasswordEncoder {
  /// Encodes [rawPassword] with a one-way cryptographic hash.
  ///
  /// ### Parameters
  /// - [rawPassword]: the plaintext password supplied by the caller.
  ///
  /// ### Returns
  /// A string containing the algorithm parameters, salt, and derived hash.
  String encode(String rawPassword);

  /// Verifies that [rawPassword] matches [encodedPassword].
  ///
  /// Implementations must compare in constant time and treat malformed stored
  /// hashes as a mismatch.
  ///
  /// ### Parameters
  /// - [rawPassword]: the plaintext candidate.
  /// - [encodedPassword]: a hash previously produced by [encode].
  ///
  /// ### Returns
  /// `true` only when the candidate derives to the stored hash.
  bool matches(String rawPassword, String encodedPassword);

  /// Asynchronous counterpart of [encode].
  ///
  /// ### Parameters
  /// - [rawPassword]: the plaintext password supplied by the caller.
  ///
  /// ### Returns
  /// The encoded hash. The default implementation forwards to [encode].
  Future<String> encodeAsync(String rawPassword) async => encode(rawPassword);

  /// Asynchronous counterpart of [matches].
  ///
  /// ### Parameters
  /// - [rawPassword]: the plaintext candidate.
  /// - [encodedPassword]: a hash previously produced by [encode].
  ///
  /// ### Returns
  /// Whether the candidate matches. The default forwards to [matches].
  Future<bool> matchesAsync(String rawPassword, String encodedPassword) async => matches(rawPassword, encodedPassword);

  /// Reports whether a stored hash should be re-encoded with stronger
  /// parameters.
  ///
  /// ### Parameters
  /// - [encodedPassword]: the stored hash to inspect.
  ///
  /// ### Returns
  /// `true` when a stronger cost factor or algorithm is available. The default
  /// implementation returns `false`.
  bool upgradeEncoding(String encodedPassword) => false;
}

/// {@template constant_time_equals}
/// Performs a constant-time equality check on two byte lists.
///
/// The comparison walks every byte even after a mismatch, so the time taken
/// does not reveal the position of the first differing byte. This protects
/// password verification against timing side-channel attacks.
///
/// ### Parameters
/// - [a]: the first byte sequence.
/// - [b]: the second byte sequence.
///
/// ### Returns
/// `true` when the lists have equal length and identical contents.
///
/// ### Example
/// ```dart
/// final ok = constantTimeEquals(utf8.encode(candidate), utf8.encode(stored));
/// ```
/// {@endtemplate}
bool constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) {
    return false;
  }
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}