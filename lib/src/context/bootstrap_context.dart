// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';

import 'bootstrap_context_impl.dart';

/// {@template bootstrap_context}
/// A context used during JetLeaf's bootstrapping phase for accessing and managing
/// lazily-created instances by their reflected [Class] types.
///
/// Unlike a full [ApplicationContext], the [BootstrapContext] is lightweight,
/// type-safe, and used primarily during the initialization of the application,
/// such as within `ApplicationContextInitializer` or `ApplicationRunner`.
///
/// Supports lazy creation, fallback supply, and registration checks.
///
/// Example:
/// ```dart
/// class CustomInitializer implements ApplicationContextInitializer {
///   @override
///   void initialize(ConfigurableApplicationContext context) {
///     final BootstrapContext bootstrap = context.getBootstrapContext();
///
///     final Logger logger = bootstrap.getOrElseSupply(
///       Class<Logger>(),
///       () => Logger('MyApp')
///     );
///   }
/// }
/// ```
/// {@endtemplate}
abstract interface class BootstrapContext {
  /// {@template bootstrap_context_get}
  /// Returns an instance of the given [type] if it has been registered in
  /// the context. The instance will be lazily created on first access.
  ///
  /// Throws [IllegalStateException] if the [type] is not registered.
  ///
  /// Example:
  /// ```dart
  /// final Logger logger = context.get(Class<Logger>());
  /// 
  /// final Logger logger = context.get(
  ///   Class<Logger>(),
  ///   supply: () => Logger('Generated')
  /// );
  /// 
  /// final Logger logger = context.get(
  ///   Class<Logger>(),
  ///   orElse: Logger('Generated')
  /// );
  /// ```
  /// {@endtemplate}
  T get<T>(Class<T> type, {T? orElse, Supplier<T>? orSupply});

  /// {@template bootstrap_context_get_or_else_throw}
  /// Returns an instance of the given [type] if registered.
  ///
  /// If not registered, throws the exception provided by [exceptionSupplier].
  ///
  /// Example:
  /// ```dart
  /// final Logger logger = context.getOrElseThrow(
  ///   Class<Logger>(),
  ///   () => ConfigurationException('Logger not found')
  /// );
  /// ```
  /// {@endtemplate}
  T getOrThrow<T, X extends Throwable>(Class<T> type, Supplier<X> exceptionSupplier);

  /// {@template bootstrap_context_is_registered}
  /// Checks whether a [type] has already been registered in this context.
  ///
  /// This is useful for conditionally initializing fallbacks or skipping logic.
  ///
  /// Example:
  /// ```dart
  /// if (!context.isClassRegistered(Class<Logger>())) {
  ///   // Register or provide fallback
  /// }
  /// ```
  /// {@endtemplate}
  bool isClassRegistered<T>(Class<T> type);

  /// Closes the bootstrap context by firing a [BootstrapContextClosedEvent].
  ///
  /// This method should be called once the [ConfigurableApplicationContext] is ready.
  ///
  /// Example:
  /// ```dart
  /// bootstrapContext.close(applicationContext);
  /// ```
	void close(ConfigurableApplicationContext applicationContext);

  /// {@template bootstrap_context_get_application_class}
  /// Returns the application class registered in this context.
  /// 
  /// This is the application class that was registered in the bootstrap context.
  /// Mostly, it is the class used to bootstrap the application.
  /// 
  /// Example:
  /// ```dart
  /// final bootstrapContext = ConfigurableBootstrapContext();
  /// bootstrapContext.setApplicationClass(Class.of(MyApplication()));
  /// final applicationClass = bootstrapContext.getApplicationClass();
  /// ```
  /// {@endtemplate}
  Class<Object> getApplicationClass();

  /// {@template bootstrap_context_set_application_class}
  /// Sets the application class in this context.
  /// 
  /// This is the application class that was registered in the bootstrap context.
  /// Mostly, it is the class used to bootstrap the application.
  /// 
  /// Example:
  /// ```dart
  /// final bootstrapContext = ConfigurableBootstrapContext();
  /// bootstrapContext.setApplicationClass(Class.of(MyApplication()));
  /// final applicationClass = bootstrapContext.getApplicationClass();
  /// ```
  /// {@endtemplate}
  void setApplicationClass(Class<Object> applicationClass);
}

