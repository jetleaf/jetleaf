import 'package:jetleaf_core/lang.dart';

import '../alias/simple_alias_registry.dart';
import '../exceptions.dart';
import 'pod_definition.dart';
import 'pod_definition_registry.dart';

/// {@template simple_pod_definition_registry}
/// A **basic registry for managing pod definitions**.
///
/// This registry stores and retrieves [PodDefinition]s by name.  
/// It provides the ability to:
/// - Register new pod definitions.
/// - Look up existing pod definitions.
/// - Check if a pod definition exists.
/// - Remove pod definitions.
/// - Track the total count and names of registered definitions.
/// - Handle conflicts with alias names inherited from [SimpleAliasRegistry].
///
/// This is commonly used as the **backbone for dependency injection containers**, 
/// where pods must be defined before they can be instantiated.
///
/// ### Example usage:
/// ```dart
/// void main() {
///   final registry = SimplePodDefinitionRegistry();
///
///   // Create a simple pod definition (hypothetical).
///   final userPod = PodDefinition('UserPod');
///
///   // Register it.
///   registry.registerDefinition('user', userPod);
///
///   // Retrieve it.
///   final retrieved = registry.getDefinition('user');
///   print(retrieved?.name); // Output: UserPod
///
///   // Check existence.
///   print(registry.containsDefinition('user')); // true
///
///   // Get total count.
///   print(registry.getDefinitionCount()); // 1
///
///   // Remove definition.
///   registry.removeDefinition('user');
///
///   // Accessing a removed pod throws an exception.
///   try {
///     registry.getDefinition('user');
///   } catch (e) {
///     print(e); // NoSuchPodDefinitionException: No pod named 'user' is defined
///   }
/// }
/// ```
/// {@endtemplate}
class SimplePodDefinitionRegistry extends SimpleAliasRegistry implements PodDefinitionRegistry {
  /// Internal storage for pod definitions, keyed by pod name.
  final Map<String, PodDefinition> _definitions = HashMap<String, PodDefinition>();

  /// Internal storage for pod definitions, keyed by pod type.
  final Map<Class, PodDefinition> _classedDefinitions = HashMap<Class, PodDefinition>();

  /// Internal storage for pod definitions, keyed by pod type qualified name.
  final Map<String, PodDefinition> _classQualifiedNameDefinitions = HashMap<String, PodDefinition>();

  /// {@macro simple_pod_definition_registry}
  ///
  /// Creates a new simple pod definition registry instance.
  ///
  /// Example:
  /// ```dart
  /// final registry = SimplePodDefinitionRegistry();
  /// ```
  SimplePodDefinitionRegistry();

  @override
  bool containsDefinition(String name) => _definitions.containsKey(name);

  @override
  PodDefinition getDefinition(String name) {
    final pod = _definitions[name];
    if(pod == null) {
      throw NoSuchPodDefinitionException.byName(name);
    }

    return pod;
  }

  @override
  @override
  PodDefinition getDefinitionByClass(Class type) {
    final isObject = type.getType() == Object && type.getName() == 'Object';
    if (!isObject) {
      final matches = <PodDefinition>[];
      final fallbackMatches = <PodDefinition>[];
      final seenNames = <String>{};

      for (final definition in _definitions.values) {
        if (!seenNames.add(definition.name)) continue;
        final defType = definition.type;

        if (defType == type || defType.isSubclassOf(type) || type.isAssignableFrom(defType)) {
          matches.add(definition);
        } else if (defType.isAssignableFrom(type)) {
          fallbackMatches.add(definition);
        }
      }

      final candidates = matches.isNotEmpty ? matches : fallbackMatches;

      if (candidates.length == 1) {
        return candidates.first;
      }

      if (candidates.length > 1) {
        // 1. Look for primary candidate
        final primaryMatches = candidates.where((d) => d.design.isPrimary).toList();
        if (primaryMatches.length == 1) {
          return primaryMatches.first;
        } else if (primaryMatches.isNotEmpty) {
          return primaryMatches.first;
        }

        // 2. Look for exact type match
        final exactMatches = candidates.where((d) => d.type == type || d.type.getQualifiedName() == type.getQualifiedName()).toList();
        if (exactMatches.isNotEmpty) {
          return exactMatches.first;
        }

        return candidates.first;
      }
    }

    PodDefinition? pod = _classedDefinitions[type];
    if (pod != null) {
      return pod;
    }

    pod = _classQualifiedNameDefinitions[type.getQualifiedName()];
    if (pod != null) {
      return pod;
    }

    throw NoSuchPodDefinitionException.byType(type);
  }

  @override
  int getNumberOfPodDefinitions() => _definitions.length;

  @override
  List<String> getDefinitionNames() => List.unmodifiable(_definitions.keys.toList());

  @override
  Future<bool> isNameInUse(String name) async => isAlias(name) || containsDefinition(name);

  @override
  Future<void> registerDefinition(String name, PodDefinition pod) async {
    if(name.isEmpty) {
      throw IllegalArgumentException('Pod name cannot be empty');
    }

    if(isAlias(name)) {
      throw IllegalArgumentException('Pod name cannot be an alias');
    }

    _definitions[name] = pod;
    _classedDefinitions[pod.type] = pod;
    _classQualifiedNameDefinitions[pod.type.getQualifiedName()] = pod;
  }

  @override
  Future<void> removeDefinition(String name) async {
    final removed = _definitions.remove(name);
    if (removed == null) {
      throw NoSuchPodDefinitionException.byName(name);
    }

    // Clean up aliases pointing to this name
    final aliases = getAliases(name).toList();
    for (final alias in aliases) {
      removeAlias(alias);
    }
  }
}