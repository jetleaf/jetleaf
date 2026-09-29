import 'package:jetleaf_build/src/cache/indexer/daemon.dart';
import 'package:jetleaf_build/src/cache/indexer/build_command.dart';
import 'package:jetleaf_build/src/cache/indexer/init_command.dart';
import 'package:jetleaf_build/src/cache/indexer/status_command.dart';

/// Entry point for the Jetleaf CLI.
///
/// Usage:
///   dart run jetleaf_build build       — one-shot build
///   dart run jetleaf_build build --test — build with test cache
///   dart run jetleaf_build init         — init current project
///   dart run jetleaf_build init --recursive — init all projects
///   dart run jetleaf_build status       — show cache status
///   dart run jetleaf_build daemon       — stdin/stdout JSON protocol
void main(List<String> args) {
  if (args.isEmpty) {
    _printUsage();
    return;
  }

  switch (args.first) {
    case 'build':
      runBuild(args);
    case 'init':
      runInit(args);
    case 'status':
      runStatus(args);
    case 'daemon':
      CommandHandler().start();
    default:
      _printUsage();
  }
}

void _printUsage() {
  print('Usage: dart run jetleaf_build <command>');
  print('');
  print('Commands:');
  print('  build       One-shot build (write cache and exit)');
  print('  build --test  Build with test cache');
  print('  init        Initialize Jetleaf config');
  print('  init --recursive  Initialize all projects recursively');
  print('  status      Show cache status');
  print('  daemon      Start JSON protocol (for VS Code extension)');
}
