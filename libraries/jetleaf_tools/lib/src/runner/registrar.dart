import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:jetleaf_core/lang.dart';
import 'package:jetleaf_core/pod.dart';
import 'package:path/path.dart' as p;
import 'package:vm_service/vm_service.dart' show LibraryRef;
import 'package:vm_service/vm_service_io.dart';

import '../cache/indexer/build_command.dart' as builder;
import '../cache/jetleaf_paths.dart';
import '../cache/manager/cacheable_manager.dart';
import '../utils/utils.dart';

/// {@template aot_registrar}
/// Function signature for a compile-time generated AOT registrar bound during
/// application bootstrap or development runtime execution.
///
/// Matches the signature of `registerGeneratedArtifacts` (in
/// `lib/_jetleaf/main/registry.g.dart`) and `registerTestGeneratedArtifacts`
/// (in `lib/_jetleaf/test/registry.g.dart`).
///
/// When invoked with `factory == null`, only type tokens, constructors, fields,
/// methods, and annotation factories are registered into [MaterializedLibrary].
/// When invoked with a [DefaultListablePodFactory], all discovered pod
/// definitions are also installed into that factory.
/// {@endtemplate}
typedef AotRegistrar = FutureOr<void> Function([DefaultListablePodFactory? factory]);

/// Isolate-local development registrar bound for production/main runs.
AotRegistrar? _boundMainAotRegistrar;

/// Isolate-local development registrar bound for test runs (`forTests: true`).
AotRegistrar? _boundTestAotRegistrar;

/// {@template is_development_runtime}
/// Returns `true` when the current process is running in development mode
/// (JIT / debug) rather than a production or profile build.
///
/// ### Detection Rules
/// Returns `false` when any of the following hold:
/// - `dart.vm.product` (`-Ddart.vm.product=true` / `dart compile exe` release)
///   is enabled.
/// - `dart.vm.profile` (`-Ddart.vm.profile=true`) is enabled.
/// - [System.isProductionMode] is `true`.
/// - [System.isRunningAot] is `true` (precompiled AOT binary).
///
/// ### Why This Matters
/// In production/AOT builds, automatic source scanning, `runBuild`, and
/// VM-service registrar binding are disabled. Applications compiled for
/// production must explicitly supply the generated [AotRegistrar] (e.g.
/// `registerGeneratedArtifacts` from `lib/_jetleaf/main.dart`) to
/// `JetleafApplication.run(..., aotRegistrar: registerGeneratedArtifacts)`.
/// {@endtemplate}
bool isDevelopmentRuntime() {
  if (const bool.fromEnvironment('dart.vm.product') || const bool.fromEnvironment('dart.vm.profile')) {
    return false;
  }
  if (System.isProductionMode() || System.isRunningAot()) {
    return false;
  }
  return true;
}

/// {@template bind_aot_registrar}
/// Binds a generated [AotRegistrar] function (`registerGeneratedArtifacts` or
/// `registerTestGeneratedArtifacts`) for the current isolate.
///
/// Typically invoked automatically by [ensureDevelopmentRuntime] via the Dart
/// VM Service after locating `lib/_jetleaf/<main|test>/registry.g.dart` in the
/// active isolate, or directly inside `.jetleaf/generated/runtime_bootstrap.g.dart`.
/// This allows `JetleafApplication.run`, `runScan`, and `runTestScan` to
/// execute with full AOT dispatch tables in development mode without requiring
/// users to pass the registrar manually.
///
/// ### Parameters
/// - [registrar]: The generated registrar closure to store for this isolate.
/// - [forTests]: When `true`, stores [registrar] in the test slot (used by
///   `runTestScan`); otherwise stores it in the main application slot.
///
/// ### Returns
/// `true` if bound successfully in development mode, or `false` if
/// [isDevelopmentRuntime] is `false`.
/// {@endtemplate}
bool bindAotRegistrar(AotRegistrar registrar, {bool forTests = false}) {
  if (!isDevelopmentRuntime()) {
    return false;
  }

  if (forTests) {
    _boundTestAotRegistrar = registrar;
  } else {
    _boundMainAotRegistrar = registrar;
  }

  return true;
}

