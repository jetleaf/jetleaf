import 'dart:async';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_web/src/http/http_body.dart';
import 'package:jetleaf_web/src/http/http_headers.dart';
import 'package:jetleaf_web/src/http/http_method.dart';
import 'package:jetleaf_web/src/http/http_status.dart';
import 'package:jetleaf_web/src/http/media_type.dart';
import 'package:jetleaf_web/src/rest/client.dart';
import 'package:jetleaf_web/src/rest/executor.dart';
import 'package:jetleaf_web/src/rest/interceptor.dart';
import 'package:jetleaf_web/src/rest/request.dart';
import 'package:jetleaf_web/src/rest/request_spec.dart';
import 'package:jetleaf_web/src/rest/response.dart';
import 'package:jetleaf_web/src/uri_builder.dart';

// ---------------------------------------------------------------------------
// Mock / Stub implementations for abstract REST interfaces
// ---------------------------------------------------------------------------

class _StubHttpResponse implements RestHttpResponse {
  final HttpStatus _status;
  final HttpHeaders _headers;
  final List<int> _bodyBytes;

  _StubHttpResponse({
    HttpStatus? status,
    HttpHeaders? headers,
    List<int>? bodyBytes,
  })  : _status = status ?? HttpStatus.OK,
        _headers = headers ?? HttpHeaders(),
        _bodyBytes = bodyBytes ?? [];

  @override
  HttpStatus getStatus() => _status;

  @override
  HttpHeaders getHeaders() => _headers;

  @override
  void setHeaders(HttpHeaders headers) {}

  @override
  InputStream getBody() => ByteArrayInputStream(Uint8List.fromList(_bodyBytes));
}

class _StubHttpRequest implements RestHttpRequest {
  final HttpMethod _method;
  final Uri _uri;
  final HttpHeaders _headers;
  final _StubHttpResponse _response;
  bool _executed = false;

  _StubHttpRequest({
    required HttpMethod method,
    required Uri uri,
    HttpHeaders? headers,
    _StubHttpResponse? response,
  })  : _method = method,
        _uri = uri,
        _headers = headers ?? HttpHeaders(),
        _response =
            response ?? _StubHttpResponse(bodyBytes: [111, 107]); // "ok"

  @override
  HttpMethod getMethod() => _method;

  @override
  Uri getUri() => _uri;

  @override
  HttpHeaders getHeaders() => _headers;

  @override
  void setHeaders(HttpHeaders headers) {}

  @override
  OutputStream getBody() => ByteArrayOutputStream();

  @override
  Future<RestHttpResponse> close() async {
    _executed = true;
    return _response;
  }

  @override
  Future<RestHttpResponse> execute() async {
    _executed = true;
    return _response;
  }

  bool get wasExecuted => _executed;
}

class _StubExecutor implements RestExecutor {
  bool _closed = false;
  final List<Uri> createdUris = [];
  final _StubHttpResponse? _defaultResponse;

  _StubExecutor({_StubHttpResponse? defaultResponse})
      : _defaultResponse = defaultResponse;

  @override
  Future<void> close() async {
    _closed = true;
  }

  @override
  Future<RestHttpRequest> createRequest(Uri uri, HttpMethod method) async {
    createdUris.add(uri);
    return _StubHttpRequest(
      method: method,
      uri: uri,
      response: _defaultResponse,
    );
  }

  bool get wasClosed => _closed;
}

class _StubInterceptor implements RestInterceptor {
  final List<String> beforeCalls = [];
  final List<String> aroundCalls = [];
  final List<String> afterCalls = [];

  @override
  Future<void> beforeExecution(RestHttpRequest request) async {
    beforeCalls.add(request.getMethod().toString());
  }

  @override
  Future<void> aroundExecution(RestHttpRequest request) async {
    aroundCalls.add(request.getMethod().toString());
  }

  @override
  Future<void> afterExecution(RestHttpResponse response) async {
    afterCalls.add(response.getStatus().getCode().toString());
  }
}

class _StubRequestSpec implements RequestSpec {
  String? _url;
  String? _uriTemplate;
  Map<String, dynamic>? _variables;
  Map<String, String>? _query;
  final HttpHeaders _headers = HttpHeaders();
  Object? _body;
  HttpHeaderBuilder? _headerBuilder;

  final _StubHttpResponse _response;

  _StubRequestSpec({_StubHttpResponse? response})
      : _response = response ?? _StubHttpResponse();

  @override
  RequestSpec url(String url) {
    _url = url;
    return this;
  }

  @override
  RequestSpec uri(String template,
      {Map<String, dynamic>? variables, Map<String, String>? query}) {
    _uriTemplate = template;
    _variables = variables;
    _query = query;
    return this;
  }

  @override
  RequestSpec header(String name, String value) {
    _headers.set(name, value);
    return this;
  }

  @override
  RequestSpec body(Object body) {
    _body = body;
    return this;
  }

  @override
  RequestSpec headers(HttpHeaders headers) {
    _headers.putAllFromHeaders(headers);
    return this;
  }

