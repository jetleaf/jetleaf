// Temporary reload-poison probe (deleted after validation).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:frontend_server_client/frontend_server_client.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

const String targetPath =
    '/private/var/folders/l0/3x4l7s0j3578cqvk1b08r3jm0000gn/T/evalprobe/target.dart';

Future<void> main() async {
  final platformDill = p2.join(
    p2.dirname(p2.dirname(Platform.resolvedExecutable)),
    'lib',
    '_internal',
    'vm_platform_strong.dill',
  );
  final snapshotPath =
      '/private/var/folders/l0/3x4l7s0j3578cqvk1b08r3jm0000gn/T/evalprobe/snap.dill';
  final rootUri = 'org-dartlang-root:///$targetPath';
  final frontend = await FrontendServerClient.start(
    rootUri,
    snapshotPath,
    platformDill,
    target: 'vm',
    fileSystemRoots: ['/private/var/folders/l0/3x4l7s0j3578cqvk1b08r3jm0000gn/T/evalprobe'],
    fileSystemScheme: 'org-dartlang-root',
    packagesJson: '.dart_tool/package_config.json',
  );
  final first = await frontend.compile();
  frontend.accept();
  print('boot dill: ${first.dillOutput} errors=${first.errorCount}');

  final process = await Process.start(
    Platform.resolvedExecutable,
    ['--enable-vm-service=0', first.dillOutput!],
  );
  final ready = Completer<String>();
  process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
    if (!ready.isCompleted &&
        (line.contains('VM service is listening on') ||
            line.contains('VM Service is listening on'))) {
      final wsUri =
          '${line.split(' ').last.replaceFirst('http', 'ws').replaceFirst('/ws', '')}ws';
      ready.complete(wsUri);
    }
  });
  process.stderr.transform(utf8.decoder).listen(stdout.write);
  final service =
      await vmServiceConnectUri(await ready.future.timeout(const Duration(seconds: 30)));
  final vm = await service.getVM();
  final isolateId = vm.isolates!.single.id!;
  var isolate = await service.getIsolate(isolateId);
  var rootLibId = isolate.rootLib!.id!;

  // Touch the file + incremental recompile (mirrors jl run flow).
  await File('$targetPath.touched').writeAsString('// touched\n');
  final second = await frontend.compile([Uri.parse(rootUri)]);
  frontend.accept();
  print('recompile dill: ${second.dillOutput} errors=${second.errorCount}');
  final rootLibUri = Uri.file(second.dillOutput!).toString();
  await service.reloadSources(isolateId, pause: false, rootLibUri: rootLibUri);
  print('reload ok');
  isolate = await service.getIsolate(isolateId);
  rootLibId = isolate.rootLib!.id!;

  final stopwatch = Stopwatch()..start();
  try {
    final result = await service
        .evaluate(isolateId, rootLibId, 'probeAsync()')
        .timeout(const Duration(seconds: 8));
    print('[${stopwatch.elapsed}] evaluate returned: ${result.runtimeType}');
  } catch (e) {
    print('[${stopwatch.elapsed}] evaluate threw: $e');
  }
  for (var i = 0; i < 8; i++) {
    await Future.delayed(const Duration(seconds: 1));
    try {
      final flag = await service.evaluate(isolateId, rootLibId, 'probeDone');
      final isTrue = flag is InstanceRef && flag.valueAsString == 'true';
      print('[${stopwatch.elapsed}] flag done=$isTrue');
      if (isTrue) break;
    } catch (e) {
      print('[${stopwatch.elapsed}] flag read threw: $e');
      break;
    }
  }
  try {
    await frontend.shutdown().timeout(const Duration(seconds: 5));
  } catch (_) {}
  await service.dispose();
  process.kill();
}

// Minimal path helpers to avoid adding a dependency to the probe.
class p2 {
  static String join(String a, String b, [String? c, String? d, String? e]) =>
      [a, b, c, d, e].whereType<String>().join(Platform.pathSeparator);
  static String dirname(String p) => File(p).parent.path;
}
