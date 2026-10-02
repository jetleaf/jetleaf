import 'dart:io';

import '../common/logger.dart';
import '../common/prompts.dart' as prompt;
import '../command_runner/command_runner.dart';

part 'application_cli.dart';

/// {@template jetleaf_cli}
/// The base contract for **Jetleaf Command Line Interface (CLI)** entry points.
///
/// A [Cli] defines the lifecycle of the Jetleaf CLI process. It serves as the
/// starting point for command discovery, argument parsing, and command
/// delegation.
///
/// ### Overview
/// The [Cli] interface provides a single method, [run], which is responsible
/// for bootstrapping and executing all CLI commands.  
/// Implementations of this interface represent the executable surface of
/// the Jetleaf CLI and act as dispatchers for [CommandRunner] instances.
///
/// ### Responsibilities
/// - Initialize logging, environment, and session context.
/// - Parse and normalize command-line arguments.
/// - Identify and execute the appropriate [CommandRunner] based on user input.
/// - Handle unexpected errors or invalid commands gracefully.
///
/// ### Usage
/// To create a custom CLI entry point, implement this interface and
/// define the orchestration logic inside [run]:
///
/// ```dart
/// final class JetleafCli extends Cli {
///   const JetleafCli();
///
///   @override
///   Future<void> run(List<String> args) async {
///     if (args.isEmpty) {
///       print('Usage: jl <command> [options]');
///       return;
///     }
///
///     final command = args.first;
///     // Delegate execution to a CommandRunner
///     if (command == 'dev') {
///       await DevelopmentCommandRunner().run(args.skip(1).toList());
///     } else {
///       print('Unknown command: $command');
///     }
///   }
/// }
/// ```
///
/// ### Extensibility
/// You can build higher-level CLI applications by layering:
/// - [CommandRunner] subclasses for distinct subcommands (e.g., `build`, `dev`, `prod`)
/// - A custom [Cli] implementation to handle dispatching and environment setup
///
/// ### See Also
/// - [CommandRunner] — Contract for individual subcommand implementations.
/// - [CliLogger] — Provides structured logging for CLI sessions.
/// - [HelpCommandRunner] — Built-in runner for displaying help information.
/// - [VersionCommandRunner] — Built-in runner for version introspection.
/// {@endtemplate}
abstract interface class Cli {
  /// Creates a new [Cli] instance.
  ///
  /// Implementations should be stateless or lightweight, as Jetleaf
  /// manages the lifecycle and execution flow of CLI sessions.
  const Cli();

  /// Entry point for executing the Jetleaf CLI process.
  ///
  /// - [args]: The command-line arguments passed by the user.
  ///
  /// Implementations should perform initialization, argument parsing,
  /// and dispatch the request to an appropriate [CommandRunner].
  ///
  /// Example:
  /// ```dart
  /// await run(['build', '--release']);
  /// ```
  Future<void> run(List<String> args);
}