// Temporary stuck-isolate inspector (deleted after validation).
import 'dart:async';

import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

Future<void> main(List<String> args) async {
  final wsUri = args[0];
  final service = await vmServiceConnectUri(wsUri);
  final vm = await service.getVM();
  final isolateId = vm.isolates!.single.id!;
  await service.pause(isolateId);
  await Future.delayed(const Duration(milliseconds: 500));
  final isolate = await service.getIsolate(isolateId);
  print('paused: ${isolate.pauseEvent?.kind}');
  for (final limit in [1, 50]) {
    final stack = await service.getStack(isolateId, limit: limit);
    print('limit=$limit type=${stack.type} truncated=${stack.truncated}');
    var i = 0;
    for (final frame in stack.frames ?? []) {
      final fn = frame.function;
      print('#$i ${fn?.name} (${fn?.location?.script?.uri}:${fn?.location?.line})');
      if (++i >= 30) break;
    }
  }
  final isolate2 = await service.getIsolate(isolateId);
  print('pauseEvent: ${isolate2.pauseEvent?.kind}');
  await service.resume(isolateId);
  await service.dispose();
}
