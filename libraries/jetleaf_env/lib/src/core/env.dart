import 'package:jetleaf_lang/lang.dart';
import 'package:meta/meta_meta.dart';

import 'configuration_property_source.dart';

/// {@template value_class}
/// A generic configuration property accessor for environment variables.
///
/// The `Env<T>` class provides a strongly-typed way to fetch environment
/// variables at runtime. You can specify a key and an optional default value.
/// If the environment variable is missing and no default is set, an
/// [InvalidArgumentException] is thrown.
/// 
/// It can also be used as an annotation to inject environment variables into
/// fields.
///
/// ### Example
/// ```dart
/// void main() {
///   // Fetch a required environment variable.
///   final apiUrl = Env<String>('API_URL').value();
///
///   // Fetch an environment variable with a default fallback.
///   final timeout = Env<int>('TIMEOUT', defaultValue: 30).value();
///
///   // Gracefully handle missing values without throwing.
///   final optionalVar = Env<String>('OPTIONAL_VAR').valueOrNull();
///
///   print('API URL: $apiUrl');
///   print('Timeout: $timeout');
///   print('Optional: $optionalVar');
/// }
/// ```
/// {@endtemplate}
@Generic(Env)
@Target({TargetKind.field})
class Env<T> with ConfigurationPropertySource {
  /// {@template value_key}
  /// The key of the environment variable to access.
  ///
  /// This key is used to look up the variable from the environment or
  /// configuration sources.
  /// {@endtemplate}
  final String _key;

  /// {@template value_default}
  /// Optional default value to return if the variable is missing.
  ///
  /// If provided, this will be used as a fallback whenever the key is not
  /// present in the environment.
  /// {@endtemplate}
  final T? defaultValue;

  /// {@macro env}
  ///
  /// Creates a new [Env] accessor for a given environment variable.
  ///
  /// ### Example
  /// ```dart
  /// final apiUrl = Env<String>('API_URL');
  /// final timeout = Env<int>('TIMEOUT', defaultValue: 30);
  /// ```
  const Env(this._key, {this.defaultValue});

  /// {@template value_method_value}
  /// Returns the value of the environment variable as type [T].
  ///
  /// - If the variable is found in the current application context, it is returned.  
  /// - If not found but a [defaultValue] is set, the default is returned.  
  /// - If neither is available, an [InvalidArgumentException] is thrown.  
  ///
  /// ### Example
  /// ```dart
  /// final port = Env<int>('PORT', defaultValue: 8080).value();
  /// print('Server running on port: $port');
  /// ```
  /// {@endtemplate}
  T value() {
    T? value = environment.getPropertyAs<T>(_key, Class<T>(), defaultValue);

    if (value.isNotNull) {
      return value!;
    }

    if (defaultValue.isNotNull) {
      return defaultValue!;
    }

    throw InvalidArgumentException(_messageSuggestion);
  }

  /// {@template value_method_get}
  /// Returns the value of the environment variable as a [String].
  ///
  /// - If the variable is found, its string representation is returned.  
  /// - If missing, the [defaultValue] is used if provided.  
  /// - If both are unavailable, returns `null`.  
  /// 
  /// If [showSuggestions] is `true`, it will print a suggestion message
  /// with similar keys if available.
  ///
  /// ### Example
  /// ```dart
  /// final dbUrl = Env<String>('DATABASE_URL').get();
  /// print('Database URL: $dbUrl');
  /// ```
  /// {@endtemplate}
  String? get([bool showSuggestions = false]) {
    String? value = environment.getProperty(_key, defaultValue.toString());

    if (value.isNotNull) {
      return value!;
    }

    if (defaultValue.isNotNull) {
      return defaultValue.toString();
    }

    if (showSuggestions) {
      System.out.println(_messageSuggestion);
    }

    return null;
  }

  /// {@template value_method_valueOrNull}
  /// Returns the value of the environment variable as type [T], or `null`
  /// if not found or invalid.
  ///
  /// Unlike [value], this method **never throws an exception**.
  /// It is useful when you want optional values without breaking execution.
  /// 
  /// If [showSuggestions] is `true`, it will print a suggestion message
  /// with similar keys if available.
  ///
  /// ### Example
  /// ```dart
  /// final optionalToken = Env<String>('OPTIONAL_TOKEN').valueOrNull();
  /// if (optionalToken != null) {
  ///   print('Token found: $optionalToken');
  /// } else {
  ///   print('No token set');
  /// }
  /// ```
  /// {@endtemplate}
  T? valueOrNull([bool showSuggestions = false]) {
    try {
      return value();
    } catch (e) {
      if (showSuggestions) {
        System.out.println(_messageSuggestion);
      }
      return null;
    }
  }

  /// {@template value_method_exists}
  /// Checks if the environment variable exists in the loaded configuration.
  ///
  /// Returns `true` if the key is defined, otherwise `false`.
  ///
  /// ### Example
  /// ```dart
  /// final exists = Env<String>('API_KEY').exists();
  /// print('API key exists? $exists');
  /// ```
  /// {@endtemplate}
  bool exists() => environment.containsProperty(_key);

  /// {@template value_error_message}
  /// Generates a detailed error message when the variable is missing.
  ///
  /// - Includes the missing key name and expected type.  
  /// - Suggests similar keys if available, using a string similarity algorithm.  
  ///
  /// This is primarily used internally for debugging and exception messages.
  /// {@endtemplate}
  String get _messageSuggestion {
    final suggestions = environment.suggestions(_key);
    final hint = suggestions.isNotEmpty ? 'Did you mean: ${suggestions.join(', ')}?' : '';

    return 'Missing value "$_key" of type ${T.toString()}. $hint';
  }

  @override
  String toString() => 'Env<$T>($_key, defaultValue: $defaultValue)';
}