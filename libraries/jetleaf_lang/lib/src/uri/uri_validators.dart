import 'uri_validator.dart';

/// {@template scheme_validator}
/// Validates that a URI contains a scheme component (e.g., "https://").
///
/// Example:
/// ```dart
/// final validator = SchemeValidator();
/// validator.isValid(Uri.parse('https://example.com')); // true
/// validator.isValid(Uri.parse('example.com'));        // false
/// print(validator.errorMessage); // "URI must include a scheme..."
/// ```
/// {@endtemplate}
class SchemeValidator implements UriValidator {
  @override 
  bool isValid(Uri uri) => uri.scheme.isNotEmpty;
  
  @override
  String get errorMessage => 'URI must include a scheme (e.g., https://)';
}

/// {@template host_validator}
/// Validates that a URI contains a hostname component.
///
/// Example:
/// ```dart
/// final validator = HostValidator();
/// validator.isValid(Uri.parse('https://example.com')); // true
/// validator.isValid(Uri.parse('https://'));            // false
/// ```
/// {@endtemplate}
class HostValidator implements UriValidator {
  @override
  bool isValid(Uri uri) => uri.host.isNotEmpty;
  
  @override 
  String get errorMessage => 'URI must include a hostname';
}

/// {@template absolute_path_validator}
/// Validates that a URI contains an absolute path (starting with '/').
///
/// Example:
/// ```dart
/// final validator = AbsolutePathValidator();
/// validator.isValid(Uri.parse('https://example.com/path')); // true
/// validator.isValid(Uri.parse('mailto:test@example.com'));  // false
/// ```
/// {@endtemplate}
class AbsolutePathValidator implements UriValidator {
  @override
  bool isValid(Uri uri) => uri.hasAbsolutePath;
  
  @override
  String get errorMessage => 'URI must have an absolute path';
}

/// {@template secure_scheme_validator}
/// Validates that a URI uses a secure scheme (https or wss by default).
///
/// The allowed schemes can be customized by extending this class.
///
/// Example:
/// ```dart
/// final validator = SecureSchemeValidator();
/// validator.isValid(Uri.parse('https://secure.com')); // true
/// validator.isValid(Uri.parse('http://insecure.com')); // false
/// ```
/// {@endtemplate}
class SecureSchemeValidator implements UriValidator {
  /// List of allowed secure schemes
  final List<String> allowedSchemes = const ['https', 'wss'];
  
  @override
  bool isValid(Uri uri) => allowedSchemes.contains(uri.scheme);
  
  @override
  String get errorMessage => 'URI must use a secure scheme (${allowedSchemes.join(', ')})';
}

/// {@template no_credentials_validator}
/// Validates that a URI doesn't contain user credentials (username/password).
///
/// Example:
/// ```dart
/// final validator = NoCredentialsValidator();
/// validator.isValid(Uri.parse('https://example.com'));       // true
/// validator.isValid(Uri.parse('https://user:pass@site.com')); // false
/// ```
/// {@endtemplate}
class NoCredentialsValidator implements UriValidator {
  @override
  bool isValid(Uri uri) => uri.userInfo.isEmpty;
  
  @override
  String get errorMessage => 'URI must not contain user credentials';
}

/// {@template allowed_domains_validator}
/// Validates that a URI's host matches one of the allowed domains.
///
/// Example:
/// ```dart
/// final validator = AllowedDomainsValidator(['example.com', 'test.org']);
/// validator.isValid(Uri.parse('https://sub.example.com')); // true
/// validator.isValid(Uri.parse('https://forbidden.com'));   // false
/// ```
/// {@endtemplate}
class AllowedDomainsValidator implements UriValidator {
  /// List of allowed domain suffixes
  final List<String> allowedDomains;
  
  AllowedDomainsValidator(this.allowedDomains);
  
  @override
  bool isValid(Uri uri) {
    return allowedDomains.any((domain) => uri.host.endsWith(domain));
  }
  
  @override
  String get errorMessage => 'URI must be from allowed domains: ${allowedDomains.join(', ')}';
}

/// {@template no_ip_validator}
/// Validates that a URI uses a domain name rather than a raw IP address.
///
/// Example:
/// ```dart
/// final validator = NoIpAddressValidator();
/// validator.isValid(Uri.parse('https://example.com')); // true
/// validator.isValid(Uri.parse('https://192.168.1.1')); // false
/// ```
/// {@endtemplate}
class NoIpAddressValidator implements UriValidator {
  @override
  bool isValid(Uri uri) {
    final host = uri.host;
    return !RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(host);
  }
  
  @override
  String get errorMessage => 'URI must use domain names, not IP addresses';
}

/// {@template no_spaces_validator}
/// Validates that a URI string doesn't contain any spaces.
///
/// Example:
/// ```dart
/// final validator = NoSpacesValidator();
/// validator.isValid(Uri.parse('https://example.com'));    // true
/// validator.isValid(Uri.parse('https://ex ample.com'));   // false
/// ```
/// {@endtemplate}
class NoSpacesValidator implements UriValidator {
  @override
  bool isValid(Uri uri) => !uri.toString().contains(' ');
  
  @override
  String get errorMessage => 'URI must not contain spaces';
}

/// {@template query_param_validator}
/// Validates that a URI contains all required query parameters.
///
/// Example:
/// ```dart
/// final validator = QueryParamValidator(['page', 'limit']);
/// validator.isValid(Uri.parse('https://api.com?page=1&limit=10')); // true
/// validator.isValid(Uri.parse('https://api.com?page=1'));          // false
/// ```
/// {@endtemplate}
class QueryParamValidator implements UriValidator {
  /// List of required query parameter names
  final List<String> requiredParams;
  
  QueryParamValidator(this.requiredParams);
  
  @override
  bool isValid(Uri uri) {
    return requiredParams.every((param) => 
      uri.queryParameters.containsKey(param));
  }
  
  @override
  String get errorMessage => 'URI must include query parameters: ${requiredParams.join(', ')}';
}