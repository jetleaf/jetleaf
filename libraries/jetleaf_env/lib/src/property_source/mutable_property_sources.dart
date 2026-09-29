import 'package:jetleaf_lang/lang.dart';

import '../property_source_ordering/property_source_ordering_rule.dart';
import 'map_property_source.dart';
import 'property_source.dart';
import 'property_sources.dart';

/// {@template mutable_property_sources}
/// A mutable container for managing an ordered list of [PropertySource] objects.
///
/// This class allows adding, removing, and retrieving property sources dynamically
/// by name or position. It maintains the search order for property resolution,
/// where the first source added has the highest precedence during lookups.
///
/// This container is typically passed to a [PropertySourcesPropertyResolver]
/// to resolve environment or configuration properties.
///
/// ### Example usage:
/// ```dart
/// final sources = MutablePropertySources();
///
/// final defaults = MapPropertySource('defaults', {'debug': 'false'});
/// final env = MapPropertySource('env', {'debug': 'true'});
///
/// sources.addLast(defaults);
/// sources.addFirst(env); // env now has higher precedence
///
/// final value = sources.get('env')?.getProperty('debug'); // 'true'
///
/// sources.remove('defaults');
/// ```
///
/// ### Ordering Methods
/// You can control precedence using:
/// - [addFirst]
/// - [addLast]
/// - [addBefore]
/// - [addAfter]
///
/// This is particularly useful for layered configuration such as:
/// command-line args > environment variables > default config.
/// {@endtemplate}
class MutablePropertySources extends PropertySources {
  /// Mutable backing list that stores the ordered collection of
  /// [PropertySource] instances.
  ///
  /// Ordering is significant:
  /// - Sources at the **beginning** have the **highest precedence**
  ///   during property resolution.
  /// - Sources at the **end** have the **lowest precedence**.
  ///
  /// This list is internally return  for operations that mutate it,
  /// ensuring thread-safe insertion, removal, and reordering.
  List<PropertySource> _sources = [];

  /// {@macro mutable_property_sources}
  MutablePropertySources();

  /// Creates a new mutable collection by copying all entries from an existing
  /// [PropertySources] instance.
  ///
  /// The original ordering is preserved, meaning each source will have the
  /// same precedence relative to the others as in the original collection.
  ///
  /// This is primarily used when upgrading an immutable source collection
  /// into a mutable one.
  MutablePropertySources.from(PropertySources propertySources) {
    for (final source in propertySources) {
      addLast(source);
    }
  }

  /// Inserts the given [source] at the beginning of the list, giving it the
  /// **highest precedence** during property resolution.
  ///
  /// If the source is already present, the existing instance is removed before
  /// insertion to ensure the new ordering is applied.
  ///
  /// Example:
  /// ```dart
  /// sources.addFirst(MapPropertySource('system', {...}));
  /// ```
  void addFirst(PropertySource source) {
    return synchronized(_sources, () {
      _removeIfPresent(source);
      _sources.insert(0, source);
    });
  }

  /// Inserts the given [source] at the end of the list, giving it the
  /// **lowest precedence**.
  ///
  /// If already present, the existing instance is removed before re-adding it.
  ///
  /// Example:
  /// ```dart
  /// sources.addLast(MapPropertySource('defaults', {...}));
  /// ```
  void addLast(PropertySource source) {
    return synchronized(_sources, () {
      _removeIfPresent(source);
      _sources.add(source);
    });
  }

  /// Inserts [newSource] **before** the property source named
  /// [relativeSourceName].
  ///
  /// Steps performed:
  /// 1. Validates legal placement (cannot insert relative to itself).
  /// 2. Ensures the relative source exists.
  /// 3. Removes any existing instance of [newSource].
  /// 4. Inserts at the appropriate index.
  ///
  /// Throws:
  /// - `IllegalArgumentException` if the relative source is not present.
  ///
  /// Example:
  /// ```dart
  /// sources.addBefore('env', MapPropertySource('fallback', {...}));
  /// ```
  void addBefore(String relativeSourceName, PropertySource newSource) {
    _assertLegalRelativeAddition(relativeSourceName, newSource);
    
    return synchronized(_sources, () {
      _removeIfPresent(newSource);
      int index = _assertPresentAndGetIndex(relativeSourceName);
      _addAtIndex(index, newSource);
    });
  }

