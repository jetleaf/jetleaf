import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/utils.dart';
import '../utils/workspace.dart';
import '../vm/jetleaf_vm.dart';
import 'jl_command.dart';

/// {@template dev_command}
/// `jl dev` — starts the [JetleafVM] manager for a project.
///
/// Resident by default: discovers `@JetleafEntry` / `@JetleafTest` on
/// `void main()`, warms the shared cache, boots one VM per entry and
/// stays alive serving `jl run` / `jl test` / `jl status` / `jl stop`.
/// With `--once`: warms once and exits (CI-friendly, no VMs).
///
/// {@endtemplate}
final class DevCommand extends JlCommand {
  /// {@macro dev_command}
  const DevCommand();

  @override
  String get name => 'dev';

  @override
  String get description =>
      'Run the JetleafVM manager for this project.';

  @override
  String get usage => '''
Usage: jl dev [options]

Description:
  $description

  Discovers @JetleafEntry / @JetleafTest on void main(), warms the
  shared cache, boots one VM per entry and stays resident.
  Entry states are published to ./.jetleaf/vm/state.json.

Options:
  --root <dir>     Project root (default: current directory). A pub
                   workspace root (pubspec.yaml declares `workspace:`)
                   boots one manager per member instead.
  --path <file>    Scoped run: only boot this entry file (repeatable).
  --verbose        Stream in-isolate scan logs ([scan] …) to the terminal.
  --plain          Do not add timestamps and source prefixes to log lines.
  --once           Warm once and exit (no VMs, for CI).
  --lazy           Discover + warm now, boot entry VMs on first run.
  --machine        Emit JSON lines instead of human-readable output.
  -h, --help       Show this help.

Examples:
  jl dev
  jl dev --root ./my_app
  jl dev --path test/app_test.dart
  jl dev --once
''';

  /// Validates the root, then serves resident or warms once.
  ///
  /// **Parameters:**
  /// - [args]: supports `--root`, `--once`, `--lazy`, `--machine`,
  ///   repeatable `--path <file>` (scoped run, resident only) and
  ///   `--verbose` (scan logs).
  ///
  /// **Returns:** the manager/warm exit code.
  @override
  Future<int> run(List<String> args) async {
    if (args.contains('-h') || args.contains('--help')) {
      print(usage);
      return 0;
    }
    final machine = args.contains('--machine');
    final root = _flagValue(args, '--root') ?? Directory.current.path;

    final dir = Directory(root);
    if (!await dir.exists()) {
      _error(machine, 'root not found: $root');
      return 1;
    }

    // Workspace fan-out: `jl dev` at a workspace root boots one manager per
    // member (inherited stdio, aggregated exit code).
    if (Workspace.isRoot(dir)) {
      return _serveWorkspace(dir, args, machine);
    }

    if (!RuntimeUtils.isJetLeafBuildProject(dir)) {
      _error(machine,
          'not a Jetleaf project: ${dir.path} (expected `jetleaf_build:` in pubspec.yaml or .dart_tool/package_config.json)');
      return 1;
    }

    if (args.contains('--once')) {
      return JetleafVM.instance.warmOnce(dir, machine: machine);
    }

    final only = _flagValues(args, '--path');
    for (final raw in only) {
      final file = File(p.isAbsolute(raw) ? raw : p.join(dir.path, raw));
      if (!raw.endsWith('.dart') || !await file.exists()) {
        _error(machine, 'scoped path not found: $raw');
        return 1;
      }
    }

    if (_verbose(args) && !machine) {
      print('Verbose scan logs on ([scan] … lines).');
    }
    return JetleafVM.instance.serve(
      dir,
      machine: machine,
      lazy: args.contains('--lazy'),
      only: only.isEmpty ? null : only,
      verbose: _verbose(args),
      prettyLogs: !args.contains('--plain'),
    );
  }

  /// Reports a startup failure in machine or human form.
  ///
  /// **Parameters:**
  /// - [machine]: JSON error frame when true, stderr line otherwise.
  /// - [message]: failure description.
  void _error(bool machine, String message) {
    if (machine) {
      print(jsonEncode({'type': 'warm_error', 'error': message}));
    } else {
      stderr.writeln('Error: $message');
    }
  }

