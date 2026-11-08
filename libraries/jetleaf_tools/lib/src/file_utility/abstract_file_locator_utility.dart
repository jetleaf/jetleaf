import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'abstract_file_utility.dart';
import '../utils/constant.dart';
import '../utils/must_avoid.dart';
import 'located_files.dart';

/// {@template abstract_file_locator_utility}
/// A high-level file discovery utility that extends [AbstractFileUtility] with
/// capabilities for locating **both Dart and non-Dart source files** across the
/// user’s project and all dependency packages.
///
/// This class forms the foundation of Jetleaf’s project-scanning layer.  
/// It provides a consistent, configurable mechanism for assembling the complete
/// set of files relevant to runtime reflection, analysis, or code generation.
///
/// ### Core Responsibilities
/// - Recursively scan the user project for Dart or non-Dart files  
/// - Optionally scan all dependency packages, respecting Jetleaf-specific rules  
/// - Apply user-defined inclusion and exclusion rules  
/// - Honor test-file skip behavior and part-file detection  
/// - Participate in Jetleaf’s “package relevance” filtering (e.g., skipping
///   non-Jetleaf packages unless required)  
/// - Route logging through the parent utility for insight into scanning behavior
///
/// ### Behavioral Highlights
/// - **User-Included Files:** If any files are explicitly listed in  
///   `configuration.filesToScan`, scanning becomes opt-in and only those files  
///   are considered.  
///
/// - **User-Excluded Files:** Paths listed in `configuration.filesToExclude`  
///   take precedence and are always ignored.  
///
/// - **Package Filtering:** Dependency packages may be included, excluded, or  
///   auto-filtered based on Jetleaf’s dependency graph.  
///
/// - **Project-wide Scanning:** Provides high-level conveniences such as  
///   `findDartFiles()` and `findNonDartFiles()`, which orchestrate scanning  
///   across the project and its dependencies.  
///
/// ### Intended Use
/// Concrete subclasses typically provide:
/// - custom traversal logic  
/// - caching/persistence for repeated scans  
/// - post-processing of discovered files  
/// - integration with build steps or runtime injection systems  
///
/// This class itself focuses on *file discovery semantics*, leaving higher-level
/// interpretation to the implementing framework.
/// {@endtemplate}
abstract class AbstractFileLocatorUtility extends AbstractFileUtility {
  /// Keeps track of logged "Skipping package" message to reduce message logs.
  final Set<String> _loggedSkippedPackageMessages = {};

  /// {@macro abstract_file_locator_utility}
  AbstractFileLocatorUtility(super.configuration, super.onError, super.onInfo, super.onWarning, super.tryOutsideIsolate);

  /// Scans the current project **and all dependency packages** for Dart source
  /// files, applying user-defined inclusion and exclusion rules.
  ///
  /// This is the primary method for assembling the complete set of Dart files
  /// relevant to Jetleaf’s analysis or code generation systems.
  ///
  /// ### Features
  /// - Honors explicit user-included files via `configuration.filesToScan`
  /// - Honors explicit user-excluded files via `configuration.filesToExclude`
  /// - Skips test files if `skipTests = true`
  /// - Skips packages that do not depend on Jetleaf (unless disabled)
  /// - Scans both the user’s project and all dependencies
  ///
  /// ### Parameters
  /// - [projectDir] — The root directory of the user's project.
  ///
  /// ### Returns
  /// A set of all discovered `.dart` files.
  Future<LocatedFiles> findDartFiles(Directory projectDir) async {
    final LocatedFiles files = LocatedFiles();

    final allFilesToScan = (configuration.filesToScan).map((f) => p.normalize(f.absolute.path)).toSet();
    final allFilesToExclude = (configuration.filesToExclude).map((f) => p.normalize(f.absolute.path)).toSet();

    // Scan user project
    onInfo('Scanning user project for Dart files...', true);
    await _scanDirectoryForDartFiles(projectDir, files, allFilesToScan, allFilesToExclude);

    // Scan ALL dependencies unless user explicitly excludes them
    onInfo('Scanning ALL dependencies for Dart files...', true);
    await scanAllDependenciesForDartFiles(files, allFilesToScan, allFilesToExclude, projectDir);

    return files;
  }

