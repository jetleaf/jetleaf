import 'dart:io';
import 'dart:mirrors' as mirrors;

import 'package:path/path.dart' as p;

import 'abstract_file_locator_utility.dart';

/// {@template abstract_file_loader_utility}
/// A high-level loading and URI-resolution utility built on top of
/// [AbstractFileLocatorUtility], responsible for converting discovered files
/// into loadable Dart libraries and ensuring they are safely introduced into
/// a mirror system.
///
/// This class serves as the final step in Jetleaf’s file-introspection pipeline:
/// after files have been located and filtered by the locator utilities, this
/// loader resolves their correct URIs, determines which files are allowed to be
/// loaded, and forces them into the active isolate or mirror system.
///
/// ### Core Responsibilities
/// - Convert absolute file system paths to `package:` URIs when possible  
/// - Fallback to `file://` URIs for non-mappable files  
/// - Apply all skip and exclusion rules inherited from
///   [AbstractFileUtility.shouldSkipFile]  
/// - Load libraries into the mirror system, with isolate-based safety and
///   fallback strategies  
/// - Distinguish user-project errors from dependency errors for accurate logging  
///
/// ### Library Loading Semantics
/// Loading a Dart library through mirrors requires special handling:
/// - Part files must never be loaded directly  
/// - Some libraries execute top-level initialization and should be loaded inside
///   an isolate for safety  
/// - URIs may fail to load depending on how they were generated, so this class
///   provides automated fallback attempts  
/// - Internal Jetleaf build/runtime files may intentionally be excluded  
///
/// ### Intended Use
/// Concrete implementations typically integrate this loader into:
/// - Jetleaf's runtime analysis workflows  
/// - Code generation pipelines  
/// - Dynamic plugin or extension systems where libraries must be introspected  
///
/// This class does **not** concern itself with *how* files were discovered—only
/// with turning them into safely loadable mirror libraries.
/// {@endtemplate}
abstract class AbstractFileLoaderUtility extends AbstractFileLocatorUtility {
  /// {@macro abstract_file_loader_utility}
  AbstractFileLoaderUtility(super.configuration, super.onError, super.onInfo, super.onWarning, super.tryOutsideIsolate);

  /// Resolves a list of files to their corresponding package or file URIs.
  /// 
  /// This method attempts to produce a usable `Uri` for every file in [files],
  /// prioritizing **package: URIs** whenever possible. If a file cannot be
  /// resolved to a package URI (e.g., it lives outside any package `lib/`
  /// directory or is an excluded dependency), a `file://` URI is used instead
  /// so the file is still loadable.
  ///
  /// Files are skipped **only** when `shouldSkipFile` indicates they should be,
  /// such as for user-excluded paths or files that cannot safely be mirrored.
  ///
  /// A summary of skipped files is logged for diagnostic purposes.
  ///
  /// Returns a mapping of each resolved file to the URI that should be used
  /// when loading it into the mirror system.
  ///
  /// - [files]: The set of Dart or non-Dart files to resolve.
  /// - [package]: The current project’s package name, used when generating
  ///   fallback `package:` URIs.
  Map<File, Uri> getUrisToLoad(Set<File> files, String package) {
    Map<File, Uri> uris = {};
    int skippedCount = 0;

    for (final file in files) {
      final normalizedFilePath = p.normalize(file.absolute.path);
      
      // Try to resolve to package URI first
      final packageUriString = resolveToPackageUri(normalizedFilePath, package);
      Uri uri;
      
      if (packageUriString != null) {
        uri = Uri.parse(packageUriString);
      } else {
        // Use file URI as fallback - don't skip files just because they can't be resolved to package URIs
        uri = file.uri;
        onInfo('Using file URI for $normalizedFilePath (could not resolve to package URI)', true);
      }

      // Only skip if user explicitly wants to exclude or if genuinely unloadable
      if (!shouldSkipFile(file, uri)) {
        uris[file] = uri;
      } else {
        skippedCount++;
      }
    }

    if (skippedCount > 0) {
      onInfo('Skipped $skippedCount files due to user configuration or unloadable files', true);
    }

    return uris;
  }

  /// Returns `true` if [filePath] belongs to the user’s own project rather than
  /// a dependency.
  ///
  /// This is used primarily for logging: failures in user files are treated as
  /// errors, while failures in dependency files are logged as warnings.
  bool _isUserProjectFile(String filePath) {
    final currentProjectPath = p.normalize(Directory.current.path);
    return p.isWithin(currentProjectPath, filePath);
  }

