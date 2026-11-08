import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'jetleaf_vm.dart';

/// {@template control_client}
/// Client for the running [JetleafVM] control channel.
///
/// Sealed helpers (`abstract final`, static only): used by the `jl run` /
/// `jl test` / `jl status` / `jl stop` commands. Reads the manager sidecar
/// ([JetleafVmPaths.managerRelativePath]), opens one loopback connection
/// per request, prints human-readable output, and resolves with the exit
/// code when the server sends the terminal `done` frame.
///
/// {@endtemplate}
abstract final class JetleafControlClient {
  /// {@macro control_client}
  JetleafControlClient._();

  /// Reads the manager sidecar for [root].
  ///
  /// **Parameters:**
  /// - [root]: project root running `jl dev`.
  ///
  /// **Returns:** `{pid, projectRoot, controlPort, startedAt}`, or null
  /// when `jl dev` is not running here.
  static Map<String, dynamic>? readManagerFile(Directory root) {
    try {
      final file =
          File(p.join(root.path, JetleafVmPaths.managerRelativePath));
      if (!file.existsSync()) return null;
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Sends one request to the running `JetleafVM` control channel.
  ///
  /// **Parameters:**
  /// - [root]: project root running `jl dev`.
  /// - [request]: one protocol message (`runApp`, `runTest`, `status`,
  ///   `stop` — see `JetleafVM` control channel docs).
  ///
  /// **Returns:** the exit code (0 ok, 1 failed).
  static Future<int> sendControlRequest(
    Directory root,
    Map<String, Object?> request,
  ) async {
    final manager = readManagerFile(root);
    if (manager == null) {
      stderr.writeln(
          'Error: jl dev is not running for ${root.path} (no manager file).');
      return 1;
    }
    final port = manager['controlPort'] as int?;
    if (port == null) {
      stderr.writeln('Error: manager file has no control port.');
      return 1;
    }

    late Socket socket;
    try {
      socket = await Socket.connect(InternetAddress.loopbackIPv4, port)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      stderr.writeln('Error: cannot reach jl dev (port $port): $e');
      return 1;
    }

    var code = 1;
    final done = Completer<void>();
    try {
      socket.writeln(jsonEncode(request));
      await socket.flush();
      socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          try {
            final event = jsonDecode(line) as Map<String, dynamic>;
            code = _printEvent(event, code);
            if (event['type'] == 'done') {
              if (event['ok'] == true && code == 1) code = 0;
              if (!done.isCompleted) done.complete();
            }
          } catch (_) {}
        },
        onDone: () {
          if (!done.isCompleted) done.complete();
        },
        onError: (_) {
          if (!done.isCompleted) done.complete();
        },
      );
      await done.future;
    } finally {
      try {
        await socket.flush();
        await socket.close();
      } catch (_) {}
    }
    return code;
  }

  /// Prints one protocol event, threading the exit code through.
  ///
  /// **Parameters:**
  /// - [event]: decoded server frame.
  /// - [code]: running exit code.
  ///
  /// **Returns:** the updated exit code.
  static int _printEvent(Map<String, dynamic> event, int code) {
    switch (event['type']) {
      case 'log':
        final message = event['formatted'] ?? event['message'];
        if (message != null) print(message);
        return code;
      case 'run_step':
        print('  … ${event['step']}');
        return code;
      case 'run_started':
        print('running ${event['entry']} ...');
        return code;
      case 'run_complete':
        print('completed ${event['entry']}');
        return 0;
      case 'run_error':
        stderr.writeln('Error: ${event['error']}');
        return 1;
      case 'status_response':
        print(_formatStatus(event));
        return 0;
      case 'stopped':
        print('stopped');
        return 0;
      case 'error':
        stderr.writeln('Error: ${event['error']}');
        return 1;
      case 'done':
        return event['ok'] == true ? 0 : 1;
      default:
        return code;
    }
  }

  /// Renders a `status_response` frame as a human-readable table.
  ///
  /// **Parameters:**
  /// - [event]: decoded `status_response` frame.
  ///
  /// **Returns:** one `state  file  pid=… ws://…` line per entry.
  static String _formatStatus(Map<String, dynamic> event) {
    final buf = StringBuffer(
        'JetleafVM pid=${event['pid']} root=${event['projectRoot']}\n');
    final entries = (event['entries'] as List?) ?? const [];
    if (entries.isEmpty) {
      buf.writeln('  (no entries discovered)');
    }
    for (final entry in entries) {
      final e = entry as Map;
      final detail = [
        if (e['pid'] != null) 'pid=${e['pid']}',
        if (e['vmServiceUri'] != null) '${e['vmServiceUri']}',
      ].join(' ');
      buf.writeln('  ${'${e['state']}'.padRight(10)} ${e['file']}'
          '${detail.isEmpty ? '' : '  $detail'}');
    }
    return buf.toString();
  }
}
