// ignore_for_file: unused_element
import 'dart:io';

import 'package:jetleaf_core/lang.dart' show Constant;
import 'package:path/path.dart' as p;

import 'abstract_file_locator_utility.dart';

/// {@template abstract_file_loader_utility}
/// A high-level loading and URI-resolution utility built on top of
/// [AbstractFileLocatorUtility], responsible for converting discovered files
/// into loadable Dart libraries and resolving their package URIs.
///
/// This class serves as the final step in Jetleaf's file-introspection pipeline:
/// after files have been located and filtered by the locator utilities, this
/// loader resolves their correct URIs, determines which files are allowed to be
/// loaded, and maps them to `package:` URIs.
///
/// ### Core Responsibilities
/// - Convert absolute file system paths to `package:` URIs when possible
/// - Fallback to `file://` URIs for non-mappable files
/// - Apply all skip and exclusion rules inherited from
///   [AbstractFileUtility.shouldSkipFile]
/// - Map libraries to loadable `package:` URIs, with isolate-based safety and
///   fallback strategies
/// - Distinguish user-project errors from dependency errors for accurate logging
///
/// ### Intended Use
/// Concrete implementations typically integrate this loader into:
/// - Jetleaf's runtime analysis workflows
/// - Code generation pipelines
/// - Dynamic plugin or extension systems where libraries must be introspected
///
/// This class does **not** concern itself with *how* files were discovered—only
/// with turning them into safely resolvable `package:` URIs.
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
  /// such as for user-excluded paths or files that cannot safely be loaded.
  ///
  /// A summary of skipped files is logged for diagnostic purposes.
  ///
  /// Returns a mapping of each resolved file to the URI that should be used
  /// when loading it.
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

    final pubspecFile = File(p.join(Directory.current.path, Constant.PUBSPEC_YAML_FILE_NAME));
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