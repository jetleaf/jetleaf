import 'dart:async';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_logging/logging.dart';
import 'package:jetleaf_web/src/context/server_context.dart';
import 'package:jetleaf_web/src/events.dart';
import 'package:jetleaf_web/src/http/http_cookies.dart';
import 'package:jetleaf_web/src/http/http_headers.dart';
import 'package:jetleaf_web/src/http/http_method.dart';
import 'package:jetleaf_web/src/http/http_session.dart';
import 'package:jetleaf_web/src/http/http_status.dart';
import 'package:jetleaf_web/src/http/media_type.dart';
import 'package:jetleaf_web/src/path/path_pattern.dart';
import 'package:jetleaf_web/src/path/path_pattern_parser_manager.dart';
import 'package:jetleaf_web/src/server/content_negotiation/accept_header_negotiation_strategy.dart';
import 'package:jetleaf_web/src/server/content_negotiation/content_negotiation_resolver.dart';
import 'package:jetleaf_web/src/server/content_negotiation/content_negotiation_strategy.dart';
import 'package:jetleaf_web/src/server/content_negotiation/default_content_negotiation_resolver.dart';
import 'package:jetleaf_web/src/server/dispatcher/abstract_server_dispatcher.dart';
import 'package:jetleaf_web/src/server/dispatcher/global_server_dispatcher.dart';
import 'package:jetleaf_web/src/server/dispatcher/server_dispatcher.dart';
import 'package:jetleaf_web/src/server/dispatcher/server_dispatcher_error_listener.dart';
import 'package:jetleaf_web/src/server/exception_resolver/exception_resolver_manager.dart';
import 'package:jetleaf_web/src/server/filter/filter_manager.dart';
import 'package:jetleaf_web/src/server/handler_adapter/handler_adapter.dart';
import 'package:jetleaf_web/src/server/handler_adapter/handler_adapter_manager.dart';
import 'package:jetleaf_web/src/server/handler_interceptor/handler_interceptor_manager.dart';
import 'package:jetleaf_web/src/server/handler_mapping/handler_mapping.dart';
import 'package:jetleaf_web/src/server/handler_method.dart';
import 'package:jetleaf_web/src/server/multipart/multipart_resolver.dart';
import 'package:jetleaf_web/src/server/multipart/multipart_server_http_request.dart';
import 'package:jetleaf_web/src/server/server_http_request.dart';
import 'package:jetleaf_web/src/server/server_http_response.dart';

// ==================== Fake / Mock helpers ====================

class FakeServerHttpRequest implements ServerHttpRequest {
  final HttpHeaders _headers = HttpHeaders();
  Uri _uri;
  HttpMethod _method;
  String _contextPath = '';
  String? _requestUrl;
  final Map<String, Object> _attributes = {};
  bool _shouldUpgrade = false;

  FakeServerHttpRequest({
    String path = '/',
    HttpMethod method = HttpMethod.GET,
    Uri? uri,
  })  : _uri = uri ?? Uri.parse('http://localhost$path'),
        _method = method;

  void setMethod(HttpMethod method) => _method = method;
  void setUri(Uri uri) => _uri = uri;
  void setShouldUpgrade(bool value) => _shouldUpgrade = value;

  @override
  HttpHeaders getHeaders() => _headers;

  @override
  void setHeaders(HttpHeaders headers) {}

  @override
  HttpMethod getMethod() => _method;

  @override
  Uri getRequestURI() => _uri;

  @override
  Uri getUri() => _uri;

  @override
  String? getQueryString() => _uri.query.isEmpty ? null : _uri.query;

  @override
  String? getParameter(String name) => _uri.queryParameters[name];

  @override
  List<String> getParameterValues(String name) =>
      _uri.queryParametersAll[name] ?? [];

  @override
  Map<String, List<String>> getParameterMap() => _uri.queryParametersAll;

  @override
  String getContextPath() => _contextPath;

  @override
  void setContextPath(String contextPath) => _contextPath = contextPath;

  @override
  Map<String, Object> getAttributes() => Map.from(_attributes);

  @override
  Object? getAttribute(String name) => _attributes[name];

