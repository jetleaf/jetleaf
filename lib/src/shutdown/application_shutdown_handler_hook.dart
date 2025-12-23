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

import 'dart:async';
import 'dart:io';

import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_env/property.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_logging/logging.dart';
import 'package:meta/meta.dart';

import 'application_shutdown_handler.dart';

/// {@template application_shutdown_handler_hook}
/// The `ApplicationShutdownHandlerHook` is responsible for managing the **graceful
/// shutdown** of a JetLeaf application, ensuring that all registered
/// [ConfigurableApplicationContext] instances and shutdown handlers are executed
/// in a predictable and safe order when the Dart process exits or receives a
/// termination signal.
///
/// This class supports:
/// 
/// 1. **Automatic shutdown hook registration** using Dart's `ProcessSignal`
///    mechanism to handle `SIGINT` and `SIGTERM`.
/// 2. **Tracking of active and closed contexts** to avoid double closures.
/// 3. **Execution of registered shutdown handlers** in **reverse registration order**
///    to ensure that dependent services are shut down in a safe sequence.
/// 4. **Environment cleanup** such as disposing of logging listeners.
/// 5. **Concurrency safety**, with internal synchronization to avoid race conditions
///    when multiple contexts or handlers are being registered or executed concurrently.
///
/// ### Usage Example:
/// ```dart
/// final shutdownHook = ApplicationShutdownHandlerHook();
/// shutdownHook.enableShutdownHook(); // Allow automatic signal registration
/// shutdownHook.registerApplicationContext(appContext);
/// shutdownHook.handler.add(() => print("Custom shutdown action"));
/// ```
///
/// ### References:
/// - [ConfigurableApplicationContext]: Represents an application context that can
///   be started and closed.
/// - [Runnable]: Interface implemented by shutdown handlers.
/// - [_ApplicationContextClosedListener]: Internal listener monitoring context closure.
/// {@endtemplate}
class ApplicationShutdownHandlerHook implements Runnable {
  /// Sleep interval in milliseconds for polling contexts during shutdown.
  ///
  /// This interval is used in `_closeAndWait` to check if contexts have completed
  /// their shutdown sequence. A small delay prevents busy-waiting while allowing
  /// fast shutdown.
  static const int _sleep = 50;

  /// Maximum duration to wait for contexts to close before forcing exit.
  ///
  /// This ensures that hanging or slow contexts do not block the shutdown
  /// indefinitely. Default is 10 minutes.
  static const Duration _timeout = Duration(minutes: 10);

  /// Logger used for reporting informational, warning, and error messages
  /// during shutdown.
  final _logger = LogFactory.getLog(ApplicationShutdownHandlerHook);

  /// Active application contexts tracked by the shutdown hook.
  ///
  /// These contexts will be closed when the shutdown hook is executed.
  final Set<ConfigurableApplicationContext> _contexts = {};

  /// Contexts that have been previously closed but need re-verification.
  ///
  /// Used to ensure that all shutdown logic is idempotent.
  final Set<ConfigurableApplicationContext> _closedContexts = {};

  /// Whether a shutdown hook has been added to the Dart runtime.
  bool _shutdownHookAdded = false;

  /// Flag indicating if shutdown hooks are enabled.
  ///
  /// Only after calling [enableShutdownHook] will runtime signals be intercepted.
  bool _shutdownHookEnabled = false;

  /// Flag indicating if a shutdown is currently in progress.
  ///
  /// Prevents re-entrant execution of the shutdown logic.
  bool _inProgress = false;

  /// {@macro application_shutdown_handler_hook}
  ApplicationShutdownHandlerHook();

  /// Internal listener to track closure of application contexts.
  _ApplicationContextClosedListener get _closeListener => _ApplicationContextClosedListener(this);

  /// Internal handlers manager for registered shutdown actions.
  _Handlers get _handlers => _Handlers(this);

  /// {@template shutdown_hook_handlers}
  /// Returns the internal shutdown handlers manager.
  ///
  /// You can register or remove shutdown `Runnable` actions through this.
  ///
  /// ### Example:
  /// ```dart
  /// hook.handlers.add(() => print("Shutting down..."));
  /// ```
  /// {@endtemplate}
  ApplicationShutdownHandler get handler => _handlers;

