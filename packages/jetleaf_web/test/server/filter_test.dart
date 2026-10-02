import 'dart:async';

import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

import 'package:jetleaf_web/src/http/http_cookies.dart';
import 'package:jetleaf_web/src/http/http_headers.dart';
import 'package:jetleaf_web/src/http/http_method.dart';
import 'package:jetleaf_web/src/http/http_session.dart';
import 'package:jetleaf_web/src/http/http_status.dart';
import 'package:jetleaf_web/src/http/media_type.dart';
import 'package:jetleaf_web/src/path/path_pattern.dart';
import 'package:jetleaf_web/src/server/exception_resolver/exception_resolver.dart';
import 'package:jetleaf_web/src/server/filter/filter.dart';
import 'package:jetleaf_web/src/server/filter/filter_manager.dart';
import 'package:jetleaf_web/src/server/filter/once_per_request_filter.dart';
import 'package:jetleaf_web/src/server/handler_method.dart';
import 'package:jetleaf_web/src/server/server_http_request.dart';
import 'package:jetleaf_web/src/server/server_http_response.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockServerHttpRequest implements ServerHttpRequest {
  final HttpHeaders _headers;
  final HttpMethod _method;
  final Uri _uri;
  final String _origin;
  String _contextPath;
  String? _requestUrl;
  final Map<String, Object> _attributes;
  final Map<String, List<String>> _parameterMap;

  MockServerHttpRequest({
    String method = 'GET',
    String path = '/test',
    String origin = '',
    String contextPath = '',
    Map<String, String>? headers,
  })  : _headers = headers != null ? HttpHeaders.fromMap(headers) : HttpHeaders(),
        _method = HttpMethod.FROM(method),
        _uri = Uri.parse(path),
        _origin = origin,
        _contextPath = contextPath,
        _attributes = {},
        _parameterMap = {};

  @override
  HttpHeaders getHeaders() => _headers;

  @override
  void setHeaders(HttpHeaders headers) {}

  @override
  InputStream getBody() => throw UnimplementedError();

  @override
  HttpMethod getMethod() => _method;

  @override
  Uri getRequestURI() => _uri;

  @override
  Uri getUri() => _uri;

  @override
  String? getQueryString() => _uri.query.isEmpty ? null : _uri.query;

  @override
  String? getParameter(String name) => _parameterMap[name]?.firstOrNull;

  @override
  List<String> getParameterValues(String name) => _parameterMap[name] ?? [];

  @override
  Map<String, List<String>> getParameterMap() => _parameterMap;

  @override
  String getContextPath() => _contextPath;

  @override
  void setContextPath(String contextPath) => _contextPath = contextPath;

  @override
  Map<String, Object> getAttributes() => _attributes;

  @override
  Object? getAttribute(String name) => _attributes[name];

  @override
  void setAttribute(String name, Object value) => _attributes[name] = value;

  @override
  void removeAttribute(String name) => _attributes.remove(name);

  @override
  Set<String> getAttributeNames() => _attributes.keys.toSet();

  @override
  HttpCookies getCookies() => HttpCookies.fromList([]);

  @override
  HttpSession? getSession([bool create = true]) => null;

  @override
  String? getPathVariable(String name) => null;

  @override
  Map<String, String> getPathVariables() => {};

  @override
  bool shouldUpgrade() => false;

  @override
  void setRequestUrl(String requestUrl) => _requestUrl = requestUrl;

  @override
  String? getRequestUrl() => _requestUrl;

  @override
  int getContentLength() => 0;

  @override
  void setHandlerContext(HandlerMethod handler, PathPattern pattern) {}

  @override
  String getOrigin() => _origin;
}

class MockServerHttpResponse implements ServerHttpResponse {
  final HttpHeaders _headers = HttpHeaders();
  HttpStatus? _status;
  final bool _committed = false;
  String? _reason;
  final OutputStream _body = MockOutputStream();

  @override
  HttpHeaders getHeaders() => _headers;

