part of 'asset_resource.dart';

/// {@template default_asset_path_resource}
/// Default implementation of [AssetPathResource] that resolves assets
/// from the runtime environment using a path or filename.
///
/// This class attempts to locate an asset in multiple ways:
/// 1. **Exact path match** – Compares against each asset’s full path.
/// 2. **Filename match** – Matches only the filename if the full path fails.
/// 3. **Normalized path match** – Handles platform-specific differences
///    like `file://` prefixes and `\` vs `/`.
/// 4. **Suffix match** – Matches by the tail end of the path if needed.
/// 5. **Single filename candidate** – If exactly one candidate matches the filename.
///
/// Once resolved, the asset is cached internally for efficient access.
///
/// ### Example
/// ```dart
/// final resource = DefaultAssetPathResource("assets/config/settings.yaml");
///
/// if (resource.exists()) {
///   print("Found: ${resource.getFileName()}");
///   final bytes = resource.getContentBytes();
///   print("Content length: ${bytes.length}");
/// } else {
///   print("Asset not found");
/// }
/// ```
/// {@endtemplate}
@internal
final class DefaultAssetPathResource implements AssetPathResource {
  Asset? _asset;

  /// The original path string used to resolve this resource.
  final String path;

  /// {@macro default_asset_path_resource}
  DefaultAssetPathResource(this.path) {
    try {
      _asset = _resolveAsset(path);
    } catch (_) {}
  }

  /// Attempts to resolve an [Asset] given a path string.
  ///
  /// Resolution is performed in multiple steps:
  /// - Exact match by file path.
  /// - Match by file name.
  /// - Normalized path comparison.
  /// - Suffix match for partial paths.
  /// - Fallback to unique filename match.
  ///
  /// Returns `null` if no matching asset is found.
  Asset? _resolveAsset(String path) {
    final allAssets = Runtime.getAllAssets();

    String normalize(String p) {
      var normalized = p;
      if (normalized.startsWith('file://')) {
        normalized = normalized.substring(7);
      }
      return normalized.replaceAll('\\', '/');
    }

    final normalizedPath = normalize(path);

    // --- 1️⃣ Exact path match ---
    for (final ast in allAssets) {
      if (normalize(ast.getFilePath()) == normalizedPath) {
        return ast;
      }
    }

    // --- 2️⃣ Try implicit HTML extension ---
    // e.g. /forgot-password → /forgot-password.html
    if (!normalizedPath.contains('.') && !normalizedPath.endsWith('/')) {
      final htmlCandidate = "$normalizedPath.html";
      for (final ast in allAssets) {
        if (normalize(ast.getFilePath()).endsWith(htmlCandidate)) {
          return ast;
        }
      }
    }

    // --- 3️⃣ Try suffix match (e.g. "resources/.../forgot-password.html") ---
    for (final ast in allAssets) {
      if (normalize(ast.getFilePath()).endsWith(normalizedPath)) {
        return ast;
      }
    }

    // --- 4️⃣ Filename match fallback ---
    final fileName = normalizedPath.split('/').last;
    final candidates = allAssets.where((ast) => ast.getFileName() == fileName).toList();
    if (candidates.length == 1) {
      return candidates.first;
    }

    // --- 5️⃣ Implicit HTML by filename ---
    final htmlFileName = "$fileName.html";
    final htmlCandidates = allAssets.where((ast) => ast.getFileName() == htmlFileName).toList();
    if (htmlCandidates.length == 1) {
      return htmlCandidates.first;
    }

    // --- Not found ---
    return null;
  }

  Exception _throwIfNotFound([String? name]) => IllegalStateException("${name ?? 'Asset'} for $path not found");
  
  @override
  bool exists() => _asset != null;

  @override
  Asset get([Supplier<Exception>? throwIfNotFound]) {
    if(_asset != null) {
      return _asset!;
    } else if(throwIfNotFound != null) {
      throw throwIfNotFound();
    } else {
      throw _throwIfNotFound();
    }
  }

  @override
  Uint8List getContentBytes() {
    if(exists()) {
      return _asset!.getContentBytes();
    }

    throw _throwIfNotFound();
  }

  @override
  String getFileName() {
    if(exists()) {
      return _asset!.getFileName();
    }

    throw _throwIfNotFound();
  }

  @override
  String getFilePath() {
    if(exists()) {
      return _asset!.getFilePath();
    }

    throw _throwIfNotFound();
  }

  @override
  String? getPackageName() {
    if(exists()) {
      return _asset!.getPackageName();
    }

    throw _throwIfNotFound();
  }

