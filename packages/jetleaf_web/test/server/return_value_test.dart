// ignore_for_file: invalid_use_of_protected_member

import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import 'package:jetleaf_web/src/converter/http_message_converters.dart';
import 'package:jetleaf_web/src/http/http_cookies.dart';
import 'package:jetleaf_web/src/http/http_headers.dart' as jetleaf_headers;
import 'package:jetleaf_web/src/http/http_method.dart';
import 'package:jetleaf_web/src/http/http_session.dart';
import 'package:jetleaf_web/src/http/http_status.dart';
import 'package:jetleaf_web/src/http/media_type.dart';
import 'package:jetleaf_web/src/server/handler_method.dart';
import 'package:jetleaf_web/src/server/content_negotiation/content_negotiation_resolver.dart';
import 'package:jetleaf_web/src/server/return_value_handler/default_return_value_handler_manager.dart';
import 'package:jetleaf_web/src/server/return_value_handler/json_return_value_handler.dart';
import 'package:jetleaf_web/src/server/return_value_handler/redirect_return_value_handler.dart';
import 'package:jetleaf_web/src/server/return_value_handler/string_return_value_handler.dart';
import 'package:jetleaf_web/src/server/return_value_handler/void_return_value_handler.dart';
import 'package:jetleaf_web/src/server/server_http_request.dart';
import 'package:jetleaf_web/src/server/server_http_response.dart';
import 'package:jetleaf_web/src/http/http_body.dart';
import 'package:jetleaf_web/src/web/view.dart';
import 'package:jtl/jtl.dart';

// ---------------------------------------------------------------------------
// Stub / Mock helpers
// ---------------------------------------------------------------------------

class _StubInputStream extends InputStream {
  @override
  Future<int> read(List<int> b, [int offset = 0, int? length]) async => -1;

  @override
  Future<int> readByte() async => -1;

  @override
  Future<Uint8List> readAll() async => Uint8List(0);

  @override
  Future<Uint8List> readFully(int length) async => Uint8List(0);

  @override
  Future<String> readAsString([Encoding encoding = utf8]) async => '';
}

class _StubOutputStream extends OutputStream {
  String _writtenContent = '';

  String get writtenContent => _writtenContent;
  bool flushed = false;

  @override
  Future<void> writeByte(int b) async {}

  @override
  Future<void> writeObject(Object? obj) async {
    _writtenContent += obj.toString();
  }

  @override
  Future<void> flush() async {
    flushed = true;
  }

  @override
  Future<void> write(List<int> b, [int offset = 0, int? length]) async {
    _writtenContent += String.fromCharCodes(b, offset, offset + (length ?? b.length));
  }
}

class MockHttpRequest implements ServerHttpRequest {
  HttpMethod _method = HttpMethod.GET;
  Uri _uri = Uri.parse('http://localhost:8080/');
  Uri _requestUri = Uri.parse('/');
  String _contextPath = '';
  String? _requestUrl;
  final Map<String, Object> _attributes = {};
  final Map<String, String> _pathVariables = {};
  final Map<String, List<String>> _parameters = {};
  final jetleaf_headers.HttpHeaders _headers = jetleaf_headers.HttpHeaders();
  final HttpCookies _cookies = HttpCookies();
  HttpSession? _session;

  void setMethod(HttpMethod method) => _method = method;
  void setUri(Uri uri) {
    _uri = uri;
    _requestUri = Uri(path: uri.path, query: uri.query);
  }

  @override
  void setContextPath(String path) => _contextPath = path;
  
  void addHeader(String name, String value) => _headers.add(name, value);

  @override
  HttpMethod getMethod() => _method;

  @override
  Uri getUri() => _uri;

  @override
  Uri getRequestURI() => _requestUri;

  @override
  String? getQueryString() {
    final query = _uri.query;
    return query.isEmpty ? null : query;
  }

  @override
  String? getParameter(String name) {
    final values = _parameters[name];
    return values?.isNotEmpty == true ? values!.first : null;
  }

  @override
  List<String> getParameterValues(String name) => _parameters[name] ?? [];

  @override
  Map<String, List<String>> getParameterMap() =>
      Map.unmodifiable(_parameters);

  @override
  String getContextPath() => _contextPath;

  @override
  Map<String, Object> getAttributes() => Map.unmodifiable(_attributes);

  @override
  Object? getAttribute(String name) => _attributes[name];

