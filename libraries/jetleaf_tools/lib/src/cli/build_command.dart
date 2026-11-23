import 'dart:io';

import '../cache/indexer/build_command.dart' as builder;
import '../utils/workspace.dart';
import 'jl_command.dart';

/// Builds declaration caches and the Jetleaf production runtime manifest.
final class BuildCommand extends JlCommand {
  const BuildCommand();

  @override
  String get name => 'build';

  @override
  String get description =>
      'Build Jetleaf caches and the production runtime manifest.';

  @override
  String get usage => '''
Usage: jl build [options]

Builds declaration metadata, indexes, runtime hints, and a production
runtime manifest under .jetleaf/build/.

Options:
  --root <dir>          Project root (default: current directory). A pub
                        workspace root (pubspec.yaml declares `workspace:`)
                        builds every member in sequence.
  --test                Include test declarations in the manifest.
  --skip-tree-shaking   Generate a complete manifest without optimization.
  -h, --help            Show this help.
''';

  @override
  Future<int> run(List<String> args) async {
    if (args.contains('-h') || args.contains('--help')) {
      print(usage);
      return 0;
    }
    final root = _flagValue(args, '--root') ?? Directory.current.path;
    final directory = Directory(root).absolute;
    if (!directory.existsSync()) {
      stderr.writeln('Error: root not found: $root');
      return 1;
    }
    try {
      // Workspace fan-out: `jl build` at a workspace root builds each member
      // in turn and fails if any member fails.
      if (Workspace.isRoot(directory)) {
        var failures = 0;
        for (final member in Workspace.members(directory)) {
          print('==> Building workspace member: ${member.path}');
          final exitCode = await builder.runBuild(args, root: member);
          if (exitCode != 0) {
            failures++;
            stderr.writeln('==> member build failed: ${member.path} (exit $exitCode)');
          }
        }
        return failures == 0 ? 0 : 1;
      }
      return await builder.runBuild(args, root: directory);
    } catch (error, stack) {
      stderr.writeln('Error: Jetleaf build failed: $error');
      stderr.writeln(stack);
      return 1;
    }
  }

  String? _flagValue(List<String> args, String flag) {
    for (var i = 0; i < args.length; i++) {
      if (args[i] == flag && i + 1 < args.length) {
        return args[i + 1];
      }
      if (args[i].startsWith('$flag=')) {
        return args[i].substring(flag.length + 1);
      }
    }
    return null;
  }
}