  @override
  RequestSpec headerBuilder(HttpHeaderBuilder builder) {
    _headerBuilder = builder;
    return this;
  }

  @override
  Future<T?> execute<T>(ResponseExtractor<T> extractor) async {
    return extractor(_response);
  }

  @override
  Future<Stream<T?>> stream<T>(ResponseExtractor<T> extractor) async {
    return Stream.fromFuture(Future.value(extractor(_response)));
  }

  @override
  Future<ResponseBody<T?>> exchange<T>(ResponseExtractor<T> extractor) async {
    final extracted = await extractor(_response);
    return ResponseBody<T?>(
      _response.getStatus(),
      extracted,
      _response.getHeaders(),
    );
  }

  String? get capturedUrl => _url;
  String? get capturedUriTemplate => _uriTemplate;
  Map<String, dynamic>? get capturedVariables => _variables;
  Map<String, String>? get capturedQuery => _query;
  Object? get capturedBody => _body;
  HttpHeaders get capturedHeaders => _headers;
  HttpHeaderBuilder? get capturedHeaderBuilder => _headerBuilder;
}

class _StubRestClient implements RestClient {
  UriBuilder? _uriBuilder;
  HttpHeaders? _defaultHeaders;
  final Map<String, String> _mappedHeaders = {};
  HttpHeaderBuilder? _headerBuilder;
  final List<RestInterceptor> _interceptors = [];
  final List<HttpMethod> createdMethods = [];

  UriBuilder? get uriBuilderInstance => _uriBuilder;
  HttpHeaders? get defaultHeadersInstance => _defaultHeaders;
  Map<String, String> get mappedHeaders => Map.unmodifiable(_mappedHeaders);
  HttpHeaderBuilder? get headerBuilderInstance => _headerBuilder;
  List<RestInterceptor> get interceptors => List.unmodifiable(_interceptors);

  @override
  RestClient uriBuilder(UriBuilder builder) {
    _uriBuilder = builder;
    return this;
  }

  @override
  RestClient withHeaders(HttpHeaders headers) {
    _defaultHeaders = headers;
    return this;
  }

  @override
  RestClient withMappedHeaders(Map<String, String> headers) {
    _mappedHeaders.addAll(headers);
    return this;
  }

  @override
  RestClient withHeaderBuilder(HttpHeaderBuilder builder) {
    _headerBuilder = builder;
    return this;
  }

  @override
  RestClient withInterceptors(List<RestInterceptor> interceptors) {
    _interceptors.addAll(interceptors);
    return this;
  }

  @override
  RequestSpec get() {
    createdMethods.add(HttpMethod.GET);
    return _StubRequestSpec();
  }

  @override
  RequestSpec post() {
    createdMethods.add(HttpMethod.POST);
    return _StubRequestSpec();
  }

  @override
  RequestSpec put() {
    createdMethods.add(HttpMethod.PUT);
    return _StubRequestSpec();
  }

  @override
  RequestSpec patch() {
    createdMethods.add(HttpMethod.PATCH);
    return _StubRequestSpec();
  }

  @override
  RequestSpec delete() {
    createdMethods.add(HttpMethod.DELETE);
    return _StubRequestSpec();
  }

  @override
  RequestSpec head() {
    createdMethods.add(HttpMethod.HEAD);
    return _StubRequestSpec();
  }

  @override
  RequestSpec options() {
    createdMethods.add(HttpMethod.OPTIONS);
    return _StubRequestSpec();
  }

