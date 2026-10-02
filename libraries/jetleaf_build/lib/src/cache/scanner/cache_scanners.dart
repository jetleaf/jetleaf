import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import '../../runtime/declaration/declaration.dart';
import '../jetleaf_paths.dart';
import '../models.dart';
import '../serializer/cacheable_serializer.dart';
import '../../serialization/jetleaf_json.dart';
import 'cache_models.dart';

// ======================================================== CACHE SUMMARY ===================================================

/// Summary of what the cache writer discovered and wrote to disk.
final class CacheSummary {
  /// The components (class declarations) written to cache.
  final List<ClassDeclaration> components;

  /// The packages discovered.
  final List<Package> packages;

  /// The assets discovered.
  final List<Asset> assets;

  /// The fingerprint used for this cache.
  final String fingerprint;

  /// The subclass graph.
  final List<SubClassEntry> subClassEntries;

  /// The annotated method entries.
  final List<AnnotatedMethodEntry> annotatedMethodEntries;

  /// The runtime hint entries.
  final List<RuntimeHintEntry> runtimeHintEntries;

  /// The library metadata entries.
  final List<IndexedLibraryMeta> libraryMetas;

  const CacheSummary({
    required this.components,
    required this.packages,
    required this.assets,
    required this.fingerprint,
    this.subClassEntries = const [],
    this.annotatedMethodEntries = const [],
    this.runtimeHintEntries = const [],
    this.libraryMetas = const [],
  });
}

// ===================================================== CACHEABLE WRITER ===================================================

/// Abstract base class for all cache writers.
///
/// Each scanner in the hierarchy has two responsibilities:
/// 1. Prepare data for caching (write path)
/// 2. Load cached data into usable form (read path)
abstract final class CacheableWriter {
  /// The project root directory.
  final Directory projectRoot;

  const CacheableWriter(this.projectRoot);

  /// Writes all cache data to disk and returns a summary.
  Future<CacheSummary> write({
    required String fingerprint,
    bool forTests = false,
  });

  /// Writes components to binary cache and returns the full summary.
  Future<CacheSummary> writeWithComponents({
    required List<ClassDeclaration> components,
    required String fingerprint,
    bool forTests = false,
  });
}

// ==================================================== ASSET SCANNER =======================================================

/// Scans and caches asset metadata.
final class _AssetScanner extends CacheableWriter {
  const _AssetScanner(super.projectRoot);

  /// Prepares assets for caching by scanning the filesystem.
  Future<List<Asset>> prepareAssets({
    required String packageName,
    bool skipTests = false,
  }) async {
    final assets = <Asset>[];
    final dirs = [
      Directory('${projectRoot.path}/lib'),
      Directory('${projectRoot.path}/bin'),
    ];

    if (!skipTests) {
      dirs.add(Directory('${projectRoot.path}/test'));
    }

    for (final dir in dirs) {
      if (!dir.existsSync()) continue;

      await for (final entity in dir.list(recursive: true)) {
        if (entity is! File) continue;
        if (_isDartFile(entity.path)) continue;
        if (!_isAssetFile(entity.path)) continue;

        assets.add(
          MaterialAsset(
            filePath: entity.path,
            fileName: entity.uri.pathSegments.last,
            packageName: packageName,
            contentBytes: Uint8List(0), // Content not needed for cache metadata
          ),
        );
      }
    }

    return assets;
  }

