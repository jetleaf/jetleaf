import 'package:test/test.dart';
import 'package:jetleaf_web/src/server/routing/route.dart';
import 'package:jetleaf_web/src/server/routing/route_entry.dart';
import 'package:jetleaf_web/src/server/routing/router.dart';

void main() {
  group('RouterBuilder', () {
    test('builds empty spec when no routes', () {
      final router = RouterBuilder();
      final spec = router.build();
      expect(spec.routes, isEmpty);
    });

    test('registers GET route', () {
      final router = RouterBuilder()
        ..route(GET('/hello'), (req) => 'Hello');
      final spec = router.build();
      expect(spec.routes.length, 1);
      expect(spec.routes[0].path, '/hello');
    });

    test('registers POST route', () {
      final router = RouterBuilder()
        ..route(POST('/users'), (req) => {'created': true});
      final spec = router.build();
      expect(spec.routes.length, 1);
    });

    test('registers PUT route', () {
      final router = RouterBuilder()
        ..route(PUT('/users/1'), (req) => 'updated');
      final spec = router.build();
      expect(spec.routes.length, 1);
    });

    test('registers DELETE route', () {
      final router = RouterBuilder()
        ..route(DELETE('/users/1'), (req) => 'deleted');
      final spec = router.build();
      expect(spec.routes.length, 1);
    });

    test('registers PATCH route', () {
      final router = RouterBuilder()
        ..route(PATCH('/users/1'), (req) => 'patched');
      final spec = router.build();
      expect(spec.routes.length, 1);
    });

    test('registers multiple routes', () {
      final router = RouterBuilder()
        ..route(GET('/a'), (req) => 'A')
        ..route(POST('/b'), (req) => 'B')
        ..route(PUT('/c'), (req) => 'C');
      final spec = router.build();
      expect(spec.routes.length, 3);
    });

    test('child() adds child route', () {
      final router = RouterBuilder()
        ..child(GET('/nested'), (req) => 'nested');
      final spec = router.build();
      expect(spec.routes.length, 1);
    });

    test('group() adds path prefix', () {
      final router = RouterBuilder()
        ..group('/api', RouterBuilder()
          ..route(GET('/users'), (req) => ['Alice'])
        );
      final spec = router.build();
      expect(spec.routes.length, 1);
      expect(spec.routes[0].path, '/api/users');
    });

    test('and() combines two routers', () {
      final r1 = RouterBuilder()..route(GET('/a'), (req) => 'A');
      final r2 = RouterBuilder()..route(GET('/b'), (req) => 'B');
      final combined = r1.and(r2);
      final spec = combined.build();
      expect(spec.routes.length, 2);
    });

    test('build() respects contextPath', () {
      final router = RouterBuilder(null, false)
        ..route(GET('/hello'), (req) => 'Hello');
      final spec = router.build(contextPath: '/app');
      expect(spec.routes.length, 1);
      expect(spec.routes[0].path, '/app/hello');
    });

    test('nested group with context path', () {
      final router = RouterBuilder(null, false)
        ..group('/api', RouterBuilder(null, false)
          ..route(GET('/users'), (req) => [])
        );
      final spec = router.build(contextPath: '/app');
      expect(spec.routes.length, 1);
      expect(spec.routes[0].path, '/app/api/users');
    });
  });

  group('RouteEntry', () {
    test('RequestRouteEntry stores handler', () {
      final entry = RequestRouteEntry(GET('/hello'), (req) => 'Hello');
      expect(entry.route.path, '/hello');
    });

    test('XRouteEntry stores handler', () {
      final entry = XRouteEntry(
        POST('/upload'),
        (req, res) async => null,
      );
      expect(entry.route.path, '/upload');
    });
  });

  group('RouterSpec', () {
    test('holds list of route definitions', () {
      final router = RouterBuilder()
        ..route(GET('/a'), (req) => 'A')
        ..route(GET('/b'), (req) => 'B');
      final spec = router.build();
      expect(spec.routes.length, 2);
    });
  });

  group('RouteDefinition', () {
    test('stores method, path, and handler', () {
      final router = RouterBuilder()
        ..route(GET('/test'), (req) => 'test');
      final spec = router.build();
      final def = spec.routes[0];
      expect(def.method, isNotNull);
      expect(def.path, '/test');
      expect(def.handler, isNotNull);
    });
  });
}