  /// Inserts [newSource] **after** the property source named
  /// [relativeSourceName].
  ///
  /// Behavior is the same as [addBefore] except the new source is placed
  /// immediately after the referenced entry.
  ///
  /// Example:
  /// ```dart
  /// sources.addAfter('commandLine', MapPropertySource('logConfig', {...}));
  /// ```
  void addAfter(String relativeSourceName, PropertySource newSource) {
    _assertLegalRelativeAddition(relativeSourceName, newSource);
    
    return synchronized(_sources, () {
      _removeIfPresent(newSource);
      int index = _assertPresentAndGetIndex(relativeSourceName);
      _addAtIndex(index + 1, newSource);
    });
  }

  /// Adds all [sources] to the collection in the order provided.
  ///
  /// This operation does **not** remove duplicates or reorder existing sources.
  ///
  /// Example:
  /// ```dart
  /// sources.addAll([source1, source2]);
  /// ```
  void addAll(List<PropertySource> sources) {
    _sources.addAll(sources);
  }

  /// Returns the index of [propertySource] within this collection,
  /// or `-1` if not found.
  ///
  /// Lower indices represent **higher precedence**.
  int precedenceOf(PropertySource propertySource) => _sources.indexOf(propertySource);

  /// Removes the property source with the given [name], if present.
  ///
  /// Returns:
  /// - The removed [PropertySource], or  
  /// - `null` if no matching source exists.
  ///
  /// Example:
  /// ```dart
  /// final removed = sources.remove('env');
  /// ```
  PropertySource? remove(String name) {
    return synchronized(_sources, () {
      int index = _getIndex(name);
      return (index != -1 ? _sources.removeAt(index) : null);
    });
  }

  /// Adds a new [MapPropertySource] with the given [name], or merges the provided
  /// [source] map into an existing one if a property source with the same name
  /// is already present.
  ///
  /// This method is designed for dynamic, incremental configuration updates,
  /// such as loading layered configuration files, merging environment overrides,
  /// or applying runtime-provided settings.
  ///
  /// ### Behavior
  /// - If no property source with the given [name] exists:
  ///   - A new [MapPropertySource] is created containing all key–value pairs
  ///     from [source].
  ///   - It is added with **lowest precedence** using [addLast].
  ///
  /// - If a matching property source *does* exist:
  ///   - The existing source is retrieved and merged (when possible) by
  ///     [mergeIfPossible].
  ///   - The merged result becomes a new [MapPropertySource].
  ///   - It **replaces** the old source using [replace].
  ///
  /// If [source] is empty, this method performs no action.
  ///
  /// ### Example
  /// ```dart
  /// sources.addOrMerge({'debug': 'true'}, 'env');
  ///
  /// // If 'env' already exists, keys are merged.
  /// // If not, a new MapPropertySource('env') is added.
  /// ```
  void addOrMerge(Map<String, Object> source, String name) {
    if (source.isNotEmpty) {
      final resultingSource = <String, Object>{};
      final propertySource = MapPropertySource(name, resultingSource);

      if (containsName(name)) {
        mergeIfPossible(source, resultingSource, name);
        replace(name, propertySource);
      } else {
        resultingSource.addAll(source);
        addLast(propertySource);
      }
    }
  }
  
  /// Attempts to merge the provided [source] map into an existing
  /// [MapPropertySource] identified by [name], writing the result into
  /// [resultingSource].
  ///
  /// ### Merging Rules
  /// - The method retrieves the existing source via [get].
  /// - If the existing source's underlying data is a [Map], its entries are
  ///   copied into [resultingSource] **first**.
  /// - The incoming [source] map is then applied **on top**, allowing the new
  ///   values to override existing ones when key names collide.
  ///
  /// ### Example merge behavior:
  /// Existing source:
  /// ```json
  /// { "host": "localhost", "port": "8080" }
  /// ```
  ///
  /// Incoming update:
  /// ```json
  /// { "port": "9090", "secure": "true" }
  /// ```
  ///
  /// Result:
  /// ```json
  /// { "host": "localhost", "port": "9090", "secure": "true" }
  /// ```
  ///
  /// If the existing property source is not backed by a `Map`, the incoming
  /// [source] map is still copied on top, but no merging occurs from the
  /// underlying data.
  ///
  /// This helper exists to keep [addOrMerge] clean while providing deterministic,
  /// override-oriented merge semantics consistent with layered configuration
  /// models.
  void mergeIfPossible(Map<String, Object> source, Map<String, Object> resultingSource, String name) {
    final existingSource = get(name);
    if (existingSource != null) {
      final underlyingSource = existingSource.getSource();
      if (underlyingSource is Map) {
        resultingSource.addAll(underlyingSource as Map<String, Object>);
      }
      resultingSource.addAll(source);
    }
  }

