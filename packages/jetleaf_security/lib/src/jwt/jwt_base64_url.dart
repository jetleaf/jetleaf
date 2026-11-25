import 'package:jetleaf_core/lang.dart' show IllegalArgumentException;
import 'dart:convert';
import 'dart:typed_data';

/// {@template jwt_base64_url}
/// Unpadded base64url helpers for compact JWS serialization and JWK members.
///
/// Compact JWT segments and the integer fields of a JWK use the base64url
/// alphabet with all padding removed. This utility keeps that encoding in one
/// place and is implemented entirely with the Dart SDK.
///
/// - **Encoding:** [encode] strips `=` padding; [decode] restores it before
///   decoding, so both padded and unpadded input are accepted.
/// - **Integers:** [encodeInteger] emits the minimal unsigned big-endian
///   representation; [decodeInteger] reads it back without sign handling.
///
/// ### Example
/// ```dart
/// final segment = JwtBase64Url.encode(utf8.encode('{"alg":"HS256"}'));
/// print(JwtBase64Url.decode(segment)); // the original UTF-8 bytes
/// ```
/// {@endtemplate}
abstract final class JwtBase64Url {
  /// {@macro jwt_base64_url}
  const JwtBase64Url._();

  /// {@template jwt_base64_url.encode}
  /// Encodes [bytes] as unpadded base64url.
  ///
  /// ### Parameters
  /// - [bytes] — raw bytes to encode.
  ///
  /// ### Returns
  /// A base64url string with all `=` padding removed.
  /// {@endtemplate}
  static String encode(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  /// {@template jwt_base64_url.decode}
  /// Decodes padded or unpadded base64url into bytes.
  ///
  /// Malformed input is rejected by the SDK decoder with a [FormatException].
  ///
  /// ### Parameters
  /// - [input] — a base64url string; padding is optional.
  ///
  /// ### Returns
  /// The decoded bytes as a [Uint8List].
  /// {@endtemplate}
  static Uint8List decode(String input) {
    final padded = input.padRight((input.length + 3) ~/ 4 * 4, '=');
    return base64Url.decode(padded);
  }

  /// {@template jwt_base64_url.encode_integer}
  /// Encodes a non-negative big-endian integer as unpadded base64url.
  ///
  /// Leading zero bytes are omitted except for the value zero, which is
  /// encoded as a single `0x00` byte as required by JWK integer members.
  ///
  /// ### Parameters
  /// - [value] — an unsigned integer; negative values are invalid.
  ///
  /// ### Returns
  /// The JWK-compatible base64url representation of [value].
  ///
  /// ### Throws
  /// [ArgumentError] when [value] is negative.
  /// {@endtemplate}
  static String encodeInteger(BigInt value) {
    if (value.sign < 0) throw IllegalArgumentException('value: Must be unsigned (got $value)');
    if (value == BigInt.zero) return encode([0]);
    var hex = value.toRadixString(16);
    if (hex.length.isOdd) hex = '0$hex';
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return encode(bytes);
  }

  /// {@template jwt_base64_url.decode_integer}
  /// Decodes a JWK base64url integer member into a [BigInt].
  ///
  /// ### Parameters
  /// - [input] — unpadded or padded base64url bytes representing an unsigned
  ///   big-endian integer.
  ///
  /// ### Returns
  /// The reconstructed non-negative integer.
  /// {@endtemplate}
  static BigInt decodeInteger(String input) => _bytesToInteger(decode(input));

  /// Folds big-endian bytes into an unsigned [BigInt], one byte at a time.
  static BigInt _bytesToInteger(List<int> bytes) {
    var value = BigInt.zero;
    for (final byte in bytes) {
      value = (value << 8) | BigInt.from(byte);
    }
    return value;
  }
}