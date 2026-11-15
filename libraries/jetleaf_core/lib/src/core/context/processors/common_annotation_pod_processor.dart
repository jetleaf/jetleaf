import 'package:jetleaf_core/lang.dart';
import 'package:jetleaf_core/pod.dart';

import '../../aware.dart';
import '../../annotations/others.dart';

/// {@template jetleaf_class_CommonAnnotationPodProcessor}
/// A built-in Pod processor in Jetleaf that handles common lifecycle
/// annotations such as:
///
/// - `@PreConstruct` → executed **before initialization**
/// - `@PostConstruct` → executed **after initialization**
/// - `@PreDestroy` → executed **before destruction**
/// - `@Cleanup` → executed **after destruction**
///
/// This processor automatically scans the Pod's class for methods annotated
/// with these lifecycle annotations and invokes them at the appropriate time.
///
/// ### Example
/// ```dart
/// // Define a Pod with lifecycle methods
/// class MyService {
///   @PreConstruct
///   void initResources() {
///     print('Preparing resources...');
///   }
///
///   @PostConstruct
///   void afterInit() {
///     print('Service initialized.');
///   }
///
///   @PreDestroy
///   void beforeDestroy() {
///     print('Cleaning up before destruction...');
///   }
///
///   @Cleanup
///   void finalCleanup() {
///     print('Final cleanup done.');
///   }
/// }
///
/// // Register the processor in Jetleaf
/// final processor = CommonAnnotationPodProcessor();
/// // Jetleaf internally calls processor hooks during Pod lifecycle
/// ```
///
/// ### When to use
/// - When you want to define lifecycle behavior directly in your Pod classes.
/// - When you prefer declarative annotations instead of manual lifecycle handling.
/// - Useful for resource initialization, cleanup, caching, and service setup.
///
/// This class is part of **Jetleaf** – a framework developers can use
/// to build web applications.
/// {@endtemplate}
class CommonAnnotationPodProcessor extends PodDestructionProcessor implements PodInitializationProcessor, PriorityOrdered, PodFactoryAware {
  /// Optional handle to the pod factory, used to skip reflection-based
  /// invocation for pods carrying an AOT compiled invoker (`initMethodInvoker`).
  ConfigurableListablePodFactory? _podFactory;

  /// {@macro jetleaf_class_CommonAnnotationPodProcessor}
  CommonAnnotationPodProcessor();

  @override
  void setPodFactory(PodFactory podFactory) {
    if (podFactory is ConfigurableListablePodFactory) {
      _podFactory = podFactory;
    }
  }

  /// True when the named pod has a statically compiled AOT invoker for the
  /// requested lifecycle step — the AOT path is invoked exactly once by the
  /// container, so the reflection-based path must step aside.
  bool _hasAotInvoker(String name, {required bool destroy}) {
    final factory = _podFactory;
    if (factory == null) return false;

    try {
      final definition = factory.getDefinition(name);
      return destroy ? definition.destroyMethodInvoker != null : definition.initMethodInvoker != null;
    } catch (_) {
      return false;
    }
  }

  @override
  int getOrder() => Ordered.LOWEST_PRECEDENCE;

  @override
  Future<Object?> processBeforeInitialization(Object pod, Class podClass, String name) async {
    for (final method in podClass.getMethods()) {
      if (method.hasDirectAnnotation<PreConstruct>()) {
        method.invoke(pod);
      }
    }

    return pod;
  }

  @override
  Future<Object?> processAfterInitialization(Object pod, Class podClass, String name) async {
    if (_hasAotInvoker(name, destroy: false)) {
      return pod;
    }

    for (final method in podClass.getMethods()) {
      if (method.hasDirectAnnotation<PostConstruct>()) {
        method.invoke(pod);
      }
    }

    return pod;
  }

  @override
  Future<void> processAfterDestruction(Object pod, Class podClass, String name) async {
    for (final method in podClass.getMethods()) {
      if (method.hasDirectAnnotation<Cleanup>()) {
        method.invoke(pod);
      }
    }
  }

  @override
  Future<void> processBeforeDestruction(Object pod, Class podClass, String name) async {
    if (_hasAotInvoker(name, destroy: true)) {
      return;
    }

    for (final method in podClass.getMethods()) {
      if (method.hasDirectAnnotation<PreDestroy>()) {
        method.invoke(pod);
      }
    }
  }
  
  @override
  Future<bool> shouldProcessBeforeInitialization(Object pod, Class podClass, String name) async => true;
}