import 'dart:convert';
import 'dart:io';

import '../../helpers/equals_and_hash_code.dart';
import '../../runtime/declaration/declaration.dart';
import '../jetleaf_paths.dart';
import '../models.dart';
import '../serializer/cacheable_serializer.dart';

part '_cacheable_manager.dart';

/// {@template scan_cache_manager}
/// Manages the scan cache files inside `.jetleaf/`.
///
/// Two separate caches are maintained:
/// - `.jetleaf/cache_{hash}.bin` — production cache (skipTests: true)
/// - `.jetleaf/test/cache_{hash}.bin` — test cache (skipTests: false)
///
/// This separation ensures that `runScan()` and `runTestScan()` each get
/// their own cache without cross-contamination.
/// {@endtemplate}
abstract final class CacheableManager with EqualsAndHashCode {
  const CacheableManager._();

  /// Checks if a valid cache exists for [directory] with the given fingerprint.
  bool isValid(Directory directory, { String configFingerprint = 'default', bool forTests = false});

  /// Loads the cache from disk. Returns null if cache doesn't exist or is invalid.
  CacheDeserializationResult? load(Directory directory, { String configFingerprint = 'default', bool forTests = false});

  /// Saves the cache to disk.
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
  });

  /// Attempts to load any valid cache from the cache directory, regardless of fingerprint.
  CacheDeserializationResult? loadAny(Directory directory, {bool forTests = false});

  /// Deletes the cache file if it exists.
  Future<void> invalidate(Directory projectRoot, { String configFingerprint = 'default', bool forTests = false});

  /// Compares cached file entries against current filesystem state.
  CacheDiff diff(Directory directory, {bool forTests = false});

  /// Generates a configuration fingerprint from scanner configuration properties.
  String generateFingerprint({
    required bool skipTests,
    List<String> packagesToExclude = const [],
    List<String> packagesToScan = const [],
    bool enableTreeShaking = false,
  });

  @override
  List<Object?> equalizedProperties() => [];
}

/// Singleton instance of [CacheableManager].
final CacheableManager CacheManager = _CacheableManager._();