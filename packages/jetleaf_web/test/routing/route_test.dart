import 'package:test/test.dart';
import 'package:jetleaf_web/src/http/http_method.dart';
import 'package:jetleaf_web/src/server/routing/route.dart';

void main() {
  group('Route', () {
    test('creates base route with path and method', () {
      final route = Route('/api/data', HttpMethod.GET);
      expect(route.path, '/api/data');
      expect(route.method, HttpMethod.GET);
    });
  });

  group('GET', () {
    test('has GET method', () {
      final route = GET('/hello');
      expect(route.method, HttpMethod.GET);
      expect(route.path, '/hello');
    });
  });

  group('POST', () {
    test('has POST method', () {
      final route = POST('/users');
      expect(route.method, HttpMethod.POST);
      expect(route.path, '/users');
    });
  });

  group('PUT', () {
    test('has PUT method', () {
      final route = PUT('/users/1');
      expect(route.method, HttpMethod.PUT);
      expect(route.path, '/users/1');
    });
  });

  group('DELETE', () {
    test('has DELETE method', () {
      final route = DELETE('/users/1');
      expect(route.method, HttpMethod.DELETE);
      expect(route.path, '/users/1');
    });
  });

  group('PATCH', () {
    test('has PATCH method', () {
      final route = PATCH('/users/1');
      expect(route.method, HttpMethod.PATCH);
      expect(route.path, '/users/1');
    });
  });

  group('HEAD', () {
    test('has HEAD method', () {
      final route = HEAD('/status');
      expect(route.method, HttpMethod.HEAD);
      expect(route.path, '/status');
    });
  });

  group('OPTIONS', () {
    test('has OPTIONS method', () {
      final route = OPTIONS('/users');
      expect(route.method, HttpMethod.OPTIONS);
      expect(route.path, '/users');
    });
  });

  group('Route Equality', () {
    test('same routes are equal', () {
      expect(GET('/hello'), equals(GET('/hello')));
    });

    test('different paths are not equal', () {
      expect(GET('/hello'), isNot(equals(GET('/world'))));
    });

    test('different methods same path are not equal', () {
      expect(GET('/hello'), isNot(equals(POST('/hello'))));
    });
  });
}