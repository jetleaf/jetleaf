// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & Jetleaf Contributors. All rights reserved.
//
// This source file is part of the Jetleaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the Jetleaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'dart:convert';
import 'dart:typed_data';

import 'package:jetleaf_lang/lang.dart';

/// {@template encoding_decoder}
/// A **unified abstraction for text encoding and decoding** operations,
/// providing a consistent interface for converting between raw bytes and
/// human-readable strings across multiple character encodings.
///
/// The [EncodingDecoder] interface defines a contract for encoding and decoding
/// text data in different formats such as UTF-8, ISO-8859-1, ASCII, and others.
/// It enables seamless integration of custom or platform-specific codecs within
/// Jetleaf’s I/O and HTTP subsystems, including file uploads, request parsing,
/// and response serialization.
///
/// ### Responsibilities
/// - Decode byte arrays into strings using a specified character encoding.
/// - Encode strings into byte arrays for transmission or storage.
/// - Report supported encodings and provide introspection capabilities.
/// - Validate encoding availability to ensure cross-platform compatibility.
///
/// ### Design Notes
/// - Implementations should use **lossless encoding** whenever possible to
///   preserve data integrity.
/// - The default encoding is `'utf-8'`, which is recommended for most use cases.
/// - Encoders and decoders must handle both text and binary-safe transformations.
/// - When unsupported encodings are requested, implementations should either
///   throw descriptive exceptions or fall back to UTF-8 gracefully.
/// - Commonly used within Jetleaf’s HTTP request/response, multipart, and
///   file I/O handling layers.
///
/// ### Example
/// ```dart
/// final decoder = DefaultEncodingDecoder();
///
/// // Decode UTF-8 bytes
/// final text = decoder.decode(Uint8List.fromList([72, 101, 108, 108, 111]));
/// print(text); // "Hello"
///
/// // Encode a string
/// final bytes = decoder.encode("Jetleaf");
/// print(bytes); // [74, 101, 116, 76, 101, 97, 102]
///
/// // Check for supported encodings
/// if (decoder.supportsEncoding("iso-8859-1")) {
///   print("ISO-8859-1 is supported!");
/// }
/// ```
///
/// ### Typical Implementations
/// - `DefaultEncodingDecoder` — Built-in UTF-8 and ISO-8859-1 support.
/// - `CustomEncodingDecoder` — Pluggable codec provider for extended charset support.
/// - `PlatformEncodingDecoder` — Uses native system libraries for charset operations.
///
/// ### See Also
/// - [dart:convert.Encoding] — Standard Dart encoding utilities.
/// - [InputStreamSource] — For working with encoded stream data.
/// - [HttpBody] — For decoding text-based HTTP payloads.
/// {@endtemplate}
abstract interface class EncodingDecoder {
  /// {@macro encoding_decoder}
  const EncodingDecoder();

  /// Decodes a byte array to a [String] using the specified [encoding].
  ///
  /// - **Parameters:**
  ///   - `bytes`: The byte array to decode.
  ///   - `encoding`: The character encoding to use (defaults to `'utf-8'`).
  ///
  /// - **Returns:**
  ///   A string representation of the decoded byte data.
  ///
  /// - **Throws:**
  ///   - `UnsupportedEncodingException` if the provided encoding is not supported.
  ///   - `FormatException` if the bytes cannot be decoded using the given encoding.
  String decode(Uint8List bytes, {String encodingString = 'utf-8', Encoding? encoding});

  /// Encodes a [String] into a [Uint8List] using the specified [encoding].
  ///
  /// - **Parameters:**
  ///   - `text`: The string to encode.
  ///   - `encoding`: The character encoding to use (defaults to `'utf-8'`).
  ///
  /// - **Returns:**
  ///   A [Uint8List] containing the encoded bytes.
  ///
  /// - **Throws:**
  ///   - `UnsupportedEncodingException` if the provided encoding is not supported.
  Uint8List encode(String text, {String encodingString = 'utf-8', Encoding? encoding});

