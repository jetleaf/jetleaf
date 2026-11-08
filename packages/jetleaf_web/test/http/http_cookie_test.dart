import 'package:test/test.dart';
import 'package:jetleaf_web/src/http/http_cookie.dart';

void main() {
  group('HttpCookie', () {
    test('creates cookie with name and value', () {
      final cookie = HttpCookie('sessionId', 'abc123');
      expect(cookie.getName(), 'sessionId');
      expect(cookie.getValue(), 'abc123');
    });

    test('defaults value to empty string', () {
      final cookie = HttpCookie('token');
      expect(cookie.getValue(), '');
    });

    test('throws on empty name', () {
      expect(() => HttpCookie(''), throwsA(anything));
    });

    test('toString formats as name=value', () {
      final cookie = HttpCookie('theme', 'dark');
      expect(cookie.toString(), 'theme=dark');
    });

    test('toDartCookie converts correctly', () {
      final cookie = HttpCookie('session', 'xyz');
      final dartCookie = cookie.toDartCookie();
      expect(dartCookie.name, 'session');
      expect(dartCookie.value, 'xyz');
    });

    test('equality based on name only', () {
      final c1 = HttpCookie('sessionId', 'abc');
      final c2 = HttpCookie('sessionId', 'xyz');
      expect(c1, equals(c2));
    });

    test('different names are not equal', () {
      final c1 = HttpCookie('sessionId', 'abc');
      final c2 = HttpCookie('token', 'abc');
      expect(c1, isNot(equals(c2)));
    });
  });

  group('ResponseCookie', () {
    test('creates with all attributes', () {
      final cookie = ResponseCookie(
        name: 'session',
        value: 'abc123',
        maxAge: const Duration(hours: 1),
        path: '/',
        domain: 'example.com',
        secure: true,
        httpOnly: true,
        sameSite: 'Strict',
      );
      expect(cookie.getName(), 'session');
      expect(cookie.getValue(), 'abc123');
      expect(cookie.getMaxAge(), const Duration(hours: 1));
      expect(cookie.getPath(), '/');
      expect(cookie.getDomain(), 'example.com');
      expect(cookie.isSecure(), isTrue);
      expect(cookie.isHttpOnly(), isTrue);
      expect(cookie.getSameSite(), 'Strict');
    });

    test('create() factory creates basic cookie', () {
      final cookie = ResponseCookie.create('token', 'value123');
      expect(cookie.getName(), 'token');
      expect(cookie.getValue(), 'value123');
      expect(cookie.isSecure(), isFalse);
      expect(cookie.isHttpOnly(), isFalse);
    });

    test('fromHttpCookie copies name and value', () {
      final base = HttpCookie('sessionId', 'xyz');
      final response = ResponseCookie.fromHttpCookie(base, path: '/');
      expect(response.getName(), 'sessionId');
      expect(response.getValue(), 'xyz');
      expect(response.getPath(), '/');
    });

    test('copyWith creates modified copy', () {
      final original = ResponseCookie.create('theme', 'light');
      final modified = original.copyWith(secure: true, httpOnly: true);
      expect(modified.isSecure(), isTrue);
      expect(modified.isHttpOnly(), isTrue);
      expect(original.isSecure(), isFalse);
    });

    test('toString includes Path attribute', () {
      final cookie = ResponseCookie(name: 'test', value: 'val', path: '/api');
      expect(cookie.toString(), contains('Path=/api'));
    });

    test('toString includes Secure attribute when true', () {
      final cookie = ResponseCookie(name: 'test', value: 'val', secure: true);
      expect(cookie.toString(), contains('Secure'));
    });

    test('toString includes HttpOnly attribute when true', () {
      final cookie = ResponseCookie(name: 'test', value: 'val', httpOnly: true);
      expect(cookie.toString(), contains('HttpOnly'));
    });

    test('toString includes Max-Age when positive', () {
      final cookie = ResponseCookie(
        name: 'test',
        value: 'val',
        maxAge: const Duration(seconds: 3600),
      );
      expect(cookie.toString(), contains('Max-Age=3600'));
    });

    test('toString includes SameSite when set', () {
      final cookie = ResponseCookie(name: 'test', value: 'val', sameSite: 'Lax');
      expect(cookie.toString(), contains('SameSite=Lax'));
    });

    test('default maxAge is negative', () {
      final cookie = ResponseCookie.create('test');
      expect(cookie.getMaxAge().isNegative, isTrue);
    });
  });
}