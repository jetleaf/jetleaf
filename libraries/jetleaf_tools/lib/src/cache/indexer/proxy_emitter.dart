// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & Jetleaf Contributors. All rights reserved.
//
// This source file is part of the Jetleaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the Jetleaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
//
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'dart:io';

import '../../aot/aot_proxy_writer.dart';
import 'declaration_builder.dart';
import 'file_discovery.dart';

/// Result of the proxy emission pass.
class ProxyEmissionResult {
  /// Number of proxy classes written (0 when nothing was emitted).
  final int written;

  /// The package name read from `pubspec.yaml` (`unknown` when unreadable).
  final String packageName;

  const ProxyEmissionResult({required this.written, required this.packageName});
}

/// Reads the package name from `pubspec.yaml`.
String packageNameFor(Directory projectRoot) {
  final pubspecFile = File('${projectRoot.path}/pubspec.yaml');
  if (!pubspecFile.existsSync()) return 'unknown';

  for (final line in pubspecFile.readAsLinesSync()) {
    if (line.trimLeft().startsWith('name:')) {
      return line.split(':').last.trim();
    }
  }
  return 'unknown';
}

/// Emits `$$JLInterfaced$$` interceptable proxies for every stereotype-annotated,
/// proxyable component under [projectRoot].
///
/// **Parameters:**
/// - [projectRoot]: project root containing `lib/` and `pubspec.yaml`.
/// - [verbose]: stream scan/generation logs (defaults to off).
///
/// **Returns:** [ProxyEmissionResult] with the number of proxies written.
Future<ProxyEmissionResult> emitProxiesForProject({
  Directory? projectRoot,
  bool verbose = false,
}) async {
  final root = projectRoot ?? Directory.current;
  final packageName = packageNameFor(root);

  final discovery = FileDiscovery(root);
  final files = await discovery.discover(
    skipTests: false,
    packagesToExclude: [],
    packagesToScan: [],
    filesToExclude: [],
  );

  final components = await DeclarationBuilder().build(
    files: files,
    packageName: packageName,
  );

  final written = await AotProxyWriter().emitProjectProxies(
    projectRoot: root,
    packageName: packageName,
    log: verbose ? print : (_) {},
    components: components,
  );

  return ProxyEmissionResult(written: written, packageName: packageName);
}
