import '../cache/indexer/daemon.dart';
import 'jl_command.dart';

/// {@template daemon_command}
/// Runs the Jetleaf builder daemon over stdin/stdout JSON protocol.
/// Used by the VS Code extension and external toolchains.
/// {@endtemplate}
final class DaemonCommand extends JlCommand {
  /// {@macro daemon_command}
  const DaemonCommand();

  @override
  String get name => 'daemon';

  @override
  String get description => 'Runs the builder daemon for IDEs and toolchains.';

  @override
  String get usage => '''
Usage: jl daemon

Runs the builder server in daemon mode, communicating via JSON lines over stdin and stdout.
''';

  @override
  Future<int> run(List<String> args) async {
    final handler = CommandHandler();
    await handler.start();
    return 0;
  }
}