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

import 'package:jetleaf_lang/lang.dart';

import 'yaml/parser/yaml_scanner.dart';

/// {@template json_parsing_exception}
/// Thrown when a JSON input cannot be parsed or is syntactically invalid.
///
/// Used internally by Jetleaf's [JsonParser] implementations to signal
/// malformed JSON, unexpected tokens, or invalid input streams.
///
/// ### Example
/// ```dart
/// try {
///   final parser = StringJsonParser('{"incomplete": true');
///   parser.nextToken(); // throws JsonParsingException
/// } on JsonParsingException catch (e) {
///   print('Invalid JSON: ${e.message}');
/// }
/// ```
///
/// ### See also
/// - [JsonParser]
/// - [InvalidFormatException]
/// - [ObjectMapper]
/// 
/// {@endtemplate}
class JsonParsingException extends RuntimeException {
  /// Creates a new [JsonParsingException] with an error [message] and
  /// optional [cause].
  /// 
  /// {@macro json_parsing_exception}
  JsonParsingException(super.message, {super.cause});
}

/// {@template malformed_json_exception}
/// Thrown when JSON data is structurally invalid or fails validation.
///
/// This exception is raised by validation utilities or serializers when:
/// - JSON structure is broken (mismatched braces/brackets)
/// - Required fields are missing or malformed
/// - JSON doesn't match expected schema or object structure
///
/// ### Example
/// ```dart
/// try {
///   final validator = JsonValidator();
///   validator.validate('{"incomplete": true', schema: User);
/// } on MalformedJsonException catch (e) {
///   print('Validation failed: ${e.message}');
/// }
/// ```
///
/// ### See also
/// - [JsonValidator]
/// - [JsonParsingException]
/// {@endtemplate}
class MalformedJsonException extends RuntimeException {
  /// Creates a new [MalformedJsonException] with an error [message] and
  /// optional [cause].
  ///
  /// {@macro malformed_json_exception}
  MalformedJsonException(super.message, {super.cause});
}

/// {@template jetleaf_illegal_object_token_exception}
/// Thrown when a parser encounters an **illegal or unexpected token** while
/// reading an object structure (JSON, YAML, XML, etc.).
///
/// Common causes:
/// - Malformed or truncated input  
/// - Structural mismatch (e.g., expected a mapping key but found a value)  
/// - Unexpected token in the current parsing context
///
/// ### Usage
/// ```dart
/// throw IllegalObjectTokenException(
///   'Expected a mapping key but found a sequence indicator at line 3.',
/// );
/// ```
///
/// ### See also
/// - [ObjectGeneratorException]
/// - Jetson parsers such as `JsonParser`, `YamlParser`, etc.
/// {@endtemplate}
class IllegalObjectTokenException extends RuntimeException {
  /// {@macro jetleaf_illegal_object_token_exception}
  IllegalObjectTokenException(super.message);
}

/// {@template jetleaf_object_generator_exception}
/// Thrown when a generator fails to serialize an object structure into an
/// output format (JSON, YAML, XML, etc.).
///
/// This exception indicates generator-phase failures such as:
/// - Unsupported value types encountered during serialization  
/// - Structural inconsistencies while emitting output (e.g., writing a value
///   outside of a mapping)  
/// - Invalid generator state or API misuse
///
/// ### Usage
/// ```dart
/// throw ObjectGeneratorException(
///   'Attempted to write a value outside a mapping context.',
/// );
/// ```
///
/// ### Notes
/// - General-purpose exception for generator failures across formats.  
/// - Consider using more specific subclasses if you want format-specific errors.
/// {@endtemplate}
class ObjectGeneratorException extends RuntimeException {
  /// {@macro jetleaf_object_generator_exception}
  ObjectGeneratorException(super.message);
}

/// {@template jetson_no_deserializer_found_exception}
/// Thrown when Jetson cannot locate a **deserializer** capable of converting
/// input data (JSON, YAML, XML, etc.) into an object of the requested type.
///
/// This typically occurs when:
/// - No `ObjectDeserializer<T>` is registered for the target type  
/// - The target type lacks Jetson metadata or annotations required for
///   reflective construction  
/// - A custom converter was expected but not provided  
///
/// ### Example
/// ```dart
/// throw NoDeserializerFoundException(
///   'No deserializer found for type User.',
/// );
/// ```
///
/// ### See also
/// - [NoSerializerFoundException]
/// - [ObjectDeserializer]
/// - [ObjectMapper]
/// {@endtemplate}
class NoDeserializerFoundException extends RuntimeException {
  /// {@macro jetson_no_deserializer_found_exception}
  NoDeserializerFoundException(super.message);
}

/// {@template jetson_no_serializer_found_exception}
/// Thrown when Jetson cannot locate a **serializer** capable of converting
/// a Dart object into an output format (JSON, YAML, XML, etc.).
///
/// This typically occurs when:
/// - No `ObjectSerializer<T>` is registered for the object's type  
/// - The type lacks Jetson annotations or reflection metadata  
/// - A required `JsonConverterAdapter` / format-specific converter
///   is not configured  
///
/// ### Example
/// ```dart
/// throw NoSerializerFoundException(
///   'No serializer found for type Order.',
/// );
/// ```
///
/// ### See also
/// - [NoDeserializerFoundException]
/// - [ObjectSerializer]
/// - [ObjectMapper]
/// {@endtemplate}
class NoSerializerFoundException extends RuntimeException {
  /// {@macro jetson_no_serializer_found_exception}
  NoSerializerFoundException(super.message);
}