  /// {@template enable_shutdown_hook_addition}
  /// Enables the addition of a runtime shutdown hook to the Dart VM.
  ///
  /// This should be called early in the application lifecycle.
  /// Once enabled, a shutdown hook is registered on the next context registration.
  ///
  /// ### Example:
  /// ```dart
  /// hook.enableShutdownHookAddition();
  /// ```
  /// {@endtemplate}
  void enableShutdownHook() {
    _shutdownHookEnabled = true;
  }

  /// {@template register_application_context}
  /// Registers a [ConfigurableApplicationContext] to be shut down
  /// when the Dart process exits.
  ///
  /// Also attaches an internal listener to monitor context closure.
  ///
  /// ### Example:
  /// ```dart
  /// hook.registerApplicationContext(context);
  /// ```
  /// {@endtemplate}
  void registerApplicationContext(ConfigurableApplicationContext context) {
    addRuntimeShutdownHookIfNecessary();

    return synchronized(this, () {
      assertNotInProgress();
      context.addApplicationListener(_closeListener);
      _contexts.add(context);
    });
  }

  /// {@template deregister_failed_context}
  /// Removes a failed or inactive application context from tracking.
  ///
  /// Throws an [IllegalArgumentException] if the context is still active.
  ///
  /// ### Example:
  /// ```dart
  /// hook.unregisterFailedApplicationContext(context);
  /// ```
  /// {@endtemplate}
  void unregisterFailedApplicationContext(ConfigurableApplicationContext context) {
    return synchronized(this, () {
      if(context.isRunning()) {
        throw IllegalArgumentException('Cannot unregister active application context');
      }

      _contexts.remove(context);
    });
  }

  /// {@template is_application_context_registered}
  /// Checks if a [ConfigurableApplicationContext] is registered for shutdown.
  ///
  /// ### Example:
  /// ```dart
  /// if (hook.isApplicationContextRegistered(context)) {
  ///   print("Context is registered for shutdown.");
  /// }
  /// ```
  /// {@endtemplate}
  bool isApplicationContextRegistered(ConfigurableApplicationContext context) {
    return synchronized(this, () => _contexts.contains(context));
  }

  /// {@template add_runtime_shutdown_hook_if_necessary}
  /// Adds a runtime shutdown hook if necessary.
  ///
  /// This method is called internally to ensure that a shutdown hook is
  /// registered when needed. It checks if the shutdown hook is enabled and
  /// not already added before registering it.
  ///
  /// ### Example:
  /// ```dart
  /// hook.addRuntimeShutdownHookIfNecessary();
  /// ```
  /// {@endtemplate}
  @protected
  void addRuntimeShutdownHookIfNecessary() {
    if (_shutdownHookEnabled && !_shutdownHookAdded) {
      _shutdownHookAdded = true;
      _registerProcessSignalHook();
    }
  }

  /// {@template register_process_signal_hook}
  /// Registers a signal handler for process termination signals.
  ///
  /// This method is called internally to register a signal handler that
  /// triggers the shutdown process when the Dart process receives a
  /// termination signal (e.g., `SIGINT` or `SIGTERM`).
  ///
  /// ### Example:
  /// ```dart
  /// hook.registerProcessSignalHook();
  /// ```
  /// {@endtemplate}
  void _registerProcessSignalHook() {
    ProcessSignal.sigint.watch().listen((signal) async => await _runInternal());
    ProcessSignal.sigterm.watch().listen((signal) async => await _runInternal());
  }

  /// {@template run_internal}
  /// Runs the shutdown process internally.
  ///
  /// This method is called internally to execute the shutdown process when
  /// a termination signal is received. It ensures that the shutdown process
  /// is executed in a clean environment and handles any exceptions that may
  /// occur during the shutdown process.
  ///
  /// ### Example:
  /// ```dart
  /// await hook._runInternal();
  /// ```
  /// {@endtemplate}
  Future<void> _runInternal() async {
    await run();
    exit(0);
  }

