import '../../lang.dart';
import 'package:meta/meta.dart';

/// {@template order_comparator}
/// A comparator that sorts objects based on the [Ordered] and [PriorityOrdered] interfaces.
///
/// This comparator is used throughout the Jetleaf framework to impose deterministic,
/// precedence-based ordering on various components, processors, and infrastructure elements.
///
/// ### Ordering Hierarchy:
/// 1. **PriorityOrdered**: Highest precedence, processed first
/// 2. **Ordered**: Standard ordering based on order value
/// 3. **Default**: Objects without ordering use [Ordered.LOWEST_PRECEDENCE]
///
/// ### Key Features:
/// - **Deterministic Sorting**: Consistent ordering across application runs
/// - **Flexible Order Sources**: Support for direct ordering and source providers
/// - **Framework Integration**: Used in pod processing, event handling, and configuration
/// - **Thread Safety**: Stateless design suitable for concurrent use
///
/// ### Basic Usage:
/// ```dart
/// final items = [ComponentA(), ComponentB(), ComponentC()];
/// OrderComparator.sortList(items);
/// 
/// // Components are now sorted by their order precedence
/// for (final component in items) {
///   print('${component.runtimeType}: ${OrderComparator.INSTANCE.getOrder(component)}');
/// }
/// ```
///
/// ### Advanced Usage with Source Provider:
/// ```dart
/// class MyOrderSourceProvider implements OrderSourceProvider {
///   @override
///   Object? getOrderSource(Object obj) {
///     // Provide alternative order metadata for objects
///     if (obj is MyComponent) {
///       return obj.getMetadata().order;
///     }
///     return null;
///   }
/// }
/// 
/// final comparator = OrderComparator.INSTANCE.withSourceProvider(MyOrderSourceProvider());
/// items.sort(comparator.compare);
/// ```
///
/// ### Order Resolution Process:
/// 1. Check if object implements [PriorityOrdered] (highest precedence)
/// 2. Check if object implements [Ordered]
/// 3. Use source provider if available for alternative order resolution
/// 4. Fall back to [Ordered.LOWEST_PRECEDENCE] if no order information found
///
/// See also:
/// - [Ordered] for the standard ordering interface
/// - [PriorityOrdered] for highest precedence ordering
/// - [OrderSourceProvider] for indirect order resolution
/// {@endtemplate}
class OrderComparator extends Comparator<Object> implements Comparable<Object> {
  /// {@template order_comparator.comparator_field}
  /// The underlying comparator implementation.
  /// 
  /// When a source provider is used, this field holds the configured comparator
  /// that incorporates the source provider logic for order resolution.
  /// {@endtemplate}
  Comparator<Object>? _comparator;

  /// {@template order_comparator.instance}
  /// Singleton instance of the [OrderComparator].
  ///
  /// This instance is used throughout the Jetleaf framework for consistent
  /// ordering behavior. It's thread-safe and can be shared across the application.
  ///
  /// ### Usage:
  /// ```dart
  /// // Use the singleton instance directly
  /// items.sort(OrderComparator.INSTANCE.compare);
  /// 
  /// // Or use the convenience methods
  /// OrderComparator.sortList(items);
  /// ```
  /// {@endtemplate}
  static final OrderComparator INSTANCE = OrderComparator();

  /// {@macro order_comparator}
  OrderComparator();