  /// Returns `true` if the specified [encoding] is supported.
  ///
  /// This method can be used to validate encoding compatibility before
  /// performing encode or decode operations.
  ///
  /// Example:
  /// ```dart
  /// if (decoder.supportsEncoding("utf-16")) {
  ///   // Safe to use utf-16 encoding
  /// }
  /// ```
  bool supportsEncoding(String encoding);

  /// Returns the list of all supported encodings.
  ///
  /// This allows introspection of available character sets for debugging,
  /// dynamic configuration, or feature detection.
  ///
  /// Example:
  /// ```dart
  /// final supported = decoder.getSupportedEncodings();
  /// print(supported); // ["utf-8", "iso-8859-1"]
  /// ```
  List<String> getSupportedEncodings();
}

/// {@template basic_encoding_decoder}
/// A **lightweight, default implementation** of [EncodingDecoder] that provides
/// native text encoding and decoding for a predefined set of common character
/// encodings.
///
/// The [BasicEncodingDecoder] relies on Dart’s built-in [Encoding] APIs
/// (`dart:convert`) to handle standard encodings such as UTF-8, ASCII, and
/// Latin-1. It serves as the foundational decoder used by higher-level systems
/// such as [MultiEncodingDecoder].
///
/// ### Supported Encodings
/// - `utf-8` / `utf8` — Unicode Transformation Format (default)
/// - `ascii` — American Standard Code for Information Interchange
/// - `latin-1` / `latin1` / `iso-8859-1` — Western European character set
///
/// ### Design Notes
/// - Gracefully falls back to UTF-8 decoding when a decode operation fails.
/// - Returns best-effort conversions for unknown encodings by using raw
///   character codes.
/// - Designed for **performance and simplicity**, without external dependencies.
/// - Safe to use as a fallback or default decoder in most applications.
///
/// ### Example
/// ```dart
/// final decoder = BasicEncodingDecoder();
///
/// final text = decoder.decode(Uint8List.fromList([72, 101, 108, 108, 111]));
/// print(text); // "Hello"
///
/// final bytes = decoder.encode("Jetleaf", "ascii");
/// print(bytes); // [74, 101, 116, 76, 101, 97, 102]
/// ```
///
/// ### See Also
/// - [EncodingDecoder] — Abstract interface for decoders.
/// - [MultiEncodingDecoder] — Pluggable extension with custom handlers.
/// - [EncodingDecoder] — Low-level encoding abstraction.
/// {@endtemplate}
class BasicEncodingDecoder implements EncodingDecoder {
  /// A static registry of all **supported character encodings** mapped to their
  /// corresponding Dart [Encoding] implementations.
  ///
  /// This map provides fast lookup for common encodings such as:
  /// - `'utf-8'` and `'utf8'` → [Closeable.DEFAULT_ENCODING]
  /// - `'ascii'` → [ascii]
  /// - `'latin-1'`, `'latin1'`, `'iso-8859-1'` → [latin1]
  ///
  /// ### Design Notes
  /// - Encoding names are stored and matched in lowercase for case-insensitive lookup.
  /// - The registry is immutable at runtime.
  /// - Used internally by [decode] and [encode] to map human-readable names
  ///   to Dart’s [Encoding] classes.
  static final Map<String, Encoding> _encodings = {
    'utf-8': Closeable.DEFAULT_ENCODING,
    'utf8': Closeable.DEFAULT_ENCODING,
    'ascii': ascii,
    'latin-1': latin1,
    'latin1': latin1,
    'iso-8859-1': latin1,
  };

  /// Creates a new instance of [BasicEncodingDecoder].
  ///
  /// This decoder supports all standard encodings defined in [_encodings],
  /// providing a lightweight, dependency-free solution for general text
  /// encoding and decoding operations.
  ///
  /// Use this class as a **default or fallback** implementation when no custom
  /// decoder is required.
  /// 
  /// {@macro basic_encoding_decoder}
  const BasicEncodingDecoder();

