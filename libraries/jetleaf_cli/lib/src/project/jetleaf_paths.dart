import 'dart:io';

import 'package:jetleaf_build/jetleaf_build.dart' show Constant, JetleafPaths;
import 'package:path/path.dart' as p;

/// {@template jetleaf_project_paths}
/// Compatibility path view for a Jetleaf project.
///
/// The CLI used to own a configurable path policy. That arrangement allowed
/// the CLI, the VM, and the build scanner to address different locations for
/// the same generated artifact. This facade remains for callers that already
/// construct `JetleafProjectPaths`, but it deliberately contains no path
/// policy of its own. Every location delegates to [JetleafPaths], whose names
/// are defined centrally by `Constant` in `jetleaf_build`.
///
/// ### Responsibilities
///
/// - Expose the canonical project, cache, generated, proxy, build, VM, and
///   report directories to CLI code.
/// - Provide small file helpers for metadata writers and command runners.
/// - Migrate known pre-canonical state without replacing newer files.
///
/// ### Non-responsibilities
///
/// This class does not decide where Jetleaf state belongs, invent alternate
/// directory names, or interpret the contents of generated files. Those
/// concerns belong to `Constant`, `JetleafPaths`, and the owning subsystem.
/// {@endtemplate}
final class JetleafProjectPaths {
  /// {@macro jetleaf_project_paths}
  ///
  /// **Parameters:**
  /// - [root]: project directory whose generated state is addressed.
  const JetleafProjectPaths(this.root);

  /// Project root whose generated state is being addressed.
  ///
  /// The directory is intentionally retained as a [Directory] instead of a
  /// string so callers can preserve the same file-system abstraction used by
  /// the build and VM layers.
  final Directory root;

  /// Canonical extensionless project state file.
  ///
  /// This file identifies the project and records the metadata needed by
  /// subsequent `init`, `build`, `dev`, and `test` commands.
  File get stateFile => JetleafPaths.stateFile(root);

  /// Canonical `.jetleaf` workspace directory.
  ///
  /// All generated state owned by Jetleaf is kept below this directory,
  /// except for the root `Jetleaf` project descriptor.
  Directory get stateDirectory => JetleafPaths.workspaceDir(root);

  /// Directory containing discovery, context, and runtime metadata.
  Directory get projectDirectory => JetleafPaths.projectDir(root);

  /// Directory containing application runtime support artifacts.
  Directory get mainDirectory => JetleafPaths.mainDir(root);

  /// Root directory containing the main and test cache namespaces.
  Directory get cacheDirectory => JetleafPaths.directory(root, Constant.CACHE_DIR_NAME);

  /// Directory containing generated bootstrap and entry source.
  Directory get generatedDirectory => JetleafPaths.generatedDir(root);

  /// Directory containing proxy manifests and CLI metadata.
  ///
  /// Generated proxy Dart sources remain under `lib/_jetleaf` so normal Dart
  /// execution and Jetleaf discovery can resolve them.
  Directory get proxyDirectory => JetleafPaths.proxyDir(root);

  /// Directory containing production build artifacts.
  Directory get buildDirectory => JetleafPaths.buildDir(root);

  /// Directory containing resident manager state and entry snapshots.
  Directory get vmDirectory => JetleafPaths.vmDir(root);

  /// Directory containing human-readable and machine-readable reports.
  Directory get reportsDirectory => JetleafPaths.reportsDir(root);

  /// Resolves [name] below the project metadata directory.
  ///
  /// **Parameters:**
  /// - [name]: file name or project-relative file path.
  ///
  /// **Returns:** a file handle; the file is not created by this method.
  File projectFile(String name) => File(p.join(projectDirectory.path, name));

  /// Resolves [name] below a cache namespace.
  ///
  /// **Parameters:**
  /// - [mode]: cache namespace, normally `main` or `test`.
  /// - [name]: cache file name or relative cache path.
  ///
  /// **Returns:** a file handle; the file is not created by this method.
  File cacheFile(String mode, String name) => File(p.join(cacheDirectory.path, mode, name));

  /// Resolves [name] below the generated source directory.
  File generatedFile(String name) => File(p.join(generatedDirectory.path, name));

  /// Resolves [name] below the production build directory.
  File buildFile(String name) => File(p.join(buildDirectory.path, name));

  /// Resolves [name] below the diagnostic report directory.
  File reportFile(String name) => File(p.join(reportsDirectory.path, name));

  /// Creates every canonical workspace directory required by the CLI.
  ///
  /// Directory creation is intentionally centralized here so commands can
  /// prepare a project without knowing which individual subsystem owns each
  /// directory. Existing directories are accepted and are never deleted.
  Future<void> createDirectories() async {
    for (final directory in [
      stateDirectory,
      projectDirectory,
      mainDirectory,
      cacheDirectory,
      generatedDirectory,
      proxyDirectory,
      buildDirectory,
      vmDirectory,
      reportsDirectory,
    ]) {
      await directory.create(recursive: true);
    }
  }

  /// Migrates known pre-canonical state into the shared workspace.
  ///
  /// Migration is deliberately conservative: an existing canonical file is
  /// never replaced by legacy content. This allows the CLI and low-level
  /// `jl` commands to be used in either order while a project is upgraded.
  Future<void> migrateLegacy() async {
    await createDirectories();
    final legacyEntries = Directory(p.join(root.path, Constant.JETLEAF_GENERATED_DIR_NAME));
    if (legacyEntries.existsSync()) {
      await _copyDirectory(legacyEntries, generatedDirectory);
    }

    final legacyVm = Directory(p.join(root.path, '.dart_tool', 'jetleaf_build'));
    if (legacyVm.existsSync()) {
      await _copyDirectory(legacyVm, vmDirectory);
    }

    final legacyState = File(p.join(root.path, Constant.LEGACY_VM_STATE_FILE_NAME));
    final canonicalState = File(p.join(vmDirectory.path, Constant.VM_STATE_FILE_NAME));

    if (legacyState.existsSync() && !canonicalState.existsSync()) {
      await legacyState.copy(canonicalState.path);
    }
  }

  /// Copies a legacy directory without replacing canonical files.
  ///
  /// **Parameters:**
  /// - [source]: legacy directory to read.
  /// - [target]: canonical directory receiving missing files.
  ///
  /// A file already present in [target] wins over its legacy counterpart. This
  /// rule makes migration repeatable and prevents an old cache from silently
  /// replacing state produced by a newer command.
  Future<void> _copyDirectory(Directory source, Directory target) async {
    await for (final entity in source.list(recursive: true, followLinks: false)) {
      final relative = p.relative(entity.path, from: source.path);
      final destination = p.join(target.path, relative);
      
      if (entity is Directory) {
        await Directory(destination).create(recursive: true);
      } else if (entity is File && !File(destination).existsSync()) {
        await File(destination).parent.create(recursive: true);
        await entity.copy(destination);
      }
    }
  }
}
