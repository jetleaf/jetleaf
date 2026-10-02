// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & Jetleaf Contributors. All rights reserved.
//
// This source file is part of the Jetleaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the Jetleaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'dart:io';

import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_logging/logging.dart';
import 'package:jetleaf_web/src/context/aware.dart';
import 'package:jetleaf_web/src/context/default_server_context.dart';
import 'package:jetleaf_web/src/context/server_context.dart';
import 'package:jetleaf_web/src/web/web.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// 🧪 Mocks
// ---------------------------------------------------------------------------

class MockServerContext implements ServerContext {
  String _contextPath = ServerContext.SERVER_CONTEXT_PATH;
  final Map<String, Object> _attributes = {};
  bool _logCalled = false;

  bool get logCalled => _logCalled;

  @override
  String getContextPath() => _contextPath;

  @override
  Object? getAttribute(String name) => _attributes[name];

  @override
  void setAttribute(String name, Object value) => _attributes[name] = value;

  @override
  void removeAttribute(String name) => _attributes.remove(name);

  @override
  Iterable<String> getAttributeNames() => _attributes.keys;

  @override
  Log get log {
    _logCalled = true;
    return LogFactory.getLog("mock-server");
  }

  void setContextPathForTest(String path) => _contextPath = path;
}

class MockWebServer implements WebServer {
  bool _started = false;
  bool _stopped = false;
  final int _port;
  final String _host;

  bool get started => _started;
  bool get stopped => _stopped;

  MockWebServer({int port = 8080, String host = 'localhost'})
      : _port = port,
        _host = host;

  @override
  int getPort() => _port;

  @override
  InternetAddress? getAddress() => InternetAddress(_host);

  @override
  Uri? getUri() => Uri.parse('http://$_host:$_port');

  @override
  bool isRunning() => _started && !_stopped;

  @override
  bool isAutoStartup() => true;

  @override
  int getPhase() => 0;

  @override
  Future<void> start() async {
    _started = true;
  }

  @override
  Future<void> stop([Runnable? callback]) async {
    _stopped = true;
    callback?.run();
  }
}

class TestServerContextAware implements ServerContextAware {
  ServerContext? receivedContext;

  @override
  void setServerContext(ServerContext context) {
    receivedContext = context;
  }
}

class TestWebServerAware implements WebServerAware {
  WebServer? receivedServer;

  @override
  void setWebServer(WebServer server) {
    receivedServer = server;
  }
}

class TestContextPathAware implements ContextPathAware {
  String? receivedContextPath;

  @override
  void setContextPath(String contextPath) {
    receivedContextPath = contextPath;
  }
}

class TestMultiAware implements ServerContextAware, WebServerAware, ContextPathAware {
  ServerContext? receivedContext;
  WebServer? receivedServer;
  String? receivedContextPath;

  @override
  void setServerContext(ServerContext context) {
    receivedContext = context;
  }

  @override
  void setWebServer(WebServer server) {
    receivedServer = server;
  }

  @override
  void setContextPath(String contextPath) {
    receivedContextPath = contextPath;
  }
}

class PlainPod {
  final String name;
  PlainPod(this.name);
}

