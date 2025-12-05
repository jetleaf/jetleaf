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

/// 🍃 **JetLeaf Framework**
///
/// The main entry point for the JetLeaf ecosystem. This library aggregates
/// the core modules, utilities, and packages required to bootstrap and
/// run a JetLeaf application. It provides access to context management,
/// configuration, logging, environment handling, dependency injection,
/// type conversion, interception, messaging, and shutdown handling.
/// 
/// This library re-exports essential JetLeaf packages for convenience:
///
/// - `jetleaf_lang` — language and localization support.
/// - `jetleaf_env` — environment handling and configuration.
/// - `jetleaf_core` — core framework utilities, annotations, messaging, and interceptors.
/// - `jetleaf_pod` — dependency injection and pod management.
/// - `jetleaf_convert` — type conversion framework.
/// - `jetleaf_logging` — logging infrastructure and printers.
/// - `jetleaf_utils` — miscellaneous utilities for the JetLeaf ecosystem.
///
///
/// ## 🎯 Intended Usage
///
/// ```dart
/// import 'package:jetleaf/jetleaf.dart';
///
/// void main(List<String> args) {
///   JetApplication.run(Application(), args);
/// }
/// ```
///
/// This provides a unified entry point to all essential JetLeaf features,
/// making it easy to build, configure, and run modular Dart applications.
///
/// {@category JetLeaf}
library;

export 'main.dart';
export 'lang.dart';
export 'env.dart';
export 'core.dart';
export 'pod.dart';
export 'convert.dart';
export 'logging.dart';
export 'utils.dart';