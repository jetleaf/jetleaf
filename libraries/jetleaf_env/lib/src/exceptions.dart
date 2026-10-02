import 'dart:collection';

import 'package:jetleaf_lang/lang.dart';

/// {@template missing_env_var_exception}
/// Exception thrown when a required environment variable is not found.
///
/// This is typically used in systems where environment variables are
/// mandatory and their absence should fail-fast during startup or runtime.
///
/// You can optionally attach a [cause] for additional context.
///
/// ---
///
/// ### 📦 Example Usage:
/// ```dart
/// final env = Environment.SYSTEM;
/// try {
///   final token = env.get('API_TOKEN');
/// } on MissingRequiredEnvironmentException catch (e) {
///   print('Missing variable: ${e.message}');
/// }
/// ```
///
/// ---
///
/// Used internally by [SystemEnvironment.get] in the Jetleaf framework.
/// {@endtemplate}
class MissingRequiredEnvironmentException extends RuntimeException {
  /// {@macro missing_env_var_exception}
  ///
  /// Creates a new [MissingRequiredEnvironmentException] with the given [message]
  /// and an optional [cause].
  MissingRequiredEnvironmentException(super.message, {super.cause});
}

/// {@template missing_required_properties_exception}
/// Exception thrown when required properties are not found.
///
/// Typically used by [ConfigurablePropertyResolver] during validation.
///
/// {@macro configurable_property_resolver_set}
/// {@macro configurable_property_resolver_validate}
///
/// See also:
/// - [ConfigurablePropertyResolver.setRequiredProperties]
/// - [ConfigurablePropertyResolver.validateRequiredProperties]
/// {@endtemplate}
class MissingRequiredPropertiesException extends RuntimeException {
  final LinkedHashSet<String> _missingRequiredProperties = LinkedHashSet<String>();

  /// Creates an instance of [MissingRequiredPropertiesException].
  MissingRequiredPropertiesException() : super('');

  /// Adds a missing required property key.
  void addMissingRequiredProperty(String key) {
    _missingRequiredProperties.add(key);
  }

  /// Returns the set of properties marked as required but not present upon validation.
  Set<String> getMissingRequiredProperties() => _missingRequiredProperties;

  @override
  String get message =>
      'The following properties were declared as required but could not be resolved: '
      '${getMissingRequiredProperties()}';
}

/// {@template environment_parsing_exception}
/// An [Exception] thrown when an error occurs during environment property parsing.
///
/// This exception typically indicates that the environment configuration
/// contains invalid or malformed values that cannot be properly interpreted.
///
/// ### Example usage:
///
/// ```dart
/// if (someParsingError) {
///   throw EnvironmentParsingException('Failed to parse environment variable XYZ');
/// }
/// ```
///
/// Catch this exception to handle or report environment parsing failures specifically.
/// {@endtemplate}
class EnvironmentParsingException extends RuntimeException {
  /// {@macro environment_parsing_exception}
  EnvironmentParsingException(super.message);

  @override
  String toString() => 'EnvironmentParsingException: $message';
}

/// {@template dart_loading_exception}
/// Exception thrown when Dart file loading fails.
///
/// This exception is thrown during the loading or parsing of Dart files
/// when an error occurs, such as:
/// 
/// - Invalid Dart syntax
/// - Missing or incorrect import statements
/// - File not found or unreadable
///
/// Typically used in reflection-based systems or runtime file loading
/// processes like those in the Jetleaf framework.
///
/// ### Example
/// ```dart
/// void loadDartFile(String path) {
///   if (!File(path).existsSync()) {
///     throw DartLoadingException('File not found: $path');
///   }
///   // ...parse or load logic
/// }
/// ```
/// {@endtemplate}
class DartLoadingException extends RuntimeException {
  /// {@macro dart_loading_exception}
  DartLoadingException(super.message);
}