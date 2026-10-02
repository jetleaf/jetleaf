import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';

/// {@template pod_factory_customizer}
/// A lifecycle hook interface for customizing the [PodFactory] **before**
/// it is fully initialized or configured within the Jetleaf framework.
///
/// Introduced in **Jetleaf v1.0.1**, this interface allows advanced users
/// or framework extensions to programmatically modify a [ConfigurablePodFactory]
/// instance prior to pod registration, scanning, or dependency resolution.
///
/// This customization stage occurs **very early** in the application startup
/// lifecycle — before any pods are instantiated or dependency lookups are
/// available. Therefore, performing lookups or depending on the existence
/// of other pods at this stage will result in errors.
///
/// Implementations of [PodFactoryCustomizer] are typically used to:
/// - **Register custom pods** or modify existing pod definitions before
///   they are loaded.
/// - **Replace or enhance pod definitions**, such as swapping out default
///   implementations or adding new configuration metadata.
/// - **Adjust factory settings** like scope strategies, naming conventions,
///   or default initialization behaviors.
///
/// ### Usage Notes
/// - This interface should be implemented by components that participate in
///   the bootstrap process of Jetleaf.
/// - Class must have a no-arg constructor, else, it will be ignored.
/// - Avoid using any form of dependency lookup (`get()`, `containsType()`,
///   etc.) inside [customize]; the pod registry is not yet available.
/// - Use this hook for **explicit registrations only** — such as adding
///   new pod definitions or altering the configuration of the factory itself.
///
/// ### Example
/// ```dart
/// final class CustomPodRegistrar implements PodFactoryCustomizer<ConfigurablePodFactory> {
///   @override
///   Future<void> customize(ConfigurablePodFactory podFactory) async {
///     // Register a custom service pod before initialization
///     podFactory.registerPodDefinition(
///       PodDefinition.ofType(MyCustomService),
///     );
///   }
/// }
/// ```
///
/// This ensures that your custom service is known to the factory
/// before the main application context begins initialization.
///
/// {@endtemplate}
@Generic(PodFactoryCustomizer)
abstract interface class PodFactoryCustomizer<T extends ConfigurablePodFactory> {
  /// Customizes the given [podFactory] before it is initialized.
  ///
  /// This method is called **once**, during the early startup phase of
  /// the Jetleaf container. It allows explicit registration or configuration
  /// of pods, interceptors, or metadata.
  ///
  /// Implementers should not perform any pod lookups here, as the factory’s
  /// dependency graph has not yet been established.
  Future<void> customize(T podFactory, Environment environment);
}