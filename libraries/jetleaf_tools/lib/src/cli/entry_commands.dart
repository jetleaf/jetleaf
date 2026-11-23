import 'dart:io';

import 'dart:convert';

import 'package:path/path.dart' as p;

import '../utils/utils.dart';
import '../utils/workspace.dart';
import '../vm/control_client.dart';
import '../vm/jetleaf_vm.dart';
import '../cache/indexer/build_command.dart' as builder;
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
    var dir = Directory(root).absolute;
    final positional = _commandPositionals(args);

    // Workspace fan-out: resolve the member owning the entry file and run
    // against that member's manager. The entry path is rewritten to be
    // relative to the member root (the manager keys entries relative to it).
    var positionalEntry = positional.isEmpty ? null : positional.first;
    if (positionalEntry != null && Workspace.isRoot(dir)) {
      final member = Workspace.memberOwning(dir, positionalEntry);
      if (member != null) {
        print('==> Workspace member: ${member.path}');
        positionalEntry = p.relative(
          p.isAbsolute(positionalEntry) ? positionalEntry : p.join(dir.path, positionalEntry),
          from: member.path,
        );
        dir = member;
      } else {
        final rootCandidate = File(p.isAbsolute(positionalEntry) ? positionalEntry : p.join(dir.path, positionalEntry));
        if (!rootCandidate.existsSync()) {
          stderr.writeln('Error: $positionalEntry is not inside a workspace member of $root');
          return 1;
        }
      }
    }

    if (positionalEntry == null) {
      stderr.writeln('Error: missing <file>. See `jl run --help`.');
      return 1;
    }
    if (!RuntimeUtils.isJetLeafBuildProject(dir)) {
      stderr.writeln('Error: not a Jetleaf project: ${dir.path}');
      return 1;
    }
    final entry = positionalEntry;
    final entryArgs = _applicationArguments(args);

    final manager = JetleafControlClient.readManagerFile(dir);
    if (manager != null) {
      try {
        return await JetleafControlClient.sendControlRequest(dir, {
          'type': 'runApp',
          'entry': entry,
          'args': entryArgs,
        });
      } catch (_) {
        // Fall back to direct execution if manager unreachable
      }
    }

    // Direct AOT Execution (Zero Daemon Required)
    await builder.runBuild([], root: dir);
    final process = await Process.start(
      Platform.resolvedExecutable,
      ['run', entry, ...entryArgs],
      workingDirectory: dir.path,
      mode: ProcessStartMode.inheritStdio,
    );
    return await process.exitCode;
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
    final dir = Directory(root).absolute;
    final positional = _commandPositionals(args);

    // Workspace fan-out: `jl test --all` at a workspace root runs every
    // member's tests in sequence.
    if (args.contains('--all') && Workspace.isRoot(dir)) {
      var code = 0;
      for (final member in Workspace.members(dir)) {
        print('==> Testing workspace member: ${member.path}');
        final outcome = await _runChildJl(['test', '--all', '--root', member.path, ..._stripRootFlag(args).where((a) => a != '--all')]);
        if (outcome != 0) code = outcome;
      }
      return code;
    }

    // Workspace fan-out: resolve the member owning the test file. The file
    // path is rewritten to be relative to the member root so the member's
    // manager can find the entry.
    if (positional.isNotEmpty && Workspace.isRoot(dir)) {
      final member = Workspace.memberOwning(dir, positional.first);
      if (member != null) {
        print('==> Workspace member: ${member.path}');
        // Rewrite the workspace-relative test-file positional to a
        // member-relative path; everything else is forwarded unchanged.
        final rest = <String>[];
        for (var i = 0; i < args.length; i++) {
          final a = args[i];
          if (a == '--root' && i + 1 < args.length) {
            i++;
            continue;
          }

          if (a.startsWith('--root=')) continue;

          if (a == positional.first) {
            final absPos = p.isAbsolute(a) ? a : p.join(dir.path, a);
            rest.add(p.relative(absPos, from: member.path));
          } else {
            rest.add(a);
          }
        }
        return _runChildJl(['test', ...rest, '--root', member.path]);
      }
      final rootCandidate = File(
        p.isAbsolute(positional.first) ? positional.first : p.join(dir.path, positional.first),
      );
      if (!rootCandidate.existsSync()) {
        stderr.writeln('Error: ${positional.first} is not inside a workspace member of $root');
        return 1;
      }
    }

    if (!RuntimeUtils.isJetLeafBuildProject(dir)) {
      stderr.writeln('Error: not a Jetleaf project: ${dir.path}');
      return 1;
    }
    final manager = JetleafControlClient.readManagerFile(dir);
    if (manager != null) {
      try {
        if (args.contains('--all')) {
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
        final innerPositional = _commandPositionals(args);
        if (innerPositional.isNotEmpty) {
          return await JetleafControlClient.sendControlRequest(dir, {
            'type': 'runTest',
            'entry': innerPositional.first,
            'args': _applicationArguments(args),
          });
        }
      } catch (_) {
        // Fall back to direct execution if manager unreachable
      }
    }

    // Direct Native Test Execution (Zero Daemon Required)
    await builder.runBuild(['--test'], root: dir);
    final directPositional = _commandPositionals(args);
    final testArgs = _applicationArguments(args);

    if (directPositional.isEmpty) {
      final (registryTests, nonRegistryTests) = _partitionTestFiles(dir);
      if (registryTests.isNotEmpty && nonRegistryTests.isNotEmpty) {
        _cleanDartToolTestCache(dir);
        final code1 = await _runDartTest(dir, [...registryTests, ...testArgs]);
        _cleanDartToolTestCache(dir);
        final code2 = await _runDartTest(dir, [...nonRegistryTests, ...testArgs]);
        return code1 != 0 ? code1 : code2;
      }
    }

    _cleanDartToolTestCache(dir);
    return await _runDartTest(dir, [...directPositional, ...testArgs]);
  }

  void _cleanDartToolTestCache(Directory dir) {
    final cacheDir = Directory(p.join(dir.path, '.dart_tool', 'test'));
    if (cacheDir.existsSync()) {
      try {
        cacheDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  }

  Future<int> _runDartTest(Directory dir, List<String> testArguments) async {
    final process = await Process.start(
      Platform.resolvedExecutable,
      ['test', ...testArguments],
      workingDirectory: dir.path,
      mode: ProcessStartMode.inheritStdio,
    );
    return await process.exitCode;
  }

  (List<String>, List<String>) _partitionTestFiles(Directory dir) {
    final testDir = Directory(p.join(dir.path, 'test'));
    if (!testDir.existsSync()) return (const [], const []);
    final testFiles = testDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('_test.dart'))
      .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    final cache = <String, bool>{};
    final registryTests = <String>[];
    final nonRegistryTests = <String>[];

    for (final file in testFiles) {
      final uri = file.absolute.uri.toString();
      final rel = p.relative(file.path, from: dir.path);
      if (_fileUsesTestRegistry(uri, cache)) {
        registryTests.add(rel);
      } else {
        nonRegistryTests.add(rel);
      }
    }
    return (registryTests, nonRegistryTests);
  }

  bool _fileUsesTestRegistry(String fileUri, Map<String, bool> cache, [Set<String>? visiting]) {
    if (cache.containsKey(fileUri)) return cache[fileUri]!;
    final visited = visiting ?? <String>{};
    if (!visited.add(fileUri)) return false;
    try {
      final file = File.fromUri(Uri.parse(fileUri));
      if (!file.existsSync()) return cache[fileUri] = false;
      final content = file.readAsStringSync();
      if (content.contains('_jetleaf/test') || content.contains('registerTestGeneratedArtifacts')) {
        return cache[fileUri] = true;
      }
      final importPattern = RegExp(
        r"""^\s*(?:import|export)\s+['"]([^'"]+)['"]""",
        multiLine: true,
      );

      for (final match in importPattern.allMatches(content)) {
        final rawImport = match.group(1);
        if (rawImport == null || rawImport.startsWith('dart:') || rawImport.startsWith('package:')) {
          continue;
        }

        final resolvedUri = Uri.parse(fileUri).resolve(rawImport).toString();
        if (_fileUsesTestRegistry(resolvedUri, cache, visited)) {
          return cache[fileUri] = true;
        }
      }
    } catch (_) {}
    return cache[fileUri] = false;
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

/// Removes `--root <dir>` / `--root=<dir>` from [args].
List<String> _stripRootFlag(List<String> args) {
  final stripped = <String>[];
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--root' && i + 1 < args.length) {
      i++;
      continue;
    }
    if (a.startsWith('--root=')) continue;
    stripped.add(a);
  }
  return stripped;
}

