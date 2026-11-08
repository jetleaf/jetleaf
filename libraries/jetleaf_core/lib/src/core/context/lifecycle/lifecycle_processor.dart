/// {@template lifecycle_processor}
/// Defines a contract for components that participate in the application lifecycle.
///
/// A [LifecycleProcessor] allows objects to hook into two major phases:
/// - **Refresh phase** ([onRefresh]) — invoked when the application context
///   is refreshed or reloaded. Components can reinitialize resources here.
/// - **Close phase** ([onClose]) — invoked during application shutdown,
///   giving components a chance to release resources asynchronously.
///
/// ### Example
/// ```dart
/// class DatabaseLifecycleProcessor extends LifecycleProcessor {
///   @override
///   void onRefresh() {
///     print("Reconnecting to database...");
///     // Initialize or refresh the database connection
///   }
///
///   @override
///   Future<void> onClose() async {
///     print("Closing database connection...");
///     // Close the connection asynchronously
///     await Future.delayed(Duration(milliseconds: 500));
///   }
/// }
///
/// void main() async {
///   final processor = DatabaseLifecycleProcessor();
///   processor.onRefresh();
///   await processor.onClose();
/// }
/// ```
/// {@endtemplate}
abstract interface class LifecycleProcessor {
  /// {@template lifecycle_processor_on_refresh}
  /// Called when the application context is refreshed.
  ///
  /// Implement this method to reinitialize resources, reload configurations,
  /// or perform setup tasks needed after a refresh.
  ///
  /// ### Example
  /// ```dart
  /// class CacheLifecycleProcessor extends LifecycleProcessor {
  ///   @override
  ///   Future<void> onRefresh() {
  ///     print("Refreshing cache...");
  ///   }
  ///
  ///   @override
  ///   Future<void> onClose() async {}
  /// }
  /// ```
  /// {@endtemplate}
  Future<void> onRefresh();

  /// {@template lifecycle_processor_on_close}
  /// Called when the application is shutting down.
  ///
  /// Implement this method to release resources, close connections,
  /// or perform asynchronous cleanup tasks.
  ///
  /// ### Example
  /// ```dart
  /// class FileLifecycleProcessor extends LifecycleProcessor {
  ///   @override
  ///   void onRefresh() {}
  ///
  ///   @override
  ///   Future<void> onClose() async {
  ///     print("Closing file streams...");
  ///     await Future.delayed(Duration(milliseconds: 200));
  ///   }
  /// }
  /// ```
  /// {@endtemplate}
  Future<void> onClose();
}