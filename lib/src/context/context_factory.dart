import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';

/// {@template application_context_factory}
/// A factory for creating Jetleaf application context and environment instances.
///
/// This abstraction allows you to define how a [ConfigurableApplicationContext]
/// and its [ConfigurableEnvironment] are created based on the application's
/// runtime type — such as `NONE`, `WEB`.
///
/// ### Default Usage
/// Jetleaf provides a default implementation via [ApplicationContextFactory.DEFAULT]
/// which uses [DefaultApplicationContextFactory].
///
/// ### Example:
/// ```dart
/// final factory = ApplicationContextFactory.DEFAULT;
/// final context = factory.create(ApplicationType.WEB);
/// ```
///
/// This interface enables integration points for customizing the environment
/// or context bootstrapping behavior, especially in advanced runtime scenarios.
/// {@endtemplate}
abstract class ApplicationContextFactory {
  /// {@macro application_context_factory}
  const ApplicationContextFactory();

  /// {@template application_context_factory_create}
  /// Creates a new [ConfigurableApplicationContext] for the given [applicationType].
  ///
  /// You can use this method to generate context trees appropriate to the environment:
  /// - `ApplicationType.NONE` → CLI or background apps
  /// - `ApplicationType.WEB` → HTTP-based web servers
  ///
  /// ### Example:
  /// ```dart
  /// final ctx = factory.create(ApplicationType.WEB);
  /// ctx.refresh();
  /// ```
  /// {@endtemplate}
  ConfigurableApplicationContext create(ApplicationType applicationType);

  /// Creates an [ApplicationContextFactory] that uses the provided [supplier]
  /// to construct the application context.
  ///
  /// This allows full control over context instantiation.
  ///
  /// ### Example:
  /// ```dart
  /// var factory = ApplicationContextFactory.of(() => MyCustomContext());
  /// var ctx = factory.create(ApplicationType.NONE);
  /// ```
  factory ApplicationContextFactory.of(Supplier<ConfigurableApplicationContext> supplier) = _ApplicationContextFactory;
}

/// {@template supplier_application_context_factory}
/// A concrete [ApplicationContextFactory] that uses a [Supplier]
/// to instantiate the application context.
///
/// This is a flexible and simple way to plug in user-defined contexts
/// without replacing the full factory system.
/// 
/// ### Example:
/// ```dart
/// var factory = ApplicationContextFactory.of(() => GenericApplicationContext());
/// var ctx = factory.create(ApplicationType.NONE);
/// ```
/// {@endtemplate}
class _ApplicationContextFactory extends ApplicationContextFactory {
  /// The supplier function used to provide a new [ConfigurableApplicationContext].
  final Supplier<ConfigurableApplicationContext> _supplier;

  /// {@macro supplier_application_context_factory}
  _ApplicationContextFactory(this._supplier);

  @override
  ConfigurableApplicationContext create(ApplicationType applicationType) => _supplier();
}