import 'package:jetleaf_core/annotation.dart';
import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';

import '../context/bootstrap_context.dart';
import 'run_listener.dart';

/// {@template jet_lifecycle_run_listener}
/// A reflection-driven JetLeaf [ApplicationRunListener] that automatically
/// discovers and invokes lifecycle-annotated methods across all loaded types.
///
/// The [LifecycleRunListener] scans all runtime-visible methods annotated with
/// JetLeaf lifecycle annotations such as:
/// - [OnApplicationStarting]
/// - [OnApplicationStarted]
/// - [OnApplicationReady]
/// - [OnApplicationFailed]
/// - [OnEnvironmentPrepared]
/// - [OnContextPrepared]
/// - [OnContextLoaded]
///
/// Once discovered, JetLeaf automatically calls these annotated methods at
/// the appropriate point during the application lifecycle without requiring
/// explicit listener registration.
///
/// ### Example
/// ```dart
/// class StartupHooks {
///   @OnApplicationStarting()
///   void beforeStart(ConfigurableBootstrapContext context, Class<Object> mainClass) {
///     print('JetLeaf application starting: ${mainClass.getName()}');
///   }
///
///   @OnApplicationReady()
///   void afterReady(ConfigurableApplicationContext context, Duration startupTime) {
///     print('Application ready in ${startupTime.inMilliseconds} ms');
///   }
/// }
///
/// // JetLeaf detects and invokes StartupHooks automatically.
/// ```
///
/// ### Features
/// - Zero-configuration discovery of lifecycle methods using reflection.
/// - Automatic dependency injection for context, environment, duration, and exceptions.
/// - Prevents duplicate invocations using identity-based deduplication.
/// - Supports abstract and concrete classes with no-arg or inferred constructors.
/// - Enables concise, annotation-driven lifecycle logic in JetLeaf applications.
///
/// This class is an integral part of JetLeaf’s reflective runtime and typically
/// runs automatically during framework initialization.
/// {@endtemplate}
final class LifecycleRunListener implements ApplicationRunListener {
  /// A collection of methods annotated with [OnContextLoaded].
  ///
  /// These methods are invoked after the JetLeaf [ConfigurableApplicationContext]
  /// has completed loading all pods and configuration sources.
  final Set<Method> _onContextLoadedMethods = {};

  /// A collection of methods annotated with [OnContextPrepared].
  ///
  /// Invoked when the [ConfigurableApplicationContext] is initialized
  /// but not yet refreshed, allowing customization before component scanning.
  final Set<Method> _onContextPreparedMethods = {};

  /// A collection of methods annotated with [OnEnvironmentPrepared].
  ///
  /// These methods run after the environment and property sources have been
  /// loaded but before the application context is created.
  final Set<Method> _onEnvironmentPreparedMethods = {};

  /// A collection of methods annotated with [OnApplicationFailed].
  ///
  /// Invoked whenever an unhandled exception occurs during JetLeaf startup
  /// or shutdown, allowing for cleanup or diagnostic reporting.
  final Set<Method> _onFailedMethods = {};

  /// A collection of methods annotated with [OnApplicationReady].
  ///
  /// These run once the application context has started successfully
  /// and the application is considered ready to serve.
  final Set<Method> _onReadyMethods = {};

  /// A collection of methods annotated with [OnApplicationStarted].
  ///
  /// Called after the JetLeaf application context has been refreshed
  /// but before [OnApplicationReady] is fired.
  final Set<Method> _onStartedMethods = {};

  /// A collection of methods annotated with [OnApplicationStarting].
  ///
  /// Fired at the earliest possible phase in JetLeaf’s startup lifecycle,
  /// before the environment or context are initialized.
  final Set<Method> _onStartingMethods = {};

  /// {@macro jet_lifecycle_run_listener}
  LifecycleRunListener() {
    MethodUtils.collectMethods<OnApplicationStarting>(_onStartingMethods);
    MethodUtils.collectMethods<OnApplicationStarted>(_onStartedMethods);
    MethodUtils.collectMethods<OnApplicationReady>(_onReadyMethods);
    MethodUtils.collectMethods<OnApplicationFailed>(_onFailedMethods);
    MethodUtils.collectMethods<OnEnvironmentPrepared>(_onEnvironmentPreparedMethods);
    MethodUtils.collectMethods<OnContextPrepared>(_onContextPreparedMethods);
    MethodUtils.collectMethods<OnContextLoaded>(_onContextLoadedMethods);
  }

  /// Checks if the given [clazz] is assignable to [ConfigurableBootstrapContext]
  bool _isAssignableFromBootstrapContext(Class clazz) => Class<ConfigurableBootstrapContext>(null, PackageNames.MAIN).isAssignableFrom(clazz);

  /// Checks if the given [clazz] is assignable to [ConfigurableApplicationContext]
  bool _isAssignableFromApplicationContext(Class clazz) => Class<ConfigurableApplicationContext>(null, PackageNames.MAIN).isAssignableFrom(clazz);

  /// Checks if the given [clazz] is assignable to [Duration]
  bool _isAssignableFromDuration(Class clazz) => Class<Duration>(null, PackageNames.DART).isAssignableFrom(clazz);

