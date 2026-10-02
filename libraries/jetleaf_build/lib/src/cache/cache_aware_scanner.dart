import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:mirrors' as mirrors;

import '../builder/runtime_builder.dart';
import '../build/runtime_manifest.dart';
import '../runtime/executor/resolving/default_runtime_executor_resolving.dart';
import '../runtime/provider/runtime_provider.dart';
import '../runtime/declaration/declaration.dart';
import '../runtime/scanner/default_runtime_scanner_summary.dart';
import '../runtime/scanner/application_runtime_scanner.dart';
import '../runtime/scanner/mock_runtime_scanner.dart';
import '../runtime/scanner/runtime_scanner.dart';
import '../runtime/scanner/runtime_scanner_configuration.dart';
import '../runtime/scanner/runtime_scanner_summary.dart';
import '../utils/utils.dart';
import '../utils/reflection_utils.dart';
import '../utils/constant.dart';
import 'jetleaf_paths.dart';
import 'manager/cacheable_manager.dart';
import 'models.dart';
import '../serialization/jetleaf_json.dart';

/// Data payload sent to the background isolate for cache writing.
///
/// All fields must be serializable (no mirrors or live objects).
class _CacheWritePayload {
  final List<ClassDeclaration> components;
  final String directoryPath;
  final String fingerprint;
  final bool forTests;
  final Set<String> libraryUris;
  final Map<String, List<String>> subclassIndex;
  final Map<String, List<Map<String, String>>> annotatedIndex;

  const _CacheWritePayload({
    required this.components,
    required this.directoryPath,
    required this.fingerprint,
    required this.forTests,
    required this.libraryUris,
    required this.subclassIndex,
    required this.annotatedIndex,
  });
}

/// Top-level function that runs in a background isolate to write cache to disk.
///
/// All data is pre-extracted — no mirror access here.
Future<void> _writeCacheToDisk(_CacheWritePayload payload) async {
  final directory = Directory(payload.directoryPath);

  // 1. Write binary cache
  await CacheManager.save(
    payload.components,
    directory,
    configFingerprint: payload.fingerprint,
    forTests: payload.forTests,
  );

  // 2. Write pre-computed JSON indexes
  final cacheDir = JetleafPaths.cacheDir(directory, forTests: payload.forTests);
  if (!cacheDir.existsSync()) {
    await cacheDir.create(recursive: true);
  }

  // libraries.json
  try {
    final file = JetleafPaths.librariesJson(
      directory,
      forTests: payload.forTests,
    );
    final data = payload.libraryUris.map((uri) => {'uri': uri}).toList();
    await file.writeAsString(_prettyJson(data), flush: true);
  } catch (_) {}

  // subclasses.json
  try {
    final file = JetleafPaths.subclassesJson(
      directory,
      forTests: payload.forTests,
    );
    await file.writeAsString(_prettyJson(payload.subclassIndex), flush: true);
  } catch (_) {}

  // annotated_methods.json
  try {
    final file = JetleafPaths.annotatedMethodsJson(
      directory,
      forTests: payload.forTests,
    );
    await file.writeAsString(_prettyJson(payload.annotatedIndex), flush: true);
  } catch (_) {}
}

/// Encodes [data] as persisted JSON with the shared four-space indentation
/// policy.
String _prettyJson(dynamic data) {
  return JetleafJson.encode(data);
}

/// Resolves a URI to a file path, handling both `file:` and `package:` schemes.
/// For `package:` URIs, reads `.dart_tool/package_config.json` to resolve.
String? _resolveUriToFilePath(Uri uri, Directory projectRoot) {
  if (uri.scheme == 'file') return uri.toFilePath();
  if (uri.scheme == 'package') {
    try {
      final configPath = '${projectRoot.path}/.dart_tool/package_config.json';
      final configFile = File(configPath);
      if (configFile.existsSync()) {
        final config =
            jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
        final packages = config['packages'] as List<dynamic>?;
        if (packages != null) {
          for (final p in packages) {
            final pkg = p as Map<String, dynamic>;
            if (pkg['name'] == uri.pathSegments.first) {
              final rootUri = Uri.parse(pkg['rootUri'] as String);
              final relUri = Uri.file(
                rootUri.toFilePath(),
              ).resolve(uri.path.substring(uri.pathSegments.first.length + 1));
              return relUri.toFilePath();
            }
          }
        }
      }
    } catch (_) {}
    // Fallback: try resolving relative to project root
    try {
      final relPath = uri.pathSegments.skip(1).join('/');
      final candidate = File('${projectRoot.path}/$relPath');
      if (candidate.existsSync()) return candidate.path;
    } catch (_) {}
  }
  return null;
}

/// {@template cache_aware_scanner}
/// A **decorator** that wraps any [RuntimeScanner] with transparent
/// disk-based cache support.
///
/// [CacheAwareScanner] intercepts [scan] calls and:
/// 1. **Cache hit** — loads pre-built declarations from `.jetleaf_cache.bin`,
///    bypassing the expensive mirror-based scan entirely.
/// 2. **Cache miss** — delegates to the wrapped scanner, then persists the
///    discovered components to disk for future startups.
///
/// This scanner is the **recommended entry point** for all scan operations
/// in Jetleaf. It should wrap both [ApplicationRuntimeScanner] and
/// [MockRuntimeScanner] to ensure consistent caching behavior across
/// production and test environments.
///
/// ---
///
/// ## Usage
///
/// ```dart
/// final scanner = CacheAwareScanner(
///   inner: ApplicationRuntimeScanner(...),
///   source: Directory.current,
/// );
/// final summary = await scanner.scan(config, args);
/// ```
///
/// ---
///
/// ## Cache Lifecycle
///
/// ```text
/// scan() called
///   → cache valid? ──yes──→ load from cache → return
///   │
///   no
///   │
///   → delegate to inner scanner
///   → inner scanner produces mirror data
///   → extract IndexedClass from mirrors
///   → save to .jetleaf_cache.bin
///   → return inner scanner's summary
/// ```
///
/// The cache stores [IndexedClass] — lightweight representations of
/// class metadata (annotations, constructors, fields, methods, etc.)
/// that can be serialized to disk and loaded on restart to skip the
/// full mirror-based scan.
/// {@endtemplate}
final class CacheAwareScanner implements RuntimeScanner {
  /// The wrapped scanner used for full mirror-based scans on cache miss.
  final RuntimeScanner _inner;

  /// Guards against concurrent scans within the same process.
  /// When one scan is in progress, subsequent scans wait for it to complete.
  static Completer<void>? _scanInProgress;

  /// Cache for mixin symbol resolution: Symbol → qualified name.
  /// Avoids repeated iteration of all libraries for each mixin of each class.
  static final Map<Symbol, String> _mixinSymbolCache = {};

  /// The root directory to scan. Defaults to [Directory.current] if null.
  final Directory? _source;

  /// Callback invoked for **informational log messages**.
  final OnLogged? onInfo;