void main() {
  // ========================================================================
  // Aware Interfaces
  // ========================================================================

  group('ServerContextAware', () {
    test('can be implemented by a concrete class', () {
      final aware = TestServerContextAware();
      expect(aware, isA<ServerContextAware>());
    });

    test('setServerContext stores the provided context', () {
      final aware = TestServerContextAware();
      final context = MockServerContext();

      aware.setServerContext(context);

      expect(aware.receivedContext, same(context));
    });

    test('setServerContext can be called multiple times', () {
      final aware = TestServerContextAware();
      final ctx1 = MockServerContext();
      final ctx2 = MockServerContext();

      aware.setServerContext(ctx1);
      expect(aware.receivedContext, same(ctx1));

      aware.setServerContext(ctx2);
      expect(aware.receivedContext, same(ctx2));
    });

    test('different implementations store independently', () {
      final aware1 = TestServerContextAware();
      final aware2 = TestServerContextAware();
      final ctx = MockServerContext();

      aware1.setServerContext(ctx);

      expect(aware1.receivedContext, same(ctx));
      expect(aware2.receivedContext, isNull);
    });
  });

  group('WebServerAware', () {
    test('can be implemented by a concrete class', () {
      final aware = TestWebServerAware();
      expect(aware, isA<WebServerAware>());
    });

    test('setWebServer stores the provided server', () {
      final aware = TestWebServerAware();
      final server = MockWebServer();

      aware.setWebServer(server);

      expect(aware.receivedServer, same(server));
    });

    test('setWebServer can be called multiple times', () {
      final aware = TestWebServerAware();
      final s1 = MockWebServer(port: 8080);
      final s2 = MockWebServer(port: 9090);

      aware.setWebServer(s1);
      expect(aware.receivedServer, same(s1));

      aware.setWebServer(s2);
      expect(aware.receivedServer, same(s2));
    });
  });

  group('ContextPathAware', () {
    test('can be implemented by a concrete class', () {
      final aware = TestContextPathAware();
      expect(aware, isA<ContextPathAware>());
    });

    test('setContextPath stores the provided path', () {
      final aware = TestContextPathAware();

      aware.setContextPath('/api/v1');

      expect(aware.receivedContextPath, '/api/v1');
    });

    test('setContextPath accepts empty string', () {
      final aware = TestContextPathAware();

      aware.setContextPath('');

      expect(aware.receivedContextPath, '');
    });

    test('setContextPath can be overwritten', () {
      final aware = TestContextPathAware();

      aware.setContextPath('/old');
      expect(aware.receivedContextPath, '/old');

      aware.setContextPath('/new');
      expect(aware.receivedContextPath, '/new');
    });
  });

  group('Multi-Aware', () {
    test('can implement multiple aware interfaces simultaneously', () {
      final aware = TestMultiAware();
      expect(aware, isA<ServerContextAware>());
      expect(aware, isA<WebServerAware>());
      expect(aware, isA<ContextPathAware>());
    });

    test('stores all injected dependencies', () {
      final aware = TestMultiAware();
      final context = MockServerContext();
      final server = MockWebServer();

      aware.setServerContext(context);
      aware.setWebServer(server);
      aware.setContextPath('/admin');

      expect(aware.receivedContext, same(context));
      expect(aware.receivedServer, same(server));
      expect(aware.receivedContextPath, '/admin');
    });
  });

  // ========================================================================
  // ServerContext Constants
  // ========================================================================

  group('ServerContext', () {
    test('SERVER_CONTEXT_PATH is an empty string', () {
      expect(ServerContext.SERVER_CONTEXT_PATH, '');
    });

    test('SERVER_CONTEXT_PATH_PROPERTY_NAME is server.context-path', () {
      expect(ServerContext.SERVER_CONTEXT_PATH_PROPERTY_NAME, 'server.context-path');
    });

    test('WEB_APPLICATION_ATTRIBUTE_NAME is a non-empty string', () {
      expect(ServerContext.WEB_APPLICATION_ATTRIBUTE_NAME, isNotEmpty);
      expect(
        ServerContext.WEB_APPLICATION_ATTRIBUTE_NAME,
        contains('.attribute'),
      );
    });

    test('can be implemented by a concrete class', () {
      final context = MockServerContext();
      expect(context, isA<ServerContext>());
    });
  });

  // ========================================================================
  // ServerContextInitializer
  // ========================================================================

  group('ServerContextInitializer', () {
    test('can be implemented', () async {
      var calledWith = <String>[];

      final initializer = _TestServerContextInitializer(
        onStartup: (ctx) async {
          calledWith.add('startup');
        },
      );

      await initializer.onStartup(MockServerContext());
      expect(calledWith, ['startup']);
    });
  });

  // ========================================================================
  // IoServerContext — Construction
  // ========================================================================

  group('IoServerContext - Construction', () {
    late IoServerContext context;

    setUp(() {
      context = IoServerContext();
    });

    test('creates a new instance', () {
      expect(context, isA<IoServerContext>());
    });

    test('implements ServerContext', () {
      expect(context, isA<ServerContext>());
    });

    test('implements EnvironmentAware', () {
      expect(context, isA<EnvironmentAware>());
    });
  });

  // ========================================================================
  // IoServerContext — Context Path
  // ========================================================================

  group('IoServerContext - Context Path', () {
    late IoServerContext context;

    setUp(() {
      context = IoServerContext();
    });

    test('defaults to SERVER_CONTEXT_PATH (empty string)', () {
      expect(context.getContextPath(), ServerContext.SERVER_CONTEXT_PATH);
      expect(context.getContextPath(), '');
    });
  });

  // ========================================================================
  // IoServerContext — Attributes
  // ========================================================================

  group('IoServerContext - Attributes', () {
    late IoServerContext context;

    setUp(() {
      context = IoServerContext();
    });

    test('getAttribute returns null for missing attribute', () {
      expect(context.getAttribute('nonexistent'), isNull);
    });

    test('setAttribute stores a value', () {
      context.setAttribute('appName', 'MyServer');
      expect(context.getAttribute('appName'), 'MyServer');
    });

    test('setAttribute does not overwrite an existing value (putIfAbsent)', () {
      context.setAttribute('key', 'value1');
      expect(context.getAttribute('key'), 'value1');

      context.setAttribute('key', 'value2');
      expect(context.getAttribute('key'), 'value1');
    });

    test('setAttribute accepts different value types', () {
      context.setAttribute('string', 'hello');
      context.setAttribute('int', 42);
      context.setAttribute('double', 3.14);
      context.setAttribute('bool', true);
      context.setAttribute('list', [1, 2, 3]);
      context.setAttribute('map', {'nested': 'value'});

      expect(context.getAttribute('string'), 'hello');
      expect(context.getAttribute('int'), 42);
      expect(context.getAttribute('double'), 3.14);
      expect(context.getAttribute('bool'), true);
      expect(context.getAttribute('list'), [1, 2, 3]);
      expect(context.getAttribute('map'), {'nested': 'value'});
    });

    test('removeAttribute removes a stored attribute', () {
      context.setAttribute('temp', 'data');
      expect(context.getAttribute('temp'), 'data');

      context.removeAttribute('temp');
      expect(context.getAttribute('temp'), isNull);
    });

    test('removeAttribute does nothing for missing attribute', () {
      expect(
        () => context.removeAttribute('nonexistent'),
        returnsNormally,
      );
    });

    test('getAttributeNames returns all attribute names', () {
      context.setAttribute('alpha', 1);
      context.setAttribute('beta', 2);
      context.setAttribute('gamma', 3);

      final names = context.getAttributeNames().toList();
      expect(names, containsAll(['alpha', 'beta', 'gamma']));
      expect(names.length, 3);
    });

    test('getAttributeNames returns empty iterable when no attributes', () {
      expect(context.getAttributeNames(), isEmpty);
    });

    test('getAttributeNames returns unmodifiable list', () {
      context.setAttribute('key', 'value');
      final names = context.getAttributeNames();

      expect(
        () => (names as dynamic).add('extra'),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('multiple attributes coexist independently', () {
      context.setAttribute('a', 1);
      context.setAttribute('b', 2);
      context.setAttribute('c', 3);

      expect(context.getAttribute('a'), 1);
      expect(context.getAttribute('b'), 2);
      expect(context.getAttribute('c'), 3);

      context.removeAttribute('b');

      expect(context.getAttribute('a'), 1);
      expect(context.getAttribute('b'), isNull);
      expect(context.getAttribute('c'), 3);
    });
  });

  // ========================================================================
  // IoServerContext — Logging
  // ========================================================================

  group('IoServerContext - Logging', () {
    late IoServerContext context;

    setUp(() {
      context = IoServerContext();
    });

    test('log returns a non-null Log instance', () {
      expect(context.log, isNotNull);
    });

    test('log is accessible without error', () {
      expect(() => context.log, returnsNormally);
    });
  });

  // ========================================================================
  // IoServerContext — Edge Cases
  // ========================================================================

  group('IoServerContext - Edge Cases', () {
    late IoServerContext context;

    setUp(() {
      context = IoServerContext();
    });

    test('empty string attribute name is valid', () {
      context.setAttribute('', 'empty-key');
      expect(context.getAttribute(''), 'empty-key');
    });

    test('attribute value can be null-like object', () {
      context.setAttribute('key', Object());
      expect(context.getAttribute('key'), isA<Object>());
    });

    test('setting and removing same attribute in sequence', () {
      context.setAttribute('volatile', 'data');
      context.removeAttribute('volatile');
      context.setAttribute('volatile', 'new-data');

      expect(context.getAttribute('volatile'), 'new-data');
    });

    test('getContextPath returns consistent value', () {
      final path1 = context.getContextPath();
      final path2 = context.getContextPath();
      expect(path1, path2);
    });

    test('large number of attributes are handled', () {
      for (var i = 0; i < 100; i++) {
        context.setAttribute('key_$i', i);
      }

      expect(context.getAttributeNames().length, 100);
      expect(context.getAttribute('key_50'), 50);
      expect(context.getAttribute('key_99'), 99);

      for (var i = 0; i < 100; i++) {
        context.removeAttribute('key_$i');
      }

      expect(context.getAttributeNames(), isEmpty);
    });
  });

  // ========================================================================
  // ServerContext — Static Constants
  // ========================================================================

  group('ServerContext - Static Constants', () {
    test('SERVER_CONTEXT_PATH is empty string', () {
      expect(ServerContext.SERVER_CONTEXT_PATH, isEmpty);
    });

    test('SERVER_CONTEXT_PATH_PROPERTY_NAME matches expected format', () {
      expect(
        ServerContext.SERVER_CONTEXT_PATH_PROPERTY_NAME,
        matches(RegExp(r'^server\.\w+(-\w+)*$')),
      );
    });

    test('WEB_APPLICATION_ATTRIBUTE_NAME contains .attribute', () {
      expect(
        ServerContext.WEB_APPLICATION_ATTRIBUTE_NAME,
        endsWith('.attribute'),
      );
    });

    test('WEB_APPLICATION_ATTRIBUTE_NAME is not empty', () {
      expect(ServerContext.WEB_APPLICATION_ATTRIBUTE_NAME, isNotEmpty);
    });
  });

  // ========================================================================
  // IoServerContext — Thread Safety (simulated)
  // ========================================================================

  group('IoServerContext - Thread Safety (Simulated)', () {
    test('concurrent setAttribute calls do not corrupt state', () async {
      final context = IoServerContext();

      final futures = List.generate(50, (i) async {
        context.setAttribute('key_$i', i);
      });

      await Future.wait(futures);

      expect(context.getAttributeNames().length, 50);

      for (var i = 0; i < 50; i++) {
        expect(context.getAttribute('key_$i'), i);
      }
    });

    test('concurrent getAttribute calls return consistent results', () async {
      final context = IoServerContext();
      context.setAttribute('stable', 'value');

      final results = await Future.wait(
        List.generate(50, (_) async => context.getAttribute('stable')),
      );

      expect(results, everyElement('value'));
    });

    test('concurrent removeAttribute calls do not throw', () async {
      final context = IoServerContext();

      for (var i = 0; i < 20; i++) {
        context.setAttribute('temp_$i', i);
      }

      final futures = List.generate(20, (i) async {
        context.removeAttribute('temp_$i');
      });

      await Future.wait(futures);

      expect(context.getAttributeNames(), isEmpty);
    });
  });

  // ========================================================================
  // IoServerContext — Realistic Usage
  // ========================================================================

  group('IoServerContext - Realistic Usage', () {
    test('simulates server startup workflow', () async {
      final context = IoServerContext();

      context.setAttribute('startupTime', DateTime.now());
      context.setAttribute('serverName', 'Production');
      context.setAttribute('version', '1.0.0');
      context.setAttribute('isRunning', true);

      expect(context.getAttribute('serverName'), 'Production');
      expect(context.getAttribute('version'), '1.0.0');
      expect(context.getAttribute('isRunning'), true);

      final names = context.getAttributeNames().toList();
      expect(names.length, 4);
      expect(names, contains('startupTime'));
    });

    test('simulates attribute lifecycle', () {
      final context = IoServerContext();

      context.setAttribute('requestCount', 0);
      expect(context.getAttribute('requestCount'), 0);

      context.setAttribute('requestCount', 1);
      expect(context.getAttribute('requestCount'), 0);

      context.setAttribute('requestCount', 2);
      expect(context.getAttribute('requestCount'), 0);

      context.removeAttribute('requestCount');
      expect(context.getAttribute('requestCount'), isNull);
    });

    test('simulates storing complex objects', () {
      final context = IoServerContext();

      final metadata = {
        'host': 'localhost',
        'port': 8080,
        'features': ['auth', 'logging', 'metrics'],
      };

      context.setAttribute('serverMetadata', metadata);
      expect(context.getAttribute('serverMetadata'), metadata);
    });
  });

  // ========================================================================
  // Type Hierarchy
  // ========================================================================

  group('Type Hierarchy', () {
    test('IoServerContext implements ServerContext', () {
      expect(IoServerContext(), isA<ServerContext>());
    });

    test('IoServerContext implements EnvironmentAware', () {
      expect(IoServerContext(), isA<EnvironmentAware>());
    });
  });
}

// ---------------------------------------------------------------------------
// 🧪 Helpers
// ---------------------------------------------------------------------------

class _TestServerContextInitializer<T extends ServerContext>
    implements ServerContextInitializer<T> {
  final Future<void> Function(T context) _onStartup;

  _TestServerContextInitializer({
    required Future<void> Function(T context) onStartup,
  }) : _onStartup = onStartup;

  @override
  Future<void> onStartup(T context) => _onStartup(context);
}
