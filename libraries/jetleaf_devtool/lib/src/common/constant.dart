/// {@template cli_constant}
/// A centralized repository of constant values used across the Jetleaf CLI.
///
/// The [CliConstant] class defines command-line flags, directory names, and
/// other symbolic constants that are used throughout the Jetleaf tooling
/// ecosystem (e.g., in [ApplicationCli], [CommandRunner], and build pipelines).
///
/// This class is intentionally **non-instantiable**, as it serves purely as a
/// static configuration holder for CLI argument parsing and internal directory
/// management. To ensure immutability and consistency, all members are declared
/// as compile-time `const` values.
///
/// ### Key Responsibilities
/// - Defines consistent flag names for developer tooling (`--jetleaf-dev`, `--watch`, etc.)
/// - Standardizes the structure of generated resource directories (e.g., `lib/_jetleaf`)
/// - Ensures CLI feature parity between development, build, and runtime modes
///
/// ### References
/// - [ApplicationCli] – The main entry point for handling CLI arguments.
/// - [CommandRunner] – Subcommand abstraction that consumes these constants.
/// - [ApplicationFileWatcher] – Uses flags such as [DEV_HOT_RELOAD_FLAG].
/// - [CliArgumentParser] – May parse and interpret these constants during boot.
/// - [JetleafVersion] – Often displayed alongside CLI flags.
///
/// ### Example
/// ```dart
/// void main(List<String> args) {
///   if (args.contains(CliConstant.DEV_FLAG)) {
///     print("Running Jetleaf in developer mode.");
///   }
///
///   if (args.contains(CliConstant.DEV_HOT_RELOAD_FLAG)) {
///     print("Hot reload is enabled.");
///   }
/// }
/// ```
///
/// ### Notes
/// - The `GENERATED_DIR_NAME` directory (`_jetleaf/`) is framework-reserved.
/// - Flag names are case-sensitive and should **not** be renamed without
///   corresponding updates in command parsing logic.
///
/// {@endtemplate}
final class CliConstant {
  /// Private constructor to prevent instantiation.
  ///
  /// Use the static constants directly instead.
  const CliConstant._();

  /// Flag used to enable Jetleaf developer mode.
  ///
  /// When present, the CLI runs in development mode with enhanced logging,
  /// validation, and debugging support.
  ///
  /// Example: `jl <command> --jetleaf-dev`
  static const String DEV_FLAG = '--jetleaf-dev';

  /// Enables Jetleaf hot reload functionality during development.
  ///
  /// Example: `jl <command> --watch`
  static const String DEV_HOT_RELOAD_FLAG = '--watch';

  /// Disables Jetleaf hot reload functionality.
  ///
  /// Example: `jl <command> --no-watch`
  static const String DEV_HOT_RELOAD_FLAG_NEGATION = '--no-watch';
}