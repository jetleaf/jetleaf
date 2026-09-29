import 'package:jetleaf/lang.dart' show ClassNotFoundException, RuntimeProvider;
import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_lang/lang.dart';

import '../jetleaf_application_starter.dart';
import 'jetleaf_config_parser.dart';

/// {@template jetleaf_import_selector}
/// 🫘 Default [ImportSelector] implementation for Jetleaf.
///
/// `JetleafImportSelector` scans the runtime environment for all available
/// Jetleaf packages and selects their names as imports. This allows the
/// framework to automatically discover and register modules without
/// requiring manual import lists.
///
/// ## How it works
///
/// - Uses [RuntimeProvider.getAllPackages] from `jetleaf_lang`.
/// - Iterates through each package and retrieves its name via [package.getName].
/// - Returns a list of package names as strings.
///
/// ## Example
///
/// ```dart
/// void main() {
///   const selector = JetleafImportSelector();
///   final imports = selector.selects();
///
///   for (final pkg in imports) {
///     print('Discovered Jetleaf package: $pkg');
///   }
/// }
/// ```
///
/// ## Notes
///
/// - Always returns a list, which may be empty if no packages are available.
/// - Intended for use by Jetleaf’s startup and dependency resolution process.
///
/// See also:
/// - [ImportSelector] 🫘 for the interface contract.
/// - [ApplicationStartup] 🫘 for orchestrating startup logic.
/// 
/// {@endtemplate}
final class ApplicationImportSelector implements ImportSelector {
  /// Creates a constant [ApplicationImportSelector].
  /// 
  /// This selector is used by Jetleaf to automatically discover and register
  /// all available Jetleaf packages.
  /// 
  /// {@macro jetleaf_import_selector}
  const ApplicationImportSelector();

  @override
  List<ImportClass> selects() {
    final list = <ImportClass>[];

    if (Runtime.getAllPackages().firstWhereOrNull((package) => package.getIsRootPackage()) case final userPackage?) {
      list.add(ImportClass.package(userPackage.getName()));
    }

    // Load all assets
    bool isConfig(String path) => path.contains("meta-inf/") || path.contains("meta_config/") || path.contains("meta_inf/");
    final assets = Runtime.getAllAssets().where((asset) => isConfig(asset.getFilePath().toLowerCase()));
    List<Map<String, List<String>>> configurations = [];

    for (final asset in assets) {
      final parser = JetleafConfigParser();
      configurations.add(parser.parseAsset(asset));
    }

    for (final configuration in configurations) {
      final enableConfiguration = configuration[JetleafApplicationStarter.ENABLE_AUTO_CONFIGURATION_PROPERTY];
      final disableConfiguration = configuration[JetleafApplicationStarter.DISABLE_AUTO_CONFIGURATION_PROPERTY];

      if (enableConfiguration != null) {
        for (final item in enableConfiguration) {
          if (item.contains(".")) {
            try {
              list.add(ImportClass.forClass(Class.fromQualifiedName(item), false));
            } on ClassNotFoundException catch (_) {
              // Extract package name
              final packageName = _extractPackageName(item);
              list.add(ImportClass.package(packageName, false));
            }
          } else {
            list.add(ImportClass.package(item, false));
          }
        }
      }

      if (disableConfiguration != null) {
        for (final item in disableConfiguration) {
          if (item.contains(".")) {
            try {
              list.add(ImportClass.forClass(Class.fromQualifiedName(item), true));
            } catch (_) {
              // Extract package name
              final packageName = _extractPackageName(item);
              list.add(ImportClass.package(packageName, true));
            }
          } else {
            list.add(ImportClass.package(item, true));
          }
        }
      }
    }
    
    return list;
  }

  /// Extracts the package name from a package specification.
  /// 
  /// ## Example
  /// 
  /// ```dart
  /// final packageName = _extractPackageName("package:jetleaf_web");
  /// print(packageName); // "jetleaf_web"
  /// ```
  String _extractPackageName(String packageSpec) {
    if (packageSpec.startsWith("dart:")) {
      // For SDK imports, keep full spec up to first dot if any
      final dotIndex = packageSpec.indexOf(".");
      return dotIndex == -1
          ? packageSpec // e.g. dart:async
          : packageSpec.substring(0, dotIndex); // e.g. dart:html.Element -> dart:html
    }

    if (packageSpec.startsWith("package:")) {
      // Format: package:<pkgName>/rest/of/path
      final parts = packageSpec.split("/");
      if (parts.isNotEmpty) {
        final prefixRemoved = parts.first; // e.g. "package:jetleaf_web"
        return prefixRemoved.split(":").last; // "jetleaf_web"
      }
    }

    if (packageSpec.contains(":")) {
      // Fallback: just return everything before first ":"
      return packageSpec.split(":").first;
    }

    if (packageSpec.contains("/")) {
      // Fallback: just return everything before first ":"
      return packageSpec.split("/").first;
    }

    return packageSpec;
  }
}