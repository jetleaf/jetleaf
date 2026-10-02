import 'package:test/test.dart';
import 'package:jetleaf_web/src/uri_builder.dart';

void main() {
  group('SimpleUriBuilder', () {
    late SimpleUriBuilder builder;

    setUp(() {
      builder = const SimpleUriBuilder();
    });

    test('builds URI without variables', () {
      final uri = builder.build('/api/users', null, null);
      expect(uri.path, '/api/users');
    });

    test('replaces single variable', () {
      final uri = builder.build('/users/{id}', {'id': '123'}, null);
      expect(uri.path, '/users/123');
    });

    test('replaces multiple variables', () {
      final uri = builder.build(
        '/users/{userId}/posts/{postId}',
        {'userId': '42', 'postId': '7'},
        null,
      );
      expect(uri.path, '/users/42/posts/7');
    });

    test('adds query parameters', () {
      final uri = builder.build('/search', null, {'q': 'dart', 'page': '2'});
      expect(uri.path, '/search');
      expect(uri.queryParameters['q'], 'dart');
      expect(uri.queryParameters['page'], '2');
    });

    test('combines variables and query parameters', () {
      final uri = builder.build(
        '/users/{id}/posts',
        {'id': '42'},
        {'limit': '10', 'offset': '0'},
      );
      expect(uri.path, '/users/42/posts');
      expect(uri.queryParameters['limit'], '10');
    });

    test('handles integer variable values', () {
      final uri = builder.build('/items/{id}', {'id': 99}, null);
      expect(uri.path, '/items/99');
    });

    test('handles null variables gracefully', () {
      final uri = builder.build('/static', null, null);
      expect(uri.path, '/static');
    });

    test('handles empty query params', () {
      final uri = builder.build('/api', null, {});
      expect(uri.path, '/api');
      expect(uri.queryParameters, isEmpty);
    });

    test('query params override template params', () {
      final uri = builder.build('/api?existing=old', null, {'existing': 'new'});
      expect(uri.queryParameters['existing'], 'new');
    });
  });
}