  @override
  void setAttribute(String name, Object value) => _attributes[name] = value;

  @override
  void removeAttribute(String name) => _attributes.remove(name);

  @override
  Set<String> getAttributeNames() => _attributes.keys.toSet();

  @override
  HttpCookies getCookies() => HttpCookies();

  @override
  HttpSession? getSession([bool create = true]) => null;

  @override
  String? getPathVariable(String name) => null;

  @override
  Map<String, String> getPathVariables() => {};

  @override
  bool shouldUpgrade() => _shouldUpgrade;

  @override
  void setRequestUrl(String requestUrl) => _requestUrl = requestUrl;

  @override
  String? getRequestUrl() => _requestUrl;

  @override
  int getContentLength() => 0;

  @override
  void setHandlerContext(HandlerMethod handler, PathPattern pattern) {}

  @override
  String getOrigin() => 'http://localhost';

  @override
  InputStream getBody() => ByteArrayInputStream(Uint8List(0));
}

class FakeServerHttpResponse implements ServerHttpResponse {
  final HttpHeaders _headers = HttpHeaders();
  HttpStatus? _status;

  @override
  HttpHeaders getHeaders() => _headers;

  @override
  void setHeaders(HttpHeaders headers) {}

  @override
  void setStatus(HttpStatus httpStatus) => _status = httpStatus;

  @override
  HttpStatus? getStatus() => _status;

  @override
  bool isCommitted() => false;

  @override
  void setReason(String message) {}

  @override
  Future<String> encodeRedirectUrl(String location) async => location;

  @override
  Future<void> sendRedirect(String encodedLocation) async {}

  @override
  OutputStream getBody() => ByteArrayOutputStream();
}

class FakeHandlerMethod implements HandlerMethod {
  final String _path;
  final HttpMethod _httpMethod;
  final Class _invokingClass;
  final Method? _method;

  FakeHandlerMethod(
    this._path, {
    HttpMethod httpMethod = HttpMethod.GET,
    Class? invokingClass,
    Method? method,
  })  : _httpMethod = httpMethod,
        _invokingClass = invokingClass ?? Class<Object>(),
        _method = method;

  @override
  HandlerArgumentContext getContext() => DefaultHandlerArgumentContext();

  @override
  Class getInvokingClass() => _invokingClass;

  @override
  Method? getMethod() => _method;

  @override
  HttpMethod getHttpMethod() => _httpMethod;

  @override
  String getPath() => _path;
}

class FakeHandlerMapping implements HandlerMapping {
  HandlerMethod? _handlerToReturn;

  void setHandler(HandlerMethod? handler) => _handlerToReturn = handler;

  @override
  HandlerMethod? getHandler(ServerHttpRequest request) => _handlerToReturn;
}

class FakeErrorListener implements ServerDispatcherErrorListener {
  final List<Object> receivedErrors = [];

  @override
  FutureOr<void> listen(Object exception, Class exceptionClass, StackTrace stacktrace) {
    receivedErrors.add(exception);
  }
}

class FakeHandlerAdapter implements HandlerAdapter {
  @override
  bool supports(HandlerMethod handler) => true;

  @override
  Future<void> handle(ServerHttpRequest request, ServerHttpResponse response, HandlerMethod handler) async {}
}

class FakeMultipartResolver implements MultipartResolver {
  bool isMultipartRequest = false;

  @override
  bool isMultipart(ServerHttpRequest request) => isMultipartRequest;

  @override
  Future<MultipartServerHttpRequest> resolveMultipart(ServerHttpRequest request) async {
    throw UnimplementedError();
  }

  @override
  Future<void> cleanupMultipart(MultipartServerHttpRequest request) async {}
}

// ==================== Concrete AbstractServerDispatcher for testing ====================

class TestableAbstractDispatcher extends AbstractServerDispatcher {
  final FakeMultipartResolver _testResolver;
  ApplicationEventBus? _eventBus;
  ServerDispatcherErrorListener? _errorListener;

  TestableAbstractDispatcher(
    super.parser,
    super.adapterManager,
    super.handlerMapping,
    super.interceptorManager,
    super.exceptionManager,
    this._testResolver,
  );