  /// Scans a directory tree for `.dart` files, respecting user-specified
  /// inclusion rules, exclusion rules, test-file behavior, and internal
  /// Jetleaf filtering logic.
  ///
  /// This function is intentionally low-level and used by both project scanning
  /// and dependency scanning routines.
  ///
  /// ### Filtering Rules
  /// - Files explicitly excluded → **skipped**
  /// - If inclusion list is non-empty → only included if explicitly listed
  /// - Test files → skipped only when configured and not force-included
  /// - "Forgotten" files via `forgetPackage()` checks → skipped
  ///
  /// ### Parameters
  /// - [dir] — Directory to scan.
  /// - [located] — The mutable [LocatedFiles] used to collect results.
  /// - [filesToScan] — Normalized user-included file paths.
  /// - [filesToExclude] — Normalized user-excluded file paths.
  /// - [packageName] — Optional package name used for advanced internal filters.
  Future<void> _scanDirectoryForDartFiles(Directory dir, LocatedFiles located, Set<String> filesToScan, Set<String> filesToExclude, [String packageName = "", Directory? pkgRoot]) async {
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final normalizedPath = p.normalize(entity.absolute.path);

        // Skip .dart_tool and build directories
        if (normalizedPath.contains('${p.separator}.dart_tool${p.separator}') ||
            normalizedPath.contains('${p.separator}build${p.separator}')) {
          continue;
        }

        // Do not traverse into nested sub-packages
        if (_isWithinSubPackage(entity.path, dir)) {
          continue;
        }
        
        // Skip only explicitly excluded files
        if (filesToExclude.contains(normalizedPath)) {
          continue;
        }

        // If specific files are listed, only include those
        if (filesToScan.isNotEmpty && !filesToScan.contains(normalizedPath)) {
          continue;
        }

        // Skip test files only if user configured skipTests
        if (configuration.skipTests && isTestFile(normalizedPath) && !filesToScan.contains(normalizedPath)) {
          continue;
        }

        if (forgetPackage(normalizedPath) || forgetPackage(await entity.readAsString())) {
          continue;
        }

        // final build = "jetleaf_build";
        // final allowed = ['annotations.dart', 'constant.dart', 'exceptions.dart'];

        // if (packageName == build && !(allowed.contains(normalizedPath) || normalizedPath.contains("runtime_hint"))) {
        //   continue;
        // }

        // Include everything else
        if (pkgRoot case final packageRoot?) {
          if ((await getJetleafDependencies(packageRoot)).isEmpty) {
            final message = 'Skipping non-Jetleaf package: $packageName';

            if (_loggedSkippedPackageMessages.add(message)) {
              onInfo(message, true);
            }

            located.addToAnalyzer(entity);
          } else {
            located.add(entity);
          }
        } else {
          located.add(entity);
        }
      }
    }
  }

  /// Scans **all dependency packages** for Dart files using the same filtering
  /// logic as project scanning, extended with package-level inclusion/exclusion
  /// configuration and Jetleaf dependency detection.
  ///
  /// ### Package-Level Logic
  /// - Packages listed in `packagesToExclude` → **skipped**
  /// - If `packagesToScan` is non-empty → scan only listed packages
  /// - A dependency is considered a “Jetleaf package” if any of its dependencies
  ///   match `jetleafPackages` or begin with `PackageNames.MAIN`
  ///
  /// ### Parameters
  /// - [located] — The [LocatedFiles] where discovered `.dart` files are added.
  /// - [filesToScan] — User-specified inclusion list.
  /// - [filesToExclude] — User-specified exclusion list.
  Future<void> scanAllDependenciesForDartFiles(LocatedFiles located, Set<String> filesToScan, Set<String> filesToExclude, [Directory? projectDir]) async {
    if (packageConfigCache == null) {
      await loadPackageConfig(projectDir);
    }

    if (packageConfigCache == null) {
      return;
    }

    final currentPkgName = projectDir != null ? await _readPackageNameFor(projectDir) : null;
    final allowedDependencies = projectDir != null ? await resolveTransitivePackageDependencies(projectDir) : null;

    for (final pkg in packageConfigCache!) {
      final packageName = pkg.name;

      // Do not re-scan the project itself as a dependency (already scanned)
      if (packageName == currentPkgName) {
        continue;
      }

      // If we resolved project dependencies, skip any package not in the dependency closure
      if (allowedDependencies != null && !allowedDependencies.contains(packageName)) {
        continue;
      }

      final packageRoot = Directory(pkg.absoluteRootPath);
      if (!await packageRoot.exists()) continue;

      // Scan only the package's lib directory (public/importable library files)
      final packageLibDir = Directory(p.normalize(p.join(pkg.absoluteRootPath, pkg.packageUri.path)));
      if (!await packageLibDir.exists()) continue;

      // Skip if user excluded the package
      if (configuration.packagesToExclude.contains(packageName)) {
        onInfo('Skipping excluded package: $packageName', true);
        continue;
      }
      
      // If user specified packages to scan, only include those. Otherwise include all.
      final bool includePackage = configuration.packagesToScan.isEmpty || configuration.packagesToScan.contains(packageName);

      if (includePackage) {
        onInfo('Scanning package: $packageName', true);
        await _scanDirectoryForDartFiles(packageLibDir, located, filesToScan, filesToExclude, packageName, packageRoot);
      }
    }
  }

  bool _isWithinSubPackage(String filePath, Directory rootDir) {
    var parent = File(filePath).parent;
    final rootPath = p.normalize(rootDir.absolute.path);
    while (p.normalize(parent.absolute.path) != rootPath) {
      if (File(p.join(parent.path, 'pubspec.yaml')).existsSync()) {
        return true;
      }
      final nextParent = parent.parent;
      if (nextParent.path == parent.path) break;
      parent = nextParent;
    }
    return false;
  }

  Future<String?> _readPackageNameFor(Directory dir) async {
    final pubspecFile = File(p.join(dir.path, 'pubspec.yaml'));
    if (!await pubspecFile.exists()) return null;
    final content = await pubspecFile.readAsString();
    final nameMatch = RegExp(r'name:\s*(\S+)').firstMatch(content);
    return nameMatch?.group(1);
  }

  /// Resolves all transitive package dependencies for [projectDir] based on
  /// `.dart_tool/package_graph.json` or recursively following `pubspec.yaml`
  /// declarations across the resolved package roots.
  Future<Set<String>> resolveTransitivePackageDependencies(Directory projectDir) async {
    final rootPubspec = File(p.join(projectDir.path, 'pubspec.yaml'));
    if (!await rootPubspec.exists()) return {};

    final currentPackage = await _readPackageNameFor(projectDir);
    final visited = <String>{};

    // 1. Try reading package_graph.json if available
    final packageConfigFile = findPackageConfigFile(projectDir);
    if (packageConfigFile != null) {
      final graphFile = File(p.join(packageConfigFile.parent.path, 'package_graph.json'));
      if (await graphFile.exists()) {
        try {
          final content = await graphFile.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          final packagesList = json['packages'] as List<dynamic>? ?? [];
          final graphMap = <String, List<String>>{};
          for (final item in packagesList) {
            if (item is Map<String, dynamic>) {
              final name = item['name'] as String?;
              final deps = (item['dependencies'] as List<dynamic>?)?.cast<String>() ?? [];
              final devDeps = (item['devDependencies'] as List<dynamic>?)?.cast<String>() ?? [];
              if (name != null) {
                graphMap[name] = [...deps, if (name == currentPackage) ...devDeps];
              }
            }
          }

          if (currentPackage != null && graphMap.containsKey(currentPackage)) {
            final toVisit = List<String>.from(graphMap[currentPackage]!);
            while (toVisit.isNotEmpty) {
              final next = toVisit.removeLast();
              if (visited.add(next)) {
                final nextDeps = graphMap[next];
                if (nextDeps != null) {
                  for (final dep in nextDeps) {
                    if (!visited.contains(dep)) {
                      toVisit.add(dep);
                    }
                  }
                }
              }
            }
            return visited;
          }
        } catch (_) {}
      }
    }

    // 2. Fallback: BFS using pubspec.yaml of packages in packageConfigCache
    if (packageConfigCache == null) {
      await loadPackageConfig(projectDir);
    }
    final configMap = <String, PackageConfigEntry>{};
    if (packageConfigCache != null) {
      for (final entry in packageConfigCache!) {
        configMap[entry.name] = entry;
      }
    }

    final direct = await extractPubspecDependencyKeys(projectDir);
    final queue = List<String>.from(direct);
    while (queue.isNotEmpty) {
      final dep = queue.removeLast();
      if (visited.add(dep)) {
        final entry = configMap[dep];
        if (entry != null) {
          final pkgDir = Directory(entry.absoluteRootPath);
          final subDeps = await extractPubspecDependencyKeys(pkgDir);
          for (final subDep in subDeps) {
            if (!visited.contains(subDep)) {
              queue.add(subDep);
            }
          }
        }
      }
    }

    return visited;
  }

  /// {@template extract_pubspec_dependency_keys}
  /// Extracts all dependency keys declared in a `pubspec.yaml` located at the
  /// given [packageRoot].
  ///
  /// This function:
  /// - locates `pubspec.yaml` inside the directory
  /// - returns an empty set if the file does not exist
  /// - scans only `dependencies:` and `dev_dependencies:` sections
  /// - stops reading when another top-level YAML key is reached
  /// - ignores comments and empty lines
  /// - extracts only the package names, not version constraints
  ///
  /// ### Example
  /// ```dart
  /// final deps = await extractPubspecDependencyKeys(Directory('/my/pkg'));
  /// print(deps); // {http, shelf, path, ...}
  /// ```
  ///
  /// Returns a `Set<String>` containing only dependency identifiers.
  /// {@endtemplate}
  Future<Set<String>> extractPubspecDependencyKeys(Directory packageRoot) async {
    final pubspecFile = File('${packageRoot.path}/pubspec.yaml');

    if (!await pubspecFile.exists()) return {};

    final lines = await pubspecFile.readAsLines();

    final Set<String> keys = {};
    bool inDeps = false;

    for (final rawLine in lines) {
      final line = rawLine.trimRight();

      // Enter dependency sections
      if (line == 'dependencies:' || line == 'dev_dependencies:') {
        inDeps = true;
        continue;
      }

      // Leave section when hitting next top-level key
      if (inDeps && !rawLine.startsWith(' ') && line.isNotEmpty) {
        inDeps = false;
        continue;
      }

      if (!inDeps) continue;

      // Ignore comments or empty lines
      if (line.isEmpty || line.trimLeft().startsWith('#')) continue;

      // Extract the package key only
      final match = RegExp(r'^\s*([\w\-]+)\s*:').firstMatch(rawLine);
      if (match != null) {
        keys.add(match.group(1)!);
      }
    }

    return keys;
  }

  /// Returns the set of **Jetleaf-related dependencies** declared in a package.
  ///
  /// This method inspects the `pubspec.yaml` located at [packageRoot] and
  /// extracts all declared dependency names. From that set, it filters and
  /// returns only dependencies that are considered part of the Jetleaf
  /// ecosystem.
  ///
  /// A dependency is classified as a *Jetleaf dependency* if:
  /// - Its name exists in [jetleafPackages], **or**
  /// - Its name starts with [PackageNames.MAIN] (the Jetleaf main package prefix)
  ///
  /// Parameters:
  /// - [packageRoot]: The root directory of the Dart package containing
  ///   a `pubspec.yaml` file.
  ///
  /// Returns:
  /// - A [Set] of dependency names that belong to the Jetleaf framework
  ///   or its core modules.
  Future<Set<String>> getJetleafDependencies(Directory packageRoot) async {
    final keys = await extractPubspecDependencyKeys(packageRoot);
    return extractJetleafDependencies(keys).toSet();
  }

  /// Returns the set of **Jetleaf-related dependencies** declared in a package.
  ///
  /// This method inspects the given iterable [dependencies] to filter and
  /// returns only dependencies that are considered part of the Jetleaf
  /// ecosystem.
  ///
  /// A dependency is classified as a *Jetleaf dependency* if:
  /// - Its name exists in [jetleafPackages], **or**
  /// - Its name starts with [PackageNames.MAIN] (the Jetleaf main package prefix)
  Iterable<String> extractJetleafDependencies(Iterable<String> dependencies) => dependencies.where((key) => jetleafPackages.contains(key) || key.startsWith(PackageNames.MAIN));

  /// Returns the set of **non-Jetleaf dependencies** declared in a package.
  ///
  /// This method complements [getJetleafDependencies] by identifying
  /// dependencies that do **not** belong to the Jetleaf ecosystem.
  ///
  /// A dependency is classified as *non-Jetleaf* if:
  /// - Its name is not listed in [jetleafPackages], **or**
  /// - Its name does not start with [PackageNames.MAIN]
  /// 
  /// Parameters:
  /// - [packageRoot]: The root directory of the Dart package containing
  ///   a `pubspec.yaml` file.
  ///
  /// Returns:
  /// - A [Set] of dependency names that are external to the Jetleaf framework.
  Future<Set<String>> getNonJetleafDependencies(Directory packageRoot) async {
    final keys = await extractPubspecDependencyKeys(packageRoot);
    return keys.where((key) => !jetleafPackages.contains(key) || !key.startsWith(PackageNames.MAIN)).toSet();
  }

  /// Finds all **non-Dart files** within the current project and optionally
  /// selected dependency packages, respecting the user's inclusion and exclusion
  /// rules from the runtime scanner configuration.
  ///
  /// ### Behavior
  /// - Any file ending **not** with `.dart` is eligible.
  /// - Files listed in `filesToExclude` are always skipped.
  /// - If `filesToScan` is non-empty, only explicitly listed files are included.
  /// - Dependencies are scanned **only** when the user explicitly lists them in
  ///   `packagesToScan`, and not present in `packagesToExclude`.
  ///
  /// ### Parameters
  /// - [projectDir] — The root directory of the user project.
  ///
  /// ### Returns
  /// A `Set<File>` containing all discovered non-Dart files.
  Future<Set<File>> findNonDartFiles(Directory projectDir) async {
    final Set<File> nonDartFiles = {};
    
    final allFilesToScan = (configuration.filesToScan).map((f) => p.normalize(f.absolute.path)).toSet();
    final allFilesToExclude = (configuration.filesToExclude).map((f) => p.normalize(f.absolute.path)).toSet();

    // Helper to check if a file should be included
    bool shouldIncludeFile(String filePath) {
      final normalizedPath = p.normalize(filePath);
      if (allFilesToExclude.contains(normalizedPath)) {
        return false;
      }
      if (allFilesToScan.isEmpty) {
        return true;
      }
      return allFilesToScan.contains(normalizedPath);
    }

    // 1. Find non-Dart files in the current project directory
    await for (final entity in projectDir.list(recursive: true, followLinks: false)) {
      if (entity is File && !entity.path.endsWith('.dart')) {
        if (shouldIncludeFile(entity.absolute.path)) {
          nonDartFiles.add(entity);
        }
      }
    }

    // 2. Find non-Dart files in dependencies (only if explicitly requested)
    if (configuration.packagesToScan.isNotEmpty && packageConfigCache != null) {
      for (final pkg in packageConfigCache!) {
        final packageName = pkg.name;
        final packageRoot = Directory(pkg.absoluteRootPath);

        final bool includePackage = configuration.packagesToScan.contains(packageName);
        final bool excludePackage = configuration.packagesToExclude.contains(packageName);

        if (includePackage && !excludePackage && await packageRoot.exists()) {
          await for (final entity in packageRoot.list(recursive: true, followLinks: false)) {
            if (entity is File && !entity.path.endsWith('.dart')) {
              if (shouldIncludeFile(entity.absolute.path)) {
                nonDartFiles.add(entity);
              }
            }
          }
        }
      }
    }

    return nonDartFiles;
  }

  @override
  Future<void> cleanup() async {
    await super.cleanup();
    _loggedSkippedPackageMessages.clear();
  }
}