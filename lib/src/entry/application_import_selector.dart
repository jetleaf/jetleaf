// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_utils/utils.dart';

import '../jet_leaf_application.dart';

/// {@template jetleaf_import_selector}
/// 🫘 Default [ImportSelector] implementation for JetLeaf.
///
/// `JetLeafImportSelector` scans the runtime environment for all available
/// JetLeaf packages and selects their names as imports. This allows the
/// framework to automatically discover and register modules without
/// requiring manual import lists.
///
/// ## How it works
///
/// - Uses [Runtime.getAllPackages] from `jetleaf_lang`.
/// - Iterates through each package and retrieves its name via [package.getName].
/// - Returns a list of package names as strings.
///
/// ## Example
///
/// ```dart
/// void main() {
///   const selector = JetLeafImportSelector();
///   final imports = selector.selects();
///
///   for (final pkg in imports) {
///     print('Discovered JetLeaf package: $pkg');
///   }
/// }
/// ```
///
/// ## Notes
///
/// - Always returns a list, which may be empty if no packages are available.
/// - Intended for use by JetLeaf’s startup and dependency resolution process.
///
/// See also:
/// - [ImportSelector] 🫘 for the interface contract.
/// - [ApplicationStartup] 🫘 for orchestrating startup logic.
/// 
/// {@endtemplate}
final class ApplicationImportSelector implements ImportSelector {
  /// Creates a constant [ApplicationImportSelector].
  /// 
  /// This selector is used by JetLeaf to automatically discover and register
  /// all available JetLeaf packages.
  /// 
  /// {@macro jetleaf_import_selector}
  const ApplicationImportSelector();

  @override
  List<ImportClass> selects() {
    final list = <ImportClass>[];

    final packages = Runtime.getAllPackages();
    final userPackage = packages.find((package) => package.getIsRootPackage());

    if (userPackage != null) {
      list.add(ImportClass.package(userPackage.getName()));
    }

    List<Map<String, dynamic>> content = [];

    // Load all assets
    final assets = Runtime.getAllAssets();

    // Filter assets to only include meta-inf
    List<Asset> importAssets = assets.where((asset) {
      final path = asset.getFilePath().toLowerCase();
      return path.contains("meta-inf/");
    }).toList();

    // Filter assets to only include yaml, yml, and properties files
    final extraAssets = assets.where((asset) {
      final path = asset.getFilePath().toLowerCase();
      return path.endsWith(".yaml") || path.endsWith(".yml")
      || path.endsWith(".properties");
    }).toList();

    // Add extra assets to import assets
    importAssets.addAll(extraAssets);

    for (final asset in importAssets) {
      if (asset.getFilePath().endsWith(".yaml") || asset.getFilePath().endsWith(".yml")) {
        final parser = YamlParser();
        content.add(parser.parseAsset(asset));
      } else if (asset.getFilePath().endsWith(".properties")) {
        final parser = PropertiesParser();
        content.add(parser.parseAsset(asset));
      }
    }

    // Collect only the maps that contain the enable property, 
    // but keep just that key in the result
    List<dynamic> enableAutoConfigurationContent = content
      .where((entry) => entry.containsKey(JetLeafApplication.ENABLE_AUTO_CONFIGURATION_PROPERTY))
      .map((entry) => entry[JetLeafApplication.ENABLE_AUTO_CONFIGURATION_PROPERTY])
      .toList();
    enableAutoConfigurationContent = _mergeContent(enableAutoConfigurationContent);

    // Same for disable property
    List<dynamic> disableAutoConfigurationContent = content
      .where((entry) => entry.containsKey(JetLeafApplication.DISABLE_AUTO_CONFIGURATION_PROPERTY))
      .map((entry) => entry[JetLeafApplication.DISABLE_AUTO_CONFIGURATION_PROPERTY])
      .toList();
    disableAutoConfigurationContent = _mergeContent(disableAutoConfigurationContent);

    // Build imports
    enableAutoConfigurationContent.forEach((entry) => _buildImport(entry, list));
    disableAutoConfigurationContent.forEach((entry) => _buildImport(entry, list));
    
    return list;
  }

  /// Builds imports from a given entry.
  /// 
  /// ## Example
  /// 
  /// ```dart
  /// final list = <ImportClass>[];
  /// _buildImport({"package": "jetleaf_web"}, list);
  /// print(list); // [ImportClass.package("jetleaf_web")]
  /// ```
  void _buildImport(dynamic entry, List<ImportClass> list) {
    if (entry is Map) {
      entry.forEach((key, value) {
        if (value is List) {
          value.forEach((item) {
            if (item is String) {
              if (item.contains(".") && item.contains(":")) {
                try {
                  Class.fromQualifiedName(item);
                  list.add(ImportClass.qualified(item));
                } catch (_) {
                  // Extract package name
                  final packageName = _extractPackageName(item);
                  list.add(ImportClass.package(packageName));
                }
              } else {
                list.add(ImportClass.package(item));
              }
            }
          });
        } else if (value is Map) {
          value.forEach((key, value) {
            if (key == "package") {
              if (value is String) {
                try {
                  final qualified = "$key:$value";
                  Class.fromQualifiedName(qualified);
                  list.add(ImportClass.qualified(qualified));
                } catch (_) {
                  // Extract package name
                  final packageName = _extractPackageName(value);
                  list.add(ImportClass.package(packageName));
                }
              }
            }
          });
        }
      });
    }
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

  /// Merge a list of maps into a single deduplicated list of maps.
  ///
  /// - If a key appears in multiple maps, values are merged:
  ///   - If both values are lists → concatenate & deduplicate
  ///   - If both values are maps  → recursively merge
  ///   - Otherwise → overwrite (last wins)
  List<Map<String, dynamic>> _mergeContent(dynamic content) {
    final merged = <String, dynamic>{};

    if (content is List) {
      for (final map in content) {
        if (map is Map) {
          _mergeMap(map, merged);
        }
      }
    } else if (content is Map) {
      _mergeMap(content, merged);
    }

    return [merged];
  }

  void _mergeMap(Map map, Map<String, dynamic> merged) {
    map.forEach((key, value) {
      if (merged.containsKey(key)) {
        final existing = merged[key];

        if (existing is List && value is List) {
          // Merge lists, deduplicate, merge maps inside
          final result = [...existing];
          for (final item in value) {
            if (item is Map) {
              // Try to merge maps if an identical key map already exists
              final idx = result.indexWhere((e) => e is Map && e.keys.first == item.keys.first);
              if (idx != -1 && result[idx] is Map) {
                result[idx] = _mergeTwoMaps(result[idx] as Map, item);
              } else {
                result.add(item);
              }
            } else if (!result.contains(item)) {
              result.add(item);
            }
          }
          merged[key] = result;
        } else if (existing is Map && value is Map) {
          merged[key] = _mergeTwoMaps(existing, value);
        } else {
          // fallback: overwrite
          merged[key] = value;
        }
      } else {
        merged[key] = value;
      }
    });
  }

  /// Helper to merge two maps deeply
  Map<String, dynamic> _mergeTwoMaps(Map a, Map b) {
    final result = Map<String, dynamic>.from(a);
    b.forEach((key, value) {
      if (result.containsKey(key)) {
        final existing = result[key];
        if (existing is List && value is List) {
          result[key] = {...existing, ...value}.toList();
        } else if (existing is Map && value is Map) {
          result[key] = _mergeTwoMaps(existing, value);
        } else {
          result[key] = value;
        }
      } else {
        result[key] = value;
      }
    });
    return result;
  }
}