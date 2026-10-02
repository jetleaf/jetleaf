import 'dart:io';

import 'package:jetleaf_build/src/cli/jl_cli.dart';

/// Low-level CLI entry for `jetleaf_build`.
///
/// ```bash
/// dart run jetleaf_build dev
/// jl dev --daemon
/// ```
Future<void> main(List<String> args) async {
  exitCode = await JlCli().run(args);
}
