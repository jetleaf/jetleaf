// Temporary evaluate-async probe (deleted after validation).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

Future<void> main() async {
  final target = File('/private/var/folders/l0/3x4l7s0j3578cqvk1b08r3jm0000gn/T/evalprobe/target.dart');
  final process = await Process.start(
    Platform.resolvedExecutable,
    ['--enable-vm-service=0', target.path],
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
  final wsUri = await ready.future.timeout(const Duration(seconds: 30));
  final service = await vmServiceConnectUri(wsUri);
  final vm = await service.getVM();
  final isolateId = vm.isolates!.single.id!;
  final isolate = await service.getIsolate(isolateId);
  final rootLibId = isolate.rootLib!.id!;

  final stopwatch = Stopwatch()..start();
  Response result;
  try {
    result = await service
        .evaluate(isolateId, rootLibId, 'probeAsync()')
        .timeout(const Duration(seconds: 8));
    print('[${stopwatch.elapsed}] evaluate returned: ${result.runtimeType}');
  } catch (e) {
    print('[${stopwatch.elapsed}] evaluate threw: $e');
    await service.dispose();
    process.kill();
    return;
  }
  for (var i = 0; i < 10; i++) {
    await Future.delayed(const Duration(seconds: 1));
    try {
      final flag = await service.evaluate(isolateId, rootLibId, 'probeDone');
      print('[${stopwatch.elapsed}] flag: $flag');
      if (flag is InstanceRef && flag.valueAsString == 'true') break;
    } catch (e) {
      print('[${stopwatch.elapsed}] flag read threw: $e');
      break;
    }
  }
  await service.dispose();
  process.kill();
}
