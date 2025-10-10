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

import 'dart:io';

import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_logging/logging.dart';
import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_pod/pod.dart';

import '../jet_application.dart';

/// {@template startup_info_logger}
/// Logs application startup events in a structured and user-friendly format.
///
/// This logger generates standardized startup messages including:
/// - Compiler mode (JIT, AOT, DILL)
/// - Application name and version
/// - Dart runtime version
/// - Process ID (PID)
/// - Execution context (file path, user, working directory)
/// - Startup duration and system uptime
///
/// It is typically used during the [StartupTracker] lifecycle to provide clear,
/// consistent console output that helps operators and developers understand
/// the state of the application at boot time.
///
/// ### Example
/// ```dart
/// final logger = StartupLogger(MyApp, environment);
/// final log = LogFactory.getLog(MyApp);
///
/// // Log "Starting ..." messages
/// logger.logStarting(log);
///
/// // After startup
/// final startup = Startup('Started JetLeafApplication', Duration(seconds: 2));
/// logger.logStarted(log, startup);
/// ```
///
/// Example output:
/// ```text
/// Starting AOT MyApp v1.0.0 using Dart 3.5.0 with PID 12345 (bin/my_app.dart started by alice in /workspace)
/// Running with JetLeaf v1.0.0, Dart v3.5.0
/// Started JetLeafApplication in 2.003 seconds (process running for 2.003)
/// ```
/// {@endtemplate}
class StartupLogger {
  /// {@template startup_info_logger.source_class}
  /// The source class used to infer the application name and version.
  ///
  /// Typically, this is the class passed to:
  /// ```dart
  /// JetApplication.run(MyApp);
  /// ```
  ///
  /// Used when generating startup messages like:
  /// ```
  /// Starting MyApp v1.0.0 ...
  /// ```
  /// {@endtemplate}
  final Class<Object>? sourceClass;

  /// {@template startup_info_logger.environment}
  /// The application [Environment] that provides properties such as:
  /// - `jetleaf.application.version` → overrides application version
  /// - `jetleaf.application.pid` → custom process ID
  ///
  /// If not set, default values such as [pid] and [sourceClass] metadata
  /// will be used instead.
  /// {@endtemplate}
  final Environment environment;

  /// {@macro startup_info_logger}
  StartupLogger(this.sourceClass, this.environment);

  /// {@template startup_info_logger.log_starting}
  /// Logs the initial **"Starting ..."** and **"Running with JetLeaf ..."**
  /// messages.
  ///
  /// - `"Starting ..."` includes compiler mode, app name, version, Dart version, PID, and context
  /// - `"Running with JetLeaf ..."` shows JetLeaf version and Dart version
  ///
  /// Example:
  /// ```dart
  /// logger.logStarting(log);
  /// ```
  ///
  /// Output:
  /// ```text
  /// Starting AOT MyApp v1.0.0 using Dart 3.5.0 with PID 12345 (bin/my_app.dart started by alice in /workspace)
  /// Running with JetLeaf v1.0.0, Dart v3.5.0
  /// ```
  /// {@endtemplate}
  void logStarting(Log log) {
    log.info(_getStartingMessage());
    log.debug(_getRunningMessage());
  }

  /// {@template startup_info_logger.log_started}
  /// Logs the **"Started ..."** message after the application has fully booted.
  ///
  /// This message includes:
  /// - The startup action description (`startup.getAction()`)
  /// - Total time taken to start in seconds
  /// - Optional system uptime
  ///
  /// Example:
  /// ```dart
  /// final startup = Startup('Started JetLeafApplication', Duration(milliseconds: 1500));
  /// logger.logStarted(log, startup);
  /// ```
  ///
  /// Output:
  /// ```text
  /// Started JetLeafApplication in 1.500 seconds (process running for 1.502)
  /// ```
  /// {@endtemplate}
  void logStarted(Log log, StartupTracker startup) {
    if (log.getIsInfoEnabled()) {
      log.info(_getStartedMessage(startup));
    }
  }

  /// Returns the full **"Starting ..."** message with compiler mode,
  /// app name, version, Dart version, PID, and context.
  String _getStartingMessage() {
    final message = StringBuffer('Starting');
    _appendCompilerMode(message);
    _appendApplicationName(message);
    _appendApplicationVersion(message);
    _appendDartVersion(message);
    _appendPid(message);
    _appendContext(message);
    return message.toString();
  }

  /// Returns the **"Running with JetLeaf ..."** message showing JetLeaf
  /// and Dart runtime versions.
  String _getRunningMessage() {
    final message = StringBuffer('Running with JetLeaf');
    _appendVersion(
      message,
      environment.getProperty(JetApplication.JETLEAF_APPLICATION_VERSION) ?? getClass(null, PackageNames.CORE).getPackage()?.getVersion(),
    );
    message.write(', Dart');
    _appendVersion(message, Platform.version);
    return message.toString();
  }

  /// Returns the **"Started ..."** message with duration and process uptime.
  String _getStartedMessage(StartupTracker startup) {
    final message = StringBuffer();
    message.write(startup.getAction());
    _appendApplicationName(message);
    message.write(' in ');
    message.write((startup.getTimeTakenToStarted().inMilliseconds / 1000.0).toStringAsFixed(3));
    message.write(' seconds');
    final uptimeMs = startup.getProcessUptime();
    if (uptimeMs != null) {
      final uptime = uptimeMs / 1000.0;
      message.write(' (process running for ${uptime.toStringAsFixed(3)})');
    }
    return message.toString();
  }

  // --- Private helpers (not documented) ---
  void _appendCompilerMode(StringBuffer message) {
    _append(message, '', () =>
      System.isRunningAot() ? 'AOT' :
      System.isRunningJit() ? 'JIT' :
      System.isRunningFromDill() ? 'DILL' : null
    );
  }

  void _appendApplicationName(StringBuffer message) {
    _append(message, '', () {
      final name = environment.getProperty(AbstractApplicationContext.JETLEAF_APPLICATION_NAME) ?? sourceClass?.getName();
      if (name != null) {
        return name.contains('.') ? name.split('.').last : name;
      }
      return 'application';
    });
  }

  void _appendVersion(StringBuffer message, String? version) {
    _append(message, 'v', () => version);
  }

  void _appendApplicationVersion(StringBuffer message) {
    _append(message, 'v', () => environment.getProperty(JetApplication.JETLEAF_APPLICATION_VERSION) ?? sourceClass?.getPackage()?.getVersion());
  }

  void _appendPid(StringBuffer message) {
    _append(message, 'with PID ', () => environment.getProperty(JetApplication.JETLEAF_APPLICATION_PID) ?? '$pid');
  }

  void _appendContext(StringBuffer message) {
    final context = StringBuffer();
    final source = Platform.script.toFilePath();
    if (source.isNotEmpty) {
      context.write(source);
    }
    _append(context, ' started by ', () => Platform.environment['USER'] ?? Platform.environment['USERNAME']);
    _append(context, ' in ', () => Directory.current.path);
    if (context.isNotEmpty) {
      message.write(' (');
      message.write(context.toString());
      message.write(')');
    }
  }

  void _appendDartVersion(StringBuffer message) {
    _append(message, 'using Dart ', () => Platform.version.split(' ').first);
  }

  void _append(
    StringBuffer message,
    String prefix,
    String? Function() call, [
    String defaultValue = '',
  ]) {
    String? value;
    try {
      value = call();
    } catch (_) {
      value = null;
    }
    value ??= defaultValue;
    if (value.isNotEmpty) {
      if (message.isNotEmpty) message.write(' ');
      message.write(prefix);
      message.write(value);
    }
  }
}