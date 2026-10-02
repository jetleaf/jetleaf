import 'package:jetleaf_core/annotation.dart';
import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';

import '../context/bootstrap_context.dart';
import 'run_listener.dart';

/// {@template jetleaf_lifecycle_run_listener}
/// A reflection-driven Jetleaf [ApplicationRunListener] that automatically
/// discovers and invokes lifecycle-annotated methods across all loaded types.
///
/// The [LifecycleRunListener] scans all runtime-visible methods annotated with
/// Jetleaf lifecycle annotations such as:
/// - [OnApplicationStarting]
/// - [OnApplicationStarted]
/// - [OnApplicationReady]
/// - [OnApplicationFailed]
/// - [OnEnvironmentPrepared]
/// - [OnContextPrepared]
/// - [OnContextLoaded]
///
/// Once discovered, Jetleaf automatically calls these annotated methods at
/// the appropriate point during the application lifecycle without requiring
/// explicit listener registration.
///
/// ### Example
/// ```dart
/// class StartupHooks {
///   @OnApplicationStarting()
///   void beforeStart(ConfigurableBootstrapContext context, Class<Object> mainClass) {
///     print('Jetleaf application starting: ${mainClass.getName()}');
///   }
///
///   @OnApplicationReady()
///   void afterReady(ConfigurableApplicationContext context, Duration startupTime) {
///     print('Application ready in ${startupTime.inMilliseconds} ms');
///   }
/// }
///
/// // Jetleaf detects and invokes StartupHooks automatically.
/// ```
///
/// ### Features
/// - Zero-configuration discovery of lifecycle methods using reflection.
/// - Automatic dependency injection for context, environment, duration, and exceptions.
/// - Prevents duplicate invocations using identity-based deduplication.
/// - Supports abstract and concrete classes with no-arg or inferred constructors.
/// - Enables concise, annotation-driven lifecycle logic in Jetleaf applications.
///
/// This class is an integral part of Jetleaf’s reflective runtime and typically
/// runs automatically during framework initialization.
/// {@endtemplate}
final class LifecycleRunListener implements ApplicationRunListener {
  /// A collection of methods annotated with [OnContextLoaded].
  ///
  /// These methods are invoked after the Jetleaf [ConfigurableApplicationContext]
  /// has completed loading all pods and configuration sources.
  Set<Method> _onContextLoadedMethods = {};

  /// A collection of methods annotated with [OnContextPrepared].
  ///
  /// Invoked when the [ConfigurableApplicationContext] is initialized
  /// but not yet refreshed, allowing customization before component scanning.
  Set<Method> _onContextPreparedMethods = {};

  /// A collection of methods annotated with [OnEnvironmentPrepared].
  ///
  /// These methods run after the environment and property sources have been
  /// loaded but before the application context is created.
  Set<Method> _onEnvironmentPreparedMethods = {};

  /// A collection of methods annotated with [OnApplicationFailed].
  ///
  /// Invoked whenever an unhandled exception occurs during Jetleaf startup
  /// or shutdown, allowing for cleanup or diagnostic reporting.
  Set<Method> _onFailedMethods = {};

  /// A collection of methods annotated with [OnApplicationReady].
  ///
  /// These run once the application context has started successfully
  /// and the application is considered ready to serve.
  Set<Method> _onReadyMethods = {};

  /// A collection of methods annotated with [OnApplicationStarted].
  ///
  /// Called after the Jetleaf application context has been refreshed
  /// but before [OnApplicationReady] is fired.
  Set<Method> _onStartedMethods = {};

  /// A collection of methods annotated with [OnApplicationStarting].
  ///
  /// Fired at the earliest possible phase in Jetleaf’s startup lifecycle,
  /// before the environment or context are initialized.
  Set<Method> _onStartingMethods = {};

  /// {@macro jetleaf_lifecycle_run_listener}
  LifecycleRunListener() {
    _onStartingMethods = MethodUtils.collectMethods<OnApplicationStarting>().toSet();
    _onStartedMethods = MethodUtils.collectMethods<OnApplicationStarted>().toSet();
    _onReadyMethods = MethodUtils.collectMethods<OnApplicationReady>().toSet();
    _onFailedMethods = MethodUtils.collectMethods<OnApplicationFailed>().toSet();
    _onEnvironmentPreparedMethods = MethodUtils.collectMethods<OnEnvironmentPrepared>().toSet();
    _onContextPreparedMethods = MethodUtils.collectMethods<OnContextPrepared>().toSet();
    _onContextLoadedMethods = MethodUtils.collectMethods<OnContextLoaded>().toSet();
  }

  /// Checks if the given [clazz] is assignable to [ConfigurableBootstrapContext]
  bool _isAssignableFromBootstrapContext(Class clazz) => Class<ConfigurableBootstrapContext>(null, PackageNames.MAIN).isAssignableFrom(clazz);

