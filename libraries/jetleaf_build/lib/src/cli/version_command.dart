import 'dart:io';

import 'jl_command.dart';

/// {@template version_command}
/// Prints the `jetleaf_build` package version.
///
/// Resolves `pubspec.yaml` by walking up from the running script, so both
/// `dart run jetleaf_build:jl` and compiled `jl` binaries report correctly.
///
/// {@endtemplate}
final class VersionCommand extends JlCommand {
  /// {@macro version_command}
  const VersionCommand();

  @override
  String get name => 'version';

  @override
  String get description => 'Print the jetleaf_build version.';

  @override
  String get usage => '''
Usage: jl version

Description:
  $description
''';

  @override
  Future<int> run(List<String> args) async {
    print('jl ${await _version()}');
    return 0;
  }

  /// Reads the `version:` field near the running script.
  ///
  /// Walks up to four levels from `Platform.script` (covers
  /// `bin/jl.dart` through pub-cache snapshot layouts).
  ///
  /// **Returns:** the version string, or `unknown` when unreadable.
  Future<String> _version() async {
    try {
      // bin/jl.dart -> packages/jetleaf_build/bin -> walk up to package root.
      var dir = Directory(Platform.script.toFilePath()).parent;
      for (var i = 0; i < 4; i++) {
        final pubspec = File('${dir.path}/pubspec.yaml');
        if (await pubspec.exists()) {
          for (final line in await pubspec.readAsLines()) {
            final t = line.trim();
            if (t.startsWith('version:')) {
              return t.split(':').last.trim();
            }
          }
        }
        dir = dir.parent;
      }
    } catch (_) {}
    return 'unknown';
  }
}
