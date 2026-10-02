import 'dart:convert';

import 'package:jetleaf/core.dart';
import 'package:jetleaf/env.dart';
import 'package:jetleaf_monitor/jetleaf_monitor.dart';
import 'package:jetleaf_web/jetleaf_web.dart';

import '../models/package_group.dart';
import 'package_service.dart';
import '../models/package.dart';

/// {@template jetleaf_package_implementation}
/// Concrete implementation of [PackageService] that fetches package metadata
/// from **pub.dev** using an HTTP REST client.
///
/// [PackageImplementation] provides:
/// - Retrieval of a single package by name  
/// - Retrieval of a predefined set of Jetleaf-related packages  
/// - A convenience method for fetching the core `jetleaf` package
///
/// This class is annotated with Jetleaf DI annotations:
/// - `@Primary` — preferred implementation for injection  
/// - `@Component` — registered as a component in the container  
/// - `@RequiredAll` — all constructor parameters are required
///
/// ### Usage Example
/// ```dart
/// final client = RestClient();
/// final service = PackageImplementation(client);
///
/// // Fetch a single package
/// final result = await service.getPackage("jetleaf_core");
/// final package = result.getBody();
/// print(package?.name); // "jetleaf_core"
///
/// // Fetch all Jetleaf packages
/// final allPackagesResult = await service.getPackages();
/// final packages = allPackagesResult.getBody();
/// print(packages.length); // 6
///
/// // Fetch the core Jetleaf package
/// final jetleafPackage = await service.getJetleaf();
/// print(jetleafPackage.getBody()?.name); // "jetleaf"
/// ```
///
/// ### Design Notes
/// - All methods return a [ResponseBody], which encapsulates the HTTP status
///   and optional payload.  
/// - Uses a hard-coded list of Jetleaf packages for `getPackages()`.  
/// - Performs JSON decoding and mapping to [Package] objects.  
/// - Handles missing packages by returning `ResponseBody.notFound()`.  
/// - Designed for development tooling and integration with Jetleaf’s web
///   components.
///
/// ### See Also
/// - [PackageService] — the abstract interface  
/// - [Package] — package metadata model  
/// - [RestClient] — HTTP client used for API requests  
/// {@endtemplate}
@Monitor()
@Primary()
@Component()
@RequiredAll()
class PackageImplementation implements PackageService {
  /// The HTTP client used to perform requests to the Pub API.
  final RestClient _client;

  /// {@macro jetleaf_package_implementation}
  PackageImplementation(this._client);

  @override
  Future<ResponseBody<Package?>> getPackage(String packageName) async {
    final result = await _client.get()
      .url("https://pub.dev/api/packages/$packageName")
      .execute((response) => response.getBody().readAsString());

    if (result != null) {
      try {
        final json = jsonDecode(result);
        if (json is Map) {
          return ResponseBody.of(HttpStatus.OK, Package.fromJson(Map<String, dynamic>.from(json)));
        }
      } catch (_) {}
    }

    return ResponseBody.notFound();
  }

  @override
  Future<ResponseBody<List<PackageGroup>>> getPackages() async {
    // Define groups and which package names belong to each
    final groups = (jsonDecode(Env<String>("PACKAGES").value()) as Map).map((key, value) => MapEntry(key as String, List<String>.from(value)));
    final packageGroups = <PackageGroup>[];

    // Iterate over each group
    for (final entry in groups.entries) {
      final groupName = entry.key;
      final packageNames = entry.value;
      final packages = <Package>[];

      for (final packageName in packageNames) {
        final result = await getPackage(packageName);
        final package = result.getBody();

        if (package != null) {
          packages.add(package);
        }
      }

      // Only add non-empty groups
      if (packages.isNotEmpty) {
        packageGroups.add(PackageGroup(groupName, packages));
      }
    }

    return ResponseBody(HttpStatus.OK, packageGroups);
  }
  
  @override
  Future<ResponseBody<Package?>> getJetleaf() => getPackage("jetleaf");
}