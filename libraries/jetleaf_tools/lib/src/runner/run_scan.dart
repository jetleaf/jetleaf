import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:vm_service/vm_service_io.dart';

import '../builder/runtime_builder.dart';
import '../cache/cache_aware_scanner.dart';
import '../cache/indexer/build_command.dart' as builder;
import '../cache/manager/cacheable_manager.dart';
import '../scanner/application_runtime_scanner.dart';
import '../scanner/runtime_scanner.dart';
import '../scanner/runtime_scanner_configuration.dart';
import '../scanner/runtime_scanner_summary.dart';
import '../utils/utils.dart';
import 'package:jetleaf_core/lang.dart';

/// Executes a **full application runtime scan**, builds a runtime context,
/// and registers it globally.
///
/// This method is the **primary entry point** for initializing Jetleaf’s
/// runtime model in real applications. It orchestrates:
/// - Source discovery
/// - Package scanning and exclusion
/// - Declaration and link generation
/// - Runtime context creation
///
/// The resulting runtime context is automatically registered into
/// [Runtime], making all scanned types, hints, and declarations immediately
/// available for runtime execution.
///
/// ---
///
/// ## Parameters
///
/// ### `source`
/// Optional root [Directory] used as the base for scanning.
///
/// If omitted, the scanner will infer the source root using the current
/// working directory and runtime environment.
///
/// This is commonly used when:
/// - Running scans in monorepos
/// - Testing alternate project layouts
/// - Executing scans from tooling or build systems
///
/// ---
///
/// ### `config`
/// Optional [RuntimeScannerConfiguration] used to customize scanning behavior.
///
/// When provided, this configuration is **merged** with Jetleaf’s
/// default production-safe configuration:
/// - Default exclusions are preserved
/// - Provided values override defaults selectively
///
/// This prevents accidental scanning of:
/// - Tests
/// - Tooling
/// - Build artifacts
/// - Analyzer internals
///
/// ---
///
/// ### `forceLoadLibraries`
/// Forces all discovered libraries to be loaded eagerly.
///
/// This flag is useful when:
/// - Performing deep reflection analysis
/// - Generating complete declaration graphs
/// - Debugging missing type resolution
///
/// If [config.forceLoadLibraries] is set, it takes precedence over this value.
///
/// ---
///
/// ### `onInfo`, `onWarning`, `onError`
/// Optional logging callbacks invoked during scanning.
///
/// If not provided, default handlers print messages to stdout using
/// clearly distinguishable markers:
/// - `(∞INFO∞)`
/// - `(∞WARN∞)`
/// - `(∞ERROR∞)`
///
/// These callbacks allow integration with structured loggers,
/// CI pipelines, or developer tooling.
///
/// ---
///
/// ### `args`
/// Command-line arguments forwarded to the scanner.
///
/// These arguments may influence:
/// - Conditional compilation
/// - Environment-specific scanning logic
/// - Feature toggles used by generators
///
/// ---
///
/// ## Configuration Merging Strategy
///
/// The scanner builds a **derived configuration** that:
/// - Uses Jetleaf-safe defaults
/// - Applies user overrides selectively
/// - Preserves exclusion rules critical to performance and correctness
///
/// Key defaults include:
/// - Skipping test directories
/// - Excluding analyzer and compiler internals
/// - Preventing accidental scans of `.dart_tool` and `build` directories
///
/// ---
///
/// ## Execution Flow
///
/// 1. An [ApplicationRuntimeScanner] is instantiated with logging hooks.
/// 2. A merged [RuntimeScannerConfiguration] is constructed.
/// 3. The scanner performs a full runtime scan using:
///    - The resolved configuration
///    - Command-line arguments
///    - Optional source directory
/// 4. A [RuntimeScannerSummary] is produced.
/// 5. The resulting runtime context is registered globally via
///    [Runtime.register].
///
/// ---
///
/// ## Returns
///
/// A [RuntimeScannerSummary] containing:
/// - Scan statistics
/// - Discovered libraries and declarations
/// - Generated runtime context
///
/// This object can be used for:
/// - Diagnostics
/// - Build tooling
/// - Reporting and analysis
///
/// ---
///
/// ## Example
///
/// ```dart
/// final summary = await runScan(
///   source: Directory('lib'),
///   config: RuntimeScannerConfiguration(
///     enableTreeShaking: true,
///   ),
/// );
///
/// print('Scanned ${summary.libraryCount} libraries');
/// ```
///
/// ---
///
/// ## Intended Use Cases
///
/// - Application startup initialization
/// - Build-time runtime generation
/// - Tooling and code generation pipelines
/// - Production runtime bootstrapping
///
/// ---
///
/// ## See Also
///
/// - [ApplicationRuntimeScanner]
/// - [RuntimeScannerConfiguration]
/// - [RuntimeScannerSummary]
/// - [Runtime]
Future<RuntimeScannerSummary> runScan({
  Directory? source,
  RuntimeScannerConfiguration? config,
  bool forceLoadLibraries = false,
  OnLogged? onInfo,
  OnLogged? onWarning,
  OnLogged? onError,
  List<String> args = const [],
  RuntimeScanner? configuredScanner,
  bool overrideConfig = false,
}) async {
  final defaultConfig = RuntimeScannerConfiguration(
    skipTests: config?.skipTests ?? true,
    reload: config?.reload ?? true,
    packagesToScan: config?.packagesToScan ?? [],
    packagesToExclude: [
      'collection',
      'analyzer',
      '_fe_analyzer',
      "r:.*/example/.*",
      "r:.*/test/.*",
      "r:.*/tool/.*",
      "r:.*/benchmark/.*",
      "r:.*/.dart_tool/.*",
      "r:.*/build/.*",
      ...config?.packagesToExclude ?? [],
    ],
    additions: config?.additions ?? [],
    updateAssets: config?.updateAssets ?? false,
    writeDeclarationsToFiles: config?.writeDeclarationsToFiles ?? false,
    forceLoadLibraries: config?.forceLoadLibraries ?? forceLoadLibraries,
    scanClasses: config?.scanClasses ?? [],
    filesToScan: config?.filesToScan ?? [],
    filesToExclude: config?.filesToExclude ?? [],
    enableTreeShaking: config?.enableTreeShaking ?? false,
    excludeClasses: config?.excludeClasses ?? [],
    updatePackages: config?.updatePackages ?? false,
    removals: config?.removals ?? [],
    outputPath: config?.outputPath ?? Constant.GENERATED_OUTPUT_PATH,
  );

  final effectiveConfig = overrideConfig
    ? config ?? defaultConfig
    : defaultConfig;
  final useCaching = effectiveConfig.enableCaching;

  final innerScanner = configuredScanner ?? ApplicationRuntimeScanner(
    onInfo: onInfo ?? (msg, overwrite) => print("(∞INFO∞) ${overwrite ? '\r$msg' : msg}"),
    onWarning: onWarning ?? (msg, overwrite) => print("(∞WARN∞) ${overwrite ? '\r$msg' : msg}"),
    onError: onError ?? (msg, overwrite) => print("(∞ERROR∞) ${overwrite ? '\r$msg' : msg}"),
  );

  final scanner = useCaching ? CacheAwareScanner(
    inner: innerScanner,
    source: source,
    onInfo: onInfo,
    onWarning: onWarning,
    onError: onError,
  ) : innerScanner;

  return await scanner.scan(effectiveConfig, args, source: source);
}

