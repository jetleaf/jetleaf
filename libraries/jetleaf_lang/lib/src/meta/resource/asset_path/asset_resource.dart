import 'dart:io';
import 'dart:typed_data';

import 'package:jetleaf_build/jetleaf_build.dart';
import 'package:jetleaf_build/cache.dart' show BinaryBuilder;
import 'package:meta/meta.dart';

import '../../../extensions/primitives/string.dart';
import '../../../commons/typedefs.dart';
import '../../../exceptions.dart';
import '../../../io/base.dart';
import '../../../io/input_stream/byte_array_input_stream.dart';
import '../../../io/input_stream/input_stream.dart';
import '../../../io/input_stream/input_stream_source.dart';
import '../asset_loader/bundler.dart';
import '../asset_loader/interface.dart';

part '_asset_path_resource.dart';
part '_asset_resource.dart';
part 'asset_path_resource.dart';

/// {@template asset_resource_extension_strategy}
/// A function signature for determining the extension of an [AssetResource].
///
/// This strategy receives a `source` object, which can either be a [String]
/// (representing raw content or a path) or an [Asset]. The function should
/// return:
///
/// - A file extension (without a leading dot) if it can determine one.
/// - `null` if the extension cannot be determined.
///
/// You can register custom strategies using:
///
/// ```dart
/// AssetResource.registerExtensionStrategy((source) {
///   if (source is String && source.endsWith('.yaml')) {
///     return 'yaml';
///   }
///   return null;
/// });
/// ```
/// {@endtemplate}
typedef AssetResourceExtensionStrategy = String? Function(Object source);

/// {@template asset_resource_content_detector}
/// A function signature for detecting whether a given source should be
/// treated as **content** rather than a file path.
///
/// The function receives a `source` which may be:
/// - A [String] containing raw content or a path-like string.
/// - An [Asset] instance.
///
/// The function should return:
/// - `true` if the source represents inline content.
/// - `false` if the source represents a file path or non-content.
///
/// You can register custom detectors using:
///
/// ```dart
/// AssetResource.registerContentDetector((source) {
///   if (source is String && source.trim().startsWith('<html>')) {
///     return true;
///   }
///   return false;
/// });
/// ```
/// {@endtemplate}
typedef AssetResourceContentDetector = bool Function(Object source);

/// {@template asset_resource}
/// An abstract representation of a resource that wraps either:
///
/// - **Raw textual content** (e.g., JSON, YAML, Dart code, properties).
/// - An [Asset] object.
///
/// This abstraction allows working uniformly with both inline content and
/// file-based assets. The actual implementation is provided by the private
/// class `_AssetResource`.
///
/// ### Example: Creating from raw content
/// ```dart
/// final resource = AssetResource('{ "name": "example" }');
/// print(resource.source); // prints the JSON string
/// ```
///
/// ### Example: Creating from an Asset
/// ```dart
/// final asset = FileAsset('/path/to/config.yaml');
/// final resource = AssetResource(asset);
/// print(resource.source); // prints the FileAsset instance
/// ```
///
/// ### Extension Strategies
/// Developers can plug in custom extension strategies to determine the file
/// extension dynamically:
///
/// ```dart
/// AssetResource.registerExtensionStrategy((source) {
///   if (source is String && source.endsWith('.conf')) {
///     return 'conf';
///   }
///   return null;
/// });
/// ```
///
/// ### Content Detectors
/// Similarly, content detectors decide whether a `String` is inline content
/// or a path:
///
/// ```dart
/// AssetResource.registerContentDetector((source) {
///   if (source is String && source.contains('{')) return true;
///   return false;
/// });
/// ```
/// {@endtemplate}
abstract final class AssetResource extends Asset {
  /// {@template asset_resource_factory}
  /// Factory constructor for creating an [AssetResource].
  ///
  /// - If the `source` is an [Asset], it delegates to
  ///   `_AssetResource.fromAsset(source)`.
  /// - Otherwise, it wraps the `source` directly.
  ///
  /// ### Example
  /// ```dart
  /// final resource1 = AssetResource('{"name":"test"}'); // from content
  /// final asset = FileAsset('/path/to/file.json');
  /// final resource2 = AssetResource(asset); // from an Asset
  /// ```
  /// {@endtemplate}
  factory AssetResource(Object source) = _AssetResource;

