import 'dart:io';

import 'package:meta/meta.dart';

import 'package:jetleaf_core/declaration.dart';
import '../runtime/scanner/runtime_scanner_configuration.dart';
import '../utils/utils.dart';

/// {@template library_generator}
/// Enhanced declaration generator that creates metadata using AST analysis.
/// {@endtemplate}
abstract class LibraryGenerator {
  /// The runtime scan configuration.
  final RuntimeScannerConfiguration configuration;

  /// List of packages to process.
  final List<Package> packages;

  /// {@macro library_generator}
  @protected
  LibraryGenerator({
    required this.configuration,
    required this.packages,
    dynamic mirrorSystem,
    dynamic forceLoadedMirrors,
  });

  /// Generates declaration metadata.
  Future<void> generate(List<File> dartFiles);

  /// {@macro non_loadable_check}
  @protected
  bool isNonLoadableJetleafFile(Uri uri) => RuntimeUtils.isNonLoadableJetleafFile(uri);

  /// {@macro non_loadable_check}
  @protected
  bool isSkippableJetleafPackage(Uri identifier) => RuntimeUtils.isSkippableJetleafPackage(identifier);

  /// {@macro package_name_extraction}
  @protected
  String? getPackageNameFromUri(dynamic uri) => RuntimeUtils.getPackageNameFromUri(uri);

  /// {@macro is_part_of}
  @protected
  bool isPartOf(String content) => RuntimeUtils.isPartOf(content);

  /// {@macro is_test}
  @protected
  bool isTest(String content) => RuntimeUtils.isTest(content);

  /// {@macro uri_resolution}
  @protected
  Future<Uri?> resolveUri(Uri uri) => RuntimeUtils.resolveUri(uri);

  /// {@macro library_exclusion}
  @protected
  Future<bool> shouldNotIncludeLibrary(Uri uri, RuntimeScannerConfiguration configuration) =>
      RuntimeUtils.shouldNotIncludeLibrary(uri, configuration);
}