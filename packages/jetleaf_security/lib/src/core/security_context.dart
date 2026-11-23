import 'package:jetleaf_core/lang.dart' show EqualsAndHashCode;

import 'authentication.dart';

/// {@template security_context}
/// Holds the [Authentication] associated with the current execution context.
///
/// A context is a small mutable carrier for a single request: once bound to a
/// zone it is shared only by code running in that zone, so concurrent requests
/// on one isolate never observe each other's identity. A context with a `null`
/// authentication represents an unauthenticated request.
///
/// Value equality compares the authentication, so two contexts holding the
/// same token are considered equal.
///
/// ### Example
/// ```dart
/// final context = SecurityContext(token);
/// context.authentication = null; // clear after logout
/// context.setAuthentication(token); // equivalent method form
/// ```
///
/// ### See also
/// - [Authentication] — the token carried by the context.
/// {@endtemplate}
class SecurityContext with EqualsAndHashCode {
  /// The currently authenticated principal, or `null` if unauthenticated.
  Authentication? authentication;

  /// {@macro security_context}
  ///
  /// Omitting [authentication] creates an empty, unauthenticated context.
  SecurityContext([this.authentication]);

  /// Sets the authentication carried by this context.
  ///
  /// Equivalent to assigning [authentication] directly. Provided for callers
  /// that prefer an explicit method, including fluent configuration code.
  ///
  /// ### Parameters
  /// - [authentication]: the trusted token to store, or `null` to clear it.
  void setAuthentication(Authentication? authentication) {
    this.authentication = authentication;
  }

  @override
  String toString() => 'SecurityContext(authentication: $authentication)';

  /// Contributes the runtime type and [authentication] to equality and hashing.
  ///
  /// ### Returns
  /// The ordered list of properties used by [EqualsAndHashCode].
  @override
  List<Object?> equalizedProperties() => [runtimeType, authentication];
}
