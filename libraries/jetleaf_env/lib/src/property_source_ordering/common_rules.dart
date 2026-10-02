import 'package:jetleaf_lang/lang.dart';

import '../property_source/property_source.dart';
import 'property_source_ordering_rule.dart';

/// {@template before_rule}
/// Represents a **reordering rule** for property sources that ensures
/// one source appears **before** another within a list of [PropertySource]s.
///
/// This class is typically used with a property source container, such as
/// [MutablePropertySources], to dynamically reorder sources according to
/// user-defined precedence rules.
///
/// ### Usage
/// ```dart
/// final rule = BeforeRule('env', 'defaults');
/// final reordered = rule.apply(sourcesList);
/// ```
///
/// In the example above:
/// - The source named `'env'` will be moved to appear before the source named `'defaults'`.
/// - If either source is not found, the original order is preserved.
/// {@endtemplate}
class BeforeRule implements PropertySourceOrderRule {
  /// The name of the property source that should appear **before** another.
  ///
  /// This field is required and determines which source is prioritized
  /// in the ordering.
  final String before;

  /// The name of the property source that should appear **after** [before].
  ///
  /// This field is required and represents the reference source that
  /// [before] will be moved ahead of during reordering.
  final String after;

  /// {@macro before_rule}
  ///
  /// Creates a new rule specifying that [before] must appear prior to [after].
  /// Both [before] and [after] must be non-null strings corresponding to
  /// existing property source names.
  const BeforeRule(this.before, this.after);

  @override
  List<PropertySource> apply(List<PropertySource> sources) {
    final list = List<PropertySource>.of(sources);

    final aIndex = list.indexWhere((s) => s.getName() == before);
    final bIndex = list.indexWhere((s) => s.getName() == after);

    if (aIndex == -1 || bIndex == -1) return list;

    // If already correct, keep it
    if (aIndex < bIndex) return list;

    // Move "before" to the correct position
    final a = list.removeAt(aIndex);
    list.insert(bIndex, a);

    return list;
  }
}

/// {@template priority_rule}
/// A **reordering rule** for property sources based on explicit numeric priorities.
///
/// Each property source name can be assigned an integer priority.  
/// - **Lower numbers indicate higher precedence**.  
/// - Sources not listed in [priorities] default to a low priority (e.g., 1000) and appear later.
///
/// This rule is typically applied to a list of [PropertySource]s to produce a
/// deterministic ordering according to user-defined priorities.
///
/// ### Example
/// ```dart
/// final rule = PriorityRule({'env': 1, 'defaults': 10});
/// final reordered = rule.apply(sourcesList);
/// ```
///
/// In this example, `'env'` will be moved before `'defaults'` regardless of
/// their original positions in the list.
/// {@endtemplate}
class PriorityRule implements PropertySourceOrderRule {
  /// A mapping from property source names to their integer priority.
  ///
  /// - Lower number → higher precedence  
  /// - Unlisted names default to a low priority (appear last)
  final Map<String, int> priorities;

  /// {@macro priority_rule}
  ///
  /// Creates a new rule using the given [priorities] map.
  /// Every entry in the map represents a property source name and its desired
  /// precedence order.
  const PriorityRule(this.priorities);

  @override
  List<PropertySource> apply(List<PropertySource> sources) {
    return sources.toList()
      ..sort((a, b) {
        final pa = priorities[a.getName()] ?? 1000;
        final pb = priorities[b.getName()] ?? 1000;
        return pa.compareTo(pb);
      });
  }
}

/// {@template alphabetical_rule}
/// A **property source ordering rule** that sorts sources alphabetically by name.
///
/// This rule can be applied to a list of [PropertySource] instances to produce
/// a predictable, lexicographical ordering based on each source's name.
///
/// ### Example
/// ```dart
/// final rule = AlphabeticalRule();
/// final reordered = rule.apply(sourcesList);
/// ```
///
/// In this example, all property sources in `sourcesList` will be reordered
/// alphabetically by their names, regardless of their original positions.
/// {@endtemplate}
class AlphabeticalRule implements PropertySourceOrderRule {
  /// {@macro alphabetical_rule}
  const AlphabeticalRule();

  @override
  List<PropertySource> apply(List<PropertySource> sources) {
    return sources.toList()
      ..sort((a, b) => a.getName().compareTo(b.getName()));
  }
}

/// {@template comparator_rule}
/// A **property source ordering rule** that sorts sources using a custom [OrderComparator].
///
/// This rule allows flexible, user-defined sorting logic for [PropertySource] instances.
/// The [comparator] defines how two sources are compared and determines their relative order.
///
/// ### Example
/// ```dart
/// final comparator = MyCustomComparator();
/// final rule = ComparatorRule(comparator);
/// final reordered = rule.apply(sourcesList);
/// ```
///
/// The `reordered` list will be sorted according to the logic implemented in `comparator`.
/// {@endtemplate}
class ComparatorRule implements PropertySourceOrderRule {
  /// The comparator used to define custom ordering logic.
  final OrderComparator comparator;

  /// {@macro comparator_rule}
  const ComparatorRule(this.comparator);

  @override
  List<PropertySource> apply(List<PropertySource> sources) {
    return sources.toList()..sort(comparator.compare);
  }
}