/// **Jetleaf Framework**
///
/// The main entry point for the Jetleaf ecosystem. This library aggregates
/// the core modules, utilities, and packages required to bootstrap and
/// run a Jetleaf application. It provides access to context management,
/// configuration, logging, environment handling, dependency injection,
/// type conversion, interception, messaging, and shutdown handling.
/// 
/// This library re-exports essential Jetleaf packages for convenience:
///
/// - `jetleaf_lang` — language and localization support.
/// - `jetleaf_env` — environment handling and configuration.
/// - `jetleaf_core` — core framework utilities, annotations, messaging, and interceptors.
/// - `jetleaf_pod` — dependency injection and pod management.
/// - `jetleaf_convert` — type conversion framework.
/// - `jetleaf_logging` — logging infrastructure and printers.
/// - `jetleaf_utils` — miscellaneous utilities for the Jetleaf ecosystem.
///
///
/// ## 🎯 Intended Usage
///
/// ```dart
/// import 'package:jetleaf/jetleaf.dart';
///
/// void main(List<String> args) {
///   JetleafApplication.run(Application(), args);
/// }
/// ```
///
/// This provides a unified entry point to all essential Jetleaf features,
/// making it easy to build, configure, and run modular Dart applications.
///
/// {@category Jetleaf}
library;

export 'main.dart';
export 'lang.dart';
export 'env.dart';
export 'core.dart';
export 'pod.dart';
export 'convert.dart';
export 'logging.dart';
export 'utils.dart';