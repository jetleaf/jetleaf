import 'dart:io';

/// Centralized path construction for the `.jetleaf/` cache directory.
///
/// All path logic lives here so a single constant change propagates everywhere.
abstract final class JetleafPaths {
  JetleafPaths._();

  /// The cache directory name (without leading separator).
  static const String dirName = '.jetleaf';

  /// The test subdirectory name within `.jetleaf/`.
  static const String testDirName = 'test';

  // ── Directory paths ────────────────────────────────────────────────

  /// Returns the `.jetleaf/` directory for [projectRoot].
  static Directory dir(Directory projectRoot) => Directory('${projectRoot.path}/$dirName');

  /// Returns the `.jetleaf/test/` directory for [projectRoot].
  static Directory testDir(Directory projectRoot) => Directory('${projectRoot.path}/$dirName/$testDirName');

  /// Returns the production or test cache directory based on [forTests].
  static Directory cacheDir(Directory projectRoot, {bool forTests = false}) => forTests ? testDir(projectRoot) : dir(projectRoot);

  // ── Cache file paths ───────────────────────────────────────────────
  
  /// `.jetleaf/cache_{fingerprint}.bin` or `.jetleaf/test/cache_{fingerprint}.bin`
  static File cacheFile(Directory projectRoot, String fingerprint, {bool forTests = false}) =>
      File('${cacheDir(projectRoot, forTests: forTests).path}/cache_$fingerprint.bin');

  /// `.jetleaf/fingerprint.txt` or `.jetleaf/test/fingerprint.txt`
  static File fingerprintFile(Directory projectRoot, {bool forTests = false}) =>
      File('${cacheDir(projectRoot, forTests: forTests).path}/fingerprint.txt');

  // ── JSON metadata files ────────────────────────────────────────────

  /// `.jetleaf/packages.json` or `.jetleaf/test/packages.json`
  static File packagesJson(Directory projectRoot, {bool forTests = false}) =>
      File('${cacheDir(projectRoot, forTests: forTests).path}/packages.json');

  /// `.jetleaf/assets.json` or `.jetleaf/test/assets.json`
  static File assetsJson(Directory projectRoot, {bool forTests = false}) =>
      File('${cacheDir(projectRoot, forTests: forTests).path}/assets.json');

  /// `.jetleaf/libraries.json` or `.jetleaf/test/libraries.json`
  static File librariesJson(Directory projectRoot, {bool forTests = false}) =>
      File('${cacheDir(projectRoot, forTests: forTests).path}/libraries.json');

  /// `.jetleaf/subclasses.json` or `.jetleaf/test/subclasses.json`
  static File subclassesJson(Directory projectRoot, {bool forTests = false}) =>
      File('${cacheDir(projectRoot, forTests: forTests).path}/subclasses.json');

  /// `.jetleaf/annotated_methods.json` or `.jetleaf/test/annotated_methods.json`
  static File annotatedMethodsJson(Directory projectRoot, {bool forTests = false}) =>
      File('${cacheDir(projectRoot, forTests: forTests).path}/annotated_methods.json');

  /// `.jetleaf/hint_registry.json` or `.jetleaf/test/hint_registry.json`
  static File hintRegistryJson(Directory projectRoot, {bool forTests = false}) =>
      File('${cacheDir(projectRoot, forTests: forTests).path}/hint_registry.json');

  // ── Generic builder ────────────────────────────────────────────────

  /// Builds an arbitrary path under `.jetleaf/`.
  ///
  /// ```dart
  /// JetleafPaths.build(projectRoot, 'subclasses.json');
  /// // → /my/project/.jetleaf/subclasses.json
  ///
  /// JetleafPaths.build(projectRoot, 'subclasses.json', forTests: true);
  /// // → /my/project/.jetleaf/test/subclasses.json
  /// ```
  static File build(Directory projectRoot, String relativePath, {bool forTests = false}) =>
      File('${cacheDir(projectRoot, forTests: forTests).path}/$relativePath');
}