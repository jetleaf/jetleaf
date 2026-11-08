import 'dart:io';

import 'package:jetleaf_tools/src/cli/jl_cli.dart';

/// CLI entry point for `jetleaf_tools`.
///
/// ```bash
/// dart run jetleaf_tools build
/// dart run jetleaf_tools dev
/// ```
Future<void> main(List<String> args) async {
  exitCode = await JlCli().run(args);
}