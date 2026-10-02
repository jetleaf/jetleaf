import 'dart:io';

import 'build_command.dart';
import 'dev_command.dart';
import 'entry_commands.dart';
import 'help_command.dart';
import 'jl_command.dart';
import 'version_command.dart';

/// {@template jl_cli}
/// Dispatcher for the low-level `jl` CLI.
///
/// Registry pattern: add future commands to [_commands] only (and to
/// both [_help] overviews so `jl help` stays complete).
///
/// {@endtemplate}
final class JlCli {
  /// Registry of subcommands (mirrored in [_help] for `jl help`).
  final List<JlCommand> _commands;

  /// {@macro jl_cli}
  JlCli()
    : _commands = [
        const BuildCommand(),
        const DevCommand(),
        const RunCommand(),
        const TestCommand(),
        const StatusCommand(),
        const StopCommand(),
        const VersionCommand(),
        HelpCommand(const [
          BuildCommand(),
          DevCommand(),
          RunCommand(),
          TestCommand(),
          StatusCommand(),
          StopCommand(),
          VersionCommand(),
        ]),
      ];

  /// Dispatches `args` to the matching subcommand.
  ///
  /// Bare `jl`, `jl -h/--help` and `jl help [name]` print help;
  /// `-v/--version` prints the version; unknown commands print help
  /// and exit 1.
  ///
  /// **Parameters:**
  /// - [args]: raw CLI arguments (command keyword first).
  ///
  /// **Returns:** the subcommand exit code.
  Future<int> run(List<String> args) async {
    if (args.isEmpty ||
        args.contains('-h') && args.length == 1 ||
        args.contains('--help') && args.length == 1) {
      return _help().run([]);
    }
    if (args.contains('--version') || args.contains('-v')) {
      return const VersionCommand().run([]);
    }

    final name = args.first;
    if (name == 'help') return _help().run(args.skip(1).toList());

    for (final cmd in _commands) {
      if (cmd.name == name) {
        return cmd.run(args.skip(1).toList());
      }
    }

    stderr.writeln('Unknown command: "$name".');
    stderr.writeln('');
    await _help().run([]);
    return 1;
  }

  HelpCommand _help() => HelpCommand(const [
    BuildCommand(),
    DevCommand(),
    RunCommand(),
    TestCommand(),
    StatusCommand(),
    StopCommand(),
    VersionCommand(),
  ]);
}