/// {@template get_bound_aot_registrar}
/// Returns the development [AotRegistrar] previously bound via
/// [bindAotRegistrar] for the current isolate, or `null` if none has been
/// bound or [isDevelopmentRuntime] is `false`.
///
/// ### Parameters
/// - [forTests]: When `true`, retrieves the test registrar bound for
///   `runTestScan`; otherwise retrieves the main application registrar.
/// {@endtemplate}
AotRegistrar? getBoundAotRegistrar({bool forTests = false}) {
  if (!isDevelopmentRuntime()) {
    return null;
  }

  return forTests ? _boundTestAotRegistrar : _boundMainAotRegistrar;
}

/// {@template resolve_project_root}
/// Resolves the root directory of the active Jetleaf project.
///
/// ### Resolution Strategy
/// 1. If [explicitRoot] is provided, returns `explicitRoot.absolute`.
/// 2. If [Platform.script] is a `file:` URI pointing to a `.dart` file inside
///    [Directory.current] (or when `Directory.current` does not contain a
///    `pubspec.yaml`, such as running `dart run example/lib/main.dart` from a
///    workspace root), walks upward from the script's parent directory to the
///    nearest directory containing `pubspec.yaml`.
/// 3. Falls back to `Directory.current.absolute`.
/// {@endtemplate}
Directory resolveProjectRoot([Directory? explicitRoot]) {
  if (explicitRoot != null) return explicitRoot.absolute;
  final cwd = Directory.current.absolute;
  try {
    final scriptUri = Platform.script;
    if (scriptUri.scheme == 'file' && scriptUri.path.endsWith('.dart')) {
      final scriptFile = File.fromUri(scriptUri).absolute;
      if (p.isWithin(cwd.path, scriptFile.path) || !File(p.join(cwd.path, Constant.PUBSPEC_YAML_FILE_NAME)).existsSync()) {
        var dir = scriptFile.parent;
        while (true) {
          if (File(p.join(dir.path, Constant.PUBSPEC_YAML_FILE_NAME)).existsSync()) {
            return dir;
          }
          final parent = dir.parent;
          if (parent.path == dir.path) break;
          dir = parent;
        }
      }
    }
  } catch (_) {}
  return cwd;
}