  /// Callback invoked for **warning log messages**.
  final OnLogged? onWarning;

  /// Callback invoked for **error log messages**.
  final OnLogged? onError;

  /// {@macro cache_aware_scanner}
  CacheAwareScanner({
    required RuntimeScanner inner,
    Directory? source,
    this.onInfo,
    this.onWarning,
    this.onError,
  }) : _inner = inner,
       _source = source;

  @override
  Future<RuntimeScannerSummary> scan(
    RuntimeScannerConfiguration configuration,
    List<String> args, {
    Directory? source,
  }) async {
    final effectiveSource = source ?? _source ?? Directory.current;
    final forTests = !configuration.skipTests;
    final manifest = configuration.buildMode == RuntimeBuildMode.development
        ? null
        : RuntimeManifestStore.load(effectiveSource, forTests: forTests);

    if (configuration.buildMode == RuntimeBuildMode.strict &&
        manifest == null) {
      throw StateError(
        'Jetleaf runtime manifest is missing or invalid for ${effectiveSource.path}. '
        'Run `jl build` before starting in strict production mode.',
      );
    }
    if (configuration.buildMode == RuntimeBuildMode.compatibility &&
        manifest == null) {
      RuntimeBuilder.logVerboseWarning(
        'Runtime manifest unavailable; falling back to mirror discovery.',
      );
    }

    // If another scan is already in progress, wait for it to complete.
    // This prevents redundant concurrent scans in all_tests.dart.
    if (_scanInProgress != null) {
      RuntimeBuilder.logVerboseInfo(
        "Scan already in progress — waiting for it to complete",
      );
      await _scanInProgress!.future;
      // After the first scan completes, the runtime is populated.
      final summary = DefaultRuntimeScannerSummary();
      summary.setBuildTime(DateTime.now());
      return summary;
    }

    // If the runtime is already populated from a prior scan, skip.
    if (Runtime.isPopulated) {
      RuntimeBuilder.logVerboseInfo(
        "Runtime already populated — skipping scan",
      );
      final summary = DefaultRuntimeScannerSummary();
      summary.setBuildTime(DateTime.now());
      return summary;
    }

    _scanInProgress = Completer<void>();
    try {
      // Generate a fingerprint from the configuration to ensure different
      // scanner configurations (e.g., skipTests: true vs false) produce
      // different cache files. This prevents cross-contamination between
      // production and test scans.
      final fingerprint = CacheManager.generateFingerprint(
        skipTests: configuration.skipTests,
        packagesToExclude: configuration.packagesToExclude,
        packagesToScan: configuration.packagesToScan,
        enableTreeShaking: configuration.enableTreeShaking,
      );

      // 1. Try cache first — if valid and not a forced reload, skip full scan
      // A production manifest makes the serialized cache authoritative. This
      // allows generated entry stubs to use the cache even when their caller
      // did not manually set reload: false.
      if (!configuration.reload || manifest != null) {
        // 1a. Try exact fingerprint match
        var cacheResult = CacheManager.load(
          effectiveSource,
          configFingerprint: fingerprint,
          forTests: forTests,
        );

        // 1b. Fallback: try any valid cache in the same cache directory
        if (cacheResult == null) {
          cacheResult = CacheManager.loadAny(
            effectiveSource,
            forTests: forTests,
          );
          if (cacheResult != null) {
            RuntimeBuilder.logVerboseInfo(
              "Cache hit (fallback) — loaded ${cacheResult.components.length} components from any valid cache",
            );
          }
        } else {
          RuntimeBuilder.logVerboseInfo(
            "Cache hit — loading ${cacheResult.components.length} cached components...",
          );
        }

        if (cacheResult != null) {
          // In test mode, skip the diff check — cache was already validated
          // by load() (mtime check). Running diff() again is redundant and
          // overly strict (any editor save between runs invalidates cache).
          if (!forTests) {
            final fileDiff = CacheManager.diff(
              effectiveSource,
              forTests: forTests,
            );
            if (fileDiff.isClean) {
              return await _loadFromCache(
                cacheResult,
                effectiveSource,
                configuration,
                args,
                forTests: forTests,
              );
            } else {
              if (configuration.buildMode == RuntimeBuildMode.strict) {
                throw StateError(
                  'Jetleaf runtime manifest cache is stale. Run `jl build` again.',
                );
              }
              RuntimeBuilder.logVerboseInfo(
                "Cache stale — ${fileDiff.changeCount} file(s) changed (${fileDiff.modified.length} modified, ${fileDiff.added.length} added, ${fileDiff.removed.length} removed). Re-scanning...",
              );
            }
          } else {
            // Test mode: trust the cache — load() already validated mtimes
            RuntimeBuilder.logVerboseInfo(
              "Cache hit (test mode) — loading ${cacheResult.components.length} cached components...",
            );
            return await _loadFromCache(
              cacheResult,
              effectiveSource,
              configuration,
              args,
              forTests: forTests,
            );
          }
        }
      }

      if (configuration.buildMode == RuntimeBuildMode.strict) {
        throw StateError(
          'Jetleaf runtime cache is missing for the manifest. Run `jl build` again.',
        );
      }

      // 2. Cache miss, stale cache, or reload requested — delegate to inner scanner
      //    The inner scanner handles the full mirror-based scan.
      RuntimeBuilder.logVerboseInfo("Delegating to inner scanner...");
      final summary = await _inner.scan(configuration, args, source: source);

      // 3. After inner scan completes, save cache in the background (non-blocking)
      unawaited(
        _trySaveCache(effectiveSource, fingerprint, forTests: forTests),
      );

      return summary;
    } finally {
      _scanInProgress!.complete();
      _scanInProgress = null;
    }
  }

