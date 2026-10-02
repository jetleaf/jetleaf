import 'dart:async';

import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';

import '../cache/cache_configurer.dart';
import 'key_generator.dart';
import 'simple_key_generator.dart';

/// {@template jetleaf_composite_key_generator}
/// A composite [KeyGenerator] that aggregates and coordinates multiple
/// [KeyGenerator] pods registered within the Jetleaf application context.
///
/// The [CompositeKeyGenerator] serves as the top-level entry point for
/// key generation, delegating the task to an internally ordered chain of
/// registered [KeyGenerator] instances. It supports both conditional and
/// prioritized key generation strategies through the [_KeyGeneratorChain].
///
/// ### Discovery and Configuration
///
/// During startup, the generator automatically discovers all available
/// [KeyGenerator] pods and [CacheConfigurer] pods using the
/// [ConfigurableListablePodFactory]. Configurers can register additional
/// generators or customize the chain dynamically.
///
/// ### Ordering Semantics
///
/// The chain honors Jetleaf’s ordering interfaces:
///
/// - [PriorityOrdered] → highest precedence  
/// - [Ordered] → secondary precedence  
/// - Non-ordered → lowest precedence
///
/// These tiers are sorted deterministically by the
/// [AnnotationAwareOrderComparator], ensuring predictable key generation
/// resolution.
///
/// ### Example
///
/// ```dart
/// final generator = CompositeKeyGenerator();
/// await generator.onSingletonReady();
///
/// final key = await generator.generate(
///   serviceInstance,
///   Class<Service>().getMethod("findUserById"),
///   MethodArgument(['id': 42]),
/// );
///
/// print(key); // "findUserById:42"
/// ```
///
/// ### Related Components
///
/// - [KeyGenerator]
/// - [ConditionalKeyGenerator]
/// - [_KeyGeneratorChain]
/// - [CacheKeyGeneratorRegistry]
/// - [CacheConfigurer]
///
/// {@endtemplate}
final class CompositeKeyGenerator implements KeyGenerator, InitializingPod, PodFactoryAware, KeyGeneratorRegistry {
  // ---------------------------------------------------------------------------
  // Internal State
  // ---------------------------------------------------------------------------

  /// Reference to the [ConfigurableListablePodFactory] used for key generator discovery.
  ///
  /// This factory allows the composite to introspect all available [KeyGenerator]
  /// pods defined in the Jetleaf application context. It is automatically
  /// injected through the [setPodFactory] callback.
  ConfigurableListablePodFactory? _configurableListablePodFactory;

  /// Registry holding all discovered and registered [KeyGenerator] instances.
  ///
  /// The collection is synchronized during mutation to ensure thread safety
  /// and prevent duplicate registrations. Each generator in this set contributes
  /// to the overall composite key generation chain.
  final Set<KeyGenerator> _cacheKeyGenerators = {};

  /// {@macro jetleaf_composite_key_generator}
  CompositeKeyGenerator();
  
  @override
  void setPodFactory(PodFactory podFactory) {
    if (podFactory is ConfigurableListablePodFactory) {
      _configurableListablePodFactory = podFactory;
    }
  }
  
  @override
  Future<void> onReady() async {
    if (_configurableListablePodFactory != null) {
      // Discover and register all KeyGenerator pods
      final type = Class<KeyGenerator>(null, PackageNames.CORE);
      final pods = await _configurableListablePodFactory!.getPodsOf(type, allowEagerInit: true);

      if (pods.isNotEmpty) {
        final generators = List<KeyGenerator>.from(pods.values);
        AnnotationAwareOrderComparator.sort(generators);

        for (final generator in generators) {
          if (generator is CompositeKeyGenerator) {
            continue;
          }
          
          addKeyGenerator(generator);
        }
      } else {}

      // Discover and apply all CacheConfigurer pods
      final configurer = Class<CacheConfigurer>(null, PackageNames.CORE);
      final configurerMap = await _configurableListablePodFactory!.getPodsOf(configurer, allowEagerInit: true);

      if (configurerMap.isNotEmpty) {
        final configurers = List<CacheConfigurer>.from(configurerMap.values);
        AnnotationAwareOrderComparator.sort(configurers);

        for (final configurer in configurers) {
          configurer.configureKeyGenerator(this);
        }
      } else {}
    }
  }

