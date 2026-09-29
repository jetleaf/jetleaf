// Temporary read-only inspector (deleted after validation).
import 'dart:async';

import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

Future<void> main(List<String> args) async {
  final service = await vmServiceConnectUri(args[0]);
  final vm = await service.getVM();
  final isolateId = vm.isolates!.single.id!;
  final isolate = await service.getIsolate(isolateId);
  final rootLibId = isolate.rootLib!.id!;
  print('rootLib: ${isolate.rootLib!.uri}');

  Future<void> show(String label, String expr) async {
    try {
      final result = await service.evaluate(isolateId, rootLibId, expr);
      var extra = '';
      if (result is InstanceRef && result.valueAsString != null) {
        extra = ' value=${result.valueAsString}';
      }
      print('$label => ${result.runtimeType}$extra');
    } catch (e) {
      print('$label THREW: $e');
    }
  }

  await show('sanity 1+1', '1 + 1');
  await show('ready flag', '_jlRuntimeReady');
  await show('testsDone flag', '_jlTestsDone');
  await show('testsPassed flag', '_jlTestsPassed');
  await show('runtimeError flag', '_jlRuntimeError');
  await show('timer probe',
      '(() async { await Future.delayed(Duration(seconds: 2)); _jlRuntimeError = "timer-ok"; })()');
  await show('main outcome',
      '(() async { try { final r = entry.main(); if (r is Future) await r; _jlRuntimeError = "main-ok"; } catch (e) { _jlRuntimeError = "main-threw: \$e"; } })()');
  await show('probe-delay',
      '(() async { await Future.delayed(Duration(seconds: 2)); _jlRuntimeError = "delay-ok"; })()');
  await show('probe-main-await',
      '(() async { final r = entry.main(); if (r is Future) await r; _jlRuntimeError = "main-ok"; })()');
  await show('probe-pump',
      '(() async { await pumpEventQueue(); _jlRuntimeError = "pump-ok"; })()');
  await service.dispose();
}