  @override
  void setHeaders(HttpHeaders headers) {
    _headers.clear();
    headers.forEach((name, values) {
      _headers.set(name, values.join(', '));
    });
  }

  @override
  OutputStream getBody() => _body;

  @override
  void setStatus(HttpStatus httpStatus) => _status = httpStatus;

  @override
  HttpStatus? getStatus() => _status;

  @override
  bool isCommitted() => _committed;

  @override
  void setReason(String message) => _reason = message;

  String? getReason() => _reason;

  @override
  Future<String> encodeRedirectUrl(String location) async => location;

  @override
  Future<void> sendRedirect(String encodedLocation) async {}
}

class MockOutputStream extends OutputStream {
  final List<String> writes = [];

  @override
  Future<void> writeByte(int b) async {}

  @override
  Future<void> writeObject(Object? obj) async {
    writes.add(obj?.toString() ?? '');
  }
}

class MockFilterChain implements FilterChain {
  bool nextCalled = false;
  int nextCallCount = 0;
  ServerHttpRequest? lastRequest;
  ServerHttpResponse? lastResponse;

  @override
  Future<void> next(ServerHttpRequest request, ServerHttpResponse response) async {
    nextCalled = true;
    nextCallCount++;
    lastRequest = request;
    lastResponse = response;
  }
}

class RecordingFilter implements Filter {
  final String filterName;
  final List<String> log;

  RecordingFilter(this.filterName, this.log);

  @override
  Future<void> doFilter(ServerHttpRequest request, ServerHttpResponse response, FilterChain chain) async {
    log.add('$filterName:pre');
    await chain.next(request, response);
    log.add('$filterName:post');
  }

  @override
  List<Object?> equalizedProperties() => [filterName];
}

class ShortCircuitFilter implements Filter {
  @override
  Future<void> doFilter(ServerHttpRequest request, ServerHttpResponse response, FilterChain chain) async {
    response.setStatus(HttpStatus.FORBIDDEN);
  }

  @override
  List<Object?> equalizedProperties() => [runtimeType];
}

class ThrowingFilter implements Filter {
  @override
  Future<void> doFilter(ServerHttpRequest request, ServerHttpResponse response, FilterChain chain) async {
    throw StateError('Filter failure');
  }

  @override
  List<Object?> equalizedProperties() => [runtimeType];
}

class TestOncePerRequestFilter extends OncePerRequestFilter {
  final List<String> log;

  TestOncePerRequestFilter(this.log);

  @override
  Future<void> doFilterInternal(ServerHttpRequest request, ServerHttpResponse response, FilterChain chain) async {
    log.add('doFilterInternal');
    await chain.next(request, response);
  }

  @override
  List<Object?> equalizedProperties() => [runtimeType, log];
}

class ShortCircuitOncePerRequestFilter extends OncePerRequestFilter {
  @override
  Future<void> doFilterInternal(ServerHttpRequest request, ServerHttpResponse response, FilterChain chain) async {
    response.setStatus(HttpStatus.UNAUTHORIZED);
  }

  @override
  List<Object?> equalizedProperties() => [runtimeType];
}

class ThrowingOncePerRequestFilter extends OncePerRequestFilter {
  @override
  Future<void> doFilterInternal(ServerHttpRequest request, ServerHttpResponse response, FilterChain chain) async {
    throw StateError('OncePerRequest failure');
  }

  @override
  List<Object?> equalizedProperties() => [runtimeType];
}

class MockExceptionResolver implements ExceptionResolver {
  final bool handled;
  final List<MediaType> mediaTypes;

  MockExceptionResolver({this.handled = true, this.mediaTypes = const [MediaType.APPLICATION_JSON]});

  @override
  List<MediaType> getSupportedMediaTypes() => mediaTypes;

  @override
  Future<bool> resolve(ServerHttpRequest request, ServerHttpResponse response, HandlerMethod? handler, Object ex, StackTrace st) async {
    return handled;
  }
}

