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

import 'package:jetleaf_core/annotation.dart';
import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_logging/logging.dart';
import 'package:jetleaf_pod/pod.dart';

import '../context/bootstrap_context.dart';
import 'run_listener.dart';

/// {@template jet_application_run_listeners}
/// A composite implementation of [ApplicationRunListener] that delegates
/// application lifecycle events to multiple registered listeners and also
/// invokes annotated lifecycle methods.
///
/// This class also integrates with [ApplicationStartup] to record structured
/// startup steps and performance metrics, making it easier to debug and
/// measure application bootstrapping.
///
/// ### Features
/// - Delegates lifecycle events to all registered listeners.
/// - Scans runtime for methods annotated with lifecycle annotations such as:
///   - [OnApplicationStarting]  
///   - [OnApplicationStarted]  
///   - [OnApplicationReady]  
///   - [OnApplicationFailed]  
///   - [OnEnvironmentPrepared]  
///   - [OnContextPrepared]  
///   - [OnContextLoaded]  
/// - Wraps each listener call with performance tracking.
/// - Provides error handling for failed lifecycle invocations.
///
/// ### Example
/// ```dart
/// final listeners = [MyCustomRunListener()];
/// final startup = ApplicationStartup();
///
/// final composite = ApplicationRunListeners(listeners, startup);
/// composite.onStarting(context, MyApp);
/// ```
/// {@endtemplate}
class ApplicationRunListeners implements ApplicationRunListener {
  /// {@template jet_application_run_listeners_listeners}
  /// All registered listeners that should receive application lifecycle events.
  /// {@endtemplate}
  final List<ApplicationRunListener> _listeners;

  /// {@template jet_application_run_listeners_lifecycle_methods}
  /// All discovered lifecycle methods annotated with JetLeaf lifecycle
  /// annotations (e.g., [OnApplicationStarting], [OnContextPrepared]).
  ///
  /// These methods are invoked in addition to the registered listeners.
  /// {@endtemplate}
  final List<Method> _lifecycleMethods = [];
  
  /// {@template jet_application_run_listeners_startup}
  /// Tracks structured startup steps and performance metrics for lifecycle
  /// events.
  /// {@endtemplate}
  final ApplicationStartup _startup;

  /// {@template jet_application_run_listeners_logger}
  /// Internal logger used to capture errors that occur during lifecycle
  /// execution.
  /// {@endtemplate}
  final Log _logger = LogFactory.getLog(ApplicationRunListeners);
  
  /// {@macro jet_application_run_listeners}
  ApplicationRunListeners(this._listeners, this._startup) {
    final methods = Runtime.getAllMethods().where((m) => m.getAnnotations().any((a) {
      return a.getType() == OnApplicationStarting 
        || a.getType() == OnApplicationStarted 
        || a.getType() == OnApplicationReady
        || a.getType() == OnApplicationFailed
        || a.getType() == OnEnvironmentPrepared
        || a.getType() == OnContextPrepared
        || a.getType() == OnContextLoaded;
    }));

    _lifecycleMethods.addAll(methods.map((m) => Method.declared(m, ProtectionDomain.system())));
  }
  
