import '../helpers/equals_and_hash_code.dart';
import '../runtime/declaration/declaration.dart';

// ========================================================== CACHE ===================================================

/// Describes the difference between cached file state and the current
/// filesystem state. Used for incremental cache updates.
class CacheDiff with EqualsAndHashCode {
  /// Files whose mtimes match the cache (no re-scan needed).
  final List<String> unchanged;
  /// Files that exist in cache but have different mtimes (need re-scan).
  final List<String> modified;
  /// Files on disk but not in cache (need scanning).
  final List<String> added;
  /// Files in cache but no longer on disk (need removal from cache).
  final List<String> removed;

  const CacheDiff.internal({
    required this.unchanged,
    required this.modified,
    required this.added,
    required this.removed,
  });

  /// Empty diff — used when no cache exists.
  const CacheDiff.empty()
    : unchanged = const [],
      modified = const [],
      added = const [],
      removed = const [];

  /// Whether the cache is fully up-to-date with the filesystem.
  bool get isClean => modified.isEmpty && added.isEmpty && removed.isEmpty;

  /// Files that need re-scanning (modified + added).
  List<String> get filesToRescan => [...modified, ...added];

  /// Total number of changes.
  int get changeCount => modified.length + added.length + removed.length;

  @override
  List<Object?> equalizedProperties() => [unchanged, modified, added, removed];
}

/// Result of deserializing a cache file.
class CacheDeserializationResult with EqualsAndHashCode {
  final List<ClassDeclaration> components;
  final Map<String, int> fileEntries;
  final DateTime timestamp;
  final List<Asset> assets;
  final List<Package> packages;
  final List<IndexedLibraryMeta> libraries;
  final Map<String, List<String>> subclasses;
  final Map<String, List<Map<String, String>>> annotatedMethods;

  const CacheDeserializationResult({
    required this.components,
    required this.fileEntries,
    required this.timestamp,
    this.assets = const [],
    this.packages = const [],
    this.libraries = const [],
    this.subclasses = const {},
    this.annotatedMethods = const {},
  });

  @override
  List<Object?> equalizedProperties() => [
    components, fileEntries, timestamp, assets, packages,
    libraries, subclasses, annotatedMethods,
  ];
}

// =============================================== INDEXED LIBRARY META ==============================================

/// A lightweight representation of a library for cache metadata.
class IndexedLibraryMeta with EqualsAndHashCode {
  final String uri;
  final String packageName;
  final bool isSdk;

  const IndexedLibraryMeta({
    required this.uri,
    required this.packageName,
    this.isSdk = false,
  });

  @override
  List<Object?> equalizedProperties() => [uri, packageName, isSdk];
}
