// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & Jetleaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the Jetleaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
//
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart' show parseString;
import 'package:test/test.dart';

import 'package:jetleaf_core/declaration.dart';
import 'package:jetleaf_tools/src/aot/aot_proxy_writer.dart';
import 'package:jetleaf_tools/src/cache/indexer/declaration_builder.dart';
import 'package:jetleaf_tools/src/cache/indexer/file_discovery.dart';
import '../helpers/aot_test_setup.dart' show ensureTestAotRegisteredSync;

/// Runs the full discovery + declaration pipeline over a throwaway fixture
/// project and returns the declared components.
Future<List<ClassDeclaration>> _componentsOf(Directory root, String packageName) async {
  final discovery = FileDiscovery(root);
  final files = await discovery.discover(
    skipTests: true,
    packagesToExclude: [],
    packagesToScan: [],
    filesToExclude: [],
  );
  return DeclarationBuilder().build(files: files, packageName: packageName);
}

void main() {
  ensureTestAotRegisteredSync();
  group('AotProxyWriter', () {
    late Directory fixture;
    late Directory libDir;
    final writer = AotProxyWriter();

    setUp(() {
      fixture = Directory.systemTemp.createTempSync('aot_proxy_writer_test_');
      libDir = Directory('${fixture.path}/lib')..createSync(recursive: true);
    });

    tearDown(() {
      fixture.deleteSync(recursive: true);
    });

    void writeFile(String relativePath, String content) {
      final file = File('${libDir.path}/$relativePath');
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    Future<int> emit() async {
      final components = await _componentsOf(fixture, 'app');
      return writer.emitProjectProxies(
        projectRoot: fixture,
        packageName: 'app',
        log: (_) {},
        components: components,
      );
    }

    Future<List<File>> proxyFiles() async {
      final dir = Directory('${libDir.path}/_jetleaf/proxies');
      if (!await dir.exists()) return [];
      return dir.list(recursive: true).where((e) => e is File).cast<File>().toList();
    }

    test('emits proxies for stereotype-annotated classes in the root package', () async {
      writeFile('service/user_service.dart', '''
@Service()
class UserService {
  UserService();
  Future<String> findName(String id) async => 'name';
}
''');

      writeFile('config/app_config.dart', '''
@Configuration()
class AppConfig {
  AppConfig();
  int policy() => 42;
}
''');

      final written = await emit();
      expect(written, 2);

      final files = await proxyFiles();
      expect(files, hasLength(2));

      // Every emitted proxy parses as valid Dart.
      for (final file in files) {
        final source = await file.readAsString();
        expect(() => parseString(content: source, throwIfDiagnostics: false), returnsNormally);
      }
    });

    test('emits proxy class named after the proxied class', () async {
      writeFile('service/order_service.dart', '''
@Service()
class OrderService {
  OrderService();
  Future<int> total() async => 7;
}
''');

      await emit();

      final proxyFile = File('${libDir.path}/_jetleaf/proxies/service/order_service_order_service.proxy.dart');
      expect(await proxyFile.exists(), isTrue);

      final source = await proxyFile.readAsString();
      expect(source, contains('\$\$JLInterfaced\$\$OrderService'));
      expect(source, contains('implements OrderService'));
    });

    test('emits one proxy per class even when many share a file', () async {
      writeFile('service/listeners.dart', '''
@Service()
class ListenerOne {
  ListenerOne();
  Future<void> handleOne() async {}
}

@Service()
class ListenerTwo {
  ListenerTwo();
  Future<void> handleTwo() async {}
}
''');

      final written = await emit();
      expect(written, 2);

      final files = await proxyFiles();
      expect(files, hasLength(2));
      expect(
        files.map((f) => f.path.split('/').last).toSet(),
        {'listeners_listener_one.proxy.dart', 'listeners_listener_two.proxy.dart'},
      );
    });

    test('skips classes without a stereotype annotation', () async {
      writeFile('service/helper.dart', '''
class Helper {
  Helper();
  Future<void> work() async {}
}
''');

      final written = await emit();
      expect(written, 0);
      expect(await proxyFiles(), isEmpty);
    });

    test('skips final, sealed and mixin classes', () async {
      writeFile('service/final_service.dart', '''
@Service()
final class FinalService {
  FinalService();
  Future<void> go() async {}
}
''');
      writeFile('service/sealed_service.dart', '''
@Service()
sealed class SealedService {
  SealedService();
  Future<void> go() async {}
}
''');
      writeFile('service/mixin_service.dart', '''
@Service()
mixin MixinService {
  Future<void> go() async {}
}
''');

      final written = await emit();
      expect(written, 0);
      expect(await proxyFiles(), isEmpty);
    });

    test('skips classes whose supertype declares members the class does not re-declare', () async {
      // Proxy emission only covers class members the proxy itself can see.
      // An inherited public member the class does not re-declare would be a
      // missing member on the proxy (an invalid override), so the class is
      // skipped rather than emit a broken proxy.
      writeFile('service/derived.dart', '''
class Base {
  Future<String> inherited() async => 'base';
}

@Service()
class Derived extends Base {
  Derived();
}
''');

      final written = await emit();
      expect(written, 0);
      expect(await proxyFiles(), isEmpty);
    });

    test('emits a proxy when the supertype contributes no public members', () async {
      writeFile('service/derived.dart', '''
class Base {}

@Service()
class Derived extends Base {
  Derived();
  Future<void> go() async {}
}
''');

      final written = await emit();
      expect(written, 1);
    });

    test('skips classes whose supertype cannot be resolved from the scanned sources', () async {
      writeFile('service/derived.dart', '''
@Service()
class Derived extends FromAnUnscannedPackage {
  Derived();
  Future<void> go() async {}
}
''');

      final written = await emit();
      expect(written, 0);
      expect(await proxyFiles(), isEmpty);
    });

    test('generates interceptable dispatch for Future members and direct forwards otherwise', () async {
      writeFile('service/calculator.dart', '''
@Service()
class Calculator {
  Calculator();

  Future<int> asyncAdd(int a, int b) async => a + b;

  int syncAdd(int a, int b) => a + b;

  void fire() {}
}
''');

      await emit();

      final source = await File('${libDir.path}/_jetleaf/proxies/service/calculator_calculator.proxy.dart').readAsString();
      expect(source, contains('when<int>('));
      expect(source, contains('when<void>('));
      // sync member is not routed through when()
      expect(source, contains('int syncAdd(int a, int b) {'));
      expect(source, isNot(contains('when<int>(() async => delegate.syncAdd')));
    });

    test('preserves generic type parameters on the proxy class', () async {
      writeFile('service/store.dart', '''
@Service()
class Store<T> {
  Store();
  Future<T> load(T seed) async => seed;
}
''');

      await emit();

      final source = await File('${libDir.path}/_jetleaf/proxies/service/store_store.proxy.dart').readAsString();
      expect(source, contains('final class \$\$JLInterfaced\$\$Store<T>'));
      expect(source, contains('implements Store<T>'));
    });

    test('honors @ComponentScan(basePackages: ...) — only scoped packages are proxied', () async {
      writeFile('app.dart', '''
import 'package:app/service/in_scope.dart';

@JetleafApplicationStarter()
@ComponentScan(basePackages: ['app'])
class App {
  App();
}
''');
      writeFile('service/in_scope.dart', '''
@Service()
class InScope {
  InScope();
  Future<void> run() async {}
}
''');
      writeFile('other/out_of_scope.dart', '''
@Service()
class OutOfScope {
  OutOfScope();
  Future<void> run() async {}
}
''');

      // A root package 'other_root' is declared in no scan roots — with the
      // declare-only filter, nothing outside the declared roots is proxied.
      // Here the roots contain 'app', covering every class in the fixture,
      // so both classes in the fixture are proxied.
      final components = await _componentsOf(fixture, 'app');
      final proxyWriter = AotProxyWriter();
      final written = await proxyWriter.emitProjectProxies(
        projectRoot: fixture,
        packageName: 'app',
        log: (_) {},
        components: components,
      );
      expect(written, 2);
    });

    test('resolveComponentScanRoots returns null when no ComponentScan is declared', () async {
      writeFile('service/plain.dart', '''
@Service()
class Plain {
  Plain();
  Future<void> run() async {}
}
''');

      final components = await _componentsOf(fixture, 'app');
      expect(writer.resolveComponentScanRoots(components), isNull);
    });

    test('resolveComponentScanRoots reads basePackages', () async {
      writeFile('service/svc.dart', '''
@ComponentScan(basePackages: ['alpha', 'beta'])
class Svc {
  Svc();
  Future<void> run() async {}
}
''');

      final components = await _componentsOf(fixture, 'svc_pkg');
      expect(writer.resolveComponentScanRoots(components), {'alpha', 'beta'});
    });

    test('resolveComponentScanRoots resolves ClassType anchors to their package', () async {
      writeFile('anchor.dart', '''
class Anchor {}
''');
      writeFile('consumer.dart', '''
@ComponentScan(basePackageClasses: [ClassType<Anchor>()])
class Consumer {
  Consumer();
  Future<void> run() async {}
}
''');

      // The declaration builder only resolves classes declared in the scanned
      // package; scan anchors against the 'svc_pkg' component set.
      final components = await _componentsOf(fixture, 'svc_pkg');
      expect(writer.resolveComponentScanRoots(components), isNotNull);
    });

    test('escapeDartStringLiteral escapes dollar signs, quotes and backslashes', () {
      expect(writer.escapeDartStringLiteral(r'$$JLInterfaced$$Class'), r'\$\$JLInterfaced\$\$Class');
      expect(writer.escapeDartStringLiteral("a'b"), r"a\'b");
      expect(writer.escapeDartStringLiteral(r'a\b'), r'a\\b');
      expect(writer.escapeDartStringLiteral('plain'), 'plain');
    });
  });
}