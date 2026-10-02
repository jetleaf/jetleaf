import 'dart:io' show Directory;
import 'dart:mirrors' as mirrors;

import 'runtime_scanner_summary.dart';
import 'runtime_scanner_configuration.dart';

/// {@template mirror_state}
/// Holds the mirror system and force-loaded library mirrors from a completed
/// scan, so that [CacheAwareScanner] can persist them to disk without
/// re-scanning.
/// {@endtemplate}
class MirrorState {
  /// {@macro mirror_state}
  const MirrorState({
    required this.forceLoadedMirrors,
    required this.mirrorSystem,
  });

  /// Library mirrors that were force-loaded during the scan.
  final List<mirrors.LibraryMirror> forceLoadedMirrors;

  /// The active mirror system after the scan.
  final mirrors.MirrorSystem mirrorSystem;
}

/// {@template runtime_scanner}
/// Defines the contract for a reflection scanner that processes Dart source
/// files, extracts metadata, and optionally persists output.
///
/// Used during framework initialization or tooling that requires reflection
/// metadata (e.g., code analyzers, documentation generators, or runtime scanners).
///
/// Implementations should handle scanning efficiently and report meaningful
/// summaries including errors, warnings, and informational messages.
///
/// ## Example
/// ```dart
/// final scanner = MyRuntimeScanner();
/// final loader = RuntimeScanLoader(
///   reload: true,
///   updatePackages: false,
///   updateAssets: true,
///   baseFilesToScan: [File('lib/main.dart')],
///   packagesToScan: ['package:meta/', 'package:args/'],
/// );
/// final summary = await scanner.scan('build/meta', loader);
///
/// print(summary.getErrors());
/// ```
/// {@endtemplate}
abstract interface class RuntimeScanner {
  /// {@macro runtime_scanner}
  ///
  /// {@template runtime_scanner.scan}
  /// Performs the reflection scan and outputs a [RuntimeScannerSummary].
  ///
  /// - [loader] is the configuration for the scan.
  /// - [source] is the root directory to scan. Defaults to [Directory.current].
  /// - [args] is the build args to use
  ///
  /// Returns a [Future] that resolves to the final [RuntimeScannerSummary].
  /// {@endtemplate}
  Future<RuntimeScannerSummary> scan(RuntimeScannerConfiguration loader, List<String> args, {Directory? source});
}