  /// {@template order_comparator.with_source}
  /// Returns a new comparator that uses the given [OrderSourceProvider]
  /// to determine order metadata indirectly from an associated source.
  ///
  /// This method enables advanced ordering scenarios where the order information
  /// is not directly available on the object but can be resolved through
  /// external metadata or relationships.
  ///
  /// ### Parameters:
  /// - [sourceProvider]: The provider that resolves order sources for objects
  ///
  /// ### Returns:
  /// A new [Comparator] that incorporates the source provider logic
  ///
  /// ### Example:
  /// ```dart
  /// class AnnotationOrderSourceProvider implements OrderSourceProvider {
  ///   @override
  ///   Object? getOrderSource(Object obj) {
  ///     if (obj is Class) {
  ///       final orderAnnotation = obj.getAnnotation<Order>();
  ///       return orderAnnotation?.value;
  ///     }
  ///     return null;
  ///   }
  /// }
  /// 
  /// final comparator = OrderComparator.INSTANCE.withSource(
  ///   AnnotationOrderSourceProvider()
  /// );
  /// 
  /// // Now classes can be sorted by their @Order annotation values
  /// classes.sort(comparator);
  /// ```
  /// {@endtemplate}
  Comparator<Object> withSource(OrderSourceProvider sourceProvider) {
    return Comparator.comparingWith<Object, int>((o1) => doCompare(o1, null, sourceProvider), Comparator.naturalOrder());
  }

  /// {@template order_comparator.with_source_provider}
  /// Configures this comparator instance to use the given [OrderSourceProvider].
  ///
  /// Unlike [withSource], this method modifies the current instance rather than
  /// creating a new comparator. The source provider will be used for all
  /// subsequent comparisons made through this instance.
  ///
  /// ### Parameters:
  /// - [sourceProvider]: The provider that resolves order sources for objects
  ///
  /// ### Returns:
  /// This comparator instance for method chaining
  ///
  /// ### Example:
  /// ```dart
  /// final comparator = OrderComparator()
  ///   .withSourceProvider(MyOrderSourceProvider());
  /// 
  /// // Now uses the source provider for all comparisons
  /// items.sort(comparator.compare);
  /// ```
  /// {@endtemplate}
  Comparable<Object> withSourceProvider(OrderSourceProvider sourceProvider) {
    _comparator = Comparator.comparingWith<Object, int>((o1) => doCompare(o1, null, sourceProvider), Comparator.naturalOrder());
    return this;
  }
    
  /// {@template order_comparator.compare}
  /// Compares two objects for order.
  ///
  /// This is the core comparison method that implements the [Comparator] interface.
  /// It determines the relative ordering of two objects based on their
  /// order precedence as defined by the Jetleaf ordering system.
  ///
  /// ### Parameters:
  /// - [o1]: The first object to compare
  /// - [o2]: The second object to compare
  ///
  /// ### Returns:
  /// - A negative integer if [o1] should come before [o2]
  /// - A positive integer if [o2] should come before [o1]
  /// - Zero if [o1] and [o2] have the same order precedence
  ///
  /// ### Comparison Logic:
  /// 1. [PriorityOrdered] objects always come before non-priority objects
  /// 2. Within the same priority class, objects are ordered by their order value
  /// 3. Lower order values indicate higher precedence
  ///
  /// ### Example:
  /// ```dart
  /// final comp1 = MyComponent()..getOrder = () => 1;
  /// final comp2 = MyComponent()..getOrder = () => 2;
  /// 
  /// final result = OrderComparator.INSTANCE.compare(comp1, comp2);
  /// print(result); // -1 (comp1 comes before comp2)
  /// ```
  /// {@endtemplate}
  @override
  int compare(Object o1, Object o2) => whenCompared(o1, o2);

  /// {@template order_comparator.when_compared}
  /// Compares two objects using order metadata.
  ///
  /// This method provides the actual comparison logic, handling both the
  /// standard comparison and the source provider-based comparison when configured.
  ///
  /// ### Parameters:
  /// - [o1]: The first object to compare, may be null
  /// - [o2]: The second object to compare, may be null
  ///
  /// ### Returns:
  /// - `-1` if [o1] should come before [o2]
  /// - `1` if [o2] should come before [o1]
  /// - `0` if order is equal or both objects are null
  ///
  /// ### Null Handling:
  /// - Null objects are treated as having the lowest possible precedence
  /// - A non-null object always comes before a null object
  /// - Two null objects are considered equal
  /// {@endtemplate}
  int whenCompared(Object? o1, Object? o2) {
    if (_comparator != null && o1 != null && o2 != null) {
      return _comparator!.compare(o1, o2);
    }
    return doCompare(o1, o2);
  }

