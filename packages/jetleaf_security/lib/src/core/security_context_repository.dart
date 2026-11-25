import 'typedefs.dart';
import 'package:jetleaf_web/jetleaf_web.dart';

import 'security_context.dart';

/// {@template deferred_security_context}
/// A lazily loaded [SecurityContext] whose loader runs at most once.
///
/// A filter chain that never reads the context never pays for a session lookup.
/// The first call to [get] invokes the supplied loader; subsequent calls return
/// the same instance, substituting a fresh empty context when the loader yields
/// `null`. Instances are single-use per request and are not shared across
/// concurrent zones.
///
/// ### Example
/// ```dart
/// final deferred = DeferredSecurityContext(() async => loadFromSession());
/// if (needsAuthentication) {
///   final context = await deferred.get();
/// }
/// ```
///
/// ### See also
/// - [SecurityContextRepository] — produces deferred contexts.
/// {@endtemplate}
class DeferredSecurityContext {
  final SecurityContextLoader _loader;
  SecurityContext? _value;
  bool _loaded = false;

  /// {@macro deferred_security_context}
  ///
  /// The loader is not invoked until [get] is first called.
  DeferredSecurityContext(this._loader);

  /// {@template deferred_security_context_of}
  /// Creates an already-loaded deferred context around [context].
  ///
  /// The supplied context is returned directly and the loader is never called.
  ///
  /// ### Parameters
  /// - [context]: the context to expose.
  /// {@endtemplate}
  /// {@macro deferred_security_context}
  DeferredSecurityContext.of(SecurityContext context)
      : _loader = (() async => context),
        _value = context,
        _loaded = true;

  /// Whether the underlying loader has been triggered.
  ///
  /// ### Returns
  /// `false` until the first call to [get].
  bool get isLoaded => _loaded;

  /// Returns the context, loading it on first access.
  ///
  /// ### Returns
  /// The loaded context, or a fresh empty [SecurityContext] if the loader
  /// returned `null`. The resolved instance is cached for later calls.
  Future<SecurityContext> get() async {
    if (!_loaded) {
      _value = await _loader() ?? SecurityContext();
      _loaded = true;
    }
    return _value!;
  }
}

/// {@template security_context_repository}
/// Strategy for loading and saving a [SecurityContext] across a request.
///
/// Implementations decide where the context lives between requests and whether
/// any persistence happens at all:
///
/// - [NullSecurityContextRepository] keeps no state and is suitable for token
///   based, stateless authentication.
/// - [HttpSessionSecurityContextRepository] stores the context in the session
///   and can be configured never to create one.
///
/// Loaders are deferred so a request that does not need authentication never
/// performs storage work. Implementations should be immutable and safe to
/// reuse across concurrent requests.
///
/// ### Example
/// ```dart
/// final deferred = repository.loadDeferredContext(request);
/// final context = await deferred.get();
/// // ...later in the same request
/// await repository.saveContext(context, request, response);
/// ```
///
/// ### See also
/// - [DeferredSecurityContext] — the lazy loader returned by [loadDeferredContext].
/// - [SecurityContext] — the value being persisted.
/// {@endtemplate}
abstract interface class SecurityContextRepository {
  /// Returns a deferred loader for the context associated with [request].
  ///
  /// ### Parameters
  /// - [request]: the active request whose storage is inspected on first read.
  ///
  /// ### Returns
  /// A [DeferredSecurityContext] that performs no work until it is read.
  DeferredSecurityContext loadDeferredContext(ServerHttpRequest request);

  /// Persists [context] after the request, if this repository supports it.
  ///
  /// ### Parameters
  /// - [context]: the context to save, possibly empty.
  /// - [request]: the request that produced the context.
  /// - [response]: the response, available to implementations that need to
  ///   write storage-related headers.
  ///
  /// ### Returns
  /// A future that completes when persistence, if any, is done.
  Future<void> saveContext(SecurityContext context, ServerHttpRequest request, ServerHttpResponse response);
}