  /// Forces a Dart library represented by [uri] to be loaded into the provided
  /// [mirrorSystem].
  ///
  /// This method exists because the Dart mirrors API does **not** eagerly load
  /// libraries referenced in the package graph. Many analyses require fully
  /// loaded libraries, so this method enforces loading with fallback strategies.
  ///
  /// **Behavior:**
  /// - Returns `null` when the library should not be loaded (e.g., part files,
  ///   excluded Jetleaf build internals, already-loaded libraries, VM-owned
  ///   temp files).
  /// - Loads in the current isolate: `MirrorSystem`/`LibraryMirror` are not
  ///   sendable, so mirrors calls must not cross isolate boundaries.
  /// - For `file://` URIs that resolve to a `package:` URI, the package URI
  ///   is loaded instead: loading a package-backed file via `file://`
  ///   aborts the VM (`mirrors.cc: Non-library from tag handler`).
  /// - Logs warnings for dependency errors and errors for user-project errors.
  ///
  /// - [uri]: The resolved package or file URI of the library.
  /// - [file]: The file backing the URI, used for fallback checks.
  /// - [mirrorSystem]: The active mirror system performing the load.
  ///
  /// Returns the loaded [LibraryMirror], or `null` if loading failed or was skipped.
  Future<mirrors.LibraryMirror?> forceLoadLibrary(Uri uri, File file, mirrors.MirrorSystem mirrorSystem) async {
    final mustSkip = "jetleaf_build/src/runtime/";

    if(uri.toString().startsWith("package:$mustSkip") || uri.toString().contains(mustSkip)) {
      return null;
    }

    if(mirrorSystem.libraries.containsKey(uri)) {
      return null;
    }

    // file:// URIs crash the VM inside `isolate.loadUri` when the target
    // is not a real library (dart-lang/sdk#41345: "Non-library from tag
    // handler" is a fatal abort, not a catchable exception). Validate
    // before touching mirrors, and prefer the package: URI (safe order).
    String? packageUriString;
    if (uri.scheme == 'file') {
      if (file.path.isEmpty) {
        return null;
      }
      final normalized = p.normalize(file.absolute.path);
      if (_isUnsafeMirrorPath(normalized)) {
        onInfo('Skipping mirror load for VM-owned temp file $normalized (kept for analyzer)', true);
        return null;
      }
      try {
        if (!file.existsSync() || file.lengthSync() == 0) {
          return null;
        }
      } catch (_) {
        return null;
      }
      if (isPartFile(file)) {
        return null;
      }
      try {
        packageUriString = resolveToPackageUri(normalized, await readPackageName());
      } catch (_) {
        packageUriString = null;
      }
      if (packageUriString != null) {
        final alternativeUri = Uri.parse(packageUriString);
        if (mirrorSystem.libraries.containsKey(alternativeUri)) {
          return null;
        }
      }
    } else if (file.path.isNotEmpty && isPartFile(file)) {
      return null;
    }

    try {
      // NOTE: mirrors must run in the current isolate. MirrorSystem /
      // LibraryMirror are not sendable, so the old Isolate.run wrapper
      // always failed and fell through to here.
      if (!tryOutsideIsolate(file, uri)) {
        return null;
      }
      return await _loadLibrary(uri, file, mirrorSystem, packageUriString);
    } catch (e) {
      // Only log as warning for dependency files, error for user files
      if (file.path.isNotEmpty) {
        try {
          if (_isUserProjectFile(file.absolute.path)) {
            onError('Error loading user library $uri: $e', true);
          }
        } catch (_) {}
      }
    }

    return null;
  }

