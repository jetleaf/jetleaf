/// {@template jl_command}
/// Base contract for all `jl` subcommands.
///
/// New commands implement this class and register themselves in
/// [JlCli]. Kept dependency-free so the low-level CLI stays lean.
///
/// {@endtemplate}
abstract class JlCommand {
  /// {@macro jl_command}
  const JlCommand();

  /// CLI keyword, e.g. `dev`.
  ///
  /// **Returns:** the command name.
  String get name;

  /// One-line description shown in general help.
  ///
  /// **Returns:** the description.
  String get description;

  /// Full usage text shown for `jl <name> --help`.
  ///
  /// **Returns:** the usage text.
  String get usage;

  /// Executes the command.
  ///
  /// **Parameters:**
  /// - [args]: arguments after the command keyword.
  ///
  /// **Returns:** the process exit code.
  Future<int> run(List<String> args);
}