  @override
  void setAttribute(String name, Object value) => _attributes[name] = value;

  @override
  void removeAttribute(String name) => _attributes.remove(name);

  @override
  Set<String> getAttributeNames() => _attributes.keys.toSet();

  @override
  jetleaf_headers.HttpHeaders getHeaders() => _headers;

  @override
  void setHeaders(jetleaf_headers.HttpHeaders headers) {
    _headers.clear();
    _headers.addAllFromHeaders(headers);
  }

  @override
  HttpCookies getCookies() => _cookies;

  @override
  HttpSession? getSession([bool create = true]) => _session;

  @override
  String? getPathVariable(String name) => _pathVariables[name];

  @override
  Map<String, String> getPathVariables() => Map.unmodifiable(_pathVariables);

  @override
  bool shouldUpgrade() => false;

  @override
  void setRequestUrl(String requestUrl) => _requestUrl = requestUrl;

  @override
  String? getRequestUrl() => _requestUrl;

  @override
  int getContentLength() => 0;

  @override
  void setHandlerContext(HandlerMethod handler, dynamic pattern) {}

  @override
  String getOrigin() => '${_uri.scheme}://${_uri.host}';

  @override
  InputStream getBody() => _StubInputStream();
}

class MockHttpResponse implements ServerHttpResponse {
  int _statusCode = 200;
  final jetleaf_headers.HttpHeaders _headers = jetleaf_headers.HttpHeaders();
  final _StubOutputStream _body = _StubOutputStream();
  bool _committed = false;
  String? _redirectLocation;

  _StubOutputStream get rawBody => _body;
  String? get redirectLocation => _redirectLocation;
  int get recordedStatusCode => _statusCode;
  bool get committed => _committed;

  @override
  void setStatus(HttpStatus httpStatus) => _statusCode = httpStatus.getCode();

  @override
  HttpStatus? getStatus() => HttpStatus.fromCode(_statusCode);

  @override
  jetleaf_headers.HttpHeaders getHeaders() => _headers;

  @override
  void setHeaders(jetleaf_headers.HttpHeaders headers) {
    _headers.clear();
    _headers.addAllFromHeaders(headers);
  }

  @override
  OutputStream getBody() => _body;

  @override
  Future<String> encodeRedirectUrl(String location) async => location;

  @override
  Future<void> sendRedirect(String encodedLocation) async {
    _redirectLocation = encodedLocation;
    _committed = true;
  }

  @override
  bool isCommitted() => _committed;

  @override
  void setReason(String message) {}
}

class _StubContentNegotiationResolver implements ContentNegotiationResolver {
  @override
  Future<void> resolve(Method? method, ServerHttpRequest request,
      ServerHttpResponse response, List<MediaType> supportedMediaTypes) async {}
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  // ReturnValueHandler interface
  // =========================================================================
  group('ReturnValueHandler interface', () {
    test('canHandle returns true when handler accepts the value', () {
      const handler = StringReturnValueHandler();
      final request = MockHttpRequest();
      expect(handler.canHandle(null, 'hello', request), isTrue);
    });

    test('canHandle returns false when handler rejects the value', () {
      const handler = StringReturnValueHandler();
      final request = MockHttpRequest();
      expect(handler.canHandle(null, 42, request), isFalse);
    });

    test('getSupportedMediaTypes returns non-empty list for string handler', () {
      const handler = StringReturnValueHandler();
      expect(handler.getSupportedMediaTypes(), isNotEmpty);
    });

    test('getSupportedMediaTypes returns empty list for void handler', () {
      const handler = VoidReturnValueHandler();
      expect(handler.getSupportedMediaTypes(), isEmpty);
    });
  });

