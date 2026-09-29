import 'package:jetleaf_lang/lang.dart';

import '../definition/pod_definition.dart';
import '../definition/pod_definition_registry.dart';

/// {@template pod_name_generator}
/// Strategy interface for generating pod names for [PodDefinition]s.
///
/// Frameworks that manage pods or dependency injection containers can use this
/// interface to determine the default name to assign to a pod definition if no
/// explicit name is provided.
///
/// This abstraction decouples naming logic from the core registration mechanism,
/// allowing different naming strategies to be plugged in (e.g., based on class names,
/// annotations, metadata, or hashing).
///
/// ### Example
/// ```dart
/// class SimpleNameGenerator implements PodNameGenerator {
///   @override
///   String generate(PodDefinition definition, PodDefinitionRegistry registry) {
///     return definition.name.toLowerCase();
///   }
/// }
///
/// void main() {
///   final definition = PodDefinition('MyService', Class<MyService>());
///   final registry = MyPodDefinitionRegistry();
///   final generator = SimpleNameGenerator();
///   print(generator.generate(definition, registry)); // Output: myservice
/// }
/// ```
/// {@endtemplate}
abstract interface class PodNameGenerator implements PackageIdentifier {
  /// {@macro pod_name_generator}
  const PodNameGenerator();

  /// {@macro pod_name_generator}
  ///
  /// Generates a name for the given [definition] within the context of the provided [registry].
  ///
  /// Implementations can inspect the pod class, metadata, annotations, or even the registry state
  /// to determine the best unique name to assign.
  String generate(PodDefinition definition, PodDefinitionRegistry registry);
}