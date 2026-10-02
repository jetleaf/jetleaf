import 'dart:convert';
import 'dart:io';

import 'package:jetleaf_build/jetleaf_build.dart' show RuntimeBuildMode;
import 'package:jetleaf_cli/src/project/jetleaf_paths.dart';
import 'package:jetleaf_cli/src/project/context_metadata.dart';
import 'package:jetleaf_cli/src/cli/jetleaf_cli.dart';
import 'package:jetleaf_cli/src/project/project_state.dart';
import 'package:jetleaf_cli/src/project/toolchain_versions.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('jetleaf_cli_state_test_');
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  test('writes the project state as deterministic four-space JSON', () async {
    final paths = JetleafProjectPaths(root);
    final state = JetleafProjectState(
      name: 'example',
      rootPath: root.path,
      applicationFile: 'lib/main.dart',
      applicationLibrary: 'package:example/main.dart',
      applicationClass: 'Application',
      createdAt: DateTime.utc(2026, 1, 1),
    );

    await state.write(paths);
    final content = await paths.stateFile.readAsString();
    expect(content, startsWith('{\n    "schemaVersion": 1,'));
    expect(content, endsWith('\n'));
    expect(jsonDecode(content), isA<Map<String, dynamic>>());
  });

  test('serializes runtime mode as a validated enum value', () async {
    final paths = JetleafProjectPaths(root);
    final state = JetleafProjectState(
      name: 'example',
      rootPath: root.path,
      runtimeMode: RuntimeBuildMode.strict,
    );

    await state.write(paths);
    final decoded = jsonDecode(await paths.stateFile.readAsString());
    expect(decoded['runtime']['mode'], 'strict');
    expect(
      JetleafProjectState.fromJson(decoded).runtimeMode,
      RuntimeBuildMode.strict,
    );
  });

  test('resolves framework versions from the project lock file', () async {
    await File('${root.path}/pubspec.lock').writeAsString('''
packages:
  jetleaf:
    version: "2.4.0"
  jetleaf_cli:
    version: "2.4.1"
  jetleaf_build:
    version: "2.4.2"
  jetleaf_core:
    version: "2.4.3"
''');

    final versions = await JetleafToolchainVersions.resolve(root);
    expect(versions['jetleafVersion'], '2.4.0');
    expect(versions['cliVersion'], '2.4.1');
    expect(versions['buildVersion'], '2.4.2');
    expect(versions['coreVersion'], '2.4.3');
  });

  test('keeps generated files under the canonical workspace', () {
    final paths = JetleafProjectPaths(root);
    expect(paths.stateFile.path, endsWith('${Platform.pathSeparator}Jetleaf'));
    expect(paths.mainDirectory.path, contains('${Platform.pathSeparator}.jetleaf${Platform.pathSeparator}main'));
    expect(paths.cacheFile('main', 'packages.json').path, contains('${Platform.pathSeparator}.jetleaf${Platform.pathSeparator}cache'));
    expect(paths.buildFile('app.dill').path, endsWith('${Platform.pathSeparator}.jetleaf${Platform.pathSeparator}build${Platform.pathSeparator}app.dill'));
  });

  test('detects a Jetleaf project from its starter dependency', () async {
    await File('${root.path}/pubspec.yaml').writeAsString('''name: example
dependencies:
  jetleaf: any
''');
    final state = await const JetleafProjectDetector().detect(root);
    expect(state?.name, 'example');
    expect(state?.rootPath, root.absolute.path);
  });

  test('extracts Core context metadata without evaluating runtime conditions', () async {
    final source = File('${root.path}/lib.dart');
    await source.writeAsString('''
@JetleafApplicationStarter()
@EnableResource()
class Application {}

@Configuration()
@Service()
class UserService {}

@ConditionalOnProperty('enabled')
class OptionalService {}
''');
    final metadata = JetleafContextMetadata.fromSource(
      root: root,
      files: [source],
      applicationFile: 'lib.dart',
      applicationLibrary: 'package:example/lib.dart',
    );
    expect(metadata.applicationClass, 'Application');
    expect(metadata.enabledFeatures, contains('Resource'));
    expect(metadata.configurationClasses, contains('UserService'));
    expect(metadata.services, contains('UserService'));
    expect(metadata.conditionalDeclarations, contains('lib.dart:ConditionalOnProperty'));
  });

  test('create produces a runnable Jetleaf project skeleton', () async {
    final target = Directory('${root.path}/sample');
    expect(await const JetleafCli().run(['create', '--path', target.path]), 0);
    expect(File('${target.path}/pubspec.yaml').existsSync(), isTrue);
    expect(File('${target.path}/lib/main.dart').readAsStringSync(), contains('JetleafApplication.run'));
    expect(File('${target.path}/Jetleaf').existsSync(), isTrue);
  });
}
