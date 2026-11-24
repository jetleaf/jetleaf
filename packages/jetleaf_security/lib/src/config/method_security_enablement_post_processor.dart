import 'package:jetleaf_core/context.dart' show PodFactoryPostProcessor;
import 'package:jetleaf_core/core.dart' show EntryApplicationAware;
import 'package:jetleaf_core/lang.dart' show Class;
import 'package:jetleaf_core/pod.dart' show ConfigurableListablePodFactory;

import '../annotation/enable_web_security.dart';
import '../authorization/role_hierarchy.dart';
import '../filter/security_filter_chain.dart';
import 'method_security_auto_configuration.dart';
import 'security_auto_configuration.dart';

/// {@template method_security_enablement_post_processor}
/// Aligns the pod registry with the security annotations on the application
/// class before any pod is instantiated.
///
/// Generated registries declare auto-configuration factory methods eagerly, so
/// a conditional annotation on a factory method cannot by itself prevent its
/// definition from existing. This processor removes definitions that must not
/// be active:
///
/// - the default filter chain when the application declares its own chain;
/// - method-security interceptors when `@EnableMethodSecurity` is absent;
/// - the post-invocation interceptor when expression security is disabled.
///
/// {@endtemplate}
final class MethodSecurityEnablementPodFactoryPostProcessor implements PodFactoryPostProcessor, EntryApplicationAware {
  Class<Object>? _entryApplication;

  /// {@macro method_security_enablement_post_processor}
  MethodSecurityEnablementPodFactoryPostProcessor();

  @override
  void setEntryApplication(Class<Object> entryApplication) =>
      _entryApplication = entryApplication;

  @override
  Future<void> postProcessFactory(ConfigurableListablePodFactory podFactory) async {
    _removeDefaultChainWhenUserChainExists(podFactory);
    _removeDefaultHierarchyWhenUserPodExists(podFactory);

    final enable = _entryApplication?.getDirectAnnotation<EnableMethodSecurity>();
    if (enable == null) {
      await _remove(
        podFactory,
        const {
          MethodSecurityAutoConfiguration.METADATA_SOURCE,
          MethodSecurityAutoConfiguration.BEFORE_INTERCEPTOR,
          MethodSecurityAutoConfiguration.AFTER_INTERCEPTOR,
        },
      );
      return;
    }

    if (!enable.prePostEnabled) {
      await _remove(
        podFactory,
        const {MethodSecurityAutoConfiguration.AFTER_INTERCEPTOR},
      );
    }
  }

  void _removeDefaultChainWhenUserChainExists(ConfigurableListablePodFactory podFactory) {
    final chainType = Class<SecurityFilterChain>();
    final hasUserChain = podFactory.getDefinitionNames().any((name) =>
      name != SecurityAutoConfiguration.FILTER_CHAIN &&
      podFactory.getDefinition(name).type.isSubclassOf(chainType),
    );

    if (hasUserChain && podFactory.containsDefinition(SecurityAutoConfiguration.FILTER_CHAIN)) {
      podFactory.removeDefinition(SecurityAutoConfiguration.FILTER_CHAIN);
    }
  }

  void _removeDefaultHierarchyWhenUserPodExists(ConfigurableListablePodFactory podFactory) {
    final hierarchyType = Class<RoleHierarchy>();
    final hasUserPod = podFactory.getDefinitionNames().any((name) =>
      name != SecurityAutoConfiguration.ROLE_HIERARCHY &&
      podFactory.getDefinition(name).type.isSubclassOf(hierarchyType),
    );
    if (hasUserPod && podFactory.containsDefinition(SecurityAutoConfiguration.ROLE_HIERARCHY)) {
      podFactory.removeDefinition(SecurityAutoConfiguration.ROLE_HIERARCHY);
    }
  }

  Future<void> _remove(ConfigurableListablePodFactory podFactory, Set<String> names) async {
    for (final name in names) {
      if (podFactory.containsDefinition(name)) {
        await podFactory.removeDefinition(name);
      }
    }
  }
}