/// Spawns `jl` as a child process (used by workspace fan-out commands).
///
/// **Parameters:**
/// - [childArgs]: arguments passed to `jl` after the script path.
///
/// **Returns:** the child process exit code.
Future<int> _runChildJl(List<String> childArgs) async {
  final script = Platform.script.toFilePath(windows: false);
  final process = await Process.start(
    Platform.resolvedExecutable,
    ['run', script, ...childArgs],
    mode: ProcessStartMode.inheritStdio,
  );
  return await process.exitCode;
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
  --root <dir>     Project root (default: current directory). At a pub
                   workspace root, shows status for every member.
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
    final dir = Directory(root).absolute;
    if (Workspace.isRoot(dir)) {
      // Fan out to every member's manager.
      var code = 0;
      for (final member in Workspace.members(dir)) {
        print('==> ${member.path.split('/').last}:');
        final result = await JetleafControlClient.sendControlRequest(member, {'type': 'status'});
        if (result != 0) code = result;
      }
      return code;
    }
    return JetleafControlClient.sendControlRequest(dir, {'type': 'status'});
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
  --root <dir>     Project root (default: current directory). At a pub
                   workspace root without <file>, stops every member.
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
    final dir = Directory(root).absolute;
    final positional = args
      .where((a) => !a.startsWith('-') && a != _flagValue(args, '--root'))
      .toList();
    if (Workspace.isRoot(dir) && positional.isEmpty) {
      // Fan out a blanket stop to every member's manager.
      var code = 0;
      for (final member in Workspace.members(dir)) {
        print('==> Stopping ${member.path.split('/').last}...');
        final result = await JetleafControlClient.sendControlRequest(member, {'type': 'stop'});
        if (result != 0) code = result;
      }
      return code;
    }
    return JetleafControlClient.sendControlRequest(dir, {
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