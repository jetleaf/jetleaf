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
import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_logging/logging.dart';
import 'package:jetleaf_pod/pod.dart';

import '../context/bootstrap_context.dart';
import 'run_listener.dart';

/// {@template jet_application_run_listeners}
/// Coordinates the execution of multiple [ApplicationRunListener] instances
/// during the JetLeaf application lifecycle.
///
/// This class serves as the central event dispatcher for JetLeaf’s bootstrap
/// process, invoking each registered listener in sequence as the application
/// progresses through its various lifecycle stages (e.g., startup, environment
/// preparation, context initialization, readiness, and failure).
///
/// The [ApplicationRunListeners] implementation ensures that all listeners
/// execute safely and that failures in one listener do not prevent others
/// from being notified. It also integrates with [ApplicationStartup] to record
/// structured startup metrics for performance analysis and debugging.
///
/// ### Example
/// ```dart
/// final listeners = ApplicationRunListeners(
///   [MyStartupListener(), MyTelemetryListener()],
///   DefaultApplicationStartup(),
/// );
///
/// listeners.onStarting(context, Class<MyApp>(MyApp));
/// listeners.onEnvironmentPrepared(context, environment);
/// listeners.onStarted(context, Duration(milliseconds: 850));
/// ```
///
/// ### Key Responsibilities
/// - Dispatches lifecycle events to registered [ApplicationRunListener]s.
/// - Records structured startup telemetry through [ApplicationStartup].
/// - Gracefully handles listener exceptions during startup and shutdown.
/// - Provides internal error logging via JetLeaf’s [LogFactory].
///
/// JetLeaf developers typically do not instantiate this class directly.
/// Instead, the framework constructs it automatically during application boot.
/// {@endtemplate}
final class ApplicationRunListeners implements ApplicationRunListener {
  /// {@template jet_application_run_listeners_listeners}
  /// A list of registered [ApplicationRunListener] instances that receive
  /// lifecycle event callbacks from JetLeaf during startup and shutdown.
  ///
  /// Each listener in this collection is invoked sequentially during each
  /// lifecycle phase (e.g., `onStarting`, `onReady`, `onFailed`).
  ///
  /// JetLeaf guarantees that an exception thrown by one listener does not
  /// interrupt the processing of the others.
  ///
  /// ### Example
  /// ```dart
  /// final listeners = [
  ///   MetricsStartupListener(),
  ///   LoggingStartupListener(),
  /// ];
  /// final registrar = ApplicationRunListeners(listeners, DefaultApplicationStartup());
  /// ```
  /// {@endtemplate}
  final List<ApplicationRunListener> _listeners;
  
  /// {@template jet_application_run_listeners_startup}
  /// Tracks structured startup metrics and event timings during the
  /// JetLeaf application lifecycle.
  ///
  /// This enables developers to analyze startup performance and visualize
  /// the duration of each listener’s processing phase.
  ///
  /// Typically, this is injected as an instance of [DefaultApplicationStartup],
  /// but custom implementations can be provided to integrate with observability
  /// systems or APM tools.
  ///
  /// ### Example
  /// ```dart
  /// final startup = DefaultApplicationStartup();
  /// final listeners = ApplicationRunListeners([], startup);
  /// ```
  /// {@endtemplate}
  final ApplicationStartup _startup;

  /// {@template jet_application_run_listeners_logger}
  /// Internal JetLeaf [Log] instance used to capture and record errors
  /// that occur during the invocation of registered [ApplicationRunListener]s.
  ///
  /// The logger writes structured error messages, especially during
  /// the `onFailed` event phase, ensuring visibility into exceptions
  /// raised by listener components.
  ///
  /// Example usage of logging:
  /// ```dart
  /// if (_logger.getIsErrorEnabled()) {
  ///   _logger.error("Error during listener invocation", error: exception);
  /// }
  /// ```
  /// {@endtemplate}
  final Log _logger = LogFactory.getLog(ApplicationRunListeners);
  
  /// {@macro jet_application_run_listeners}
  ApplicationRunListeners(this._listeners, this._startup);
  
  @override
  void onStarting(ConfigurableBootstrapContext context, Class<Object> mainClass) {
    _doWith("starting", (listener) => listener.onStarting(context, mainClass), (step) {
      step.tag("mainClass", value: mainClass.getName());
    });
  }
  
  @override
  void onEnvironmentPrepared(ConfigurableBootstrapContext context, ConfigurableEnvironment environment) {
    _doWith("environmentPrepared", (listener) => listener.onEnvironmentPrepared(context, environment));
  }
  
  @override
  void onContextPrepared(ConfigurableApplicationContext context) {
    _doWith("contextPrepared", (listener) => listener.onContextPrepared(context));
  }
  
  @override
  void onContextLoaded(ConfigurableApplicationContext context) {
    _doWith("contextLoaded", (listener) => listener.onContextLoaded(context));
  }
  
  @override
  void onStarted(ConfigurableApplicationContext context, Duration timeTaken) {
    _doWith("started", (listener) => listener.onStarted(context, timeTaken));
  }
  
  @override
  void onReady(ConfigurableApplicationContext context, Duration timeTaken) {
    _doWith("ready", (listener) => listener.onReady(context, timeTaken));
  }

  @override
  void onFailed(ConfigurableApplicationContext? context, Object exception) {
    _doWith("failed", (listener) {
      try {
        listener.onFailed(context, exception);
      } catch (ex) {
        if (_logger.getIsErrorEnabled()) {
          _logger.error("Error in failure listener", error: ex);
        }
      }
    }, (step) {
      step.tag("exception", value: exception.toString());

      if (exception is Throwable) {
        step.tag("message", value: exception.getMessage());
        step.tag("stacktrace", value: exception.getStackTrace().toString());
      }

      if (exception is Exception) {
        step.tag("exception", value: exception.toString());
      }

      if (exception is Error) {
        step.tag("stacktrace", value: exception.stackTrace.toString());
      }
    });
  }
  
  /// {@template jet_application_run_listeners_doWith}
  /// Executes a given [consumer] action for each registered listener,
  /// while recording a structured startup [StartupStep] identified by [stepName].
  ///
  /// Optionally accepts a [stepAction] that tags additional metadata to the
  /// active [StartupStep] (e.g., exception information or application context details).
  ///
  /// This method ensures that each listener’s invocation is isolated and
  /// does not interfere with the others, even in the presence of exceptions.
  ///
  /// ### Example
  /// ```dart
  /// _doWith("customStep", (listener) {
  ///   listener.onStarted(context, Duration(seconds: 1));
  /// }, (step) {
  ///   step.tag("info", "custom data");
  /// });
  /// ```
  ///
  /// ### Internal Behavior
  /// - Starts a new [StartupStep] via [_startup].
  /// - Invokes the provided [consumer] for every listener.
  /// - Applies optional [stepAction] tagging.
  /// - Ends the step when processing completes.
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