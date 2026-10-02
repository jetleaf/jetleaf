import 'dart:io';

import 'dart:convert';

import '../utils/utils.dart';
import '../vm/control_client.dart';
import '../vm/jetleaf_vm.dart';
import 'jl_command.dart';

/// {@template run_command}
/// `jl run <file> [args...]` — runs an app entry in its warm VM.
///
/// Sends a `runApp` request to the manager (`jl dev` must be running);
/// streams the run and resolves with its exit code.
///
/// {@endtemplate}
final class RunCommand extends JlCommand {
  /// {@macro run_command}
  const RunCommand();

  @override
  String get name => 'run';

  @override
  String get description => 'Run an app entry in its warm VM.';

  @override
  String get usage => '''
Usage: jl run <file> [args...] [options]

Description:
  $description
  Requires `jl dev` running for the project.

Options:
  --root <dir>     Project root (default: current directory).
  -h, --help       Show this help.

Examples:
  jl run lib/main.dart
  jl run lib/main.dart -- --port 8080
''';

  /// Validates args and forwards a `runApp` request for `<file>`.
  ///
  /// **Parameters:**
  /// - [args]: `<file> [entry-args...] [--root <dir>]`.
  ///
  /// **Returns:** the run exit code.
  @override
  Future<int> run(List<String> args) async {
    if (args.contains('-h') || args.contains('--help')) {
      print(usage);
      return 0;
    }
    final root = _flagValue(args, '--root') ?? Directory.current.path;
    final dir = Directory(root);
    final positional = _commandPositionals(args);
    if (positional.isEmpty) {
      stderr.writeln('Error: missing <file>. See `jl run --help`.');
      return 1;
    }
    if (!RuntimeUtils.isJetLeafBuildProject(dir)) {
      stderr.writeln('Error: not a jetleaf_build project: ${dir.path}');
      return 1;
    }
    final entry = positional.first;
    final entryArgs = _applicationArguments(args);
    return JetleafControlClient.sendControlRequest(dir, {
      'type': 'runApp',
      'entry': entry,
      'args': entryArgs,
    });
  }

  /// Reads a `--flag value` / `--flag=value` option.
  ///
  /// **Parameters:**
  /// - [args]: raw command arguments.
  /// - [flag]: flag name including leading dashes.
  ///
  /// **Returns:** the value, or null when absent.
  String? _flagValue(List<String> args, String flag) {
    for (var i = 0; i < args.length; i++) {
      final a = args[i];
      if (a == flag && i + 1 < args.length) return args[i + 1];
      if (a.startsWith('$flag=')) return a.substring(flag.length + 1);
    }
    return null;
  }
}

/// {@template test_command}
/// `jl test [<file>|--all]` — runs test entries in warm VMs.
///
/// Sends `runTest` requests to the manager (`jl dev` must be running);
/// `--all` replays every `@JetleafTest` entry from VM state in order.
///
/// {@endtemplate}
final class TestCommand extends JlCommand {
  /// {@macro test_command}
  const TestCommand();

  @override
  String get name => 'test';

  @override
  String get description => 'Run test entries in warm VMs.';

  @override
  String get usage => '''
Usage: jl test [<file>|--all] [options]

Description:
  $description
  Requires `jl dev` running for the project.

Options:
  --root <dir>     Project root (default: current directory).
  --all            Run every discovered @JetleafTest entry.
  -h, --help       Show this help.

Examples:
  jl test test/app_test.dart
  jl test --all
''';

  /// Validates args and forwards `runTest` requests (one file or `--all`).
  ///
  /// **Parameters:**
  /// - [args]: `[<file>|--all] [--root <dir>]`.
  ///
  /// **Returns:** the run exit code (first failure for `--all`).
  @override
  Future<int> run(List<String> args) async {
    if (args.contains('-h') || args.contains('--help')) {
      print(usage);
      return 0;
    }
    final root = _flagValue(args, '--root') ?? Directory.current.path;
    final dir = Directory(root);
    if (!RuntimeUtils.isJetLeafBuildProject(dir)) {
      stderr.writeln('Error: not a jetleaf_build project: ${dir.path}');
      return 1;
    }
    if (args.contains('--all')) {
      final manager = JetleafControlClient.readManagerFile(dir);
      if (manager == null) {
        stderr.writeln('Error: jl dev is not running for ${dir.path}.');
        return 1;
      }
      final entries = await _testEntries(dir);
      final testArgs = _applicationArguments(args);
      var code = 0;
      for (final entry in entries) {
        final c = await JetleafControlClient.sendControlRequest(dir, {
          'type': 'runTest',
          'entry': entry,
          'args': testArgs,
        });
        if (c != 0) code = c;
      }
      if (entries.isEmpty) {
        print('(no test entries discovered)');
      }
      return code;
    }
    final positional = _commandPositionals(args);
    if (positional.isEmpty) {
      stderr.writeln('Error: missing <file> (or use --all).');
      return 1;
    }
    return JetleafControlClient.sendControlRequest(dir, {
      'type': 'runTest',
      'entry': positional.first,
      'args': _applicationArguments(args),
    });
  }

