import 'package:jetleaf/core.dart';
import 'package:jetleaf_resource/jetleaf_resource.dart';
import 'package:jetleaf_web/jetleaf_web.dart';

import 'models/package.dart';
import 'models/package_group.dart';
import 'services/package_service.dart';

/// {@template jetleaf_package_controller}
/// A REST controller exposing **package metadata endpoints** via HTTP.
///
/// [PackageController] delegates all operations to an underlying
/// [PackageService] implementation, providing:
/// - Retrieval of a single package by name  
/// - Retrieval of all known packages  
/// - Retrieval of the core `jetleaf` package
///
/// This controller is annotated for Jetleaf’s DI and web routing:
/// - `@RestController("/packages")` — base path for all endpoints  
/// - `@RequiredAll()` — all constructor parameters are required
///
/// ### HTTP Endpoints
/// | Method | Path                  | Description                       |
/// |--------|----------------------|-----------------------------------|
/// | GET    | `/packages/{package}` | Returns a single package by name  |
/// | GET    | `/packages`           | Returns all known packages        |
/// | GET    | `/packages/main`      | Returns the core `jetleaf` package |
///
/// ### Usage Example
/// ```bash
/// # Get a specific package
/// GET /packages/jetleaf_core
///
/// # Get all packages
/// GET /packages
///
/// # Get the main Jetleaf package
/// GET /packages/main
/// ```
///
/// ### Design Notes
/// - Delegates all logic to the injected [PackageService] for consistency
///   and testability.  
/// - Compatible with Jetleaf web framework for automatic routing.  
/// - Returns [ResponseBody] objects encapsulating HTTP status and payload.  
/// - Designed for development and production use.
///
/// ### See Also
/// - [PackageService] — abstract service interface  
/// - [Package] — data model representing package metadata  
/// - Jetleaf Web Framework and REST annotations  
/// {@endtemplate}
@RequiredAll()
@RestController("/packages")
class PackageController implements PackageService {
  /// The underlying service providing package data.
  final PackageService _packageService;

  /// {@macro jetleaf_package_controller}
  const PackageController(this._packageService);

  @override
  @GetMapping(path: "/{package}")
  @CachePut({"${ResourceUtils.PARAM_KEY}package"})
  @RateLimit({"packages"}, limit: 5, window: Duration(seconds: 10))
  Future<ResponseBody<Package?>> getPackage(@PathVariable() String package) => _packageService.getPackage(package);

  @override
  @GetMapping()
  @CachePut({"packages"})
  @RateLimit({"packages"}, limit: 5, window: Duration(seconds: 10))
  Future<ResponseBody<List<PackageGroup>>> getPackages() => _packageService.getPackages();
  
  @override
  @CachePut({"_packageMain"})
  @GetMapping(path: "/main")
  @RateLimit({"_packageMain"}, limit: 5, window: Duration(seconds: 10))
  Future<ResponseBody<Package?>> getJetleaf() => _packageService.getJetleaf();
}