/// {@template bootstrap_registry}
/// A registry interface for bootstrapping components during early
/// phases of application startup.
///
/// Components can be registered as suppliers which are resolved later via
/// the [BootstrapContext]. This allows for flexible and lazy initialization
/// of pods.
///
/// Suppliers can be registered with different scopes:
/// - [ScopeType.SINGLETON] (default)
/// - [ScopeType.PROTOTYPE]
///
/// Example:
/// ```dart
/// registry.register(
///   Class.of(Logger),
///   InstanceSupplier.from(() => Logger('bootstrap')),
/// );
/// ```
/// {@endtemplate}
abstract class BootstrapRegistry {
  /// {@template bootstrap_registry_register}
  /// Register a supplier for a type [T] into the registry.
  ///
  /// If the type is already registered and the previous one was not a
  /// singleton or has not been resolved yet, it will be replaced.
  ///
  /// Example:
  /// ```dart
  /// registry.register(
  ///   Class.of(MyService),
  ///   InstanceSupplier.from(() => MyService()),
  /// );
  /// ```
  /// {@endtemplate}
  void register<T>(Class<T> type, BootstrapInstanceSupplier<T> supplier);

  /// {@template bootstrap_registry_is_registered}
  /// Checks whether a supplier for type [T] is already registered.
  ///
  /// Example:
  /// ```dart
  /// if (!registry.isRegistered(Class.of(MyService))) {
  ///   // Safe to register
  /// }
  /// ```
  /// {@endtemplate}
  bool isRegistered<T>(Class<T> type);

  /// {@template bootstrap_registry_get_registered_supplier}
  /// Returns the registered [BootstrapInstanceSupplier] for a type [T],
  /// or `null` if not registered.
  ///
  /// Example:
  /// ```dart
  /// final supplier = registry.getSupplier(Class.of(MyService));
  /// ```
  /// {@endtemplate}
  BootstrapInstanceSupplier<T>? getSupplier<T>(Class<T> type);

  /// {@template bootstrap_registry_add_close_listener}
  /// Adds an [ApplicationEventListener] that is called when the [BootstrapContext]
  /// is closed and the [ApplicationContext] has been fully prepared.
  ///
  /// Useful for cleanup or post-configuration logic.
  ///
  /// Example:
  /// ```dart
  /// registry.addCloseListener((event) {
  ///   print("Context closed: ${event.applicationContext}");
  /// });
  /// ```
  /// {@endtemplate}
  void addCloseListener(ApplicationEventListener<BootstrapContextClosedEvent> listener);
}

/// {@template instance_supplier}
/// A supplier that can create instances based on a [BootstrapContext],
/// with optional scoping support.
///
/// This abstraction supports two main use cases:
/// - Supplying constant instances via [of]
/// - Supplying dynamic instances via a factory [from]
///
/// The default scope is [ScopeType.SINGLETON].
///
/// Example:
/// ```dart
/// final supplier = InstanceSupplier.from(() => MyService());
/// final instance = supplier.get(context);
/// ```
/// {@endtemplate}
@Generic(BootstrapInstanceSupplier)
abstract class BootstrapInstanceSupplier<T> {
  /// {@macro instance_supplier}
  const BootstrapInstanceSupplier();

  /// Factory method used to create the instance.
  ///
  /// The [context] is typically provided by the framework during bootstrap.
  T get(BootstrapContext context);

  /// The scope of the supplied instance.
  ///
  /// Defaults to [ScopeType.SINGLETON].
  ScopeType get scope => ScopeType.SINGLETON;

  /// Returns a new [BootstrapInstanceSupplier] with a different scope.
  ///
  /// Example:
  /// ```dart
  /// final prototypeSupplier = supplier.withScope(ScopeType.PROTOTYPE);
  /// ```
  BootstrapInstanceSupplier<T> withScope(ScopeType newScope) {
    final parent = this;
    return _SIS<T>(parent, newScope);
  }