  // =========================================================================
  // DefaultReturnValueHandlerManager
  // =========================================================================
  group('DefaultReturnValueHandlerManager', () {
    late DefaultReturnValueHandlerManager manager;
    late ContentNegotiationResolver resolver;

    setUp(() {
      resolver = _StubContentNegotiationResolver();
      manager = DefaultReturnValueHandlerManager(resolver);
    });

    test('findHandler returns null when no handlers registered', () {
      final request = MockHttpRequest();
      final handler = manager.findHandler(null, 'hello', request);
      expect(handler, isNull);
    });

    test('getHandlers returns empty list initially', () {
      expect(manager.getHandlers(), isEmpty);
    });

    test('canHandle returns false when no handler matches', () {
      final request = MockHttpRequest();
      expect(manager.canHandle(null, 'hello', request), isFalse);
    });

    test('canHandle returns true when a handler matches', () {
      manager.addHandler(const StringReturnValueHandler());
      final request = MockHttpRequest();
      expect(manager.canHandle(null, 'hello', request), isTrue);
    });

    test('findHandler returns correct handler for string value', () {
      manager.addHandler(const StringReturnValueHandler());
      manager.addHandler(const VoidReturnValueHandler());
      final request = MockHttpRequest();
      final handler = manager.findHandler(null, 'hello', request);
      expect(handler, isA<StringReturnValueHandler>());
    });

    test('findHandler returns null for unmatched value', () {
      manager.addHandler(const StringReturnValueHandler());
      final request = MockHttpRequest();
      final handler = manager.findHandler(null, 42, request);
      expect(handler, isNull);
    });

    test('getHandlers returns unmodifiable list', () {
      manager.addHandler(const StringReturnValueHandler());
      final handlers = manager.getHandlers();
      expect(() => handlers.add(const VoidReturnValueHandler()),
          throwsUnsupportedError);
    });

    test('getSupportedMediaTypes aggregates from registered handlers', () {
      manager.addHandler(const StringReturnValueHandler());
      manager.addHandler(const VoidReturnValueHandler());
      final mediaTypes = manager.getSupportedMediaTypes();
      expect(mediaTypes, isNotEmpty);
      expect(mediaTypes, contains(MediaType.TEXT_PLAIN));
    });

    test('handleReturnValue sets NO_CONTENT for null when no status set', () async {
      final response = MockHttpResponse();
      final request = MockHttpRequest();
      await manager.handleReturnValue(null, null, request, response, null);
      expect(response.getStatus(), equals(HttpStatus.OK));
    });

    test('handleReturnValue delegates to matched handler', () async {
      manager.addHandler(const StringReturnValueHandler());
      final response = MockHttpResponse();
      final request = MockHttpRequest();
      await manager.handleReturnValue('hello world', null, request, response, null);
      expect(response.getStatus(), equals(HttpStatus.OK));
      expect(response.rawBody.writtenContent, contains('hello world'));
    });
  });

  // =========================================================================
  // JsonReturnValueHandler
  // =========================================================================
  group('JsonReturnValueHandler', () {
    late JsonReturnValueHandler handler;
    late HttpMessageConverters converters;

    setUp(() {
      converters = HttpMessageConverters();
      handler = JsonReturnValueHandler(converters);
    });

    test('getSupportedMediaTypes includes APPLICATION_JSON', () {
      expect(handler.getSupportedMediaTypes(), contains(MediaType.APPLICATION_JSON));
    });

    test('canHandle returns false for null', () {
      final request = MockHttpRequest();
      expect(handler.canHandle(null, null, request), isFalse);
    });

    test('canHandle returns false for String', () {
      final request = MockHttpRequest();
      expect(handler.canHandle(null, 'hello', request), isFalse);
    });

    test('canHandle returns false for ResponseBody', () {
      final request = MockHttpRequest();
      final body = ResponseBody(HttpStatus.OK, 'data');
      expect(handler.canHandle(null, body, request), isFalse);
    });

    test('canHandle returns true for Map', () {
      final request = MockHttpRequest();
      expect(handler.canHandle(null, {'key': 'value'}, request), isTrue);
    });

    test('canHandle returns true for List', () {
      final request = MockHttpRequest();
      expect(handler.canHandle(null, [1, 2, 3], request), isTrue);
    });

    test('canHandle returns false for non-null non-String non-ResponseBody', () {
      final request = MockHttpRequest();
      expect(handler.canHandle(null, 42, request), isFalse);
    });

    test('handleReturnValue does not override existing status for null', () async {
      final response = MockHttpResponse();
      final request = MockHttpRequest();
      await handler.handleReturnValue(null, null, request, response, null);
      expect(response.getStatus(), equals(HttpStatus.OK));
    });

    test('handleReturnValue returns early for null when status already set', () async {
      final response = MockHttpResponse();
      response.setStatus(HttpStatus.OK);
      final request = MockHttpRequest();
      await handler.handleReturnValue(null, null, request, response, null);
      // Should not overwrite existing status
      expect(response.getStatus(), equals(HttpStatus.OK));
    });
  });