  @override
  Future<void> run() async {
    _inProgress = true;
    if (_logger.getIsInfoEnabled()) {
      _logger.info("Shutdown initiated. Beginning graceful shutdown of all application contexts.");
    }

    Set<ConfigurableApplicationContext> contexts = {};
    Set<ConfigurableApplicationContext> closed = {};
    Set<_Handler> handlers = {};

    synchronized(this, () {
      _inProgress = true;
      contexts = Set.from(_contexts);
      closed = Set.from(_closedContexts);
      handlers = Set.from(_handlers.actions.toList().reversed.toSet());
    });

    // ---------------------------------------------------------------------------
    // Step 1: Close active contexts
    // ---------------------------------------------------------------------------
    if (contexts.isEmpty) {
      if (_logger.getIsInfoEnabled()) {
        _logger.info("No active application contexts to close.");
      }
    } else {
      if (_logger.getIsInfoEnabled()) {
        _logger.info("Closing ${contexts.length} active application context(s).");
      }

      for (final context in contexts) {
        AvailabilityEvent.publish(context, ReadinessState.REFUSING_TRAFFIC);

        final name = context.getDisplayName();
        final id = context.getId();
        
        if (_logger.getIsInfoEnabled()) {
          _logger.info("Closing application context $name with id $id.");
        }

        await _closeAndWait(context);
        if (_logger.getIsInfoEnabled()) {
          _logger.info("✓ Application context $name with id $id closed successfully.");
        }
      }
    }

    // ---------------------------------------------------------------------------
    // Step 2: Re-close previously closed contexts (for safety)
    // ---------------------------------------------------------------------------
    if (closed.isNotEmpty) {
      if (_logger.getIsInfoEnabled()) {
        _logger.info("Ensuring ${closed.length} previously closed context(s) are fully shut down.");
      }
      
      for (final context in closed) {
        final name = context.getDisplayName();
        final id = context.getId();
        if (_logger.getIsInfoEnabled()) {
          _logger.info("Re-closing application context $name with id $id (already marked closed).");
        }

        await _closeAndWait(context);
        if (_logger.getIsInfoEnabled()) {
          _logger.info("✓ Verified application context $name with id $id is fully closed.");
        }
      }
    }

    // ---------------------------------------------------------------------------
    // Step 3: Execute registered shutdown handlers
    // ---------------------------------------------------------------------------
    if (handlers.isEmpty) {
      if (_logger.getIsInfoEnabled()) {
        _logger.info("No registered shutdown handlers to execute.");
      }
    } else {
      if (_logger.getIsInfoEnabled()) {
        _logger.info("Executing ${handlers.length} registered shutdown handler(s) in reverse registration order.");
      }
      
      for (final handler in handlers) {
        if (_logger.getIsInfoEnabled()) {
          _logger.info("Running shutdown handler: ${handler.runtimeType}");
        }

        try {
          handler.run();
          if (_logger.getIsInfoEnabled()) {
            _logger.info("✓ Shutdown handler ${handler.runtimeType} completed successfully.");
          }
        } catch (e, st) {
          if (_logger.getIsWarnEnabled()) {
            _logger.warn("⚠ Shutdown handler ${handler.runtimeType} failed: $e", error: e, stacktrace: st);
          }
        }
      }
    }

    // ---------------------------------------------------------------------------
    // Step 4: Dispose environment listener
    // ---------------------------------------------------------------------------
    if (_logger.getIsInfoEnabled()) {
      _logger.info("Disposing environment logging listener.");
    }
    
    try {
      await environmentLoggingListener.dispose();
      if (_logger.getIsInfoEnabled()) {
        _logger.info("✓ Environment logging listener disposed.");
      }
    } catch (e, st) {
      if (_logger.getIsWarnEnabled()) {
        _logger.warn("⚠ Failed to dispose environment logging listener: $e", error: e, stacktrace: st);
      }
    }

    if (_logger.getIsInfoEnabled()) {
      _logger.info("Shutdown completed. All contexts and handlers shut down gracefully.");
    }
  }