  /// VM-owned temp/generated paths that must never reach `isolate.loadUri`.
  bool _isUnsafeMirrorPath(String normalizedPath) {
    final lower = normalizedPath.toLowerCase();
    if (lower.endsWith('.dill')) {
      return true;
    }
    if (lower.contains('dart_test.kernel') || lower.contains('/.dart_tool/')) {
      return true;
    }
    try {
      if (p.isWithin(Directory.systemTemp.path, normalizedPath)) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Internal low-level loader used by [forceLoadLibrary].
  ///
  /// Tries the `package:` URI first (safe order) and falls back to the
  /// original `file://` URI, which the caller explicitly requires even when
  /// no package mapping exists. The caller pre-validates file:// targets
  /// because a bad target aborts the VM instead of throwing.
  ///
  /// This method never throws: it returns `null` on any failure.
  Future<mirrors.LibraryMirror?> _loadLibrary(Uri uri, File file, mirrors.MirrorSystem mirrorSystem, [String? cachedPackageUri]) async {
    onInfo('Force loading library $uri...', true);
    if (uri.scheme == 'file' && file.path.isNotEmpty) {
      String? packageUri = cachedPackageUri;
      if (packageUri == null) {
        try {
          packageUri = resolveToPackageUri(p.normalize(file.absolute.path), await readPackageName());
        } catch (_) {
          packageUri = null;
        }
      }
      if (packageUri != null && packageUri != uri.toString()) {
        try {
          final alternativeUri = Uri.parse(packageUri);
          if (!mirrorSystem.libraries.containsKey(alternativeUri)) {
            onInfo('Loading via package URI first: $alternativeUri for file: ${file.path}', true);
            return await mirrorSystem.isolate.loadUri(alternativeUri);
          } else {
            return null;
          }
        } catch (e) {
          onWarning('Package URI load failed for ${file.path}: $e — trying file URI', true);
        }
      }
    }
    try {
      return await mirrorSystem.isolate.loadUri(uri);
    } catch (e) {
      onWarning('Failed to load library $uri for ${file.path}: $e', true);
      return null;
    }
  }

  /// Resolves an absolute file system path into a Dart `package:` URI, if possible.
  ///
  /// This enables consistent reference formatting when mapping local files into
  /// package-relative URIs used by the Dart analyzer, Jetleaf runtime systems,
  /// and asset pipelines.
  ///
  /// ### Resolution Order
  /// 1. **Search dependency packages:**  
  ///    If the file resides under a recognized package's `lib/` directory,
  ///    returns a URI of the form:
  ///    ```
  ///    package:<packageName>/<relativePath>
  ///    ```
  ///
  /// 2. **Check current project:**  
  ///    If the file resides under the current project's `lib/` directory,
  ///    returns:
  ///    ```
  ///    package:<currentPackageName>/<relativePath>
  ///    ```
  ///
  /// 3. **Otherwise:**  
  ///    Returns `null` if no valid package mapping can be determined.
  ///
  /// ### Parameters
  /// - [absoluteFilePath] — The absolute path to the file being resolved.
  /// - [currentPackageName] — Name of the user project package.
  /// - [project] — Optional override directory for determining the project's root.
  ///
  /// ### Returns
  /// A `package:` URI string, or `null` if the file cannot be mapped.
  String? resolveToPackageUri(String absoluteFilePath, String currentPackageName, [Directory? project]) {
    if (packageConfig.isEmpty) {
      return null;
    }

    final normalizedAbsoluteFilePath = p.normalize(absoluteFilePath);

    // Try to resolve against known packages
    for (final pkg in packageConfig) {
      final absoluteLibPath = p.normalize(p.join(pkg.absoluteRootPath, p.fromUri(pkg.packageUri)));
      if (p.isWithin(absoluteLibPath, normalizedAbsoluteFilePath)) {
        final relativePath = p.relative(normalizedAbsoluteFilePath, from: absoluteLibPath);
        final cleanedRelativePath = relativePath.startsWith('/') ? relativePath.substring(1) : relativePath;
        return 'package:${pkg.name}/$cleanedRelativePath';
      }
    }

    // Check if it's in the current project's lib directory
    final current = project ?? Directory.current;
    final currentProjectLibPath = p.normalize(p.join(current.path, 'lib'));
    
    if (p.isWithin(currentProjectLibPath, normalizedAbsoluteFilePath)) {
      final relativePath = p.relative(normalizedAbsoluteFilePath, from: currentProjectLibPath);
      final cleanedRelativePath = relativePath.startsWith('/') ? relativePath.substring(1) : relativePath;
      return 'package:$currentPackageName/$cleanedRelativePath';
    }

    return null;
  }

  /// Reads the current package's name from the project's `pubspec.yaml`.
  ///
  /// The method attempts to extract the value of the top-level `name:` field.
  /// Once successfully resolved, the name is cached and subsequent calls return
  /// the cached value without re-reading the file.
  ///
  /// ### Behavior
  /// - Throws if `pubspec.yaml` cannot be found in the current directory.
  /// - Throws if the `name:` field is missing or malformed.
  ///
  /// ### Returns
  /// A `String` containing the package name as declared in `pubspec.yaml`.
  Future<String> readPackageName() async {
    if (currentPackageName != null) return currentPackageName!;

    final pubspecFile = File(p.join(Directory.current.path, 'pubspec.yaml'));
    if (!await pubspecFile.exists()) {
      throw Exception('pubspec.yaml not found in current directory.');
    }
    
    final content = await pubspecFile.readAsString();
    final nameMatch = RegExp(r'name:\s*(\S+)').firstMatch(content);
    if (nameMatch != null && nameMatch.group(1) != null) {
      currentPackageName = nameMatch.group(1)!;
      return currentPackageName!;
    }
    throw Exception('Could not find package name in pubspec.yaml');
  }
}