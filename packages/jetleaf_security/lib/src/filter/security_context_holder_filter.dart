import 'package:jetleaf_web/jetleaf_web.dart';

import '../core/null_security_context_repository.dart';
import '../core/security_context_holder.dart';
import '../core/security_context_repository.dart';
import 'security_filter.dart';

/// {@template security_context_holder_filter}
/// Loads the `SecurityContext` through the configured repository, binds it to a
/// forked Zone for the request, saves it on completion and clears it in a
/// `finally` block on every path.
///
/// The forked zone gives downstream filters and handlers a stable view of the
/// context for the lifetime of the request, even when work is scheduled
/// asynchronously. The repository decides whether the context is persistent
/// (session-backed) or transient.
///
/// ### Contract and invariants
/// - The context is loaded before the chain runs and saved after it completes.
/// - Cleanup happens in `finally`, so failures do not leak a context into the
///   next request handled by the same isolate.
/// - With `NullSecurityContextRepository` the context is request-scoped only.
/// - It occupies the `SecurityFilterOrders.securityContextHolder` slot so all
///   later filters see an initialized context.
///
/// ### Example
/// ```dart
/// final filter = SecurityContextHolderFilter(
///   contextRepository: HttpSessionSecurityContextRepository(),
/// );
/// ```
/// {@endtemplate}
class SecurityContextHolderFilter extends SecurityFilter {
  /// Execution priority: before authentication, which reads and writes the
  /// context established here.
  @override
  int get order => -60;

  /// Repository used to load and save the context.
  final SecurityContextRepository contextRepository;

  /// {@macro security_context_holder_filter}
  SecurityContextHolderFilter({SecurityContextRepository? contextRepository})
      : contextRepository = contextRepository ?? const NullSecurityContextRepository();

  /// Binds a loaded context around the downstream chain, then saves and clears
  /// it.
  ///
  /// [request] is passed to the repository to locate a stored context.
  /// [response] is passed to the repository when saving, allowing session
  /// creation where the policy permits it. [chain] is invoked inside
  /// `SecurityContextHolder.runWithContext` so every downstream filter observes
  /// the bound context.
  ///
  /// ### Parameters
  /// - [request]: The incoming [ServerHttpRequest].
  /// - [response]: The outgoing [ServerHttpResponse].
  /// - [chain]: The remaining filter chain to delegate to.
  ///
  /// ### Returns
  /// A [Future] that completes after the context has been saved and cleared.
  ///
  /// ### Throws
  /// Propagates load or save errors from [contextRepository] and any error from
  /// downstream filters, after cleanup has run.
  ///
  /// ### Example
  /// ```dart
  /// await filter.doFilter(request, response, chain);
  /// assert(SecurityContextHolder.getContext() == null || true);
  /// ```
  @override
  Future<void> doFilter(ServerHttpRequest request, ServerHttpResponse response, FilterChain chain) async {
    final context = await contextRepository.loadDeferredContext(request).get();

    await SecurityContextHolder.runWithContext(() async {
      try {
        await chain.next(request, response);
      } finally {
        await contextRepository.saveContext(context, request, response);
        SecurityContextHolder.clearContext();
      }
    }, context);
  }
}