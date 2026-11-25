import 'package:jetleaf_core/annotation.dart';
import 'package:jetleaf_core/intercept.dart';

import '../authorization/method/enablement_aware_method_security_metadata_source.dart';
import '../authorization/method/method_security_interceptors.dart';
import '../authorization/method/method_security_metadata_source.dart';
import '../authorization/role_hierarchy.dart';
import 'method_security_enablement_post_processor.dart';

/// {@template method_security_auto_configuration}
/// Registers the method interceptors that enforce `@PreAuthorize`,
/// `@PostAuthorize`, `@Secured` and `@RolesAllowed` on generated proxies.
///
/// Target classes must be non-final, carry a proxy stereotype and be built with
/// `jl build`; otherwise interception silently does not happen (see ledger
/// 019). Every Pod is guarded by `@ConditionalOnMissingPod`, so applications
/// can replace the metadata source or either interceptor.
///
/// ### Contract and invariants
/// - The metadata source supplies authorization rules for annotated methods.
/// - The before interceptor checks access prior to method invocation.
/// - The after interceptor checks access on the returned value.
/// - All three Pods are optional overrides of framework defaults.
///
/// ### See also
/// - `SecurityAutoConfiguration`
/// - [MethodSecurityMetadataSource]
/// {@endtemplate}
@AutoConfiguration()
final class MethodSecurityAutoConfiguration {
  /// Pod name for this auto-configuration.
  static const String NAME = 'jetleaf.security.methodSecurityAutoConfiguration';

  /// Pod name for the enablement post-processor.
  static const String ENABLEMENT_PROCESSOR = 'jetleaf.security.methodSecurityEnablementPostProcessor';

  /// Pod name for the method security metadata source.
  static const String METADATA_SOURCE = 'jetleaf.security.methodSecurityMetadataSource';

  /// Pod name for the before-invocation interceptor.
  static const String BEFORE_INTERCEPTOR = 'jetleaf.security.authorizationManagerBeforeMethodInterceptor';

  /// Pod name for the after-returning interceptor.
  static const String AFTER_INTERCEPTOR = 'jetleaf.security.authorizationManagerAfterMethodInterceptor';

  /// {@macro method_security_auto_configuration}
  const MethodSecurityAutoConfiguration();

  /// Registers the processor that prunes disabled method-security Pods.
  @Pod(value: ENABLEMENT_PROCESSOR)
  @ConditionalOnMissingPod(values: [MethodSecurityEnablementPodFactoryPostProcessor])
  MethodSecurityEnablementPodFactoryPostProcessor methodSecurityEnablementPostProcessor() => MethodSecurityEnablementPodFactoryPostProcessor();

  /// Creates the default [MethodSecurityMetadataSource].
  ///
  /// ### Returns
  /// A metadata source that honours the `@EnableMethodSecurity` switches.
  @Pod(value: METADATA_SOURCE)
  @ConditionalOnMissingPod(values: [MethodSecurityMetadataSource])
  MethodSecurityMetadataSource methodSecurityMetadataSource() => EnablementAwareMethodSecurityMetadataSource();

  /// Creates the before-invocation security interceptor.
  ///
  /// ### Parameters
  /// - [metadataSource]: Source of method-level authorization rules.
  ///
  /// ### Returns
  /// An [AuthorizationManagerBeforeMethodInterceptor] bound to [metadataSource].
  @Pod(value: BEFORE_INTERCEPTOR)
  @ConditionalOnMissingPod(values: [AuthorizationManagerBeforeMethodInterceptor])
  MethodBeforeInterceptor methodSecurityBeforeInterceptor(
    MethodSecurityMetadataSource metadataSource,
    RoleHierarchy roleHierarchy,
  ) => AuthorizationManagerBeforeMethodInterceptor(
    metadataSource: metadataSource,
    roleHierarchy: roleHierarchy,
  );

  /// Creates the after-returning security interceptor.
  ///
  /// ### Parameters
  /// - [metadataSource]: Source of method-level authorization rules.
  ///
  /// ### Returns
  /// An [AuthorizationManagerAfterMethodInterceptor] bound to [metadataSource].
  @Pod(value: AFTER_INTERCEPTOR)
  @ConditionalOnMissingPod(values: [AuthorizationManagerAfterMethodInterceptor])
  AfterReturningInterceptor methodSecurityAfterInterceptor(
    MethodSecurityMetadataSource metadataSource,
    RoleHierarchy roleHierarchy,
  ) => AuthorizationManagerAfterMethodInterceptor(
    metadataSource: metadataSource,
    roleHierarchy: roleHierarchy,
  );
}