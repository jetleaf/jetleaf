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

/// {@template application_shutdown_handlers}
/// Interface used to register or remove shutdown handlers for the Dart VM,
/// typically during JetLeaf application shutdown.
///
/// These handlers are executed **sequentially** in the order they were added,
/// after the `ConfigurableApplicationContext` has been closed but before
/// the Dart process exits. This allows for cleanup operations such as:
/// - Closing database connections
/// - Flushing logs
/// - Releasing file handles or sockets
///
/// ### Example:
/// ```dart
/// class DefaultShutdownHandlers implements ApplicationShutdownHandler {
///   final List<Runnable> _handlers = [];
///
///   @override
///   void add(Runnable runnable) => _handlers.add(runnable);
///
///   @override
///   void remove(Runnable runnable) => _handlers.remove(runnable);
///
///   void runAll() {
///     for (final handler in _handlers) {
///       handler.run();
///     }
///   }
/// }
///
/// final shutdownHandlers = DefaultShutdownHandlers();
///
/// shutdownHandlers.add(() => print('Closing DB...'));
/// shutdownHandlers.add(() => print('Flushing logs...'));
/// ```
/// {@endtemplate}
abstract interface class ApplicationShutdownHandler {
  /// {@template add_shutdown_handler}
  /// Registers a shutdown [runnable] that will be called when the application
  /// is shutting down.
  ///
  /// Actions are executed **in the order they were added**.
  ///
  /// ### Example:
  /// ```dart
  /// shutdownHandlers.add(() => print('Disconnecting...'));
  /// ```
  /// {@endtemplate}
  void add(Runnable runnable);

  /// {@template remove_shutdown_handler}
  /// Removes a previously registered shutdown [runnable], if it exists.
  ///
  /// If the same function reference was registered multiple times, only the
  /// first match will be removed.
  ///
  /// ### Example:
  /// ```dart
  /// void clean() => print('Cleaning up...');
  ///
  /// shutdownHandlers.add(clean);
  /// shutdownHandlers.remove(clean);
  /// ```
  /// {@endtemplate}
  void remove(Runnable runnable);
}