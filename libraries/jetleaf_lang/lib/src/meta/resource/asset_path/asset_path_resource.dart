part of 'asset_resource.dart';

/// {@template asset_path_resource}
/// Represents a resource that can be loaded from a path-based asset.
///
/// Implementations of [AssetPathResource] provide ways to:
/// - Check whether the resource exists.
/// - Retrieve the asset or throw an exception if not found.
/// - Safely attempt retrieval without forcing an exception.
/// - Validate the file extension against a given list.
///
/// This is useful for handling project assets such as configuration
/// files, templates, or bundled resources in a structured way.
///
/// ### Example
/// ```dart
/// class ConfigFileResource extends AssetPathResource {
///   final String path;
///
///   const ConfigFileResource(this.path) : super(path);
///
///   @override
///   bool exists() => path.endsWith(".json");
///
///   @override
///   Asset get([Supplier<Exception>? throwIfNotFound]) {
///     if (!exists()) {
///       if (throwIfNotFound != null) throw throwIfNotFound();
///       throw Exception("Asset not found: $path");
///     }
///     return this; // Example only
///   }
///
///   @override
///   Asset? tryGet([Supplier<Exception>? orElseThrow]) =>
///       exists() ? this : null;
///
///   @override
///   bool hasExtension(List<String> exts) =>
///       exts.any((ext) => path.endsWith(ext));
/// }
/// ```
/// {@endtemplate}
abstract class AssetPathResource implements Asset, InputStreamSource {
  /// {@macro asset_path_resource}
  factory AssetPathResource(String path) = DefaultAssetPathResource;

  /// {@macro asset_path_resource}
  factory AssetPathResource.file(String path, [AssetLoaderInterface? assetLoader]) = FileAssetPathResource;

  /// {@template asset_path_resource_exists}
  /// Checks whether the underlying resource exists.
  ///
  /// Returns `true` if the asset is available, otherwise `false`.
  ///
  /// ### Example
  /// ```dart
  /// if (resource.exists()) {
  ///   print("Asset is available!");
  /// }
  /// ```
  /// {@endtemplate}
  bool exists();

  /// {@template asset_path_resource_get}
  /// Retrieves the asset represented by this resource.
  ///
  /// - If the asset does not exist and [throwIfNotFound] is provided,
  ///   the supplied exception will be thrown.
  /// - If [throwIfNotFound] is not provided, a generic exception may be thrown.
  ///
  /// ### Example
  /// ```dart
  /// try {
  ///   final asset = resource.get(() => Exception("Missing resource"));
  ///   print("Loaded: $asset");
  /// } catch (e) {
  ///   print("Failed to load asset: $e");
  /// }
  /// ```
  /// {@endtemplate}
  Asset get([Supplier<Exception>? throwIfNotFound]);

  /// {@template asset_path_resource_try_get}
  /// Attempts to retrieve the asset safely.
  ///
  /// - If the asset exists, it is returned.
  /// - If the asset does not exist, returns `null` instead of throwing,
  ///   unless [orElseThrow] is provided, in which case the supplied
  ///   exception will be thrown.
  ///
  /// ### Example
  /// ```dart
  /// final asset = resource.tryGet();
  /// if (asset != null) {
  ///   print("Asset loaded successfully");
  /// } else {
  ///   print("Asset not found");
  /// }
  /// ```
  /// {@endtemplate}
  Asset? tryGet([Supplier<Exception>? orElseThrow]);

  /// {@template asset_path_resource_has_extension}
  /// Checks whether the asset’s path ends with any of the provided extensions.
  ///
  /// This is useful for filtering specific types of files
  /// (e.g., `.json`, `.yaml`, `.properties`).
  ///
  /// ### Example
  /// ```dart
  /// if (resource.hasExtension([".json", ".yaml"])) {
  ///   print("This is a supported config file");
  /// }
  /// ```
  /// {@endtemplate}
  bool hasExtension(List<String> exts);

  /// {@template asset_path_resource_get_resource_path}
  /// Returns the underlying file system path for this resource.
  ///
  /// This is a convenience method that delegates to [getFilePath].
  ///
  /// ### Example
  /// ```dart
  /// print("Resource path: ${resource.getResourcePath()}");
  /// ```
  /// {@endtemplate}
  String getResourcePath() => getFilePath();
}

/// {@template jetleaf_asset_builder}
/// Defines a contract for classes that build [Asset] instances from a
/// given template identifier.
///
/// An [AssetBuilder] is responsible for transforming a template string
/// or path into an actual [Asset] representation used by the system.
///
/// ### Usage Example
/// ```dart
/// final builder = DefaultAssetBuilder();
/// final asset = builder.build('templates/main.html');
/// ```
///
/// ### Design Notes
/// - Implementations should provide a deterministic `build` method
///   returning an [Asset] instance.
/// - Can be extended or replaced with custom asset resolution strategies.
/// {@endtemplate}
abstract interface class AssetBuilder with EqualsAndHashCode {
  /// Builds an [Asset] based on the provided [template] identifier.
  AssetPathResource build(String template);

  /// {@macro jetleaf_asset_builder}
  factory AssetBuilder([AssetLoaderInterface? assetLoader]) = DefaultAssetBuilder;
}