import '../core/typedefs.dart';
import '../core/authentication.dart';
import '../core/authentication_trust_resolver.dart';
import 'authorization_decision.dart';
import 'authorization_manager.dart';

/// {@template authenticated_authorization_manager}
/// Requires an authenticated principal, with optional rules for anonymous and
/// remember-me authentication.
///
/// This manager answers one question: does the current [Authentication]
/// represent a real, signed-in user? It classifies the authentication with the
/// configured [AuthenticationTrustResolver], then applies two acceptance
/// flags — [allowFullyAuthenticated] for principals that signed in directly
/// and [allowRememberMe] for principals restored from a persistent token.
///
/// ### Contract and invariants
/// - A `null` authentication, or one whose `isAuthenticated` is `false`, is denied.
/// - An anonymous authentication is always denied, regardless of the flags.
/// - A remember-me authentication is granted only when [allowRememberMe] is `true`.
/// - Any other authenticated authentication is granted only when
///   [allowFullyAuthenticated] is `true`.
/// - The generic [context] is ignored; the decision depends solely on the
///   authentication supplier and the configured flags.
/// - [check] reports denial through an [AuthorizationDecision]; it never throws
///   for a missing or unauthenticated principal.
///
/// ### Example
/// ```dart
/// // Accept any non-anonymous, signed-in principal.
/// final manager =
///     AuthenticatedAuthorizationManager<RequestAuthorizationContext>.authenticated();
/// final decision = manager.check(() => currentAuthentication, context);
/// print(decision.isGranted);
///
/// // Require a direct sign-in, rejecting remember-me sessions.
/// final strict = AuthenticatedAuthorizationManager<Object>.fullyAuthenticated();
///
/// // Accept remember-me principals too.
/// final relaxed = AuthenticatedAuthorizationManager<Object>.rememberMe();
/// ```
/// {@endtemplate}
final class AuthenticatedAuthorizationManager<T> implements AuthorizationManager<T> {
  /// Whether a fully authenticated principal is accepted.
  ///
  /// A principal is "fully authenticated" when it is neither anonymous nor
  /// remembered. Defaults to `true`.
  final bool allowFullyAuthenticated;

  /// Whether a remember-me principal is accepted.
  ///
  /// Remember-me principals are rejected by default; enable this flag to treat
  /// a restored session as sufficient. Anonymous principals are never accepted
  /// through this flag.
  final bool allowRememberMe;

  /// Resolver used to classify the authentication as anonymous or remember-me.
  ///
  /// Providing a custom resolver lets applications plug in their own token
  /// types without changing this manager.
  final AuthenticationTrustResolver trustResolver;

  /// {@macro authenticated_authorization_manager}
  ///
  /// Creates a manager with explicit acceptance flags and trust resolver.
  ///
  /// ### Parameters
  /// - [allowFullyAuthenticated]: accept directly authenticated principals.
  /// - [allowRememberMe]: accept principals restored from a remember-me token.
  /// - [trustResolver]: classifies the authentication; defaults to
  ///   `AuthenticationTrustResolverImpl`.
  const AuthenticatedAuthorizationManager({
    this.allowFullyAuthenticated = true,
    this.allowRememberMe = false,
    this.trustResolver = const AuthenticationTrustResolverImpl(),
  });

  /// {@template authenticated_authorization_manager_authenticated}
  /// Creates a manager that accepts any non-anonymous authentication.
  ///
  /// Remember-me principals are accepted, while anonymous and unauthenticated
  /// principals are denied.
  ///
  /// ### Returns
  /// A manager with [allowFullyAuthenticated] set to `true` and
  /// [allowRememberMe] set to `false`.
  /// {@endtemplate}
  /// {@macro authenticated_authorization_manager}
  factory AuthenticatedAuthorizationManager.authenticated() => AuthenticatedAuthorizationManager<T>();

  /// {@template authenticated_authorization_manager_fully_authenticated}
  /// Creates a manager that requires a fully authenticated principal.
  ///
  /// Both anonymous and remember-me principals are denied; only a principal
  /// that signed in directly is accepted.
  ///
  /// ### Returns
  /// A manager with [allowRememberMe] set to `false`.
  /// {@endtemplate}
  /// {@macro authenticated_authorization_manager}
  factory AuthenticatedAuthorizationManager.fullyAuthenticated() => AuthenticatedAuthorizationManager<T>(allowRememberMe: false);

  /// {@template authenticated_authorization_manager_remember_me}
  /// Creates a manager that also accepts remember-me principals.
  ///
  /// Anonymous and unauthenticated principals are still denied.
  ///
  /// ### Returns
  /// A manager with [allowRememberMe] set to `true`.
  /// {@endtemplate}
  /// {@macro authenticated_authorization_manager}
  factory AuthenticatedAuthorizationManager.rememberMe() => AuthenticatedAuthorizationManager<T>(allowRememberMe: true);

  /// {@template authenticated_authorization_manager_check}
  /// Decides whether the current authentication satisfies the configured rules.
  ///
  /// The authentication is resolved lazily through [authentication], so rules
  /// that never need it can avoid touching the security context. The [context]
  /// value is not inspected by this manager.
  ///
  /// ### Parameters
  /// - [authentication]: supplier for the current [Authentication], or `null`
  ///   when no authentication is present.
  /// - [context]: the caller's context; ignored by this manager.
  ///
  /// ### Returns
  /// An [AuthorizationDecision] that is granted only for an accepted principal.
  ///
  /// ### Example
  /// ```dart
  /// final decision = manager.check(
  ///   () => SecurityContextHolder.getContext().authentication,
  ///   context,
  /// );
  /// if (!decision.isGranted) throw AccessDeniedException('Sign in required');
  /// ```
  /// {@endtemplate}
  @override
  AuthorizationDecision check(AuthenticationSupplier authentication, T context) {
    final auth = authentication();
    if (auth == null || !auth.isAuthenticated) {
      return const AuthorizationDecision(false);
    }
    if (trustResolver.isAnonymous(auth)) {
      return const AuthorizationDecision(false);
    }
    if (trustResolver.isRememberMe(auth)) {
      return AuthorizationDecision(allowRememberMe);
    }
    return AuthorizationDecision(allowFullyAuthenticated);
  }
}
