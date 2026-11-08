import 'jl_command.dart';

/// {@template help_command}
/// Prints general or per-command help.
///
/// `jl help` lists every registered command; `jl help <name>` (or
/// `jl <name> --help`) prints that command's [JlCommand.usage].
///
/// {@endtemplate}
final class HelpCommand extends JlCommand {
  /// {@macro help_command}
  const HelpCommand(this.commands);

  /// Commands listed in the overview, in display order.
  final List<JlCommand> commands;

  @override
  String get name => 'help';

  @override
  String get description => 'Show help for jl commands.';

  @override
  String get usage => '''
Usage: jl [command] [options]

${_overview()}

Run "jl <command> --help" for command details.
''';

  /// Renders the `Available commands:` overview block.
  ///
  /// **Returns:** one padded `name  description` line per command.
  String _overview() {
    final buf = StringBuffer('Available commands:\n');
    for (final c in commands) {
      buf.writeln('  ${c.name.padRight(10)} ${c.description}');
    }
    return buf.toString();
  }

  @override
  Future<int> run(List<String> args) async {
    if (args.isNotEmpty && args.first != '--help' && args.first != '-h') {
      final target = args.first;
      for (final c in commands) {
        if (c.name == target) {
          print(c.usage);
          return 0;
        }
      }
      print('Unknown command: $target\n');
    }
    print(usage);
    return 0;
  }
}
