import 'dart:convert';
import 'dart:io';

import 'package:jetleaf_build/jetleaf_build.dart'
    show Constant, RuntimeBuildMode;

import 'jetleaf_paths.dart';
import 'json_document.dart';
import 'toolchain_versions.dart';

/// {@template jetleaf_project_state}
/// Serializable identity and lifecycle state for a Jetleaf application.
///
/// The root `Jetleaf` file is deliberately a project descriptor rather than a
/// user configuration file. It records how the CLI identified the project,
/// which application and tests were discovered, which runtime mode is active,
/// and whether initialization has completed. Generated metadata can therefore
/// be invalidated or rebuilt without asking the application to interpret its
/// own tooling state.
///
/// The object follows the shared JSON contract: stable property names,
/// deterministic ordering supplied by [JetleafJsonWriter], and no ad-hoc
/// command-specific fields.
/// {@endtemplate}
final class JetleafProjectState implements JetleafJsonDocument {
  /// {@macro jetleaf_project_state}

  /// Version of the serialized project-state schema.
  final int schemaVersion;

  /// Package/project name displayed by CLI diagnostics.
  final String name;

  /// Absolute path of the project root used to create the state.
  final String rootPath;

  /// Project-relative application entry file, when one has been discovered.
  final String? applicationFile;

  /// Importable library URI for [applicationFile].
  final String? applicationLibrary;

  /// Starter class used to create the Jetleaf application context.
  final String? applicationClass;

  /// Project-relative test entry files known to the build layer.
  final List<String> tests;

  /// Runtime metadata policy used by initialization and execution commands.
  final RuntimeBuildMode runtimeMode;

  /// Whether discovery and metadata preparation completed successfully.
  final bool initialized;

  /// Whether the resident runtime has completed its warm-up sequence.
  final bool warmed;

  /// Time at which the project descriptor was first created.
  final DateTime? createdAt;

  /// Time of the most recent state transition written by the CLI.
  final DateTime? updatedAt;

  /// Toolchain versions captured during detection or initialization.
  final Map<String, Object?> toolchain;

  /// Creates a project state value.
  ///
  /// **Parameters:**
  /// - [name]: package/project name discovered from `pubspec.yaml`.
  /// - [rootPath]: absolute project root used by generated artifacts.
  /// - [applicationFile]: project-relative application entry file.
  /// - [applicationLibrary]: library URI used to load the application entry.
  /// - [applicationClass]: starter class discovered in the application source.
  /// - [tests]: project-relative test entries discovered by the build layer.
  /// - [runtimeMode]: metadata loading policy for the runtime.
  /// - [initialized]: whether project preparation has completed.
  /// - [warmed]: whether the resident runtime has been prepared.
  const JetleafProjectState({
    required this.name,
    required this.rootPath,
    this.schemaVersion = 1,
    this.applicationFile,
    this.applicationLibrary,
    this.applicationClass,
    this.tests = const [],
    this.runtimeMode = RuntimeBuildMode.compatibility,
    this.initialized = false,
    this.warmed = false,
    this.createdAt,
    this.updatedAt,
    this.toolchain = const {},
  });

  /// Reconstructs state from the decoded root `Jetleaf` document.
  ///
  /// Missing optional sections are interpreted using compatibility defaults so
  /// older project descriptors can be read while the CLI upgrades them.
  /// Invalid top-level JSON is rejected by [read] before this factory is used.
  factory JetleafProjectState.fromJson(Map<String, dynamic> json) {
    final project = _map(json['project']);
    final entrypoints = _map(json['entrypoints']);
    final application = _map(entrypoints['application']);
    final runtime = _map(json['runtime']);
    final status = _map(json['status']);

    return JetleafProjectState(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      name: project['name'] as String? ?? 'unknown',
      rootPath: project['rootPath'] as String? ?? Directory.current.path,
      applicationFile: application['filePath'] as String?,
      applicationLibrary: application['library'] as String?,
      applicationClass: application['mainClass'] as String?,
      tests: [for (final value in (entrypoints['tests'] as List? ?? const [])) '$value'],
      runtimeMode: _runtimeMode(runtime['mode']),
      initialized: status['initialized'] as bool? ?? false,
      warmed: status['warmed'] as bool? ?? false,
      createdAt: _date(project['createdAt']),
      updatedAt: _date(project['updatedAt']),
      toolchain: Map<String, Object?>.from(_map(json['toolchain'])),
    );
  }

  /// Creates a new state value while preserving unchanged project metadata.
  ///
  /// This method is used by lifecycle commands after discovery or warming. A
  /// state transition creates a new immutable value instead of mutating a
  /// descriptor that may already be queued for JSON serialization.
  JetleafProjectState copyWith({
    String? applicationFile,
    String? applicationLibrary,
    String? applicationClass,
    List<String>? tests,
    RuntimeBuildMode? runtimeMode,
    bool? initialized,
    bool? warmed,
    DateTime? updatedAt,
    Map<String, Object?>? toolchain,
  }) => JetleafProjectState(
    schemaVersion: schemaVersion,
    name: name,
    rootPath: rootPath,
    applicationFile: applicationFile ?? this.applicationFile,
    applicationLibrary: applicationLibrary ?? this.applicationLibrary,
    applicationClass: applicationClass ?? this.applicationClass,
    tests: tests ?? this.tests,
    runtimeMode: runtimeMode ?? this.runtimeMode,
    initialized: initialized ?? this.initialized,
    warmed: warmed ?? this.warmed,
    createdAt: createdAt,
    updatedAt: updatedAt ?? DateTime.now().toUtc(),
    toolchain: toolchain ?? this.toolchain,
  );

