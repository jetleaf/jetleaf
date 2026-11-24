import 'package:jetleaf_core/annotation.dart';
import 'package:jetleaf_core/lang.dart' show Class;
import 'package:jetleaf_core/pod.dart' show ConfigurableListablePodFactory;

import '../authentication/authentication_event_publisher.dart';
import '../authorization/access_denied_handler.dart';
import '../authorization/authentication_entry_point.dart';
import '../authorization/role_hierarchy.dart';
import '../core/authentication_trust_resolver.dart';
import '../core/null_security_context_repository.dart';
import '../core/security_context_repository.dart';
import '../crypto/delegating_password_encoder.dart';
import '../crypto/password_encoder.dart';
import '../crypto/password_encoder_factories.dart';
import '../filter/filter_chain_proxy.dart';
import '../filter/security_exception_resolver.dart';
import '../filter/security_filter_chain.dart';
import 'http_security.dart';

/// {@template security_auto_configuration}
/// Registers overridable default security Pods.
///
/// Every default is guarded by `@ConditionalOnMissingPod`, so an application
/// Pod of the same type replaces the default without modifying the framework.
/// The Pods cover trust resolution, context storage, password encoding and the
/// default web filter chain plus its proxy.
///
/// As with all Jetleaf pods, the application must run `jl build` for these
/// factory methods to be present in the AOT pod registry.
///
/// ### Contract and invariants
/// - Defaults are installed only when no pod of the target type already exists.
/// - The default chain is an empty `HttpSecurity` build; applications normally
///   provide their own chain Pod.
/// - The proxy wraps a single chain and is registered as a web filter.
///
/// ### See also
/// - `MethodSecurityAutoConfiguration`
/// - [HttpSecurity]
/// {@endtemplate}
@AutoConfiguration()
final class SecurityAutoConfiguration {
  /// Pod name for this auto-configuration.
  static const String NAME = 'jetleaf.security.securityAutoConfiguration';

  /// Pod name for the default authentication trust resolver.
  static const String TRUST_RESOLVER = 'jetleaf.security.authenticationTrustResolver';

  /// Pod name for the default security context repository.
  static const String CONTEXT_REPOSITORY = 'jetleaf.security.securityContextRepository';

  /// Pod name for the default password encoder.
  static const String PASSWORD_ENCODER = 'jetleaf.security.passwordEncoder';

  /// Pod name for the default security filter chain.
  static const String FILTER_CHAIN = 'jetleaf.security.securityFilterChain';

  /// Pod name for the default filter chain proxy.
  static const String FILTER_CHAIN_PROXY = 'jetleaf.security.filterChainProxy';

  /// Pod name for the default role hierarchy used by request and method
  /// authorization.
  static const String ROLE_HIERARCHY = 'jetleaf.security.roleHierarchy';

  /// Pod name for the resolver that maps handler-level security exceptions to
  /// HTTP 401 and 403 responses.
  static const String EXCEPTION_RESOLVER = 'jetleaf.security.exceptionResolver';

  /// Pod name for the publisher that forwards authentication outcomes to the
  /// application event bus.
  static const String EVENT_PUBLISHER = 'jetleaf.security.authenticationEventPublisher';

  /// Pod name for the writer used when an unauthenticated request is denied.
  static const String ENTRY_POINT = 'jetleaf.security.authenticationEntryPoint';

  /// Pod name for the writer used when an authenticated principal lacks the
  /// required authority.
  static const String ACCESS_DENIED_HANDLER = 'jetleaf.security.accessDeniedHandler';

  /// {@macro security_auto_configuration}
  const SecurityAutoConfiguration();

  /// Creates the default [AuthenticationTrustResolver].
  ///
  /// ### Returns
  /// An [AuthenticationTrustResolverImpl] used to classify anonymous and
  /// remember-me tokens.
  @Pod(value: TRUST_RESOLVER)
  @ConditionalOnMissingPod(values: [AuthenticationTrustResolver])
  AuthenticationTrustResolver authenticationTrustResolver() => const AuthenticationTrustResolverImpl();

  /// Creates the default [SecurityContextRepository].
  ///
  /// ### Returns
  /// A [NullSecurityContextRepository], keeping context state request-scoped.
  @Pod(value: CONTEXT_REPOSITORY)
  @ConditionalOnMissingPod(values: [SecurityContextRepository])
  SecurityContextRepository securityContextRepository() => const NullSecurityContextRepository();

  /// Creates the default [DelegatingPasswordEncoder].
  ///
  /// ### Returns
  /// An encoder supporting the algorithm identifiers registered in
  /// [PasswordEncoderFactories].
  @Pod(value: PASSWORD_ENCODER)
  @ConditionalOnMissingPod(values: [PasswordEncoder])
  DelegatingPasswordEncoder passwordEncoder() => PasswordEncoderFactories.createDelegatingPasswordEncoder();

  /// Creates an empty default [RoleHierarchy] so request and method security
  /// always have a hierarchy to consult.
  @Pod(value: ROLE_HIERARCHY)
  @ConditionalOnMissingPod(values: [RoleHierarchy])
  RoleHierarchy roleHierarchy() => RoleHierarchy();

  /// Creates the default [SecurityFilterChain].
  ///
  /// ### Returns
  /// A chain built from a fresh [HttpSecurity], containing the baseline
  /// security filters.
  @Pod(value: FILTER_CHAIN)
  @ConditionalOnMissingPod(values: [SecurityFilterChain])
  SecurityFilterChain securityFilterChain() => HttpSecurity().build();

  /// Creates the [FilterChainProxy] for the given [chain].
  ///
  /// ### Parameters
  /// - [chain]: The security filter chain the proxy should dispatch to.
  ///
  /// ### Returns
  /// A proxy wrapping that single chain.
  @Pod(value: FILTER_CHAIN_PROXY)
  @ConditionalOnMissingPod(values: [FilterChainProxy])
  Future<FilterChainProxy> filterChainProxy(ConfigurableListablePodFactory podFactory) async {
    final chains = await podFactory.getPodsOf(
      Class<SecurityFilterChain>(),
      allowEagerInit: true,
    );

    return FilterChainProxy(chains.values.toList());
  }

  /// Publishes authentication outcomes onto the application event bus.
  @Pod(value: EVENT_PUBLISHER)
  @ConditionalOnMissingPod(values: [AuthenticationEventPublisher])
  AuthenticationEventPublisher authenticationEventPublisher() => BusAuthenticationEventPublisher();

  /// Default entry point for unauthenticated requests.
  @Pod(value: ENTRY_POINT)
  @ConditionalOnMissingPod(values: [AuthenticationEntryPoint])
  AuthenticationEntryPoint authenticationEntryPoint() => const BearerAuthenticationEntryPoint();

  /// Default handler for authorization denials.
  @Pod(value: ACCESS_DENIED_HANDLER)
  @ConditionalOnMissingPod(values: [AccessDeniedHandler])
  AccessDeniedHandler accessDeniedHandler() => const JsonAccessDeniedHandler();

  /// Maps handler-level security failures to 401 or 403 responses using the
  /// same handlers configured for the filter chain.
  @Pod(value: EXCEPTION_RESOLVER)
  @ConditionalOnMissingPod(values: [SecurityExceptionResolver])
  SecurityExceptionResolver securityExceptionResolver(AuthenticationEntryPoint entryPoint, AccessDeniedHandler deniedHandler) => SecurityExceptionResolver(
    entryPoint: entryPoint,
    accessDeniedHandler: deniedHandler,
  );
}