  /// Lists test entries for `--all` from the VM state array file.
  ///
  /// **Parameters:**
  /// - [dir]: project root owning `.jetleaf/vm/state.json`.
  ///
  /// **Returns:** test entry file keys (empty when unreadable).
  Future<List<String>> _testEntries(Directory dir) async {
    try {
      final file = File('${dir.path}/${JetleafVmPaths.vmFileName}');
      if (!file.existsSync()) return const [];
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .where((e) => e['kind'] == 'test')
          .map((e) => '${e['file']}')
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Reads a `--flag value` / `--flag=value` option.
  ///
  /// **Parameters:**
  /// - [args]: raw command arguments.
  /// - [flag]: flag name including leading dashes.
  ///
  /// **Returns:** the value, or null when absent.
  String? _flagValue(List<String> args, String flag) {
    for (var i = 0; i < args.length; i++) {
      final a = args[i];
      if (a == flag && i + 1 < args.length) return args[i + 1];
      if (a.startsWith('$flag=')) return a.substring(flag.length + 1);
    }
    return null;
  }
}

/// Returns positional command arguments before the `--` application delimiter.
List<String> _commandPositionals(List<String> args) {
  final end = args.indexOf('--');
  final commandArgs = end == -1 ? args : args.sublist(0, end);
  final values = <String>[];
  final rootValue = _readFlagValue(commandArgs, '--root');
  for (var i = 0; i < commandArgs.length; i++) {
    final value = commandArgs[i];
    if (value == '--root') {
      i++;
      continue;
    }
    if (value.startsWith('--root=')) continue;
    if (!value.startsWith('-') && value != rootValue) values.add(value);
  }
  return values;
}

/// Returns arguments after the `--` application delimiter unchanged.
List<String> _applicationArguments(List<String> args) {
  final separator = args.indexOf('--');
  return separator == -1 ? const [] : args.sublist(separator + 1);
}

String? _readFlagValue(List<String> args, String flag) {
  for (var i = 0; i < args.length; i++) {
    if (args[i] == flag && i + 1 < args.length) return args[i + 1];
    if (args[i].startsWith('$flag=')) {
      return args[i].substring(flag.length + 1);
    }
  }
  return null;
}

/// {@template status_command}
/// `jl status` — shows entry states from the running manager.
///
/// Prints the `state  file  pid=… ws://…` table from the manager's
/// `status_response` frame.
///
/// {@endtemplate}
final class StatusCommand extends JlCommand {
  /// {@macro status_command}
  const StatusCommand();

  @override
  String get name => 'status';

  @override
  String get description => 'Show entry VM states.';

  @override
  String get usage => '''
Usage: jl status [options]

Options:
  --root <dir>     Project root (default: current directory).
  -h, --help       Show this help.
''';

  /// Forwards a `status` request and prints the table.
  ///
  /// **Parameters:**
  /// - [args]: `[--root <dir>]`.
  ///
  /// **Returns:** the request exit code.
  @override
  Future<int> run(List<String> args) async {
    if (args.contains('-h') || args.contains('--help')) {
      print(usage);
      return 0;
    }
    final root = _flagValue(args, '--root') ?? Directory.current.path;
    return JetleafControlClient.sendControlRequest(Directory(root), {'type': 'status'});
  }

  /// Reads a `--flag value` / `--flag=value` option.
  ///
  /// **Parameters:**
  /// - [args]: raw command arguments.
  /// - [flag]: flag name including leading dashes.
  ///
  /// **Returns:** the value, or null when absent.
  String? _flagValue(List<String> args, String flag) {
    for (var i = 0; i < args.length; i++) {
      final a = args[i];
      if (a == flag && i + 1 < args.length) return args[i + 1];
      if (a.startsWith('$flag=')) return a.substring(flag.length + 1);
    }
    return null;
  }
}

/// {@template stop_command}
/// `jl stop [file]` — stops one entry VM, or all + the manager.
///
/// Without `<file>` stops every VM and terminates the manager itself.
 ///
/// {@endtemplate}
final class StopCommand extends JlCommand {
  /// {@macro stop_command}
  const StopCommand();

  @override
  String get name => 'stop';

  @override
  String get description => 'Stop entry VMs (or everything).';

  @override
  String get usage => '''
Usage: jl stop [<file>] [options]

Description:
  $description
  Without <file>: stops all VMs and the manager.

Options:
  --root <dir>     Project root (default: current directory).
  -h, --help       Show this help.
''';

  /// Forwards a `stop` request (one entry, or everything).
  ///
  /// **Parameters:**
  /// - [args]: `[<file>] [--root <dir>]`.
  ///
  /// **Returns:** the request exit code.
  @override
  Future<int> run(List<String> args) async {
    if (args.contains('-h') || args.contains('--help')) {
      print(usage);
      return 0;
    }
    final root = _flagValue(args, '--root') ?? Directory.current.path;
    final positional = args
        .where((a) => !a.startsWith('-') && a != _flagValue(args, '--root'))
        .toList();
    return JetleafControlClient.sendControlRequest(Directory(root), {
      'type': 'stop',
      if (positional.isNotEmpty) 'entry': positional.first,
    });
  }

  /// Reads a `--flag value` / `--flag=value` option.
  ///
  /// **Parameters:**
  /// - [args]: raw command arguments.
  /// - [flag]: flag name including leading dashes.
  ///
  /// **Returns:** the value, or null when absent.
  String? _flagValue(List<String> args, String flag) {
    for (var i = 0; i < args.length; i++) {
      final a = args[i];
      if (a == flag && i + 1 < args.length) return args[i + 1];
      if (a.startsWith('$flag=')) return a.substring(flag.length + 1);
    }
    return null;
  }
}