  /// Replaces the property source with the given [name] with [propertySource].
  ///
  /// The names must match, and the target must already exist.
  ///
  /// Throws:
  /// - `IllegalArgumentException` if no source with the given name exists.
  ///
  /// Example:
  /// ```dart
  /// sources.replace('env', MapPropertySource('env', {'mode': 'prod'}));
  /// ```
  void replace(String name, PropertySource propertySource) {
    return synchronized(_sources, () {
      int index = _assertPresentAndGetIndex(name);
      _sources[index] = propertySource;
    });
  }

  /// Reorders property sources using the provided [rules].
  ///
  /// Each rule is applied in the order given. Later rules may refine or override
  /// earlier ones. The reordering is executed atomically.
  ///
  /// Example:
  /// ```dart
  /// sources.reorder([
  ///   BeforeRule('env', 'defaults'),
  ///   PriorityRule({'system': 0, 'env': 1, 'defaults': 99}),
  /// ]);
  /// ```
  void reorder(List<PropertySourceOrderRule> rules) {
    synchronized(_sources, () {
      List<PropertySource> working = List.of(_sources);
      for (final rule in rules) {
        working = rule.apply(working);
      }

      _sources = working;
    });
  }

  /// Returns `true` if this collection contains a [PropertySource] whose
  /// name matches [name].
  ///
  /// Useful for checking whether a configuration layer has been registered.
  ///
  /// Example:
  /// ```dart
  /// final hasEnv = sources.containsName('env');
  /// ```
  bool containsName(String name) {
    for (final propertySource in _sources) {
      if (propertySource.getName() == name) {
        return true;
      }
    }
    return false;
  }

  @override
  Iterator<PropertySource> get iterator => _sources.iterator;

  /// Returns the index of the property source whose name matches [name],
  /// or `-1` if no such source exists.
  ///
  /// This method performs a linear search using `indexWhere` and compares
  /// names using the `equals` extension for safe, null-aware equality.
  ///
  /// Used internally for lookup operations such as insertion, removal,
  /// replacement, and relative ordering.
  int _getIndex(String name) => _sources.indexWhere((s) => s.getName().equals(name));

  /// Ensures that a relative addition involving [propertySource] and the
  /// referenced [sourceName] is valid.
  ///
  /// This method prevents adding a property source *relative to itself*,
  /// which would create ambiguous or circular ordering semantics.
  ///
  /// Throws:
  /// - [IllegalArgumentException] if both names refer to the same source.
  ///
  /// Example invalid usage:
  /// ```dart
  /// addBefore('env', MapPropertySource('env', {...})); // ❌ invalid
  /// ```
  void _assertLegalRelativeAddition(String sourceName, PropertySource propertySource) {
    String name = propertySource.getName();
    if (sourceName.equals(name)) {
      throw IllegalArgumentException("PropertySource named '$name' cannot be added relative to itself");
    }
  }

  /// Removes the given [propertySource] from the internal list if it is
  /// present. If it is not present, the operation is a no-op.
  ///
  /// This helper ensures that operations such as `addFirst`, `addLast`,
  /// `addBefore`, and `addAfter` do not introduce duplicates in the list,
  /// while preserving consistent ordering behavior.
  void _removeIfPresent(PropertySource propertySource) {
    _sources.remove(propertySource);
  }

  /// Inserts the given [propertySource] at the specified [index], ensuring
  /// that any existing instance of the same source is removed first.
  ///
  /// This guarantees consistent ordering semantics, preventing the same
  /// source from appearing in multiple positions.
  ///
  /// Used internally by [addBefore] and [addAfter].
  void _addAtIndex(int index, PropertySource propertySource) {
    _removeIfPresent(propertySource);
    _sources.insert(index, propertySource);
  }

  /// Ensures that a property source with the given [name] exists and returns
  /// its index.
  ///
  /// Throws:
  /// - [IllegalArgumentException] if no property source with the specified
  ///   name is present.
  ///
  /// Used internally by operations that require a guaranteed target, such
  /// as `addBefore`, `addAfter`, and `replace`.
  int _assertPresentAndGetIndex(String name) {
    // First try to find the source by name
    int index = _getIndex(name);
    if (index == -1) {
      throw IllegalArgumentException("PropertySource named '$name' does not exist");
    }

    return index;
  }
}