  /// Attempts to load declarations from the disk cache.
  ///
  /// If successful, registers the declarations in the runtime, populates
  /// `_sourceLibraries` from the current mirror system (so that subclass
  /// discovery, library lookups, and method enumeration all work), and
  /// returns a summary without invoking the inner scanner.
  Future<RuntimeScannerSummary> _loadFromCache(
    CacheDeserializationResult cacheResult,
    Directory directory,
    RuntimeScannerConfiguration configuration,
    List<String> args, {
    bool forTests = false,
  }) async {
    RuntimeBuilder.logVerboseInfo(
      "Cache hit — loading ${cacheResult.components.length} cached components...",
    );

    // Build declarations from cached data — already ClassDeclaration
    final declarations = <ClassDeclaration>[];
    for (final data in cacheResult.components) {
      try {
        declarations.add(data);
      } catch (e) {
        RuntimeBuilder.logVerboseWarning(
          "Failed to load declaration from cache for ${data.getName()}: $e",
        );
      }
    }

    // Populate subclasses and annotated methods on each class declaration
    for (final decl in declarations) {
      if (decl is StandardClassDeclaration) {
        final subClassNames = cacheResult.subclasses[decl.getQualifiedName()];
        if (subClassNames != null) {
          decl.setSubClasses(subClassNames);
        }
        // Collect annotated methods for this class
        final annotatedMethodNames = <String>[];
        for (final entry in cacheResult.annotatedMethods.entries) {
          for (final methodInfo in entry.value) {
            if (methodInfo['class'] == decl.getName()) {
              annotatedMethodNames.add(methodInfo['method'] ?? '');
            }
          }
        }
        if (annotatedMethodNames.isNotEmpty) {
          decl.setAnnotatedMethods(annotatedMethodNames);
        }
      }
    }

    RuntimeBuilder.logVerboseInfo(
      "Built ${declarations.length} declarations from cache",
    );

    // Register declarations in the runtime provider
    registerCachedDeclarations(declarations);

    // Register packages from cache
    for (final pkg in cacheResult.packages) {
      final name = pkg.getName();
      if (name.isEmpty) continue;
      final runtimePkg = createDefaultPackage(name);
      addRuntimePackage(runtimePkg);
    }
    RuntimeBuilder.logVerboseInfo(
      "Loaded ${cacheResult.packages.length} cached packages",
    );

    // Register assets from cache
    int loadedAssets = 0;
    for (final asset in cacheResult.assets) {
      final filePath = asset.getFilePath();
      if (filePath.isEmpty) continue;
      try {
        addRuntimeAsset(asset);
        loadedAssets++;
      } catch (_) {}
    }
    RuntimeBuilder.logVerboseInfo("Loaded $loadedAssets cached assets");

    // Populate _sourceLibraries from the current mirror system.
    await _registerSourceLibrariesFromMirrors(
      directory,
      cacheResult: cacheResult,
      forTests: forTests,
      skipFreeze: true,
    );

    // Load pre-computed subclass and annotated-method indexes for
    // fast-path lookups (avoids walking _ClassReference trees at runtime).
    await loadPrecomputedIndexes(directory, forTests: forTests);

    // Freeze — hierarchy sorting and source library finalization
    freezeRuntimeLibrary();

    // Initialize runtime resolver for cache mode (AOT hints + JIT fallback)
    final resolving = DefaultRuntimeExecutorResolving(
      libraries: mirrors.currentMirrorSystem().libraries.values.toList(),
    );
    setRuntimeResolver(await resolving.resolve());

    // Build summary
    final summary = DefaultRuntimeScannerSummary();
    summary.setBuildTime(DateTime.now());
    summary.addInfos(RuntimeBuilder.onCompleted().getInfos());
    summary.addWarnings(RuntimeBuilder.onCompleted().getWarnings());
    summary.addErrors(RuntimeBuilder.onCompleted().getErrors());
    summary.addAll(RuntimeBuilder.onCompleted().getLogs());
    RuntimeBuilder.clearTrackedLogs();

    return summary;
  }

  /// Checks if pre-computed indexes exist on disk.
  Future<void> loadPrecomputedIndexes(
    Directory directory, {
    bool forTests = false,
  }) async {
    // Pre-computed indexes are loaded lazily by the runtime provider
    // when needed. This method is a no-op for now.
  }

  /// Populates `_sourceLibraries` from the current mirror system.
  ///
  /// Uses pre-computed `libraries.json` from the builder to skip source code
  /// reading and filter which mirrors to process. Without this, APIs like
  /// getSubClasses(), getAllMethods(), collectAnnotatedMethods(), and library
  /// lookups all return empty because they iterate `_sourceLibraries`.
  ///
  /// In test mode [forTests], the `libraries.json` filter is skipped because
  /// the test mirror system already has the correct libraries loaded. The
  /// pre-computed registry was generated by a previous test's scan which may
  /// have had a different mirror system state.
  Future<void> _registerSourceLibrariesFromMirrors(
    Directory directory, {
    CacheDeserializationResult? cacheResult,
    bool forTests = false,
    bool skipFreeze = false,
  }) async {
    final sw = Stopwatch()..start();
    final ms = mirrors.currentMirrorSystem();
    int registered = 0;

    // Build a package cache from the root package
    final packageName = await _readPackageName(directory);
    final packageCache = <String, Package>{
      packageName: createDefaultPackage(packageName),
    };

    // Use pre-computed library URIs from cache for filtering
    final knownLibs = cacheResult != null
        ? cacheResult.libraries.map((l) => l.uri).toSet()
        : await _loadLibraryRegistry(directory);

    try {
      for (final lib in ms.libraries.values) {
        final uri = lib.uri;

        // Skip dart:mirrors itself — it causes issues when registered
        if (uri.toString() == 'dart:mirrors') continue;

        // If we have a pre-computed registry, only process known libraries
        // (avoids registering test-only or transitive-dependency mirrors
        // that the builder deliberately excluded). In test mode, skip this
        // filter because the test mirror system already has the correct
        // libraries loaded and the pre-computed registry may be stale.
        if (!forTests &&
            knownLibs != null &&
            !knownLibs.contains(uri.toString())) {
          RuntimeBuilder.logVerboseInfo(
            "Skipping library $uri (not in libraries.json)",
          );
          continue;
        }

        try {
          final isBuiltIn = RuntimeUtils.isBuiltInDartLibrary(uri);
          final pkg = _resolvePackage(uri, packageCache);

          // Skip source code reading — modifiers (mixin, sealed, base, etc.)
          // are already stored in the IndexedClass cache. The full scan path
          // needs source code for modifier detection, but the cache path
          // already has that data.
          addRuntimeSourceLibrary(pkg, '', isBuiltIn, lib);
          registered++;
        } catch (e) {
          // If the list is frozen mid-iteration (triggered by _SourceLibrary._init
          // calling into code that invokes getSourceLibraries()), stop immediately.
          if (e is UnsupportedError) break;
          RuntimeBuilder.logVerboseWarning(
            "Failed to register source library $uri: $e",
          );
        }
      }
    } catch (e) {
      if (e is UnsupportedError) {
        RuntimeBuilder.logVerboseInfo(
          "Source libraries already frozen — skipping registration",
        );
        return;
      }
      rethrow;
    }

    // Only freeze if we actually registered something and it's not yet frozen
    if (registered > 0 && !skipFreeze) {
      freezeRuntimeLibrary();
    }

    sw.stop();
    RuntimeBuilder.logVerboseInfo(
      "Registered $registered source libraries from mirror system in ${sw.elapsedMilliseconds}ms",
    );
  }

  /// Loads the pre-computed library registry from `libraries.json`.
  ///
  /// Returns the set of known library URIs, or null if the file doesn't exist.
  /// Checks both production and test cache directories.
  Future<Set<String>?> _loadLibraryRegistry(Directory directory) async {
    final candidates = [
      JetleafPaths.librariesJson(directory),
      JetleafPaths.librariesJson(directory, forTests: true),
    ];
    for (final file in candidates) {
      try {
        if (!file.existsSync()) continue;

        final content = await file.readAsString();
        final List<dynamic> data = jsonDecode(content);
        return data.map((e) => e['uri'] as String).toSet();
      } catch (_) {}
    }
    return null;
  }