  /// {@template asset_resource_source}
  /// The underlying source of this resource.
  ///
  /// This can be either:
  /// - A [String], which may represent inline content or a path-like string.
  /// - An [Asset] object.
  ///
  /// ### Example
  /// ```dart
  /// final resource = AssetResource('config: value');
  /// print(resource.source); // 'config: value'
  /// ```
  /// {@endtemplate}
  Object getSource();

  /* ------------------------- Dynamic extension system ------------------------- */

  /// {@template asset_resource_extension_strategies}
  /// The list of registered extension strategies.
  ///
  /// Strategies are evaluated in the order they were registered. If one fails
  /// or throws, the system ignores it and proceeds to the next.
  ///
  /// Developers can register new strategies via
  /// [registerExtensionStrategy].
  /// {@endtemplate}
  static final List<AssetResourceExtensionStrategy> _extensionStrategies = [
    _AssetResource._defaultExtensionStrategy,
  ];

  /// {@template asset_resource_content_detectors}
  /// The list of registered content detection strategies.
  ///
  /// Each detector determines if a `source` should be treated as **content**.
  /// If any registered detector returns `true`, the source is treated as
  /// inline content.
  ///
  /// Developers can register new detectors via
  /// [registerContentDetector].
  /// {@endtemplate}
  static final List<AssetResourceContentDetector> _contentDetectors = [
    _AssetResource._defaultContentDetector,
  ];

  /// {@template asset_resource_register_extension_strategy}
  /// Registers a new extension strategy.
  ///
  /// A strategy is a function that attempts to determine the extension of
  /// a given `source`. If it cannot, it should return `null`.
  ///
  /// ### Example
  /// ```dart
  /// AssetResource.registerExtensionStrategy((source) {
  ///   if (source is String && source.contains('xml')) return 'xml';
  ///   return null;
  /// });
  /// ```
  /// {@endtemplate}
  static void registerExtensionStrategy(AssetResourceExtensionStrategy strategy) {
    _extensionStrategies.add(strategy);
  }

  /// {@template asset_resource_register_content_detector}
  /// Registers a new content detector.
  ///
  /// A detector is a function that decides whether a `source` should be
  /// treated as inline content.
  ///
  /// ### Example
  /// ```dart
  /// AssetResource.registerContentDetector((source) {
  ///   if (source is String && source.startsWith('{')) return true;
  ///   return false;
  /// });
  /// ```
  /// {@endtemplate}
  static void registerContentDetector(AssetResourceContentDetector detector) {
    _contentDetectors.add(detector);
  }

  /// {@template asset_resource_determine_extension}
  /// Determines the file extension for a given `source`.
  ///
  /// - Consults all registered [AssetResourceExtensionStrategy] functions
  ///   in the order they were registered.
  /// - Returns the first non-null, non-empty extension.
  /// - Falls back to `_AssetResource.determineExtension(source)` if none match.
  ///
  /// ### Example
  /// ```dart
  /// final ext = AssetResource.determineExtension('config.yaml');
  /// print(ext); // 'yaml'
  /// ```
  /// {@endtemplate}
  static String? determineExtension(Object source) {
    for (final strat in _extensionStrategies) {
      try {
        final ext = strat(source);
        if (ext != null && ext.isNotEmpty) return ext;
      } catch (_) {
        // ignore strategy errors so one faulty strategy won't break others
      }
    }
    return _AssetResource.determineExtension(source);
  }

  /// {@template asset_resource_get_is_content}
  /// Determines whether a given `source` should be treated as inline content.
  ///
  /// - Runs through all registered [AssetResourceContentDetector] functions.
  /// - If any return `true`, the `source` is considered inline content.
  /// - Falls back to `_AssetResource.getIsContent(source)` if none match.
  ///
  /// ### Example
  /// ```dart
  /// final isContent = AssetResource.getIsContent('{"key": "value"}');
  /// print(isContent); // true
  /// ```
  /// {@endtemplate}
  static bool getIsContent(Object source) {
    for (final d in _contentDetectors) {
      try {
        if (d(source)) return true;
      } catch (_) {
        // ignore detector errors
      }
    }

    return _AssetResource.getIsContent(source);
  }
}