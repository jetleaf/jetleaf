import 'dart:convert';
import 'dart:io';

import 'package:jetleaf_build/jetleaf_build.dart';
import 'package:path/path.dart' as p;

import '../project/jetleaf_paths.dart';
import '../project/context_metadata.dart';
import '../project/project_state.dart';
import '../project/toolchain_versions.dart';

/// User-facing Jetleaf command dispatcher.
///
/// Low-level runtime commands remain implemented by `jetleaf_build`; this
/// class owns application project state and delegates runtime work to the
/// existing VM command registry.
final class JetleafCli {
  const JetleafCli();

  Future<int> run(List<String> args) async {
    if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
      _printHelp();
      return 0;
    }
    if (args.contains('--version') || args.contains('-v')) {
      final versions = await JetleafToolchainVersions.resolve(Directory.current);
      print('Jetleaf CLI ${versions['cliVersion'] ?? 'Unknown'}');
      return 0;
    }

    final command = args.first;
    final commandArgs = args.skip(1).toList();
    switch (command) {
      case 'create':
        return _create(commandArgs);
      case 'init':
        return _init(commandArgs);
      case 'build':
        return _build(commandArgs);
      case 'clean':
        return _clean(commandArgs);
      case 'proxy':
        return _proxy(commandArgs);
      case 'help':
        _printHelp(commandArgs.isEmpty ? null : commandArgs.first);
        return 0;
      case 'dev':
      case 'run':
      case 'test':
        return _runPrepared(command, commandArgs);
      case 'stop':
      case 'status':
      case 'version':
        return JlCli().run(args);
      default:
        stderr.writeln('Unknown command: $command');
        _printHelp();
        return 1;
    }
  }

  /// Prepares an application before delegating to the resident VM commands.
  ///
  /// `jetleaf dev` prepares metadata without starting a second manager because
  /// the delegated low-level command owns the resident manager lifecycle.
  /// `jetleaf run` and `jetleaf test` ensure that a manager is already alive so
  /// they work on a freshly created project as well as an initialized one.
  Future<int> _runPrepared(String command, List<String> args) async {
    final root = Directory(
      _value(args, '--root') ?? Directory.current.path,
    ).absolute;
    final paths = JetleafProjectPaths(root);
    var state = await JetleafProjectState.read(paths);

    if (state == null || !state.initialized) {
      final initArgs = <String>['--root', root.path];
      if (command == 'dev') initArgs.add('--no-warm');
      final initialized = await _init(initArgs);
      if (initialized != 0) return initialized;
      state = await JetleafProjectState.read(paths);
    }

    if (command != 'dev' && !_managerIsAvailable(paths)) {
      final warmResult = await _startWarmManager(root);
      if (warmResult != 0) return warmResult;
    }

    final forwarded = <String>[command, ...args];
    if (command == 'run' && _firstPositional(args) == null) {
      var entry = state?.applicationFile;
      if (entry == null) {
        final file = await _findApplication(root, args);
        if (file != null) entry = p.relative(file.path, from: root.path);
      }
      if (entry == null) {
        stderr.writeln('Error: no Jetleaf application entrypoint was found.');
        return 1;
      }
      forwarded.insert(1, entry);
    } else if (command == 'test' && _firstPositional(args) == null) {
      forwarded.insert(1, '--all');
    }

    return JlCli().run(forwarded);
  }

  /// Returns whether the resident manager sidecar points to a live process.
  bool _managerIsAvailable(JetleafProjectPaths paths) {
    final file = File(
      p.join(paths.vmDirectory.path, Constant.VM_MANAGER_FILE_NAME),
    );
    return file.existsSync() && _managerIsAlive(file);
  }

  /// Finds the first command positional while skipping known option values.
  String? _firstPositional(List<String> args) {
    final delimiter = args.indexOf('--');
    final commandArgs = delimiter == -1 ? args : args.sublist(0, delimiter);
    for (var index = 0; index < commandArgs.length; index++) {
      final value = commandArgs[index];
      if (value == '--root' || value == '--entry') {
        index++;
        continue;
      }
      if (value.startsWith('--root=') || value.startsWith('--entry=')) {
        continue;
      }
      if (!value.startsWith('-')) return value;
    }
    return null;
  }

  Future<int> _init(List<String> args) async {
    final root = Directory(_value(args, '--root') ?? Directory.current.path).absolute;
    final paths = JetleafProjectPaths(root);
    final detector = const JetleafProjectDetector();
    var state = await detector.detect(root);
    if (state == null) {
      stderr.writeln('Error: ${root.path} is not a Jetleaf project.');
      return 1;
    }

    state = state.copyWith(toolchain: await JetleafToolchainVersions.resolve(root));

    await paths.createDirectories();
    await paths.migrateLegacy();
    final application = await _findApplication(root, args);
    final tests = await _findTests(root);
    final packageName = state.name;
    final applicationFile = application == null ? null : p.relative(application.path, from: root.path);
    state = state.copyWith(
      applicationFile: applicationFile,
      applicationLibrary: applicationFile == null ? null : 'package:$packageName/${applicationFile.replaceFirst('lib${p.separator}', '')}',
      applicationClass: application == null ? null : _applicationClass(await application.readAsString()),
      tests: tests.map((file) => p.relative(file.path, from: root.path)).toList(growable: false),
      initialized: true,
      warmed: false,
    );
    await state.write(paths);
    final sourceFiles = await _dartFiles(Directory(p.join(root.path, 'lib')));
    await JetleafContextMetadata.fromSource(
      root: root,
      files: sourceFiles,
      applicationFile: state.applicationFile,
      applicationLibrary: state.applicationLibrary,
    ).write(paths);

    final buildArgs = <String>['build', '--root', root.path];
    if (args.contains('--skip-tree-shaking')) buildArgs.add('--skip-tree-shaking');
    final result = await JlCli().run(buildArgs);
    if (result != 0) return result;

    if (!args.contains('--no-warm')) {
      final warmResult = await _startWarmManager(root);
      if (warmResult != 0) return warmResult;
      state = state.copyWith(warmed: true, updatedAt: DateTime.now().toUtc());
    }

    await state.write(paths);
    print('Jetleaf project initialized: ${root.path}');
    print(state.warmed ? 'Resident Jetleaf VM is ready.' : 'Run `jetleaf dev` to warm the resident VM.');
    return 0;
  }

  Future<int> _build(List<String> args) async {
    final root = Directory(_value(args, '--root') ?? Directory.current.path).absolute;
    var state = await const JetleafProjectDetector().detect(root);
    if (state == null) {
      stderr.writeln('Error: ${root.path} is not a Jetleaf project.');
      return 1;
    }
    final metadataResult = await JlCli().run(['build', '--root', root.path, if (args.contains('--skip-tree-shaking')) '--skip-tree-shaking']);
    if (metadataResult != 0) return metadataResult;
    final entry = state.applicationFile ?? (await _findApplication(root, args))?.path;
    if (entry == null) {
      stderr.writeln('Error: no Jetleaf application entrypoint was found.');
      return 1;
    }
    if (state.applicationLibrary == null) {
      final relative = p.relative(entry, from: root.path);
      final file = relative.startsWith('lib${p.separator}')
          ? relative.substring('lib${p.separator}'.length)
          : relative;
      state = state.copyWith(
        applicationFile: relative,
        applicationLibrary: 'package:${state.name}/$file',
      );
    }
    final paths = JetleafProjectPaths(root);
    final output = paths.buildFile('app.dill');
    final launcher = paths.buildFile('launcher.dart');
    final library = state.applicationLibrary;
    if (library == null) {
      stderr.writeln('Error: application entrypoint has no package library.');
      return 1;
    }
    await output.parent.create(recursive: true);
    await launcher.writeAsString('''// GENERATED FILE. Do not edit.
import '$library' as application;

Future<void> main(List<String> args) async {
  final result = Function.apply(application.main, [args]);
  if (result is Future) await result;
}
''');
    final result = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'kernel',
      launcher.path,
      '-o',
      output.path,
    ], workingDirectory: root.path);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    if (result.exitCode != 0) return result.exitCode;
    await state.copyWith(
      initialized: true,
      updatedAt: DateTime.now().toUtc(),
    ).write(paths);
    print('Jetleaf VM kernel: ${output.path}');
    return 0;
  }

  Future<int> _startWarmManager(Directory root) async {
    final manager = JetleafProjectPaths(root).vmDirectory;
    final stateFile = File(p.join(manager.path, 'manager.json'));
    if (stateFile.existsSync() && _managerIsAlive(stateFile)) return 0;
    if (stateFile.existsSync()) await stateFile.delete();
    await Process.start(
      Platform.resolvedExecutable,
      ['run', 'jetleaf_build:jl', 'dev', '--root', root.path],
      workingDirectory: root.path,
      mode: ProcessStartMode.detached,
    );
    final deadline = DateTime.now().add(const Duration(minutes: 2));
    while (DateTime.now().isBefore(deadline)) {
      if (stateFile.existsSync()) return 0;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    stderr.writeln('Error: Jetleaf VM did not become ready in time.');
    return 1;
  }

  bool _managerIsAlive(File file) {
    try {
      final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final pid = (data['pid'] as num?)?.toInt();
      return pid != null && Process.killPid(pid, ProcessSignal.sigcont);
    } catch (_) {
      return false;
    }
  }

  Future<int> _create(List<String> args) async {
    final name = args.isEmpty || args.first.startsWith('-') ? 'example' : args.first;
    final root = Directory(_value(args, '--path') ?? p.join(Directory.current.path, name)).absolute;
    if (root.existsSync() && root.listSync().isNotEmpty) {
      stderr.writeln('Error: target directory is not empty: ${root.path}');
      return 1;
    }
    final packageName = _packageName(name);
    await root.create(recursive: true);
    await Directory(p.join(root.path, 'lib')).create(recursive: true);
    await Directory(p.join(root.path, 'test')).create(recursive: true);
    await File(p.join(root.path, 'pubspec.yaml')).writeAsString('''name: $packageName
description: A Jetleaf application.
publish_to: none
environment:
  sdk: ^3.9.0
dependencies:
  jetleaf: any
''');
    await File(p.join(root.path, 'lib', 'main.dart')).writeAsString('''import 'package:jetleaf/jetleaf.dart';

Future<void> main(List<String> args) async {
  await JetleafApplication.run(Application(), args);
}

@JetleafApplicationStarter()
class Application {}
''');
    final state = JetleafProjectState(
      name: packageName,
      rootPath: root.path,
      createdAt: DateTime.now().toUtc(),
      toolchain: await JetleafToolchainVersions.resolve(root),
    );
    await state.write(JetleafProjectPaths(root));
    print('Created Jetleaf project: ${root.path}');
    return 0;
  }

  Future<int> _clean(List<String> args) async {
    final root = Directory(_value(args, '--root') ?? Directory.current.path).absolute;
    final paths = JetleafProjectPaths(root);
    if (paths.vmDirectory.existsSync()) {
      await JlCli().run(['stop', '--root', root.path]);
    }
    if (args.contains('--all')) {
      if (paths.stateDirectory.existsSync()) await paths.stateDirectory.delete(recursive: true);
      if (paths.stateFile.existsSync()) await paths.stateFile.delete();
    } else {
      for (final directory in [paths.generatedDirectory, paths.proxyDirectory, paths.buildDirectory, paths.reportsDirectory]) {
        if (directory.existsSync()) await directory.delete(recursive: true);
      }
    }
    print('Cleaned Jetleaf state in ${root.path}');
    return 0;
  }

  Future<int> _proxy(List<String> args) async {
    final root = Directory(_value(args, '--root') ?? Directory.current.path).absolute;
    final result = await Process.run(
      Platform.resolvedExecutable,
      ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
      workingDirectory: root.path,
    );
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    return result.exitCode;
  }

  Future<File?> _findApplication(Directory root, List<String> args) async {
    final requested = _value(args, '--entry');
    if (requested != null) {
      final file = File(p.isAbsolute(requested) ? requested : p.join(root.path, requested));
      return file.existsSync() ? file : null;
    }
    final candidates = await _dartFiles(Directory(p.join(root.path, 'lib')));
    for (final file in candidates) {
      final content = await file.readAsString();
      if (content.contains('JetleafApplication.run(') && content.contains('JetleafApplicationStarter')) return file;
    }
    return null;
  }

  Future<List<File>> _findTests(Directory root) async => _dartFiles(Directory(p.join(root.path, 'test')));

  Future<List<File>> _dartFiles(Directory directory) async {
    if (!directory.existsSync()) return const [];
    final files = <File>[];
    await for (final entity in directory.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('.dart')) files.add(entity);
    }
    files.sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  String? _applicationClass(String content) => RegExp(r'@JetleafApplicationStarter(?:\s*\([^)]*\))?\s*class\s+(\w+)').firstMatch(content)?.group(1);
  String? _value(List<String> args, String flag) {
    final index = args.indexOf(flag);
    if (index >= 0 && index + 1 < args.length) return args[index + 1];
    final prefix = '$flag=';
    return args.where((value) => value.startsWith(prefix)).map((value) => value.substring(prefix.length)).firstOrNull;
  }

  String _packageName(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]+'), '_');

  void _printHelp([String? command]) {
    if (command != null) {
      print('Usage: jetleaf $command [options]');
      return;
    }
    print('''Jetleaf CLI

Commands:
  create    Create a Jetleaf application
  init      Discover, validate, and prepare project metadata
  dev       Start the resident development VM
  test      Run a test through the resident VM
  build     Build runtime metadata and the VM artifact
  run       Run an application entry through the resident VM
  proxy     Generate application proxies
  clean     Remove generated Jetleaf state
  stop      Stop resident VMs
  status    Show runtime status
  help      Show command help
''');
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
