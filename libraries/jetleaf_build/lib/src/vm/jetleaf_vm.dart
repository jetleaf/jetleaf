import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:frontend_server_client/frontend_server_client.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import '../cache/indexer/declaration_builder.dart';
import '../cache/indexer/file_discovery.dart';
import '../cache/manager/cacheable_manager.dart';
import '../cache/scanner/cache_scanners.dart';
import '../utils/constant.dart';
import '../utils/utils.dart';
import 'jetleaf_decorator.dart';
import 'project_watcher.dart';

part 'discoverable.dart';
part 'entry_state.dart';
part 'entry_writer.dart';

/// {@template vm_paths}
/// Centralized paths and package-config resolution for [JetleafVM].
///
/// Sealed helpers (`abstract final`, static only): every file location the
/// manager, its clients and its tests share — the human-readable
/// `Jetleaf.VM` array, the machine-only manager sidecar, per-entry
/// snapshots, and the `package_config.json` lookup.
///
/// {@endtemplate}
abstract final class JetleafVmPaths {
  /// {@macro vm_paths}
  JetleafVmPaths._();

  /// Name of the human-readable entry-state file at the project root
  /// (next to `pubspec.yaml`). JSON array, 4-space indent, one object
  /// per entry. Written on every state change, deleted on clean stop.
  static const String vmFileName = 'Jetleaf.VM';

  /// Internal manager metadata (pid, control port). Machine-only sidecar
  /// next to the old `dev.json` location; `Jetleaf.VM` stays a pure
  /// human-readable entry array.
  static const String managerRelativePath =
      '.dart_tool/jetleaf_build/manager.json';

  /// Per-entry incremental snapshots live here.
  static const String entrySnapshotDir =
      '.dart_tool/jetleaf_build/entries';

  /// Resolves the `package_config.json` for [root], searching upward so
  /// workspace members (which keep no local
  /// `.dart_tool/package_config.json`) inherit the workspace root config.
  ///
  /// **Parameters:**
  /// - [root]: project root to start searching from.
  ///
  /// **Returns:** an absolute path. Throws [StateError] when nothing is
  /// found — callers must fail fast instead of booting a VM that cannot
  /// resolve `package:` imports.
  static String resolvePackagesJson(Directory root) {
    var dir = root;
    while (true) {
      final candidate =
          File(p.join(dir.path, '.dart_tool', 'package_config.json'));
      if (candidate.existsSync()) return candidate.absolute.path;
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
    throw StateError(
        'No .dart_tool/package_config.json found from ${root.path} upward. '
        'Run `dart pub get` in the workspace root.');
  }
}

/// {@template warm_summary}
/// Result of a one-shot cache warm run.
///
/// Private to the `jetleaf_vm` library: counts of everything the
/// `FileDiscovery` → `DeclarationBuilder` → `CacheWriter` pipeline found
/// and wrote, plus the wall-clock cost.
///
/// {@endtemplate}
final class _WarmSummary {
  /// {@macro warm_summary}
  const _WarmSummary({
    required this.packageName,
    required this.fileCount,
    required this.componentCount,
    required this.libraryCount,
    required this.packageCount,
    required this.assetCount,
    required this.fingerprint,
    required this.durationMs,
  });

  /// Package name read from the project `pubspec.yaml`.
  final String packageName;

  /// Dart files discovered (including tests).
  final int fileCount;

  /// Components in the test cache (superset incl. tests).
  final int componentCount;

  /// Distinct libraries across all components.
  final int libraryCount;

  /// Packages in the test cache summary.
  final int packageCount;

  /// Assets in the test cache summary.
  final int assetCount;

  /// Production fingerprint written (used as the warm identity).
  final String fingerprint;

  /// Wall-clock cost in milliseconds.
  final int durationMs;
}

/// Live backend for one entry: incremental compiler + VM process +
/// debugger connection.
///
/// Private to the `jetleaf_vm` library, keyed per entry in
/// [JetleafVM._live] instead of the old single global VM.
final class _LiveEntry {
  /// Incremental compiler for this entry's stub.
  FrontendServerClient? frontend;

  /// Running VM process, when booted.
  Process? process;

  /// Debugger connection, when the VM service is up.
  VmService? service;

  /// WebSocket URI of the entry VM service, when connected.
  String? vmServiceUri;

  /// Absolute path of the last compiled snapshot, when any.
  String? snapshotPath;

  /// True while a run occupies this backend.
  bool busy = false;

  /// Completes when the boot that created this backend finishes
  /// (success or failure). Lets runs wait instead of racing the boot.
  Completer<void>? boot;
}

/// {@template jetleaf_vm}
/// One manager for all VMs running a project.
///
/// End of the `EntryWriter → Discoverable → JetleafVM` chain (plus
/// [JetleafDecorator] lifecycle): discovers `@JetleafEntry` /
/// `@JetleafTest` on `void main()`, warms the shared `.jetleaf/` cache
/// once, boots one VM per entry (each with its own frontend server,
/// snapshot, process and stub), tracks per-entry state
/// (discovered/warming/parked/running/failed/stopped), shuts one or all
/// down on request, serves `jl run` / `jl test` / `jl status` / `jl stop`
/// clients over a loopback control channel, and publishes the
/// `Jetleaf.VM` entry array at the project root.
///
/// Obtain via [JetleafVM.instance]; every caller goes through it.
///
/// {@endtemplate}
final class JetleafVM extends Discoverable implements JetleafDecorator {
  /// {@macro jetleaf_vm}
  JetleafVM._();

  /// The single manager. Not `const`: live processes, sockets and
  /// completers are inherently mutable.
  static final JetleafVM instance = JetleafVM._();

  /// Project root under management (set by [serve]).
  late Directory _root;

  /// When true, stdout carries JSON lines instead of human logs.
  bool _machine = false;

  /// When true, entry VMs boot lazily on first run instead of eagerly.
  bool _lazy = false;

  /// When true, in-isolate scan logs stream to the dev terminal
  /// (`[scan] …` lines) instead of staying silent.
  bool _verbose = false;

  /// Scoped entry allowlist from `--path` (null = full discovery).
  /// Persists across rewarm so rescans never pick up other entries.
  List<String>? _only;

  /// Discovered entries by project-relative file key.
  final Map<String, EntryRecord> _entries = {};

  /// Runtime statuses by project-relative file key.
  final Map<String, EntryStatus> _states = {};

  /// Live backends by project-relative file key.
  final Map<String, _LiveEntry> _live = {};

  /// Filesystem watcher (save-time rewarm + reload).
  JetleafWatcher? _watcher;

  /// Loopback control socket for CLI clients.
  ServerSocket? _control;

  /// Bound control port, published via the manager sidecar.
  int? _controlPort;

  /// Broadcast event bus (lifecycle + log frames for subscribers).
  final StreamController<Map<String, Object?>> _events =
      StreamController<Map<String, Object?>>.broadcast();

  /// Completes with the process exit code on [stop].
  final Completer<int> _exitCode = Completer<int>();

  /// OS signal subscriptions (cancelled on [dispose]).
  final List<StreamSubscription<ProcessSignal>> _signalSubs = [];

