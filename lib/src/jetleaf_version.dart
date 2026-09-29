import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_utils/utils.dart';

/// {@template jetleaf_version}
/// A utility class for retrieving the current version of the Jetleaf framework.
///
/// This class provides a static method to access the version of Jetleaf from
/// the package metadata. The version is typically defined in the `pubspec.yaml`
/// of the main application package (referenced via [PackageNames.MAIN]).
///
/// ### Key Points
/// 1. **Static Access Only:** This class cannot be instantiated; use [getVersion] directly.
/// 2. **Source of Truth:** The version is read from the package metadata provided
///    by [PackageUtils.getPackage].
/// 3. **Fallback:** If the version cannot be resolved (for example, in AOT-compiled
///    binaries, test environments, or missing `pubspec.yaml`), `'Unknown'` is returned.
/// 4. **Use Cases:**
///    - Logging the Jetleaf version during application startup ([ApplicationCli], [Logger]).
///    - Embedding the version in CLI commands such as `jl --version` ([VersionCommandRunner]).
///    - Conditional execution of code based on framework version.
///
/// ### References
/// - [PackageUtils.getPackage] – Fetches the Dart package metadata for a given package name.
/// - [PackageNames.MAIN] – Represents the main application package containing the pubspec.
/// - [VersionCommandRunner] – CLI command that displays the current Jetleaf CLI version.
/// - [Logger] – Can be used to log the framework version during application startup.
///
/// ### Example
/// ```dart
/// import 'package:jetleaf_core/jetleaf_core.dart';
///
/// void main() {
///   final version = JetleafVersion.getVersion();
///   print('Jetleaf Framework Version: $version');
/// }
/// ```
///
/// {@endtemplate}
abstract final class JetleafVersion {
  /// Returns the current Jetleaf version as a [String].
  ///
  /// Attempts to read the version from the main package metadata. If the version
  /// cannot be determined due to missing metadata or AOT compilation, `'Unknown'` is returned.
  ///
  /// ### Example
  /// ```dart
  /// final version = JetleafVersion.getVersion();
  /// print('Running Jetleaf CLI version $version');
  /// ```
  static String getVersion() {
    try {
      final Package? package = PackageUtils.getPackage(PackageNames.MAIN);
      return package?.getVersion() ?? 'Unknown';
    } catch (e) {
      // In case of any error (e.g., package metadata not found), return Unknown
      return 'Unknown';
    }
  }
}