  @override
  RequestSpec method(HttpMethod method) {
    createdMethods.add(method);
    return _StubRequestSpec();
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('RestClient', () {
    late _StubRestClient client;

    setUp(() {
      client = _StubRestClient();
    });

    group('HTTP method factories', () {
      test('get() creates request with GET method', () {
        client.get();
        expect(client.createdMethods, contains(HttpMethod.GET));
      });

      test('post() creates request with POST method', () {
        client.post();
        expect(client.createdMethods, contains(HttpMethod.POST));
      });

      test('put() creates request with PUT method', () {
        client.put();
        expect(client.createdMethods, contains(HttpMethod.PUT));
      });

      test('patch() creates request with PATCH method', () {
        client.patch();
        expect(client.createdMethods, contains(HttpMethod.PATCH));
      });

      test('delete() creates request with DELETE method', () {
        client.delete();
        expect(client.createdMethods, contains(HttpMethod.DELETE));
      });

      test('head() creates request with HEAD method', () {
        client.head();
        expect(client.createdMethods, contains(HttpMethod.HEAD));
      });

      test('options() creates request with OPTIONS method', () {
        client.options();
        expect(client.createdMethods, contains(HttpMethod.OPTIONS));
      });

      test('method() creates request with custom HTTP method', () {
        final custom = HttpMethod.FROM('PROPFIND');
        client.method(custom);
        expect(client.createdMethods, contains(custom));
      });

      test('method() creates request with custom string method', () {
        client.method(HttpMethod.FROM('PURGE'));
        expect(client.createdMethods.last.toString(), 'PURGE');
      });
    });

    group('configuration', () {
      test('uriBuilder() stores the builder', () {
        const builder = SimpleUriBuilder();
        client.uriBuilder(builder);
        expect(client.uriBuilderInstance, same(builder));
      });

      test('withHeaders() stores default headers', () {
        final headers = HttpHeaders()..set('X-Api-Key', 'abc123');
        client.withHeaders(headers);
        expect(client.defaultHeadersInstance, same(headers));
      });

      test('withMappedHeaders() stores mapped headers', () {
        client.withMappedHeaders({
          'Accept': 'application/json',
          'X-Custom': 'value',
        });
        expect(client.mappedHeaders['Accept'], 'application/json');
        expect(client.mappedHeaders['X-Custom'], 'value');
      });

      test('withHeaderBuilder() stores the builder', () {
        final builder = DefaultHttpHeaderBuilder();
        client.withHeaderBuilder(builder);
        expect(client.headerBuilderInstance, same(builder));
      });

      test('withInterceptors() stores interceptors', () {
        final interceptor1 = _StubInterceptor();
        final interceptor2 = _StubInterceptor();
        client.withInterceptors([interceptor1, interceptor2]);
        expect(client.interceptors, hasLength(2));
        expect(client.interceptors, contains(interceptor1));
        expect(client.interceptors, contains(interceptor2));
      });
    });

    group('chaining', () {
      test('all configuration methods return the same client instance', () {
        const builder = SimpleUriBuilder();
        final headers = HttpHeaders();
        final interceptor = _StubInterceptor();
        final headerBuilder = DefaultHttpHeaderBuilder();

        final result = client
            .uriBuilder(builder)
            .withHeaders(headers)
            .withMappedHeaders({'A': '1'})
            .withHeaderBuilder(headerBuilder)
            .withInterceptors([interceptor]);

        expect(result, same(client));
      });

      test('fluent configuration builds correct state', () {
        const builder = SimpleUriBuilder();
        final interceptor = _StubInterceptor();

        client
            .uriBuilder(builder)
            .withMappedHeaders({'Accept': 'text/plain'})
            .withInterceptors([interceptor]);

        expect(client.uriBuilderInstance, same(builder));
        expect(client.mappedHeaders['Accept'], 'text/plain');
        expect(client.interceptors, hasLength(1));
      });
    });
  });

  group('RestExecutor', () {
    late _StubExecutor executor;

    setUp(() {
      executor = _StubExecutor();
    });

    test('createRequest records the URI', () async {
      final uri = Uri.parse('https://api.example.com/users');
      await executor.createRequest(uri, HttpMethod.GET);

      expect(executor.createdUris, hasLength(1));
      expect(executor.createdUris.first, uri);
    });

    test('createRequest returns a request with correct method', () async {
      final uri = Uri.parse('https://api.example.com/data');
      final request = await executor.createRequest(uri, HttpMethod.POST);

      expect(request.getMethod(), HttpMethod.POST);
    });

    test('createRequest returns a request with correct URI', () async {
      final uri = Uri.parse('https://api.example.com/items/42');
      final request = await executor.createRequest(uri, HttpMethod.PUT);

      expect(request.getUri(), uri);
    });

    test('createRequest with different HTTP methods', () async {
      final uri = Uri.parse('https://api.example.com/r');

      for (final method in HttpMethod.getMethods()) {
        executor.createdUris.clear();
        await executor.createRequest(uri, method);
        expect(executor.createdUris.first, uri);
      }
    });

    test('close() marks executor as closed', () async {
      expect(executor.wasClosed, isFalse);
      await executor.close();
      expect(executor.wasClosed, isTrue);
    });

    test('createRequest after close still works', () async {
      await executor.close();
      final uri = Uri.parse('https://api.example.com/r');
      final request = await executor.createRequest(uri, HttpMethod.GET);
      expect(request.getMethod(), HttpMethod.GET);
    });

    test('multiple createRequest calls track all URIs', () async {
      final uri1 = Uri.parse('https://api.example.com/a');
      final uri2 = Uri.parse('https://api.example.com/b');
      final uri3 = Uri.parse('https://api.example.com/c');

      await executor.createRequest(uri1, HttpMethod.GET);
      await executor.createRequest(uri2, HttpMethod.POST);
      await executor.createRequest(uri3, HttpMethod.DELETE);

      expect(executor.createdUris, [uri1, uri2, uri3]);
    });
  });

  group('RestInterceptor', () {
    late _StubInterceptor interceptor;

    setUp(() {
      interceptor = _StubInterceptor();
    });

    test('beforeExecution is called with correct method', () async {
      final request = _StubHttpRequest(
        method: HttpMethod.GET,
        uri: Uri.parse('https://example.com'),
      );

      await interceptor.beforeExecution(request);

      expect(interceptor.beforeCalls, ['GET']);
    });

    test('beforeExecution handles POST', () async {
      final request = _StubHttpRequest(
        method: HttpMethod.POST,
        uri: Uri.parse('https://example.com'),
      );

      await interceptor.beforeExecution(request);

      expect(interceptor.beforeCalls, ['POST']);
    });

    test('aroundExecution is called with correct method', () async {
      final request = _StubHttpRequest(
        method: HttpMethod.PUT,
        uri: Uri.parse('https://example.com'),
      );

      await interceptor.aroundExecution(request);

      expect(interceptor.aroundCalls, ['PUT']);
    });

    test('afterExecution is called with correct status code', () async {
      final response = _StubHttpResponse(status: HttpStatus.CREATED);

      await interceptor.afterExecution(response);

      expect(interceptor.afterCalls, ['201']);
    });

    test('afterExecution handles 404', () async {
      final response = _StubHttpResponse(status: HttpStatus.NOT_FOUND);

      await interceptor.afterExecution(response);

      expect(interceptor.afterCalls, ['404']);
    });

    test('interceptor lifecycle: before -> around -> after', () async {
      final request = _StubHttpRequest(
        method: HttpMethod.DELETE,
        uri: Uri.parse('https://example.com/items'),
        response: _StubHttpResponse(status: HttpStatus.NO_CONTENT),
      );

      await interceptor.beforeExecution(request);
      await interceptor.aroundExecution(request);
      final response = await request.execute();
      await interceptor.afterExecution(response);

      expect(interceptor.beforeCalls, ['DELETE']);
      expect(interceptor.aroundCalls, ['DELETE']);
      expect(interceptor.afterCalls, ['204']);
    });

    test('multiple interceptors execute independently', () async {
      final interceptor2 = _StubInterceptor();
      final request = _StubHttpRequest(
        method: HttpMethod.GET,
        uri: Uri.parse('https://example.com'),
      );

      await interceptor.beforeExecution(request);
      await interceptor2.beforeExecution(request);

      expect(interceptor.beforeCalls, ['GET']);
      expect(interceptor2.beforeCalls, ['GET']);
    });
  });

  group('RestHttpRequest', () {
    test('getMethod returns the configured method', () {
      final request = _StubHttpRequest(
        method: HttpMethod.POST,
        uri: Uri.parse('https://example.com/api'),
      );

      expect(request.getMethod(), HttpMethod.POST);
    });

    test('getUri returns the configured URI', () {
      final uri = Uri.parse('https://example.com/api/users');
      final request = _StubHttpRequest(
        method: HttpMethod.GET,
        uri: uri,
      );

      expect(request.getUri(), uri);
    });

    test('execute returns a response', () async {
      final request = _StubHttpRequest(
        method: HttpMethod.GET,
        uri: Uri.parse('https://example.com'),
      );

      final response = await request.execute();

      expect(response, isA<RestHttpResponse>());
      expect(response.getStatus(), HttpStatus.OK);
    });

    test('close returns a response', () async {
      final request = _StubHttpRequest(
        method: HttpMethod.GET,
        uri: Uri.parse('https://example.com'),
      );

      final response = await request.close();

      expect(response, isA<RestHttpResponse>());
    });

    test('execute marks request as executed', () async {
      final request = _StubHttpRequest(
        method: HttpMethod.GET,
        uri: Uri.parse('https://example.com'),
      );

      expect(request.wasExecuted, isFalse);
      await request.execute();
      expect(request.wasExecuted, isTrue);
    });

    test('close marks request as executed', () async {
      final request = _StubHttpRequest(
        method: HttpMethod.DELETE,
        uri: Uri.parse('https://example.com/items'),
      );

      expect(request.wasExecuted, isFalse);
      await request.close();
      expect(request.wasExecuted, isTrue);
    });

    test('getHeaders returns default headers', () {
      final request = _StubHttpRequest(
        method: HttpMethod.GET,
        uri: Uri.parse('https://example.com'),
      );

      expect(request.getHeaders(), isA<HttpHeaders>());
      expect(request.getHeaders().getIsEmpty(), isTrue);
    });

    test('request with all HTTP methods', () {
      for (final method in HttpMethod.getMethods()) {
        final request = _StubHttpRequest(
          method: method,
          uri: Uri.parse('https://example.com'),
        );
        expect(request.getMethod(), method);
      }
    });
  });

  group('RequestSpec', () {
    late _StubRequestSpec spec;

    setUp(() {
      spec = _StubRequestSpec();
    });

    group('url()', () {
      test('sets a full URL', () {
        spec.url('https://api.example.com/users');
        expect(spec.capturedUrl, 'https://api.example.com/users');
      });

      test('returns the same spec for chaining', () {
        final result = spec.url('https://example.com');
        expect(result, same(spec));
      });

      test('overwrites previous URL', () {
        spec.url('https://first.com');
        spec.url('https://second.com');
        expect(spec.capturedUrl, 'https://second.com');
      });
    });

    group('uri()', () {
      test('sets URI template', () {
        spec.uri('/users/{id}');
        expect(spec.capturedUriTemplate, '/users/{id}');
      });

      test('stores variables', () {
        spec.uri('/users/{id}', variables: {'id': 42});
        expect(spec.capturedVariables, {'id': 42});
      });

      test('stores query parameters', () {
        spec.uri('/search', query: {'q': 'dart', 'page': '1'});
        expect(spec.capturedQuery, {'q': 'dart', 'page': '1'});
      });

      test('returns the same spec for chaining', () {
        final result = spec.uri('/items');
        expect(result, same(spec));
      });
    });

    group('header()', () {
      test('adds a header', () {
        spec.header('Authorization', 'Bearer token123');
        expect(
            spec.capturedHeaders.getFirst('Authorization'), 'Bearer token123');
      });

      test('returns the same spec for chaining', () {
        final result = spec.header('Accept', 'application/json');
        expect(result, same(spec));
      });

      test('overwrites previous value for same header', () {
        spec.header('Accept', 'text/html');
        spec.header('Accept', 'application/json');
        expect(spec.capturedHeaders.getFirst('Accept'), 'application/json');
      });

      test('adds multiple different headers', () {
        spec
            .header('Authorization', 'Bearer abc')
            .header('Accept', 'application/json')
            .header('X-Custom', 'value');

        expect(spec.capturedHeaders.getFirst('Authorization'), 'Bearer abc');
        expect(spec.capturedHeaders.getFirst('Accept'), 'application/json');
        expect(spec.capturedHeaders.getFirst('X-Custom'), 'value');
      });
    });

    group('body()', () {
      test('sets a string body', () {
        spec.body('Hello, World!');
        expect(spec.capturedBody, 'Hello, World!');
      });

      test('sets a map body', () {
        final data = {'name': 'Alice', 'age': 30};
        spec.body(data);
        expect(spec.capturedBody, data);
      });

      test('returns the same spec for chaining', () {
        final result = spec.body('data');
        expect(result, same(spec));
      });

      test('overwrites previous body', () {
        spec.body('first');
        spec.body('second');
        expect(spec.capturedBody, 'second');
      });
    });

    group('headers()', () {
      test('adds all headers from HttpHeaders', () {
        final headers = HttpHeaders()
          ..set('Accept', 'application/json')
          ..set('X-Request-ID', 'abc123');
        spec.headers(headers);

        expect(spec.capturedHeaders.getFirst('Accept'), 'application/json');
        expect(spec.capturedHeaders.getFirst('X-Request-ID'), 'abc123');
      });

      test('returns the same spec for chaining', () {
        final result = spec.headers(HttpHeaders());
        expect(result, same(spec));
      });
    });

    group('headerBuilder()', () {
      test('stores the header builder', () {
        final builder = DefaultHttpHeaderBuilder();
        spec.headerBuilder(builder);
        expect(spec.capturedHeaderBuilder, same(builder));
      });

      test('returns the same spec for chaining', () {
        final result = spec.headerBuilder(DefaultHttpHeaderBuilder());
        expect(result, same(spec));
      });
    });

    group('fluent chaining', () {
      test('url -> header -> body chains correctly', () {
        final result = spec
            .url('https://api.example.com/users')
            .header('Content-Type', 'application/json')
            .body({'name': 'Bob'});

        expect(result, same(spec));
        expect(spec.capturedUrl, 'https://api.example.com/users');
        expect(spec.capturedHeaders.getFirst('Content-Type'),
            'application/json');
        expect(spec.capturedBody, {'name': 'Bob'});
      });

      test('uri -> headers -> execute works end-to-end', () async {
        final response = await _StubRequestSpec()
            .uri('/users/{id}',
                variables: {'id': 7}, query: {'fields': 'name'})
            .headers(HttpHeaders()..set('Accept', 'application/json'))
            .execute<String>((resp) async => 'extracted');

        expect(response, 'extracted');
      });
    });

    group('execute()', () {
      test('calls extractor with the response', () async {
        final stubResponse = _StubHttpResponse(
          status: HttpStatus.OK,
          bodyBytes: [104, 101, 108, 108, 111], // "hello"
        );
        final spec = _StubRequestSpec(response: stubResponse);

        final result = await spec.execute<String>((resp) async {
          final body = resp.getBody();
          final bytes = <int>[];
          int byte;
          while ((byte = await body.readByte()) != -1) {
            bytes.add(byte);
          }
          return String.fromCharCodes(bytes);
        });

        expect(result, 'hello');
      });

      test('extractor receives correct status', () async {
        final stubResponse = _StubHttpResponse(status: HttpStatus.NOT_FOUND);
        final spec = _StubRequestSpec(response: stubResponse);

        final result = await spec.execute<HttpStatus>(
            (resp) async => resp.getStatus());

        expect(result, HttpStatus.NOT_FOUND);
      });
    });

    group('stream()', () {
      test('returns a stream of extracted values', () async {
        final spec = _StubRequestSpec();
        final stream =
            await spec.stream<String>((resp) async => 'streamed-value');

        final values = await stream.toList();
        expect(values, ['streamed-value']);
      });
    });

    group('exchange()', () {
      test('returns a ResponseBody with extracted value', () async {
        final stubResponse = _StubHttpResponse(
          status: HttpStatus.OK,
          headers: HttpHeaders()..set('X-Trace', 'abc'),
        );
        final spec = _StubRequestSpec(response: stubResponse);

        final body = await spec.exchange<String>(
            (resp) async => 'exchange-data');

        expect(body.status, HttpStatus.OK);
        expect(body.getBody(), 'exchange-data');
        expect(body.getHeaders()?.getFirst('X-Trace'), 'abc');
      });

      test('preserves status from the response', () async {
        final spec = _StubRequestSpec(
          response: _StubHttpResponse(status: HttpStatus.ACCEPTED),
        );

        final body = await spec.exchange<String>((resp) async => 'accepted');

        expect(body.status, HttpStatus.ACCEPTED);
        expect(body.getBody(), 'accepted');
      });
    });
  });

  group('RestHttpResponse (via ResponseBody)', () {
    test('status field returns the configured status', () {
      final response = ResponseBody(HttpStatus.OK);
      expect(response.status, HttpStatus.OK);
    });

    test('getBody returns the body', () {
      final response = ResponseBody<String>(HttpStatus.OK, 'hello');
      expect(response.getBody(), 'hello');
    });

    test('getBody returns null when no body', () {
      final response = ResponseBody.statusCode<String>(204);
      expect(response.getBody(), isNull);
    });

    test('getHeaders returns the headers', () {
      final headers = HttpHeaders()..set('Content-Type', 'text/plain');
      final response = ResponseBody(HttpStatus.OK, 'body', headers);
      expect(response.getHeaders()?.getFirst('Content-Type'), 'text/plain');
    });

    test('getHeaders returns null when no headers', () {
      final response = ResponseBody(HttpStatus.OK);
      expect(response.getHeaders(), isNull);
    });

    group('factory methods', () {
      test('ok() creates a 200 response', () {
        final response = ResponseBody.ok<String>('success');
        expect(response.status, HttpStatus.OK);
        expect(response.getBody(), 'success');
      });

      test('ok() without body', () {
        final response = ResponseBody.ok<String>();
        expect(response.status, HttpStatus.OK);
        expect(response.getBody(), isNull);
      });

      test('notFound() creates a 404 response', () {
        final response = ResponseBody.notFound<String>();
        expect(response.status, HttpStatus.NOT_FOUND);
      });

      test('statusCode() creates response from int code', () {
        final response = ResponseBody.statusCode<String>(201, 'created');
        expect(response.status, HttpStatus.CREATED);
        expect(response.getBody(), 'created');
      });

      test('statusText() creates response from status name', () {
        final response = ResponseBody.statusText<String>('OK', 'data');
        expect(response.status, HttpStatus.OK);
        expect(response.getBody(), 'data');
      });

      test('of() creates response with provided status', () {
        final response =
            ResponseBody.of<String>(HttpStatus.ACCEPTED, 'pending');
        expect(response.status, HttpStatus.ACCEPTED);
        expect(response.getBody(), 'pending');
      });
    });

    group('status category checks', () {
      test('200 is successful', () {
        expect(HttpStatus.OK.is2xxSuccessful(), isTrue);
        expect(HttpStatus.OK.is4xxClientError(), isFalse);
        expect(HttpStatus.OK.is5xxServerError(), isFalse);
      });

      test('404 is client error', () {
        expect(HttpStatus.NOT_FOUND.is4xxClientError(), isTrue);
        expect(HttpStatus.NOT_FOUND.is2xxSuccessful(), isFalse);
      });

      test('500 is server error', () {
        expect(HttpStatus.INTERNAL_SERVER_ERROR.is5xxServerError(), isTrue);
        expect(
            HttpStatus.INTERNAL_SERVER_ERROR.is2xxSuccessful(), isFalse);
      });

      test('301 is redirection', () {
        expect(HttpStatus.MOVED_PERMANENTLY.is3xxRedirection(), isTrue);
      });

      test('100 is informational', () {
        expect(HttpStatus.CONTINUE.is1xxInformational(), isTrue);
      });

      test('600 is connection error', () {
        expect(
            HttpStatus.CONNECTION_NOT_REACHABLE.is6xxConnectionError(), isTrue);
      });
    });

    group('HttpStatus properties', () {
      test('getCode returns the numeric code', () {
        expect(HttpStatus.OK.getCode(), 200);
        expect(HttpStatus.NOT_FOUND.getCode(), 404);
        expect(HttpStatus.INTERNAL_SERVER_ERROR.getCode(), 500);
      });

      test('getName returns the status name', () {
        expect(HttpStatus.OK.getName(), 'OK');
        expect(HttpStatus.NOT_FOUND.getName(), 'NOT_FOUND');
      });

      test('getDescription returns the description', () {
        expect(HttpStatus.OK.getDescription(), isNotEmpty);
        expect(HttpStatus.NOT_FOUND.getDescription(), isNotEmpty);
      });

      test('fromCode returns predefined status', () {
        expect(HttpStatus.fromCode(200), HttpStatus.OK);
        expect(HttpStatus.fromCode(404), HttpStatus.NOT_FOUND);
        expect(HttpStatus.fromCode(500), HttpStatus.INTERNAL_SERVER_ERROR);
      });

      test('fromCode creates unknown status for undefined codes', () {
        final unknown = HttpStatus.fromCode(999);
        expect(unknown.getCode(), 999);
        expect(unknown.getName(), 'UNKNOWN_999');
      });

      test('fromJson creates status from map', () {
        final json = {
          'code': '201',
          'name': 'CREATED',
          'description': 'Resource created',
        };
        final status = HttpStatus.fromCode(200).fromJson(json);
        expect(status.getCode(), 201);
        expect(status.getName(), 'CREATED');
      });
    });

    test('equality is based on status, body, and headers', () {
      final a = ResponseBody<String>(HttpStatus.OK, 'hello');
      final b = ResponseBody<String>(HttpStatus.OK, 'hello');
      expect(a, equals(b));
    });

    test('inequality for different bodies', () {
      final a = ResponseBody<String>(HttpStatus.OK, 'hello');
      final b = ResponseBody<String>(HttpStatus.OK, 'world');
      expect(a, isNot(equals(b)));
    });

    test('inequality for different statuses', () {
      final a = ResponseBody<String>(HttpStatus.OK, 'hello');
      final b = ResponseBody<String>(HttpStatus.NOT_FOUND, 'hello');
      expect(a, isNot(equals(b)));
    });
  });

  group('HttpHeaders (used by REST)', () {
    test('set and get a header', () {
      final headers = HttpHeaders();
      headers.set('X-Api-Key', 'abc123');
      expect(headers.getFirst('X-Api-Key'), 'abc123');
    });

    test('case-insensitive header lookup', () {
      final headers = HttpHeaders();
      headers.set('Content-Type', 'application/json');
      expect(headers.getFirst('content-type'), 'application/json');
      expect(headers.getFirst('CONTENT-TYPE'), 'application/json');
    });

    test('add appends values', () {
      final headers = HttpHeaders();
      headers.set('Accept', 'text/html');
      headers.add('Accept', 'application/json');
      final values = headers.get('Accept');
      expect(values, contains('text/html'));
      expect(values, contains('application/json'));
    });

    test('remove deletes a header', () {
      final headers = HttpHeaders();
      headers.set('X-Remove', 'value');
      headers.remove('X-Remove');
      expect(headers.getFirst('X-Remove'), isNull);
    });

    test('containsHeader checks existence', () {
      final headers = HttpHeaders();
      headers.set('X-Exists', 'yes');
      expect(headers.containsHeader('X-Exists'), isTrue);
      expect(headers.containsHeader('X-No'), isFalse);
    });

    test('getIsEmpty checks emptiness', () {
      final headers = HttpHeaders();
      expect(headers.getIsEmpty(), isTrue);
      headers.set('A', '1');
      expect(headers.getIsEmpty(), isFalse);
    });

    test('clear removes all headers', () {
      final headers = HttpHeaders()
        ..set('A', '1')
        ..set('B', '2');
      headers.clear();
      expect(headers.getIsEmpty(), isTrue);
    });

    test('getSize returns count', () {
      final headers = HttpHeaders()
        ..set('A', '1')
        ..set('B', '2')
        ..set('C', '3');
      expect(headers.getSize(), 3);
    });

    test('fromMap creates headers from map', () {
      final headers = HttpHeaders.fromMap({
        'Accept': 'application/json',
        'Authorization': 'Bearer token',
      });
      expect(headers.getFirst('Accept'), 'application/json');
      expect(headers.getFirst('Authorization'), 'Bearer token');
    });

    test('setContentType sets Content-Type', () {
      final headers = HttpHeaders();
      headers.setContentType(MediaType.parse('application/json'));
      expect(headers.getContentType()?.toString(), 'application/json');
    });

    test('setContentLength sets Content-Length', () {
      final headers = HttpHeaders();
      headers.setContentLength(1024);
      expect(headers.getContentLength(), 1024);
    });

    test('setBearerAuth sets Authorization header', () {
      final headers = HttpHeaders();
      headers.setBearerAuth('mytoken');
      expect(headers.getFirst('Authorization'), 'Bearer mytoken');
    });
  });

  group('SimpleUriBuilder', () {
    const builder = SimpleUriBuilder();

    test('builds URI from template with no variables', () {
      final uri = builder.build('/users', null, null);
      expect(uri.toString(), '/users');
    });

    test('substitutes single variable', () {
      final uri = builder.build('/users/{id}', {'id': 42}, null);
      expect(uri.toString(), '/users/42');
    });

    test('substitutes multiple variables', () {
      final uri = builder.build('/users/{userId}/posts/{postId}',
          {'userId': 5, 'postId': 99}, null);
      expect(uri.toString(), '/users/5/posts/99');
    });

    test('adds query parameters', () {
      final uri =
          builder.build('/search', null, {'q': 'dart', 'page': '1'});
      expect(uri.queryParameters['q'], 'dart');
      expect(uri.queryParameters['page'], '1');
    });

    test('preserves existing query params and adds new ones', () {
      final uri = builder.build('/search?q=old', null, {'page': '2'});
      expect(uri.queryParameters['q'], 'old');
      expect(uri.queryParameters['page'], '2');
    });

    test('new query params override existing ones', () {
      final uri = builder.build('/search?q=old', null, {'q': 'new'});
      expect(uri.queryParameters['q'], 'new');
    });

    test('handles full URL templates', () {
      final uri = builder.build(
          'https://api.example.com/users/{id}', {'id': 7}, null);
      expect(uri.toString(), 'https://api.example.com/users/7');
    });

    test('handles variable with no existing query params', () {
      final uri =
          builder.build('/items/{id}', {'id': 12}, {'sort': 'asc'});
      expect(uri.toString(), '/items/12?sort=asc');
      expect(uri.queryParameters['sort'], 'asc');
    });

    test('no variables or query params', () {
      final uri = builder.build('/health', null, null);
      expect(uri.toString(), '/health');
    });
  });

  group('ResponseBody toString', () {
    test('includes status name and description', () {
      final body = ResponseBody<String>(HttpStatus.OK, 'hello');
      final str = body.toString();
      expect(str, contains('OK'));
      expect(str, contains('Standard response for successful HTTP requests'));
      expect(str, contains('hello'));
    });

    test('includes body in string', () {
      final body = ResponseBody<String>(HttpStatus.OK, 'data');
      expect(body.toString(), contains('data'));
    });

    test('handles null body', () {
      final body = ResponseBody<void>(HttpStatus.NO_CONTENT);
      final str = body.toString();
      expect(str, contains('NO_CONTENT'));
    });
  });

  group('HttpBody', () {
    test('stores body value', () {
      final entity = HttpBody<String>('hello');
      expect(entity.getBody(), 'hello');
    });

    test('stores null body', () {
      final entity = HttpBody<String>();
      expect(entity.getBody(), isNull);
    });

    test('stores headers', () {
      final headers = HttpHeaders()..set('X-Test', 'value');
      final entity = HttpBody<String>('body', headers);
      expect(entity.getHeaders()?.getFirst('X-Test'), 'value');
    });

    test('null headers when not provided', () {
      final entity = HttpBody<String>('body');
      expect(entity.getHeaders(), isNull);
    });

    test('equality based on body and headers', () {
      final a = HttpBody<String>('hello');
      final b = HttpBody<String>('hello');
      expect(a, equals(b));
    });

    test('inequality for different bodies', () {
      final a = HttpBody<String>('hello');
      final b = HttpBody<String>('world');
      expect(a, isNot(equals(b)));
    });
  });

  group('HttpMethod through REST interface', () {
    test('all standard methods have correct toString', () {
      expect(HttpMethod.GET.toString(), 'GET');
      expect(HttpMethod.POST.toString(), 'POST');
      expect(HttpMethod.PUT.toString(), 'PUT');
      expect(HttpMethod.DELETE.toString(), 'DELETE');
      expect(HttpMethod.PATCH.toString(), 'PATCH');
      expect(HttpMethod.HEAD.toString(), 'HEAD');
      expect(HttpMethod.OPTIONS.toString(), 'OPTIONS');
      expect(HttpMethod.TRACE.toString(), 'TRACE');
      expect(HttpMethod.CONNECT.toString(), 'CONNECT');
    });

    test('custom method via FROM', () {
      final custom = HttpMethod.FROM('PROPFIND');
      expect(custom.toString(), 'PROPFIND');
    });

    test('method equality', () {
      expect(HttpMethod.FROM('GET'), equals(HttpMethod.GET));
      expect(HttpMethod.FROM('get'), equals(HttpMethod.GET));
    });
  });

  group('Integration: RequestSpec with ResponseBody', () {
    test('exchange() wraps extracted value in ResponseBody', () async {
      final response = _StubHttpResponse(
        status: HttpStatus.OK,
        headers: HttpHeaders()..set('X-Trace-Id', 'trace-123'),
      );
      final spec = _StubRequestSpec(response: response);

      final result = await spec.exchange<Map<String, dynamic>>((resp) async {
        return {'status': 'ok'};
      });

      expect(result.status, HttpStatus.OK);
      expect(result.getBody(), {'status': 'ok'});
      expect(result.getHeaders()?.getFirst('X-Trace-Id'), 'trace-123');
    });

    test('execute() extracts data from response body', () async {
      final bodyText = '{"users": []}';
      final response = _StubHttpResponse(
        status: HttpStatus.OK,
        bodyBytes: bodyText.codeUnits,
      );
      final spec = _StubRequestSpec(response: response);

      final result = await spec.execute<String>((resp) async {
        final stream = resp.getBody();
        final bytes = <int>[];
        int byte;
        while ((byte = await stream.readByte()) != -1) {
          bytes.add(byte);
        }
        return String.fromCharCodes(bytes);
      });

      expect(result, bodyText);
    });
  });
}
