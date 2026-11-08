import 'dart:io';

import 'application_runtime_scanner.dart';
import 'runtime_scanner.dart';
import 'runtime_scanner_configuration.dart';
import 'runtime_scanner_summary.dart';

/// {@template mock_runtime_scanner}
/// A mock implementation of [RuntimeScanner] for testing.
/// {@endtemplate}
final class MockRuntimeScanner implements RuntimeScanner {
  final ApplicationRuntimeScanner _delegate;

  MockRuntimeScanner({
    dynamic onInfo,
    dynamic onWarning,
    dynamic onError,
  }) : _delegate = ApplicationRuntimeScanner(
          onInfo: onInfo,
          onWarning: onWarning,
          onError: onError,
        );

  @override
  Future<RuntimeScannerSummary> scan(
    RuntimeScannerConfiguration configuration,
    List<String> args, {
    Directory? source,
  }) async {
    return _delegate.scan(configuration, args, source: source);
  }
}