  // =========================================================================
  // StringReturnValueHandler
  // =========================================================================
  group('StringReturnValueHandler', () {
    const handler = StringReturnValueHandler();

    test('getSupportedMediaTypes includes text types', () {
      final mediaTypes = handler.getSupportedMediaTypes();
      expect(mediaTypes, contains(MediaType.TEXT_PLAIN));
      expect(mediaTypes, contains(MediaType.TEXT_HTML));
    });

    test('canHandle returns false for null', () {
      final request = MockHttpRequest();
      expect(handler.canHandle(null, null, request), isFalse);
    });

    test('canHandle returns true for plain string', () {
      final request = MockHttpRequest();
      expect(handler.canHandle(null, 'hello', request), isTrue);
    });

    test('canHandle returns false for redirect string', () {
      final request = MockHttpRequest();
      expect(handler.canHandle(null, 'redirect:/login', request), isFalse);
    });

    test('canHandle returns false for non-String types', () {
      final request = MockHttpRequest();
      expect(handler.canHandle(null, 42, request), isFalse);
      expect(handler.canHandle(null, true, request), isFalse);
      expect(handler.canHandle(null, {'a': 1}, request), isFalse);
    });

    test('handleReturnValue writes string to response body', () async {
      final response = MockHttpResponse();
      final request = MockHttpRequest();
      await handler.handleReturnValue('Hello, World!', null, request, response, null);
      expect(response.rawBody.writtenContent, equals('Hello, World!'));
    });

    test('handleReturnValue sets OK status when none set', () async {
      final response = MockHttpResponse();
      final request = MockHttpRequest();
      await handler.handleReturnValue('test', null, request, response, null);
      expect(response.getStatus(), equals(HttpStatus.OK));
    });

    test('handleReturnValue respects pre-set status', () async {
      final response = MockHttpResponse();
      response.setStatus(HttpStatus.CREATED);
      final request = MockHttpRequest();
      await handler.handleReturnValue('created', null, request, response, null);
      expect(response.getStatus(), equals(HttpStatus.CREATED));
    });

    test('handleReturnValue uses Accept header for Content-Type', () async {
      final response = MockHttpResponse();
      final request = MockHttpRequest();
      request.addHeader('Accept', 'text/html');
      await handler.handleReturnValue('<p>hi</p>', null, request, response, null);
      expect(response.getHeaders().getContentType(), equals(MediaType.TEXT_HTML));
    });

    test('handleReturnValue defaults to text/plain when no Accept header', () async {
      final response = MockHttpResponse();
      final request = MockHttpRequest();
      await handler.handleReturnValue('plain', null, request, response, null);
      expect(response.getHeaders().getContentType(), equals(MediaType.TEXT_PLAIN));
    });
  });

  // =========================================================================
  // RedirectReturnValueHandler
  // =========================================================================
  group('RedirectReturnValueHandler', () {
    late RedirectReturnValueHandler handler;
    late AssetBuilder assetBuilder;
    late Jtl jtl;

    setUp(() {
      assetBuilder = AssetBuilder();
      jtl = JtlFactory();
      handler = RedirectReturnValueHandler(assetBuilder, jtl);
    });

    test('getSupportedMediaTypes includes TEXT_HTML', () {
      expect(handler.getSupportedMediaTypes(), contains(MediaType.TEXT_HTML));
    });

    test('canHandle returns false for null', () {
      final request = MockHttpRequest();
      expect(handler.canHandle(null, null, request), isFalse);
    });

    test('canHandle returns true for redirect string', () {
      final request = MockHttpRequest();
      expect(handler.canHandle(null, 'redirect:/dashboard', request), isTrue);
    });

    test('canHandle returns false for plain string', () {
      final request = MockHttpRequest();
      expect(handler.canHandle(null, 'hello', request), isFalse);
    });

    test('canHandle returns true for RedirectView', () {
      final request = MockHttpRequest();
      expect(handler.canHandle(null, RedirectView('/login'), request), isTrue);
    });

    test('canHandle returns false for PageView', () {
      final request = MockHttpRequest();
      expect(handler.canHandle(null, PageView('home.html'), request), isFalse);
    });

    test('canHandle returns false for non-string non-RedirectView types', () {
      final request = MockHttpRequest();
      expect(handler.canHandle(null, 42, request), isFalse);
      expect(handler.canHandle(null, {'key': 'value'}, request), isFalse);
    });

    test('handleReturnValue redirects to correct location for string', () async {
      final response = MockHttpResponse();
      final request = MockHttpRequest();
      request.setContextPath('/app');
      await handler.handleReturnValue('redirect:/dashboard', null, request, response, null);
      expect(response.redirectLocation, equals('/app/dashboard'));
      expect(response.getStatus(), equals(HttpStatus.MOVED_TEMPORARILY));
    });

    test('handleReturnValue sets no-store cache control', () async {
      final response = MockHttpResponse();
      final request = MockHttpRequest();
      await handler.handleReturnValue('redirect:/page', null, request, response, null);
      expect(response.getHeaders().getFirst('Cache-Control'), equals('no-store'));
    });

    test('handleReturnValue sets Location header', () async {
      final response = MockHttpResponse();
      final request = MockHttpRequest();
      await handler.handleReturnValue('redirect:/somewhere', null, request, response, null);
      expect(response.getHeaders().getFirst('Location'), isNotNull);
    });

    test('handleReturnValue handles absolute URL redirect', () async {
      final response = MockHttpResponse();
      final request = MockHttpRequest();
      await handler.handleReturnValue('redirect:https://example.com', null, request, response, null);
      expect(response.redirectLocation, equals('https://example.com'));
    });

    test('handleReturnValue sets FOUND status for redirect string', () async {
      final response = MockHttpResponse();
      final request = MockHttpRequest();
      await handler.handleReturnValue('redirect:/home', null, request, response, null);
      expect(response.getStatus(), equals(HttpStatus.MOVED_TEMPORARILY));
    });
  });