  /// Loads cached assets from the JSON file.
  Future<List<Asset>> loadAssets({bool forTests = false}) async {
    final file = JetleafPaths.assetsJson(projectRoot, forTests: forTests);
    if (!file.existsSync()) return [];

    try {
      final content = await file.readAsString();
      final List<dynamic> data = jsonDecode(content);
      return data
          .map(
            (e) => MaterialAsset(
              filePath: e['filePath'] as String,
              fileName: e['fileName'] as String,
              packageName: e['packageName'] as String,
              contentBytes: Uint8List(
                0,
              ), // Content not needed for cache metadata
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  bool _isDartFile(String path) => path.endsWith('.dart');

  bool _isAssetFile(String path) {
    const extensions = [
      'json',
      'yaml',
      'yml',
      'properties',
      'env',
      'png',
      'jpg',
      'jpeg',
      'gif',
      'svg',
      'ico',
      'woff',
      'woff2',
      'ttf',
      'eot',
      'xml',
      'txt',
      'csv',
    ];
    return extensions.any((ext) => path.endsWith('.$ext'));
  }

  @override
  Future<CacheSummary> write({
    required String fingerprint,
    bool forTests = false,
  }) {
    throw UnsupportedError('Use _CacheableWriter.write() instead');
  }

  @override
  Future<CacheSummary> writeWithComponents({
    required List<ClassDeclaration> components,
    required String fingerprint,
    bool forTests = false,
  }) {
    throw UnsupportedError(
      'Use _CacheableWriter.writeWithComponents() instead',
    );
  }
}

// ==================================================== PACKAGE SCANNER =====================================================

/// Scans and caches package metadata.
final class _PackageScanner extends _AssetScanner {
  const _PackageScanner(super.projectRoot);

  /// Prepares packages for caching by reading pubspec.yaml and package_config.json.
  Future<List<Package>> preparePackages() async {
    final packages = <Package>[];

    // Read root package
    final pubspecFile = File('${projectRoot.path}/pubspec.yaml');
    if (pubspecFile.existsSync()) {
      final content = pubspecFile.readAsStringSync();
      final name = _extractPackageName(content);
      final version = _extractPackageVersion(content);

      // Read package_config.json for dependency info
      final packageConfigFile = File(
        '${projectRoot.path}/.dart_tool/package_config.json',
      );
      final dependencies = <String>[];
      final devDependencies = <String>[];

      if (packageConfigFile.existsSync()) {
        try {
          final configContent = packageConfigFile.readAsStringSync();
          final config = jsonDecode(configContent) as Map<String, dynamic>;
          final packagesList = config['packages'] as List<dynamic>? ?? [];

          for (final pkg in packagesList) {
            final pkgMap = pkg as Map<String, dynamic>;
            final pkgName = pkgMap['name'] as String;
            if (pkgName != name && !pkgName.startsWith('dart:')) {
              dependencies.add(pkgName);
            }
          }
        } catch (_) {}
      }

      packages.add(
        MaterialPackage(
          name: name,
          version: version,
          isRootPackage: true,
          filePath: pubspecFile.path,
          rootUri: Uri.parse('package:$name/').toString(),
          dependencies: dependencies,
          devDependencies: devDependencies,
          jetleafDependencies: dependencies
              .where((d) => d.startsWith('jetleaf'))
              .toList(),
        ),
      );
    }

    return packages;
  }

  /// Loads cached packages from the JSON file.
  Future<List<Package>> loadPackages({bool forTests = false}) async {
    final file = JetleafPaths.packagesJson(projectRoot, forTests: forTests);
    if (!file.existsSync()) return [];

    try {
      final content = await file.readAsString();
      final List<dynamic> data = jsonDecode(content);
      return data
          .map(
            (e) => MaterialPackage(
              name: e['name'] as String,
              version: e['version'] as String,
              isRootPackage: e['isRootPackage'] as bool? ?? false,
              filePath: e['filePath'] as String?,
              rootUri: e['rootUri'] as String?,
              dependencies: (e['dependencies'] as List<dynamic>? ?? [])
                  .cast<String>(),
              devDependencies: (e['devDependencies'] as List<dynamic>? ?? [])
                  .cast<String>(),
              jetleafDependencies:
                  (e['jetleafDependencies'] as List<dynamic>? ?? [])
                      .cast<String>(),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  String _extractPackageName(String content) {
    for (final line in content.split('\n')) {
      if (line.trimLeft().startsWith('name:')) {
        return line.split(':').last.trim();
      }
    }
    return 'unknown';
  }

  String _extractPackageVersion(String content) {
    for (final line in content.split('\n')) {
      if (line.trimLeft().startsWith('version:')) {
        return line.split(':').last.trim();
      }
    }
    return '0.0.0';
  }
}

// ==================================================== SUBCLASS SCANNER ====================================================

/// Computes and caches the subclass graph from class declarations.
final class _SubClassScanner extends _PackageScanner {
  const _SubClassScanner(super.projectRoot);

  /// Prepares subclass entries by computing the graph from declarations.
  List<SubClassEntry> prepareSubClasses(List<ClassDeclaration> components) {
    final graph = <String, List<String>>{};

    for (final decl in components) {
      final superLink = decl.getSuperClass();
      if (superLink != null) {
        final superQn = superLink.getPointerQualifiedName();
        graph.putIfAbsent(superQn, () => []).add(decl.getQualifiedName());
      }

      for (final iface in decl.getInterfaces()) {
        graph
            .putIfAbsent(iface.getPointerQualifiedName(), () => [])
            .add(decl.getQualifiedName());
      }

      for (final mixin in decl.getMixins()) {
        graph
            .putIfAbsent(mixin.getPointerQualifiedName(), () => [])
            .add(decl.getQualifiedName());
      }
    }

    return graph.entries
        .map(
          (e) => SubClassEntry(
            parentQualifiedName: e.key,
            childQualifiedNames: e.value,
          ),
        )
        .toList();
  }

  /// Loads cached subclass entries from the JSON file.
  Future<List<SubClassEntry>> loadSubClasses({bool forTests = false}) async {
    final file = JetleafPaths.subclassesJson(projectRoot, forTests: forTests);
    if (!file.existsSync()) return [];

    try {
      final content = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(content);
      return data.entries
          .map(
            (e) => SubClassEntry(
              parentQualifiedName: e.key,
              childQualifiedNames: (e.value as List<dynamic>).cast<String>(),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }
}

// ================================================== ANNOTATED METHOD SCANNER ==============================================

/// Computes and caches the annotated method index from class declarations.
final class _AnnotatedMethodScanner extends _SubClassScanner {
  const _AnnotatedMethodScanner(super.projectRoot);

  /// Prepares annotated method entries by scanning declarations.
  List<AnnotatedMethodEntry> prepareAnnotatedMethods(
    List<ClassDeclaration> components,
  ) {
    final entries = <AnnotatedMethodEntry>[];

    for (final decl in components) {
      for (final method in decl.getMethods()) {
        for (final annotation in method.getAnnotations()) {
          entries.add(
            AnnotatedMethodEntry(
              annotationName: annotation.getName(),
              className: decl.getName(),
              methodName: method.getName(),
              uri: decl.getLibrary().getUri(),
            ),
          );
        }
      }
    }

    return entries;
  }

  /// Loads cached annotated method entries from the JSON file.
  Future<List<AnnotatedMethodEntry>> loadAnnotatedMethods({
    bool forTests = false,
  }) async {
    final file = JetleafPaths.annotatedMethodsJson(
      projectRoot,
      forTests: forTests,
    );
    if (!file.existsSync()) return [];

    try {
      final content = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(content);
      final entries = <AnnotatedMethodEntry>[];

      for (final annotationEntry in data.entries) {
        final annotationName = annotationEntry.key;
        final methods = annotationEntry.value as List<dynamic>;

        for (final method in methods) {
          final methodMap = method as Map<String, dynamic>;
          entries.add(
            AnnotatedMethodEntry(
              annotationName: annotationName,
              className: methodMap['class'] as String? ?? '',
              methodName: methodMap['method'] as String? ?? '',
              uri: methodMap['uri'] as String? ?? '',
            ),
          );
        }
      }

      return entries;
    } catch (_) {
      return [];
    }
  }
}

// ==================================================== RUNTIME HINT SCANNER ================================================

/// Detects and caches RuntimeHint implementations from class declarations.
final class _RuntimeHintScanner extends _AnnotatedMethodScanner {
  const _RuntimeHintScanner(super.projectRoot);

  /// Prepares runtime hint entries by scanning declarations.
  List<RuntimeHintEntry> prepareRuntimeHints(
    List<ClassDeclaration> components,
  ) {
    final hints = <RuntimeHintEntry>[];

    for (final decl in components) {
      final superName = decl.getSuperClass()?.getName();
      if (superName == 'RuntimeHint' || superName == 'RuntimeHintProvider') {
        hints.add(
          RuntimeHintEntry(
            qualifiedName: decl.getQualifiedName(),
            name: decl.getName(),
            type: superName == 'RuntimeHintProvider' ? 'provider' : 'direct',
          ),
        );
      }
    }

    return hints;
  }

  /// Loads cached runtime hint entries from the JSON file.
  Future<List<RuntimeHintEntry>> loadRuntimeHints({
    bool forTests = false,
  }) async {
    final file = JetleafPaths.hintRegistryJson(projectRoot, forTests: forTests);
    if (!file.existsSync()) return [];

    try {
      final content = await file.readAsString();
      final List<dynamic> data = jsonDecode(content);
      return data
          .map((e) => RuntimeHintEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

// ===================================================== CACHE WRITER ======================================================

/// Writes all cache data to disk.
///
/// This is the final writer in the scanner hierarchy. It orchestrates
/// writing all metadata files (binary cache, JSON indexes) using the
/// data prepared by the scanner chain.
final class _CacheableWriter extends _RuntimeHintScanner {
  const _CacheableWriter(super.projectRoot);

  @override
  Future<CacheSummary> write({
    required String fingerprint,
    bool forTests = false,
  }) async {
    // Ensure cache directory exists
    final cacheDir = JetleafPaths.cacheDir(projectRoot, forTests: forTests);
    if (!cacheDir.existsSync()) {
      await cacheDir.create(recursive: true);
    }

    // Prepare all data
    final packages = await preparePackages();
    final assets = await prepareAssets(
      packageName: packages.firstOrNull?.getName() ?? 'unknown',
    );
    final subClassEntries = prepareSubClasses(
      [],
    ); // Components will be passed in
    final annotatedMethodEntries = prepareAnnotatedMethods(
      [],
    ); // Components will be passed in
    final runtimeHintEntries = prepareRuntimeHints(
      [],
    ); // Components will be passed in

    // Write JSON indexes
    await _writeSubClassesJson(subClassEntries, forTests);
    await _writeAnnotatedMethodsJson(annotatedMethodEntries, forTests);
    await _writeRuntimeHintsJson(runtimeHintEntries, forTests);
    await _writePackagesJson(packages, forTests);
    await _writeAssetsJson(assets, forTests);

    // Return summary (components will be added by the caller)
    return CacheSummary(
      components: [], // Will be populated by the caller
      packages: packages,
      assets: assets,
      fingerprint: fingerprint,
      subClassEntries: subClassEntries,
      annotatedMethodEntries: annotatedMethodEntries,
      runtimeHintEntries: runtimeHintEntries,
    );
  }

  @override
  Future<CacheSummary> writeWithComponents({
    required List<ClassDeclaration> components,
    required String fingerprint,
    bool forTests = false,
  }) async {
    // Ensure cache directory exists
    final cacheDir = JetleafPaths.cacheDir(projectRoot, forTests: forTests);
    if (!cacheDir.existsSync()) {
      await cacheDir.create(recursive: true);
    }

    // Prepare all data
    final packages = await preparePackages();
    final assets = await prepareAssets(
      packageName: packages.firstOrNull?.getName() ?? 'unknown',
    );
    final subClassEntries = prepareSubClasses(components);
    final annotatedMethodEntries = prepareAnnotatedMethods(components);
    final runtimeHintEntries = prepareRuntimeHints(components);

    // Write binary cache
    await _writeBinaryCache(
      components,
      packages,
      assets,
      fingerprint,
      forTests,
    );
    await JetleafPaths.fingerprintFile(
      projectRoot,
      forTests: forTests,
    ).writeAsString('$fingerprint\n', flush: true);

    // Write JSON indexes
    await _writeSubClassesJson(subClassEntries, forTests);
    await _writeAnnotatedMethodsJson(annotatedMethodEntries, forTests);
    await _writeRuntimeHintsJson(runtimeHintEntries, forTests);
    await _writePackagesJson(packages, forTests);
    await _writeAssetsJson(assets, forTests);

    return CacheSummary(
      components: components,
      packages: packages,
      assets: assets,
      fingerprint: fingerprint,
      subClassEntries: subClassEntries,
      annotatedMethodEntries: annotatedMethodEntries,
      runtimeHintEntries: runtimeHintEntries,
    );
  }

  Future<void> _writeBinaryCache(
    List<ClassDeclaration> components,
    List<Package> packages,
    List<Asset> assets,
    String fingerprint,
    bool forTests,
  ) async {
    final cacheFile = JetleafPaths.cacheFile(
      projectRoot,
      fingerprint,
      forTests: forTests,
    );
    final data = CacheSerializer.serialize(
      components,
      {}, // fileEntries not needed for new cache format
      packages: packages,
      assets: assets,
    );
    await cacheFile.writeAsBytes(data);
  }

  Future<void> _writeSubClassesJson(
    List<SubClassEntry> entries,
    bool forTests,
  ) async {
    final file = JetleafPaths.subclassesJson(projectRoot, forTests: forTests);
    final map = <String, List<String>>{};
    for (final entry in entries) {
      map[entry.parentQualifiedName] = entry.childQualifiedNames;
    }
    await file.writeAsString(JetleafJson.encode(map));
  }

  Future<void> _writeAnnotatedMethodsJson(
    List<AnnotatedMethodEntry> entries,
    bool forTests,
  ) async {
    final file = JetleafPaths.annotatedMethodsJson(
      projectRoot,
      forTests: forTests,
    );
    final map = <String, List<Map<String, String>>>{};
    for (final entry in entries) {
      map.putIfAbsent(entry.annotationName, () => []);
      map[entry.annotationName]!.add({
        'class': entry.className,
        'method': entry.methodName,
        'uri': entry.uri,
      });
    }
    await file.writeAsString(JetleafJson.encode(map));
  }

  Future<void> _writeRuntimeHintsJson(
    List<RuntimeHintEntry> entries,
    bool forTests,
  ) async {
    final file = JetleafPaths.hintRegistryJson(projectRoot, forTests: forTests);
    await file.writeAsString(JetleafJson.encode(entries.map((e) => e.toJson()).toList()));
  }

  Future<void> _writePackagesJson(List<Package> packages, bool forTests) async {
    final file = JetleafPaths.packagesJson(projectRoot, forTests: forTests);
    await file.writeAsString(
      JetleafJson.encode(
        packages
            .map(
              (p) => {
                'name': p.getName(),
                'version': p.getVersion(),
                'isRootPackage': p.getIsRootPackage(),
                'filePath': p.getFilePath(),
                'rootUri': p.getRootUri(),
                'dependencies': p.getDependencies().toList(),
                'devDependencies': p.getDevDependencies().toList(),
                'jetleafDependencies': p.getJetleafDependencies().toList(),
              },
            )
            .toList(),
      ),
    );
  }

  Future<void> _writeAssetsJson(List<Asset> assets, bool forTests) async {
    final file = JetleafPaths.assetsJson(projectRoot, forTests: forTests);
    await file.writeAsString(
      JetleafJson.encode(
        assets
            .map(
              (a) => {
                'filePath': a.getFilePath(),
                'fileName': a.getFileName(),
                'packageName': a.getPackageName(),
              },
            )
            .toList(),
      ),
    );
  }
}

/// Factory function to create a [_CacheableWriter].
CacheableWriter CacheWriter(Directory projectRoot) =>
    _CacheableWriter(projectRoot);

// ===================================================== CACHE READER =======================================================

/// Reads all cache data from disk.
///
/// This class mirrors the writer hierarchy but for the read path.
/// It loads all cached metadata and converts it into usable forms.
final class CacheableReader extends _RuntimeHintScanner {
  const CacheableReader(super.projectRoot);

  /// Reads all cached data and returns a [CacheReadResult].
  Future<CacheReadResult?> readAll({bool forTests = false}) async {
    // Check if binary cache exists
    final fingerprintFile = JetleafPaths.fingerprintFile(
      projectRoot,
      forTests: forTests,
    );
    if (!fingerprintFile.existsSync()) return null;

    try {
      final fingerprint = await fingerprintFile.readAsString();

      // Load all cached data
      final packages = await loadPackages(forTests: forTests);
      final assets = await loadAssets(forTests: forTests);
      final subClassEntries = await loadSubClasses(forTests: forTests);
      final annotatedMethodEntries = await loadAnnotatedMethods(
        forTests: forTests,
      );
      final runtimeHintEntries = await loadRuntimeHints(forTests: forTests);

      return CacheReadResult(
        fingerprint: fingerprint.trim(),
        packages: packages,
        assets: assets,
        subClassEntries: subClassEntries,
        annotatedMethodEntries: annotatedMethodEntries,
        runtimeHintEntries: runtimeHintEntries,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Result of reading cached data.
final class CacheReadResult {
  final String fingerprint;
  final List<Package> packages;
  final List<Asset> assets;
  final List<SubClassEntry> subClassEntries;
  final List<AnnotatedMethodEntry> annotatedMethodEntries;
  final List<RuntimeHintEntry> runtimeHintEntries;

  const CacheReadResult({
    required this.fingerprint,
    required this.packages,
    required this.assets,
    required this.subClassEntries,
    required this.annotatedMethodEntries,
    required this.runtimeHintEntries,
  });
}
