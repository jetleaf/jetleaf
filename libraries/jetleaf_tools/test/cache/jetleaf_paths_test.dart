import 'dart:io';

import 'package:jetleaf_tools/src/cache/jetleaf_paths.dart';
import 'package:jetleaf_core/lang.dart';
import 'package:test/test.dart';
import '../helpers/aot_test_setup.dart' show ensureTestAotRegisteredSync;

/// Verifies the workspace contract used by every Jetleaf layer.
void main() {
  ensureTestAotRegisteredSync();
  test('constructs every canonical workspace location from one policy', () {
    final root = Directory('/workspace/example');

    expect(JetleafPaths.stateFile(root).path, '/workspace/example/Jetleaf');
    expect(
      JetleafPaths.projectDir(root).path,
      '/workspace/example/.jetleaf/project',
    );
    expect(
      JetleafPaths.generatedDir(root).path,
      '/workspace/example/.jetleaf/generated',
    );
    expect(
      JetleafPaths.vmDir(root).path,
      '/workspace/example/.jetleaf/vm',
    );
    expect(
      JetleafPaths.runtimeManifest(root).path,
      '/workspace/example/.jetleaf/project/runtime.json',
    );
    expect(
      JetleafPaths.runtimeRegistry(root).path,
      '/workspace/example/.jetleaf/main/registry.dart',
    );
  });

  test('keeps migration names separate from canonical names', () {
    expect(Constant.WORKSPACE_DIR_NAME, '.jetleaf');
    expect(Constant.JETLEAF_GENERATED_DIR_NAME, '_jetleaf');
    expect(Constant.LEGACY_VM_STATE_FILE_NAME, 'Jetleaf.VM');
  });
}