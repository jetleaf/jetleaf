import 'pubspec.dart';

/// {@template latest}
/// Represents the latest release of a Dart/Jetleaf package.
///
/// The [Latest] class contains metadata about a specific published version,
/// including its [Pubspec] information, archive URL, hash, and publication date.
///
/// ### Example
/// ```dart
/// final latest = Latest(
///   version: "1.0.0",
///   pubspec: Pubspec(
///     name: "my_app",
///     description: "A sample Jetleaf application",
///     version: "1.0.0",
///     homepage: "https://example.com",
///     repository: "https://github.com/example/my_app",
///     issueTracker: "https://github.com/example/my_app/issues",
///     documentation: "https://docs.example.com/my_app",
///     topics: ["server", "jetleaf", "backend"],
///     keywords: ["jetleaf", "dart", "server"],
///     environment: Environment(sdk: "3.3.0"),
///     dependencies: {"jetleaf_core": "^1.0.0"},
///     devDependencies: {"test": "^1.21.0"},
///   ),
///   archiveUrl: "https://pub.dev/packages/my_app/versions/1.0.0.tar.gz",
///   archiveSha256: "abc123...",
///   published: DateTime.parse("2025-11-22T10:00:00Z"),
/// );
/// ```
/// {@endtemplate}
final class Latest {
  /// The version string of this release (e.g., "1.0.0").
  final String? version;

  /// The [Pubspec] metadata for this release.
  final Pubspec? pubspec;

  /// The URL to the archive file (e.g., `.tar.gz`) for this release.
  final String? archiveUrl;

  /// The SHA-256 checksum of the archive file.
  final String? archiveSha256;

  /// The publication date of this release.
  final DateTime? published;

  /// Creates a new [Latest] release instance with the given properties.
  /// 
  /// {@macro latest}
  const Latest({
    required this.version,
    required this.pubspec,
    required this.archiveUrl,
    required this.archiveSha256,
    required this.published,
  });

  /// Creates a copy of this [Latest] instance with optional overridden values.
  ///
  /// Useful for immutably updating fields without modifying the original instance.
  ///
  /// ### Example
  /// ```dart
  /// final updated = latest.copyWith(version: "1.0.1");
  /// print(updated.version); // "1.0.1"
  /// ```
  Latest copyWith({
    String? version,
    Pubspec? pubspec,
    String? archiveUrl,
    String? archiveSha256,
    DateTime? published,
  }) {
    return Latest(
      version: version ?? this.version,
      pubspec: pubspec ?? this.pubspec,
      archiveUrl: archiveUrl ?? this.archiveUrl,
      archiveSha256: archiveSha256 ?? this.archiveSha256,
      published: published ?? this.published,
    );
  }

  /// Creates a [Latest] instance from a JSON map.
  ///
  /// Converts nested [Pubspec] JSON and parses [published] as a [DateTime].
  ///
  /// ### Example
  /// ```dart
  /// final json = {
  ///   "version": "1.0.0",
  ///   "pubspec": { "name": "my_app", "version": "1.0.0" },
  ///   "archive_url": "https://pub.dev/packages/my_app/versions/1.0.0.tar.gz",
  ///   "archive_sha256": "abc123",
  ///   "published": "2025-11-22T10:00:00Z"
  /// };
  /// final latest = Latest.fromJson(json);
  /// print(latest.version); // "1.0.0"
  /// ```
  factory Latest.fromJson(Map<String, dynamic> json) {
    return Latest(
      version: json["version"] as String?,
      pubspec: json["pubspec"] == null ? null : Pubspec.fromJson(json["pubspec"]),
      archiveUrl: json["archive_url"] as String?,
      archiveSha256: json["archive_sha256"] as String?,
      published: DateTime.tryParse(json["published"] ?? ""),
    );
  }
}