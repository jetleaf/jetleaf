import 'package:jetleaf_lang/lang.dart';

import 'listable_property_source.dart';
import 'property_source.dart';

/// {@template composite_property_source}
/// A composite implementation of [ListablePropertySource] that aggregates multiple [PropertySource] instances.
///
/// This class allows you to group multiple property sources under a single logical name.
/// When resolving properties, the sources are checked in the order they were added.
///
/// Example:
/// ```dart
/// var composite = CompositePropertySource('applicationConfig');
/// composite.addPropertySource(MapPropertySource('map1', {'foo': 'bar'}));
/// composite.addPropertySource(SystemEnvironmentPropertySource('env'));
/// var value = composite.getProperty('foo'); // searches map1 first, then env
/// ```
/// {@endtemplate}
class CompositePropertySource extends ListablePropertySource<Object> {
  /// The internal ordered set of property sources that make up this composite.
  ///
  /// Each [PropertySource] in this set contributes key–value pairs to the
  /// composite lookup chain. Ordering matters:
  ///
  /// - Earlier entries have **higher lookup precedence**.
  /// - Later entries act as fallback sources.
  ///
  /// A [Set] is used to ensure that each property source is included at most
  /// once, but the composite methods maintain ordering semantics by recreating
  /// or re-adding elements as needed (e.g. via [addFirstPropertySource]).
  ///
  /// This field is internal and should not be accessed or modified directly.
  final Set<PropertySource<dynamic>> _propertySources = {};

  /// {@macro composite_property_source}
  CompositePropertySource(super.name) : super.named();

  @override
  Object? getProperty(String name) {
    for (final propertySource in _propertySources) {
      final candidate = propertySource.getProperty(name);
      if (candidate != null) {
        return candidate;
      }
    }

    return null;
  }

  @override
  bool containsProperty(String name) {
    for (final propertySource in _propertySources) {
      if (propertySource.containsProperty(name)) {
        return true;
      }
    }
    
    return false;
  }

  @override
  List<String> getPropertyNames() {
    final namesList = ArrayList<List<String>>.withCapacity(_propertySources.length);
    for (final propertySource in _propertySources) {
      if (propertySource is! ListablePropertySource) {
        throw IllegalStateException("Failed to enumerate property names due to non-enumerable property source: $propertySource");
      }

      List<String> names = propertySource.getPropertyNames();
      namesList.add(names);
    }

    final allNames = HashSet<String>();
    for (var names in namesList) {
      allNames.addAll(names);
    }

    return allNames.toList();
  }

  /// Adds the given [propertySource] to the **end** of the composite chain.
  ///
  /// When resolving properties, the property sources are queried in order.
  /// Therefore, a source added via this method has **lower precedence** than
  /// any source previously added.
  ///
  /// This is appropriate when the new source represents fallback configuration,
  /// optional overrides, or system/environment defaults.
  ///
  /// If the source already exists in the set, it will not be duplicated.
  void addPropertySource(PropertySource propertySource) {
    _propertySources.add(propertySource);
  }

  /// Adds the given [propertySource] to the **start** of the composite chain.
  ///
  /// This method ensures that the new source receives the **highest precedence**
  /// when resolving properties—its values are checked before all others.
  ///
  /// Internally, the existing sources are temporarily copied, the composite
  /// is cleared, and the new source is inserted first, followed by the
  /// previously present sources in their original order.
  ///
  /// Use this method when a new configuration source must override existing
  /// entries, such as:
  /// - in-memory overrides
  /// - command-line arguments
  /// - profile-specific configuration
  void addFirstPropertySource(PropertySource propertySource) {
    final existing = ArrayList<PropertySource>.from(_propertySources);
    _propertySources.clear();
    _propertySources.add(propertySource);
    _propertySources.addAll(existing);
  }

  /// Returns a snapshot list of all [PropertySource] instances contained
  /// within this composite.
  ///
  /// The returned list reflects the current ordering of the composite, where
  /// earlier entries have higher lookup precedence.
  ///
  /// ### Important:
  /// Modifying the returned list **does not** affect the internal composite.
  /// This method provides read-only external visibility without exposing the
  /// mutable internal state.
  ///
  /// Useful for:
  /// - diagnostics / logging
  /// - property source enumeration
  /// - unit testing and verification
  List<PropertySource> getPropertySources() => _propertySources.toList();

  @override
  String toString() => "CompositePropertySource {name='$getName()', propertySources=${_propertySources.toList()}";
}