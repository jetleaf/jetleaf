import '../property_source/property_source.dart';

/// {@template property_source_order_rule}
/// Defines a user-supplied rule that determines the ordering of
/// [`PropertySource`] objects within Jetleaf’s configuration system.
///
/// `PropertySourceOrderRule` provides a flexible mechanism for altering,
/// prioritizing, or constraining the sequence in which property sources are
/// evaluated. This ordering impacts how configuration values are resolved,
/// especially when multiple sources define overlapping keys.
///
/// Implementations may express:
/// - strict ordering constraints (e.g., *source A must precede source B*),
/// - priority- or ranking-based positioning,
/// - dynamic sorting based on runtime conditions,
/// - conditional precedence (e.g., environment-specific ordering),
/// - fallback or override behavior for colliding configuration entries.
///
/// The rule is intentionally **composable**: multiple rules may be applied
/// sequentially by higher-level components such as
/// `PropertySourceOrderer` or `ConfigurationContext`.
///
/// ---
/// ## 💡 When Is This Used?
///
/// Jetleaf invokes ordering rules:
/// - when aggregating sources from different providers,  
/// - during configuration bootstrap,  
/// - when reloading configuration,  
/// - or when resolving layered configuration models (env → file → system).  
///
/// ---
/// ## ✨ Example
///
/// ```dart
/// class EnvFirstRule implements PropertySourceOrderRule {
///   @override
///   List<PropertySource> apply(List<PropertySource> sources) {
///     return [
///       ...sources.where((s) => s.name == 'environment'),
///       ...sources.where((s) => s.name != 'environment'),
///     ];
///   }
/// }
///
/// final ordered = EnvFirstRule().apply(propertySources);
/// ```
///
/// ---
/// ## 🔧 Design Notes
///
/// - Rules must be **pure**: the input list must **not be mutated**; instead,
///   a new ordered list is returned.
/// - Rules should be deterministic and consistent.
/// - Implementations may remove duplicates or synthesize new ordering
///   relationships, but should not create new sources or discard required ones
///   unless intentionally designed to.
/// - Ordering rules are a key extensibility point for advanced configuration
///   behavior such as multi-layer overrides, hierarchical property models,
///   or plugin-driven configuration enrichment.
///
/// ---
/// ## 🔗 Related Components
///
/// - [PropertySource] – A logical configuration key/value provider
///
/// {@endtemplate}
abstract interface class PropertySourceOrderRule {
  /// {@macro property_source_order_rule}
  const PropertySourceOrderRule();

  /// Applies this ordering rule to the provided list of [`PropertySource`]s.
  ///
  /// Implementations must treat [sources] as immutable input and return a
  /// **new list** representing the reordered sequence. The returned list may:
  ///
  /// - preserve the original order,  
  /// - apply custom sorting algorithms,  
  /// - enforce precedence or override relationships,  
  /// - remove or merge duplicates,  
  /// - or otherwise reorganize the collection.  
  ///
  /// ### Parameters
  /// - **sources** – The list of property sources to be ordered.  
  ///
  /// ### Returns
  /// A newly constructed list representing the result of applying this rule.
  ///
  /// ### Important
  /// This method must never modify the original [sources] list.
  List<PropertySource> apply(List<PropertySource> sources);
}