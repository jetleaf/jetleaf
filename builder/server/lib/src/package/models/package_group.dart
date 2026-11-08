import 'package.dart';

/// {@template package_group}
/// Represents a group of packages under a common [group] name.
///
/// The [PackageGroup] holds the group identifier and a list of [Package] instances
/// that belong to this group.
///
/// ### Example
/// ```dart
/// final group = PackageGroup(
///   "utilities",
///   [
///     Package(name: "http_client", latest: ..., versions: [...]),
///     Package(name: "json_parser", latest: ..., versions: [...]),
///   ],
/// );
/// print(group.group); // "utilities"
/// print(group.packages.length); // 2
/// ```
/// {@endtemplate}
final class PackageGroup {
  /// The identifier of this package group.
  final String group;

  /// The list of packages under this group.
  final List<Package> packages;

  /// Creates a new [PackageGroup] instance with the given [group] name
  /// and [packages].
  /// 
  /// {@macro package_group}
  const PackageGroup(this.group, this.packages);
}