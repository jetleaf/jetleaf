import '../../lang.dart';

/// {@template version}
/// Represents a semantic version in **Jetleaf** with major, minor, and patch 
/// components.
///
/// This class is used to define precise versions and to compare versions when 
/// evaluating version ranges or conditional processing.
///
/// ### Usage Example:
/// ```dart
/// final version = Version(3, 1, 4);
/// final other = Version.parse('3.2.0');
///
/// print(version < other); // true
/// print(version >= Version(3,1,0)); // true
/// ```
/// {@endtemplate}
class Version with EqualsAndHashCode implements Comparable<Version> {
  /// The major version component.
  final int major;

  /// The minor version component.
  final int minor;

  /// The patch version component.
  final int patch;

  /// {@macro version}
  const Version(this.major, this.minor, this.patch);

  /// Parses a version string (e.g., '3.1.4') into a [Version] instance.
  ///
  /// Missing minor or patch components default to 0.
  ///
  /// ### Example:
  /// ```dart
  /// final version = Version.parse('3.2'); // Version(3, 2, 0)
  /// ```
  factory Version.parse(String version) {
    final parts = version.split('.');
    return Version(
      int.parse(parts[0]),
      parts.length > 1 ? int.parse(parts[1]) : 0,
      parts.length > 2 ? int.parse(parts[2]) : 0,
    );
  }

  /// Returns `true` if this version is greater than or equal to [other].
  bool operator >=(Version other) => compareTo(other) >= 0;

  /// Returns `true` if this version is less than or equal to [other].
  bool operator <=(Version other) => compareTo(other) <= 0;

  /// Returns `true` if this version is strictly greater than [other].
  bool operator >(Version other) => compareTo(other) > 0;

  /// Returns `true` if this version is strictly less than [other].
  bool operator <(Version other) => compareTo(other) < 0;

  @override
  int compareTo(Version other) {
    if (major != other.major) return major - other.major;
    if (minor != other.minor) return minor - other.minor;
    return patch - other.patch;
  }

  @override
  List<Object?> equalizedProperties() => [major, minor, patch];

  @override
  String toString() => '$major.$minor.$patch';
}