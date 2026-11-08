import 'dart:async';
import 'dart:io';

import '../builder/runtime_builder.dart';
import '../file_utility/file_utility.dart';
import '../runtime/executor/aot/aot_runtime_executor.dart';
import '../runtime/hint/default_runtime_hint_descriptor.dart';
import '../runtime/provider/runtime_provider.dart';
import '../runtime/scanner/default_runtime_scanner_summary.dart';
import '../runtime/scanner/application_runtime_scanner.dart';
import '../runtime/scanner/runtime_scanner.dart';
import '../runtime/scanner/runtime_scanner_configuration.dart';
import '../runtime/scanner/runtime_scanner_summary.dart';
import 'manager/cacheable_manager.dart';
import 'models.dart';
import 'indexer/declaration_builder.dart';
import 'indexer/file_discovery.dart';
import 'scanner/cache_scanners.dart';

/// {@template cache_aware_scanner}
/// A pure Dart AOT caching decorator around [RuntimeScanner].
///
/// On cache hits, loads pre-indexed declarations from `.jetleaf/` without
/// re-analyzing source files.
/// On cache misses, uses [FileDiscovery] and [DeclarationBuilder] to analyze
/// source files via the analyzer AST and persist the result.
/// {@endtemplate}
class CacheAwareScanner implements RuntimeScanner {
  final RuntimeScanner _inner;
  final Directory? _source;
  final OnLogged? onInfo;
  final OnLogged? onWarning;
  final OnLogged? onError;

  Completer<RuntimeScannerSummary>? _scanInProgress;

  /// {@macro cache_aware_scanner}
  CacheAwareScanner({
    required RuntimeScanner inner,
    Directory? source,
    this.onInfo,
    this.onWarning,
    this.onError,
  })  : _inner = inner,
        _source = source;

  @override
  Future<RuntimeScannerSummary> scan(
    RuntimeScannerConfiguration configuration,
    List<String> args, {
    Directory? source,
  }) async {
    final effectiveSource = source ?? _source ?? Directory.current;
    final forTests = !configuration.skipTests;

    if (_scanInProgress != null) {
      RuntimeBuilder.logVerboseInfo(
        "Scan already in progress — waiting for existing scan to complete...",
      );
      return await _scanInProgress!.future;
    }

    _scanInProgress = Completer<RuntimeScannerSummary>();
    RuntimeScannerSummary? summary;

    try {
      final fingerprint = CacheManager.generateFingerprint(
        skipTests: !forTests,
      );

      // 1. Try loading from cache
      if (!configuration.reload &&
          CacheManager.isValid(
            effectiveSource,
            configFingerprint: fingerprint,
            forTests: forTests,
          )) {
        RuntimeBuilder.logVerboseInfo("Cache hit — loading declarations from cache...");
        final cached = CacheManager.load(
          effectiveSource,
          configFingerprint: fingerprint,
          forTests: forTests,
        );

        if (cached != null) {
          summary = await _loadFromCache(
            cached,
            effectiveSource,
            configuration,
            args,
            forTests: forTests,
          );
          return summary;
        }
      }

      if (configuration.buildMode == RuntimeBuildMode.strict) {
        throw StateError(
          'Jetleaf runtime cache is missing for the manifest. Run `jl build` again.',
        );
      }

      // 2. Cache miss — run AST builder (Zero Mirrors)
      RuntimeBuilder.logVerboseInfo("Building declarations via AST DeclarationBuilder (zero mirrors)...");
      try {
        final discovery = FileDiscovery(effectiveSource);
        final files = await discovery.discover(
          skipTests: !forTests,
          packagesToExclude: configuration.packagesToExclude,
          packagesToScan: configuration.packagesToScan,
          filesToExclude: configuration.filesToExclude,
        );
        final packageName = await _readPackageName(effectiveSource);
        final declarationBuilder = DeclarationBuilder();
        final components = await declarationBuilder.build(
          files: files,
          packageName: packageName,
        );

        final cacheWriter = CacheWriter(effectiveSource);
        await cacheWriter.writeWithComponents(
          components: components,
          fingerprint: fingerprint,
          forTests: forTests,
        );

        final freshCache = CacheManager.load(
          effectiveSource,
          configFingerprint: fingerprint,
          forTests: forTests,
        );
        if (freshCache != null) {
          summary = await _loadFromCache(
            freshCache,
            effectiveSource,
            configuration,
            args,
            forTests: forTests,
          );
          return summary;
        }
      } catch (e) {
        RuntimeBuilder.logVerboseWarning("AST DeclarationBuilder fallback failed: $e. Falling back to inner scanner...");
      }

      // 3. Fallback: delegate to inner scanner
      RuntimeBuilder.logVerboseInfo("Delegating to inner scanner...");
      summary = await _inner.scan(configuration, args, source: source);

      // 4. Save cache if inner scanner has declarations
      if (_inner case ApplicationRuntimeScanner appScanner) {
        final decls = appScanner.getLastDeclarations();
        if (decls.isNotEmpty) {
          final cacheWriter = CacheWriter(effectiveSource);
          await cacheWriter.writeWithComponents(
            components: decls,
            fingerprint: fingerprint,
            forTests: forTests,
          );
        }
      }

      return summary;
    } finally {
      if (!_scanInProgress!.isCompleted) {
        if (summary != null) {
          _scanInProgress!.complete(summary);
        } else {
          _scanInProgress!.completeError(StateError('Scan did not produce a summary'));
        }
      }
      _scanInProgress = null;
    }
  }

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

    registerCachedDeclarations(cacheResult.components);

    final fileUtils = FileUtility(
      RuntimeBuilder.logInfo,
      RuntimeBuilder.logWarning,
      RuntimeBuilder.logError,
      configuration,
      configuration.tryOutsideIsolate ?? (file, uri) => true,
    );
    final packageName = await _readPackageName(directory);

    if (cacheResult.packages.isNotEmpty) {
      addRuntimePackages(cacheResult.packages, replace: true);
    } else {
      final packages = await fileUtils.readPackageGraphDependencies(directory);
      if (packages.isNotEmpty) {
        addRuntimePackages(packages, replace: true);
      }
    }

    if (cacheResult.assets.isNotEmpty) {
      addRuntimeAssets(cacheResult.assets, replace: true);
    } else {
      final resources = await fileUtils.discoverAllResources(packageName);
      if (resources.isNotEmpty) {
        addRuntimeAssets(resources, replace: true);
      }
    }

    freezeRuntimeLibrary();

    setRuntimeResolver(AotRuntimeExecutor(DefaultRuntimeHintDescriptor()));

    final summary = DefaultRuntimeScannerSummary();
    summary.setBuildTime(DateTime.now());
    summary.addInfos(RuntimeBuilder.onCompleted().getInfos());
    summary.addWarnings(RuntimeBuilder.onCompleted().getWarnings());
    summary.addErrors(RuntimeBuilder.onCompleted().getErrors());
    summary.addAll(RuntimeBuilder.onCompleted().getLogs());
    RuntimeBuilder.clearTrackedLogs();

    return summary;
  }

  Future<String> _readPackageName(Directory directory) async {
    final pubspec = File('${directory.path}/pubspec.yaml');
    if (pubspec.existsSync()) {
      final lines = await pubspec.readAsLines();
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('name:')) {
          return trimmed.substring(5).trim();
        }
      }
    }
    return 'unknown';
  }
}