  /// Reads the current lifecycle state of a member's manager sidecar
  /// (`<member>/.jetleaf/vm/manager.json`), or `warming` when the file
  /// does not exist yet.
  ///
  /// **Parameters:**
  /// - [member]: member project root owning `.jetleaf/vm/manager.json`.
  ///
  /// **Returns:** the `state` field (`warming`, `ready`, `failed`).
  Future<String> _readMemberManagerState(Directory member) async {
    try {
      final file = File('${member.path}/.jetleaf/vm/manager.json');
      if (!file.existsSync()) return 'warming';
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return 'warming';
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['state'] is String) {
        return decoded['state'] as String;
      }
      return 'warming';
    } catch (_) {
      return 'warming';
    }
  }

  /// Boots one `jl dev` manager per workspace member.
  ///
  /// Members inherit stdio; the returned exit code is non-zero when any
  /// member exits non-zero. `--root`/`--once` are honored per member when
  /// passed through the argument list; `--once` spawns warms sequentially.
  ///
  /// **Parameters:**
  /// - [root]: workspace root (pubspec.yaml declares `workspace:`).
  /// - [args]: raw command arguments (forwarded with per-member `--root`).
  /// - [machine]: emit machine-readable JSON lines on failure.
  Future<int> _serveWorkspace(Directory root, List<String> args, bool machine) async {
    final members = Workspace.members(root);
    if (members.isEmpty) {
      _error(machine, 'workspace declares members in ${root.path}/pubspec.yaml but none exist on disk');
      return 1;
    }

    // Strip the root flag; each child gets its own per-member root.
    final forwarded = <String>[];
    for (var i = 0; i < args.length; i++) {
      final a = args[i];
      if (a == '--root' && i + 1 < args.length) {
        i++;
        continue;
      }
      if (a.startsWith('--root=')) continue;
      forwarded.add(a);
    }

    final once = forwarded.contains('--once');
    final script = Platform.script;
    if (once) {
      var failures = 0;
      for (final member in members) {
        print('==> Warming workspace member: ${member.path}');
        final result = await Process.start(
          Platform.resolvedExecutable,
          ['run', script.toFilePath(windows: false), 'dev', '--once', '--root', member.path, ...forwarded.where((a) => a != '--once')],
          mode: ProcessStartMode.inheritStdio,
        );
        final exitCode = await result.exitCode;
        if (exitCode != 0) failures++;
      }
      return failures == 0 ? 0 : 1;
    }

    final children = <Process>[];
    // Boot members sequentially and only kick off the next one once the
    // current member reports `ready` in its manager sidecar — racing several
    // warms at once starves the frontend compiler on busy machines.
    for (final member in members) {
      print('==> Starting workspace member: ${member.path}');
      final child = await Process.start(
        Platform.resolvedExecutable,
        ['run', script.toFilePath(windows: false), 'dev', '--root', member.path, ...forwarded],
        mode: ProcessStartMode.inheritStdio,
      );
      children.add(child);

      final deadline = DateTime.now().add(const Duration(seconds: 240));
      var state = await _readMemberManagerState(member);
      while (state == 'warming' && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        state = await _readMemberManagerState(member);
      }
      if (state == 'failed') {
        stderr.writeln('==> member reported failure: ${member.path}');
      }
    }

    var exitCode = 0;
    // Stream children's exit codes; terminate the rest when any child exits.
    final exits = <Process, int>{};
    for (final child in children) {
      unawaited(child.exitCode.then((code) {
        exits[child] = code;
        if (code != 0) exitCode = code;
        // A child exited (crash) — stop the rest of the fleet.
        for (final other in children) {
          if (other != child && exits[other] == null) {
            try {
              other.kill(ProcessSignal.sigterm);
            } catch (_) {
              // best-effort shutdown
            }
          }
        }
      }));
    }

    // When the user interrupts (SIGINT), terminate all members.
    try {
      ProcessSignal.sigint.watch().listen((_) {
        for (final child in children) {
          try {
            child.kill(ProcessSignal.sigint);
          } catch (_) {
            // already exited
          }
        }
      });
    } catch (_) {
      // Signal watching is not supported on every platform — members die
      // with the parent anyway when the parent's stdio is inherited.
    }

    await Future.wait(children.map((c) => c.exitCode));
    return exitCode;
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

  /// True when `--verbose` is present.
  ///
  /// **Returns:** whether scan logs stream to the terminal.
  bool _verbose(List<String> args) => args.contains('--verbose');

  /// Reads a repeatable `--flag value` / `--flag=value` option.
  ///
  /// **Parameters:**
  /// - [args]: raw command arguments.
  /// - [flag]: flag name including leading dashes.
  ///
  /// **Returns:** all values in order (empty when absent).
  List<String> _flagValues(List<String> args, String flag) {
    final values = <String>[];
    for (var i = 0; i < args.length; i++) {
      final a = args[i];
      if (a == flag && i + 1 < args.length) {
        values.add(args[i + 1]);
      } else if (a.startsWith('$flag=')) {
        values.add(a.substring(flag.length + 1));
      }
    }
    return values;
  }
}