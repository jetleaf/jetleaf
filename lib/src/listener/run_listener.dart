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

import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';

import '../context/bootstrap_context.dart';
import '../jet_application.dart';

/// {@template jet_application_run_listener}
/// A listener for JetLeaf application lifecycle events during startup.
/// 
/// This abstract class can be implemented to hook into specific stages
/// of the application's lifecycle such as environment preparation,
/// context creation, and application readiness.
/// 
/// Implementations are often used to perform logging, initialize external
/// services, configure context properties, or monitor startup performance.
/// 
/// ## Example
/// ```dart
/// class LoggingRunListener implements ApplicationRunListener {
///   @override
///   void onStarting(ConfigurableBootstrapContext context) {
///     print("Application is starting...");
///   }
///
///   @override
///   void onReady(ConfigurableApplicationContext context, Duration timeTaken) {
///     print("Application ready in ${timeTaken.inMilliseconds}ms");
///   }
///
///   @override
///   void onFailed(ConfigurableApplicationContext? context, Object exception) {
///     print("Application failed to start: $exception");
///   }
/// }
/// ```
/// {@endtemplate}
abstract class ApplicationRunListener {
  /// Called immediately when the application starts.
  ///
  /// Use this hook for **very early initialization logic**, such as logging
  /// startup banners or initializing bootstrap resources.
  FutureOr<void> onStarting(ConfigurableBootstrapContext context, Class<Object> mainClass) {}

  /// Called once the application environment has been prepared.
  ///
  /// This is typically where you can **inspect or modify environment variables,
  /// configuration files, or system properties** before the application context
  /// is created.
  FutureOr<void> onEnvironmentPrepared(ConfigurableBootstrapContext context, ConfigurableEnvironment environment) {}

  /// Called after the application context has been created but not yet loaded.
  ///
  /// Allows for **programmatic modifications of the context** before pods or
  /// components are loaded into it.
  FutureOr<void> onContextPrepared(ConfigurableApplicationContext context) {}

  /// Called when the application context has loaded all configurations.
  ///
  /// This happens **before the context is refreshed**. It is useful for
  /// validating configurations or setting up monitoring tools.
  FutureOr<void> onContextLoaded(ConfigurableApplicationContext context) {}

  /// Called after the application context has been refreshed and started.
  ///
  /// Provides the [timeTaken] to start the context. This is useful for
  /// logging startup performance or initializing runtime services.
  FutureOr<void> onStarted(ConfigurableApplicationContext context, Duration timeTaken) {}

  /// Called when the application is fully ready to service requests.
  ///
  /// This is the **final lifecycle stage** before the application begins
  /// handling traffic. Use this to trigger tasks that require a fully
  /// initialized system.
  FutureOr<void> onReady(ConfigurableApplicationContext context, Duration timeTaken) {}

  /// Called if the application fails to start.
  ///
  /// Provides both the [context] (may be `null` if initialization failed
  /// very early) and the [exception] that caused the failure.
  ///
  /// Use this to log or report startup errors.
  FutureOr<void> onFailed(ConfigurableApplicationContext? context, Object exception) {}
}

/// {@template jet_application_hook}
/// A hook interface for integrating with the lifecycle of a [Application].
///
/// Implementations of this interface can register listeners that observe and
/// react to application startup events such as context preparation, environment
/// loading, and shutdown.
///
/// This is useful for frameworks or extensions that want to plug into the
/// application bootstrap process without modifying the application code.
///
/// Example:
/// ```dart
/// class LoggingHook implements ApplicationHook {
///   @override
///   ApplicationRunListener getRunListener(Application app) {
///     return LoggingRunListener(app);
///   }
/// }
/// ```
/// {@endtemplate}
abstract interface class ApplicationHook {
  /// {@macro jet_application_hook}
  ///
  /// Returns a [ApplicationRunListener] that will be attached to the
  /// lifecycle of the given [jetApplication].
  ApplicationRunListener getRunListener(JetApplication jetApplication);
}