/// {@template yaml_exception}
/// Thrown when an error occurs while parsing or processing a YAML document.
///
/// This exception represents **syntax or structural errors** encountered
/// during YAML parsing. It includes precise location information to help
/// identify where in the source document the error occurred.
///
/// This typically occurs when:
/// - The YAML document is malformed or contains invalid syntax
/// - Indentation rules are violated
/// - Unexpected tokens or values are encountered
///
/// ### Example
/// ```dart
/// throw YamlException(
///   'Unexpected token while parsing YAML',
///   position,
/// );
/// ```
///
/// ### See also
/// - [UnsupportedYamlFeatureException]
/// - [YamlPosition]
/// {@endtemplate}
class YamlException extends RuntimeException {
  /// The position in the YAML source where the error occurred.
  ///
  /// This provides line, column, and offset information to help
  /// pinpoint the exact location of the parsing error.
  final YamlPosition position;

  /// {@macro yaml_exception}
  ///
  /// Creates a new [YamlException] with the given error [message]
  /// and source [position].
  ///
  /// An optional [stackTrace] may be provided for debugging purposes.
  YamlException(super.message, this.position, {super.stackTrace});
  
  @override
  String toString() => 'YAML Exception at $position: $message';
}

/// {@template unsupported_yaml_feature_exception}
/// Thrown when a YAML document uses a feature that is not supported.
///
/// This exception is used when the YAML parser encounters valid YAML
/// syntax that relies on features not implemented or intentionally
/// disabled by the current parser configuration.
///
/// This typically occurs when:
/// - Advanced YAML features (anchors, aliases, tags, etc.) are used
/// - Custom YAML extensions are encountered
/// - The parser is running in a restricted or safe mode
///
/// ### Example
/// ```dart
/// throw UnsupportedYamlFeatureException(
///   'anchors',
///   position,
/// );
/// ```
///
/// ### See also
/// - [YamlException]
/// - [YamlPosition]
/// {@endtemplate}
class UnsupportedYamlFeatureException extends YamlException {
  /// The name of the unsupported YAML feature.
  ///
  /// This value describes which specific feature caused the exception,
  /// making it easier to diagnose compatibility issues.
  final String feature;

  /// {@macro unsupported_yaml_feature_exception}
  ///
  /// Creates a new [UnsupportedYamlFeatureException] for the given
  /// unsupported [feature] at the specified YAML [position].
  ///
  /// An optional [stackTrace] may be provided for debugging purposes.
  UnsupportedYamlFeatureException(this.feature, YamlPosition position, [StackTrace? stackTrace])
      : super('Unsupported YAML feature: $feature', position, stackTrace: stackTrace);
}

/// {@template yaml_syntax_exception}
/// Thrown when a YAML document contains **invalid or malformed syntax**.
///
/// This exception represents errors that occur when the YAML parser
/// encounters syntax that violates the YAML specification.
///
/// This typically occurs when:
/// - Indentation is incorrect or inconsistent
/// - Required delimiters (`:`, `-`, etc.) are missing
/// - Invalid scalar or mapping syntax is used
/// - Unexpected tokens are encountered during parsing
///
/// ### Example
/// ```dart
/// throw YamlSyntaxException(
///   'Expected ":" after key',
///   position,
/// );
/// ```
///
/// ### See also
/// - [YamlException]
/// - [YamlPosition]
/// - [UnsupportedYamlFeatureException]
/// {@endtemplate}
class YamlSyntaxException extends YamlException {
  /// {@macro yaml_syntax_exception}
  ///
  /// Creates a new [YamlSyntaxException] with a descriptive [message]
  /// and the exact source [position] where the syntax error occurred.
  ///
  /// An optional [stackTrace] may be provided for debugging purposes.
  YamlSyntaxException(String message, YamlPosition position, [StackTrace? stackTrace])
      : super('Syntax error: $message', position, stackTrace: stackTrace);
}

/// {@template failed_deserialization_exception}
/// Thrown when an object cannot be deserialized into the target Dart type.
///
/// This exception indicates a failure during the **deserialization process**,
/// where input data (JSON, YAML, XML, etc.) cannot be converted into
/// the expected object structure.
///
/// This typically occurs when:
/// - Required fields are missing or have incompatible types
/// - The input structure does not match the target model
/// - A custom deserializer throws an error
/// - Invalid or unexpected values are encountered
///
/// ### Example
/// ```dart
/// throw FailedDeserializationException(
///   'Unable to deserialize User from YAML document',
/// );
/// ```
///
/// ### See also
/// - [RuntimeException]
/// - [YamlException]
/// - [NoSerializerFoundException]
/// {@endtemplate}
class FailedDeserializationException extends RuntimeException {
  /// {@macro failed_deserialization_exception}
  ///
  /// Creates a new [FailedDeserializationException] with the given
  /// error [message].
  ///
  /// An optional [cause] and [stackTrace] may be provided to preserve
  /// the original failure context.
  FailedDeserializationException(super.message, {super.cause, super.stackTrace});
}