import 'dart:io';

import 'package:jetleaf_build/src/vm/jetleaf_vm.dart';
import 'package:test/test.dart';

void main() {
  group('JetleafVmPaths.resolvePackagesJson', () {
    test('finds local package config first', () async {
      final dir = await Directory.systemTemp.createTemp('jl_pkg');
      try {
        final toolDir = Directory('${dir.path}/.dart_tool')..createSync();
        await File('${toolDir.path}/package_config.json')
            .writeAsString('{}');
        expect(JetleafVmPaths.resolvePackagesJson(dir),
            '${toolDir.path}/package_config.json');
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('inherits workspace root config when member has none', () async {
      final dir = await Directory.systemTemp.createTemp('jl_pkg');
      try {
        final toolDir = Directory('${dir.path}/.dart_tool')..createSync();
        await File('${toolDir.path}/package_config.json')
            .writeAsString('{}');
        final member = Directory('${dir.path}/libraries/my_pkg')
          ..createSync(recursive: true);
        // Walks up: member -> libraries -> temp root (has config).
        expect(JetleafVmPaths.resolvePackagesJson(member),
            '${toolDir.path}/package_config.json');
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });
}