  @override
  String getUniqueName() {
    if(exists()) {
      return _asset!.getUniqueName();
    }

    throw _throwIfNotFound();
  }

  @override
  bool hasExtension(List<String> exts) {
    if(exists()) {
      return exts.any((e) => _asset!.getFilePath().containsIgnoreCase(e));
    }

    throw _throwIfNotFound();
  }

  @override
  Map<String, Object> toJson() {
    if(exists()) {
      return _asset!.toJson();
    }

    throw _throwIfNotFound();
  }

  @override
  Asset? tryGet([Supplier<Exception>? orElseThrow]) {
    if(_asset != null) {
      return _asset!;
    } else if(orElseThrow != null) {
      throw orElseThrow();
    } else {
      return null;
    }
  }

  @override
  InputStream getInputStream() {
    if(_asset != null) {
      return ByteArrayInputStream(_asset!.getContentBytes());
    }

    throw _throwIfNotFound();
  }
  
  @override
  List<Object?> equalizedProperties() => _asset?.equalizedProperties() ?? [DefaultAssetPathResource];
  
  @override
  String getContentAsString() => _asset?.getContentAsString() ?? "";
  
  @override
  String getResourcePath() => _asset?.getFilePath() ?? "";
  
  @override
  void serialize(BinaryBuilder builder) { }
}

/// {@template file_asset_path_resource}
/// A file-based implementation of [AssetPathResource] that loads assets directly
/// from the local file system using [File] from `dart:io`.
///
/// This class attempts to locate and load a file from disk using the provided
/// [path]. If the file does not exist locally, it can optionally fall back to
/// the Jetleaf [AssetLoader] for bundled resources.
///
/// ### Example
/// ```dart
/// final resource = FileAssetPathResource('/app/assets/templates/home.html');
///
/// if (resource.exists()) {
///   print('File: ${resource.getFileName()}');
///   print('Size: ${resource.getContentBytes().length} bytes');
/// } else {
///   print('Resource not found');
/// }
/// ```
///
/// ### Features
/// - Supports file system assets and Jetleaf-bundled assets.
/// - Automatically normalizes paths.
/// - Provides consistent API with [DefaultAssetPathResource].
/// - Lazy loads content for efficiency.
/// {@endtemplate}
@internal
final class FileAssetPathResource implements AssetPathResource {
  /// The absolute or relative file path to resolve.
  final String path;

  /// Cached file instance.
  late final File _file = File(_normalizePath(path));

  /// Cached file content (lazy-loaded).
  Uint8List? _cachedBytes;

  /// Optional fallback loader (for bundled assets).
  AssetLoaderInterface? assetLoader;

  final AssetLoaderInterface _assetLoader;
  _FileSystemAsset? _asset;

  /// {@macro file_asset_path_resource}
  FileAssetPathResource(this.path, [this.assetLoader]) 
    : _assetLoader = assetLoader ?? jetLeafAssetLoader
  {
    if (exists()) {
      _asset = _FileSystemAsset(_file);
    }

    // Try fallback loader
    try {
      final content = File(_normalizePath(path));
      if (content.existsSync()) {
        _asset = _FileSystemAsset(content);
      }
    } catch (_) {}
  }

  /// Normalizes the file path for consistent cross-platform access.
  String _normalizePath(String input) {
    var p = input.trim();
    if (p.startsWith('file://')) {
      p = p.substring(7);
    }
    return p.replaceAll('\\', '/');
  }

  Exception _throwIfNotFound([String? name]) => IllegalStateException("${name ?? 'File'} not found at path: $path");

  /// Checks if the file exists on the local file system or via the loader.
  @override
  bool exists() {
    try {
      return _file.existsSync();
    } catch (_) {
      return false;
    }
  }

  /// Attempts to retrieve the file as an [Asset].
  ///
  /// Converts the file into an [Asset]-like structure compatible with
  /// the Jetleaf ecosystem.
  @override
  Asset get([Supplier<Exception>? throwIfNotFound]) {
    if (_asset case final asset?) {
      return asset;
    }

    throw throwIfNotFound?.call() ?? _throwIfNotFound();
  }

  /// Returns the file contents as raw bytes.
  @override
  Uint8List getContentBytes() {
    if (_cachedBytes != null) return _cachedBytes!;

    if (exists()) {
      _cachedBytes = _file.readAsBytesSync();
      return _cachedBytes!;
    }

    // Fallback to Jetleaf bundler
    try {
      final data = Closeable.DEFAULT_ENCODING.encode(_assetLoader.load(path).toString());
      _cachedBytes = Uint8List.fromList(data);
      return _cachedBytes!;
    } catch (_) {
      throw _throwIfNotFound();
    }
  }

