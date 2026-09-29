import 'dart:async';

import 'package:meta/meta.dart';

/// {@template jetleaf_decorator}
/// Base lifecycle + event contract for the `jl dev` runtime.
///
/// Internal: [JetleafVM] is the only implementation. Exists so lifecycle
/// handling (start/stop/dispose, event fan-out) stays in one place while
/// stub generation ([EntryWriter]) and discovery ([Discoverable]) compose
/// above it.
///
/// {@endtemplate}
@internal
abstract class JetleafDecorator {
  /// {@macro jetleaf_decorator}
  JetleafDecorator();

  /// Broadcast stream of lifecycle/log events (JSON-style maps).
  ///
  /// **Returns:** the event stream.
  Stream<Map<String, Object?>> get onEvent;

  /// Starts the decorator.
  ///
  /// **Returns:** only when fully stopped (process exit code).
  Future<int> start();

  /// Requests a graceful stop.
  ///
  /// **Parameters:**
  /// - [code]: process exit code to complete with.
  ///
  /// **Returns:** when shutdown is scheduled.
  Future<void> stop([int code = 0]);

  /// Releases all resources (processes, sockets, watchers, subscriptions).
  ///
  /// **Returns:** when everything is torn down.
  Future<void> dispose();
}