  @override
  void onContextLoaded(ConfigurableApplicationContext context) {
    for(final method in _onContextLoadedMethods) {
      final cls = method.getDeclaringClass();
      final instance = !cls.isInvokable() ? null : (cls.getNoArgConstructor() ?? cls.getBestConstructor([]))?.newInstance();

      final arguments = <String, Object>{};
      final parameters = method.getParameters();
      final contextArgName = parameters.find((p) => _isAssignableFromApplicationContext(p.getClass()))?.getName();
      
      if(contextArgName != null) {
        arguments[contextArgName] = context;
      }
      
      method.invoke(instance, arguments);
    }
  }

  @override
  void onContextPrepared(ConfigurableApplicationContext context) {
    for(final method in _onContextPreparedMethods) {
      final cls = method.getDeclaringClass();
      final instance = !cls.isInvokable() ? null : (cls.getNoArgConstructor() ?? cls.getBestConstructor([]))?.newInstance();

      final arguments = <String, Object>{};
      final parameters = method.getParameters();
      final contextArgName = parameters.find((p) => _isAssignableFromApplicationContext(p.getClass()))?.getName();
      
      if(contextArgName != null) {
        arguments[contextArgName] = context;
      }
      
      method.invoke(instance, arguments);
    }
  }

  @override
  void onEnvironmentPrepared(ConfigurableBootstrapContext context, ConfigurableEnvironment environment) {
    for(final method in _onEnvironmentPreparedMethods) {
      final cls = method.getDeclaringClass();
      final instance = !cls.isInvokable() ? null : (cls.getNoArgConstructor() ?? cls.getBestConstructor([]))?.newInstance();

      final arguments = <String, Object>{};
      final parameters = method.getParameters();
      final contextArgName = parameters.find((p) => _isAssignableFromBootstrapContext(p.getClass()))?.getName();
      final environmentArgName = parameters.find((p) => !_isAssignableFromBootstrapContext(p.getClass()))?.getName();
      
      if(contextArgName != null) {
        arguments[contextArgName] = context;
      }
      
      if(environmentArgName != null) {
        arguments[environmentArgName] = environment;
      }
      
      method.invoke(instance, arguments);
    }
  }

  @override
  void onFailed(ConfigurableApplicationContext? context, Object exception) {
    for(final method in _onFailedMethods) {
      final cls = method.getDeclaringClass();
      final instance = !cls.isInvokable() ? null : (cls.getNoArgConstructor() ?? cls.getBestConstructor([]))?.newInstance();

      final arguments = <String, Object?>{};
      final parameters = method.getParameters();
      final contextArgName = parameters.find((p) => _isAssignableFromApplicationContext(p.getClass()))?.getName();
      final exceptionArgName = parameters.find((p) => ClassUtils.isAssignableToError(p.getClass()))?.getName();
      
      if(contextArgName != null) {
        arguments[contextArgName] = context;
      }
      
      if(exceptionArgName != null) {
        arguments[exceptionArgName] = exception;
      }
      
      method.invoke(instance, arguments);
    }
  }

  @override
  void onReady(ConfigurableApplicationContext context, Duration timeTaken) {
    for(final method in _onReadyMethods) {
      final cls = method.getDeclaringClass();
      final instance = !cls.isInvokable() ? null : (cls.getNoArgConstructor() ?? cls.getBestConstructor([]))?.newInstance();

      final arguments = <String, Object>{};
      final parameters = method.getParameters();
      final contextArgName = parameters.find((p) => _isAssignableFromApplicationContext(p.getClass()))?.getName();
      final timeTakenArgName = parameters.find((p) => _isAssignableFromDuration(p.getClass()))?.getName();
      
      if(contextArgName != null) {
        arguments[contextArgName] = context;
      }
      
      if(timeTakenArgName != null) {
        arguments[timeTakenArgName] = timeTaken;
      }
      
      method.invoke(instance, arguments);
    }
  }

  @override
  void onStarted(ConfigurableApplicationContext context, Duration timeTaken) {
    for(final method in _onStartedMethods) {
      final cls = method.getDeclaringClass();
      final instance = !cls.isInvokable() ? null : (cls.getNoArgConstructor() ?? cls.getBestConstructor([]))?.newInstance();

      final arguments = <String, Object>{};
      final parameters = method.getParameters();
      final contextArgName = parameters.find((p) => _isAssignableFromApplicationContext(p.getClass()))?.getName();
      final timeTakenArgName = parameters.find((p) => _isAssignableFromDuration(p.getClass()))?.getName();
      
      if(contextArgName != null) {
        arguments[contextArgName] = context;
      }
      
      if(timeTakenArgName != null) {
        arguments[timeTakenArgName] = timeTaken;
      }
      
      method.invoke(instance, arguments);
    }
  }

  @override
  void onStarting(ConfigurableBootstrapContext context, Class<Object> mainClass) {
    for(final method in _onStartingMethods) {
      final cls = method.getDeclaringClass();
      final instance = !cls.isInvokable() ? null : (cls.getNoArgConstructor() ?? cls.getBestConstructor([]))?.newInstance();
      final arguments = <String, Object>{};

      final parameters = method.getParameters();
      final classArgName = parameters.find((p) => !_isAssignableFromBootstrapContext(p.getClass()))?.getName();
      final contextArgName = parameters.find((p) => _isAssignableFromBootstrapContext(p.getClass()))?.getName();
      
      if(classArgName != null) {
        arguments[classArgName] = mainClass;
      }
      
      if(contextArgName != null) {
        arguments[contextArgName] = context;
      }
      
      method.invoke(instance, arguments);
    }
  }
}