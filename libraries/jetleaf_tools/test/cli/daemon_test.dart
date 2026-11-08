@Timeout(Duration(seconds: 90))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:jetleaf_tools/src/cli/jl_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Builder Server Daemon', () {
    late Directory tempDir;
    late String jlScriptPath;

    setUpAll(() {
      final currentDir = Directory.current.path;
      jlScriptPath = p.join(currentDir, 'bin', 'jl.dart');
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('jl_daemon_test_');
      await File('${tempDir.path}/pubspec.yaml').writeAsString('''
name: demo_daemon_project
dependencies:
  jetleaf_pod: any
''');
      final libDir = Directory('${tempDir.path}/lib')..createSync(recursive: true);
      final toolDir = Directory('${tempDir.path}/.dart_tool')..createSync(recursive: true);
      await File('${toolDir.path}/package_config.json').writeAsString('''{
  "configVersion": 2,
  "packages": [
    {
      "name": "demo_daemon_project",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "3.0"
    }
  ]
}''');
      await File('${libDir.path}/service.dart').writeAsString('''
import 'package:jetleaf_pod/pod.dart';

@Service()
class GreeterService {
  String sayHello(String name) => "Hello, \$name!";
}

@Controller()
class UserController {
  final GreeterService greeter;
  UserController(this.greeter);
}
''');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('jl cli recognises daemon command in help', () async {
      final cli = JlCli();
      expect(await cli.run(['help', 'daemon']), 0);
    });

    test('spawns daemon and handles status, build, and stop protocol', () async {
      final dartExe = Platform.resolvedExecutable;
      final rawPkgConfig = Platform.packageConfig;
      final args = <String>['run'];
      if (rawPkgConfig != null) {
        final pkgPath = rawPkgConfig.startsWith('file:')
            ? Uri.parse(rawPkgConfig).toFilePath()
            : rawPkgConfig;
        args.add('--packages=$pkgPath');
      }
      args.addAll([jlScriptPath, 'daemon']);

      final process = await Process.start(
        dartExe,
        args,
        workingDirectory: tempDir.path,
      );

      final readyCompleter = Completer<Map<String, dynamic>>();
      final statusCompleter = Completer<Map<String, dynamic>>();
      final buildCompleter = Completer<Map<String, dynamic>>();
      final stopCompleter = Completer<Map<String, dynamic>>();

      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          switch (json['type']) {
            case 'ready':
              if (!readyCompleter.isCompleted) readyCompleter.complete(json);
              break;
            case 'status_response':
              if (!statusCompleter.isCompleted) statusCompleter.complete(json);
              break;
            case 'build_complete':
              if (!buildCompleter.isCompleted) buildCompleter.complete(json);
              break;
            case 'stopped':
              if (!stopCompleter.isCompleted) stopCompleter.complete(json);
              break;
          }
        } catch (_) {}
      });

      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {});

      // 1. Wait for ready message
      final readyJson = await readyCompleter.future.timeout(const Duration(seconds: 30));
      expect(readyJson['type'], equals('ready'));
      expect(readyJson['projectRoot'], isNotNull);

      // 2. Send status request
      process.stdin.writeln(jsonEncode({'type': 'status'}));
      final statusJson = await statusCompleter.future.timeout(const Duration(seconds: 30));
      expect(statusJson['type'], equals('status_response'));
      expect(statusJson['packageName'], equals('demo_daemon_project'));

      // 3. Send build request
      process.stdin.writeln(jsonEncode({
        'type': 'build',
        'config': {
          'skipTests': false,
          'packagesToExclude': <String>[],
          'packagesToScan': <String>[],
        },
      }));

      // Wait for build_complete
      final completeJson = await buildCompleter.future.timeout(const Duration(seconds: 30));
      expect(completeJson['type'], equals('build_complete'));
      expect(completeJson['components'], greaterThan(0));

      // Verify that cache and AOT registrar were written
      final cacheDir = Directory('${tempDir.path}/.jetleaf/cache/main');
      expect(cacheDir.existsSync(), isTrue);
      final generatedAotFile = File('${tempDir.path}/lib/_jetleaf/aot_registry.g.dart');
      expect(generatedAotFile.existsSync(), isTrue);

      final generatedPodsFile = File('${tempDir.path}/lib/_jetleaf/sample_app/registry_pods.g.dart');
      expect(generatedPodsFile.existsSync(), isTrue);

      final aotContent = await generatedPodsFile.readAsString();
      expect(aotContent, contains('GreeterService'));
      expect(aotContent, contains('UserController'));

      // 4. Send stop request
      process.stdin.writeln(jsonEncode({'type': 'stop'}));
      final stoppedJson = await stopCompleter.future.timeout(const Duration(seconds: 10));
      expect(stoppedJson['type'], equals('stopped'));

      final exitCode = await process.exitCode.timeout(const Duration(seconds: 5));
      expect(exitCode, equals(0));
    });
  });
}