  @override
  void onStarting(ConfigurableBootstrapContext context, Class<Object> mainClass) {
    _doWith("starting", (listener) => listener.onStarting(context, mainClass), (step) {
      step.tag("mainClass", value: mainClass.getName());
    });

    final startingMethods = _lifecycleMethods.where((m) => m.hasDirectAnnotation<OnApplicationStarting>());
    
    for(final method in startingMethods) {
      final cls = method.getDeclaringClass();
      final instance = cls.isAbstract() ? null : (cls.getNoArgConstructor() ?? cls.getBestConstructor([]))?.newInstance();
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
  
  @override
  void onEnvironmentPrepared(ConfigurableBootstrapContext context, ConfigurableEnvironment environment) {
    _doWith("environmentPrepared", (listener) => listener.onEnvironmentPrepared(context, environment));

    final preparedMethods = _lifecycleMethods.where((m) => m.hasDirectAnnotation<OnEnvironmentPrepared>());
    
    for(final method in preparedMethods) {
      final cls = method.getDeclaringClass();
      final instance = cls.isAbstract() ? null : (cls.getNoArgConstructor() ?? cls.getBestConstructor([]))?.newInstance();

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
  void onContextPrepared(ConfigurableApplicationContext context) {
    _doWith("contextPrepared", (listener) => listener.onContextPrepared(context));

    final preparedMethods = _lifecycleMethods.where((m) => m.hasDirectAnnotation<OnContextPrepared>());
    
    for(final method in preparedMethods) {
      final cls = method.getDeclaringClass();
      final instance = cls.isAbstract() ? null : (cls.getNoArgConstructor() ?? cls.getBestConstructor([]))?.newInstance();

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
  void onContextLoaded(ConfigurableApplicationContext context) {
    _doWith("contextLoaded", (listener) => listener.onContextLoaded(context));

    final loadedMethods = _lifecycleMethods.where((m) => m.hasDirectAnnotation<OnContextLoaded>());
    
    for(final method in loadedMethods) {
      final cls = method.getDeclaringClass();
      final instance = cls.isAbstract() ? null : (cls.getNoArgConstructor() ?? cls.getBestConstructor([]))?.newInstance();

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
  void onStarted(ConfigurableApplicationContext context, Duration timeTaken) {
    _doWith("started", (listener) => listener.onStarted(context, timeTaken));

    final startedMethods = _lifecycleMethods.where((m) => m.hasDirectAnnotation<OnApplicationStarted>());
    
    for(final method in startedMethods) {
      final cls = method.getDeclaringClass();
      final instance = cls.isAbstract() ? null : (cls.getNoArgConstructor() ?? cls.getBestConstructor([]))?.newInstance();

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
  void onReady(ConfigurableApplicationContext context, Duration timeTaken) {
    _doWith("ready", (listener) => listener.onReady(context, timeTaken));

    final readyMethods = _lifecycleMethods.where((m) => m.hasDirectAnnotation<OnApplicationReady>());
    
    for(final method in readyMethods) {
      final cls = method.getDeclaringClass();
      final instance = cls.isAbstract() ? null : (cls.getNoArgConstructor() ?? cls.getBestConstructor([]))?.newInstance();

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
  void onFailed(ConfigurableApplicationContext? context, Object exception) {
    _doWith("failed", (listener) {
      try {
        listener.onFailed(context, exception);
      } catch (ex) {
        if(_logger.getIsErrorEnabled()) {
          _logger.error("Error in failure listener", error: ex);
        }
      }
    }, (step) {
      step.tag("exception", value: exception.toString());

      if(exception is Throwable) {
        step.tag("message", value: exception.getMessage());
        step.tag("stacktrace", value: exception.getStackTrace().toString());
      }

      if(exception is Exception) {
        step.tag("exception", value: exception.toString());
      }

      if(exception is Error) {
        
        step.tag("stacktrace", value: exception.stackTrace.toString());
      }
    });

    final failedMethods = _lifecycleMethods.where((m) => m.hasDirectAnnotation<OnApplicationFailed>());
    
    for(final method in failedMethods) {
      final cls = method.getDeclaringClass();
      final instance = cls.isAbstract() ? null : (cls.getNoArgConstructor() ?? cls.getBestConstructor([]))?.newInstance();

      final arguments = <String, Object?>{};
      final parameters = method.getParameters();
      final contextArgName = parameters.find((p) => _isAssignableFromApplicationContext(p.getClass()))?.getName();
      final exceptionArgName = parameters.find((p) => _isAssignableFromThrowable(p.getClass()))?.getName();
      
      if(contextArgName != null) {
        arguments[contextArgName] = context;
      }
      
      if(exceptionArgName != null) {
        arguments[exceptionArgName] = exception;
      }
      
      method.invoke(instance, arguments);
    }
  }

  /// Checks if the given [clazz] is assignable to [ConfigurableBootstrapContext]
  bool _isAssignableFromBootstrapContext(Class clazz) {
    return Class<ConfigurableBootstrapContext>().isAssignableFrom(clazz);
  }

  /// Checks if the given [clazz] is assignable to [ConfigurableApplicationContext]
  bool _isAssignableFromApplicationContext(Class clazz) {
    return Class<ConfigurableApplicationContext>().isAssignableFrom(clazz);
  }

  /// Checks if the given [clazz] is assignable to [Throwable]
  bool _isAssignableFromThrowable(Class clazz) {
    return Class<Throwable>().isAssignableFrom(clazz) || Class<Exception>().isAssignableFrom(clazz) || Class<Error>().isAssignableFrom(clazz);
  }

  /// Checks if the given [clazz] is assignable to [Duration]
  bool _isAssignableFromDuration(Class clazz) {
    return Class<Duration>().isAssignableFrom(clazz);
  }
  
  /// {@template jet_application_run_listeners_doWith}
  /// Executes the given [consumer] for each registered listener while recording
  /// a structured startup step under [stepName].
  ///
  /// Optionally accepts a [stepAction] to tag additional metadata to the
  /// [StartupStep] (e.g., exception details, context information).
  ///
  /// ### Example
  /// ```dart
  /// _doWith("customStep", (listener) {
  ///   listener.onStarted(context, Duration(seconds: 1));
  /// }, (step) {
  ///   step.tag("info", "custom data");
  /// });
  /// ```
  /// {@endtemplate}
  void _doWith(String stepName, Consumer<ApplicationRunListener> consumer, [Consumer<StartupStep>? stepAction]) {
    final tag = _startup.start("listeners.$stepName");
    try {
      for (final listener in _listeners) {
        consumer(listener);
        stepAction?.call(tag);
      }
    } finally {
      tag.end();
    }
  }
}