  /// Resolves the [Package] for a given library [uri], using a local cache
  /// to avoid redundant package construction.
  Package _resolvePackage(Uri uri, Map<String, Package> packageCache) {
    if (RuntimeUtils.isBuiltInDartLibrary(uri)) {
      final existing = packageCache[Constant.DART_PACKAGE_NAME];
      if (existing != null) return existing;
      return createBuiltInPackage(packageCache);
    }

    final packageName = RuntimeUtils.getPackageNameFromUri(uri.toString());
    if (packageName != null) {
      final existing = packageCache[packageName];
      if (existing != null) return existing;
      final pkg = createDefaultPackage(packageName);
      packageCache[packageName] = pkg;
      return pkg;
    }

    return createDefaultPackage(uri.toString());
  }

  /// Attempts to save scan results to cache after the inner scanner completes.
  ///
  /// This is called after the inner scanner's [scan] method returns.
  /// Extracts data from mirrors in the main isolate, then writes to disk
  /// in a separate isolate to avoid blocking the event loop.
  Future<void> _trySaveCache(
    Directory directory,
    String fingerprint, {
    bool forTests = false,
  }) async {
    await Future<void>.value(); // yield before synchronous work
    try {
      // Check if cache already exists and is valid — skip save if so
      if (CacheManager.isValid(
        directory,
        configFingerprint: fingerprint,
        forTests: forTests,
      )) {
        RuntimeBuilder.logVerboseInfo("Cache already valid — skipping save");
        return;
      }

      // Delegate to inner scanner's cache-save capability if available
      MirrorState? mirrorState;
      if (_inner case MockRuntimeScanner mockScanner) {
        mirrorState = mockScanner.getMirrorState();
      } else if (_inner case ApplicationRuntimeScanner appScanner) {
        mirrorState = appScanner.getMirrorState();
      }

      if (mirrorState != null) {
        // Extract components from mirrors in main isolate (mirrors can't cross isolate boundary)
        // These are async and yield periodically to avoid blocking the event loop.
        final components = await _extractComponentsFromMirrors(
          directory,
          mirrorState.forceLoadedMirrors,
          mirrorState.mirrorSystem,
        );

        // Extract index data from mirrors in main isolate
        final indexData = await _extractIndexDataFromMirrors(
          mirrorState.forceLoadedMirrors,
          mirrorState.mirrorSystem,
        );

        // Create payload for background isolate
        final payload = _CacheWritePayload(
          components: components,
          directoryPath: directory.path,
          fingerprint: fingerprint,
          forTests: forTests,
          libraryUris: indexData.libraryUris,
          subclassIndex: indexData.subclassIndex,
          annotatedIndex: indexData.annotatedIndex,
        );

        // Write to disk in a separate isolate (non-blocking)
        await Isolate.run(() => _writeCacheToDisk(payload));

        RuntimeBuilder.logVerboseInfo(
          "Saved ${components.length} components to cache in background isolate",
        );
      }
    } catch (e) {
      RuntimeBuilder.logVerboseWarning("Failed to save cache: $e");
    }
  }

  /// Extracts [ClassDeclaration] from mirror data.
  ///
  /// Collects [ClassDeclaration] directly from force-loaded mirrors and SDK mirrors.
  /// This runs in the main isolate where mirrors are available.
  /// Yields periodically to avoid blocking the event loop.
  Future<List<ClassDeclaration>> _extractComponentsFromMirrors(
    Directory directory,
    List<mirrors.LibraryMirror> forceLoadedMirrors,
    mirrors.MirrorSystem access,
  ) async {
    final processedUris = <String>{};
    final components = <ClassDeclaration>[];

    // Build library declarations for each URI (needed for declaration construction)
    final libMap = <String, LibraryDeclaration>{};
    final unknownPkg = MaterialPackage(
      name: 'unknown',
      version: 'unknown',
      isRootPackage: false,
      filePath: null,
      rootUri: null,
      dependencies: const [],
      devDependencies: const [],
      jetleafDependencies: const [],
    );
    for (final lib in forceLoadedMirrors) {
      final uri = lib.uri.toString();
      libMap.putIfAbsent(
        uri,
        () => StandardLibraryDeclaration(
          uri: uri,
          name: uri,
          isPublic: true,
          isSynthetic: false,
          parentPackage: unknownPkg,
        ),
      );
    }
    for (final lib in access.libraries.values) {
      final uri = lib.uri.toString();
      libMap.putIfAbsent(
        uri,
        () => StandardLibraryDeclaration(
          uri: uri,
          name: uri,
          isPublic: true,
          isSynthetic: false,
          parentPackage: unknownPkg,
        ),
      );
    }

    // Collect ClassDeclaration from force-loaded mirrors (user code)
    int mirrorCount = 0;
    for (final lib in forceLoadedMirrors) {
      final uri = lib.uri.toString();
      if (processedUris.contains(uri)) continue;
      processedUris.add(uri);

      String? sourceCode;
      try {
        final fileUri = lib.uri;
        final filePath = _resolveUriToFilePath(fileUri, directory);
        if (filePath != null) {
          sourceCode = await File(filePath).readAsString();
        }
      } catch (_) {}

      final library = libMap[uri]!;
      for (final entry in lib.declarations.entries) {
        final value = entry.value;
        if (value case mirrors.TypeMirror typeMirror) {
          if (!typeMirror.isPrivate) {
            components.add(
              _declarationFromMirror(
                typeMirror,
                uri,
                library,
                sourceCode: sourceCode,
              ),
            );
          }
        }
      }

      mirrorCount++;
      if (mirrorCount % 50 == 0) await Future<void>.value();
    }

    // Collect from SDK mirrors (dart:core, etc.)
    for (final lib in access.libraries.values) {
      final uri = lib.uri.toString();
      if (processedUris.contains(uri)) continue;
      if (!uri.startsWith('dart:')) continue;
      processedUris.add(uri);

      final library = libMap[uri]!;
      for (final entry in lib.declarations.entries) {
        final value = entry.value;
        if (value case mirrors.TypeMirror typeMirror) {
          if (!typeMirror.isPrivate) {
            components.add(_declarationFromMirror(typeMirror, uri, library));
          }
        }
      }

      mirrorCount++;
      if (mirrorCount % 50 == 0) await Future<void>.value();
    }

    // Collect from mirror system libraries not yet processed
    for (final lib in access.libraries.values) {
      final uri = lib.uri.toString();
      if (processedUris.contains(uri)) continue;
      if (uri.startsWith('dart:')) continue;
      processedUris.add(uri);

      final library = libMap[uri]!;
      for (final entry in lib.declarations.entries) {
        final value = entry.value;
        if (value case mirrors.TypeMirror typeMirror) {
          if (!typeMirror.isPrivate) {
            String? typeSourceCode;
            try {
              final typeUri = typeMirror.location?.sourceUri;
              if (typeUri != null) {
                final filePath = _resolveUriToFilePath(typeUri, directory);
                if (filePath != null) {
                  typeSourceCode = await File(filePath).readAsString();
                }
              }
            } catch (_) {}
            if (typeSourceCode == null) {
              try {
                final fileUri = lib.uri;
                final filePath = _resolveUriToFilePath(fileUri, directory);
                if (filePath != null) {
                  typeSourceCode = await File(filePath).readAsString();
                }
              } catch (_) {}
            }
            components.add(
              _declarationFromMirror(
                typeMirror,
                uri,
                library,
                sourceCode: typeSourceCode,
              ),
            );
          }
        }
      }

      mirrorCount++;
      if (mirrorCount % 50 == 0) await Future<void>.value();
    }

    return components;
  }

