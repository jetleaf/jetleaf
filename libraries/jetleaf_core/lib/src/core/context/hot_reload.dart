import 'package:jetleaf_core/lang.dart';

import 'base/application_context.dart';
import 'event/application_event.dart';

/// {@template hot_reload_delta}
/// Describes the incremental changes detected between two application scans
/// during a **Hot Reload** or **Hot Restart** cycle.
///
/// Computed by comparing the previous `RuntimeManifest` fingerprint table
/// against the newly scanned AST, pod definitions, and assets.
///
/// ### Usage Example
/// ```dart
/// final delta = HotReloadDelta(
///   modifiedClasses: {Class<UserController>()},
///   modifiedAssetPaths: {'templates/index.jtl'},
/// );
/// if (delta.isStructuralChange()) {
///   // Trigger Hot Restart
/// }
/// ```
/// {@endtemplate}
final class HotReloadDelta with EqualsAndHashCode {
  /// Reflective [Class] handle for [HotReloadDelta].
  static final Class<HotReloadDelta> CLASS = Class<HotReloadDelta>(null, PackageNames.CORE);

  final Set<Class> _modifiedClasses;
  final Set<String> _addedPodNames;
  final Set<String> _modifiedPodNames;
  final Set<String> _removedPodNames;
  final Set<String> _modifiedAssetPaths;
  final bool _structuralChange;

  /// {@macro hot_reload_delta}
  HotReloadDelta({
    Set<Class> modifiedClasses = const {},
    Set<String> addedPodNames = const {},
    Set<String> modifiedPodNames = const {},
    Set<String> removedPodNames = const {},
    Set<String> modifiedAssetPaths = const {},
    bool structuralChange = false,
  })  : _modifiedClasses = Set.unmodifiable(modifiedClasses),
        _addedPodNames = Set.unmodifiable(addedPodNames),
        _modifiedPodNames = Set.unmodifiable(modifiedPodNames),
        _removedPodNames = Set.unmodifiable(removedPodNames),
        _modifiedAssetPaths = Set.unmodifiable(modifiedAssetPaths),
        _structuralChange = structuralChange;

  /// Empty delta representing no detected changes.
  static final HotReloadDelta empty = HotReloadDelta();

  /// Returns the set of [Class] descriptors whose AST body or annotations
  /// changed in this reload cycle.
  Set<Class> getModifiedClasses() => _modifiedClasses;

  /// Returns the names of newly discovered pods added in this reload cycle.
  Set<String> getAddedPodNames() => _addedPodNames;

  /// Returns the names of existing pods whose definitions or constructors
  /// changed in this reload cycle.
  Set<String> getModifiedPodNames() => _modifiedPodNames;

  /// Returns the names of pods removed in this reload cycle.
  Set<String> getRemovedPodNames() => _removedPodNames;

  /// Returns the asset paths (`.yaml`, `.properties`, `.html`, `.jtl`, `.sql`)
  /// modified in this reload cycle.
  Set<String> getModifiedAssetPaths() => _modifiedAssetPaths;

  /// Returns `true` if constructor signatures of singleton pods or class
  /// hierarchies changed in a way that requires re-instantiating affected pods
  /// or performing a full Hot Restart.
  bool isStructuralChange() => _structuralChange;

  /// Returns `true` if no classes, pods, or assets changed.
  bool isEmpty() => _modifiedClasses.isEmpty &&
    _addedPodNames.isEmpty &&
    _modifiedPodNames.isEmpty &&
    _removedPodNames.isEmpty &&
    _modifiedAssetPaths.isEmpty &&
    !_structuralChange;

  @override
  List<Object?> equalizedProperties() => [
    _modifiedClasses,
    _addedPodNames,
    _modifiedPodNames,
    _removedPodNames,
    _modifiedAssetPaths,
    _structuralChange,
  ];
}

/// {@template refreshable_pod}
/// Lifecycle contract implemented by stateful pods and framework subsystems
/// that participate in **Hot Reload** delta updates without tearing down the
/// entire application context.
///
/// ### Usage Example
/// ```dart
/// final class MyRouteRegistry implements RefreshablePod {
///   @override
///   Future<void> onHotReload(HotReloadDelta delta, ApplicationContext context) async {
///     for (final cls in delta.getModifiedClasses()) {
///       // Re-register routes for modified controller classes
///     }
///   }
/// }
/// ```
/// {@endtemplate}
abstract interface class RefreshablePod {
  /// Reflective [Class] handle for [RefreshablePod].
  static final Class<RefreshablePod> CLASS = Class<RefreshablePod>(null, PackageNames.CORE);

  /// Invoked after Dart VM `reloadSources` completes during a Hot Reload.
  Future<void> onHotReload(HotReloadDelta delta, ApplicationContext context);
}

/// {@template hot_reload_event}
/// [ApplicationContextEvent] published after Dart VM `reloadSources` and
/// selective container refresh complete during a **Hot Reload**.
///
/// Listeners can inspect [getDelta] to react to modified classes, pod
/// definitions, or asset files.
/// {@endtemplate}
class HotReloadEvent extends ApplicationContextEvent {
  /// The incremental [HotReloadDelta] computed for this reload cycle.
  final HotReloadDelta _delta;