  /// Checks if the given [clazz] is assignable to [ConfigurableApplicationContext]
  bool _isAssignableFromApplicationContext(Class clazz) => Class<ConfigurableApplicationContext>(null, PackageNames.MAIN).isAssignableFrom(clazz);

  @override
  void onContextLoaded(ConfigurableApplicationContext context) {
    for(final method in _onContextLoadedMethods) {
      final cls = method.getDeclaringClass();
      final instance = !cls.isInvokable() ? null : (cls.getNoArgConstructor() ?? cls.getBestConstructor([]))?.newInstance();

      final arguments = ExecutableArgumentResolver()
        .and(Class<ApplicationContext>(null, PackageNames.MAIN), context)
        .resolve(method);
      
      method.invoke(instance, arguments.getNamedArguments(), arguments.getPositionalArguments());
    }
  }

  @override
  void onContextPrepared(ConfigurableApplicationContext context) {
    for(final method in _onContextPreparedMethods) {
      final cls = method.getDeclaringClass();
      final instance = !cls.isInvokable() ? null : (cls.getNoArgConstructor() ?? cls.getBestConstructor([]))?.newInstance();

      final arguments = ExecutableArgumentResolver()
        .and(Class<ApplicationContext>(null, PackageNames.MAIN), context)
        .resolve(method);
      
      method.invoke(instance, arguments.getNamedArguments(), arguments.getPositionalArguments());
    }
  }

  @override
  void onEnvironmentPrepared(ConfigurableBootstrapContext context, ConfigurableEnvironment environment) {
    for(final method in _onEnvironmentPreparedMethods) {
      final cls = method.getDeclaringClass();
      final instance = !cls.isInvokable() ? null : (cls.getNoArgConstructor() ?? cls.getBestConstructor([]))?.newInstance();

      final arguments = ExecutableArgumentResolver()
        .and(Class<BootstrapContext>(null, PackageNames.MAIN), context)
        .and(Class<Environment>(), environment)
        .resolve(method);
      
      method.invoke(instance, arguments.getNamedArguments(), arguments.getPositionalArguments());
    }
  }

  @override
  void onFailed(ConfigurableApplicationContext? context, Object exception) {
    for(final method in _onFailedMethods) {
      final cls = method.getDeclaringClass();
      final instance = !cls.isInvokable() ? null : (cls.getNoArgConstructor() ?? cls.getBestConstructor([]))?.newInstance();
      
      final arguments = ExecutableArgumentResolver()
        .when((p) => _isAssignableFromApplicationContext(p.getReturnClass()), context)
        .when((p) => ClassUtils.isAssignableToError(p.getReturnClass()), exception)
        .resolve(method);
      
      method.invoke(instance, arguments.getNamedArguments(), arguments.getPositionalArguments());
    }
  }

  @override
  void onReady(ConfigurableApplicationContext context, Duration timeTaken) {
    for(final method in _onReadyMethods) {
      final cls = method.getDeclaringClass();
      final instance = !cls.isInvokable() ? null : (cls.getNoArgConstructor() ?? cls.getBestConstructor([]))?.newInstance();
      
      final arguments = ExecutableArgumentResolver()
        .and(Class<ApplicationContext>(null, PackageNames.MAIN), context)
        .and(Class<Duration>(null, PackageNames.DART), timeTaken)
        .resolve(method);
      
      method.invoke(instance, arguments.getNamedArguments(), arguments.getPositionalArguments());
    }
  }

  @override
  void onStarted(ConfigurableApplicationContext context, Duration timeTaken) {
    for(final method in _onStartedMethods) {
      final cls = method.getDeclaringClass();
      final instance = !cls.isInvokable() ? null : (cls.getNoArgConstructor() ?? cls.getBestConstructor([]))?.newInstance();

      final arguments = ExecutableArgumentResolver()
        .and(Class<ApplicationContext>(null, PackageNames.MAIN), context)
        .and(Class<Duration>(null, PackageNames.DART), timeTaken)
        .resolve(method);
      
      method.invoke(instance, arguments.getNamedArguments(), arguments.getPositionalArguments());
    }
  }

  @override
  void onStarting(ConfigurableBootstrapContext context, Class<Object> mainClass) {
    for(final method in _onStartingMethods) {
      final cls = method.getDeclaringClass();
      final instance = !cls.isInvokable() ? null : (cls.getNoArgConstructor() ?? cls.getBestConstructor([]))?.newInstance();
      
      final arguments = ExecutableArgumentResolver()
        .when((p) => !_isAssignableFromBootstrapContext(p.getReturnClass()), mainClass)
        .when((p) => _isAssignableFromBootstrapContext(p.getReturnClass()), context)
        .resolve(method);
      
      method.invoke(instance, arguments.getNamedArguments(), arguments.getPositionalArguments());
    }
  }
}