  /// True once shutdown has started; guards re-entry and watcher work.
  bool _stopping = false;

  /// True while the initial boot or a rewarm owns the cache/VMs.
  bool _warming = false;

  /// ISO-8601 manager start time, published via the manager sidecar.
  String? _startedAt;

  @override
  Stream<Map<String, Object?>> get onEvent => _events.stream;

  /// Validates [root], then [start]s.
  ///
  /// **Parameters:**
  /// - [root]: project root to manage.
  /// - [machine]: JSON-lines output instead of human logs.
  /// - [lazy]: boot entry VMs on first run instead of eagerly.
  /// - [only]: scoped entry allowlist (`--path`, repeatable). Only these
  ///   files are detected and booted; watcher rewarm still tracks the
  ///   project so dependency edits reload them.
  /// - [verbose]: stream in-isolate scan logs (`[scan] …`) to the dev
  ///   terminal; answers "did the scan run in dev or at run time, and
  ///   what did it do".
  ///
  /// **Returns:** the process exit code.
  Future<int> serve(Directory root,
      {bool machine = false, bool lazy = false, List<String>? only, bool verbose = false}) {
    _root = root;
    _machine = machine;
    _lazy = lazy;
    _only = only;
    _verbose = verbose;
    return start();
  }

  /// One-shot warm for CI: discovers entries, prints them, warms the
  /// shared cache and exits. No VMs are booted, no state files written.
  /// Used by `jl dev --once`.
  ///
  /// **Parameters:**
  /// - [root]: project root to warm.
  /// - [machine]: JSON-lines output instead of human logs.
  ///
  /// **Returns:** the process exit code (0 ok, 1 failed).
  Future<int> warmOnce(Directory root, {required bool machine}) async {
    try {
      final registry = await discoverEntries(root,
          onWarning: (message) {
        if (machine) {
          print(jsonEncode({'type': 'warning', 'message': message}));
        } else {
          print('Warning: $message');
        }
      });
      if (!machine) {
        for (final entry in registry.entries) {
          print('${entry.kind.name}  ${entry.file}::main');
        }
        print('found ${registry.entries.length} '
            'entr${registry.entries.length == 1 ? 'y' : 'ies'} '
            '(${registry.appCount} app, ${registry.testCount} test)');
      } else {
        print(jsonEncode(
            {'type': 'entries', 'entries': registry.toJson()}));
      }
      final summary = await _warmProject(root);
      if (!machine) {
        print('Warmed ${summary.componentCount} components, '
            '${summary.libraryCount} libraries.');
      } else {
        print(jsonEncode({
          'type': 'warm_complete',
          'components': summary.componentCount,
          'libraries': summary.libraryCount,
        }));
      }
      return 0;
    } catch (e) {
      if (machine) {
        print(jsonEncode({'type': 'warm_error', 'error': '$e'}));
      } else {
        stderr.writeln('Error: warm failed: $e');
      }
      return 1;
    }
  }

  /// Boots the manager for [root] and serves until stopped.
  ///
  /// Validates the project, prints the banner, binds the control
  /// channel, starts the watcher, then warms + boots entries in the
  /// background.
  ///
  /// **Returns:** completes with the process exit code.
  @override
  Future<int> start() async {
    _startedAt = DateTime.now().toIso8601String();
    if (!RuntimeUtils.isJetLeafBuildProject(_root)) {
      _log('Error: not a jetleaf_build project: ${_root.path} '
          '(expected `jetleaf_build:` in pubspec.yaml or .dart_tool/package_config.json)');
      return 1;
    }

    _watchSignals();
    final packageName = _resolvePackageName(_root);
    _printBanner(packageName);

    await _ensureGitignore();
    await _bindControl();
    // Machine-detectable readiness (used by the VS Code `jl dev`
    // background task matcher). Printed after the port is bound.
    _log('manager listening on 127.0.0.1:$_controlPort');
    _writeManagerFile();
    _writeVmFile();

    _watcher = JetleafWatcher(
      projectRoot: _root,
      onChanged: _onFilesChanged,
    );
    await _watcher!.start();

    _warming = true;
    unawaited(_bootSequence());
    return _exitCode.future;
  }

  /// Prints the startup banner (human mode) / emits it (machine mode).
  ///
  /// Art comes from the shared [Constant.BANNER_ART] so every JetLeaf
  /// tool prints the same brand.
  ///
  /// **Parameters:**
  /// - [packageName]: resolved project package name.
  void _printBanner(String packageName) {
    final buf = StringBuffer(Constant.BANNER_ART.trim());
    buf.writeln();
    buf.writeln('project  $packageName');
    buf.writeln('root     ${_root.path}');
    buf.write('state    ./${JetleafVmPaths.vmFileName}');
    _log(buf.toString());
  }

  /// Runs the full warm pipeline for [dir]:
  /// `FileDiscovery` -> `DeclarationBuilder` -> `CacheWriter`
  /// (prod + test).
  ///
  /// Progress events go to [onEvent] as JSON-style maps
  /// (`warm_started`/`warm_progress`/`warm_complete`); human-readable
  /// printing is the caller's job.
  ///
  /// **Parameters:**
  /// - [dir]: project root to warm.
  /// - [onEvent]: optional progress sink.
  ///
  /// **Returns:** the [_WarmSummary] for the run. Throws on failure.
  static Future<_WarmSummary> _warmProject(
    Directory dir, {
    void Function(Map<String, Object?> event)? onEvent,
  }) async {
    final stopwatch = Stopwatch()..start();
    final packageName = _resolvePackageName(dir);
    onEvent?.call({
      'type': 'warm_started',
      'projectRoot': dir.path,
      'package': packageName
    });

    // 1. Discovery
    onEvent?.call(
        {'type': 'warm_progress', 'phase': 'discovery', 'status': 'scanning'});
    final discovery = FileDiscovery(dir);
    final files = await discovery.discover(
      skipTests: false,
      packagesToExclude: [],
      packagesToScan: [],
      filesToExclude: [],
    );
    final fileCount = files.dartFiles.length;
    onEvent?.call({
      'type': 'warm_progress',
      'phase': 'discovery',
      'filesFound': fileCount,
    });

    // 2. Analysis
    onEvent?.call({
      'type': 'warm_progress',
      'phase': 'analysis',
      'current': 0,
      'total': fileCount,
    });
    final components = await DeclarationBuilder()
        .build(files: files, packageName: packageName);
    onEvent?.call({
      'type': 'warm_progress',
      'phase': 'analysis',
      'current': fileCount,
      'total': fileCount,
      'components': components.length,
    });

    // 3. Write cache (prod + test, same layout as the old indexer daemon)
    onEvent?.call(
        {'type': 'warm_progress', 'phase': 'cache', 'status': 'writing'});
    final cacheWriter = CacheWriter(dir);

    final prodFingerprint = CacheManager.generateFingerprint(skipTests: true);
    final prodComponents = components
        .where((c) => !c.getLibrary().getUri().contains('/test/'))
        .toList();
    await cacheWriter.writeWithComponents(
      components: prodComponents,
      fingerprint: prodFingerprint,
      forTests: false,
    );

    final testFingerprint = CacheManager.generateFingerprint(skipTests: false);
    final testSummary = await cacheWriter.writeWithComponents(
      components: components,
      fingerprint: testFingerprint,
      forTests: true,
    );

    stopwatch.stop();
    final summary = _WarmSummary(
      packageName: packageName,
      fileCount: fileCount,
      componentCount: testSummary.components.length,
      libraryCount:
          components.map((c) => c.getLibrary().getUri()).toSet().length,
      packageCount: testSummary.packages.length,
      assetCount: testSummary.assets.length,
      fingerprint: prodFingerprint,
      durationMs: stopwatch.elapsedMilliseconds,
    );
    onEvent?.call({
      'type': 'warm_complete',
      'components': summary.componentCount,
      'libraries': summary.libraryCount,
      'packages': summary.packageCount,
      'assets': summary.assetCount,
      'fingerprint': summary.fingerprint,
      'durationMs': summary.durationMs,
    });
    return summary;
  }

