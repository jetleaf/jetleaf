import 'package:jetleaf_web/jetleaf_web.dart';

import '../models/package.dart';
import '../models/package_group.dart';

/// {@template jetleaf_package_service}
/// A service interface for accessing **package metadata** within Jetleaf.
///
/// The [PackageService] provides methods to retrieve information about
/// individual packages or the full set of available packages.  
/// It is typically used in tooling, dependency management, and build pipelines.
///
/// Implementations may:
/// - Query a local package cache  
/// - Fetch remote package metadata  
/// - Integrate with the Jetleaf package registry or pub repositories
///
/// ### Usage Example
/// ```dart
/// final service = MyPackageService();
///
/// // Get a specific package
/// final package = await service.getPackage('jetleaf_core');
/// print(package.name);
///
/// // List all available packages
/// final allPackages = await service.getPackages();
/// print(allPackages.length);
/// ```
///
/// ### Design Notes
/// - All methods are asynchronous to allow network or disk-bound operations.  
/// - Implementations should handle caching and error handling as needed.  
/// - Methods return [Package] objects, which provide metadata such as
///   name, version, language version, and package location.
///
/// ### See Also
/// - [Package] — the data model representing a package  
/// - Jetleaf build and dependency management tooling  
/// {@endtemplate}
abstract interface class PackageService {
  /// Returns a [Package] for the given [packageName].
  ///
  /// Throws if the package cannot be found or retrieved.
  Future<ResponseBody<Package?>> getPackage(String packageName);

  /// Returns a list of all available [Package]s.
  ///
  /// May query local or remote repositories.
  Future<ResponseBody<List<PackageGroup>>> getPackages();

  /// Returns the Jetleaf package.
  /// 
  /// This is separated from other package methods [getPackages], [getPackage]
  Future<ResponseBody<Package?>> getJetleaf();
}