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
/// ## 🔑 Key Features
///
/// - **Application Bootstrapping:** `JetLeafApplication` and `JetApplication`
///   manage lifecycle, startup, and shutdown.
/// - **Context Management:** Core and bootstrap contexts with factories,
///   environment parsing, and property sources.
/// - **Dependency Injection:** Pod factories, post-processors, and type filtering.
/// - **Logging & Monitoring:** Logging listeners, startup logging, and
///   configurable logging properties.
/// - **Exception Handling:** Application-level exception handlers and reporters.
/// - **Environment & Configuration:** Parsing and management of environment
///   properties, Dart config files, and runtime listeners.
/// - **Lifecycle & Listeners:** Run listeners and lifecycle management hooks.
/// - **Shutdown Handling:** Hooks and handlers for graceful application shutdown.
/// - **Messaging & Interception:** Core interceptable mechanisms and message sources.
/// - **Conversion Utilities:** Integration with JetLeaf Convert for type conversions.
///
///
/// ## 🔗 Included Packages
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

export 'src/banner/banner.dart';
export 'src/banner/_banner.dart';

export 'src/components/pod_factory_post_processors.dart';
export 'src/components/runner.dart';

export 'src/context/bootstrap_context.dart';
export 'src/context/bootstrap_context_impl.dart';
export 'src/context/context_factory.dart';
export 'src/context/default_context_factory.dart';

export 'src/entry/application_import_selector.dart';
export 'src/entry/application_type_filter.dart';
export 'src/entry/jet_leaf_config_parser.dart';

export 'src/env/property_source.dart';
export 'src/env/dart_config_parser.dart';
export 'src/env/environment_listener.dart';
export 'src/env/environment_parser.dart';

export 'src/exception_handler/application_exception_handler.dart';
export 'src/exception_handler/exception_handler.dart';
export 'src/exception_handler/exception_reporter.dart';

export 'src/listener/run_listener.dart';
export 'src/listener/lifecycle_run_listener.dart';
export 'src/listener/run_listeners.dart';

export 'src/logging/jet_logging_property.dart';
export 'src/logging/logging_listener.dart';
export 'src/logging/startup_logger.dart';

export 'src/shutdown/application_shutdown_handler.dart';
export 'src/shutdown/application_shutdown_handler_hook.dart';

export 'src/jet_application.dart';
export 'src/jet_leaf_application.dart';
export 'src/jet_leaf_exception.dart';
export 'src/jet_leaf_version.dart';

// PACKAGES
export 'package:jetleaf_lang/lang.dart';
export 'package:jetleaf_lang/jetleaf_lang.dart';

export 'package:jetleaf_env/env.dart';
export 'package:jetleaf_env/jetleaf_env.dart';

export 'package:jetleaf_core/annotation.dart';
export 'package:jetleaf_core/core.dart';
export 'package:jetleaf_core/context.dart';
export 'package:jetleaf_core/intercept.dart';
export 'package:jetleaf_core/message.dart';
export 'package:jetleaf_core/jetleaf_core.dart';

export 'package:jetleaf_pod/pod.dart';
export 'package:jetleaf_pod/jetleaf_pod.dart';

export 'package:jetleaf_convert/convert.dart';
export 'package:jetleaf_convert/jetleaf_convert.dart';

export 'package:jetleaf_logging/logging.dart';
export 'package:jetleaf_logging/printers.dart';
export 'package:jetleaf_logging/jetleaf_logging.dart';

export 'package:jetleaf_utils/utils.dart';
export 'package:jetleaf_utils/jetleaf_utils.dart';