/// {@template ensure_development_runtime}
/// Ensures that the project's `.jetleaf/cache/<main|test>/` declaration cache
/// and `lib/_jetleaf/<main|test>/registry.g.dart` AOT registry are built,
/// up-to-date, and bound in the current isolate when running in development mode
/// (`dart run`, `dart test`, or IDE Run/Debug).
///
/// ### Production / AOT Guard
/// When [isDevelopmentRuntime] returns `false` (e.g. `dart compile exe`,
/// `-Ddart.vm.product=true`, or `CompilationMode.release`), this function
/// immediately returns `false` without scanning, building, or binding.
///
/// ### Skip Guards
/// - Always skips inside pre-warmed `jl dev` entry stubs
///   (`.jetleaf/generated/entries/`), since `JetleafVM` manages their runtime.
/// - When [forTests] is `false`, skips `dart test` runner isolates so main
///   builds are never triggered accidentally during test execution.
/// - Skips directories that are not Jetleaf build projects or lack a `lib/`
///   directory.
///
/// ### Rebuild & Synchronization Flow
/// 1. Validates the existing cache fingerprint (`CacheManager.isValid`),
///    existence of `registry.g.dart`, and source modification timestamps via
///    [_hasSourceNewerThan].
/// 2. If stale or missing, runs `builder.runBuild` (`--test` when [forTests] is
///    `true`) to regenerate `.jetleaf/` caches and `lib/_jetleaf/`.
/// 3. If `registry.g.dart` changed on disk and [isRunningFromDill] is `false`,
///    reloads sources in the running VM isolate via the VM Service.
/// 4. When [hasAotRegistrar] is `false` and no registrar is bound yet, binds
///    the generated registrar in-process (if `registry.g.dart` is already loaded
///    in the isolate) or launches [_runBootstrappedChild] for non-test
///    `dart run` invocations that did not import `_jetleaf/main.dart`.
///
/// ### Parameters
/// - [projectRoot]: Optional explicit project root; defaults to
///   [resolveProjectRoot].
/// - [hasAotRegistrar]: Whether the caller already holds an explicit
///   [AotRegistrar] reference.
/// - [isRunningFromDill]: Whether the current process was launched from a
///   precompiled `.dill` kernel snapshot.
/// - [forTests]: Targets the test cache and `lib/_jetleaf/test/registry.g.dart`
///   (`registerTestGeneratedArtifacts`) when `true`.
/// - [args]: Application CLI arguments forwarded to [_runBootstrappedChild] if
///   a bootstrapped child launch is required.
///
/// ### Returns
/// `true` if a rebuild (`runBuild`) was executed, or `false` otherwise.
/// {@endtemplate}
Future<bool> ensureDevelopmentRuntime({
  Directory? projectRoot,
  bool hasAotRegistrar = true,
  bool isRunningFromDill = false,
  bool forTests = false,
  List<String> args = const [],
}) async {
  try {
    if (!isDevelopmentRuntime()) {
      return false;
    }

    final path = Platform.script.toString();
    // Skip inside pre-warmed `jl dev` entry stubs, and skip `dart test`
    // runner isolates when ensuring the main (non-test) runtime.
    final devEntriesSegment = '${Constant.WORKSPACE_DIR_NAME}/${Constant.GENERATED_DIRECTORY_NAME}/${Constant.ENTRIES_DIR_NAME}/';
    if (path.contains(devEntriesSegment)) {
      return false;
    }
    if (!forTests &&
        (path.contains('${Constant.TEST_DIR_NAME}.dart') ||
            path.contains('/${Constant.TEST_DIR_NAME}/') ||
            path.endsWith('_${Constant.TEST_DIR_NAME}.dart'))) {
      return false;
    }

    final root = resolveProjectRoot(projectRoot);
    if (!RuntimeUtils.isJetLeafBuildProject(root)) {
      return false;
    }

    final libDir = Directory(p.join(root.path, Constant.LIB));
    if (!libDir.existsSync()) {
      return false;
    }

    final fingerprint = CacheManager.generateFingerprint(skipTests: !forTests);
    final cacheValid = CacheManager.isValid(
      root,
      configFingerprint: fingerprint,
      forTests: forTests,
    );
    final generatedDirName = forTests ? Constant.TEST_GENERATED_DIR_NAME : Constant.GENERATED_DIR_NAME;
    final registryFile = File(
      p.join(
        root.path,
        generatedDirName,
        Constant.REGISTRY_FILE_NAME,
      ),
    );
    final cacheFpFile = JetleafPaths.fingerprintFile(root, forTests: forTests);

    bool needsRebuild = !cacheValid || !registryFile.existsSync();
    if (!needsRebuild && cacheFpFile.existsSync()) {
      DateTime baseline = cacheFpFile.lastModifiedSync();
      if (registryFile.existsSync()) {
        final regTime = registryFile.lastModifiedSync();
        if (regTime.isBefore(baseline)) {
          baseline = regTime;
        }
      }
      needsRebuild = _hasSourceNewerThan(root, baseline, forTests: forTests);
    }

    bool registryChanged = false;
    if (needsRebuild) {
      final previousRegistrySource = registryFile.existsSync() ? registryFile.readAsStringSync() : null;

      await builder.runBuild(
        forTests ? const ['--test'] : const [],
        root: root,
      );

      final updatedRegistrySource = registryFile.existsSync() ? registryFile.readAsStringSync() : null;
      registryChanged = updatedRegistrySource != null && previousRegistrySource != updatedRegistrySource;
    }

    final alreadyBound = getBoundAotRegistrar(forTests: forTests) != null;
    final needsReload = registryChanged && !isRunningFromDill;
    final needsBind = !hasAotRegistrar && !alreadyBound && registryFile.existsSync();

    if (needsReload || needsBind) {
      await _syncAndBindIsolateAotRegistry(
        root: root,
        registryFile: registryFile,
        reloadSources: needsReload,
        bindRegistrar: needsBind,
        isRunningFromDill: isRunningFromDill,
        forTests: forTests,
        args: args,
      );
    }
    return needsRebuild;
  } catch (_) {
    return false;
  }
}