  /// {@template reset}
  /// Resets the shutdown hook state, clearing all registered contexts,
  /// handlers, and closing any active contexts.
  ///
  /// ### Example:
  /// ```dart
  /// hook.reset();
  /// ```
  /// {@endtemplate}
  void reset() {
    return synchronized(this, () {
      _contexts.clear();
      _closedContexts.clear();
      _handlers.actions.clear();
      _inProgress = false;
    });
  }

  /// {@template close_and_wait}
  /// Closes the given [ConfigurableApplicationContext] and waits for it to
  /// complete shutdown.
  ///
  /// This method is called internally to close and wait for the shutdown of
  /// a registered application context. It uses a timeout to ensure that the
  /// context is closed within a reasonable amount of time.
  ///
  /// ### Example:
  /// ```dart
  /// await hook._closeAndWait(context);
  /// ```
  /// {@endtemplate}
  Future<void> _closeAndWait(ConfigurableApplicationContext context) async {
    if (!context.isRunning()) return;

    await context.close();
    final start = DateTime.now();
    while (context.isRunning()) {
      if (DateTime.now().difference(start) > _timeout) {
        stderr.writeln('Timeout while waiting for context shutdown.');
        break;
      }
      await Future.delayed(Duration(milliseconds: _sleep));
    }
  }

  /// {@template assert_not_in_progress}
  /// Asserts that the shutdown hook is not currently in progress.
  ///
  /// Throws an [IllegalArgumentException] if the shutdown hook is already
  /// in progress.
  ///
  /// ### Example:
  /// ```dart
  /// hook.assertNotInProgress();
  /// ```
  /// {@endtemplate}
  @protected
  void assertNotInProgress() {
    if (_inProgress) {
      throw IllegalArgumentException('Shutdown already in progress');
    }
  }
}

/// {@template handlers}
/// Internal implementation of [ApplicationShutdownHandler] that wraps
/// a set of `Runnable` actions and coordinates their execution.
///
/// Shutdown actions are executed in reverse order of registration.
/// {@endtemplate}
class _Handlers implements ApplicationShutdownHandler, Runnable {
  final ApplicationShutdownHandlerHook _hook;

  /// {@macro handlers}
  _Handlers(this._hook);

  final Set<_Handler> actions = {};

  @override
  void add(Runnable action) {
    _hook.addRuntimeShutdownHookIfNecessary();
    return synchronized(this, () {
      _hook.assertNotInProgress();
      actions.add(_Handler(action));
    });
  }

  @override
  void remove(Runnable action) {
    return synchronized(this, () {
      _hook.assertNotInProgress();
      actions.remove(_Handler(action));
    });
  }

  @override
  void run() {
    _hook.run();
    _hook.reset();
  }
}

/// {@template handler}
/// Internal implementation of [Runnable] that wraps a single `Runnable` action.
///
/// This class is used to coordinate the execution of shutdown actions.
/// {@endtemplate}
class _Handler {
  final Runnable _action;

  /// {@macro handler}
  const _Handler(this._action);

  void run() => _action.run();

  @override
  int get hashCode => identityHashCode(_action);

  @override
  bool operator ==(Object other) => other is _Handler && identical(other._action, _action);
}

/// {@template application_context_closed_listener}
/// Internal implementation of [ApplicationEventListener] that monitors the
/// closure of application contexts and registers them for shutdown.
///
/// This listener is used to coordinate the shutdown process of registered
/// application contexts.
/// {@endtemplate}
class _ApplicationContextClosedListener implements ApplicationEventListener<ContextClosedEvent> {
  final ApplicationShutdownHandlerHook hook;

  _ApplicationContextClosedListener(this.hook);

  @override
  bool supportsEventOf(ApplicationEvent event) {
    return event is ContextClosedEvent;
  }

  @override
  Future<void> onApplicationEvent(ContextClosedEvent event) async {
    return synchronized(hook, () {
      final context = event.getApplicationContext();
      hook._contexts.remove(context);
      hook._closedContexts.add(context as ConfigurableApplicationContext);
    });
  }
}