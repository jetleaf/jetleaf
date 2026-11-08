import 'dart:io';

import 'package:jetleaf_tools/src/cli/jl_cli.dart';

/// Low-level CLI entry for `jetleaf_tools`.
///
/// ```bash
/// dart run jetleaf_tools dev
/// jl dev --daemon
/// ```
Future<void> main(List<String> args) async {
  exitCode = await JlCli().run(args);
}