/// Checks whether `pubspec.yaml` or any non-generated source file in [root]
/// has been modified more recently than [baseline].
///
/// Scans `lib/`, `bin/`, and `resources/` (plus `test/` when [forTests] is
/// `true`), ignoring generated files under `lib/_jetleaf/` and `*.g.dart` so
/// build outputs do not self-trigger subsequent rebuilds.
bool _hasSourceNewerThan(
  Directory root,
  DateTime baseline, {
  bool forTests = false,
}) {
  final pubspec = File(p.join(root.path, Constant.PUBSPEC_YAML_FILE_NAME));
  if (pubspec.existsSync() && pubspec.lastModifiedSync().isAfter(baseline)) {
    return true;
  }

  final folders = forTests
    ? const [Constant.LIB, 'bin', Constant.RESOURCES_DIR_NAME, Constant.TEST_DIR_NAME]
    : const [Constant.LIB, 'bin', Constant.RESOURCES_DIR_NAME];

  final generatedPrefix = '${p.join(Constant.LIB, Constant.JETLEAF_GENERATED_DIR_NAME)}${p.separator}';

  for (final folder in folders) {
    final dir = Directory(p.join(root.path, folder));
    if (!dir.existsSync()) continue;
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final rel = p.relative(entity.path, from: root.path);
      if (rel.startsWith(generatedPrefix) || rel.endsWith('.g.dart')) {
        continue;
      }

      if (entity.lastModifiedSync().isAfter(baseline)) {
        return true;
      }
    }
  }
  return false;
}

/// Reads the `name:` field from `<root>/pubspec.yaml`, or returns `null` if
/// the file does not exist or cannot be parsed.
String? _readPackageName(Directory root) {
  final pubspec = File(p.join(root.path, Constant.PUBSPEC_YAML_FILE_NAME));
  if (!pubspec.existsSync()) return null;
  try {
    for (final line in pubspec.readAsLinesSync()) {
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('name:')) {
        return trimmed.substring('name:'.length).trim();
      }
    }
  } catch (_) {}
  return null;
}

/// Converts a `file:` URI pointing inside `<root>/lib/` into its canonical
/// `package:<packageName>/...` URI.
///
/// Returns `null` if [packageName] is missing, [uriString] is not a `file:`
/// URI, or the resolved path lies outside `<root>/lib/`.
String? _toPackageUriIfInLib(String uriString, Directory root, String? packageName) {
  if (packageName == null || packageName.isEmpty) return null;
  if (!uriString.startsWith('file:')) return null;
  try {
    final filePath = p.normalize(File.fromUri(Uri.parse(uriString)).absolute.path);
    final libPath = p.normalize(p.join(root.absolute.path, Constant.LIB));
    if (p.isWithin(libPath, filePath)) {
      final rel = p.relative(filePath, from: libPath).replaceAll(p.separator, '/');
      return 'package:$packageName/$rel';
    }
  } catch (_) {}
  return null;
}

/// Searches [libraries] in the current isolate for the loaded main or test
/// `registry.g.dart` library matching [forTests].
LibraryRef? _findRegistryLibrary(
  List<LibraryRef>? libraries, {
  required bool forTests,
}) {
  if (libraries == null) return null;
  final scopeDir = forTests ? Constant.TEST_JETLEAF_GENERATED_DIR_NAME : Constant.MAIN_JETLEAF_GENERATED_DIR_NAME;
  final suffix = '/${Constant.JETLEAF_GENERATED_DIR_NAME}/$scopeDir/${Constant.REGISTRY_FILE_NAME}';
  for (final lib in libraries) {
    final uri = lib.uri ?? '';
    if (uri.endsWith(suffix)) {
      return lib;
    }
  }
  return null;
}

