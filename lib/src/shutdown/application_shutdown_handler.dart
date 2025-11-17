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

import 'package:jetleaf_lang/lang.dart';

/// {@template application_shutdown_handler}
/// Represents a registry of shutdown actions (tasks) that are executed when
/// the application is in the process of shutting down.
///
/// Implementations of this interface are responsible for managing and
/// executing shutdown tasks in a controlled manner, ensuring that
/// resources are released properly and any cleanup logic is executed.
///
/// Shutdown tasks are typically added during the lifecycle of an
/// application for purposes such as:
/// - Closing open files or database connections
/// - Terminating background threads or isolates
/// - Cleaning up temporary directories or caches
/// - Sending final logs or telemetry data
///
/// ### Example usage:
/// ```dart
/// final ApplicationShutdownHandler shutdownHandlers = ...;
///
/// // Add a shutdown task
/// shutdownHandlers.add(() => print('Disconnecting resources...'));
///
/// // Remove a previously registered task
/// void cleanup() => print('Cleaning temporary files...');
/// shutdownHandlers.add(cleanup);
/// shutdownHandlers.remove(cleanup);
/// ```
///
/// ### Implementation Notes:
/// - Tasks should ideally be **idempotent**, as multiple shutdown
///   signals may be received depending on the runtime environment.
/// - Tasks should be **short-running** and non-blocking, or if long-running,
///   the implementation should handle them asynchronously.
/// - Implementations may execute tasks **in order of addition** or in reverse,
///   depending on the design. This interface does not mandate a specific ordering.
/// - The interface is designed to be **thread-safe**; implementations should
///   handle concurrent calls to `add` and `remove`.
/// {@endtemplate}
abstract interface class ApplicationShutdownHandler {
  /// {@macro add_shutdown_handler}
  ///
  /// Registers a shutdown [runnable] that will be called when the application
  /// is shutting down.
  ///
  /// Actions are executed **in the order they were added**, unless the
  /// implementation specifies reverse execution.
  void add(Runnable runnable);

  /// {@macro remove_shutdown_handler}
  ///
  /// Removes a previously registered shutdown [runnable], if it exists.
  ///
  /// If the same function reference was registered multiple times, only the
  /// first match will be removed.
  void remove(Runnable runnable);
}