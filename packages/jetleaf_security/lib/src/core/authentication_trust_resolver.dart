import '../authentication/anonymous_authentication_token.dart';
import 'authentication.dart';

/// {@template authentication_trust_resolver}
/// Distinguishes anonymous, remembered, and fully authenticated principals.
///
/// Trust classification matters at the HTTP boundary: an anonymous token
/// reports `isAuthenticated == true` so that requests can progress through the
/// filter chain, but it must never be mistaken for a fully authenticated user
/// when deciding between an authentication challenge and an access-denied
/// response.
///
/// Implementations are stateless classifiers and may be shared across
/// concurrent requests.
///
/// ### Example
/// ```dart
/// final resolver = AuthenticationTrustResolverImpl();
/// if (resolver.isAnonymous(authentication)) {
///   entryPoint.commence(request, response);
/// }
/// ```
///
/// ### See also
/// - [Authentication] — the token being classified.
/// - [AuthenticationTrustResolverImpl] — the default implementation.
/// {@endtemplate}
abstract interface class AuthenticationTrustResolver {
  /// Whether [authentication] is anonymous, including when it is `null`.
  ///
  /// ### Parameters
  /// - [authentication]: the token to classify; `null` is treated as anonymous.
  ///
  /// ### Returns
  /// `true` when no real identity has been established.
  bool isAnonymous(Authentication? authentication);

  /// Whether [authentication] represents a remembered principal.
  ///
  /// ### Parameters
  /// - [authentication]: the token to classify; `null` is never remembered.
  ///
  /// ### Returns
  /// `true` when the token was issued by a remember-me mechanism.
  bool isRememberMe(Authentication? authentication);

  /// Whether [authentication] is trusted and carries a real identity.
  ///
  /// ### Parameters
  /// - [authentication]: the token to classify; `null` is never fully trusted.
  ///
  /// ### Returns
  /// `true` only when the token is authenticated, non-anonymous, and not a
  /// remember-me token.
  bool isFullyAuthenticated(Authentication? authentication);
}

/// {@template authentication_trust_resolver_impl}
/// Default [AuthenticationTrustResolver] implementation.
///
/// Anonymous tokens are recognized by their concrete type. Additional
/// remember-me token types can be registered at construction time, so custom
/// tokens participate in classification without requiring a subclass.
///
/// The registered type list is treated as immutable after construction; the
/// resolver itself holds no request state and is safe to reuse.
///
/// ### Example
/// ```dart
/// const resolver = AuthenticationTrustResolverImpl(
///   rememberMeTokenTypes: [CustomRememberMeToken],
/// );
/// ```
/// {@endtemplate}
final class AuthenticationTrustResolverImpl implements AuthenticationTrustResolver {
  /// Concrete token types that are treated as remember-me tokens.
  final List<Type> rememberMeTokenTypes;

  /// {@macro authentication_trust_resolver_impl}
  const AuthenticationTrustResolverImpl({this.rememberMeTokenTypes = const []});

  @override
  bool isAnonymous(Authentication? authentication) => authentication == null || authentication is AnonymousAuthenticationToken;

  @override
  bool isRememberMe(Authentication? authentication) {
    if (authentication == null) return false;
    for (final type in rememberMeTokenTypes) {
      if (authentication.runtimeType == type) return true;
    }
    return false;
  }

  @override
  bool isFullyAuthenticated(Authentication? authentication) => authentication != null &&
    authentication.isAuthenticated &&
    !isAnonymous(authentication) &&
    !isRememberMe(authentication);
}
