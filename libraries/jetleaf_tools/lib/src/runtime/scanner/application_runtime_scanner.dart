import 'dart:io';

import '../../builder/runtime_builder.dart';
import '../../cache/indexer/declaration_builder.dart';
import '../../cache/indexer/file_discovery.dart';
import '../../file_utility/file_utility.dart';
import '../declaration/declaration.dart';
import '../executor/aot/aot_runtime_executor.dart';
import '../hint/default_runtime_hint_descriptor.dart';
import '../provider/runtime_provider.dart';
import 'default_runtime_scanner_summary.dart';
import 'runtime_scanner.dart';
import 'runtime_scanner_configuration.dart';
import 'runtime_scanner_summary.dart';

/// {@template application_runtime_scanner}
/// A pure Dart AOT runtime scanner responsible for analyzing application code
/// and generating declaration metadata without `dart:mirrors`.
/// {@endtemplate}
final class ApplicationRuntimeScanner implements RuntimeScanner {
  /// Optional callback invoked for informational log messages.
  final OnLogged? onInfo;

  /// Optional callback invoked for warning log messages.
  final OnLogged? onWarning;

  /// Optional callback invoked for error log messages.
  final OnLogged? onError;

  List<ClassDeclaration> _lastDeclarations = [];

  /// {@macro application_runtime_scanner}
  ApplicationRuntimeScanner({this.onInfo, this.onWarning, this.onError});

  /// Returns the declarations from the last completed scan.
  List<ClassDeclaration> getLastDeclarations() => _lastDeclarations;

  @override
  Future<RuntimeScannerSummary> scan(
    RuntimeScannerConfiguration configuration,
    List<String> args, {
    Directory? source,
  }) async {
    String? package;
    RuntimeBuilder.setContext(args, onError: onError, onInfo: onInfo, onWarning: onWarning, package: package);

    if (Runtime.isPopulated) {
      RuntimeBuilder.logVerboseInfo("Runtime already populated — skipping scan");
      final summary = DefaultRuntimeScannerSummary();
      summary.setBuildTime(DateTime.now());
      return summary;
    }

    final result = await RuntimeBuilder.timeAsyncExecution(() async {
      final Directory directory = source ?? Directory.current;
      final fileUtils = FileUtility(
        RuntimeBuilder.logInfo,
        RuntimeBuilder.logWarning,
        RuntimeBuilder.logError,
        configuration,
        configuration.tryOutsideIsolate ?? (file, uri) => true,
      );

      package ??= await fileUtils.readPackageName();
      RuntimeBuilder.setPackage(package);

      configuration = _addDefaultPackagesToScan(configuration, package!);
      setRuntimeLibraryTag(directory.uri.toString());

      RuntimeBuilder.logVerboseInfo("Scanning $package application via AST analyzer...");

      // 1. Discover files
      final discovery = FileDiscovery(directory);
      final discoveredFiles = await discovery.discover(
        skipTests: configuration.skipTests,
        packagesToExclude: configuration.packagesToExclude,
        packagesToScan: configuration.packagesToScan,
        filesToExclude: configuration.filesToExclude,
      );

      // 2. Build declarations with analyzer
      final declarationBuilder = DeclarationBuilder();
      final declarations = await declarationBuilder.build(
        files: discoveredFiles,
        packageName: package!,
      );

      _lastDeclarations = declarations;

      // 3. Register declarations in MaterialLibrary
      registerCachedDeclarations(declarations);

      // 4. Discover and register resources
      final resources = await fileUtils.discoverAllResources(package!);
      if (resources.isNotEmpty) {
        addRuntimeAssets(resources, replace: configuration.reload);
      }

      // 5. Discover and register packages
      final packages = await fileUtils.readPackageGraphDependencies(directory);
      if (packages.isNotEmpty) {
        addRuntimePackages(packages, replace: configuration.reload);
      }

      // 6. Set AOT runtime resolver
      setRuntimeResolver(AotRuntimeExecutor(DefaultRuntimeHintDescriptor()));

      freezeRuntimeLibrary();
    });

    RuntimeBuilder.logVerboseInfo("Application scanning completed in ${result.getFormatted()}.");

    final summary = DefaultRuntimeScannerSummary();
    summary.setBuildTime(DateTime.fromMillisecondsSinceEpoch(result.watch.elapsedMilliseconds));
    summary.addInfos(RuntimeBuilder.onCompleted().getInfos());
    summary.addWarnings(RuntimeBuilder.onCompleted().getWarnings());
    summary.addErrors(RuntimeBuilder.onCompleted().getErrors());
    summary.addAll(RuntimeBuilder.onCompleted().getLogs());

    RuntimeBuilder.clearTrackedLogs();
    return summary;
  }

  RuntimeScannerConfiguration _addDefaultPackagesToScan(
    RuntimeScannerConfiguration configuration,
    String currentPackage,
  ) {
    final defaultPackages = {
      currentPackage,
      ...configuration.packagesToScan,
    }.toList();
    final filteredDefaults = defaultPackages
        .where((pkg) => !configuration.packagesToExclude.contains(pkg))
        .toList();

    return configuration.copyWith(packagesToScan: filteredDefaults);
  }
}
