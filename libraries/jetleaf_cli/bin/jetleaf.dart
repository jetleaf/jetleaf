import 'dart:io';

import 'package:jetleaf_cli/jetleaf_cli.dart';

Future<void> main(List<String> args) async {
  exitCode = await const JetleafCli().run(args);
}