  /// Creates a supplier that always returns the same [instance].
  ///
  /// This supplier will use [SINGLETON] scope.
  static BootstrapInstanceSupplier<T> of<T>(T instance) => _CIS<T>(instance);

  /// Creates a supplier from a function that returns a new instance.
  ///
  /// Example:
  /// ```dart
  /// final supplier = InstanceSupplier.from(() => MyService());
  /// ```
  /// The scope defaults to [SINGLETON], but can be changed with [withScope].
  static BootstrapInstanceSupplier<T> from<T>(T Function() supplier) => _IS<T>(supplier);
}

/// Internal implementation that overrides the scope of another supplier.
class _SIS<T> implements BootstrapInstanceSupplier<T> {
  final BootstrapInstanceSupplier<T> _delegate;
  final ScopeType _customScope;

  /// Creates a new scoped supplier from the original delegate and a custom scope.
  const _SIS(this._delegate, this._customScope);

  @override
  T get(BootstrapContext context) => _delegate.get(context);

  @override
  ScopeType get scope => _customScope;

  @override
  BootstrapInstanceSupplier<T> withScope(ScopeType newScope) {
    final parent = this;
    return _SIS<T>(parent, newScope);
  }
}

/// Internal supplier that returns a constant instance every time.
class _CIS<T> implements BootstrapInstanceSupplier<T> {
  final T _instance;

  /// Creates a constant supplier that returns the same [_instance] every time.
  const _CIS(this._instance);

  @override
  T get(BootstrapContext context) => _instance;

  @override
  ScopeType get scope => ScopeType.SINGLETON;

  @override
  BootstrapInstanceSupplier<T> withScope(ScopeType newScope) {
    final parent = this;
    return _SIS<T>(parent, newScope);
  }
}

/// Internal supplier that calls a function each time to create a new instance.
class _IS<T> implements BootstrapInstanceSupplier<T> {
  final T Function() _supplier;

  /// Creates a new supplier from a function that provides the instance.
  const _IS(this._supplier);

  @override
  T get(BootstrapContext context) => _supplier.call();

  @override
  ScopeType get scope => ScopeType.SINGLETON;

  @override
  BootstrapInstanceSupplier<T> withScope(ScopeType newScope) {
    final parent = this;
    return _SIS<T>(parent, newScope);
  }
}

/// {@template bootstrap_registry_initializer}
/// Strategy interface used to programmatically register bootstrap instances
/// into a [BootstrapRegistry] before the application context is refreshed.
///
/// Implementations of this interface are typically used to pre-register
/// pods or resources (like loggers, metrics, or external connections)
/// that need to be available early in the application's lifecycle.
///
/// This is useful in scenarios where specific types or suppliers must be
/// initialized before the full application context is available.
///
/// ## Example:
/// ```dart
/// class MyRegistryInitializer implements BootstrapRegistryInitializer {
///   @override
///   void initialize(BootstrapRegistry registry) {
///     registry.register(MyService.classType, (ctx) => MyService());
///   }
/// }
/// ```
///
/// To use it, register the initializer before launching the application context,
/// or during your application bootstrap phase.
/// {@endtemplate}
abstract interface class BootstrapRegistryInitializer {
  /// {@macro bootstrap_registry_initializer}
  Future<void> initialize(BootstrapRegistry registry);
}

/// {@template configurable_bootstrap_context}
/// A configurable bootstrap context that acts as both a [BootstrapRegistry]
/// and a [BootstrapContext].
///
/// This interface is typically used internally during application startup
/// to allow registration and retrieval of bootstrapping dependencies.
/// 
/// Once bootstrapping is complete, it may be exposed as a read-only
/// [BootstrapContext] to consumers.
///
/// Example usage:
/// ```dart
/// final context = DefaultConfigurableBootstrapContext();
/// context.register(MyService, () => MyServiceImpl());
/// final service = context.get(MyService);
/// ```
/// {@endtemplate}
abstract interface class ConfigurableBootstrapContext extends BootstrapRegistry implements BootstrapContext {}