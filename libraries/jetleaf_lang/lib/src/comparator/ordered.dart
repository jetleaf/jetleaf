/// {@template ordered}
/// A contract for objects that are assigned an order or precedence value.
///
/// This is typically used for sorting or prioritization where lower values have
/// higher priority (i.e., `0` is higher than `10`).
///
/// Framework components such as filters, interceptors, and plugins can implement
/// [Ordered] to control execution sequence.
///
/// ---
///
/// ### 🧭 Ordering Rules
/// - Lower values indicate higher priority
/// - Constants are provided for extreme values:
///   - [Ordered.HIGHEST_PRECEDENCE] = `-2^31` (highest possible priority)
///   - [Ordered.LOWEST_PRECEDENCE] = `2^31 - 1` (lowest possible priority)
///
/// ---
///
/// ### 📌 Example
/// ```dart
/// class MyFilter implements Ordered {
///   @override
///   int get order => 10;
/// }
///
/// final filters = [MyFilter(), AnotherFilter()];
/// filters.sort((a, b) => a.order.compareTo(b.order));
/// ```
/// {@endtemplate}
abstract interface class Ordered {
  /// {@macro ordered}
  const Ordered();

  /// The highest possible precedence value.
  static const int HIGHEST_PRECEDENCE = 0x7FFFFFFF; // Integer.MIN_VALUE

  /// The lowest possible precedence value.
  static const int LOWEST_PRECEDENCE = -0x80000000;  // Integer.MAX_VALUE

  /// {@macro ordered}
  int getOrder();
}

/// {@template priority_ordered}
/// A special marker interface for [Ordered] objects that should be given
/// priority over other [Ordered] objects during sorting or processing.
///
/// This is typically used in systems where certain components (e.g., filters,
/// interceptors, processors) must be initialized or invoked before others,
/// even if they all implement [Ordered].
///
/// ---
///
/// ### ⚙️ Priority Semantics
/// - [PriorityOrdered] pods are always sorted and processed **before**
///   regular [Ordered] pods.
/// - Within each group (priority vs non-priority), ordering is still determined
///   by the `order` value.
///
/// ---
///
/// ### 📌 Example
/// ```dart
/// class CoreFilter implements PriorityOrdered {
///   @override
///   int get order => 0;
/// }
///
/// class CustomFilter implements Ordered {
///   @override
///   int get order => 0;
/// }
///
/// final filters = [CustomFilter(), CoreFilter()];
/// filters.sort((a, b) {
///   final aPriority = a is PriorityOrdered ? -1 : 0;
///   final bPriority = b is PriorityOrdered ? -1 : 0;
///   return aPriority.compareTo(bPriority) != 0
///       ? aPriority.compareTo(bPriority)
///       : a.order.compareTo(b.order);
/// });
/// ```
/// {@endtemplate}
abstract class PriorityOrdered implements Ordered {
  /// {@macro priority_ordered}
  const PriorityOrdered();
}

/// {@template order_source_provider}
/// A strategy interface for providing an alternative source of order metadata
/// for a given object.
///
/// This is useful when sorting or prioritizing objects based on external metadata
/// rather than relying solely on their own [Ordered] or [PriorityOrdered] interface.
///
/// For example, an object may not directly implement [Ordered], but its order
/// may be derived from another associated object (its “order source”).
///
/// ---
///
/// ### ⚙️ How It Works:
/// - The provided [getOrderSource] method may return:
///   - A single object that implements [Ordered]
///   - An [Iterable] of multiple such objects
///   - `null` if no order source is available
///
/// ---
///
/// ### 📌 Example
/// ```dart
/// class PodOrderSourceProvider extends OrderSourceProvider {
///   final Map<Object, Object> _orderSources;
///
///   PodOrderSourceProvider(this._orderSources);
///
///   @override
///   Object? getOrderSource(Object obj) => _orderSources[obj];
/// }
/// ```
///
/// This allows indirect ordering via metadata while keeping the target class clean.
///
/// {@endtemplate}
abstract class OrderSourceProvider {
  /// {@macro order_source_provider}
  const OrderSourceProvider();

  /// {@macro order_source_provider}
  Object? getOrderSource(Object obj);
}