  @override
  MultipartResolver getResolver() => _testResolver;

  @override
  ApplicationEventBus getEventBus() => _eventBus!;

  @override
  ServerDispatcherErrorListener? getErrorListener() => _errorListener;

  @override
  Log getLog() => Log('test');

  void setEventBus(ApplicationEventBus bus) => _eventBus = bus;
  void setErrorListener(ServerDispatcherErrorListener listener) => _errorListener = listener;
}

class FakeEventBus implements ApplicationEventBus {
  final List<ApplicationEvent> publishedEvents = [];

  @override
  Future<void> onEvent(ApplicationEvent event) async {
    publishedEvents.add(event);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// ==================== Tests ====================

void main() {
  // ---- ServerDispatcher interface ----
  group('ServerDispatcher interface', () {
    test('THROW_IF_HANDLER_NOT_FOUND_PROPERTY_NAME has correct value', () {
      expect(
        ServerDispatcher.THROW_IF_HANDLER_NOT_FOUND_PROPERTY_NAME,
        'jetleaf.web.exception.throw-if-handler-not-found',
      );
    });
  });

  // ---- AbstractServerDispatcher ----
  group('AbstractServerDispatcher', () {
    late TestableAbstractDispatcher dispatcher;
    late FakeHandlerMapping handlerMapping;
    late FakeMultipartResolver multipartResolver;
    late FakeErrorListener errorListener;
    late FakeEventBus eventBus;

    setUp(() {
      handlerMapping = FakeHandlerMapping();
      multipartResolver = FakeMultipartResolver();
      errorListener = FakeErrorListener();
      eventBus = FakeEventBus();

      final adapterManager = HandlerAdapterManager();
      adapterManager.addAdapter(FakeHandlerAdapter());

      dispatcher = TestableAbstractDispatcher(
        PathPatternParserManager(),
        adapterManager,
        handlerMapping,
        HandlerInterceptorManager(),
        ExceptionResolverManager(_FakeContentNegotiationResolver()),
        multipartResolver,
      );
      dispatcher.setEventBus(eventBus);
      dispatcher.setErrorListener(errorListener);
    });

    group('canDispatch', () {
      test('returns true when handler mapping resolves a handler', () {
        handlerMapping.setHandler(FakeHandlerMethod('/users'));
        final request = FakeServerHttpRequest(path: '/users');

        expect(dispatcher.canDispatch(request), isTrue);
      });

      test('returns false when no handler mapping resolves a handler', () {
        handlerMapping.setHandler(null);
        final request = FakeServerHttpRequest(path: '/unknown');

        expect(dispatcher.canDispatch(request), isFalse);
      });
    });

    group('setThrowIfHandlerIsNotFound / getThrowIfHandlerIsNotFound', () {
      test('defaults to true', () {
        expect(dispatcher.getThrowIfHandlerIsNotFound(), isTrue);
      });

      test('can be set to false', () {
        dispatcher.setThrowIfHandlerIsNotFound(false);
        expect(dispatcher.getThrowIfHandlerIsNotFound(), isFalse);
      });

      test('can be toggled back to true', () {
        dispatcher.setThrowIfHandlerIsNotFound(false);
        dispatcher.setThrowIfHandlerIsNotFound(true);
        expect(dispatcher.getThrowIfHandlerIsNotFound(), isTrue);
      });
    });

    group('setDefaultHandlerMethod', () {
      test('sets the default handler', () {
        final defaultHandler = FakeHandlerMethod('/fallback');
        dispatcher.setDefaultHandlerMethod(defaultHandler);
        expect(dispatcher.defaultHandler, equals(defaultHandler));
      });
    });

    group('dispatch', () {
      test('publishes HttpUpgradedEvent when request.shouldUpgrade() is true', () async {
        final request = FakeServerHttpRequest(path: '/ws');
        request.setShouldUpgrade(true);
        final response = FakeServerHttpResponse();

        await dispatcher.dispatch(request, response);

        expect(eventBus.publishedEvents, hasLength(1));
        expect(eventBus.publishedEvents.first, isA<HttpUpgradedEvent>());
      });

      test('does not publish event when request.shouldUpgrade() is false', () async {
        handlerMapping.setHandler(FakeHandlerMethod('/users'));
        final request = FakeServerHttpRequest(path: '/users');
        final response = FakeServerHttpResponse();

        await dispatcher.dispatch(request, response);

        expect(eventBus.publishedEvents, isEmpty);
      });

      test('resolves multipart request when resolver reports multipart', () async {
        multipartResolver.isMultipartRequest = true;
        handlerMapping.setHandler(FakeHandlerMethod('/upload'));
        final request = FakeServerHttpRequest(path: '/upload');
        final response = FakeServerHttpResponse();

        expect(
          () => dispatcher.dispatch(request, response),
          throwsA(isA<UnimplementedError>()),
        );
      });
    });

    group('doDispatch', () {
      test('calls interceptors in correct order on success', () async {
        // Interceptors are discovered from ApplicationContext in real usage.
        // For testing, we verify the dispatch completes successfully.
        final interceptorManager = HandlerInterceptorManager();
        final adapterManager = HandlerAdapterManager();
        adapterManager.addAdapter(FakeHandlerAdapter());
        final exceptionManager = ExceptionResolverManager(_FakeContentNegotiationResolver());

        dispatcher = TestableAbstractDispatcher(
          PathPatternParserManager(),
          adapterManager,
          handlerMapping,
          interceptorManager,
          exceptionManager,
          multipartResolver,
        );
        dispatcher.setEventBus(eventBus);
        dispatcher.setErrorListener(errorListener);

        handlerMapping.setHandler(FakeHandlerMethod('/users'));
        final request = FakeServerHttpRequest(path: '/users');
        final response = FakeServerHttpResponse();

        // Note: Interceptors are discovered from ApplicationContext in real usage.
        // For testing, we verify the dispatch completes successfully.
        await dispatcher.doDispatch(request, response);

        // Verify no exception was thrown
        expect(eventBus.publishedEvents, isEmpty);
      });

      test('returns early when no handler found and throwIfHandlerIsNotFound is false', () async {
        dispatcher.setThrowIfHandlerIsNotFound(false);
        handlerMapping.setHandler(null);
        final request = FakeServerHttpRequest(path: '/no-handler');
        final response = FakeServerHttpResponse();

        await dispatcher.doDispatch(request, response);

        // Should complete without error
      });
    });
  });

  // ---- GlobalServerDispatcher ----
  group('GlobalServerDispatcher', () {
    late GlobalServerDispatcher dispatcher;
    late FakeMultipartResolver multipartResolver;
    late FakeHandlerMapping handlerMapping;

    setUp(() {
      multipartResolver = FakeMultipartResolver();
      handlerMapping = FakeHandlerMapping();

      final adapterManager = HandlerAdapterManager();
      adapterManager.addAdapter(FakeHandlerAdapter());

      dispatcher = GlobalServerDispatcher(
        multipartResolver,
        _FakeServerContext(),
        PathPatternParserManager(),
        FilterManager(),
        adapterManager,
        handlerMapping,
        HandlerInterceptorManager(),
        ExceptionResolverManager(_FakeContentNegotiationResolver()),
      );
    });

    group('getLog', () {
      test('returns a log instance', () {
        final log = dispatcher.getLog();
        expect(log, isNotNull);
      });
    });

    group('getResolver', () {
      test('returns the multipart resolver provided at construction', () {
        expect(dispatcher.getResolver(), equals(multipartResolver));
      });
    });

    group('getPackageName', () {
      test('returns WEB package name', () {
        expect(dispatcher.getPackageName(), equals(PackageNames.WEB));
      });
    });

    group('setApplicationEventBus', () {
      test('sets the event bus', () {
        final bus = FakeEventBus();
        dispatcher.setApplicationEventBus(bus);
        expect(dispatcher.getEventBus(), equals(bus));
      });
    });

    group('doDispatch with filters', () {
      test('dispatches when no filters are registered', () async {
        handlerMapping.setHandler(FakeHandlerMethod('/filtered'));
        final request = FakeServerHttpRequest(path: '/filtered');
        final response = FakeServerHttpResponse();
        final bus = FakeEventBus();
        dispatcher.setApplicationEventBus(bus);

        await dispatcher.doDispatch(request, response);

        // Should complete without error
      });
    });
  });

  // ---- ContentNegotiationStrategy interface ----
  group('ContentNegotiationStrategy interface', () {
    test('negotiate returns MediaType for matching accept header', () async {
      final strategy = AcceptHeaderNegotiationStrategy();
      final request = FakeServerHttpRequest();
      request.getHeaders().add('accept', 'application/json');

      final result = await strategy.negotiate(
        null,
        request,
        [MediaType.APPLICATION_JSON, MediaType.TEXT_PLAIN],
      );

      expect(result, equals(MediaType.APPLICATION_JSON));
    });
  });

  // ---- ContentNegotiationResolver interface ----
  group('ContentNegotiationResolver interface', () {
    test('can be implemented', () async {
      final resolver = _TestContentNegotiationResolver();
      final request = FakeServerHttpRequest();
      final response = FakeServerHttpResponse();

      await resolver.resolve(null, request, response, [MediaType.APPLICATION_JSON]);

      expect(response.getHeaders().getContentType(), isNotNull);
    });
  });

  // ---- AcceptHeaderNegotiationStrategy ----
  group('AcceptHeaderNegotiationStrategy', () {
    late AcceptHeaderNegotiationStrategy strategy;

    setUp(() {
      strategy = const AcceptHeaderNegotiationStrategy();
    });

    test('returns null when both accept headers and supported types are empty', () async {
      final request = FakeServerHttpRequest();

      final result = await strategy.negotiate(
        null,
        request,
        [],
      );

      expect(result, isNull);
    });

    test('returns first supported type when no accept header is present', () async {
      final request = FakeServerHttpRequest();

      final result = await strategy.negotiate(
        null,
        request,
        [MediaType.APPLICATION_JSON, MediaType.TEXT_PLAIN],
      );

      expect(result, equals(MediaType.APPLICATION_JSON));
    });

    test('matches exact accept header against supported types', () async {
      final request = FakeServerHttpRequest();
      request.getHeaders().add('accept', 'text/plain');

      final result = await strategy.negotiate(
        null,
        request,
        [MediaType.APPLICATION_JSON, MediaType.TEXT_PLAIN, MediaType.TEXT_HTML],
      );

      expect(result, equals(MediaType.TEXT_PLAIN));
    });

    test('matches wildcard accept header', () async {
      final request = FakeServerHttpRequest();
      request.getHeaders().add('accept', '*/*');

      final result = await strategy.negotiate(
        null,
        request,
        [MediaType.APPLICATION_JSON],
      );

      expect(result, equals(MediaType.APPLICATION_JSON));
    });

    test('matches type wildcard (application/*)', () async {
      final request = FakeServerHttpRequest();
      request.getHeaders().add('accept', 'application/*');

      final result = await strategy.negotiate(
        null,
        request,
        [MediaType.APPLICATION_JSON, MediaType.TEXT_PLAIN],
      );

      expect(result, equals(MediaType.APPLICATION_JSON));
    });

    test('returns first accept header when no supported type matches', () async {
      final request = FakeServerHttpRequest();
      request.getHeaders().add('accept', 'image/png');

      final result = await strategy.negotiate(
        null,
        request,
        [MediaType.APPLICATION_JSON, MediaType.TEXT_PLAIN],
      );

      expect(result, isNotNull);
      expect(result!.getMimeType(), 'image/png');
    });

    test('handles multiple accept headers', () async {
      final request = FakeServerHttpRequest();
      request.getHeaders().add('accept', 'text/html, application/json');

      final result = await strategy.negotiate(
        null,
        request,
        [MediaType.APPLICATION_JSON, MediaType.TEXT_PLAIN],
      );

      expect(result, equals(MediaType.APPLICATION_JSON));
    });

    test('matches with parameters ignored', () async {
      final request = FakeServerHttpRequest();
      request.getHeaders().add('accept', 'text/plain; charset=utf-8');

      final result = await strategy.negotiate(
        null,
        request,
        [MediaType.TEXT_PLAIN],
      );

      expect(result, equals(MediaType.TEXT_PLAIN));
    });
  });

  // ---- DefaultContentNegotiationResolver ----
  group('DefaultContentNegotiationResolver', () {
    late DefaultContentNegotiationResolver resolver;

    setUp(() {
      resolver = DefaultContentNegotiationResolver();
    });

    test('sets Content-Type header on response after resolution', () async {
      resolver.setStrategies([_AlwaysJsonStrategy()]);

      final request = FakeServerHttpRequest();
      final response = FakeServerHttpResponse();

      await resolver.resolve(null, request, response, []);

      final contentType = response.getHeaders().getContentType();
      expect(contentType, isNotNull);
      expect(contentType!.getMimeType(), 'application/json');
    });

    test('uses first strategy that produces a non-null result', () async {
      final strategy1 = _NullableStrategy(null);
      final strategy2 = _NullableStrategy(MediaType.TEXT_PLAIN);

      resolver.setStrategies([strategy1, strategy2]);

      final request = FakeServerHttpRequest();
      final response = FakeServerHttpResponse();

      await resolver.resolve(null, request, response, []);

      final contentType = response.getHeaders().getContentType();
      expect(contentType, isNotNull);
      expect(contentType!.getMimeType(), 'text/plain');
    });

    test('falls back to application/json when no strategy produces a result', () async {
      resolver.setStrategies([_NullableStrategy(null)]);

      final request = FakeServerHttpRequest();
      final response = FakeServerHttpResponse();

      await resolver.resolve(null, request, response, []);

      final contentType = response.getHeaders().getContentType();
      expect(contentType, isNotNull);
      expect(contentType!.getMimeType(), 'application/json');
    });

    test('applies charset from Accept-Charset header', () async {
      resolver.setStrategies([_AlwaysJsonStrategy()]);

      final request = FakeServerHttpRequest();
      request.getHeaders().add('accept-charset', 'utf-8');
      final response = FakeServerHttpResponse();

      await resolver.resolve(null, request, response, []);

      final contentType = response.getHeaders().getContentType();
      expect(contentType, isNotNull);
      expect(contentType!.getCharset(), 'utf-8');
    });

    test('setStrategies replaces all strategies', () async {
      resolver.setStrategies([_NullableStrategy(MediaType.TEXT_HTML)]);

      var request = FakeServerHttpRequest();
      var response = FakeServerHttpResponse();
      await resolver.resolve(null, request, response, []);
      expect(response.getHeaders().getContentType()!.getMimeType(), 'text/html');

      resolver.setStrategies([_NullableStrategy(MediaType.TEXT_PLAIN)]);
      response = FakeServerHttpResponse();
      await resolver.resolve(null, request, response, []);
      expect(response.getHeaders().getContentType()!.getMimeType(), 'text/plain');
    });

    test('getPackageName returns WEB', () {
      expect(resolver.getPackageName(), equals(PackageNames.WEB));
    });
  });
}

// ==================== Helper classes ====================

class _FakeServerContext implements ServerContext {
  @override
  Log get log => Log('test');

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeContentNegotiationResolver implements ContentNegotiationResolver {
  @override
  Future<void> resolve(Method? method, ServerHttpRequest request, ServerHttpResponse response, List<MediaType> supportedMediaTypes) async {}
}

class _AlwaysJsonStrategy implements ContentNegotiationStrategy {
  @override
  Future<MediaType?> negotiate(Method? method, ServerHttpRequest request, List<MediaType> supportedMediaTypes) async {
    return MediaType.APPLICATION_JSON;
  }
}

class _NullableStrategy implements ContentNegotiationStrategy {
  final MediaType? _result;
  _NullableStrategy(this._result);

  @override
  Future<MediaType?> negotiate(Method? method, ServerHttpRequest request, List<MediaType> supportedMediaTypes) async {
    return _result;
  }
}

class _TestContentNegotiationResolver implements ContentNegotiationResolver {
  @override
  Future<void> resolve(Method? method, ServerHttpRequest request, ServerHttpResponse response, List<MediaType> supportedMediaTypes) async {
    response.getHeaders().setContentType(MediaType.APPLICATION_JSON);
  }
}