  /// {@template order_comparator.do_compare}
  /// Internal comparison implementation that handles the core ordering logic.
  ///
  /// This protected method implements the actual precedence rules without
  /// the source provider wrapper. It's used internally and can be overridden
  /// by subclasses for custom ordering behavior.
  ///
  /// ### Parameters:
  /// - [o1]: The first object to compare
  /// - [o2]: The second object to compare
  /// - [provider]: Optional order source provider for indirect order resolution
  ///
  /// ### Returns:
  /// The comparison result following the standard precedence rules
  ///
  /// ### Implementation Details:
  /// ```dart
  /// // PriorityOrdered takes absolute precedence
  /// if (o1 is PriorityOrdered && o2 is! PriorityOrdered) return -1;
  /// if (o2 is PriorityOrdered && o1 is! PriorityOrdered) return 1;
  /// 
  /// // Then compare by order value
  /// final order1 = getOrder(o1, provider);
  /// final order2 = getOrder(o2, provider);
  /// return order1.compareTo(order2);
  /// ```
  /// {@endtemplate}
  @protected
  int doCompare(Object? o1, Object? o2, [OrderSourceProvider? provider]) {
    final p1 = o1 is PriorityOrdered;
    final p2 = o2 is PriorityOrdered;

    if (p1 && !p2) return -1;
    if (p2 && !p1) return 1;

    final i1 = getOrder(o1, provider);
    final i2 = getOrder(o2, provider);
    return i1.compareTo(i2);
  }

  /// {@template order_comparator.get_order}
  /// Resolves the order value of the given object.
  ///
  /// This method attempts to determine the order value through multiple strategies:
  /// 1. Direct inspection if the object implements [Ordered]
  /// 2. Using the provided [provider] for indirect order resolution
  /// 3. Fallback to default ordering behavior
  ///
  /// ### Parameters:
  /// - [obj]: The object to resolve order for
  /// - [provider]: Optional order source provider for indirect resolution
  ///
  /// ### Returns:
  /// The resolved order value as an integer
  ///
  /// ### Resolution Process:
  /// 1. If a provider is given, use it to find order sources
  /// 2. If multiple sources are found (Iterable), use the first valid one
  /// 3. Fall back to direct order inspection
  /// 4. Default to [Ordered.LOWEST_PRECEDENCE] if no order information found
  /// {@endtemplate}
  int getOrder(Object? obj, OrderSourceProvider? provider) {
    int? order;
    if (obj != null && provider != null) {
      final source = provider.getOrderSource(obj);
      if (source != null) {
        if (source is Iterable) {
          for (final s in source) {
            order = doGetOrder(s);
            if (order != null) break;
          }
        } else {
          order = doGetOrder(source);
        }
      }
    }
    return order ?? doGet(obj);
  }

  /// {@template order_comparator.do_get}
  /// Internal method to resolve order value with fallback handling.
  ///
  /// This protected method provides the final fallback for order resolution
  /// when no specific order information is found through other means.
  ///
  /// ### Parameters:
  /// - [obj]: The object to resolve order for
  ///
  /// ### Returns:
  /// The resolved order value, never null
  /// {@endtemplate}
  @protected
  int doGet(Object? obj) => doGetOrder(obj) ?? Ordered.LOWEST_PRECEDENCE;

  /// {@template order_comparator.do_get_order}
  /// Internal method to extract order value from various source types.
  ///
  /// This protected method handles the actual extraction of order values
  /// from different types of order sources.
  ///
  /// ### Supported Source Types:
  /// - [Ordered] interface implementations
  /// - Raw integer values
  /// - Other types return null (handled by fallback)
  ///
  /// ### Parameters:
  /// - [obj]: The order source object to extract value from
  ///
  /// ### Returns:
  /// The extracted order value, or null if not supported
  /// {@endtemplate}
  @protected
  int? doGetOrder(Object? obj) {
    if (obj is Ordered) {
      return obj.getOrder();
    }

    if (obj is int) {
      return obj;
    }

    return null;
  }

