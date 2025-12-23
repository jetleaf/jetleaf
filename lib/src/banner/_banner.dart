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

import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';

import '../jet_application.dart';
import '../jet_leaf_version.dart';
import 'banner.dart';

/// {@template jetleaf_banner}
/// A [Banner] implementation that displays a simple text-based banner
/// with the JetLeaf logo and version information.
///
/// ### Example
/// ```dart
/// final banner = JetLeafBanner();
/// banner.printBanner(env, MyApp, printStream);
/// ```
///
/// This banner is the default banner used by the [JetApplication].
/// {@endtemplate}
final class JetLeafBanner implements Banner {

  static final String BANNER = r'''                                                             
🍃    .-.          _      _   _                __    ______________  
🍃   /   \        | | ___| |_| |    ___  __ _ / _|   \ \ \ \ \ \ \ \
🍃  /  _  \    _  | |/ _ \ __| |   / _ \/ _` | |_     \ \ \ \ \ \ \ \
🍃 |  ( )  |  | |_| |  __/ |_| |__|  __/ (_| |  _|    / / / / / / / /
🍃  \     /    \___/ \___|\__|_____\___|\__,_|_|     /_/_/_/_/_/_/_/ 
🍃   `---'                                                              
🍃 https://jetleaf.hapnium.com      
🍃 Running 🍃 JetLeaf ({VERSION})       
  ''';

  /// {@macro jetleaf_banner}
  JetLeafBanner();

  @override
  void printBanner(Environment environment, Class<Object> sourceClass, PrintStream printStream) {
    printStream.println();

    String banner = BANNER.replaceAll("{VERSION}", "v${JetLeafVersion.getVersion()}");
    printStream.println(banner);
  }

  @override
  String getPackageName() => PackageNames.MAIN;
}

/// {@template default_banner}
/// A fallback [Banner] implementation that attempts to load a custom banner
/// from the application environment, but defaults to another banner if none
/// is found.
///
/// The lookup process checks the following in order:
/// 1. `banner.location` → a file path to an asset
/// 2. `banner.text` → inline banner text
/// 3. Falls back to the provided [_fallback] banner
///
/// ### Example
/// ```dart
/// // Use DefaultBanner with JetLeafBanner as fallback
/// final banner = DefaultBanner(JetLeafBanner());
/// banner.printBanner(env, MyApp, printStream);
/// ```
///
/// This allows applications to override the startup banner dynamically
/// without changing code, just via environment properties.
/// {@endtemplate}
final class DefaultBanner implements Banner {
  /// The fallback banner to use if no custom banner is configured.
  final Banner _fallback;

  /// {@macro default_banner}
  DefaultBanner(this._fallback);

  @override
  void printBanner(Environment environment, Class<Object> sourceClass, PrintStream printStream) {
    final bannerFile = environment.getProperty(JetApplication.BANNER_LOCATION);
    String? banner;

    if (bannerFile != null) {
      final asset = Runtime.getAllAssets().firstWhereOrNull((asset) => asset.getFilePath().contains(bannerFile));

      if (asset != null) {
        banner = String.fromCharCodes(asset.getContentBytes());
      }
    }

    if (banner == null || banner.isEmpty) {
      final bannerText = environment.getProperty(JetApplication.BANNER_TEXT);
      if (bannerText != null) {
        banner = bannerText;
      }
    }

    if (banner != null && banner.isNotEmpty) {
      // 🔑 interpolate placeholders before printing
      final resolvedBanner = _interpolateBanner(banner, environment, sourceClass);
      printStream.println(resolvedBanner);
    } else {
      _fallback.printBanner(environment, sourceClass, printStream);
    }
  }

  /// Replace placeholders like #{jetleaf.version} or ${jetleaf.application.version}.
  String _interpolateBanner(String banner, Environment env, Class<Object> sourceClass) {
    String version = env.getProperty(JetApplication.JETLEAF_VERSION) ?? JetLeafVersion.getVersion();
    String applicationVersion = env.getProperty(JetApplication.JETLEAF_APPLICATION_VERSION) ?? sourceClass.getPackage().getVersion();

    banner = env.resolvePlaceholders(banner);

    return banner
      .replaceAll(RegExp(r'(\#\{jetleaf\.version\}|\$\{jetleaf\.version\})'), version)
      .replaceAll(RegExp(r'(\#\{jetleaf\.application\.version\}|\$\{jetleaf\.application\.version\})'), applicationVersion);
  }

  @override
  String getPackageName() => PackageNames.MAIN;
}