  /// Reads the `name:` field from a pubspec.yaml.
  ///
  /// Manual line parsing is used on purpose: no yaml dependency here.
  ///
  /// **Parameters:**
  /// - [dir]: project root holding `pubspec.yaml`.
  ///
  /// **Returns:** the package name, or `unknown` when unreadable.
  static String _resolvePackageName(Directory dir) {
    try {
      for (final line in File('${dir.path}/pubspec.yaml').readAsLinesSync()) {
        if (line.trimLeft().startsWith('name:')) {
          return line.split(':').last.trim();
        }
      }
    } catch (_) {}
    return 'unknown';
  }

  // ------------------------------------------------------------ boot flow

  /// Background boot: discover entries, warm the shared cache once,
  /// then boot every entry VM (sequentially) unless `--lazy`.
  ///
  /// Runs detached from [start] so the banner + control channel are
  /// live immediately. Run requests during boot report busy.
  ///
  /// **Returns:** when all eager boots finished (or stopping began).
  Future<void> _bootSequence() async {
    try {
      if (_only != null) {
        _log('Scoped run (${_only!.length} path(s)), skipping full discovery.');
      } else {
        _log('Discovering entries ...');
      }
      await _rediscover(log: true);

      _log('Warming cache ...');
      final summary = await _warmProject(_root);
      for (final status in _states.values) {
        status.fingerprint = summary.fingerprint;
      }
      _log('Warmed ${summary.componentCount} components, '
          '${summary.libraryCount} libraries.');
      _writeVmFile();

      if (_lazy) {
        _log('Lazy mode: entry VMs boot on first run.');
      } else {
        for (final key in _entries.keys) {
          if (_stopping) break;
          await _bootEntry(key);
        }
      }
    } catch (e) {
      _emit({'type': 'daemon_error', 'error': e.toString()});
      _log('Failed to boot: $e');
    } finally {
      _warming = false;
    }
  }

  /// Re-runs analyzer discovery, adds new entries, drops deleted files.
  ///
  /// **Parameters:**
  /// - [log]: whether to log per-entry add/remove lines.
  ///
  /// **Returns:** when the registry, statuses and `Jetleaf.VM` are updated.
  Future<void> _rediscover({required bool log}) async {
    final registry = await discoverEntries(_root,
        only: _only,
        onWarning: (message) => _log('Warning: $message'));
    final seen = <String>{};
    for (final record in registry.entries) {
      seen.add(record.file);
      if (!_entries.containsKey(record.file)) {
        _entries[record.file] = record;
        _states[record.file] = EntryStatus(record: record);
        if (log) {
          final tag =
              record.kind == EntryKind.test ? '@JetleafTest' : '@JetleafEntry';
          _log('${record.kind == EntryKind.test ? 'test  ' : 'entry '} '
              '${record.file}::main  [$tag]');
        }
      } else {
        _entries[record.file] = record;
        _states[record.file]!.record = record;
      }
    }
    for (final key in _entries.keys.toList()) {
      if (!seen.contains(key)) {
        await stopEntry(key, quiet: true);
        _entries.remove(key);
        _states.remove(key);
        if (log) _log('removed $key (file deleted)');
      }
    }
    if (log) {
      final apps = registry.appCount;
      final tests = registry.testCount;
      _log('found ${registry.entries.length} '
          'entr${registry.entries.length == 1 ? 'y' : 'ies'} '
          '($apps app, $tests test)');
    }
    _writeVmFile();
  }

  // ---------------------------------------------------------- entry boot

  /// Matches both old (`Observatory listening on ...`) and current
  /// (`The Dart VM service is listening on ...`) SDK output.
  ///
  /// **Parameters:**
  /// - [line]: one stdout line from the child VM process.
  ///
  /// **Returns:** true on the VM-service banner line.
  static bool _isVmServiceLine(String line) =>
      line.contains('Observatory listening on') ||
      line.contains('VM service is listening on') ||
      line.contains('VM Service is listening on');

  /// Boots one entry VM: parked stub -> frontend compile -> snapshot
  /// -> VM process -> VM-service connect. Sets `warming`, then
  /// `parked` (or `failed` with [EntryStatus.lastError]).
  ///
  /// No-op when the entry already has a live backend.
  ///
  /// **Parameters:**
  /// - [key]: project-relative entry file key.
  ///
  /// **Returns:** when the VM is parked (or failed and recorded).
  Future<void> _bootEntry(String key) async {
    final record = _entries[key];
    if (record == null) return;
    final status = _states[key]!;
    if (_live.containsKey(key)) return;

    status.state = EntryState.warming;
    status.lastError = null;
    _writeVmFile();
    _log('warming $key ...');

    final live = _LiveEntry();
    live.boot = Completer<void>();
    _live[key] = live;
    try {
      await writeParkedEntryStub(_root, key, forTests: record.forTests, verbose: _verbose);

      final snapshotPath = snapshotPathFor(_root, key);
      await Directory(p.dirname(snapshotPath)).create(recursive: true);

      final platformDill = p.join(
        p.dirname(p.dirname(Platform.resolvedExecutable)),
        'lib',
        '_internal',
        'vm_platform_strong.dill',
      );
      if (!File(platformDill).existsSync()) {
        throw StateError('VM platform dill not found: $platformDill');
      }

      // The workspace root owns `.dart_tool/package_config.json`;
      // members usually have none — resolve upward and fail fast when
      // missing (a VM without package resolution compiles stubs that
      // can park but never run user code).
      final packagesPath = JetleafVmPaths.resolvePackagesJson(_root);
      _log('packages: $packagesPath');
      live.frontend = await FrontendServerClient.start(
        stubRootUriFor(_root, key),
        snapshotPath,
        platformDill,
        target: 'vm',
        fileSystemRoots: [_root.path],
        fileSystemScheme: 'org-dartlang-root',
        packagesJson: packagesPath,
        verbose:
            const bool.fromEnvironment('JL_FE_VERBOSE', defaultValue: false),
      );

      final compilation = await live.frontend!.compile();
      final compiled = compilation.dillOutput;
      if (compiled == null) {
        for (final line in compilation.compilerOutputLines.take(15)) {
          _log('  compile: $line');
        }
        throw StateError(
            'Frontend compile failed (${compilation.errorCount} errors)');
      }
      live.frontend!.accept();
      live.snapshotPath = compiled;
      status.snapshot = compiled;

      await _startVmProcess(key, live, compiled);

      status.state = EntryState.parked;
      status.pid = live.process?.pid;
      status.vmServiceUri = live.vmServiceUri;
      final identity = _vmIdentity(key, live);
      _log('active $identity');
    } catch (e) {
      await _disposeLive(key);
      status.state = EntryState.failed;
      status.lastError = e.toString();
      _log('failed $key: $e');
    } finally {
      if (!(live.boot?.isCompleted ?? true)) live.boot?.complete();
      _writeVmFile();
    }
  }

