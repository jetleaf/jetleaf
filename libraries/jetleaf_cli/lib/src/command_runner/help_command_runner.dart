part of 'command_runner.dart';

/// {@template jetleaf_help_command_runner}
/// A built-in CLI subcommand that displays contextual help information
/// for available **Jetleaf CLI** commands.
///
/// The `HelpCommandRunner` serves as the entry point for `jl --help` or
/// `jl -h`, providing formatted usage information, command descriptions,
/// and guidance on how to use each registered subcommand.
///
/// ### Behavior
///
/// 1. **General Help**
///    - When invoked without arguments, it displays a summary of all
///      registered CLI commands, including their descriptions and usage
///      syntax.
///
/// 2. **Command-Specific Help**
///    - When a command name is provided (e.g., `jl build --help`),
///      this runner locates the associated [CommandRunner] and prints its
///      detailed usage message.
///
/// 3. **Error Handling**
///    - If an unknown command is provided, the runner logs an error and
///      displays the general help screen.
///
/// ### Output Formatting
///
/// Each registered subcommand’s usage information is rendered inside a
/// decorative ASCII box for better readability:
///
/// ```text
/// ┌────────────────────────────────────────────────────────────────────────────┐
/// │ Usage: jl --version                                                       │
/// │                                                                            │
/// │ Description:                                                               │
/// │   Displays the current version of the JL CLI and related tooling.          │
/// └────────────────────────────────────────────────────────────────────────────┘
/// ```
///
/// The output automatically wraps long lines to maintain consistent
/// alignment within an 80-character box width.
///
/// ### Example
///
/// ```bash
/// $ jl --help
/// Jetleaf CLI - Command Line Interface
///
/// Available Commands:
///   ┌────────────────────────────────────────────────────────────────────────┐
///   │ Usage: jl dev                                                          │
///   │ Description: Starts Jetleaf in development mode.                       │
///   └────────────────────────────────────────────────────────────────────────┘
///
/// Run "jl <command> --help" for more information on a specific command.
/// ```
///
/// ### Extensibility
/// To include custom command runners in this help system, simply extend
/// [CommandRunner] and add your runner to the static `_runners` list.
///
/// ### See Also
/// - [CommandRunner] — Base contract for Jetleaf CLI commands.
/// - [CliLogger] — Structured logging API used for CLI diagnostics.
/// - [VersionCommandRunner] — Companion command for displaying CLI version.
/// {@endtemplate}
final class HelpCommandRunner extends CommandRunner {
  /// Creates a new instance of the `--help` command runner.
  ///
  /// {@macro jetleaf_help_command_runner}
  const HelpCommandRunner();

  /// A static list of registered command runners that this help system
  /// can display documentation for.
  ///
  /// Add your own runners here to make them visible in the `--help` output.
  static const List<CommandRunner> RUNNERS = [
    DevelopmentCommandRunner(),
    ProductionCommandRunner(),
    HotReloadCommandRunner(),
    VersionCommandRunner(),
    InfoCommandRunner(),
    ProxyCommandRunner(),
    PauseCommandRunner()
  ];

  @override
  String get command => '--help';

  @override
  String get description => 'Displays help information for available commands or the entire application.';

  @override
  CliLogger get logger => cliSession.get(command.toUpperCase());

  @override
  String get usage => '''
Usage: jl $command [options]

Description:
  $description

Available Commands:
${_buildUsagesFromOtherCommandRunner()}

Optional Command-Line Args For Build:
${BuildArg.getCommandLineUsage()}

Run "jl <command> --help" for more information on a specific command.
''';

  /// Dynamically constructs formatted help boxes for all registered
  /// [CommandRunner] instances in [RUNNERS].
  String _buildUsagesFromOtherCommandRunner() {
    const boxWidth = 80;
    final buffer = StringBuffer();

    for (final runner in RUNNERS) {
      final usage = runner.usage.trimRight();
      final lines = usage.split('\n');
      final horizontalBorder = '┌${'─' * (boxWidth - 2)}┐';

      buffer.writeln(horizontalBorder);

      for (final line in lines) {
        // Wrap long lines *without collapsing indentation or spacing*
        final wrapped = _preserveWrap(line, boxWidth - 4);
        for (final wLine in wrapped) {
          final padded = wLine.padRight(boxWidth - 4);
          buffer.writeln('│ $padded │');
        }
      }

      buffer.writeln('└${'─' * (boxWidth - 2)}┘');
      buffer.writeln();
    }

    // Add indentation to align with “Available Commands:”
    return buffer.toString().split('\n').map((line) {
      if (line.trim().isEmpty) return line;
      return '  $line'; // 2-space tab for visual alignment
    }).join('\n');
  }

  @override
  Future<void> run(List<String> args) async {
    print('Jetleaf CLI - Command Line Interface');
    logger.space();

    if (args.isEmpty || (args.length == 1 && args.first.equalsAny(['--help', '-h']))) {
      logger.warn('No command specified. Showing general help.');
      logger.space();
      print(usage);
    } else {
      final commandName = args.first;
      try {
        final targetCommand = RUNNERS.firstWhere((cmd) => cmd.command == commandName);
        print(targetCommand.usage);
      } catch (e) {
        logger.error('❌ Unknown command: $commandName');
        logger.space();
        print(usage);
      }
    }
  }
}