  /// Extracts pre-computed index data from mirror data.
  ///
  /// Returns a record of (libraryUris, subclassIndex, annotatedIndex).
  /// This runs in the main isolate where mirrors are available.
  /// Yields periodically to avoid blocking the event loop.
  Future<
    ({
      Set<String> libraryUris,
      Map<String, List<String>> subclassIndex,
      Map<String, List<Map<String, String>>> annotatedIndex,
    })
  >
  _extractIndexDataFromMirrors(
    List<mirrors.LibraryMirror> forceLoadedMirrors,
    mirrors.MirrorSystem access,
  ) async {
    // ── 1. Library URIs ──────────────────────────────────────────
    final libraryUris = <String>{};
    for (final lib in forceLoadedMirrors) {
      libraryUris.add(lib.uri.toString());
    }
    for (final lib in access.libraries.values) {
      if (lib.uri.toString().startsWith('dart:')) {
        libraryUris.add(lib.uri.toString());
      }
    }

    // ── 2. Subclass index ────────────────────────────────────────
    final subclassIndex = <String, List<String>>{};
    mirrors.ClassMirror? safeSuperclass(mirrors.ClassMirror cls) {
      try {
        final sc = cls.superclass;
        if (sc == null) return null;
        if (sc.simpleName == #Object) return null;
        return sc;
      } catch (_) {
        return null;
      }
    }

    String? qualifiedNameFor(mirrors.TypeMirror type) {
      try {
        if (type is! mirrors.ClassMirror) return null;
        final name = mirrors.MirrorSystem.getName(type.simpleName);
        final uri =
            type.location?.sourceUri.toString() ??
            type.owner?.location?.sourceUri.toString();
        if (uri == null) return null;
        return ReflectionUtils.buildQualifiedName(name, uri);
      } catch (_) {
        return null;
      }
    }

    void registerChild(String parentqn, String childqn) {
      subclassIndex.putIfAbsent(parentqn, () => []);
      final list = subclassIndex[parentqn]!;
      if (!list.contains(childqn)) list.add(childqn);
    }

    final allClassMirrors = <mirrors.ClassMirror>[];
    for (final lib in forceLoadedMirrors) {
      for (final decl in lib.declarations.values) {
        if (decl is mirrors.ClassMirror) allClassMirrors.add(decl);
      }
    }
    for (final lib in access.libraries.values) {
      if (!lib.uri.toString().startsWith('dart:')) continue;
      for (final decl in lib.declarations.values) {
        if (decl is mirrors.ClassMirror) allClassMirrors.add(decl);
      }
    }

    int idx = 0;
    for (final classMirror in allClassMirrors) {
      final childqn = qualifiedNameFor(classMirror);
      if (childqn == null) {
        idx++;
        continue;
      }

      final sc = safeSuperclass(classMirror);
      if (sc != null) {
        final parentqn = qualifiedNameFor(sc);
        if (parentqn != null) registerChild(parentqn, childqn);
      }

      try {
        for (final iface in classMirror.superinterfaces) {
          final parentqn = qualifiedNameFor(iface);
          if (parentqn != null) registerChild(parentqn, childqn);
        }
      } catch (_) {}

      idx++;
      if (idx % 100 == 0) await Future<void>.value();
    }

    // ── 3. Annotated method index ────────────────────────────────
    final annotatedIndex = <String, List<Map<String, String>>>{};
    idx = 0;
    for (final classMirror in allClassMirrors) {
      final classqn = qualifiedNameFor(classMirror);
      if (classqn == null) {
        idx++;
        continue;
      }

      try {
        for (final decl in classMirror.declarations.values) {
          if (decl is! mirrors.MethodMirror) continue;
          if (decl.isConstructor) continue;
          if (decl.metadata.isEmpty) continue;

          for (final meta in decl.metadata) {
            if (!meta.hasReflectee) continue;
            final annotationName = mirrors.MirrorSystem.getName(
              meta.type.simpleName,
            );
            final methodName = mirrors.MirrorSystem.getName(decl.simpleName);
            final methodUri = classMirror.location?.sourceUri.toString() ?? '';

            annotatedIndex.putIfAbsent(annotationName, () => []);
            annotatedIndex[annotationName]!.add({
              'class': mirrors.MirrorSystem.getName(classMirror.simpleName),
              'method': methodName,
              'uri': methodUri,
            });
          }
        }
      } catch (_) {}

      idx++;
      if (idx % 100 == 0) await Future<void>.value();
    }

    return (
      libraryUris: libraryUris,
      subclassIndex: subclassIndex,
      annotatedIndex: annotatedIndex,
    );
  }

  /// Resolves a parameter type name from a mirror, handling function types,
  /// record types, and generic types that have special string representations.
  String _resolveParameterTypeName(
    mirrors.ParameterMirror p, {
    String? sourceCode,
  }) {
    final mirrorName = mirrors.MirrorSystem.getName(p.type.simpleName);

    // Function types: mirror returns "(ArgType) -> ReturnType" format
    // We want just "Function" for the LinkDeclaration name
    if (p.type is mirrors.FunctionTypeMirror) {
      return 'Function';
    }

    // Record types: mirror returns "Record" but we want the actual shape
    // e.g., "(String, int)" or "({String name, int age})"
    if (mirrorName == 'Record' && sourceCode != null) {
      final paramName = mirrors.MirrorSystem.getName(p.simpleName);
      try {
        // Match positional record: (Type1, Type2) paramName
        // Use [^()]+ to avoid matching from the outer constructor paren
        final positionalPattern = RegExp(
          r'\(([^()]+,[^()]+)\)\s+' + RegExp.escape(paramName) + r'\b',
          multiLine: true,
        );
        final posMatch = positionalPattern.firstMatch(sourceCode);
        if (posMatch != null) {
          return '(${posMatch.group(1)!})';
        }
        // Match named record: ({Type1 name1, Type2 name2}) paramName
        final namedPattern = RegExp(
          r'\(\{[^}]+\}\)\s+' + RegExp.escape(paramName) + r'\b',
          multiLine: true,
        );
        final namedMatch = namedPattern.firstMatch(sourceCode);
        if (namedMatch != null) {
          return namedMatch
              .group(0)!
              .replaceAll(RegExp(r'\s+' + RegExp.escape(paramName) + r'\b'), '')
              .trim();
        }
      } catch (_) {}
    }

    return mirrorName;
  }

  /// Resolves a return type name from a method mirror, handling function types,
  /// record types, and generic types.
  String _resolveReturnTypeName(
    mirrors.MethodMirror method, {
    String? sourceCode,
  }) {
    final mirrorName = mirrors.MirrorSystem.getName(
      method.returnType.simpleName,
    );

    // Function types
    if (method.returnType is mirrors.FunctionTypeMirror) {
      return 'Function';
    }

    // Record types
    if (mirrorName == 'Record' && sourceCode != null) {
      final methodName = mirrors.MirrorSystem.getName(method.simpleName);
      try {
        final pattern = RegExp(
          r'\(\([^)]*\)|\{[^}]*\}[^)]*\)\s+' +
              RegExp.escape(methodName) +
              r'\b',
          multiLine: true,
        );
        final match = pattern.firstMatch(sourceCode);
        if (match != null) {
          return match
              .group(0)!
              .replaceAll(
                RegExp(r'\s+' + RegExp.escape(methodName) + r'\b'),
                '',
              )
              .trim();
        }
      } catch (_) {}
    }

    return mirrorName;
  }

  /// Detects if a class name is declared as a mixin from source code.
  bool _isMixinClass(
    String? sourceCode,
    String className,
    mirrors.TypeMirror? typeMirror,
  ) {
    // Only use source code detection — the mirror check (typeMirror.mixin == typeMirror)
    // is a false positive: it returns true for ANY class that can be used as a mixin,
    // not just classes declared with `mixin class`.
    if (sourceCode != null) {
      final pattern1 = RegExp(
        r'\bmixin\s+class\s+' + RegExp.escape(className) + r'\b',
      );
      final pattern2 = RegExp(r'\bmixin\s+' + RegExp.escape(className) + r'\b');
      if (pattern1.hasMatch(sourceCode) || pattern2.hasMatch(sourceCode)) {
        return true;
      }
    }
    return false;
  }

  bool _isFinalClass(String? sourceCode, String className) {
    if (sourceCode == null) return false;
    final pattern = RegExp(
      r'\bfinal\s+class\s+' + RegExp.escape(className) + r'\b',
    );
    return pattern.hasMatch(sourceCode);
  }

  bool _isSealedClass(String? sourceCode, String className) {
    if (sourceCode == null) return false;
    final pattern = RegExp(
      r'\bsealed\s+class\s+' + RegExp.escape(className) + r'\b',
    );
    return pattern.hasMatch(sourceCode);
  }

  bool _isBaseClass(String? sourceCode, String className) {
    if (sourceCode == null) return false;
    final pattern = RegExp(
      r'\bbase\s+class\s+' + RegExp.escape(className) + r'\b',
    );
    return pattern.hasMatch(sourceCode);
  }

  bool _isInterfaceClass(String? sourceCode, String className) {
    if (sourceCode == null) return false;
    final pattern = RegExp(
      r'\binterface\s+class\s+' + RegExp.escape(className) + r'\b',
    );
    return pattern.hasMatch(sourceCode);
  }

  /// Extracts mixin names from source code or a [ClassMirror].
  ///
  /// In compiled kernel mode, [ClassMirror.mixin] doesn't work correctly,
  /// so we parse source code to find `with Mixin1, Mixin2` clauses.
  List<String> _extractMixins(
    mirrors.ClassMirror classMirror, {
    String? sourceCode,
  }) {
    // Try source code first — most reliable
    if (sourceCode != null) {
      final name = mirrors.MirrorSystem.getName(classMirror.simpleName);
      try {
        // Match: class ClassName ... with Mixin1, Mixin2 {
        final pattern = RegExp(
          r'\bclass\s+' +
              RegExp.escape(name) +
              r'\b[^{]*\bwith\s+([\w\s,<>\?]+)\s*\{',
          multiLine: true,
        );
        final match = pattern.firstMatch(sourceCode);
        if (match != null) {
          final withClause = match.group(1)!;
          return withClause
              .split(',')
              .map((s) => s.trim().replaceAll(RegExp(r'<[^>]*>'), '').trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }
      } catch (_) {}
    }
    // Fallback to mirror — may not work in compiled kernel mode
    try {
      final mixin = classMirror.mixin;
      if (mixin != classMirror) {
        return [mirrors.MirrorSystem.getName(mixin.simpleName)];
      }
    } catch (_) {}
    return const [];
  }

  /// Creates a [ClassDeclaration] from a mirror [TypeMirror].
  ///
  /// [sourceCode] is the source code of the file containing the type, used
  /// for detecting modifiers like `mixin`, `final`, `sealed`, etc. that are
  /// not available through dart:mirrors.
  ///
  /// [library] is the library declaration this type belongs to.
  ClassDeclaration _declarationFromMirror(
    mirrors.TypeMirror typeMirror,
    String libraryUri,
    LibraryDeclaration library, {
    String? sourceCode,
  }) {
    final name = mirrors.MirrorSystem.getName(typeMirror.simpleName);
    final actualUri = typeMirror.location?.sourceUri.toString() ?? libraryUri;

    List<ConstructorDeclaration> constructors = [];
    List<AnnotationDeclaration> classAnnotations = [];
    List<FieldDeclaration> fields = [];
    List<MethodDeclaration> methods = [];

    if (typeMirror case mirrors.ClassMirror classMirror) {
      for (final entry in classMirror.declarations.entries) {
        final declName = mirrors.MirrorSystem.getName(entry.key);
        final decl = entry.value;

        if (decl case mirrors.MethodMirror method) {
          if (method.isConstructor) {
            final ctorName = method.constructorName == Symbol('')
                ? ''
                : declName.replaceAll('$name.', '');
            constructors.add(
              _buildConstructorFromMirror(
                method,
                ctorName,
                name,
                library,
                sourceCode: sourceCode,
              ),
            );
          } else if (!method.isConstructor) {
            methods.add(
              _buildMethodFromMirror(
                method,
                declName,
                name,
                library,
                sourceCode: sourceCode,
              ),
            );
          }
        } else if (decl case mirrors.VariableMirror field) {
          fields.add(
            _buildFieldFromMirror(
              field,
              declName,
              name,
              library,
              sourceCode: sourceCode,
            ),
          );
        }
      }

      // Collect class annotations
      for (final meta in classMirror.metadata) {
        classAnnotations.add(_buildAnnotationFromMirror(meta, library));
      }
    }

    // Helper to build a qualified name from a TypeMirror
    String? qualifiedNameFor(mirrors.TypeMirror type) {
      try {
        final typeName = mirrors.MirrorSystem.getName(type.simpleName);
        final uri =
            type.location?.sourceUri.toString() ??
            type.owner?.location?.sourceUri.toString();
        if (uri == null) return null;
        return ReflectionUtils.buildQualifiedName(typeName, uri);
      } catch (_) {
        return null;
      }
    }

    // Extract superclass
    StandardLinkDeclaration? superClassDecl;
    if (typeMirror is mirrors.ClassMirror && typeMirror.superclass != null) {
      final sc = typeMirror.superclass!;
      final superName = mirrors.MirrorSystem.getName(sc.simpleName);
      final superQn = qualifiedNameFor(sc);
      superClassDecl = StandardLinkDeclaration(
        name: superName,
        type: Object,
        isPublic: true,
        isSynthetic: false,
        pointerType: Object,
        qualifiedName: superQn ?? superName,
      );
    }

    // Extract mixins
    final mixinLinks = <StandardLinkDeclaration>[];
    if (typeMirror is mirrors.ClassMirror) {
      final mixinNames = _extractMixins(typeMirror, sourceCode: sourceCode);
      for (final mixinName in mixinNames) {
        String qn = mixinName;
        try {
          final symbol = mirrors.MirrorSystem.getSymbol(mixinName);
          final cached = _mixinSymbolCache[symbol];
          if (cached != null) {
            qn = cached;
          } else {
            for (final lib in mirrors.currentMirrorSystem().libraries.values) {
              final decl = lib.declarations[symbol];
              if (decl != null && decl is mirrors.TypeMirror) {
                final resolved = qualifiedNameFor(decl);
                if (resolved != null) {
                  qn = resolved;
                  _mixinSymbolCache[symbol] = resolved;
                }
                break;
              }
            }
          }
        } catch (_) {}
        mixinLinks.add(
          StandardLinkDeclaration(
            name: mixinName,
            type: Object,
            isPublic: true,
            isSynthetic: false,
            pointerType: Object,
            qualifiedName: qn,
          ),
        );
      }
    }

    // Extract interfaces
    final interfaceLinks = <StandardLinkDeclaration>[];
    if (typeMirror is mirrors.ClassMirror) {
      for (final iface in typeMirror.superinterfaces) {
        final ifaceName = mirrors.MirrorSystem.getName(iface.simpleName);
        final ifaceQn = qualifiedNameFor(iface);
        interfaceLinks.add(
          StandardLinkDeclaration(
            name: ifaceName,
            type: Object,
            isPublic: true,
            isSynthetic: false,
            pointerType: Object,
            qualifiedName: ifaceQn ?? ifaceName,
          ),
        );
      }
    }

    final isPublic = !typeMirror.isPrivate;
    final isAbstract = typeMirror is mirrors.ClassMirror
        ? typeMirror.isAbstract
        : false;
    final isMixin = _isMixinClass(sourceCode, name, typeMirror);
    final isEnum = typeMirror is mirrors.ClassMirror
        ? typeMirror.isEnum
        : false;

    if (isEnum) {
      return StandardEnumDeclaration(
        name: name,
        type: Object,
        isPublic: isPublic,
        isSynthetic: false,
        library: library,
        constructors: constructors,
        fields: fields
            .where((f) => !(f.getIsStatic() && f.getType() == Object))
            .toList(),
        methods: methods,
        superClass: superClassDecl,
        interfaces: interfaceLinks,
        mixins: mixinLinks,
        annotations: classAnnotations,
        sourceLocation: Uri.parse('$actualUri:0'),
        isAbstract: false,
        qualifiedName: '$actualUri.$name',
        values: [],
      );
    }

    return StandardClassDeclaration(
      name: name,
      type: Object,
      isPublic: isPublic,
      isSynthetic: false,
      library: library,
      constructors: constructors,
      fields: fields,
      methods: methods,
      superClass: superClassDecl,
      interfaces: interfaceLinks,
      mixins: mixinLinks,
      annotations: classAnnotations,
      sourceLocation: Uri.parse('$actualUri:0'),
      isAbstract: isAbstract,
      isMixin: isMixin,
      isSealed: _isSealedClass(sourceCode, name),
      isBase: _isBaseClass(sourceCode, name),
      isInterface: _isInterfaceClass(sourceCode, name),
      isFinal: _isFinalClass(sourceCode, name),
      qualifiedName: '$actualUri.$name',
      isRecord: false,
      packageUri: actualUri,
      simpleName: name,
      kind: isMixin ? TypeKind.mixinType : TypeKind.classType,
    );
  }

  /// Builds a [ConstructorDeclaration] from a mirror [MethodMirror].
  ConstructorDeclaration _buildConstructorFromMirror(
    mirrors.MethodMirror method,
    String ctorName,
    String className,
    LibraryDeclaration library, {
    String? sourceCode,
  }) {
    final params = method.parameters.map((p) {
      return _buildParameterFromMirror(p, library, sourceCode: sourceCode);
    }).toList();

    return StandardConstructorDeclaration(
      name: ctorName,
      type: Object,
      isPublic: !method.isPrivate,
      isSynthetic: false,
      parentClass: StandardLinkDeclaration(
        name: className,
        type: Object,
        isPublic: true,
        isSynthetic: false,
        pointerType: Object,
        qualifiedName: className,
      ),
      parameters: params,
      annotations: const [],
      sourceLocation: null,
      isConst: method.isConstConstructor,
      isFactory: method.isFactoryConstructor,
    );
  }

  /// Builds a [MethodDeclaration] from a mirror [MethodMirror].
  MethodDeclaration _buildMethodFromMirror(
    mirrors.MethodMirror method,
    String methodName,
    String className,
    LibraryDeclaration library, {
    String? sourceCode,
  }) {
    final params = method.parameters.map((p) {
      return _buildParameterFromMirror(p, library, sourceCode: sourceCode);
    }).toList();

    bool returnIsNullable = false;
    if (sourceCode != null) {
      try {
        final returnPattern = RegExp(
          r'\b' +
              RegExp.escape(
                mirrors.MirrorSystem.getName(method.returnType.simpleName),
              ) +
              r'\?\s+' +
              RegExp.escape(methodName) +
              r'\b',
          multiLine: true,
        );
        returnIsNullable = returnPattern.hasMatch(sourceCode);
      } catch (_) {}
    }

    final returnTypeName = _resolveReturnTypeName(
      method,
      sourceCode: sourceCode,
    );

    return StandardMethodDeclaration(
      name: methodName,
      type: Object,
      returnType: StandardLinkDeclaration(
        name: returnTypeName,
        type: Object,
        isPublic: true,
        isSynthetic: false,
        pointerType: Object,
        qualifiedName: returnTypeName,
      ),
      parameters: params,
      annotations: method.metadata
          .map((m) => _buildAnnotationFromMirror(m, library))
          .toList(),
      isPublic: !method.isPrivate,
      isSynthetic: false,
      sourceLocation: null,
      isStatic: method.isStatic,
      isAbstract: method.isAbstract,
      isExternal: false,
      isGetter: method.isGetter,
      isSetter: method.isSetter,
      parentClass: StandardLinkDeclaration(
        name: className,
        type: Object,
        isPublic: true,
        isSynthetic: false,
        pointerType: Object,
        qualifiedName: className,
      ),
      hasNullableReturn: returnIsNullable,
    );
  }

  /// Builds a [FieldDeclaration] from a mirror [VariableMirror].
  FieldDeclaration _buildFieldFromMirror(
    mirrors.VariableMirror field,
    String fieldName,
    String className,
    LibraryDeclaration library, {
    String? sourceCode,
  }) {
    bool fieldIsLate = false;
    bool fieldIsNullable = false;
    if (sourceCode != null) {
      try {
        final latePattern = RegExp(
          r'\blate\s+[^;]*\b' + RegExp.escape(fieldName) + r'\b',
        );
        fieldIsLate = latePattern.hasMatch(sourceCode);
      } catch (_) {}
      try {
        final nullablePattern = RegExp(
          r'\b(?:late\s+)?(?:static\s+)?(?:final\s+|const\s+)?[A-Za-z_$][A-Za-z0-9_$<>\?,\s]*?\?\s+' +
              RegExp.escape(fieldName) +
              r'\b',
          multiLine: true,
        );
        fieldIsNullable = nullablePattern.hasMatch(sourceCode);
      } catch (_) {}
    }
    if (!fieldIsNullable) {
      try {
        final typeName = mirrors.MirrorSystem.getName(field.type.simpleName);
        fieldIsNullable = typeName.endsWith('?');
      } catch (_) {}
    }

    return StandardFieldDeclaration(
      name: fieldName,
      type: Object,
      parentClass: StandardLinkDeclaration(
        name: className,
        type: Object,
        isPublic: true,
        isSynthetic: false,
        pointerType: Object,
        qualifiedName: className,
      ),
      linkDeclaration: StandardLinkDeclaration(
        name: mirrors.MirrorSystem.getName(field.type.simpleName),
        type: Object,
        isPublic: true,
        isSynthetic: false,
        pointerType: Object,
        qualifiedName: mirrors.MirrorSystem.getName(field.type.simpleName),
      ),
      annotations: field.metadata
          .map((m) => _buildAnnotationFromMirror(m, library))
          .toList(),
      isPublic: !field.isPrivate,
      isSynthetic: false,
      sourceLocation: null,
      isStatic: field.isStatic,
      isLate: fieldIsLate,
      isConst: field.isConst,
      isFinal: field.isFinal,
      isNullable: fieldIsNullable,
    );
  }

  /// Builds a [ParameterDeclaration] from a mirror [ParameterMirror].
  ParameterDeclaration _buildParameterFromMirror(
    mirrors.ParameterMirror p,
    LibraryDeclaration library, {
    String? sourceCode,
  }) {
    final paramName = mirrors.MirrorSystem.getName(p.simpleName);
    bool paramIsNullable = false;
    bool paramIsRequired = !p.isOptional;
    bool paramIsOptional = p.isOptional;

    // Nullable detection using source code
    if (sourceCode != null) {
      try {
        final nullablePattern = RegExp(
          r'\b[A-Za-z_$][A-Za-z0-9_$<>\?,\s()\[\]]*?\?\s+(?:this\.)?' +
              RegExp.escape(paramName) +
              r'\b',
          multiLine: true,
        );
        paramIsNullable = nullablePattern.hasMatch(sourceCode);
      } catch (_) {}
      if (!paramIsNullable) {
        try {
          final fieldPattern = RegExp(
            r'\?\s+(?:this\.)?' + RegExp.escape(paramName) + r'\b',
            multiLine: true,
          );
          paramIsNullable = fieldPattern.hasMatch(sourceCode);
        } catch (_) {}
      }
    }

    // Mirror-based fallback
    if (!paramIsNullable) {
      try {
        final typeName = mirrors.MirrorSystem.getName(p.type.simpleName);
        paramIsNullable = typeName.endsWith('?');
      } catch (_) {}
    }

    // Required keyword detection for named parameters
    if (sourceCode != null && p.isNamed) {
      try {
        final requiredPattern = RegExp(
          r'\brequired\b[^\n]*\b' + RegExp.escape(paramName) + r'\b',
          multiLine: true,
        );
        if (requiredPattern.hasMatch(sourceCode)) {
          paramIsRequired = true;
          paramIsOptional = false;
        }
      } catch (_) {}
    }

    dynamic defaultValue;
    if (p.hasDefaultValue &&
        p.defaultValue != null &&
        p.defaultValue!.hasReflectee) {
      try {
        defaultValue = p.defaultValue!.reflectee;
      } catch (_) {}
    }

    final typeName = _resolveParameterTypeName(p, sourceCode: sourceCode);

    return StandardParameterDeclaration(
      name: paramName,
      type: Object,
      typeDeclaration: StandardLinkDeclaration(
        name: typeName,
        type: Object,
        isPublic: true,
        isSynthetic: false,
        pointerType: Object,
        qualifiedName: typeName,
      ),
      isNullable: paramIsNullable,
      isRequired: paramIsRequired,
      isOptional: paramIsOptional,
      isNamed: p.isNamed,
      hasDefaultValue: defaultValue != null,
      defaultValue: defaultValue,
      index: 0,
      isPublic: true,
      isSynthetic: false,
      sourceLocation: null,
      annotations: const [],
    );
  }

  /// Builds an [AnnotationDeclaration] from a mirror [InstanceMirror].
  AnnotationDeclaration _buildAnnotationFromMirror(
    mirrors.InstanceMirror meta,
    LibraryDeclaration library,
  ) {
    final annotationName = mirrors.MirrorSystem.getName(meta.type.simpleName);
    return StandardAnnotationDeclaration(
      linkDeclaration: StandardLinkDeclaration(
        name: annotationName,
        type: Object,
        isPublic: true,
        isSynthetic: false,
        pointerType: Object,
        qualifiedName: annotationName,
      ),
      instance: meta.hasReflectee ? meta.reflectee : null,
      isPublic: true,
      isSynthetic: false,
      name: annotationName,
      type: Object,
      fields: const {},
      userProvidedValues: const {},
    );
  }

  /// Reads the package name from pubspec.yaml in the given directory.
  Future<String> _readPackageName(Directory directory) async {
    try {
      final pubspecFile = File('${directory.path}/pubspec.yaml');
      final content = await pubspecFile.readAsString();
      final nameMatch = RegExp(r'name:\s*(\S+)').firstMatch(content);
      if (nameMatch != null && nameMatch.group(1) != null) {
        return nameMatch.group(1)!;
      }
    } catch (e) {
      RuntimeBuilder.logVerboseWarning(
        'Could not read package name from pubspec.yaml: $e',
      );
    }
    return 'unknown';
  }
}
