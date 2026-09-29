import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

void main() {
  group('UriTemplate.match', () {
    test('matches valid path with variables', () {
      final template = UriTemplate('/users/{id}/orders/{orderId}');
      final result = template.match('/users/42/orders/123');
      expect(result, {'id': '42', 'orderId': '123'});
    });

    test('returns null for non-matching path', () {
      final template = UriTemplate('/users/{id}/orders/{orderId}');
      final result = template.match('/posts/42/comments/123');
      expect(result, isNull);
    });

    test('returns null when missing segments', () {
      final template = UriTemplate('/users/{id}/orders/{orderId}');
      final result = template.match('/users/42/orders');
      expect(result, isNull);
    });
  });

  group('UriTemplate.expand', () {
    test('expands template with provided variables', () {
      final template = UriTemplate('/users/{id}/orders/{orderId}');
      final result = template.expand({'id': '42', 'orderId': '123'});
      expect(result, '/users/42/orders/123');
    });

    test('throws UriPathMatchingException for missing variable', () {
      final template = UriTemplate('/users/{id}/orders/{orderId}');
      expect(
        () => template.expand({'id': '42'}),
        throwsA(
          isA<UriPathMatchingException>().having(
            (e) => e.message,
            'message',
            contains('orderId'),
          ),
        ),
      );
    });
  });

  group('UriTemplate.normalizePath', () {
    test('normalizes redundant slashes and trims', () {
      expect(UriTemplate.normalizePath('///api//v1/users/'), '/api/v1/users');
      expect(UriTemplate.normalizePath('users'), '/users');
      expect(UriTemplate.normalizePath('/'), '/');
    });
  });

  group('UriTemplate.normalize', () {
    test('normalizes scheme, host, default port, and query', () {
      final input = 'HTTP://Example.com:80/path///to///resource/?b=2&a=1&a=0';
      final expected = 'http://example.com/path/to/resource?a=0&a=1&b=2';
      expect(UriTemplate.normalize(input), expected);
    });

    test('preserves fragment and user info', () {
      final input = 'https://user@Example.com:443/test/?q=1#frag';
      final expected = 'https://user@example.com/test?q=1#frag';
      expect(UriTemplate.normalize(input), expected);
    });

    test('removes trailing slashes for non-root', () {
      final input = 'http://localhost:8080/test/';
      final normalized = UriTemplate.normalize(input);
      expect(normalized.endsWith('/'), isFalse);
    });
  });

  group('UriTemplate.matches', () {
    test('returns true for semantically equivalent URLs', () {
      expect(
        UriTemplate.matches('http://EXAMPLE.com:80/users/', 'http://example.com/users'),
        isTrue,
      );
    });

    test('returns false for different logical URLs', () {
      expect(
        UriTemplate.matches('http://example.com/a', 'http://example.com/b'),
        isFalse,
      );
    });
  });

  group('UriPathMatchingException', () {
    test('has proper message and toString output', () {
      final ex = UriPathMatchingException('Missing segment');
      expect(ex.message, 'Missing segment');
      expect(ex.toString(), contains('Missing segment'));
    });
  });
}