  @override
  String getFileName() => path.split('/').last;

  @override
  String getFilePath() => _file.path;

  @override
  String? getPackageName() => _assetLoader.packageName;

  @override
  String getUniqueName() => "file://${getPackageName() ?? 'local'}:${_normalizePath(path)}";

  @override
  bool hasExtension(List<String> exts) {
    final lowerPath = path.toLowerCase();
    return exts.any((e) => lowerPath.endsWith(e.toLowerCase()));
  }

  @override
  InputStream getInputStream() {
    if (exists()) {
      return ByteArrayInputStream(getContentBytes());
    }

    throw _throwIfNotFound();
  }

  @override
  Map<String, Object> toJson() {
    if (!exists()) throw _throwIfNotFound();

    return {
      "type": "file",
      "path": getFilePath(),
      "name": getFileName(),
      "package": getPackageName() ?? "local",
      "uniqueName": getUniqueName(),
      "size": _file.existsSync() ? _file.lengthSync() : 0,
    };
  }

  @override
  Asset? tryGet([Supplier<Exception>? orElseThrow]) {
    if (exists()) {
      return _FileSystemAsset(_file);
    }
    return null;
  }

  @override
  List<Object?> equalizedProperties() => _asset?.equalizedProperties() ?? [DefaultAssetPathResource];
  
  @override
  String getContentAsString() => _asset?.getContentAsString() ?? "";
  
  @override
  String getResourcePath() => _asset?.getFilePath() ?? "";

  @override
  void serialize(BinaryBuilder builder) { }
}

/// Internal adapter for treating a local [File] as an [Asset].
class _FileSystemAsset extends GenerativeAsset {
  final File file;

  _FileSystemAsset(this.file);

  @override
  String getFilePath() => file.path;

  @override
  String getFileName() => file.uri.pathSegments.isNotEmpty
      ? file.uri.pathSegments.last
      : file.path.split('/').last;

  @override
  String getUniqueName() => 'file://${file.absolute.path}';

  @override
  String? getPackageName() => 'local';

  @override
  Uint8List getContentBytes() => file.readAsBytesSync();

  @override
  Map<String, Object> toJson() => {
    'type': 'file',
    'path': file.path,
    'name': getFileName(),
    'size': file.existsSync() ? file.lengthSync() : 0,
  };
}

/// {@template jetleaf_default_asset_builder}
/// Default implementation of [AssetBuilder] used by Jetleaf to construct
/// [Asset] instances from a given template path.
///
/// This builder automatically determines the most appropriate asset source:
///
/// 1. **Runtime-resolved assets** – If the asset exists in the current
///    runtime registry (via [Runtime.getAllAssets]), it will be loaded
///    using [DefaultAssetPathResource].
///
/// 2. **File system assets** – If the runtime lookup fails, it will
///    fall back to [FileAssetPathResource], which attempts to load
///    the asset directly from the local file system using `dart:io`.
///
/// 3. **Bundled package assets** – When the file does not exist locally,
///    [FileAssetPathResource] may also delegate to the configured
///    [AssetLoaderInterface] (e.g., [jetLeafAssetLoader]) to locate
///    and load bundled resources.
///
/// This design provides a transparent, hierarchical resolution strategy
/// for assets, supporting both **development-time** and **runtime**
/// asset access seamlessly.
///
/// ### Example
/// ```dart
/// final builder = DefaultAssetBuilder();
/// final asset = builder.build('templates/page.html');
///
/// print(asset.getFileName()); // -> page.html
/// print(asset.getFilePath()); // -> assets/templates/page.html or bundle path
/// ```
///
/// You can optionally inject a custom [AssetLoaderInterface] to control
/// how package assets are resolved:
///
/// ```dart
/// final customBuilder = DefaultAssetBuilder(
///   AssetLoader.forPackage('my_app'),
/// );
/// ```
/// {@endtemplate}
@internal
final class DefaultAssetBuilder implements AssetBuilder {
  /// Optional asset loader for bundled or package-level assets.
  final AssetLoaderInterface? assetLoader;

  /// {@macro jetleaf_default_asset_builder}
  const DefaultAssetBuilder([this.assetLoader]);

  @override
  AssetPathResource build(String template) {
    try {
      // Attempt runtime asset resolution first.
      return DefaultAssetPathResource(template);
    } catch (_) {
      // Fallback to file system or package-based loading.
      return FileAssetPathResource(template, assetLoader);
    }
  }

  @override
  List<Object?> equalizedProperties() => [DefaultAssetBuilder];
}