/// Connects to the current isolate's Dart VM Service (temporarily enabling the
/// VM Service web server if needed) to reload updated sources and bind the
/// generated [AotRegistrar].
///
/// - When [reloadSources] is `true`, invokes `reloadSources` on the current
///   isolate so newly generated AOT closures and proxies are live.
/// - When [bindRegistrar] is `true` and [registryFile] is already loaded in
///   [isolate.libraries], evaluates `bindAotRegistrar(...)` directly inside the
///   registry library so no child process is needed.
/// - When [bindRegistrar] is `true` for a non-test `dart run` entrypoint that
///   did not import `_jetleaf/main.dart` (and `JETLEAF_BOOTSTRAPPED != '1'`),
///   defers to [_runBootstrappedChild] instead of attempting an unsafe
///   cross-URI hot reload of `file:` vs `package:` entrypoints.
Future<void> _syncAndBindIsolateAotRegistry({
  required Directory root,
  required File registryFile,
  required bool reloadSources,
  required bool bindRegistrar,
  required bool isRunningFromDill,
  required bool forTests,
  required List<String> args,
}) async {
  bool startedWebServer = false;
  bool shouldBootstrapChild = false;
  String? currentRootUri;
  try {
    var info = await developer.Service.getInfo();
    if (info.serverUri == null) {
      info = await developer.Service.controlWebServer(
        enable: true,
        silenceOutput: true,
      );
      startedWebServer = info.serverUri != null;
    }
    final serverUri = info.serverUri;
    final isolateId = developer.Service.getIsolateId(Isolate.current);
    if (serverUri == null || isolateId == null) return;

    final wsScheme = serverUri.scheme == 'https' ? 'wss' : 'ws';
    var wsPath = serverUri.path;
    if (!wsPath.endsWith('/')) wsPath = '$wsPath/';
    final wsUri = serverUri.replace(scheme: wsScheme, path: '${wsPath}ws').toString();

    final service = await vmServiceConnectUri(wsUri).timeout(const Duration(seconds: 5));
    try {
      if (reloadSources && !startedWebServer) {
        await service
          .reloadSources(isolateId, pause: false)
          .timeout(const Duration(seconds: 15));
      } else if (reloadSources && startedWebServer && !forTests && !isRunningFromDill && Platform.environment['JETLEAF_BOOTSTRAPPED'] != '1') {
        final isolate = await service.getIsolate(isolateId);
        currentRootUri = isolate.rootLib?.uri;
        shouldBootstrapChild = currentRootUri != null && (currentRootUri.startsWith('file:') || currentRootUri.startsWith('package:'));
      }

      if (bindRegistrar && !shouldBootstrapChild) {
        final isolate = await service.getIsolate(isolateId);
        final registryLib = _findRegistryLibrary(isolate.libraries, forTests: forTests);

        final libId = registryLib?.id;
        if (libId != null) {
          final fnName = forTests
            ? Constant.REGISTER_TEST_GENERATED_ARTIFACTS_FN_NAME
            : Constant.REGISTER_GENERATED_ARTIFACTS_FN_NAME;
          await service
            .evaluate(
              isolateId,
              libId,
              'bindAotRegistrar($fnName, forTests: $forTests)',
            )
            .timeout(const Duration(seconds: 10));
        } else if (!forTests && !isRunningFromDill && Platform.environment['JETLEAF_BOOTSTRAPPED'] != '1') {
          currentRootUri = isolate.rootLib?.uri;
          shouldBootstrapChild = currentRootUri != null && (currentRootUri.startsWith('file:') || currentRootUri.startsWith('package:'));
        }
      }
    } finally {
      await service.dispose();
    }
  } catch (_) {
    // Best-effort in-process reload/binding; if VM Service is unavailable
    // (e.g. AOT native executable), continue with the currently loaded symbols.
  } finally {
    if (startedWebServer) {
      try {
        await developer.Service.controlWebServer(
          enable: false,
          silenceOutput: true,
        );
      } catch (_) {}
    }
  }

  if (shouldBootstrapChild && currentRootUri != null) {
    await _runBootstrappedChild(
      root: root,
      registryFile: registryFile,
      currentRootUri: currentRootUri,
      args: args,
    );
  }
}