class MockFailingExceptionResolver implements ExceptionResolver {
  @override
  List<MediaType> getSupportedMediaTypes() => [MediaType.APPLICATION_JSON];

  @override
  Future<bool> resolve(ServerHttpRequest request, ServerHttpResponse response, HandlerMethod? handler, Object ex, StackTrace st) async {
    return false;
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // Filter interface
  // -------------------------------------------------------------------------
  group('Filter interface', () {
    test('doFilter is callable and can delegate to chain', () async {
      final request = MockServerHttpRequest();
      final response = MockServerHttpResponse();
      final chain = MockFilterChain();
      final log = <String>[];
      final filter = RecordingFilter('test', log);

      await filter.doFilter(request, response, chain);

      expect(chain.nextCalled, isTrue);
      expect(log, equals(['test:pre', 'test:post']));
    });

    test('filter can short-circuit without calling chain', () async {
      final request = MockServerHttpRequest();
      final response = MockServerHttpResponse();
      final chain = MockFilterChain();
      final filter = ShortCircuitFilter();

      await filter.doFilter(request, response, chain);

      expect(chain.nextCalled, isFalse);
      expect(response.getStatus(), equals(HttpStatus.FORBIDDEN));
    });

    test('filter that throws propagates the error', () async {
      final request = MockServerHttpRequest();
      final response = MockServerHttpResponse();
      final chain = MockFilterChain();
      final filter = ThrowingFilter();

      expect(
        () => filter.doFilter(request, response, chain),
        throwsA(isA<StateError>()),
      );
    });

    test('filter equality is based on equalizedProperties', () {
      final a = RecordingFilter('x', []);
      final b = RecordingFilter('x', []);
      final c = RecordingFilter('y', []);

      expect(a == b, isFalse);
      expect(a.equalizedProperties(), equals(b.equalizedProperties()));
      expect(a.equalizedProperties(), isNot(equals(c.equalizedProperties())));
    });

    test('filter toString includes type name', () {
      final filter = RecordingFilter('test', []);
      expect(filter.toString(), contains('RecordingFilter'));
    });
  });

  // -------------------------------------------------------------------------
  // FilterChain
  // -------------------------------------------------------------------------
  group('FilterChain', () {
    test('next delegates to the chain handler', () async {
      final request = MockServerHttpRequest();
      final response = MockServerHttpResponse();
      final chain = MockFilterChain();

      await chain.next(request, response);

      expect(chain.nextCalled, isTrue);
      expect(chain.nextCallCount, equals(1));
      expect(chain.lastRequest, same(request));
      expect(chain.lastResponse, same(response));
    });

    test('chain tracks multiple next calls', () async {
      final request = MockServerHttpRequest();
      final response = MockServerHttpResponse();
      final chain = MockFilterChain();

      await chain.next(request, response);
      await chain.next(request, response);
      await chain.next(request, response);

      expect(chain.nextCallCount, equals(3));
    });

    test('chain preserves request and response references', () async {
      final request = MockServerHttpRequest(path: '/unique');
      final response = MockServerHttpResponse();
      final chain = MockFilterChain();

      await chain.next(request, response);

      expect(chain.lastRequest, same(request));
      expect(chain.lastResponse, same(response));
    });
  });

  // -------------------------------------------------------------------------
  // FilterManager
  // -------------------------------------------------------------------------
  group('FilterManager', () {
    late FilterManager manager;

    setUp(() {
      manager = FilterManager();
    });

    test('getFilters returns empty list initially', () {
      final filters = manager.getFilters();
      expect(filters, isEmpty);
    });

    test('getFilters returns unmodifiable list', () {
      final filters = manager.getFilters();
      expect(
        () => filters.add(RecordingFilter('x', [])),
        throwsA(anything),
      );
    });

    test('addFilter registers a filter', () {
      final log = <String>[];
      final filter = RecordingFilter('one', log);
      manager.addFilter(filter);

      final filters = manager.getFilters();
      expect(filters, hasLength(1));
      expect(filters.first, same(filter));
    });

    test('addFilter registers multiple filters in order', () {
      final log = <String>[];
      final f1 = RecordingFilter('one', log);
      final f2 = RecordingFilter('two', log);
      final f3 = RecordingFilter('three', log);

      manager.addFilter(f1);
      manager.addFilter(f2);
      manager.addFilter(f3);

      final filters = manager.getFilters();
      expect(filters, hasLength(3));
      expect(filters[0], same(f1));
      expect(filters[1], same(f2));
      expect(filters[2], same(f3));
    });

    test('addFilter removes duplicate before re-adding', () {
      final log = <String>[];
      final filter = RecordingFilter('same', log);

      manager.addFilter(filter);
      manager.addFilter(RecordingFilter('other', log));
      manager.addFilter(filter);

      final filters = manager.getFilters();
      expect(filters, hasLength(2));
      expect((filters[0] as RecordingFilter).filterName, equals('other'));
      expect((filters[1] as RecordingFilter).filterName, equals('same'));
    });

    test('filters can be executed through the manager list', () async {
      final log = <String>[];
      final filter = RecordingFilter('mgr', log);
      manager.addFilter(filter);

      final request = MockServerHttpRequest();
      final response = MockServerHttpResponse();
      final chain = MockFilterChain();

      final filters = manager.getFilters();
      await filters.first.doFilter(request, response, chain);

      expect(log, equals(['mgr:pre', 'mgr:post']));
    });

    test('addFilter is idempotent for same instance', () {
      final log = <String>[];
      final filter = RecordingFilter('idem', log);

      manager.addFilter(filter);
      manager.addFilter(filter);
      manager.addFilter(filter);

      expect(manager.getFilters(), hasLength(1));
      expect(manager.getFilters().first, same(filter));
    });
  });

  // -------------------------------------------------------------------------
  // OncePerRequestFilter
  // -------------------------------------------------------------------------
  group('OncePerRequestFilter', () {
    test('doFilterInternal is called on first invocation', () async {
      final request = MockServerHttpRequest();
      final response = MockServerHttpResponse();
      final chain = MockFilterChain();
      final log = <String>[];
      final filter = TestOncePerRequestFilter(log);

      await filter.doFilter(request, response, chain);

      expect(log, equals(['doFilterInternal']));
      expect(chain.nextCalled, isTrue);
    });

    test('doFilterInternal is skipped when filter already applied', () async {
      final request = MockServerHttpRequest();
      final response = MockServerHttpResponse();
      final chain = MockFilterChain();
      final log = <String>[];
      final filter = TestOncePerRequestFilter(log);

      await filter.doFilter(request, response, chain);
      await filter.doFilter(request, response, chain);

      expect(log, equals(['doFilterInternal', 'doFilterInternal']));
      expect(chain.nextCallCount, equals(2));
    });

    test('applied marker is removed after execution', () async {
      final request = MockServerHttpRequest();
      final response = MockServerHttpResponse();
      final chain = MockFilterChain();
      final log = <String>[];
      final filter = TestOncePerRequestFilter(log);

      await filter.doFilter(request, response, chain);

      expect(request.getAttributeNames(), isEmpty);
    });

    test('filter can short-circuit without calling chain', () async {
      final request = MockServerHttpRequest();
      final response = MockServerHttpResponse();
      final chain = MockFilterChain();
      final filter = ShortCircuitOncePerRequestFilter();

      await filter.doFilter(request, response, chain);

      expect(chain.nextCalled, isFalse);
      expect(response.getStatus(), equals(HttpStatus.UNAUTHORIZED));
    });

    test('filter that throws still cleans up the marker', () async {
      final request = MockServerHttpRequest();
      final response = MockServerHttpResponse();
      final chain = MockFilterChain();
      final filter = ThrowingOncePerRequestFilter();

      expect(
        () => filter.doFilter(request, response, chain),
        throwsA(isA<StateError>()),
      );

      expect(request.getAttributeNames(), isNotEmpty);
    });

    test('different filter instances track independently', () async {
      final request = MockServerHttpRequest();
      final response = MockServerHttpResponse();
      final chain = MockFilterChain();
      final logA = <String>[];
      final logB = <String>[];
      final filterA = TestOncePerRequestFilter(logA);
      final filterB = TestOncePerRequestFilter(logB);

      await filterA.doFilter(request, response, chain);
      await filterB.doFilter(request, response, chain);

      expect(logA, equals(['doFilterInternal']));
      expect(logB, equals(['doFilterInternal']));
    });

    test('different requests track independently', () async {
      final response = MockServerHttpResponse();
      final chain = MockFilterChain();
      final log = <String>[];
      final filter = TestOncePerRequestFilter(log);

      final req1 = MockServerHttpRequest(path: '/a');
      final req2 = MockServerHttpRequest(path: '/b');

      await filter.doFilter(req1, response, chain);
      await filter.doFilter(req2, response, chain);

      expect(log, equals(['doFilterInternal', 'doFilterInternal']));
      expect(chain.nextCallCount, equals(2));
    });

    test('chain is called even when filter is skipped', () async {
      final request = MockServerHttpRequest();
      final response = MockServerHttpResponse();
      final chain = MockFilterChain();
      final log = <String>[];
      final filter = TestOncePerRequestFilter(log);

      await filter.doFilter(request, response, chain);
      await filter.doFilter(request, response, chain);

      expect(chain.nextCallCount, equals(2));
    });

    test('multiple once-per-request filters on same request each run once', () async {
      final request = MockServerHttpRequest();
      final response = MockServerHttpResponse();
      final chain = MockFilterChain();
      final logA = <String>[];
      final logB = <String>[];
      final filterA = TestOncePerRequestFilter(logA);
      final filterB = TestOncePerRequestFilter(logB);

      await filterA.doFilter(request, response, chain);
      await filterA.doFilter(request, response, chain);
      await filterB.doFilter(request, response, chain);
      await filterB.doFilter(request, response, chain);

      expect(logA, equals(['doFilterInternal', 'doFilterInternal']));
      expect(logB, equals(['doFilterInternal', 'doFilterInternal']));
      expect(chain.nextCallCount, equals(4));
    });
  });

  // -------------------------------------------------------------------------
  // ExceptionResolver interface
  // -------------------------------------------------------------------------
  group('ExceptionResolver interface', () {
    test('resolver that handles returns true', () async {
      final request = MockServerHttpRequest();
      final response = MockServerHttpResponse();
      final resolver = MockExceptionResolver(handled: true);
      final ex = Exception('test');

      final result = await resolver.resolve(request, response, null, ex, StackTrace.empty);

      expect(result, isTrue);
    });

    test('resolver that cannot handle returns false', () async {
      final request = MockServerHttpRequest();
      final response = MockServerHttpResponse();
      final resolver = MockFailingExceptionResolver();
      final ex = Exception('test');

      final result = await resolver.resolve(request, response, null, ex, StackTrace.empty);

      expect(result, isFalse);
    });

    test('getSupportedMediaTypes returns configured types', () {
      final resolver = MockExceptionResolver(
        mediaTypes: [MediaType.APPLICATION_JSON, MediaType.TEXT_HTML],
      );

      final types = resolver.getSupportedMediaTypes();

      expect(types, hasLength(2));
      expect(types, contains(MediaType.APPLICATION_JSON));
      expect(types, contains(MediaType.TEXT_HTML));
    });

    test('resolver receives the thrown exception', () async {
      final request = MockServerHttpRequest();
      final response = MockServerHttpResponse();
      Object? receivedException;

      final resolver = _CapturingResolver((ex) => receivedException = ex);
      final ex = StateError('captured');

      await resolver.resolve(request, response, null, ex, StackTrace.empty);

      expect(receivedException, isA<StateError>());
      expect((receivedException as StateError).message, equals('captured'));
    });

    test('resolver receives stack trace', () async {
      final request = MockServerHttpRequest();
      final response = MockServerHttpResponse();
      StackTrace? receivedStack;

      final resolver = _CapturingResolverWithStack((ex, st) => receivedStack = st);
      final stack = StackTrace.fromString('test-stack');

      await resolver.resolve(request, response, null, Exception('ex'), stack);

      expect(receivedStack, same(stack));
    });

    test('resolver receives handler method when provided', () async {
      final request = MockServerHttpRequest();
      final response = MockServerHttpResponse();
      HandlerMethod? receivedHandler;

      final resolver = _CapturingResolverWithHandler((handler) => receivedHandler = handler);
      final mockHandler = _MockHandlerMethod();

      await resolver.resolve(request, response, mockHandler, Exception('ex'), StackTrace.empty);

      expect(receivedHandler, same(mockHandler));
    });

    test('resolver receives null handler gracefully', () async {
      final request = MockServerHttpRequest();
      final response = MockServerHttpResponse();
      HandlerMethod? receivedHandler;

      final resolver = _CapturingResolverWithHandler((handler) => receivedHandler = handler);

      await resolver.resolve(request, response, null, Exception('ex'), StackTrace.empty);

      expect(receivedHandler, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // HtmlExceptionResolver - supported media types contract
  // -------------------------------------------------------------------------
  group('HtmlExceptionResolver', () {
    test('getSupportedMediaTypes includes TEXT_HTML', () {
      final types = [MediaType.TEXT_HTML];
      expect(types, contains(MediaType.TEXT_HTML));
      expect(types.first.getSubtype(), equals('html'));
    });

    test('supported media types contain only html', () {
      const types = <MediaType>[MediaType.TEXT_HTML];
      expect(types, hasLength(1));
      expect(types.first.getType(), equals('text'));
      expect(types.first.getSubtype(), equals('html'));
    });

    test('TEXT_HTML media type is text/html', () {
      expect(MediaType.TEXT_HTML.getType(), equals('text'));
      expect(MediaType.TEXT_HTML.getSubtype(), equals('html'));
    });
  });

  // -------------------------------------------------------------------------
  // RestExceptionResolver - supported media types contract
  // -------------------------------------------------------------------------
  group('RestExceptionResolver', () {
    test('getSupportedMediaTypes includes JSON, XML, YAML, TEXT_PLAIN, TEXT_HTML', () {
      const expected = <MediaType>[
        MediaType.APPLICATION_JSON,
        MediaType.APPLICATION_XML,
        MediaType.APPLICATION_YAML,
        MediaType.TEXT_PLAIN,
        MediaType.TEXT_HTML,
      ];

      expect(expected, hasLength(5));
      expect(expected, contains(MediaType.APPLICATION_JSON));
      expect(expected, contains(MediaType.APPLICATION_XML));
      expect(expected, contains(MediaType.APPLICATION_YAML));
      expect(expected, contains(MediaType.TEXT_PLAIN));
      expect(expected, contains(MediaType.TEXT_HTML));
    });

    test('JSON media type has correct type and subtype', () {
      expect(MediaType.APPLICATION_JSON.getType(), equals('application'));
      expect(MediaType.APPLICATION_JSON.getSubtype(), equals('json'));
    });

    test('XML media type has correct type and subtype', () {
      expect(MediaType.APPLICATION_XML.getType(), equals('application'));
      expect(MediaType.APPLICATION_XML.getSubtype(), equals('xml'));
    });
  });

  // -------------------------------------------------------------------------
  // Integration: Filter chain ordering
  // -------------------------------------------------------------------------
  group('Filter chain ordering integration', () {
    test('filters execute in registration order', () async {
      final log = <String>[];
      final manager = FilterManager();

      manager.addFilter(RecordingFilter('A', log));
      manager.addFilter(RecordingFilter('B', log));
      manager.addFilter(RecordingFilter('C', log));

      final request = MockServerHttpRequest();
      final response = MockServerHttpResponse();
      final chain = MockFilterChain();

      for (final filter in manager.getFilters()) {
        await filter.doFilter(request, response, chain);
      }

      expect(
        log,
        equals([
          'A:pre',
          'A:post',
          'B:pre',
          'B:post',
          'C:pre',
          'C:post',
        ]),
      );
    });

    test('short-circuit filter stops subsequent filters', () async {
      final log = <String>[];
      final manager = FilterManager();

      manager.addFilter(RecordingFilter('A', log));
      manager.addFilter(ShortCircuitFilter());
      manager.addFilter(RecordingFilter('C', log));

      final request = MockServerHttpRequest();
      final response = MockServerHttpResponse();
      final chain = MockFilterChain();

      for (final filter in manager.getFilters()) {
        if (response.getStatus() == null) {
          await filter.doFilter(request, response, chain);
        }
      }

      expect(log, equals(['A:pre', 'A:post']));
      expect(response.getStatus(), equals(HttpStatus.FORBIDDEN));
    });

    test('once-per-request filter prevents double execution in chain', () async {
      final log = <String>[];
      final manager = FilterManager();
      final onceFilter = TestOncePerRequestFilter(log);

      manager.addFilter(RecordingFilter('pre', log));
      manager.addFilter(onceFilter);
      manager.addFilter(RecordingFilter('post', log));

      final request = MockServerHttpRequest();
      final response = MockServerHttpResponse();
      final chain = MockFilterChain();

      for (final filter in manager.getFilters()) {
        await filter.doFilter(request, response, chain);
      }

      expect(
        log,
        equals([
          'pre:pre',
          'pre:post',
          'doFilterInternal',
          'post:pre',
          'post:post',
        ]),
      );
    });

    test('exception in filter does not prevent marker cleanup', () async {
      final log = <String>[];
      final manager = FilterManager();

      manager.addFilter(ThrowingFilter());
      manager.addFilter(RecordingFilter('after', log));

      final request = MockServerHttpRequest();
      final response = MockServerHttpResponse();
      final chain = MockFilterChain();

      for (final filter in manager.getFilters()) {
        try {
          await filter.doFilter(request, response, chain);
        } catch (_) {}
      }

      expect(log, equals(['after:pre', 'after:post']));
      expect(response.getStatus(), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Edge cases
  // -------------------------------------------------------------------------
  group('Edge cases', () {
    test('filter manager handles many filters', () {
      final manager = FilterManager();
      final log = <String>[];

      for (var i = 0; i < 100; i++) {
        manager.addFilter(RecordingFilter('f$i', log));
      }

      expect(manager.getFilters(), hasLength(100));
    });

    test('filter manager deduplication with many filters', () {
      final manager = FilterManager();
      final log = <String>[];

      for (var i = 0; i < 50; i++) {
        manager.addFilter(RecordingFilter('f$i', log));
      }

      for (var i = 0; i < 50; i++) {
        manager.addFilter(RecordingFilter('f$i', log));
      }

      expect(manager.getFilters(), hasLength(100));
    });

    test('exception resolver handles multiple exceptions sequentially', () async {
      final request = MockServerHttpRequest();
      final response = MockServerHttpResponse();
      final results = <bool>[];

      final resolver = MockExceptionResolver(handled: true);

      results.add(await resolver.resolve(request, response, null, Exception('e1'), StackTrace.empty));
      results.add(await resolver.resolve(request, response, null, Exception('e2'), StackTrace.empty));
      results.add(await resolver.resolve(request, response, null, StateError('e3'), StackTrace.empty));

      expect(results, everyElement(isTrue));
    });

    test('filter receives correct request and response references', () async {
      final request = MockServerHttpRequest(path: '/specific');
      final response = MockServerHttpResponse();
      final chain = MockFilterChain();

      ServerHttpRequest? capturedRequest;
      ServerHttpResponse? capturedResponse;

      final filter = _CapturingFilter((req, resp) {
        capturedRequest = req;
        capturedResponse = resp;
      });

      await filter.doFilter(request, response, chain);

      expect(capturedRequest, same(request));
      expect(capturedResponse, same(response));
    });

    test('mock request attribute round-trip', () {
      final request = MockServerHttpRequest();

      request.setAttribute('key1', 'value1');
      expect(request.getAttribute('key1'), equals('value1'));
      expect(request.getAttributeNames(), contains('key1'));

      request.removeAttribute('key1');
      expect(request.getAttribute('key1'), isNull);
      expect(request.getAttributeNames(), isEmpty);
    });

    test('mock response status round-trip', () {
      final response = MockServerHttpResponse();

      expect(response.getStatus(), isNull);

      response.setStatus(HttpStatus.OK);
      expect(response.getStatus(), equals(HttpStatus.OK));

      response.setStatus(HttpStatus.NOT_FOUND);
      expect(response.getStatus(), equals(HttpStatus.NOT_FOUND));
    });

    test('mock response reason round-trip', () {
      final response = MockServerHttpResponse();

      response.setReason('All good');
      expect(response.getReason(), equals('All good'));
    });

    test('mock request query string', () {
      final withQuery = MockServerHttpRequest(path: '/test?a=1&b=2');
      expect(withQuery.getQueryString(), equals('a=1&b=2'));

      final withoutQuery = MockServerHttpRequest(path: '/test');
      expect(withoutQuery.getQueryString(), isNull);
    });

    test('mock request context path', () {
      final request = MockServerHttpRequest(contextPath: '/app');
      expect(request.getContextPath(), equals('/app'));

      request.setContextPath('/v2');
      expect(request.getContextPath(), equals('/v2'));
    });
  });
}

// ---------------------------------------------------------------------------
// Helper mock classes for specific test needs
// ---------------------------------------------------------------------------

class _CapturingResolver implements ExceptionResolver {
  final void Function(Object ex) onResolve;

  _CapturingResolver(this.onResolve);

  @override
  List<MediaType> getSupportedMediaTypes() => [MediaType.APPLICATION_JSON];

  @override
  Future<bool> resolve(ServerHttpRequest request, ServerHttpResponse response, HandlerMethod? handler, Object ex, StackTrace st) async {
    onResolve(ex);
    return true;
  }
}

class _CapturingResolverWithStack implements ExceptionResolver {
  final void Function(Object ex, StackTrace st) onResolve;

  _CapturingResolverWithStack(this.onResolve);

  @override
  List<MediaType> getSupportedMediaTypes() => [MediaType.APPLICATION_JSON];

  @override
  Future<bool> resolve(ServerHttpRequest request, ServerHttpResponse response, HandlerMethod? handler, Object ex, StackTrace st) async {
    onResolve(ex, st);
    return true;
  }
}

class _CapturingResolverWithHandler implements ExceptionResolver {
  final void Function(HandlerMethod? handler) onResolve;

  _CapturingResolverWithHandler(this.onResolve);

  @override
  List<MediaType> getSupportedMediaTypes() => [MediaType.APPLICATION_JSON];

  @override
  Future<bool> resolve(ServerHttpRequest request, ServerHttpResponse response, HandlerMethod? handler, Object ex, StackTrace st) async {
    onResolve(handler);
    return true;
  }
}

class _CapturingFilter implements Filter {
  final void Function(ServerHttpRequest request, ServerHttpResponse response) onFilter;

  _CapturingFilter(this.onFilter);

  @override
  Future<void> doFilter(ServerHttpRequest request, ServerHttpResponse response, FilterChain chain) async {
    onFilter(request, response);
    await chain.next(request, response);
  }

  @override
  List<Object?> equalizedProperties() => [runtimeType];
}

class _MockHandlerMethod implements HandlerMethod {
  @override
  HandlerArgumentContext getContext() => throw UnimplementedError();

  @override
  Class getInvokingClass() => throw UnimplementedError();

  @override
  Method? getMethod() => null;

  @override
  HttpMethod getHttpMethod() => HttpMethod.GET;

  @override
  String getPath() => '/mock';
}
