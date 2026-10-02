import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../utils/constant.dart';

/// {@template jetleaf_watcher}
/// Debounced project watcher for [JetleafVM].
///
/// Internal: watches `lib/`, `bin/`, `test/`, `pubspec.yaml` and
/// `.dart_tool/package_config.json`. Build outputs (`.jetleaf/`,
/// `.dart_tool/`, `build/`, `.jetleaf/`) are ignored. Bursts of filesystem
/// events are coalesced into a single [onChanged] call after [debounce].
///
/// {@endtemplate}
@internal
final class JetleafWatcher {
  /// {@macro jetleaf_watcher}
  JetleafWatcher({
    required this.projectRoot,
    required this.onChanged,
    this.debounce = const Duration(milliseconds: 750),
  });

  /// Project root under watch.
  final Directory projectRoot;

  /// Quiet period coalescing filesystem bursts.
  final Duration debounce;

  /// Called with the absolute paths that changed during the debounce window.
  final Future<void> Function(List<String> changedPaths) onChanged;

  /// Active filesystem subscriptions.
  final List<StreamSubscription<FileSystemEvent>> _subscriptions = [];

  /// Paths accumulated during the debounce window.
  final Set<String> _pending = {};

  /// Pending debounce timer.
  Timer? _timer;

  /// Whether [start] has been called without [stop].
  bool _running = false;

  /// Starts watching. Idempotent.
  ///
  /// **Returns:** when all watches are installed.
  Future<void> start() async {
    if (_running) return;
    _running = true;

    for (final sub in ['lib', 'bin', 'test']) {
      final dir = Directory(p.join(projectRoot.path, sub));
      if (await dir.exists()) {
        _subscriptions.add(
          dir.watch(recursive: true).listen(_handleEvent),
        );
      }
    }
    
    for (final file in ['pubspec.yaml', '.dart_tool/package_config.json']) {
      final f = File(p.join(projectRoot.path, file));
      if (await f.exists()) {
        _subscriptions.add(
          f.parent.watch().listen(_handleEvent),
        );
      }
    }
  }

  /// Buffers one filesystem event into the debounce window.
  ///
  /// **Parameters:**
  /// - [event]: raw filesystem event (ignored when not running or when
  ///   [_isIgnored] matches).
  void _handleEvent(FileSystemEvent event) {
    if (!_running) return;
    if (_isIgnored(event.path)) return;
    _pending.add(p.normalize(event.path));
    _timer?.cancel();
    _timer = Timer(debounce, () {
      if (!_running) return;
      final changed = _pending.toList();
      _pending.clear();
      unawaited(onChanged(changed));
    });
  }

  /// Decides whether [path] is build output, tool state, or a
  /// non-Dart file (all ignored) versus watched sources/manifests.
  ///
  /// **Parameters:**
  /// - [path]: raw event path.
  ///
  /// **Returns:** true when the event must be dropped.
  bool _isIgnored(String path) {
    final normalized = p.normalize(path);
    // Generated workspace state is written by the manager while source files
    // are being watched. Ignoring it prevents the manager from reacting to
    // its own cache, VM state, and diagnostic writes.
    for (final ignored in [
      '/${Constant.WORKSPACE_DIR_NAME}/',
      '/.dart_tool/',
      '/build/',
    ]) {
      if (normalized.contains(ignored)) return true;
    }
    if (normalized.endsWith('pubspec.yaml')) return false;
    if (normalized.endsWith('package_config.json')) return false;
    return !normalized.endsWith('.dart');
  }

  /// Stops watching and releases all subscriptions.
  ///
  /// **Returns:** when everything is cancelled.
  Future<void> stop() async {
    _running = false;
    _timer?.cancel();
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
  }
}
