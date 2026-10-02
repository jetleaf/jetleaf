import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/constant.dart';

/// {@template jetleaf_paths}
/// Shared path construction for the Jetleaf workspace.
///
/// [Constant] owns the names that make up the workspace contract. This class
/// owns the platform-aware joining of those names to a project root. Keeping
/// those responsibilities separate lets every Jetleaf package use the same
/// layout without embedding operating-system path syntax or duplicating
/// directory policies.
///
/// The canonical layout is `.jetleaf/project`, `.jetleaf/main`,
/// `.jetleaf/cache`, `.jetleaf/generated`, `.jetleaf/proxy`,
/// `.jetleaf/build`, `.jetleaf/vm`, and `.jetleaf/reports`.
/// {@endtemplate}
abstract final class JetleafPaths {
  /// {@macro jetleaf_paths}
  JetleafPaths._();

  /// The canonical workspace directory name.
  static const String dirName = Constant.WORKSPACE_DIR_NAME;

  /// The cache directory name inside the workspace.
  static const String cacheDirName = Constant.CACHE_DIR_NAME;

  /// The application cache name.
  static const String mainDirName = Constant.MAIN_DIR_NAME;

  /// The test cache name.
  static const String testDirName = Constant.TEST_DIR_NAME;

  /// Returns the canonical `.jetleaf` workspace directory.
  static Directory workspaceDir(Directory projectRoot) => Directory(p.join(projectRoot.path, Constant.WORKSPACE_DIR_NAME));

  /// Returns the extensionless project state file at the project root.
  static File stateFile(Directory projectRoot) => File(p.join(projectRoot.path, Constant.STATE_FILE_NAME));

  /// Returns a named directory directly under `.jetleaf`.
  static Directory directory(Directory projectRoot, String name) => Directory(p.join(workspaceDir(projectRoot).path, name));

  /// Returns a named file directly under `.jetleaf`.
  static File file(Directory projectRoot, String name) => File(p.join(workspaceDir(projectRoot).path, name));

  /// Returns the application cache directory.
  static Directory dir(Directory projectRoot) => Directory(p.join(workspaceDir(projectRoot).path, cacheDirName, mainDirName));

  /// Returns the test cache directory.
  static Directory testDir(Directory projectRoot) => Directory(p.join(workspaceDir(projectRoot).path, cacheDirName, testDirName));

  /// Returns an application or test cache directory.
  static Directory cacheDir(Directory projectRoot, {bool forTests = false}) => forTests ? testDir(projectRoot) : dir(projectRoot);

  /// Returns a cache binary identified by [fingerprint].
  static File cacheFile(Directory projectRoot, String fingerprint, { bool forTests = false }) => File(p.join(
    cacheDir(projectRoot, forTests: forTests).path,
    'cache_$fingerprint.bin',
  ));

  /// Returns the cache fingerprint file.
  static File fingerprintFile(Directory projectRoot, {bool forTests = false}) => File(p.join(cacheDir(projectRoot, forTests: forTests).path, 'fingerprint.txt'));

  /// Returns the package discovery metadata file.
  static File packagesJson(Directory projectRoot, {bool forTests = false}) => File(p.join(cacheDir(projectRoot, forTests: forTests).path, 'packages.json'));

  /// Returns the asset discovery metadata file.
  static File assetsJson(Directory projectRoot, {bool forTests = false}) => File(p.join(cacheDir(projectRoot, forTests: forTests).path, 'assets.json'));

  /// Returns the library discovery metadata file.
  static File librariesJson(Directory projectRoot, {bool forTests = false}) => File(p.join(cacheDir(projectRoot, forTests: forTests).path, 'libraries.json'));

  /// Returns the subclass discovery metadata file.
  static File subclassesJson(Directory projectRoot, {bool forTests = false}) => File(p.join(cacheDir(projectRoot, forTests: forTests).path, 'subclasses.json'));

  /// Returns the annotated-method metadata file.
  static File annotatedMethodsJson(Directory projectRoot, {bool forTests = false}) => File(p.join(cacheDir(projectRoot, forTests: forTests).path, 'annotated_methods.json'));

  /// Returns the project metadata directory.
  static Directory projectDir(Directory projectRoot) => directory(projectRoot, Constant.PROJECT_DIR_NAME);

  /// Returns the application runtime directory.
  static Directory mainDir(Directory projectRoot) => directory(projectRoot, Constant.MAIN_DIR_NAME);

  /// Returns the generated source directory.
  static Directory generatedDir(Directory projectRoot) => directory(projectRoot, Constant.GENERATED_DIRECTORY_NAME);

  /// Returns the proxy metadata directory.
  ///
  /// Generated proxy Dart sources do not belong here. They remain under the
  /// active `lib/_jetleaf` path so Dart execution and runtime discovery can
  /// resolve them through the normal package source graph. This directory is
  /// reserved for proxy manifests and tooling metadata.
  static Directory proxyDir(Directory projectRoot) => directory(projectRoot, Constant.PROXY_DIR_NAME);

  /// Returns the production build directory.
  static Directory buildDir(Directory projectRoot) => directory(projectRoot, Constant.BUILD_DIR_NAME);

  /// Returns the resident VM directory.
  static Directory vmDir(Directory projectRoot) => directory(projectRoot, Constant.VM_DIR_NAME);

  /// Returns the diagnostic report directory.
  static Directory reportsDir(Directory projectRoot) => directory(projectRoot, Constant.REPORTS_DIR_NAME);

  /// Returns the production runtime manifest.
  static File runtimeManifest(Directory projectRoot) => File(p.join(projectDir(projectRoot).path, Constant.RUNTIME_MANIFEST_FILE_NAME));

  /// Returns the generated application registry.
  static File runtimeRegistry(Directory projectRoot) => File(p.join(mainDir(projectRoot).path, Constant.RUNTIME_REGISTRY_FILE_NAME));

  /// Returns the runtime hint registry.
  static File hintRegistryJson(Directory projectRoot, {bool forTests = false}) => File(p.join(cacheDir(projectRoot, forTests: forTests).path, 'hint_registry.json'));

  /// Returns an arbitrary file below the selected cache directory.
  static File build(Directory projectRoot, String relativePath, {bool forTests = false}) => File(p.join(cacheDir(projectRoot, forTests: forTests).path, relativePath));
}
