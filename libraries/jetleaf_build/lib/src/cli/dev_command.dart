import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/utils.dart';
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
  --root <dir>     Project root (default: current directory).
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
    if (!RuntimeUtils.isJetLeafBuildProject(dir)) {
      _error(machine,
          'not a jetleaf_build project: ${dir.path} (expected `jetleaf_build:` in pubspec.yaml or .dart_tool/package_config.json)');
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
