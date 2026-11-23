import 'package:jetleaf_web/jetleaf_web.dart';

import '../core/authentication.dart';
import 'session_authentication_strategy.dart';

/// {@template change_session_id_authentication_strategy}
/// A [SessionAuthenticationStrategy] that protects against session fixation by
/// moving session state into a freshly created session.
///
/// Jetleaf sessions have immutable identifiers, so the identifier itself cannot
/// be replaced in place. Instead this strategy copies every attribute from the
/// existing session into a new [HttpSession], invalidates the old session, and
/// writes a new session cookie to the response.
///
/// ### Contract and invariants
/// - If the request has no existing session, the strategy does nothing.
/// - All attribute names and values from the previous session are carried over
///   before it is invalidated.
/// - The new cookie is `HttpOnly`, uses `SameSite=Lax`, and is scoped to [path].
/// - The old session is invalidated once migration finishes, preventing a
///   pre-authentication identifier from being reused.
///
/// ### Example
/// ```dart
/// const strategy = ChangeSessionIdAuthenticationStrategy(
///   cookieName: HttpSession.JSESSIONID,
///   path: '/',
/// );
/// await strategy.onAuthentication(result, request, response);
/// ```
///
/// ### See also
/// - [SessionFixationProtectionStrategy]
/// - [SessionAuthenticationStrategy]
/// {@endtemplate}
class ChangeSessionIdAuthenticationStrategy implements SessionAuthenticationStrategy {
  /// Cookie name used for the session id.
  final String cookieName;

  /// Cookie path.
  final String path;

  /// {@macro change_session_id_authentication_strategy}
  const ChangeSessionIdAuthenticationStrategy({
    this.cookieName = HttpSession.JSESSIONID,
    this.path = '/',
  });

  /// Migrates the current session into a new one and issues its cookie.
  ///
  /// ### Parameters
  /// - [authentication] — the trusted result; accepted for interface conformance
  ///   but not used by this strategy.
  /// - [request] — the request whose existing session is migrated, if any.
  /// - [response] — the response that receives the new session cookie.
  ///
  /// ### Returns
  /// A future completing once the old session is invalidated and the cookie is
  /// written.
  @override
  Future<void> onAuthentication(Authentication authentication, ServerHttpRequest request, ServerHttpResponse response) async {
    final previous = request.getSession(false);
    if (previous == null) return;

    final fresh = HttpSession.create();
    for (final name in previous.getAttributeNames()) {
      fresh.setAttribute(name, previous.getAttribute(name));
    }
    previous.invalidate();

    final cookie = ResponseCookie(
      name: cookieName,
      value: fresh.getId(),
      path: path,
      httpOnly: true,
      sameSite: 'Lax',
    );
    response.getHeaders().set(HttpHeaders.SET_COOKIE, cookie.toString());
  }
}

/// {@template session_fixation_protection_strategy}
/// A named [SessionAuthenticationStrategy] for session-fixation protection.
///
/// This type delegates to [ChangeSessionIdAuthenticationStrategy], giving
/// configuration code a descriptive name for the protection policy while
/// keeping the migration behaviour in one place.
///
/// ### Contract and invariants
/// - Delegation is one-to-one: every call is forwarded unchanged.
/// - A custom [delegate] can be supplied to replace the default behaviour.
///
/// ### Example
/// ```dart
/// const strategy = SessionFixationProtectionStrategy();
/// await strategy.onAuthentication(result, request, response);
/// ```
///
/// ### See also
/// - [ChangeSessionIdAuthenticationStrategy]
/// - [SessionAuthenticationStrategy]
/// {@endtemplate}
final class SessionFixationProtectionStrategy implements SessionAuthenticationStrategy {
  /// Delegate performing the actual migration.
  final ChangeSessionIdAuthenticationStrategy delegate;

  /// {@macro session_fixation_protection_strategy}
  const SessionFixationProtectionStrategy([this.delegate = const ChangeSessionIdAuthenticationStrategy()]);

  /// Forwards the call to [delegate].
  ///
  /// ### Parameters
  /// - [authentication] — the trusted authentication result.
  /// - [request] — the current HTTP request.
  /// - [response] — the current HTTP response.
  ///
  /// ### Returns
  /// A future completing when the delegate finishes.
  @override
  Future<void> onAuthentication(Authentication authentication, ServerHttpRequest request, ServerHttpResponse response) => delegate.onAuthentication(authentication, request, response);
}
