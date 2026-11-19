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

import '../cache/indexer/proxy_emitter.dart';
import '../utils/workspace.dart';
import 'jl_command.dart';

/// Generates `$$JLInterfaced$$` interceptable proxies for stereotype-annotated
/// pods only — no cache, no AOT registry, no tree shaking.
final class ProxyCommand extends JlCommand {
  const ProxyCommand();

  @override
  String get name => 'proxy';

  @override
  String get description =>
      'Emit interceptable proxies for stereotype-annotated components.';

  @override
  String get usage => '''
Usage: jl proxy [options]

Discovers stereotype-annotated classes (e.g. @Service, @RestController,
@Configuration) under lib/ and writes one JLInterfaced proxy per proxiable
class into <projectRoot>/lib/_jetleaf/proxies/.

Proxies are normally written by `jl build` on every build. `jl proxy` runs
only the proxy emission pass — useful when you want to inspect or commit the
generated proxies without rebuilding the whole runtime manifest.

Options:
  --root <dir>     Project directory (default: current directory). A pub
                   workspace root (pubspec.yaml declares `workspace:`)
                   emits proxies for every member in sequence.
  --verbose        Stream scan and generation logs.
  -h, --help       Show this help.
''';

  @override
  Future<int> run(List<String> args) async {
    if (args.contains('-h') || args.contains('--help')) {
      print(usage);
      return 0;
    }

    final root = _flagValue(args, '--root') ?? Directory.current.path;
    final directory = Directory(root);
    if (!directory.existsSync()) {
      stderr.writeln('Error: root not found: $root');
      return 1;
    }
    if (!File('${directory.path}/pubspec.yaml').existsSync()) {
      stderr.writeln('Error: not a package: ${directory.path} (expected pubspec.yaml)');
      return 1;
    }

    final verbose = args.contains('--verbose');

    // Workspace fan-out: `jl proxy` at a workspace root emits for each member.
    if (isWorkspaceRoot(directory)) {
      var failures = 0;
      for (final member in workspaceMembers(directory)) {
        print('==> Proxies for workspace member: ${member.path}');
        final result = await _emit(member, verbose);
        if (result == null) failures++;
      }
      return failures == 0 ? 0 : 1;
    }

    final result = await _emit(directory, verbose);
    return result == null ? 1 : 0;
  }

  /// Emits proxies for a single package.
  ///
  /// **Parameters:**
  /// - [root]: package root (must contain `pubspec.yaml`).
  /// - [verbose]: stream scan and generation logs.
  ///
  /// **Returns:** the number of proxies written, or `null` on failure.
  Future<int?> _emit(Directory root, bool verbose) async {
    try {
      final result = await emitProxiesForProject(
        projectRoot: root,
        verbose: verbose,
      );
      print('  Proxy emission: ${result.written} proxies written');
      return result.written;
    } catch (error, stack) {
      stderr.writeln('Error: proxy emission failed: $error');
      stderr.writeln(stack);
      return null;
    }
  }

  /// Reads a `--flag <value>` or `--flag=<value>` option.
  ///
  /// **Parameters:**
  /// - [args]: raw command arguments.
  /// - [flag]: flag name including leading dashes.
  ///
  /// **Returns:** the value, or null when absent.
  static String? _flagValue(List<String> args, String flag) {
    for (var i = 0; i < args.length; i++) {
      final a = args[i];
      if (a == flag && i + 1 < args.length) return args[i + 1];
      if (a.startsWith('$flag=')) return a.substring(flag.length + 1);
    }
    return null;
  }
}