/// Emits `.jetleaf/generated/runtime_bootstrap.g.dart` importing both
/// [registryFile] and the user's entrypoint ([currentRootUri]), binds
/// `registerGeneratedArtifacts` via [bindAotRegistrar], and executes the user's
/// `main` in a child Dart process with `JETLEAF_BOOTSTRAPPED=1`.
///
/// Watches `SIGINT` and `SIGTERM` on the parent process and forwards them to
/// the child process before awaiting `process.exitCode` so Jetleaf's
/// `ApplicationShutdownHandlerHook` runs cleanly when the user or IDE stops
/// the application.
Future<void> _runBootstrappedChild({
  required Directory root,
  required File registryFile,
  required String currentRootUri,
  required List<String> args,
}) async {
  final outDir = JetleafPaths.generatedDir(root);
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }
  final bootstrapFile = File(p.join(outDir.path, 'runtime_bootstrap.g.dart'));
  final packageName = _readPackageName(root);
  final entryUri = _toPackageUriIfInLib(currentRootUri, root, packageName) ?? currentRootUri;
  final registryUri = _toPackageUriIfInLib(Uri.file(registryFile.absolute.path).toString(), root, packageName) ?? Uri.file(registryFile.absolute.path).toString();

  final shape = await _entryMainShapeFor(currentRootUri, root);
  final call = shape.takesArgs ? 'entry.main(args)' : 'entry.main()';
  final tail = shape.returnsVoid
      ? '$call;'
      : 'final result = $call;\n  if (result is Future) await result;';

  await bootstrapFile.writeAsString(
    "// ignore_for_file: unused_import, duplicate_import\n"
    "import 'package:jetleaf_tools/jetleaf_tools.dart';\n"
    "import '$registryUri';\n"
    "import '$entryUri' as entry;\n\n"
    "Future<void> main(List<String> args) async {\n"
    "  bindAotRegistrar(${Constant.REGISTER_GENERATED_ARTIFACTS_FN_NAME});\n"
    "  $tail\n"
    "}\n",
  );

  final process = await Process.start(
    Platform.resolvedExecutable,
    ['run', bootstrapFile.absolute.path, ...args],
    workingDirectory: root.path,
    environment: {'JETLEAF_BOOTSTRAPPED': '1'},
    mode: ProcessStartMode.inheritStdio,
  );

  final signalSubs = <StreamSubscription<ProcessSignal>>[];
  void forwardSignal(ProcessSignal signal) {
    try {
      signalSubs.add(signal.watch().listen((sig) {
        try {
          process.kill(sig);
        } catch (_) {}
      }));
    } catch (_) {
      // Signal watching may be unsupported on some platforms (e.g. SIGTERM on Windows).
    }
  }

  forwardSignal(ProcessSignal.sigint);
  forwardSignal(ProcessSignal.sigterm);

  final code = await process.exitCode;
  for (final sub in signalSubs) {
    await sub.cancel();
  }
  exit(code);
}

/// Parses the top-level `main` function declaration in [uriString] to
/// determine whether it accepts positional arguments (`takesArgs`) and whether
/// it declares a `void` return type (`returnsVoid`).
///
/// Falls back to `(takesArgs: true, returnsVoid: false)` if the source file
/// cannot be located or parsed.
Future<({bool takesArgs, bool returnsVoid})> _entryMainShapeFor(
  String uriString,
  Directory root,
) async {
  try {
    File? entryFile;
    if (uriString.startsWith('file:')) {
      entryFile = File.fromUri(Uri.parse(uriString));
    } else if (uriString.startsWith('package:')) {
      final parts = uriString.substring('package:'.length).split('/');
      if (parts.length > 1) {
        entryFile = File(p.join(root.path, Constant.LIB, parts.skip(1).join(p.separator)));
      }
    }
    if (entryFile != null && entryFile.existsSync()) {
      final content = await entryFile.readAsString();
      final result = parseString(content: content, throwIfDiagnostics: false);
      for (final declaration in result.unit.declarations) {
        if (declaration is! ast.FunctionDeclaration) continue;
        if (declaration.name.lexeme != 'main') continue;
        final params = declaration.functionExpression.parameters?.parameters ?? [];
        final takesArgs = params.any((param) => param.isRequiredPositional || param.isOptionalPositional);
        final returnsVoid = declaration.returnType?.toString().trim() == 'void';
        return (takesArgs: takesArgs, returnsVoid: returnsVoid);
      }
    }
  } catch (_) {}
  return (takesArgs: true, returnsVoid: false);
}