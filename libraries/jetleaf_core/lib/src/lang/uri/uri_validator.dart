/// {@template uri_validator}
/// An abstract validator for URI/URL validation.
///
/// This provides a contract for validating URIs and returning appropriate
/// error messages when validation fails. Implement this to create custom
/// URI validation logic.
///
/// Example Usage:
/// ```dart
/// class HttpUriValidator implements UriValidator {
///   @override
///   bool isValid(Uri uri) => uri.scheme == 'http' || uri.scheme == 'https';
///
///   @override
///   String get errorMessage => 'Must be a valid HTTP/HTTPS URL';
/// }
///
/// void main() {
///   final validator = HttpUriValidator();
///   final uri = Uri.parse('https://example.com');
///   
///   if (!validator.isValid(uri)) {
///     print(validator.errorMessage);
///   }
/// }
/// ```
/// {@endtemplate}
abstract interface class UriValidator {
  /// Validates whether the given URI meets specific criteria.
  ///
  /// Implement this method to define custom validation logic.
  ///
  /// Example:
  /// ```dart
  /// final validator = MyUriValidator();
  /// final isValid = validator.isValid(Uri.parse('https://test.com'));
  /// ```
  ///
  /// @param uri The URI to validate
  /// @return `true` if the URI is valid, `false` otherwise
  bool isValid(Uri uri);

  /// {@template uri_validator_error_message}
  /// Gets the error message to display when validation fails.
  ///
  /// This should provide a clear explanation of the validation requirements.
  ///
  /// Example:
  /// ```dart
  /// if (!validator.isValid(uri)) {
  ///   throw FormatException(validator.errorMessage);
  /// }
  /// ```
  /// {@endtemplate}
  String get errorMessage;
}