  /// Serializes this state into the canonical root document structure.
  ///
  /// Paths stored in the document are project-relative workspace paths. They
  /// are derived from the shared constants so consumers can inspect the file
  /// without depending on the host platform's absolute path syntax.
  @override
  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'format': 'jetleaf-project',
    'project': {
      'name': name,
      'rootPath': rootPath,
      'createdAt': createdAt?.toUtc().toIso8601String(),
      'updatedAt': updatedAt?.toUtc().toIso8601String(),
    },
    'toolchain': toolchain,
    'entrypoints': {
      'application': {
        'filePath': applicationFile,
        'library': applicationLibrary,
        'mainClass': applicationClass,
      },
      'tests': tests,
    },
    'runtime': {
      'mode': runtimeMode.name,
      'manifestPath': '${Constant.WORKSPACE_DIR_NAME}/${Constant.PROJECT_DIR_NAME}/${Constant.RUNTIME_MANIFEST_FILE_NAME}',
      'cachePath': '${Constant.WORKSPACE_DIR_NAME}/${Constant.CACHE_DIR_NAME}/${Constant.MAIN_DIR_NAME}',
    },
    'context': {
      'applicationClass': applicationClass,
      'starterAnnotation': 'JetleafApplicationStarter',
      'enabledFeatures': <String>[],
      'componentScanPackages': <String>[],
      'configurationClasses': <String>[],
      'autoConfigurations': <String>[],
    },
    'generated': {
      'directory': '${Constant.WORKSPACE_DIR_NAME}/${Constant.GENERATED_DIRECTORY_NAME}',
      'proxyDirectory': '${Constant.WORKSPACE_DIR_NAME}/${Constant.PROXY_DIR_NAME}',
      'buildDirectory': '${Constant.WORKSPACE_DIR_NAME}/${Constant.BUILD_DIR_NAME}',
    },
    'status': {
      'initialized': initialized,
      'warmed': warmed,
      'lastInit': updatedAt?.toUtc().toIso8601String(),
      'lastBuild': null,
      'lastError': null,
    },
  };

  /// Writes the state atomically through the shared JSON writer.
  ///
  /// **Parameters:**
  /// - [paths]: canonical project path view used to locate `Jetleaf`.
  Future<void> write(JetleafProjectPaths paths) async {
    await JetleafJsonWriter().write(
      paths.stateFile.path,
      toJson(),
    );
  }

  /// Reads a project descriptor when it exists.
  ///
  /// **Returns:** `null` when the project has not been initialized.
  /// **Throws:** [FormatException] when the file is not a JSON object.
  static Future<JetleafProjectState?> read(JetleafProjectPaths paths) async {
    if (!paths.stateFile.existsSync()) return null;

    final decoded = jsonDecode(await paths.stateFile.readAsString());

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Jetleaf must contain a JSON object.');
    }

    return JetleafProjectState.fromJson(decoded);
  }

  static Map<String, dynamic> _map(Object? value) => value is Map<String, dynamic> ? value : const {};

  /// Converts persisted mode text without making old descriptors unloadable.
  ///
  /// A descriptor may have been written by an earlier CLI or may have been
  /// edited incorrectly. Compatibility mode is the safe fallback because it
  /// preserves the previous behavior of discovering metadata when generated
  /// artifacts cannot be trusted.
  static RuntimeBuildMode _runtimeMode(Object? value) {
    if (value is String) {
      for (final mode in RuntimeBuildMode.values) {
        if (mode.name == value) return mode;
      }
    }
    return RuntimeBuildMode.compatibility;
  }

  static DateTime? _date(Object? value) => value is String ? DateTime.tryParse(value) : null;
}

/// Locates Jetleaf projects using the canonical descriptor and starter rules.
///
/// Detection first trusts a valid root `Jetleaf` document. When one is not
/// present, it performs the lightweight dependency check required to create a
/// provisional state value. Full source discovery remains an initialization
/// responsibility and is intentionally not hidden inside project detection.
final class JetleafProjectDetector {
  const JetleafProjectDetector();

  /// Detects a Jetleaf project rooted at [root].
  ///
  /// **Returns:** existing state, provisional dependency-derived state, or
  /// `null` when the directory is not a Jetleaf project.
  Future<JetleafProjectState?> detect(Directory root) async {
    final paths = JetleafProjectPaths(root.absolute);
    final current = await JetleafProjectState.read(paths);

    if (current != null) return current;

    final pubspec = File('${root.path}/pubspec.yaml');
    if (!pubspec.existsSync()) return null;

    final content = await pubspec.readAsString();
    if (!content.contains('jetleaf:') && !content.contains('jetleaf_core:')) return null;

    final name = _packageName(content) ?? root.basename;

    return JetleafProjectState(
      name: name,
      rootPath: root.absolute.path,
      toolchain: await JetleafToolchainVersions.resolve(root),
    );
  }

  /// Extracts the package name without requiring a YAML parser for detection.
  ///
  /// Full pubspec validation belongs to initialization; this narrow helper is
  /// only used to give a provisional detected project a stable display name.
  String? _packageName(String content) {
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('name:')) return trimmed.substring(5).trim();
    }
    
    return null;
  }
}

extension on Directory {
  String get basename => path.split(Platform.pathSeparator).last;
}