  /// Starts the VM process for [dillPath] in the project root and
  /// completes with the debugger connection once the VM-service line
  /// appears on stdout (60s timeout, process killed on expiry).
  ///
  /// Child stdout/stderr are forwarded as `log` events (and printed in
  /// human mode). Process exit is logged and clears the backend slot.
  ///
  /// **Parameters:**
  /// - [key]: project-relative entry file key (log attribution).
  /// - [live]: backend slot receiving process + service.
  /// - [dillPath]: compiled snapshot to execute.
  ///
  /// **Returns:** when the debugger connection is established.
  Future<void> _startVmProcess(
      String key, _LiveEntry live, String dillPath) async {
    final ready = Completer<VmService>();
    final process = await Process.start(
      Platform.resolvedExecutable,
      ['--enable-vm-service=0', dillPath],
      workingDirectory: _root.path,
    );
    live.process = process;

    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
      (line) {
        _emit({'type': 'log', 'entry': key, 'message': line});
        if (!_machine) print(line);
        if (!ready.isCompleted && _isVmServiceLine(line)) {
          final wsUri =
              '${line.split(' ').last.replaceFirst('http', 'ws').replaceFirst('/ws', '')}ws';
          live.vmServiceUri = wsUri;
          vmServiceConnectUri(wsUri).then(ready.complete,
              onError: ready.completeError);
        }
      },
      onError: (Object e) {
        if (!ready.isCompleted) ready.completeError(e);
      },
    );
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      _emit({'type': 'log', 'entry': key, 'stream': 'stderr', 'message': line});
      if (!_machine) print(line);
    });

    unawaited(process.exitCode.then((code) {
      if (live.process == process) live.process = null;
      _log('vm exited for $key ($code)');
    }));

    live.service = await ready.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        process.kill(ProcessSignal.sigkill);
        throw TimeoutException('Timed out waiting for VM service ($key)');
      },
    );
  }

  /// Waits for a stub completion flag to turn true.
  ///
  /// Debugger evaluation returns async futures *uncompleted*, so stub
  /// work (runtime scans, test engines) is triggered with one evaluate
  /// and observed here: each tick re-evaluates the boolean [flag] until
  /// it reads `true`. A companion [errorFlag] (`String?`, set on
  /// failure) short-circuits with a [StateError] carrying its content.
  ///
  /// **Parameters:**
  /// - [service]: debugger connection of the entry VM.
  /// - [isolateId]: target isolate.
  /// - [rootLibId]: reloaded root library (the runner stub).
  /// - [key]: project-relative entry file key (logs).
  /// - [flag]: boolean completion expression (e.g. `_jlRuntimeReady`).
  /// - [errorFlag]: optional `String?` failure expression.
  /// - [timeout]: overall deadline.
  /// - [timeoutMessage]: message for the [TimeoutException].
  /// - [progressStep]: single `run_step` label announced while waiting.
  /// - [emit]: control-channel event sink.
  ///
  /// **Returns:** when [flag] reads true. Throws [StateError] on
  /// reported failure, [TimeoutException] past [timeout].
  Future<void> _awaitFlagTrue({
    required VmService service,
    required String isolateId,
    required String rootLibId,
    required String key,
    required String flag,
    String? errorFlag,
    required Duration timeout,
    required String timeoutMessage,
    required String progressStep,
    void Function(Map<String, Object?> event)? emit,
  }) async {
    final deadline = DateTime.now().add(timeout);
    var announced = false;
    while (true) {
      final ready = await service.evaluate(isolateId, rootLibId, flag);
      if (ready is InstanceRef && ready.valueAsString == 'true') return;
      if (errorFlag != null) {
        final failure =
            await service.evaluate(isolateId, rootLibId, errorFlag);
        if (failure is InstanceRef &&
            failure.classRef?.name != 'Null' &&
            (failure.valueAsString?.isNotEmpty ?? false)) {
          throw StateError('Failed for $key: ${failure.valueAsString}');
        }
      }
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException(timeoutMessage);
      }
      if (!announced) {
        announced = true;
        _log('$progressStep $key ...');
        emit?.call({'type': 'run_step', 'step': progressStep});
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  /// Recompiles the runner stub + entry, reloads the isolate from the
  /// fresh dill, ensures the JetLeaf runtime, then invokes user `main`.
  ///
  /// Throws [StateError] on recompile failure, rejected reload, missing
  /// root library, failed ensure, or failed entry invocation. Also
  /// throws [TimeoutException] when the ensure step (>10min) or a test
  /// entry `main` (> annotation `timeoutSeconds`) hangs.
  ///
  /// **Parameters:**
  /// - [key]: project-relative entry file key.
  /// - [record]: discovery data (runtime kind, timeout).
  /// - [live]: connected backend to invoke in.
  /// - [entryFile]: user entry file (absolute or project-relative).
  /// - [args]: CLI args forwarded to user `main`.
  /// - [emit]: control-channel event sink.
  ///
  /// **Returns:** when user `main` completes in the isolate.
  Future<void> _invokeEntry(
    String key,
    EntryRecord record,
    _LiveEntry live,
    File entryFile,
    List<String> args,
    void Function(Map<String, Object?> event)? emit,
  ) async {
    final stubRootUri = stubRootUriFor(_root, key);
    await writeRunnerEntryStub(_root, key, entryFile,
        forTests: record.forTests, verbose: _verbose);

    final frontend = live.frontend;
    final service = live.service;
    if (frontend == null || service == null) {
      throw StateError('VM for $key is not connected');
    }

    emit?.call({'type': 'run_step', 'step': 'recompile:start'});
    final compilation = await frontend.compile([
      Uri.parse(stubRootUri),
      _rootUriForFile(entryFile),
    ]);
    emit?.call({
      'type': 'run_step',
      'step': 'recompile:done errors=${compilation.errorCount}'
    });
    _log('recompiled $key (errors=${compilation.errorCount})');
    if (compilation.errorCount > 0) {
      for (final line in compilation.compilerOutputLines.take(15)) {
        _log('  compile: $line');
      }
    }
    final dillOutput = compilation.dillOutput;
    if (dillOutput == null) {
      throw StateError(
          'Recompile failed (${compilation.errorCount} errors)');
    }
    frontend.accept();

    final vmInfo = await service.getVM();
    final isolateCount = vmInfo.isolates?.length ?? 0;
    _log('reloading $isolateCount isolate(s) for $key ...');
    final rootLibUri = Uri.file(dillOutput).toString();
    final argLiteral =
        '[${args.map((a) => "'${a.replaceAll("'", "\\'")}'").join(', ')}]';
    for (final isolateRef in vmInfo.isolates ?? []) {
      final id = isolateRef.id;
      if (id == null) continue;
      final report = await service.reloadSources(id,
          pause: false, rootLibUri: rootLibUri);
      _log('reload $key isolate $id: success=${report.success}');
      if (report.success != true) {
        throw StateError('Reload rejected for $key isolate $id');
      }

      final isolate = await service.getIsolate(id);
      _log('root lib for $key isolate $id: ${isolate.rootLib?.uri}');
      final rootLibId = isolate.rootLib?.id;
      if (rootLibId == null) {
        throw StateError('Isolate $id has no root library');
      }

      // Populate the JetLeaf runtime inside the warm isolate first
      // (cache fast path after the first run), then invoke user main.
      // NOTE: debugger evaluation returns async futures *uncompleted*,
      // so the scan is triggered here and completion is polled via the
      // `_jlRuntimeReady` / `_jlRuntimeError` flags — never awaited.
      emit?.call({'type': 'run_step', 'step': 'ensure-runtime:start'});
      final ensureCall = await service
          .evaluate(id, rootLibId, '_ensureJetleafRuntime()')
          .timeout(const Duration(seconds: 60));
      if (ensureCall is ErrorRef) {
        throw StateError(
            'Failed to ensure runtime: ${ensureCall.message}');
      }
      await _awaitFlagTrue(
        service: service,
        isolateId: id,
        rootLibId: rootLibId,
        key: key,
        flag: '_jlRuntimeReady',
        errorFlag: '_jlRuntimeError',
        timeout: const Duration(minutes: 10),
        timeoutMessage: 'Timed out waiting for runtime for $key',
        progressStep: 'ensure-runtime:warming',
        emit: emit,
      );
      emit?.call({'type': 'run_step', 'step': 'ensure-runtime:done'});

      if (record.forTests) {
        emit?.call({'type': 'run_step', 'step': 'run-tests:start'});
        final driverCall = await service
            .evaluate(id, rootLibId, 'runJetleafTests($argLiteral)')
            .timeout(const Duration(seconds: 60));
        if (driverCall is ErrorRef) {
          throw StateError(
              'Test driver failed for $key: ${driverCall.message}');
        }
        await _awaitFlagTrue(
          service: service,
          isolateId: id,
          rootLibId: rootLibId,
          key: key,
          flag: '_jlTestsDone',
          timeout: Duration(seconds: record.timeoutSeconds),
          timeoutMessage:
              'Tests timed out for $key after ${record.timeoutSeconds}s',
          progressStep: 'run-tests:running',
          emit: emit,
        );
        final passed =
            await service.evaluate(id, rootLibId, '_jlTestsPassed');
        if (passed is! InstanceRef || passed.valueAsString != 'true') {
          throw StateError('Tests failed for $key');
        }
        emit?.call({'type': 'run_step', 'step': 'run-tests:done'});
      } else {
        final Response result =
            await _invokeUserMain(service, id, rootLibId, argLiteral);
        if (result is ErrorRef) {
          throw StateError(
              'Failed to invoke entry main: ${result.message}');
        }
      }
    }
  }

  /// Invokes an app entry `main`, retrying bare on signature mismatch.
  ///
  /// Tries `entry.main(args)` first, then `entry.main()`
  /// when the entry rejects the args call — either as an [ErrorRef]
  /// result or as a thrown expression-compilation error naming the
  /// mismatch (`Too many positional arguments`). Timeouts always
  /// propagate (a hanging `main` is not a mismatch).
  ///
  /// **Parameters:**
  /// - [service]: debugger connection of the entry VM.
  /// - [isolateId]: target isolate.
  /// - [rootLibId]: reloaded root library (the runner stub).
  /// - [argLiteral]: Dart list literal of CLI args.
  /// - [timeout]: per-call deadline (test entries).
  ///
  /// **Returns:** the evaluation response (never an args-mismatch).
  Future<Response> _invokeUserMain(
    VmService service,
    String isolateId,
    String rootLibId,
    String argLiteral, {
    Duration? timeout,
  }) async {
    Future<Response> call(String expression) {
      var future = service.evaluate(isolateId, rootLibId, expression);
      if (timeout != null) future = future.timeout(timeout);
      return future;
    }

    try {
      final first = await call('entry.main($argLiteral)');
      if (first is! ErrorRef) return first;
    } catch (e) {
      if (e is TimeoutException) rethrow;
      if (!'$e'.contains('Too many positional arguments')) rethrow;
    }
    return call('entry.main()');
  }

  /// True when [e] is the stale-root failure: the isolate's root library
  /// has no `_ensureJetleafRuntime` (RPC 113 expression compilation
  /// error naming it). Anything else is a genuine run failure.
  ///
  /// Matches on the message text (not the error type): the 113 failure
  /// surfaces as a thrown RPC error, not a [StateError], so a typed
  /// catch would miss the reboot path.
  ///
  /// **Parameters:**
  /// - [e]: run failure to classify.
  ///
  /// **Returns:** true when a reboot-and-retry applies.
  bool _isStaleEnsureError(Object e) =>
      '$e'.contains('_ensureJetleafRuntime');

  /// `name pid=… ws://…` identity used across all VM logs.
  ///
  /// **Parameters:**
  /// - [key]: project-relative entry file key.
  /// - [live]: backend holding pid + service URI.
  ///
  /// **Returns:** e.g. `test/a_test.dart pid=123 ws://…`.
  String _vmIdentity(String key, _LiveEntry live) {
    final pid = live.process?.pid;
    final uri = live.vmServiceUri;
    final buf = StringBuffer(key);
    if (pid != null) buf.write(' pid=$pid');
    if (uri != null) buf.write(' $uri');
    return buf.toString();
  }

  // ----------------------------------------------------------------- runs

  /// Runs [file] (project-relative or absolute) in its entry VM.
  ///
  /// Boots the VM on demand when missing/failed/stopped; unknown files
  /// become ad-hoc entries (test-kind iff under `test/` or [forTests]).
  /// Both kinds share one flow — rewrite runner stub, incremental
  /// recompile, `reloadSources` from the fresh dill, evaluate
  /// `_ensureJetleafRuntime()` (populates the JetLeaf runtime inside the
  /// warm isolate) — then diverge: app entries evaluate the entry
  /// `main(args)` (bare `main()` retried when it takes no args), while
  /// test entries evaluate `runJetleafTests(args)`, which drives the
  /// `package:test` engine in the isolate and returns success as a bool
  /// (evaluating `main()` alone would only register tests, never run
  /// them). Test entries run under `timeoutSeconds`; everything returns
  /// to `parked` afterwards and the VM persists across runs.
  ///
  /// **Parameters:**
  /// - [file]: entry path (project-relative or absolute).
  /// - [args]: CLI args forwarded to user `main`.
  /// - [forTests]: runtime kind override (defaults to registry kind,
  ///   `test/` heuristic for ad-hoc entries).
  /// - [emit]: JSON event sink (`run_started`, `run_step`,
  ///   `run_complete`, `run_error`) for control-channel streaming.
  ///
  /// **Returns:** when the run completes (or fails and is recorded).
  Future<void> runEntry(
    String file, {
    List<String> args = const [],
    bool? forTests,
    void Function(Map<String, Object?> event)? emit,
  }) async {
    final key = _keyFor(file);
    var record = _entries[key];
    if (record == null) {
      // Ad-hoc entry: any file can run even without an annotation.
      final test = forTests ?? key.startsWith('test/');
      record = EntryRecord(
          file: key, kind: test ? EntryKind.test : EntryKind.entry);
      _entries[key] = record;
      _states[key] = EntryStatus(record: record);
      _log('discovered ad-hoc ${test ? 'test' : 'entry'} $key');
    }

    final status = _states[key]!;
    var live = _live[key];
    final ongoing = live?.boot;
    if (ongoing != null && !ongoing.isCompleted) {
      // Boot in progress (first frontend compile is slow): wait for it
      // instead of failing against a half-connected backend.
      _log('waiting for $key to finish booting ...');
      emit?.call({'type': 'run_step', 'step': 'wait-boot'});
      try {
        await ongoing.future.timeout(const Duration(minutes: 5));
      } on TimeoutException {
        emit?.call(
            {'type': 'error', 'error': 'Timed out waiting for $key boot'});
        return;
      }
      live = _live[key];
    }
    if (live == null ||
        status.state == EntryState.failed ||
        status.state == EntryState.stopped) {
      _log('booting $key on demand ...');
      await _bootEntry(key);
      live = _live[key];
    }
    if (live == null) {
      final error = 'No VM for $key (${status.lastError ?? 'boot failed'})';
      emit?.call({'type': 'run_error', 'entry': key, 'error': error});
      _log('failed $key: $error');
      return;
    }
    if (live.busy) {
      emit?.call({'type': 'error', 'error': 'VM busy: $key'});
      return;
    }

    final entryFile = File(p.isAbsolute(file)
        ? file
        : p.join(_root.path, file));
    if (!await entryFile.exists()) {
      emit?.call({'type': 'error', 'error': 'Entry not found: $file'});
      return;
    }

    live.busy = true;
    status.state = EntryState.running;
    status.lastRunAt = DateTime.now().toIso8601String();
    _writeVmFile();
    final started = {'type': 'run_started', 'entry': key};
    _emit(started);
    emit?.call(started);
    _log('running $key${args.isEmpty ? '' : ' ${args.join(' ')}'} ...');

    _LiveEntry? current = live;
    try {
      try {
        await _invokeEntry(key, record, live, entryFile, args, emit);
      } catch (e) {
        if (!_isStaleEnsureError(e)) rethrow;
        // The isolate's root library predates the on-disk stub (stale
        // incremental reload): reboot from the current stub file — which
        // defines `_ensureJetleafRuntime` — and retry exactly once.
        _log('stale vm detected for $key, rebooting ...');
        emit?.call({'type': 'run_step', 'step': 'reboot-stale-vm'});
        await _disposeLive(key);
        await _bootEntry(key);
        final fresh = _live[key];
        if (fresh == null) {
          throw StateError('Reboot failed for $key '
              '(${_states[key]?.lastError ?? 'unknown error'})');
        }
        fresh.busy = true;
        current = fresh;
        await _invokeEntry(key, record, fresh, entryFile, args, emit);
      }

      final done = {'type': 'run_complete', 'entry': key};
      _emit(done);
      emit?.call(done);
      _log('completed $key');
    } on TimeoutException catch (e) {
      final error = 'Run timed out for $key: $e';
      emit?.call({'type': 'run_error', 'entry': key, 'error': error});
      _log('failed $key: $error');
      status.lastError = error;
    } catch (e) {
      final error = e.toString();
      emit?.call({'type': 'run_error', 'entry': key, 'error': error});
      _log('failed $key: $error');
      status.lastError = error;
    } finally {
      current?.busy = false;
      live.busy = false;
      if (_live.containsKey(key)) status.state = EntryState.parked;
      _writeVmFile();
    }
  }

  // --------------------------------------------------------------- stop

  /// Shuts down one entry VM. Kept in the registry as `stopped`.
  ///
  /// Disposes debugger connection, kills the process (SIGKILL, 5s
  /// grace), shuts down the frontend server. Next [runEntry] reboots.
  ///
  /// **Parameters:**
  /// - [key]: project-relative entry file key.
  /// - [quiet]: suppress the `stopped` log (internal rediscover use).
  ///
  /// **Returns:** when the backend is gone.
  Future<void> stopEntry(String key, {bool quiet = false}) async {
    await _disposeLive(key);
    final status = _states[key];
    if (status != null) {
      status.state = EntryState.stopped;
      status.pid = null;
      status.vmServiceUri = null;
    }
    if (!quiet) _log('stopped $key');
    _writeVmFile();
  }

  /// Shuts down every entry VM (used by `jl stop` and [dispose]).
  ///
  /// **Returns:** when every backend is gone.
  Future<void> stopAll() async {
    for (final key in _live.keys.toList()) {
      await _disposeLive(key);
      final status = _states[key];
      if (status != null) {
        status.state = EntryState.stopped;
        status.pid = null;
        status.vmServiceUri = null;
      }
    }
    _log('stopped all entry vms');
    _writeVmFile();
  }

  /// Tears down one live backend (service, process, frontend).
  /// Removes it from [_live]; registry status is the caller's job.
  ///
  /// **Parameters:**
  /// - [key]: project-relative entry file key.
  ///
  /// **Returns:** when service, process and frontend are released.
  Future<void> _disposeLive(String key) async {
    final live = _live.remove(key);
    if (live == null) return;
    try {
      await live.service?.dispose();
    } catch (_) {}
    live.service = null;
    final process = live.process;
    live.process = null;
    if (process != null) {
      try {
        process.kill(ProcessSignal.sigkill);
        await process.exitCode.timeout(const Duration(seconds: 5));
      } catch (_) {
        try {
          process.kill(ProcessSignal.sigkill);
        } catch (_) {}
      }
    }
    final frontend = live.frontend;
    live.frontend = null;
    if (frontend != null) {
      // The frontend server may already be gone: its broken pipe then
      // surfaces through stream callbacks in the zone, outside normal
      // try/catch reach. Shut down detached inside a guarded zone that
      // swallows transport errors but logs anything else. Detached on
      // purpose: a hung shutdown must never block stop/dispose
      // (`runZonedGuarded` is synchronous; completion is not observed).
      try {
        runZonedGuarded<void>(
          () {
            // Returned-future errors land in the chain below; stream-zone
            // errors land in the guarded-zone handler. Both swallowed.
            // ignore: discarded_futures
            frontend.shutdown().timeout(const Duration(seconds: 10)).then(
                  (_) {},
                  // ignore: avoid_types_on_closure_parameters
                  onError: (Object _) {},
                );
          },
          (Object error, StackTrace stack) {
            if (error is! SocketException) {
              _log('frontend shutdown error for $key: $error');
            }
          },
        );
      } catch (_) {}
    }
  }

  // -------------------------------------------------------------- watcher

  /// Save-time update: re-runs discovery (new files boot lazily on next
  /// run, deleted files are dropped), rewarms the shared cache, then
  /// incrementally recompiles + `reloadSources` every idle live VM.
  /// Busy VMs are skipped with a log line. Ignored while stopping or
  /// while the initial boot is still warming.
  ///
  /// **Parameters:**
  /// - [changedPaths]: absolute paths from the debounce window.
  ///
  /// **Returns:** when cache, VMs and `Jetleaf.VM` are current again.
  Future<void> _onFilesChanged(List<String> changedPaths) async {
    if (_stopping || _warming) return;
    _warming = true;
    final displayPaths =
        changedPaths.map((abs) => p.relative(abs, from: _root.path)).toList();
    try {
      _log('changed ${displayPaths.length} '
          'file${displayPaths.length == 1 ? '' : 's'}: '
          '${displayPaths.join(', ')}');
      await _rediscover(log: false);
      await _warmProject(_root);
      final uris = changedPaths.map(_rootUriFor).toList();
      final reloaded = <String>[];
      for (final entry in _live.entries) {
        final live = entry.value;
        if (live.busy) {
          _log('skipped ${entry.key} (run in progress)');
          continue;
        }
        final frontend = live.frontend;
        final service = live.service;
        if (frontend == null || service == null) continue;
        try {
          final compilation = await frontend.compile(uris);
          final dillOutput = compilation.dillOutput;
          if (dillOutput == null) continue;
          frontend.accept();
          final vmInfo = await service.getVM();
          final rootLibUri = Uri.file(dillOutput).toString();
          for (final isolateRef in vmInfo.isolates ?? []) {
            final id = isolateRef.id;
            if (id == null) continue;
            await service.reloadSources(
                id, pause: false, rootLibUri: rootLibUri);
          }
          reloaded.add(_vmIdentity(entry.key, live));
        } catch (e) {
          _log('reload failed for ${entry.key}: $e');
        }
      }
      if (reloaded.isEmpty) {
        _log('updated, no vms reloaded');
      } else {
        _log('updated, reloaded ${reloaded.length} '
            'vm${reloaded.length == 1 ? '' : 's'}:');
        for (final identity in reloaded) {
          _log('  reloaded vm $identity');
        }
      }
      _writeVmFile();
    } catch (e) {
      _log('Rewarm failed: $e');
    } finally {
      _warming = false;
    }
  }

  // ------------------------------------------------------ control channel

  /// Binds the loopback control socket (ephemeral port) for `jl run` /
  /// `jl test` / `jl status` / `jl stop` clients.
  ///
  /// **Returns:** when listening (port published via manager sidecar).
  Future<void> _bindControl() async {
    _control =
        await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    _controlPort = _control!.port;
    _control!.listen(_serveControl);
  }

  /// Serves one control connection: first JSON line is the request,
  /// handled by [_handleControl]; the socket closes after the terminal
  /// `done` frame (or on protocol errors).
  ///
  /// **Parameters:**
  /// - [socket]: accepted client connection.
  ///
  /// **Returns:** when the socket is flushed and closed.
  Future<void> _serveControl(Socket socket) async {
    try {
      final lines = socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      await for (final line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          final message = jsonDecode(line) as Map<String, dynamic>;
          final done = await _handleControl(message, (event) {
            try {
              socket.writeln(jsonEncode(event));
            } catch (_) {}
          });
          if (done) break;
        } catch (e) {
          socket.writeln(jsonEncode(
              {'type': 'error', 'error': 'Invalid message: $e'}));
        }
      }
    } catch (_) {
    } finally {
      try {
        await socket.flush();
        await socket.close();
      } catch (_) {}
    }
  }

  /// Dispatches one control request (`runApp`, `runTest`, `boot`,
  /// `status`, `stop`). Run output streams back through [emit]; every
  /// branch ends with a terminal `done` frame. A `stop` without `entry`
  /// also terminates the manager.
  ///
  /// **Parameters:**
  /// - [message]: decoded client request.
  /// - [emit]: per-connection response sink.
  ///
  /// **Returns:** true when the connection is finished.
  Future<bool> _handleControl(Map<String, dynamic> message,
      void Function(Map<String, Object?> event) emit) async {
    switch (message['type']) {
      case 'runApp':
        final entry = message['entry'] as String?;
        if (entry == null || entry.isEmpty) {
          emit({'type': 'error', 'error': 'Missing entry in runApp'});
          emit({'type': 'done', 'ok': false});
          return true;
        }
        final args =
            (message['args'] as List?)?.cast<String>() ?? const [];
        emit({
          'type': 'done',
          'ok': await _runGuarded(
              emit, (e) => runEntry(entry, args: args, forTests: false, emit: e))
        });
        return true;
      case 'runTest':
        final entry = message['entry'] as String?;
        if (entry == null || entry.isEmpty) {
          emit({'type': 'error', 'error': 'Missing entry in runTest'});
          emit({'type': 'done', 'ok': false});
          return true;
        }
        emit({
          'type': 'done',
          'ok': await _runGuarded(
              emit, (e) => runEntry(entry, forTests: true, emit: e))
        });
        return true;
      case 'status':
        emit({
          'type': 'status_response',
          'pid': pid,
          'projectRoot': _root.path,
          'entries': _states.values.map((s) => s.toJson()).toList(),
        });
        emit({'type': 'done', 'ok': true});
        return true;
      case 'boot':
        final entry = message['entry'] as String?;
        if (entry == null || entry.isEmpty) {
          emit({'type': 'error', 'error': 'Missing entry in boot'});
          emit({'type': 'done', 'ok': false});
          return true;
        }
        await _bootEntry(_keyFor(entry));
        emit({'type': 'done', 'ok': _live.containsKey(_keyFor(entry))});
        return true;
      case 'stop':
        final entry = message['entry'] as String?;
        if (entry != null && entry.isNotEmpty) {
          await stopEntry(_keyFor(entry));
        } else {
          await stopAll();
        }
        emit({'type': 'stopped'});
        emit({'type': 'done', 'ok': true});
        if (entry == null || entry.isEmpty) {
          unawaited(stop(0));
        }
        return true;
      default:
        emit({
          'type': 'error',
          'error': 'Unknown message type: ${message['type']}'
        });
        emit({'type': 'done', 'ok': false});
        return true;
    }
  }

  /// Runs [run], folding any `run_error` frame (or escape) into the
  /// terminal verdict.
  ///
  /// `runEntry` reports failures as frames rather than throws, so the
  /// `done` verdict is derived from observed frames.
  ///
  /// **Parameters:**
  /// - [emit]: per-connection response sink.
  /// - [run]: the run to guard (receives the observing sink).
  ///
  /// **Returns:** true when no `run_error` frame was observed.
  Future<bool> _runGuarded(
    void Function(Map<String, Object?> event) emit,
    Future<void> Function(void Function(Map<String, Object?> event) emit)
        run,
  ) async {
    var ok = true;
    void guardedEmit(Map<String, Object?> event) {
      if (event['type'] == 'run_error') ok = false;
      emit(event);
    }

    try {
      await run(guardedEmit);
    } catch (e) {
      ok = false;
      emit({'type': 'run_error', 'error': e.toString()});
    }
    return ok;
  }

  // ---------------------------------------------------------------- state

  /// Machine-readable snapshot: manager pid, project root, all entry
  /// statuses (same shape as the `Jetleaf.VM` array elements).
  ///
  /// **Returns:** `{pid, projectRoot, entries}`.
  Map<String, Object?> status() => {
        'pid': pid,
        'projectRoot': _root.path,
        'entries': _states.values.map((s) => s.toJson()).toList(),
      };

  /// Human-readable status table (`jl status`): one
  /// `state  file  pid=… ws://…` line per entry.
  ///
  /// **Returns:** the rendered table.
  String humanStatus() {
    final buf = StringBuffer('JetleafVM pid=$pid root=${_root.path}\n');
    for (final status in _states.values) {
      final detail = [
        if (status.pid != null) 'pid=${status.pid}',
        if (status.vmServiceUri != null) status.vmServiceUri!,
        if (status.lastError != null) 'error=${status.lastError}',
      ].join(' ');
      buf.writeln('  ${status.state.name.padRight(10)} ${status.file}'
          '${detail.isEmpty ? '' : '  $detail'}');
    }
    return buf.toString();
  }

  /// Writes the `Jetleaf.VM` array file (4-space indent).
  ///
  /// Best-effort (never throws): skipped silently when unwritable.
  void _writeVmFile() {
    try {
      final file = File(p.join(_root.path, JetleafVmPaths.vmFileName));
      final data = _states.values.map((s) => s.toJson()).toList();
      file.writeAsStringSync(
          '${const JsonEncoder.withIndent('    ').convert(data)}\n');
    } catch (_) {}
  }

  /// Writes the internal manager sidecar (pid, control port,
  /// started-at) next to the old `dev.json` location. Read by
  /// `jl run` / `jl test` / `jl status` / `jl stop` clients.
  ///
  /// Best-effort (never throws): skipped silently when unwritable.
  void _writeManagerFile() {
    try {
      final file = File(p.join(_root.path, JetleafVmPaths.managerRelativePath));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(jsonEncode({
        'pid': pid,
        'projectRoot': _root.path,
        'controlPort': _controlPort,
        'startedAt': _startedAt,
      }));
    } catch (_) {}
  }

  /// Removes `Jetleaf.VM` + the manager sidecar (clean stop only;
  /// crash leftovers are overwritten on the next boot).
  ///
  /// Best-effort (never throws): missing files are ignored.
  void _deleteState() {
    try {
      File(p.join(_root.path, JetleafVmPaths.vmFileName)).deleteSync();
    } catch (_) {}
    try {
      File(p.join(_root.path, JetleafVmPaths.managerRelativePath)).deleteSync();
    } catch (_) {}
  }

  /// Appends `Jetleaf.VM` + `_jetleaf/` to the project `.gitignore`
  /// (created when missing) so manager state never pollutes git.
  ///
  /// **Returns:** when the ignore entries exist.
  Future<void> _ensureGitignore() async {
    try {
      final file = File(p.join(_root.path, '.gitignore'));
      final existing = file.existsSync() ? file.readAsStringSync() : '';
      final lines = existing.split('\n').map((l) => l.trim()).toSet();
      final missing = <String>[];
      if (!lines.contains(JetleafVmPaths.vmFileName)) missing.add(JetleafVmPaths.vmFileName);
      if (!lines.contains('_jetleaf/')) missing.add('_jetleaf/');
      if (missing.isNotEmpty) {
        final prefix = existing.isEmpty || existing.endsWith('\n') ? '' : '\n';
        file.writeAsStringSync(
            '$existing$prefix${missing.join('\n')}\n');
      }
    } catch (_) {}
  }

  // ------------------------------------------------------------ lifecycle

  /// Traps SIGINT/SIGTERM for graceful shutdown via [stop].
  ///
  /// Survives platforms without a given signal (subscription skipped).
  void _watchSignals() {
    for (final signal in [ProcessSignal.sigint, ProcessSignal.sigterm]) {
      _signalSubs.add(signal.watch().listen((_) {
        _log('Received $signal, stopping.');
        stop(0);
      }));
    }
  }

  /// Requests shutdown and completes the [start] future with [code].
  /// Idempotent; also triggered by the `stop` control request and
  /// OS signals.
  ///
  /// **Parameters:**
  /// - [code]: process exit code to complete with.
  ///
  /// **Returns:** when [dispose] finished and the exit code completed.
  @override
  Future<void> stop([int code = 0]) async {
    if (_stopping) return;
    _stopping = true;
    await dispose();
    if (!_exitCode.isCompleted) _exitCode.complete(code);
  }

  /// Releases everything: watcher, control socket, all entry VMs,
  /// signal subscriptions, event stream — then deletes manager state.
  ///
  /// **Returns:** when teardown finished.
  @override
  Future<void> dispose() async {
    await _watcher?.stop();
    _watcher = null;
    try {
      await _control?.close();
    } catch (_) {}
    _control = null;
    await stopAll();
    for (final sub in _signalSubs) {
      await sub.cancel();
    }
    _signalSubs.clear();
    try {
      await _events.close();
    } catch (_) {}
    _deleteState();
  }

  // -------------------------------------------------------------- helpers

  /// Normalizes an absolute or project-relative file to a registry key.
  ///
  /// **Parameters:**
  /// - [file]: absolute path or project-relative path.
  ///
  /// **Returns:** the project-relative key.
  String _keyFor(String file) {
    final abs = p.isAbsolute(file)
        ? p.normalize(file)
        : p.normalize(p.join(_root.path, file));
    return p.relative(abs, from: _root.path);
  }

  /// Maps an absolute file path to the `org-dartlang-root` URI
  /// understood by the frontend server (same scheme as each stub root).
  ///
  /// **Parameters:**
  /// - [absolutePath]: absolute file path.
  ///
  /// **Returns:** the invalidation URI for incremental compiles.
  Uri _rootUriFor(String absolutePath) =>
      Uri.parse('org-dartlang-root:///$absolutePath');

  /// Same as [_rootUriFor] for a [File].
  ///
  /// **Parameters:**
  /// - [file]: file to map.
  ///
  /// **Returns:** the invalidation URI for incremental compiles.
  Uri _rootUriForFile(File file) => _rootUriFor(file.absolute.path);

  /// Emits [event] as a JSON line in `--machine` mode and always
  /// forwards it to [onEvent] subscribers (control streaming included).
  ///
  /// **Parameters:**
  /// - [event]: JSON-style event frame.
  void _emit(Map<String, Object?> event) {
    if (_machine) print(jsonEncode(event));
    if (!_events.isClosed) _events.add(event);
  }

  /// Human log line (suppressed in `--machine` mode, where the
  /// event alone is printed). VM child output bypasses this and is
  /// printed directly so app/test output stays verbatim.
  ///
  /// **Parameters:**
  /// - [message]: line to log (also emitted as a `log` event).
  void _log(String message) {
    _emit({'type': 'log', 'message': message});
    if (!_machine) print(message);
  }
}