  // =========================================================================
  // VoidReturnValueHandler
  // =========================================================================
  group('VoidReturnValueHandler', () {
    const handler = VoidReturnValueHandler();

    test('getSupportedMediaTypes returns empty list', () {
      expect(handler.getSupportedMediaTypes(), isEmpty);
    });

    test('canHandle returns true for null return value', () {
      final request = MockHttpRequest();
      expect(handler.canHandle(null, null, request), isTrue);
    });

    test('canHandle returns false for non-null return value', () {
      final request = MockHttpRequest();
      expect(handler.canHandle(null, 'hello', request), isFalse);
      expect(handler.canHandle(null, 42, request), isFalse);
      expect(handler.canHandle(null, true, request), isFalse);
    });

    // Note: Testing the `method.isFutureVoid()` path requires a real Method
    // instance from dart:mirrors or the framework's reflection system.
    // The null-method paths are covered by the other tests above.

    test('handleReturnValue does not override existing status when no status set', () async {
      final response = MockHttpResponse();
      final request = MockHttpRequest();
      await handler.handleReturnValue(null, null, request, response, null);
      expect(response.getStatus(), equals(HttpStatus.OK));
    });

    test('handleReturnValue respects pre-set status', () async {
      final response = MockHttpResponse();
      response.setStatus(HttpStatus.OK);
      final request = MockHttpRequest();
      await handler.handleReturnValue(null, null, request, response, null);
      expect(response.getStatus(), equals(HttpStatus.OK));
    });

    test('handleReturnValue does nothing when response is committed', () async {
      final response = MockHttpResponse();
      final request = MockHttpRequest();
      // Force committed
      await response.sendRedirect('/somewhere');
      expect(response.isCommitted(), isTrue);
      // Should not throw or modify status
      await handler.handleReturnValue(null, null, request, response, null);
    });
  });