/// Ensures that the project's `.jetleaf/cache/main/` declaration cache and
/// `lib/_jetleaf/` AOT registry are built and up-to-date when a developer
/// launches the application directly via `dart run` or IDE Run/Debug buttons.
///
/// When source files in `lib/`, `bin/`, `resources/`, or `pubspec.yaml` are
/// newer than the generated artifacts (or when `.jetleaf/cache/` is missing
/// after a fresh clone or `jl clean`), this function automatically:
/// 1. Executes an incremental build (`runBuild`) to refresh `.jetleaf/cache/`
///    and `lib/_jetleaf/`.
/// 2. If `lib/_jetleaf/main/registry.g.dart` changed on disk during the build,
///    connects to the current Dart VM isolate's VM Service (temporarily
///    enabling it via `dart:developer` if needed) and invokes `reloadSources`
///    so the newly generated closures and AOP proxies are live in the running
///    isolate before `registerGeneratedArtifacts` executes.
Future<bool> ensureDevelopmentRuntime({
  Directory? projectRoot,
  bool hasAotRegistrar = true,
  bool isRunningFromDill = false,
}) async {
  try {
    final scriptPath = Platform.script.toString();
    // Skip inside `dart test` runner isolates or pre-warmed `jl dev` entry stubs.
    if (scriptPath.contains('test.dart') ||
        scriptPath.contains('/test/') ||
        scriptPath.endsWith('_test.dart') ||
        scriptPath.contains('.jetleaf/generated/entries/')) {
      return false;
    }

    final root = (projectRoot ?? Directory.current).absolute;
    if (!RuntimeUtils.isJetLeafBuildProject(root)) {
      return false;
    }
    final libDir = Directory(p.join(root.path, 'lib'));
    if (!libDir.existsSync()) {
      return false;
    }

    final fingerprint = CacheManager.generateFingerprint(skipTests: true);
    final cacheValid = CacheManager.isValid(
      root,
      configFingerprint: fingerprint,
      forTests: false,
    );
    final registryFile = File(
      p.join(
        root.path,
        Constant.GENERATED_DIR_NAME,
        Constant.REGISTRY_FILE_NAME,
      ),
    );
    final cacheFpFile = File(
      p.join(
        root.path,
        Constant.WORKSPACE_DIR_NAME,
        Constant.CACHE_DIR_NAME,
        Constant.MAIN_DIR_NAME,
        'fingerprint.txt',
      ),
    );

    bool needsRebuild = !cacheValid || (hasAotRegistrar && !registryFile.existsSync());
    if (!needsRebuild && cacheFpFile.existsSync()) {
      DateTime baseline = cacheFpFile.lastModifiedSync();
      if (hasAotRegistrar && registryFile.existsSync()) {
        final regTime = registryFile.lastModifiedSync();
        if (regTime.isBefore(baseline)) {
          baseline = regTime;
        }
      }
      needsRebuild = _hasSourceNewerThan(root, baseline);
    }

    if (!needsRebuild) {
      return false;
    }

    final previousRegistrySource = registryFile.existsSync() ? registryFile.readAsStringSync() : null;

    await builder.runBuild(const [], root: root);

    final updatedRegistrySource = registryFile.existsSync() ? registryFile.readAsStringSync() : null;
    final registryChanged = hasAotRegistrar
      && updatedRegistrySource != null
      && previousRegistrySource != updatedRegistrySource;

    if (registryChanged && !isRunningFromDill) {
      await _reloadCurrentIsolateSources();
    }
    return true;
  } catch (_) {
    return false;
  }
}

bool _hasSourceNewerThan(Directory root, DateTime baseline) {
  final pubspec = File(p.join(root.path, 'pubspec.yaml'));
  if (pubspec.existsSync() && pubspec.lastModifiedSync().isAfter(baseline)) {
    return true;
  }

  for (final folder in const ['lib', 'bin', 'resources']) {
    final dir = Directory(p.join(root.path, folder));
    if (!dir.existsSync()) continue;
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final rel = p.relative(entity.path, from: root.path);
      if (rel.startsWith('lib${p.separator}${Constant.JETLEAF_GENERATED_DIR_NAME}${p.separator}') || rel.endsWith('.g.dart')) {
        continue;
      }
      
      if (entity.lastModifiedSync().isAfter(baseline)) {
        return true;
      }
    }
  }
  return false;
}

Future<void> _reloadCurrentIsolateSources() async {
  bool startedWebServer = false;
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
      await service
        .reloadSources(isolateId, pause: false)
        .timeout(const Duration(seconds: 15));
    } finally {
      await service.dispose();
    }
  } catch (_) {
    // Best-effort in-process reload; if VM Service is unavailable (e.g. AOT),
    // continue with the currently loaded isolate symbols.
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
}