  /// {@macro hot_reload_event}
  HotReloadEvent(super.source, this._delta);

  /// {@macro hot_reload_event}
  HotReloadEvent.withClock(super.source, this._delta, super.clock) : super.withClock();

  /// Returns the [HotReloadDelta] describing what changed in this reload cycle.
  HotReloadDelta getDelta() => _delta;

  @override
  String getPackageName() => PackageNames.CORE;
}

/// {@template hot_restart_event}
/// [ApplicationContextEvent] published immediately before
/// [ConfigurableApplicationContext] tears down for a **Hot Restart** inside the
/// same resident VM isolate.
///
/// Pods holding OS resources (HTTP sockets, database pools, file locks) can
/// observe this event to release or hand off resources cleanly prior to
/// re-bootstrap.
/// {@endtemplate}
class HotRestartEvent extends ApplicationContextEvent {
  /// Optional [HotReloadDelta] that triggered the Hot Restart, if available.
  final HotReloadDelta? _delta;

  /// {@macro hot_restart_event}
  HotRestartEvent(super.source, [this._delta]);

  /// {@macro hot_restart_event}
  HotRestartEvent.withClock(super.source, super.clock, [this._delta]) : super.withClock();

  /// Returns the [HotReloadDelta] that triggered the Hot Restart, or `null` if
  /// manually requested.
  HotReloadDelta? getDelta() => _delta;

  @override
  String getPackageName() => PackageNames.CORE;
}

/// {@template hot_reload_coordinator}
/// Process-wide coordinator tracking active [ApplicationContext] instances so
/// tooling (`jl dev` / `JetleafVM`) can dispatch Hot Reload and Hot Restart
/// notifications into the running isolate after `vmService.reloadSources(...)`.
/// {@endtemplate}
final class HotReloadCoordinator {
  HotReloadCoordinator._();

  static final Set<Future<void> Function(HotReloadDelta)> _reloadHandlers = {};
  static final Set<Future<void> Function([HotReloadDelta?])> _restartHandlers = {};

  /// Registers a context's [onReload] and [onRestart] callbacks.
  static void register({
    required Future<void> Function(HotReloadDelta delta) onReload,
    required Future<void> Function([HotReloadDelta? delta]) onRestart,
  }) {
    _reloadHandlers.add(onReload);
    _restartHandlers.add(onRestart);
  }

  /// Unregisters a context's [onReload] and [onRestart] callbacks on close.
  static void unregister({
    required Future<void> Function(HotReloadDelta delta) onReload,
    required Future<void> Function([HotReloadDelta? delta]) onRestart,
  }) {
    _reloadHandlers.remove(onReload);
    _restartHandlers.remove(onRestart);
  }

  /// Resolves the reflective [Class] handle for a metadata [declaration].
  ///
  /// Declarations produced by the AOT scan carry `Object` as their
  /// [ClassDeclaration.getType] placeholder because no live [Type] exists at
  /// build time. Building the handle from the qualified name (or, failing
  /// that, directly from the declaration) preserves the real class name.
  ///
  /// **Parameters:**
  /// - [declaration]: matched class metadata from [Runtime.getAllClasses].
  ///
  /// **Returns:** a [Class] whose name matches [declaration].
  static Class classForDeclaration(ClassDeclaration declaration) {
    try {
      return Class.fromQualifiedName(declaration.getQualifiedName());
    } on Object {
      return Class.declared(declaration, ProtectionDomain.current());
    }
  }

  /// Computes a [HotReloadDelta] from [changedUris] and dispatches it to all
  /// active registered application contexts.
  static Future<void> notifyReload([List<String> changedUris = const []]) async {
    if (_reloadHandlers.isEmpty) return;

    final modifiedClasses = <Class>{};
    final modifiedAssets = <String>{};

    for (final uri in changedUris) {
      if (!uri.endsWith('.dart')) {
        modifiedAssets.add(uri);
      }
    }

    if (changedUris.any((u) => u.endsWith('.dart'))) {
      for (final decl in Runtime.getAllClasses()) {
        final libUri = decl.getLibrary().getUri();
        if (changedUris.any((u) => libUri == u || libUri.endsWith(u) || u.endsWith(libUri))) {
          modifiedClasses.add(classForDeclaration(decl));
        }
      }
    }

    final delta = HotReloadDelta(
      modifiedClasses: modifiedClasses,
      modifiedAssetPaths: modifiedAssets,
    );

    for (final handler in _reloadHandlers.toList(growable: false)) {
      await handler(delta);
    }
  }

  /// Dispatches a Hot Restart notification to all active registered contexts.
  static Future<void> notifyRestart([HotReloadDelta? delta]) async {
    for (final handler in _restartHandlers.toList(growable: false)) {
      await handler(delta);
    }
  }
}