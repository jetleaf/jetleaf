import 'dart:io' show Directory;

import 'runtime_scanner_summary.dart';
import 'runtime_scanner_configuration.dart';

/// {@template runtime_scanner}
/// Defines the contract for a scanner that processes Dart source
/// files, extracts declarations and metadata, and registers runtime context.
/// {@endtemplate}
abstract interface class RuntimeScanner {
  /// Performs the scan and outputs a [RuntimeScannerSummary].
  Future<RuntimeScannerSummary> scan(
    RuntimeScannerConfiguration loader,
    List<String> args, {
    Directory? source,
  });
}
