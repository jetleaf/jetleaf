/// {@template environment}
/// Represents the runtime environment of a Jetleaf application.
///
/// The [Environment] class holds important metadata about the application's
/// runtime, including the Dart SDK version and other environment-specific
/// properties. This class is often injected into pods or services that need
/// to adapt behavior based on the runtime context.
///
/// The environment can be **serialized from JSON**, copied with modified
/// properties, or inspected at runtime to make decisions dynamically.
///
/// ### Example
/// ```dart
/// final env = Environment(sdk: "3.3.0");
/// print(env.sdk); // "3.3.0"
/// ```
///
/// Use [copyWith] to create a modified environment without mutating the
/// original instance:
/// ```dart
/// final updated = env.copyWith(sdk: "3.4.0");
/// print(updated.sdk); // "3.4.0"
/// ```
///
/// Use [fromJson] and [toJson] when reading or writing environment
/// configuration from JSON files, API responses, or persisted storage:
/// ```dart
/// final json = {"sdk": "3.2.0"};
/// final env = Environment.fromJson(json);
/// print(env.toJson()); // {"sdk": "3.2.0"}
/// ```
/// {@endtemplate}
final class Environment {
  /// The Dart SDK version for this environment.
  ///
  /// This is typically the value returned by `Platform.version` at runtime,
  /// but can also be overridden during configuration or testing.
  final String? sdk;

  /// {@macro environment}
  const Environment({required this.sdk});

  /// Creates a new [Environment] instance by copying the current instance
  /// and optionally overriding selected properties.
  ///
  /// This is useful when you want to modify part of the environment without
  /// changing the original instance (immutability pattern).
  ///
  /// ### Example
  /// ```dart
  /// final env = Environment(sdk: "3.3.0");
  /// final updated = env.copyWith(sdk: "3.4.0");
  /// print(updated.sdk); // "3.4.0"
  /// ```
  Environment copyWith({String? sdk}) {
    return Environment(sdk: sdk ?? this.sdk);
  }

  /// Creates a new [Environment] instance from a JSON map.
  ///
  /// This is typically used when loading environment configuration from
  /// external sources such as configuration files, API responses, or
  /// persisted storage.
  ///
  /// ### Example
  /// ```dart
  /// final json = {"sdk": "3.2.0"};
  /// final env = Environment.fromJson(json);
  /// print(env.sdk); // "3.2.0"
  /// ```
  factory Environment.fromJson(Map<String, dynamic> json) {
    return Environment(sdk: json["sdk"] as String?);
  }
}