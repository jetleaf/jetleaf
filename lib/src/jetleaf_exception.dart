import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_lang/lang.dart';

/// {@template jetleaf_exception}
/// A [RuntimeException] thrown when the application context is considered
/// "abandoned" during startup or shutdown.
///
/// This typically indicates a failure or interruption during the
/// initialization or lifecycle process of the Jetleaf application context.
///
/// Use this exception to signal that the [ConfigurableApplicationContext]
/// is no longer valid and cannot continue.
///
/// ### Example
/// ```dart
/// if (context == null) {
///   throw JetleafException.nullable();
/// }
///
/// if (context.failed) {
///   throw JetleafException(context);
/// }
/// ```
/// {@endtemplate}
class JetleafException extends RuntimeException {
  /// The application context that was abandoned, if available.
  final ConfigurableApplicationContext? _applicationContext;

  /// {@macro jetleaf_exception}
  ///
  /// Creates a [JetleafException] with a reference to the abandoned
  /// [applicationContext].
  ///
  /// Use this when the context exists but is no longer valid, such as after
  /// a failed refresh or shutdown sequence.
  JetleafException(this._applicationContext) : super("Application context was abandoned");

  /// Returns the [ConfigurableApplicationContext] that was abandoned,
  /// or `null` if no context was ever created.
  ///
  /// ### Example
  /// ```dart
  /// try {
  ///   // startup logic...
  /// } on JetleafException catch (ex) {
  ///   final ctx = ex.getApplicationContext();
  ///   log.warn('Context abandoned: $ctx');
  /// }
  /// ```
  ConfigurableApplicationContext? getApplicationContext() => _applicationContext;
}