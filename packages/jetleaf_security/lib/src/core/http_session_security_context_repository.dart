import 'package:jetleaf_web/jetleaf_web.dart';

import 'authentication_trust_resolver.dart';
import 'security_context.dart';
import 'security_context_repository.dart';

/// {@template http_session_security_context_repository}
/// Stores the [SecurityContext] as an attribute of the HTTP session.
///
/// A stateful repository: an existing session is read on demand, and a new
/// session is created only when a non-empty context must be saved and
/// [allowSessionCreation] permits it. Set [allowSessionCreation] to `false`
/// for a `never` creation policy — stored contexts are still loaded, but no
/// new session is requested.
///
/// When the transport wrapper does not honour the session-creation flag, this
/// repository simply avoids calling the session accessor altogether in the
/// `false` case, so no session can be created implicitly.
///
/// ### Example
/// ```dart
/// const repository = HttpSessionSecurityContextRepository(
///   allowSessionCreation: false,
/// );
/// final deferred = repository.loadDeferredContext(request);
/// final context = await deferred.get();
/// ```
///
/// ### See also
/// - [SecurityContextRepository] — the strategy contract.
/// - [DeferredSecurityContext] — the lazy loader returned on read.
/// {@endtemplate}
final class HttpSessionSecurityContextRepository implements SecurityContextRepository {
  /// Default session attribute name used to store the security context.
  static const String SECURITY_CONTEXT_KEY = 'JETLEAF_SECURITY_CONTEXT';

  /// Whether a new session may be created when saving a non-empty context.
  final bool allowSessionCreation;

  /// Session attribute under which the context is stored.
  final String contextAttributeName;

  /// Resolver used to recognise anonymous authentication as "empty".
  final AuthenticationTrustResolver trustResolver;

  /// {@macro http_session_security_context_repository}
  const HttpSessionSecurityContextRepository({
    this.allowSessionCreation = true,
    this.contextAttributeName = SECURITY_CONTEXT_KEY,
    this.trustResolver = const AuthenticationTrustResolverImpl(),
  });

  @override
  DeferredSecurityContext loadDeferredContext(ServerHttpRequest request) {
    return DeferredSecurityContext(() async {
      // Do not touch the session accessor unless the client actually presented
      // a session cookie. Some transports create a session unconditionally.
      if (request.getCookies().get(HttpSession.JSESSIONID) == null) {
        return null;
      }
      final session = request.getSession(false);
      final stored = session?.getAttribute(contextAttributeName);
      return stored is SecurityContext ? stored : null;
    });
  }

  @override
  Future<void> saveContext(SecurityContext context, ServerHttpRequest request, ServerHttpResponse response) async {
    final authentication = context.authentication;
    final isEmpty = authentication == null || trustResolver.isAnonymous(authentication);
    if (isEmpty && !allowSessionCreation) {
      // No session is needed just to remove an attribute that cannot exist.
      return;
    }

    final session = request.getSession(!isEmpty && allowSessionCreation);
    if (session == null) return;

    if (isEmpty) {
      session.removeAttribute(contextAttributeName);
    } else {
      session.setAttribute(contextAttributeName, context);
    }
  }
}
