import 'environment.dart';

/// {@template pubspec}
/// Represents the `pubspec.yaml` metadata of a Dart/Jetleaf project.
///
/// The [Pubspec] class captures all standard properties of a pubspec file,
/// including project metadata, dependencies, and environment constraints.
/// This class is immutable; to create modified instances, use [copyWith].
///
/// ### Example
/// ```dart
/// final pubspec = Pubspec(
///   name: "my_app",
///   description: "A sample Jetleaf application",
///   version: "1.0.0",
///   homepage: "https://example.com",
///   repository: "https://github.com/example/my_app",
///   issueTracker: "https://github.com/example/my_app/issues",
///   documentation: "https://docs.example.com/my_app",
///   topics: ["server", "jetleaf", "backend"],
///   keywords: ["jetleaf", "dart", "server"],
///   environment: Environment(sdk: "3.3.0"),
///   dependencies: {"jetleaf_core": "^1.0.0"},
///   devDependencies: {"test": "^1.21.0"},
/// );
/// ```
/// {@endtemplate}
final class Pubspec {
  /// The name of the project/package.
  final String? name;

  /// A short description of the project.
  final String? description;

  /// The project version (e.g., "1.0.0").
  final String? version;

  /// The project's homepage URL.
  final String? homepage;

  /// The project's repository URL.
  final String? repository;

  /// The URL to the issue tracker for the project.
  final String? issueTracker;

  /// The URL to the project's documentation.
  final String? documentation;

  /// A list of topic strings associated with the project.
  final List<String> topics;

  /// A list of keyword strings associated with the project.
  final List<String> keywords;

  /// The environment constraints (e.g., SDK version) for the project.
  final Environment? environment;

  /// A map of runtime dependencies (`package:version`).
  final Map<String, String>? dependencies;

  /// A map of development dependencies (`package:version`).
  final Map<String, String>? devDependencies;

  /// Creates a new [Pubspec] instance with the given values.
  ///
  /// All fields are optional, but [topics] and [keywords] default to empty lists
  /// if not provided.
  /// 
  /// {@macro pubspec}
  const Pubspec({
    required this.name,
    required this.description,
    required this.version,
    required this.homepage,
    required this.repository,
    required this.issueTracker,
    required this.documentation,
    required this.topics,
    required this.keywords,
    required this.environment,
    required this.dependencies,
    required this.devDependencies,
  });

  /// Creates a new [Pubspec] instance by copying the current instance and
  /// optionally overriding selected fields.
  ///
  /// Useful for immutably updating pubspec data without modifying the original
  /// instance.
  ///
  /// ### Example
  /// ```dart
  /// final updated = pubspec.copyWith(version: "1.0.1");
  /// print(updated.version); // "1.0.1"
  /// ```
  Pubspec copyWith({
    String? name,
    String? description,
    String? version,
    String? homepage,
    String? repository,
    String? issueTracker,
    String? documentation,
    List<String>? topics,
    List<String>? keywords,
    Environment? environment,
    Map<String, String>? dependencies,
    Map<String, String>? devDependencies,
  }) {
    return Pubspec(
      name: name ?? this.name,
      description: description ?? this.description,
      version: version ?? this.version,
      homepage: homepage ?? this.homepage,
      repository: repository ?? this.repository,
      issueTracker: issueTracker ?? this.issueTracker,
      documentation: documentation ?? this.documentation,
      topics: topics ?? this.topics,
      keywords: keywords ?? this.keywords,
      environment: environment ?? this.environment,
      dependencies: dependencies ?? this.dependencies,
      devDependencies: devDependencies ?? this.devDependencies,
    );
  }

  /// Creates a [Pubspec] instance from a JSON map.
  ///
  /// Converts JSON keys to the corresponding fields in [Pubspec], including
  /// nested [Environment] if provided.
  ///
  /// ### Example
  /// ```dart
  /// final json = {
  ///   "name": "my_app",
  ///   "version": "1.0.0",
  ///   "topics": ["server", "jetleaf"],
  /// };
  /// final pubspec = Pubspec.fromJson(json);
  /// print(pubspec.name); // "my_app"
  /// ```
  factory Pubspec.fromJson(Map<String, dynamic> json) {
    return Pubspec(
      name: json["name"] as String?,
      description: json["description"] as String?,
      version: json["version"] as String?,
      homepage: json["homepage"] as String?,
      repository: json["repository"] as String?,
      issueTracker: json["issue_tracker"] as String?,
      documentation: json["documentation"] as String?,
      topics: json["topics"] == null
          ? []
          : List<String>.from(json["topics"]!.map((x) => x)),
      keywords: json["keywords"] == null
          ? []
          : List<String>.from(json["keywords"]!.map((x) => x)),
      environment: json["environment"] == null
          ? null
          : Environment.fromJson(json["environment"]),
      dependencies: json["dependencies"] == null
          ? null
          : Map<String, String>.from(json["dependencies"]),
      devDependencies: json["dev_dependencies"] == null
          ? null
          : Map<String, String>.from(json["dev_dependencies"]),
    );
  }
}