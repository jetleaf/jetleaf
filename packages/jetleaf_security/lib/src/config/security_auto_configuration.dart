import 'package:jetleaf_core/annotation.dart';

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
/// Registers overridable default security beans.
///
/// Every default is guarded by `@ConditionalOnMissingPod`, so an application
/// bean of the same type replaces the default without modifying the framework.
/// The beans cover trust resolution, context storage, password encoding and the
/// default web filter chain plus its proxy.
///
/// As with all Jetleaf pods, the application must run `jl build` for these
/// factory methods to be present in the AOT pod registry.
///
/// ### Contract and invariants
/// - Defaults are installed only when no pod of the target type already exists.
/// - The default chain is an empty `HttpSecurity` build; applications normally
///   provide their own chain bean.
/// - The proxy wraps a single chain and is registered as a web filter.
///
/// ### See also
/// - `MethodSecurityAutoConfiguration`
/// - [HttpSecurity]
/// {@endtemplate}
@AutoConfiguration()
final class SecurityAutoConfiguration {
  /// Bean name for this auto-configuration.
  static const String NAME = 'jetleaf.security.securityAutoConfiguration';

  /// Bean name for the default authentication trust resolver.
  static const String TRUST_RESOLVER = 'jetleaf.security.authenticationTrustResolver';

  /// Bean name for the default security context repository.
  static const String CONTEXT_REPOSITORY = 'jetleaf.security.securityContextRepository';

  /// Bean name for the default password encoder.
  static const String PASSWORD_ENCODER = 'jetleaf.security.passwordEncoder';

  /// Bean name for the default security filter chain.
  static const String FILTER_CHAIN = 'jetleaf.security.securityFilterChain';

  /// Bean name for the default filter chain proxy.
  static const String FILTER_CHAIN_PROXY = 'jetleaf.security.filterChainProxy';

  static const String EXCEPTION_RESOLVER = 'jetleaf.security.exceptionResolver';

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
  FilterChainProxy filterChainProxy(SecurityFilterChain chain) => FilterChainProxy([chain]);

  /// Maps handler-level security failures to 401 or 403 responses.
  @Pod(value: EXCEPTION_RESOLVER)
  @ConditionalOnMissingPod(values: [SecurityExceptionResolver])
  SecurityExceptionResolver securityExceptionResolver() =>
      const SecurityExceptionResolver();
}