  @override
  String decode(Uint8List bytes, {String encodingString = 'utf-8', Encoding? encoding}) {
    if (encoding != null) {
      return encoding.decode(bytes);
    }

    final normalizedEncoding = encodingString.toLowerCase();
    final dartEncoding = _encodings[normalizedEncoding];

    if (dartEncoding != null) {
      try {
        return dartEncoding.decode(bytes);
      } catch (e) {
        // Fallback to UTF-8 if decoding fails
        return Closeable.DEFAULT_ENCODING.decode(bytes, allowMalformed: true);
      }
    }

    // Fallback for unsupported encodings
    return String.fromCharCodes(bytes);
  }

  @override
  Uint8List encode(String text, {String encodingString = 'utf-8', Encoding? encoding}) {
    if (encoding != null) {
      return Uint8List.fromList(encoding.encode(text));
    }

    final normalizedEncoding = encodingString.toLowerCase();
    final dartEncoding = _encodings[normalizedEncoding];

    if (dartEncoding != null) {
      try {
        return Uint8List.fromList(dartEncoding.encode(text));
      } catch (e) {
        // Fallback to UTF-8 if encoding fails
        return Uint8List.fromList(Closeable.DEFAULT_ENCODING.encode(text));
      }
    }

    // Fallback for unsupported encodings
    return Uint8List.fromList(text.codeUnits);
  }

  @override
  bool supportsEncoding(String encoding) => _encodings.containsKey(encoding.toLowerCase());

  @override
  List<String> getSupportedEncodings() => _encodings.keys.toList();
}

/// {@template base64_encoding_handler}
/// A **Base64-specific implementation** of [EncodingDecoder] that provides
/// encoding and decoding functionality for binary and textual data using
/// the Base64 scheme.
///
/// Base64 encoding is widely used for safely representing binary data
/// (such as images, files, or encrypted tokens) in textual formats like
/// JSON, XML, or HTTP payloads. This handler leverages Dart’s built-in
/// [base64] utilities to ensure consistent and standards-compliant behavior.
///
/// ### Design Notes
/// - Encodes raw bytes into Base64 strings for safe textual transmission.
/// - Decodes Base64-encoded strings back into their original binary form.
/// - Fully compatible with RFC 4648 Base64 encoding rules.
/// - Safe for use in file uploads, web APIs, and token serialization.
///
/// ### Example
/// ```dart
/// final handler = Base64EncodingHandler();
///
/// final encoded = handler.decode(Uint8List.fromList([72, 101, 108, 108, 111]));
/// print(encoded); // "SGVsbG8="
///
/// final decoded = handler.encode("SGVsbG8=");
/// print(decoded); // [72, 101, 108, 108, 111]
/// ```
///
/// ### See Also
/// - [BasicEncodingDecoder] — Provides text encoding (UTF-8, ASCII, etc.).
/// - [MultiEncodingDecoder] — Combines multiple encoding handlers dynamically.
/// {@endtemplate}
class Base64EncodingDecoder implements EncodingDecoder {
  /// Creates a new instance of [Base64EncodingDecoder].
  ///
  /// This handler provides **Base64 encoding and decoding** functionality
  /// using Dart’s standard [base64] utilities. It can be registered as a
  /// plugin in a [MultiEncodingDecoder] to extend its decoding capabilities.
  /// 
  /// {@macro base64_encoding_handler}
  const Base64EncodingDecoder();

  @override
  String decode(Uint8List bytes, {String encodingString = 'utf-8', Encoding? encoding}) {
    return base64.encode(bytes);
  }

  @override
  Uint8List encode(String text, {String encodingString = 'utf-8', Encoding? encoding}) {
    return Uint8List.fromList(base64.decode(text));
  }

  @override
  List<String> getSupportedEncodings() => ["base64"];

  @override
  bool supportsEncoding(String encoding) => true;
}