  @override
  void addKeyGenerator(KeyGenerator cacheKeyGenerator) {
    return synchronized(_cacheKeyGenerators, () {
      _cacheKeyGenerators.remove(cacheKeyGenerator);
      _cacheKeyGenerators.add(cacheKeyGenerator);
    });
  }

  /// Collects and returns all registered [KeyGenerator] instances in a 
  /// deterministic, ordered sequence.
  ///
  /// The method inspects the internal list of configured key generators 
  /// ([_cacheKeyGenerators]) and arranges them according to Jetleaf’s 
  /// ordering contracts — ensuring predictable evaluation and execution order.
  ///
  /// ### Behavior
  ///
  /// - Iterates over all registered [KeyGenerator] instances.
  /// - Separates them into three ordered groups:
  ///   - **PriorityOrdered**: Highest precedence components, evaluated first.
  ///   - **Ordered**: Components with defined but lower precedence.
  ///   - **Simple**: Components without explicit ordering semantics.
  /// - Each group is individually sorted using the 
  ///   [AnnotationAwareOrderComparator] to ensure stable ordering.
  /// - The sorted groups are concatenated in the order:
  ///   1. `PriorityOrdered`
  ///   2. `Ordered`
  ///   3. `Simple`
  ///
  /// ### Deterministic Ordering
  ///
  /// The use of [AnnotationAwareOrderComparator] guarantees that multiple 
  /// [KeyGenerator] implementations behave predictably across runs, especially 
  /// when multiple annotations define conflicting priorities.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final generators = _getKeyGenerators();
  /// for (final generator in generators) {
  ///   final key = generator.generate('userCache', [userId]);
  ///   print('Generated cache key: $key');
  /// }
  /// ```
  ///
  /// ### Notes
  ///
  /// - Ordering ensures that custom or framework-provided key generators 
  ///   can be composed reliably without unpredictable overrides.
  /// - This method forms part of Jetleaf’s cache subsystem initialization 
  ///   sequence and is invoked internally by cache configuration utilities.
  ///
  /// ### Related Components
  ///
  /// - [KeyGenerator]: Defines the strategy for generating cache keys.
  /// - [AnnotationAwareOrderComparator]: Comparator that respects ordering 
  ///   metadata such as `@Order` and [PriorityOrdered].
  /// - [PriorityOrdered]: Marker interface indicating the highest precedence.
  /// - [Ordered]: Marker interface for medium-level ordering.
  /// - [_cacheKeyGenerators]: Internal list containing all registered 
  ///   [KeyGenerator] instances.
  ///
  /// Returns an ordered, immutable list of all [KeyGenerator] instances ready 
  /// for use in cache key resolution.
  List<KeyGenerator> _getKeyGenerators() => AnnotationAwareOrderComparator.getOrderedItems(_cacheKeyGenerators);

  @override
  Object generate(Object target, Method method, ExecutableArgument? argument) {
    final generators = _getKeyGenerators();
    final simpleGenerator = SimpleKeyGenerator();

    for (final generator in generators) {
      if (generator is ConditionalKeyGenerator) {
        if (generator.canGenerate(method, target)) {
          return generator.generate(target, method, argument);
        }
      } else {
        // Non-conditional generators always generate
        return generator.generate(target, method, argument);
      }
    }

    return simpleGenerator.generate(target, method, argument);
  }

  @override
  String getPackageName() => PackageNames.RESOURCE;

  @override
  List<Object?> equalizedProperties() => [runtimeType];
}