  /// {@template order_comparator.get_priority}
  /// Optionally override this to expose a numeric "priority" classification.
  ///
  /// This method provides a hook for subclasses to implement custom priority
  /// resolution logic. By default, it returns `null` indicating that standard
  /// ordering should be used.
  ///
  /// ### Parameters:
  /// - [obj]: The object to determine priority for
  ///
  /// ### Returns:
  /// The priority value, or null if not applicable
  ///
  /// ### Usage in Subclasses:
  /// ```dart
  /// class CustomOrderComparator extends OrderComparator {
  ///   @override
  ///   int? getPriority(Object obj) {
  ///     if (obj is MyComponent) {
  ///       return obj.getCustomPriority();
  ///     }
  ///     return super.getPriority(obj);
  ///   }
  /// }
  /// ```
  /// {@endtemplate}
  int? getPriority(Object obj) => null;

  /// {@template order_comparator.sort_list}
  /// Sorts the given [list] using this comparator.
  ///
  /// This static convenience method provides an easy way to sort lists
  /// using the standard Jetleaf ordering rules.
  ///
  /// ### Parameters:
  /// - [list]: The list to sort in-place
  ///
  /// ### Optimization:
  /// - No-op for lists with 0 or 1 elements
  /// - Uses the singleton [INSTANCE] for consistent ordering
  ///
  /// ### Example:
  /// ```dart
  /// final processors = [
  ///   HighPriorityProcessor(), // implements PriorityOrdered
  ///   LowPriorityProcessor(),  // implements Ordered with value 100
  ///   MediumPriorityProcessor() // implements Ordered with value 50
  /// ];
  /// 
  /// OrderComparator.sortList(processors);
  /// 
  /// // Processors are now sorted: HighPriority, MediumPriority, LowPriority
  /// for (final processor in processors) {
  ///   processor.process();
  /// }
  /// ```
  /// {@endtemplate}
  static void sortList(List<Object> list) {
    if (list.length > 1) {
      list.sort(INSTANCE.compare);
    }
  }

  /// {@template order_comparator.sort_array}
  /// Alias for [sortList].
  ///
  /// Provided for API consistency with other frameworks and legacy code.
  /// Prefer [sortList] for new code.
  /// {@endtemplate}
  static void sortArray(List<Object> array) => sortList(array);

  /// {@template order_comparator.sort_if_necessary}
  /// Sorts the given [value] if it's a `List<Object>`.
  ///
  /// This method provides safe sorting that only operates on compatible types.
  /// It's useful in scenarios where you're not sure if a value needs sorting
  /// or is even sortable.
  ///
  /// ### Parameters:
  /// - [value]: The value to potentially sort
  ///
  /// ### Behavior:
  /// - If [value] is a `List<Object>`, sorts it in-place
  /// - For any other type, does nothing (safe no-op)
  ///
  /// ### Example:
  /// ```dart
  /// void configureProcessors(Object processors) {
  ///   // Safely sort if it's a list, otherwise ignore
  ///   OrderComparator.sortIfNecessary(processors);
  /// }
  /// 
  /// // Both usages are safe
  /// configureProcessors([processor1, processor2]);
  /// configureProcessors('not-a-list'); // safely ignored
  /// ```
  /// {@endtemplate}
  static void sortIfNecessary(Object? value) {
    if (value is List<Object>) {
      sortList(value);
    }
  }

  /// {@template order_comparator.compare_to}
  /// Allows this comparator to be compared with other objects.
  ///
  /// This implementation enables the comparator to be used in sorted
  /// collections or other comparison contexts.
  ///
  /// ### Parameters:
  /// - [other]: The object to compare this comparator to
  ///
  /// ### Returns:
  /// Standard comparison result following the same rules as [compare]
  /// {@endtemplate}
  @override
  int compareTo(Object other) => _comparator?.compare(this, other) ?? compare(this, other);
}