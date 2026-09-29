import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../manager/cacheable_manager.dart';
import '../scanner/cache_scanners.dart';
import 'declaration_builder.dart';
import 'file_discovery.dart';

/// Daemon mode — stdin/stdout JSON protocol for VS Code extension.
final class CommandHandler {
  late final Directory _projectRoot;
  late final String _packageName;
  bool _isBuilding = false;

  /// Starts listening for commands on stdin.
  void start() {
    _projectRoot = Directory.current;
    _packageName = _resolvePackageName();

    stdin
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleMessage);

    _send({'type': 'ready', 'projectRoot': _projectRoot.path});
  }

  /// Handles an incoming JSON message.
  void _handleMessage(String line) {
    try {
      final message = jsonDecode(line) as Map<String, dynamic>;
      _processMessage(message);
    } catch (e) {
      _send({'type': 'error', 'error': 'Invalid message: $e'});
    }
  }

  /// Processes a decoded JSON message.
  void _processMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;

    switch (type) {
      case 'build':
        _handleBuild(message);
        break;
      case 'file_changed':
        _handleFileChanged(message);
        break;
      case 'status':
        _handleStatus();
        break;
      case 'stop':
        _handleStop();
        break;
      default:
        _send({'type': 'error', 'error': 'Unknown message type: $type'});
    }
  }

  /// Handles a build request.
  Future<void> _handleBuild(Map<String, dynamic> message) async {
    if (_isBuilding) {
      _send({'type': 'error', 'error': 'Build already in progress'});
      return;
    }

    _isBuilding = true;
    _send({'type': 'build_started'});

    try {
      final config = message['config'] as Map<String, dynamic>?;
      final packagesToExclude =
          (config?['packagesToExclude'] as List<dynamic>?)?.cast<String>() ??
              [];
      final packagesToScan =
          (config?['packagesToScan'] as List<dynamic>?)?.cast<String>() ??
              [];

      // 1. Discovery
      _send({'type': 'build_progress', 'phase': 'discovery', 'status': 'scanning'});
      final discovery = FileDiscovery(_projectRoot);
      final files = await discovery.discover(
        skipTests: false,
        packagesToExclude: packagesToExclude,
        packagesToScan: packagesToScan,
        filesToExclude: [],
      );

      final fileCount = files.dartFiles.length;
      _send({
        'type': 'build_progress',
        'phase': 'discovery',
        'filesFound': fileCount,
      });

      // 2. Analysis
      _send({'type': 'build_progress', 'phase': 'analysis', 'current': 0, 'total': fileCount});
      final declarationBuilder = DeclarationBuilder();
      final components = await declarationBuilder.build(
        files: files,
        packageName: _packageName,
      );

      int analyzedCount = 0;
      for (final component in components) {
        analyzedCount++;
        _send({
          'type': 'build_progress',
          'phase': 'analysis',
          'current': analyzedCount,
          'total': fileCount,
          'library': component.getLibrary().getUri(),
        });
      }

      // 3. Write cache
      _send({'type': 'build_progress', 'phase': 'cache', 'status': 'writing'});
      final cacheWriter = CacheWriter(_projectRoot);

      final prodFingerprint = CacheManager.generateFingerprint(
        skipTests: true,
        packagesToExclude: packagesToExclude,
        packagesToScan: packagesToScan,
      );
      final prodComponents = components.where((c) {
        return !c.getLibrary().getUri().contains('/test/');
      }).toList();
      await cacheWriter.writeWithComponents(
        components: prodComponents,
        fingerprint: prodFingerprint,
        forTests: false,
      );

      final testFingerprint = CacheManager.generateFingerprint(
        skipTests: false,
        packagesToExclude: packagesToExclude,
        packagesToScan: packagesToScan,
      );
      final testSummary = await cacheWriter.writeWithComponents(
        components: components,
        fingerprint: testFingerprint,
        forTests: true,
      );

      _send({
        'type': 'build_complete',
        'components': testSummary.components.length,
        'libraries': testSummary.components.map((c) => c.getLibrary().getUri()).toSet().length,
        'packages': testSummary.packages.length,
        'assets': testSummary.assets.length,
        'fingerprint': prodFingerprint,
      });
    } catch (e) {
      _send({'type': 'build_error', 'error': e.toString()});
    } finally {
      _isBuilding = false;
    }
  }

  /// Handles a file change notification.
  void _handleFileChanged(Map<String, dynamic> message) {
    final path = message['path'] as String?;
    if (path == null) {
      _send({'type': 'error', 'error': 'Missing path in file_changed'});
      return;
    }

    if (!_isBuilding) {
      _handleBuild({'type': 'build', 'config': {'skipTests': true}});
    }
  }

  /// Handles a status request.
  void _handleStatus() {
    final prodFingerprint = CacheManager.generateFingerprint(skipTests: true);
    final cacheValid = CacheManager.isValid(_projectRoot, configFingerprint: prodFingerprint);
    final result = CacheManager.load(_projectRoot, configFingerprint: prodFingerprint);

    _send({
      'type': 'status_response',
      'isBuilding': _isBuilding,
      'cacheValid': cacheValid,
      'fingerprint': prodFingerprint,
      'projectRoot': _projectRoot.path,
      'packageName': _packageName,
      'components': result?.components.length ?? 0,
    });
  }

  /// Handles a stop request.
  void _handleStop() {
    _send({'type': 'stopped'});
    exit(0);
  }

  void _send(Map<String, dynamic> message) {
    stdout.writeln(jsonEncode(message));
  }

  String _resolvePackageName() {
    final pubspecFile = File('${_projectRoot.path}/pubspec.yaml');
    if (!pubspecFile.existsSync()) return 'unknown';

    try {
      final content = pubspecFile.readAsStringSync();
      for (final line in content.split('\n')) {
        if (line.trimLeft().startsWith('name:')) {
          return line.split(':').last.trim();
        }
      }
    } catch (_) {}

    return 'unknown';
  }
}