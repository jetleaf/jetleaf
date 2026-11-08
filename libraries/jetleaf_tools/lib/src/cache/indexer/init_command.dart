import 'dart:io';

import '../../utils/constant.dart';

/// Init command — creates Jetleaf config file.
void runInit(List<String> args) {
  final flags = args.where((a) => a.startsWith('--')).toList();
  final positional = args.where((a) => !a.startsWith('--')).skip(1).toList();
  final recursive = flags.contains('--recursive') || flags.contains('-r');
  final targetDir = positional.isNotEmpty ? positional.first : Directory.current.path;

  final root = Directory(targetDir);
  if (!root.existsSync()) {
    stderr.writeln('Error: Directory not found: ${root.path}');
    exit(1);
  }

  final pubspecInTarget = File('${root.path}/pubspec.yaml').existsSync();

  if (!recursive && pubspecInTarget) {
    final configPath = '${root.path}/Jetleaf';
    if (File(configPath).existsSync()) {
      print('Already initialized: ${root.path}');
      return;
    }

    print('Initializing ${root.path} ...');
    _writeConfig(root);
    print('Done.');
    return;
  }

  print('Scanning for Dart projects in ${root.path} ...\n');

  final projects = _findProjects(root);

  if (projects.isEmpty) {
    print('No Dart projects found (no pubspec.yaml found).');
    return;
  }

  print('Found ${projects.length} project(s):\n');

  int initialized = 0;
  int skipped = 0;

  for (final project in projects) {
    final configPath = '${project.path}/Jetleaf';
    if (File(configPath).existsSync()) {
      print('  ${_relativePath(root, project)} — already initialized, skipping');
      skipped++;
      continue;
    }

    _writeConfig(project);
    print('  ${_relativePath(root, project)} — initialized');
    initialized++;
  }

  print('\nDone: $initialized initialized, $skipped skipped.');
}

List<Directory> _findProjects(Directory root) {
  final projects = <Directory>[];

  for (final entity in root.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('pubspec.yaml')) {
      final rel = entity.path.substring(root.path.length + 1);
      if (rel.startsWith('.dart_tool') ||
          rel.startsWith('build') ||
          rel.startsWith('node_modules') ||
          rel.contains('/.dart_tool/') ||
          rel.contains('/build/') ||
          rel.contains('/node_modules/')) {
        continue;
      }
      projects.add(Directory(entity.parent.path));
    }
  }

  projects.sort((a, b) => a.path.compareTo(b.path));
  return projects;
}

void _writeConfig(Directory project) {
  final pubspecFile = File('${project.path}/pubspec.yaml');
  var packageName = 'unknown';
  final jetleafDeps = <String>[];

  if (pubspecFile.existsSync()) {
    final lines = pubspecFile.readAsStringSync().split('\n');
    var inDeps = false;
    var inDevDeps = false;

    for (final line in lines) {
      final trimmed = line.trimLeft();

      if (trimmed.startsWith('name:')) {
        packageName = line.split(':').last.trim();
      }

      if (trimmed == 'dependencies:') {
        inDeps = true;
        inDevDeps = false;
        continue;
      }
      if (trimmed == 'dev_dependencies:') {
        inDeps = false;
        inDevDeps = true;
        continue;
      }

      if (inDeps || inDevDeps) {
        if (!line.startsWith(' ') && trimmed.contains(':')) {
          inDeps = false;
          inDevDeps = false;
        } else if (line.startsWith('  ') && !line.startsWith('    ') &&
            trimmed.contains(':') && trimmed.contains('jetleaf')) {
          final depName = trimmed.split(':').first.trim();
          if (!depName.startsWith('#') && !jetleafDeps.contains(depName)) {
            jetleafDeps.add(depName);
          }
        }
      }
    }
  }

  final config = {
    'version': 1,
    'name': packageName,
    'extensions': {
      'builder': {
        'enabled': true,
        'autoIndex': true,
        'indexOnStartup': true,
        'watchPaths': ['lib/', 'bin/', 'test/'],
        'excludePaths': [
          '.dart_tool/',
          'build/',
          '${Constant.WORKSPACE_DIR_NAME}/',
        ],
      },
      'devtool': {
        'enabled': true,
        'daemonPort': 9876,
        'autoHotReload': true,
        'showTerminal': true,
      },
    },
    'framework': {
      'packages': jetleafDeps.isNotEmpty ? jetleafDeps : ['jetleaf'],
    },
  };

  final yamlContent = _toYaml(config);
  File('${project.path}/Jetleaf').writeAsStringSync(yamlContent);
}

String _toYaml(Map<String, dynamic> map, {int indent = 0}) {
  final buf = StringBuffer();
  final pad = '  ' * indent;

  for (final entry in map.entries) {
    final key = entry.key;
    final value = entry.value;

    if (value is Map<String, dynamic>) {
      buf.writeln('$pad$key:');
      buf.write(_toYaml(value, indent: indent + 1));
    } else if (value is List) {
      buf.writeln('$pad$key:');
      for (final item in value) {
        buf.writeln('$pad  - $item');
      }
    } else if (value is String) {
      buf.writeln('$pad$key: "$value"');
    } else {
      buf.writeln('$pad$key: $value');
    }
  }

  return buf.toString();
}

String _relativePath(Directory base, Directory target) {
  final basePath = base.path;
  if (target.path.startsWith(basePath)) {
    final rel = target.path.substring(basePath.length);
    return rel.startsWith('/') ? rel.substring(1) : rel;
  }
  return target.path;
}
