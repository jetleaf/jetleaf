import 'package:jetleaf_web/jetleaf_web.dart';

import 'security_context.dart';
import 'security_context_repository.dart';

/// {@template null_security_context_repository}
/// Repository for stateless authentication.
///
/// It never reads or writes an HTTP session, even when the request carries a
/// session cookie. Loading always yields an empty [SecurityContext], and saving
/// is a no-op, which makes this repository safe to share across concurrent
/// requests with no mutable state.
///
/// ### Example
/// ```dart
/// const repository = NullSecurityContextRepository();
/// final context = await repository.loadDeferredContext(request).get();
/// assert(context.authentication == null);
/// ```
///
/// ### See also
/// - [SecurityContextRepository] — the strategy contract.
/// - [SecurityContext] — the empty context returned by every load.
/// {@endtemplate}
final class NullSecurityContextRepository implements SecurityContextRepository {
  /// {@macro null_security_context_repository}
  const NullSecurityContextRepository();

  @override
  DeferredSecurityContext loadDeferredContext(ServerHttpRequest request) => DeferredSecurityContext(() async => null);

  @override
  Future<void> saveContext(SecurityContext context, ServerHttpRequest request, ServerHttpResponse response) async {
    // Intentionally empty.
  }
}
