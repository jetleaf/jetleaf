import 'package:test/test.dart';
import 'package:jetleaf_web/src/http/http_method.dart';

void main() {
  group('HttpMethod - Standard Methods', () {
    test('GET has correct string value', () {
      expect(HttpMethod.GET.toString(), 'GET');
    });

    test('POST has correct string value', () {
      expect(HttpMethod.POST.toString(), 'POST');
    });

    test('PUT has correct string value', () {
      expect(HttpMethod.PUT.toString(), 'PUT');
    });

    test('DELETE has correct string value', () {
      expect(HttpMethod.DELETE.toString(), 'DELETE');
    });

    test('PATCH has correct string value', () {
      expect(HttpMethod.PATCH.toString(), 'PATCH');
    });

    test('HEAD has correct string value', () {
      expect(HttpMethod.HEAD.toString(), 'HEAD');
    });

    test('OPTIONS has correct string value', () {
      expect(HttpMethod.OPTIONS.toString(), 'OPTIONS');
    });

    test('TRACE has correct string value', () {
      expect(HttpMethod.TRACE.toString(), 'TRACE');
    });

    test('CONNECT has correct string value', () {
      expect(HttpMethod.CONNECT.toString(), 'CONNECT');
    });
  });

  group('HttpMethod - FROM()', () {
    test('creates custom method', () {
      final propfind = HttpMethod.FROM('PROPFIND');
      expect(propfind.toString(), 'PROPFIND');
    });

    test('normalizes lowercase to uppercase', () {
      final search = HttpMethod.FROM('search');
      expect(search.toString(), 'SEARCH');
    });

    test('FROM creates method equal to predefined constant', () {
      expect(HttpMethod.FROM('GET'), equals(HttpMethod.GET));
      expect(HttpMethod.FROM('get'), equals(HttpMethod.GET));
      expect(HttpMethod.FROM('Get'), equals(HttpMethod.GET));
    });
  });

  group('HttpMethod - matches()', () {
    test('matches same case', () {
      expect(HttpMethod.GET.matches('GET'), isTrue);
    });

    test('matches lower case', () {
      expect(HttpMethod.GET.matches('get'), isTrue);
    });

    test('matches mixed case', () {
      expect(HttpMethod.POST.matches('Post'), isTrue);
    });

    test('does not match different method', () {
      expect(HttpMethod.GET.matches('POST'), isFalse);
    });
  });

  group('HttpMethod - valueOf()', () {
    test('returns method from string', () {
      final method = HttpMethod.valueOf('GET');
      expect(method.toString(), 'GET');
      expect(method, equals(HttpMethod.GET));
    });
  });

  group('HttpMethod - getMethods()', () {
    test('returns list of 9 standard methods', () {
      final methods = HttpMethod.getMethods();
      expect(methods.length, 9);
      expect(methods, contains(HttpMethod.GET));
      expect(methods, contains(HttpMethod.POST));
      expect(methods, contains(HttpMethod.PUT));
      expect(methods, contains(HttpMethod.DELETE));
      expect(methods, contains(HttpMethod.PATCH));
      expect(methods, contains(HttpMethod.HEAD));
      expect(methods, contains(HttpMethod.OPTIONS));
      expect(methods, contains(HttpMethod.TRACE));
      expect(methods, contains(HttpMethod.CONNECT));
    });
  });

  group('HttpMethod - Equality', () {
    test('same methods are equal', () {
      expect(HttpMethod.GET, equals(HttpMethod.GET));
    });

    test('different methods are not equal', () {
      expect(HttpMethod.GET, isNot(equals(HttpMethod.POST)));
    });

    test('from created methods equal predefined for same value', () {
      expect(HttpMethod.FROM('GET'), equals(HttpMethod.GET));
    });

    test('from created methods equal each other for same value', () {
      expect(HttpMethod.FROM('PROPFIND'), equals(HttpMethod.FROM('PROPFIND')));
    });

    test('hashCode is consistent for equal methods', () {
      expect(HttpMethod.GET.hashCode, equals(HttpMethod.GET.hashCode));
    });
  });
}