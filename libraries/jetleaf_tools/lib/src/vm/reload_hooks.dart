// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & Jetleaf Contributors. All rights reserved.
//
// This source file is part of the Jetleaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
//
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

/// Describes where an explicit reload/restart request came from.
///
/// Tooling (the `jl` CLI, the VS Code panel, a future Jetleaf extension, or
/// an external Dart command) sends a request with one of these origins so a
/// registered handler can decide how to react.
enum ToolingTrigger {
  /// A panel action in a developer tool (for example the VS Code side panel).
  panel,

  /// A developer command such as a future `jl reload` / `jl restart`.
  command,

  /// An automatic file-system change observed by the manager's watcher.
  fileChange,

  /// A trigger raised by external Dart tooling or a third-party integration.
  external,
}

/// A request to reload source in one or more live entry VMs.
final class ReloadRequest {
  /// Where the request originated.
  final ToolingTrigger trigger;

  /// Entry key to reload, or `null` for every live entry.
  final String? entry;

  /// Absolute URIs known to have changed, or an empty list for "reload all".
  final List<String> changedUris;

  /// Creates a reload request.
  const ReloadRequest({
    this.trigger = ToolingTrigger.external,
    this.entry,
    this.changedUris = const [],
  });
}

/// A request to restart one or more live entry VMs.
final class RestartRequest {
  /// Where the request originated.
  final ToolingTrigger trigger;

  /// Entry key to restart, or `null` for every live entry.
  final String? entry;

  /// Creates a restart request.
  const RestartRequest({
    this.trigger = ToolingTrigger.external,
    this.entry,
  });
}

/// Result of handling a reload or restart request.
final class ReloadOutcome {
  /// Whether the request was handled successfully.
  final bool ok;

  /// Entry identities that were actually reloaded/restarted.
  final List<String> entries;

  /// Optional human-readable detail surfaced to the caller.
  final String? message;

  /// Creates an outcome.
  const ReloadOutcome({
    required this.ok,
    this.entries = const [],
    this.message,
  });

  /// A successful no-op outcome.
  static const ReloadOutcome none = ReloadOutcome(ok: true);

  /// A failed outcome carrying [message].
  static ReloadOutcome failure(String message) =>
      ReloadOutcome(ok: false, message: message);
}

/// Decides what happens when tooling requests a reload.
typedef ReloadHandler = Future<ReloadOutcome> Function(ReloadRequest request);

/// Decides what happens when tooling requests a restart.
typedef RestartHandler = Future<ReloadOutcome> Function(RestartRequest request);

/// Central hook point for reload and restart requests raised by tooling.
///
/// The manager calls [reload] / [restart] for every explicit trigger. By
/// default the built-in VM behaviour (registered by `JetleafVM`) runs. Any
/// library can replace a handler with [onReload] / [onRestart] to "key into"
/// the request and decide what happens, for example to reload a subset of
/// entries, delegate to a remote worker, or refuse a restart while a
/// transaction is in flight.
///
/// Handlers are process-wide by design: a single manager serves every entry
/// of a project, and the decision is a tooling concern rather than an
/// application-pod concern. Application-level hooks live in
/// `HotReloadCoordinator` inside the target isolate.
final class ReloadHooks {
  ReloadHooks._();

  static ReloadHandler? _reloadHandler;
  static RestartHandler? _restartHandler;

  /// Registers the handler used for reload requests.
  ///
  /// Pass `null` to restore the built-in fallback.
  static void onReload(ReloadHandler? handler) => _reloadHandler = handler;

  /// Registers the handler used for restart requests.
  ///
  /// Pass `null` to restore the built-in fallback.
  static void onRestart(RestartHandler? handler) => _restartHandler = handler;

  /// Dispatches [request] to the registered reload handler, or [fallback]
  /// when none is registered.
  static Future<ReloadOutcome> reload(
    ReloadRequest request, {
    required ReloadHandler fallback,
  }) =>
      (_reloadHandler ?? fallback)(request);

  /// Dispatches [request] to the registered restart handler, or [fallback]
  /// when none is registered.
  static Future<ReloadOutcome> restart(
    RestartRequest request, {
    required RestartHandler fallback,
  }) =>
      (_restartHandler ?? fallback)(request);

  /// Clears registered handlers. Intended for tests and host shutdown.
  static void reset() {
    _reloadHandler = null;
    _restartHandler = null;
  }
}