import 'dart:io';

import '../cache/indexer/declaration_builder.dart';
import '../cache/indexer/discovered_files.dart';
import 'package:jetleaf_core/lang.dart';
import 'library_generator.dart';

/// {@template default_library_generator}
/// Default AST-based implementation of [LibraryGenerator].
/// {@endtemplate}
base class DefaultLibraryGenerator extends LibraryGenerator {
  /// Whether the library list should be refreshed.
  final bool refresh;

  /// Cache storing resolved [Package] metadata.
  final Map<String, Package> packageCache = {};

  /// {@macro default_library_generator}
  DefaultLibraryGenerator({
    required super.configuration,
    required super.packages,
    this.refresh = true,
    super.mirrorSystem,
    super.forceLoadedMirrors,
  });

  @override
  Future<void> generate(List<File> dartFiles) async {
    for (final package in packages) {
      packageCache[package.getName()] = package;
    }

    final rootPkg = packages.where((p) => p.getIsRootPackage()).firstOrNull?.getName() ?? 'unknown';
    final discoveredFiles = DiscoveredFiles();
    for (final file in dartFiles) {
      discoveredFiles.add(file, packageName: rootPkg);
    }

    final declarationBuilder = DeclarationBuilder();
    final declarations = await declarationBuilder.build(
      files: discoveredFiles,
      packageName: rootPkg,
    );

    registerCachedDeclarations(declarations);
  }
}