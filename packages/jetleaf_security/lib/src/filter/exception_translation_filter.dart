import 'package:jetleaf_web/jetleaf_web.dart';

import '../authorization/access_denied_handler.dart';
import '../authorization/authentication_entry_point.dart';
import '../core/exceptions.dart';
import 'security_filter.dart';

/// {@template exception_translation_filter}
/// Catches [AuthenticationException] and [AccessDeniedException] thrown by
/// downstream filters and translates them into HTTP responses through an
/// [AuthenticationEntryPoint] or an [AccessDeniedHandler].
///
/// Authentication failures are rendered as 401 responses by
/// [authenticationEntryPoint]; authorization failures are rendered as 403
/// responses by [accessDeniedHandler]. Any other exception is left untouched
/// for outer layers to handle.
///
/// ### Contract and invariants
/// - Authentication exceptions take precedence over access-denied exceptions
///   because they are caught first.
/// - The filter must be placed before the filters whose exceptions it
///   translates; its `SecurityFilterOrders.exceptionTranslation` position is
///   chosen for that reason.
/// - A successful chain run leaves the response untouched.
/// - `CsrfFilter` handles denial itself and does not rely on this filter.
///
/// ### See also
/// - [AuthenticationEntryPoint]
/// - [AccessDeniedHandler]
/// - `SecurityFilterChain`
/// {@endtemplate}
class ExceptionTranslationFilter extends SecurityFilter {
  /// Entry point invoked on [AuthenticationException].
  final AuthenticationEntryPoint authenticationEntryPoint;

  /// Handler invoked on [AccessDeniedException].
  final AccessDeniedHandler accessDeniedHandler;

  /// Execution priority: immediately before authentication and authorization so
  /// their security exceptions can be translated.
  @override
  int get order => -65;

  /// {@macro exception_translation_filter}
  ExceptionTranslationFilter({
    this.authenticationEntryPoint = const BearerAuthenticationEntryPoint(),
    this.accessDeniedHandler = const JsonAccessDeniedHandler(),
  });

  /// Delegates to [chain] and translates security exceptions from downstream
  /// filters into HTTP responses.
  ///
  /// [request] and [response] are forwarded to the chain and then to the entry
  /// point or denial handler when an exception occurs. [chain] must be called
  /// with `chain.next(request, response)` inside the guarded block; without it
  /// no downstream security exception can be observed.
  ///
  /// ### Parameters
  /// - [request]: The incoming [ServerHttpRequest].
  /// - [response]: The outgoing [ServerHttpResponse] that may be written by a
  ///   translator.
  /// - [chain]: The remaining filter chain to delegate to.
  ///
  /// ### Returns
  /// A [Future] that completes after the chain or a translator finishes.
  ///
  /// ### Throws
  /// Catches [AuthenticationException] and [AccessDeniedException]; all other
  /// errors from the chain propagate unchanged.
  ///
  /// ### Example
  /// ```dart
  /// final filter = ExceptionTranslationFilter();
  /// await filter.doFilter(request, response, chain);
  /// // An AccessDeniedException from authorization becomes a 403 response.
  /// ```
  @override
  Future<void> doFilter(ServerHttpRequest request, ServerHttpResponse response, FilterChain chain) async {
    try {
      await chain.next(request, response);
    } on AuthenticationException catch (e) {
      await authenticationEntryPoint.commence(request, response, e);
    } on AccessDeniedException catch (e) {
      await accessDeniedHandler.handle(request, response, e);
    }
  }
}