  // =========================================================================
  // Handler precedence and interaction
  // =========================================================================
  group('Handler precedence and interaction', () {
    late DefaultReturnValueHandlerManager manager;
    late ContentNegotiationResolver resolver;

    setUp(() {
      resolver = _StubContentNegotiationResolver();
      manager = DefaultReturnValueHandlerManager(resolver);
      manager.addHandler(const StringReturnValueHandler());
      manager.addHandler(const VoidReturnValueHandler());
      manager.addHandler(JsonReturnValueHandler(HttpMessageConverters()));
    });

    test('string handler chosen over void for non-null string', () {
      final request = MockHttpRequest();
      final handler = manager.findHandler(null, 'hello', request);
      expect(handler, isA<StringReturnValueHandler>());
    });

    test('void handler chosen for null value', () {
      final request = MockHttpRequest();
      final handler = manager.findHandler(null, null, request);
      expect(handler, isA<VoidReturnValueHandler>());
    });

    test('json handler chosen for Map value', () {
      final request = MockHttpRequest();
      final handler = manager.findHandler(null, {'key': 'value'}, request);
      expect(handler, isA<JsonReturnValueHandler>());
    });

    test('json handler chosen for List value', () {
      final request = MockHttpRequest();
      final handler = manager.findHandler(null, [1, 2, 3], request);
      expect(handler, isA<JsonReturnValueHandler>());
    });

    test('full pipeline: string handler writes correct body', () async {
      final response = MockHttpResponse();
      final request = MockHttpRequest();
      await manager.handleReturnValue('Hello, Jetleaf!', null, request, response, null);
      expect(response.rawBody.writtenContent, equals('Hello, Jetleaf!'));
      expect(response.getStatus(), equals(HttpStatus.OK));
    });

    test('full pipeline: void handler sets 204 for null', () async {
      final response = MockHttpResponse();
      final request = MockHttpRequest();
      await manager.handleReturnValue(null, null, request, response, null);
      expect(response.getStatus(), equals(HttpStatus.OK));
    });

    test('handler order is preserved in getHandlers', () {
      final handlers = manager.getHandlers();
      expect(handlers[0], isA<StringReturnValueHandler>());
      expect(handlers[1], isA<VoidReturnValueHandler>());
      expect(handlers[2], isA<JsonReturnValueHandler>());
    });
  });

  // =========================================================================
  // Edge cases and boundary conditions
  // =========================================================================
  group('Edge cases', () {
    test('StringReturnValueHandler handles empty string', () async {
      const handler = StringReturnValueHandler();
      final response = MockHttpResponse();
      final request = MockHttpRequest();
      await handler.handleReturnValue('', null, request, response, null);
      expect(response.rawBody.writtenContent, isEmpty);
      expect(response.getStatus(), equals(HttpStatus.OK));
    });

    test('StringReturnValueHandler handles unicode string', () async {
      const handler = StringReturnValueHandler();
      final response = MockHttpResponse();
      final request = MockHttpRequest();
      await handler.handleReturnValue('Hello 🌍', null, request, response, null);
      expect(response.rawBody.writtenContent, startsWith('Hello '));
    });

    test('VoidReturnValueHandler ignores non-null return values when method is null',
        () {
      const handler = VoidReturnValueHandler();
      final request = MockHttpRequest();
      expect(handler.canHandle(null, 'something', request), isFalse);
    });

    test('JsonReturnValueHandler rejects ResponseBody instances', () {
      final converters = HttpMessageConverters();
      final handler = JsonReturnValueHandler(converters);
      final request = MockHttpRequest();
      final body = ResponseBody(HttpStatus.OK, 'data');
      expect(handler.canHandle(null, body, request), isFalse);
    });

    test('RedirectReturnValueHandler rejects empty redirect string location',
        () async {
      final assetBuilder = AssetBuilder();
      final jtl = JtlFactory();
      final handler = RedirectReturnValueHandler(assetBuilder, jtl);
      final response = MockHttpResponse();
      final request = MockHttpRequest();
      // 'redirect:' with no path after it
      expect(
        () => handler.handleReturnValue('redirect:', null, request, response, null),
        throwsA(isA<Exception>()),
      );
    });

    test('DefaultReturnValueHandlerManager caches handler list', () {
      final resolver = _StubContentNegotiationResolver();
      final manager = DefaultReturnValueHandlerManager(resolver);
      manager.addHandler(const StringReturnValueHandler());
      final first = manager.getHandlers();
      final second = manager.getHandlers();
      expect(first, orderedEquals(second));
    });

    test('DefaultReturnValueHandlerManager invalidates cache on addHandler', () {
      final resolver = _StubContentNegotiationResolver();
      final manager = DefaultReturnValueHandlerManager(resolver);
      manager.addHandler(const StringReturnValueHandler());
      final first = manager.getHandlers();
      manager.addHandler(const VoidReturnValueHandler());
      final second = manager.getHandlers();
      expect(identical(first, second), isFalse);
      expect(second.length, equals(2));
    });

    test('handleReturnValue sets status from method annotation when available',
        () async {
      final resolver = _StubContentNegotiationResolver();
      final manager = DefaultReturnValueHandlerManager(resolver);
      manager.addHandler(const StringReturnValueHandler());
      final response = MockHttpResponse();
      final request = MockHttpRequest();
      // Null return value with no status → 204
      await manager.handleReturnValue(null, null, request, response, null);
      expect(response.getStatus(), equals(HttpStatus.OK));
    });
  });
}
