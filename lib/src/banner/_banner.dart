import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';

import '../jetleaf_application.dart';
import '../jetleaf_version.dart';
import 'banner.dart';

/// {@template jetleaf_banner}
/// A [Banner] implementation that displays a simple text-based banner
/// with the Jetleaf logo and version information.
///
/// ### Example
/// ```dart
/// final banner = JetleafBanner();
/// banner.printBanner(env, MyApp, printStream);
/// ```
///
/// This banner is the default banner used by the [JetleafApplication].
/// {@endtemplate}
final class JetleafBanner implements Banner {

  static final String BANNER = r'''                                                             
  ______      _      _   _             __  ______    ____             _   
 / / / /     | | ___| |_| | ___  __ _ / _| \ \ \ \  |  _ \  __ _ _ __| |_ 
/ / / /   _  | |/ _ \ __| |/ _ \/ _` | |_   \ \ \ \ | | | |/ _` | '__| __|
\ \ \ \  | |_| |  __/ |_| |  __/ (_| |  _|  / / / / | |_| | (_| | |  | |_ 
 \_\_\_\  \___/ \___|\__|_|\___|\__,_|_|   /_/_/_/  |____/ \__,_|_|   \__|
https://jetleaf.hapnium.com      
Running Jetleaf ({VERSION})       
  ''';

  /// {@macro jetleaf_banner}
  JetleafBanner();

  @override
  void printBanner(Environment environment, Class<Object> sourceClass, PrintStream printStream) {
    printStream.println();

    String banner = BANNER.replaceAll("{VERSION}", "v${JetleafVersion.getVersion()}");
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
/// // Use DefaultBanner with JetleafBanner as fallback
/// final banner = DefaultBanner(JetleafBanner());
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
    final bannerFile = environment.getProperty(JetleafApplication.BANNER_LOCATION);
    String? banner;

    if (bannerFile != null) {
      final asset = Runtime.getAllAssets().firstWhereOrNull((asset) => asset.getFilePath().contains(bannerFile));

      if (asset != null) {
        banner = String.fromCharCodes(asset.getContentBytes());
      }
    }

    if (banner == null || banner.isEmpty) {
      final bannerText = environment.getProperty(JetleafApplication.BANNER_TEXT);
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
    String version = env.getProperty(JetleafApplication.JETLEAF_VERSION) ?? JetleafVersion.getVersion();
    String applicationVersion = env.getProperty(JetleafApplication.JETLEAF_APPLICATION_VERSION) ?? sourceClass.getPackage().getVersion();

    banner = env.resolvePlaceholders(banner);

    return banner
      .replaceAll(RegExp(r'(\#\{jetleaf\.version\}|\$\{jetleaf\.version\})'), version)
      .replaceAll(RegExp(r'(\#\{jetleaf\.application\.version\}|\$\{jetleaf\.application\.version\})'), applicationVersion);
  }

  @override
  String getPackageName() => PackageNames.MAIN;
}