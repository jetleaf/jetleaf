part of 'cacheable_manager.dart';

/// {@template scan_cache_manager_impl}
/// Private implementation of [CacheableManager].
/// {@endtemplate}
final class _CacheableManager extends CacheableManager {
  static const String _cacheFilePrefix = 'cache';
  static const String _cacheFileSuffix = '.bin';

  const _CacheableManager._() : super._();

  Directory _cacheDir(Directory directory, {bool forTests = false}) => forTests
    ? JetleafPaths.testDir(directory)
    : JetleafPaths.dir(directory);

  File _cacheFile(Directory directory, {String configFingerprint = 'default', bool forTests = false}) {
    return File('${_cacheDir(directory, forTests: forTests).path}/${_cacheFilePrefix}_$configFingerprint$_cacheFileSuffix');
  }

  @override
  bool isValid(Directory directory, { String configFingerprint = 'default', bool forTests = false }) {
    final file = _cacheFile(directory, configFingerprint: configFingerprint, forTests: forTests);
    if (!file.existsSync()) return false;
    
    try {
      final data = file.readAsBytesSync();
      final result = CacheSerializer.deserialize(data);
      return _validateFileEntries(result.fileEntries, directory.path);
    } catch (e) {
      return false;
    }
  }

  @override
  CacheDeserializationResult? load(Directory directory, { String configFingerprint = 'default', bool forTests = false}) {
    final file = _cacheFile(directory, configFingerprint: configFingerprint, forTests: forTests);
    if (!file.existsSync()) return null;
    try {
      final data = file.readAsBytesSync();
      final result = CacheSerializer.deserialize(data);
      if (!_validateFileEntries(result.fileEntries, directory.path)) {
        return null;
      }
      return result;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> save(
    List<ClassDeclaration> components,
    Directory projectRoot, {
    String configFingerprint = 'default',
    bool forTests = false,
    List<Asset> assets = const [],
    List<Package> packages = const [],
    List<IndexedLibraryMeta> libraries = const [],
    Map<String, List<String>> subclasses = const {},
    Map<String, List<Map<String, String>>> annotatedMethods = const {},
  }) async {
    final dir = _cacheDir(projectRoot, forTests: forTests);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    final fileEntries = _collectFileEntries(projectRoot, forTests: forTests);
    final data = CacheSerializer.serialize(
      components, fileEntries,
      assets: assets,
      packages: packages,
      libraries: libraries,
      subclasses: subclasses,
      annotatedMethods: annotatedMethods,
    );
    final cacheFile = _cacheFile(projectRoot, configFingerprint: configFingerprint, forTests: forTests);
    await cacheFile.writeAsBytes(data, flush: true);
  }

  @override
  CacheDeserializationResult? loadAny(Directory directory, {bool forTests = false}) {
    final dir = _cacheDir(directory, forTests: forTests);
    if (!dir.existsSync()) return null;

    final candidates = <(int size, File file)>[];
    for (final entity in dir.listSync()) {
      if (entity is File &&
          entity.path.contains('/${_cacheFilePrefix}_') &&
          entity.path.endsWith(_cacheFileSuffix)) {
        candidates.add((entity.lengthSync(), entity));
      }
    }

    candidates.sort((a, b) => b.$1.compareTo(a.$1));
    for (final (_, file) in candidates) {
      try {
        final data = file.readAsBytesSync();
        final result = CacheSerializer.deserialize(data);
        if (_validateFileEntries(result.fileEntries, directory.path)) {
          return result;
        }
      } catch (_) {}
    }

    return null;
  }

  @override
  Future<void> invalidate(
    Directory projectRoot, {
    String configFingerprint = 'default',
    bool forTests = false,
  }) async {
    final file = _cacheFile(projectRoot, configFingerprint: configFingerprint, forTests: forTests);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  @override
  CacheDiff diff(Directory directory, {bool forTests = false}) {
    final dir = _cacheDir(directory, forTests: forTests);
    if (!dir.existsSync()) return CacheDiff.empty();

    Map<String, int> cachedEntries = {};
    for (final entity in dir.listSync()) {
      if (entity is File &&
          entity.path.contains('/${_cacheFilePrefix}_') &&
          entity.path.endsWith(_cacheFileSuffix)) {
        try {
          final data = entity.readAsBytesSync();
          final result = CacheSerializer.deserialize(data);
          cachedEntries = result.fileEntries;
          break;
        } catch (_) {}
      }
    }

    if (cachedEntries.isEmpty) return CacheDiff.empty();

    final currentEntries = _collectFileEntries(directory, forTests: forTests);
    final unchanged = <String>[];
    final modified = <String>[];
    final removed = <String>[];
    final added = <String>[];

    for (final entry in cachedEntries.entries) {
      final currentMtime = currentEntries[entry.key];
      if (currentMtime == null) {
        removed.add(entry.key);
      } else if ((currentMtime - entry.value).abs() > 1000) {
        modified.add(entry.key);
      } else {
        unchanged.add(entry.key);
      }
    }

    for (final entry in currentEntries.entries) {
      if (!cachedEntries.containsKey(entry.key)) {
        added.add(entry.key);
      }
    }

    return CacheDiff.internal(
      unchanged: unchanged,
      modified: modified,
      added: added,
      removed: removed,
    );
  }

  @override
  String generateFingerprint({
    required bool skipTests,
    List<String> packagesToExclude = const [],
    List<String> packagesToScan = const [],
    bool enableTreeShaking = false,
  }) {
    final sortedExclude = List<String>.from(packagesToExclude)..sort();
    final sortedScan = List<String>.from(packagesToScan)..sort();
    final config = {
      'skipTests': skipTests,
      'packagesToExclude': sortedExclude,
      'packagesToScan': sortedScan,
      'enableTreeShaking': enableTreeShaking,
    };
    final json = jsonEncode(config);
    return _shortHash(json);
  }

  // ── Private helpers ──────────────────────────────────────────────────

  Map<String, int> _collectFileEntries(Directory projectRoot, {bool forTests = false}) {
    final entries = <String, int>{};
    final scanDirs = forTests ? ['lib', 'bin', 'test'] : ['lib', 'bin'];
    for (final dirName in scanDirs) {
      final dir = Directory('${projectRoot.path}/$dirName');
      if (!dir.existsSync()) continue;
      _scanDirectory(dir, entries, projectRoot.path);
    }
    return entries;
  }

  void _scanDirectory(Directory dir, Map<String, int> entries, String rootPath) {
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final relativePath = entity.path.substring(rootPath.length + 1);
        entries[relativePath] = entity.statSync().modified.millisecondsSinceEpoch;
      }
    }
  }

  bool _validateFileEntries(Map<String, int> cachedEntries, [String? rootPath]) {
    for (final entry in cachedEntries.entries) {
      final path = rootPath != null ? '$rootPath/${entry.key}' : entry.key;
      final file = File(path);
      if (!file.existsSync()) return false;
      final currentMtime = file.statSync().modified.millisecondsSinceEpoch;
      // Allow 1 second tolerance for mtime differences (filesystem granularity,
      // editor saves, IDE indexing, etc.)
      if ((currentMtime - entry.value).abs() > 1000) return false;
    }
    return true;
  }

  String _shortHash(String input) {
    int hash = 5381;
    for (var i = 0; i < input.length; i++) {
      hash = ((hash << 5) + hash) ^ input.codeUnitAt(i);
    }
    return (hash & 0x7FFFFFFF).toRadixString(16).padLeft(8, '0');
  }
}