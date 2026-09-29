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

import '../exceptions.dart';

/// {@template json_validator}
/// Utility class for validating JSON structures and content.
///
/// The [JsonValidator] provides comprehensive validation capabilities to ensure
/// JSON data is well-formed and structurally sound. It can validate:
/// - JSON strings (syntax and structure)
/// - JSON maps (Dart object representations)
/// - Nested structures and arrays
/// - Distinguishes between actual JSON and HTML/text strings
///
/// ### Core Features
/// - Validates JSON syntax and structure
/// - Detects malformed JSON vs HTML/text strings
/// - Provides detailed error messages
/// - Handles null and empty inputs gracefully
/// - Supports validation of maps and complex objects
///
/// ### Usage Examples
///
/// **Validate a JSON String**
/// ```dart
/// final validator = JsonValidator();
///
/// // Valid JSON
/// validator.validateJsonString('{"name":"Alice","age":30}');
/// print('Valid JSON');
///
/// // Invalid JSON
/// try {
///   validator.validateJsonString('{"name":"Alice""age":30}'); // Missing comma
/// } on MalformedJsonException catch (e) {
///   print('Error: ${e.message}');
/// }
///
/// // HTML String (not JSON)
/// try {
///   validator.validateJsonString('<html><body>Hello</body></html>');
/// } on MalformedJsonException catch (e) {
///   print('Not JSON: ${e.message}');
/// }
/// ```
///
/// **Validate a JSON Map**
/// ```dart
/// final validator = JsonValidator();
///
/// final user = {'name': 'Bob', 'age': 25};
/// validator.validateJsonMap(user);
/// print('Valid JSON-compatible map');
/// ```
///
/// **Validate Nested Structures**
/// ```dart
/// final validator = JsonValidator();
///
/// final data = {
///   'users': [
///     {'name': 'Alice', 'age': 30},
///     {'name': 'Bob', 'age': 25},
///   ],
///   'count': 2,
/// };
///
/// validator.validateJsonMap(data);
/// print('Complex structure is valid');
/// ```
///
/// ### Design Notes
/// - Automatically distinguishes between JSON objects/arrays and HTML/text strings
/// - Does not perform semantic validation (schema checking)
/// - Thread-safe; can be used across isolates
/// - Lightweight and efficient for high-frequency validation
///
/// ### See also
/// - [MalformedJsonException]
/// - [JsonParser]
/// - [ObjectMapper]
/// {@endtemplate}
final class JsonValidator {
  /// Creates a new [JsonValidator] instance.
  ///
  /// {@macro json_validator}
  const JsonValidator._();

  /// Validates that a string is valid JSON.
  ///
  /// Throws [MalformedJsonException] if:
  /// - The string is malformed JSON (syntax errors)
  /// - The string is HTML markup instead of JSON
  /// - The string is plain text or other non-JSON formats
  /// - The string is null or empty
  ///
  /// ### Example
  /// ```dart
  /// final validator = JsonValidator();
  /// validator.validateJsonString('{"key":"value"}'); // OK
  /// validator.validateJsonString('<html></html>');   // Throws
  /// validator.validateJsonString('plain text');      // Throws
  /// ```
  static void validateJsonString(String? jsonString) {
    if (jsonString == null || jsonString.trim().isEmpty) {
      throw MalformedJsonException('JSON string cannot be null or empty');
    }

    final trimmed = jsonString.trim();

    // Check if it looks like HTML
    if (isHtml(trimmed)) {
      throw MalformedJsonException(
        'Input appears to be HTML markup, not JSON: ${trimmed.substring(0, (trimmed.length > 50 ? 50 : trimmed.length))}...',
      );
    }

    // Check if it looks like plain text (no JSON structure)
    if (isPlainText(trimmed)) {
      throw MalformedJsonException('Input appears to be plain text, not JSON: $trimmed');
    }

    // Attempt to parse as JSON
    try {
      jsonDecode(trimmed);
    } catch (e) {
      throw MalformedJsonException('Invalid JSON syntax: ${e.toString()}', cause: e);
    }
  }

  /// Validates that a map can be safely serialized to JSON.
  ///
  /// Throws [MalformedJsonException] if:
  /// - The map contains non-JSON-serializable types
  /// - The map has null values and strict mode is enabled
  /// - The map contains circular references
  ///
  /// ### Example
  /// ```dart
  /// final validator = JsonValidator();
  /// validator.validateJsonMap({'key': 'value', 'number': 42}); // OK
  /// validator.validateJsonMap({'key': 'value', 'func': () => 1}); // Throws
  /// ```
  static void validateJsonMap(Map<String, dynamic>? map) {
    if (map == null) {
      throw MalformedJsonException('JSON map cannot be null');
    }

    _validateMapStructure(map, <Object>{});
  }

  /// Recursively validates the structure of a map to ensure JSON compatibility.
  static void _validateMapStructure(Map<String, dynamic> map, Set<Object> visited) {
    // Check for circular references
    if (visited.contains(map)) {
      throw MalformedJsonException('Circular reference detected in JSON map');
    }

    visited.add(map);

    for (final entry in map.entries) {
      final value = entry.value;

      _validateValue(value, visited);
    }

    visited.remove(map);
  }

  /// Recursively validates a value for JSON compatibility.
  static void _validateValue(dynamic value, Set<Object> visited) {
    if (value == null) {
      return; // null is valid JSON
    }

    if (value is String || value is num || value is bool) {
      return; // Primitive types are always valid
    }

    if (value is Map) {
      final map = value;
      if (visited.contains(map)) {
        throw MalformedJsonException('Circular reference detected in JSON structure');
      }
      visited.add(map);
      for (final entry in map.entries) {
        if (entry.key is! String) {
          throw MalformedJsonException('JSON map keys must be strings, got ${entry.key.runtimeType}: ${entry.key}');
        }
        _validateValue(entry.value, visited);
      }
      visited.remove(map);
      return;
    }

    if (value is List) {
      if (visited.contains(value)) {
        throw MalformedJsonException('Circular reference detected in JSON array');
      }
      visited.add(value);
      for (final item in value) {
        _validateValue(item, visited);
      }
      visited.remove(value);
      return;
    }

    // Invalid type for JSON
    throw MalformedJsonException(
      'Cannot serialize type ${value.runtimeType} to JSON. '
      'Only String, num, bool, null, Map<String, dynamic>, and List are JSON-compatible.',
    );
  }

  /// Detects if a string is HTML markup.
  static bool isHtml(String str) {
    final lowerStr = str.toLowerCase();
    return lowerStr.startsWith('<') && 
           (lowerStr.contains('html') || 
            lowerStr.contains('body') || 
            lowerStr.contains('div') ||
            lowerStr.contains('<!doctype') ||
            lowerStr.contains('<head') ||
            lowerStr.contains('<script') ||
            lowerStr.contains('<style'));
  }

  /// Detects if a string is plain text (not JSON or HTML).
  static bool isPlainText(String str) {
    // If it doesn't start with { or [ or ", it's likely plain text
    if (!str.startsWith('{') && !str.startsWith('[') && !str.startsWith('"')) {
      return true;
    }
    return false;
  }
}