/// 🔐 **Jetleaf Authentication & Session Security**
///
/// This library aggregates the contracts and implementations that establish
/// *who* is making a request. It covers credential tokens, authentication
/// managers and providers, outcome observability, and stateful session
/// handling — the foundation on which authorization decisions are made.
///
/// The pieces fit together in a predictable pipeline:
/// - **Tokens** such as [UsernamePasswordAuthenticationToken] and
///   [AnonymousAuthenticationToken] carry a principal, credentials, and the
///   authorities that have been granted.
/// - **Providers** such as [AuthenticationProvider] and
///   [DaoAuthenticationProvider] validate a specific token shape.
/// - **Managers** such as [AuthenticationManager] and [ProviderManager] drive
///   providers in order and return a fully populated token.
/// - **Observability** through [AuthenticationEventPublisher] reports successes
///   and failures without changing the outcome.
/// - **Sessions** through [SessionRegistry], [SessionInformation], and the
///   session strategies keep stateful principals safe from fixation and
///   trackable across requests.
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### 🎫 Authentication Tokens
/// - `Authentication` — the core token contract that every token implements.
/// - [UsernamePasswordAuthenticationToken] — username/password presentation and authenticated result token.
/// - [AnonymousAuthenticationToken] — placeholder identity for requests without credentials.
///
/// ### 🧭 Managers & Providers
/// - [AuthenticationManager] — contract for processing an authentication request.
/// - [ProviderManager] — iterates supporting providers, optionally delegating to a parent manager.
/// - [AuthenticationProvider] — contract for a provider that handles a specific token type.
/// - [DaoAuthenticationProvider] — validates credentials against a user-details store and password encoder.
///
/// ### 📣 Outcome Observability
/// - [AuthenticationEvent] — base type for authentication lifecycle events.
/// - [AuthenticationSuccessEvent] — emitted after credentials are verified.
/// - [AuthenticationFailureEvent] — emitted with the exception that caused a failure.
/// - [AuthenticationEventPublisher] — sink for authentication outcomes.
/// - [NoOpAuthenticationEventPublisher] — default publisher that discards events.
///
/// ### 🍪 Session Handling
/// - [SessionAuthenticationStrategy] — hook run after a successful authentication in a stateful policy.
/// - [NullAuthenticatedSessionStrategy] — no-op strategy for stateless flows.
/// - [CompositeSessionAuthenticationStrategy] — runs several strategies in order.
/// - [ChangeSessionIdAuthenticationStrategy] — migrates session state into a fresh session.
/// - [SessionFixationProtectionStrategy] — convenience alias for session-fixation protection.
/// - [SessionInformation] — record of one principal's session.
/// - [SessionRegistry] — tracks sessions per principal for concurrency control.
///
/// ---
///
/// ## 🎯 Usage Example
///
/// ```dart
/// import 'package:jetleaf_security/jetleaf_security.dart';
///
/// void main() async {
///   final manager = ProviderManager([
///     DaoAuthenticationProvider(
///       userDetailsService: myUserDetailsService,
///       passwordEncoder: myPasswordEncoder,
///     ),
///   ]);
///
///   final request = UsernamePasswordAuthenticationToken.unauthenticated(
///     principal: 'alice',
///     credentials: 's3cret',
///   );
///
///   final authenticated = await manager.authenticate(request);
///   print('${authenticated.name} is trusted: ${authenticated.isAuthenticated}');
/// }
/// ```
library;

export 'src/authentication/anonymous_authentication_token.dart';
export 'src/authentication/authentication_event_publisher.dart';
export 'src/authentication/authentication_manager.dart';
export 'src/authentication/authentication_provider.dart';
export 'src/authentication/dao_authentication_provider.dart';
export 'src/authentication/provider_manager.dart';
export 'src/authentication/session_authentication_strategy.dart';
export 'src/authentication/session_fixation_protection_strategy.dart';
export 'src/authentication/session_registry.dart';
export 'src/authentication/username_password_authentication_token.dart';
