import 'latest.dart';

/// {@template package}
/// Represents a Dart/Jetleaf package with its latest release and all available versions.
///
/// The [Package] class holds the package's name, the [Latest] release,
/// and a list of all version releases.
///
/// ### Example
/// ```dart
/// final package = Package(
///   name: "my_app",
///   latest: Latest(version: "1.0.0", pubspec: ..., archiveUrl: ..., archiveSha256: ..., published: DateTime.now()),
///   versions: [
///     Latest(version: "0.9.0", pubspec: ..., archiveUrl: ..., archiveSha256: ..., published: DateTime.now()),
///     Latest(version: "1.0.0", pubspec: ..., archiveUrl: ..., archiveSha256: ..., published: DateTime.now()),
///   ],
/// );
/// print(package.name); // "my_app"
/// print(package.latest?.version); // "1.0.0"
/// ```
/// {@endtemplate}
final class Package {
  /// The name of the package.
  final String? name;

  /// The latest release of the package.
  final Latest? latest;

  /// All available versions of the package, including [latest].
  final List<Latest> versions;

  /// Creates a new [Package] instance with the given properties.
  /// 
  /// {@macro package}
  const Package({
    required this.name,
    required this.latest,
    required this.versions,
  });

  /// Creates a copy of this [Package] with optional overridden values.
  ///
  /// Useful for immutably updating fields without modifying the original instance.
  ///
  /// ### Example
  /// ```dart
  /// final updated = package.copyWith(name: "new_name");
  /// print(updated.name); // "new_name"
  /// ```
  Package copyWith({
    String? name,
    Latest? latest,
    List<Latest>? versions,
  }) {
    return Package(
      name: name ?? this.name,
      latest: latest ?? this.latest,
      versions: versions ?? this.versions,
    );
  }

  /// Creates a [Package] instance from a JSON map.
  ///
  /// Converts nested [Latest] JSON objects into proper [Latest] instances.
  ///
  /// ### Example
  /// ```dart
  /// final json = {
  ///   "name": "my_app",
  ///   "latest": { "version": "1.0.0", "pubspec": { ... }, "archive_url": "...", "archive_sha256": "...", "published": "2025-11-22T10:00:00Z" },
  ///   "versions": [
  ///     { "version": "0.9.0", "pubspec": { ... }, "archive_url": "...", "archive_sha256": "...", "published": "2025-10-01T10:00:00Z" }
  ///   ]
  /// };
  /// final package = Package.fromJson(json);
  /// print(package.latest?.version); // "1.0.0"
  /// ```
  factory Package.fromJson(Map<String, dynamic> json) {
    return Package(
      name: json["name"] as String?,
      latest: json["latest"] == null ? null : Latest.fromJson(json["latest"]),
      versions: json["versions"] == null
          ? []
          : List<Latest>.from(json["versions"]!.map((x) => Latest.fromJson(x))),
    );
  }
}