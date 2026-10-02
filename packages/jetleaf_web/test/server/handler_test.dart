// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & Jetleaf Contributors. All rights reserved.
//
// This source file is part of the Jetleaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the Jetleaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';
import 'package:jetleaf_core/context.dart';

import 'package:jetleaf_web/src/http/http_headers.dart';
import 'package:jetleaf_web/src/http/http_method.dart';
import 'package:jetleaf_web/src/http/http_status.dart';
import 'package:jetleaf_web/src/http/http_cookies.dart';
import 'package:jetleaf_web/src/http/http_session.dart';
import 'package:jetleaf_web/src/http/media_type.dart';
import 'package:jetleaf_web/src/path/path_pattern.dart';
import 'package:jetleaf_web/src/path/path_pattern_parser_manager.dart';
import 'package:jetleaf_web/src/path/path_segment.dart';
import 'package:jetleaf_web/src/server/handler_adapter/handler_adapter.dart';
import 'package:jetleaf_web/src/server/handler_adapter/handler_adapter_manager.dart';
import 'package:jetleaf_web/src/server/handler_adapter/annotated_handler_adapter.dart';
import 'package:jetleaf_web/src/server/handler_mapping/handler_mapping.dart';
import 'package:jetleaf_web/src/server/handler_mapping/route_registry_handler_mapping.dart';
import 'package:jetleaf_web/src/server/handler_mapping/abstract_route_dsl_handler_mapping.dart';
import 'package:jetleaf_web/src/server/handler_mapping/abstract_annotated_handler_mapping.dart';
import 'package:jetleaf_web/src/server/handler_mapping/abstract_framework_handler_mapping.dart';
import 'package:jetleaf_web/src/server/handler_method.dart';
import 'package:jetleaf_web/src/server/server_http_request.dart';
import 'package:jetleaf_web/src/server/server_http_response.dart';
import 'package:jetleaf_web/src/server/method_argument_resolver/method_argument_resolver.dart';
import 'package:jetleaf_web/src/server/return_value_handler/return_value_handler.dart';
import 'package:jetleaf_web/src/server/routing/router_interface.dart';
import 'package:jetleaf_web/src/server/routing/router_spec.dart';

// ---------------------------------------------------------------------------
// Test Doubles / Fakes
// ---------------------------------------------------------------------------

/// A fake [ServerHttpRequest] for unit testing handler logic without
/// requiring a real HTTP server.
class FakeServerHttpRequest implements ServerHttpRequest {
  HttpMethod _method;
  Uri _uri;
  final Map<String, Object> _attributes = {};
  final Map<String, List<String>> _headers = {};
  final HttpHeaders _httpHeaders = HttpHeaders();
  String _contextPath = '';
  String? _requestUrl;

  FakeServerHttpRequest({
    HttpMethod method = HttpMethod.GET,
    Uri? uri,
    String contextPath = '',
  })  : _method = method,
        _uri = uri ?? Uri.parse('/test'),
        _contextPath = contextPath;

  void setMethod(HttpMethod method) => _method = method;
  void setUri(Uri uri) => _uri = uri;

  @override
  HttpMethod getMethod() => _method;

  @override
  Uri getRequestURI() => _uri;

  @override
  Uri getUri() => _uri;

  @override
  String? getQueryString() => _uri.query.isEmpty ? null : _uri.query;

  @override
  String getContextPath() => _contextPath;

  @override
  void setContextPath(String contextPath) => _contextPath = contextPath;

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
  String? getParameter(String name) => null;

  @override
  List<String> getParameterValues(String name) => [];

  @override
  Map<String, List<String>> getParameterMap() => {};

  @override
  HttpCookies getCookies() => HttpCookies();

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
  String getOrigin() => '';

  @override
  HttpHeaders getHeaders() {
    return _httpHeaders;
  }

  @override
  void setHeaders(HttpHeaders headers) {}

  @override
  InputStream getBody() => ByteArrayInputStream(Uint8List(0));

  void addHeader(String name, String value) {
    _headers.putIfAbsent(name, () => []).add(value);
    _httpHeaders.add(name, value);
  }
}

/// A fake [ServerHttpResponse] for unit testing handler logic.
class FakeServerHttpResponse implements ServerHttpResponse {
  HttpStatus? _status;
  final bool _committed = false;
  final HttpHeaders _headers = HttpHeaders();
  String? _reason;

  @override
  void setStatus(HttpStatus httpStatus) => _status = httpStatus;

  @override
  HttpStatus? getStatus() => _status;

  @override
  bool isCommitted() => _committed;

  @override
  void setReason(String message) => _reason = message;

  @override
  Future<String> encodeRedirectUrl(String location) async => location;

  @override
  Future<void> sendRedirect(String encodedLocation) async {}

  @override
  HttpHeaders getHeaders() => _headers;

  @override
  void setHeaders(HttpHeaders headers) {}

  @override
  OutputStream getBody() => ByteArrayOutputStream();

  String? getReason() => _reason;
}

/// A concrete [HandlerMethod] implementation for testing purposes.
class FakeHandlerMethod implements HandlerMethod {
  final HandlerArgumentContext _context;
  final HttpMethod _httpMethod;
  final String _path;
  final Method? _method;
  final Class _invokingClass;

  FakeHandlerMethod({
    HandlerArgumentContext? context,
    HttpMethod? httpMethod,
    String path = '/test',
    Method? method,
    Class? invokingClass,
  })  : _context = context ?? DefaultHandlerArgumentContext(),
        _httpMethod = httpMethod ?? HttpMethod.GET,
        _path = path,
        _method = method,
        _invokingClass = invokingClass ?? Class<Object>();

  @override
  HandlerArgumentContext getContext() => _context;

  @override
  Class getInvokingClass() => _invokingClass;

  @override
  HttpMethod getHttpMethod() => _httpMethod;

  @override
  Method? getMethod() => _method;

  @override
  String getPath() => _path;
}

/// A test-only [HandlerAdapter] that supports a specific [HandlerMethod] type.
class FakeHandlerAdapter implements HandlerAdapter {
  final bool Function(HandlerMethod) _supportsFn;
  int handleCount = 0;

  FakeHandlerAdapter({bool Function(HandlerMethod)? supports})
      : _supportsFn = supports ?? ((_) => false);

  @override
  bool supports(HandlerMethod handler) => _supportsFn(handler);

  @override
  Future<void> handle(
    ServerHttpRequest request,
    ServerHttpResponse response,
    HandlerMethod handler,
  ) async {
    handleCount++;
  }
}

/// A test-only [HandlerMapping] that returns a configured handler.
class FakeHandlerMapping implements HandlerMapping {
  final HandlerMethod? Function(ServerHttpRequest) _getHandlerFn;

  FakeHandlerMapping({HandlerMethod? Function(ServerHttpRequest)? getHandler})
      : _getHandlerFn = getHandler ?? ((_) => null);

  @override
  HandlerMethod? getHandler(ServerHttpRequest request) => _getHandlerFn(request);
}

/// A test-only [MethodArgumentResolverManager] for verifying adapter behavior.
class FakeMethodArgumentResolverManager implements MethodArgumentResolverManager {
  @override
  List<MethodArgumentResolver> getHandlers() => [];

  @override
  Future<ArgumentValueHolder> resolveArgs(
    Method method,
    ServerHttpRequest req,
    ServerHttpResponse res,
    HandlerMethod handler, [
    Object? ex,
    StackTrace? st,
  ]) async {
    return ArgumentValueHolder();
  }
}

/// A test-only [ReturnValueHandlerManager] for verifying adapter behavior.
class FakeReturnValueHandlerManager implements ReturnValueHandlerManager {
  int handleCount = 0;

  @override
  bool canHandle(Method? method, Object? returnValue, ServerHttpRequest request) => false;

  @override
  List<MediaType> getSupportedMediaTypes() => [];

  @override
  Future<void> handleReturnValue(
    Object? returnValue,
    Method? method,
    ServerHttpRequest request,
    ServerHttpResponse response,
    HandlerMethod? hm,
  ) async {
    handleCount++;
  }

  @override
  ReturnValueHandler? findHandler(Method? method, Object? returnValue, ServerHttpRequest request) => null;

  @override
  List<ReturnValueHandler> getHandlers() => [];

  @override
  List<Object?> equalizedProperties() => [];
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

@JetleafTest()
void main() {
  // ==========================================================================
  // HandlerAdapter Interface
  // ==========================================================================
  group('HandlerAdapter', () {
    test('is an abstract interface class', () {
      expect(HandlerAdapter, isA<Type>());
    });

    test('can be implemented by a concrete class', () {
      final adapter = FakeHandlerAdapter();
      expect(adapter, isA<HandlerAdapter>());
    });

    test('supports returns boolean', () {
      final adapter = FakeHandlerAdapter(supports: (_) => true);
      final handler = FakeHandlerMethod();
      expect(adapter.supports(handler), isTrue);
    });

    test('supports returns false when not supported', () {
      final adapter = FakeHandlerAdapter(supports: (_) => false);
      final handler = FakeHandlerMethod();
      expect(adapter.supports(handler), isFalse);
    });

    test('handle returns a Future', () async {
      final adapter = FakeHandlerAdapter(supports: (_) => true);
      final request = FakeServerHttpRequest();
      final response = FakeServerHttpResponse();
      final handler = FakeHandlerMethod();

      await adapter.handle(request, response, handler);
      expect(adapter.handleCount, 1);
    });
  });

  // ==========================================================================
  // HandlerAdapterManager
  // ==========================================================================
  group('HandlerAdapterManager', () {
    late HandlerAdapterManager manager;

    setUp(() {
      manager = HandlerAdapterManager();
    });

    test('initializes with empty adapter list', () {
      final adapters = manager.getHandlerAdapters();
      expect(adapters, isEmpty);
    });

    test('getHandlerAdapters returns unmodifiable list', () {
      final adapters = manager.getHandlerAdapters();
      expect(
        () => adapters.add(FakeHandlerAdapter()),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('findSupportingAdapter returns null when no adapters registered', () {
      final handler = FakeHandlerMethod(httpMethod: HttpMethod.GET);
      final result = manager.findSupportingAdapter(handler);
      expect(result, isNull);
    });

    test('findSupportingAdapter returns matching adapter', () async {
      final handler = FakeHandlerMethod(httpMethod: HttpMethod.GET);
      final adapter = FakeHandlerAdapter(supports: (h) => h.getHttpMethod() == HttpMethod.GET);

      // Manually invoke the private _addAdapter via onReady simulation.
      // Since _addAdapter is private, we test via the public interface.
      // For unit testing, we rely on the fact that onReady scans the context.
      // Instead, verify the manager's public contract works with the adapter.
      manager.setApplicationContext(_FakeApplicationContext(adapters: [adapter]));
      await manager.onReady();

      final result = manager.findSupportingAdapter(handler);
      expect(result, same(adapter));
    });

    test('findSupportingAdapter returns first matching adapter', () async {
      final handler = FakeHandlerMethod(httpMethod: HttpMethod.GET);
      final adapter1 = FakeHandlerAdapter(supports: (h) => h.getHttpMethod() == HttpMethod.GET);
      final adapter2 = FakeHandlerAdapter(supports: (h) => h.getHttpMethod() == HttpMethod.GET);

      manager.setApplicationContext(
        _FakeApplicationContext(adapters: [adapter1, adapter2]),
      );
      await manager.onReady();

      final result = manager.findSupportingAdapter(handler);
      expect(result, same(adapter1));
    });

    test('findSupportingAdapter skips non-matching adapters', () async {
      final handler = FakeHandlerMethod(httpMethod: HttpMethod.POST);
      final adapter = FakeHandlerAdapter(supports: (h) => h.getHttpMethod() == HttpMethod.GET);

      manager.setApplicationContext(_FakeApplicationContext(adapters: [adapter]));
      await manager.onReady();

      final result = manager.findSupportingAdapter(handler);
      expect(result, isNull);
    });

    test('getPackageName returns WEB', () {
      expect(manager.getPackageName(), PackageNames.WEB);
    });
  });

  // ==========================================================================
  // AnnotatedHandlerAdapter
  // ==========================================================================
  group('AnnotatedHandlerAdapter', () {
    late AnnotatedHandlerAdapter adapter;
    late FakeMethodArgumentResolverManager argResolver;
    late FakeReturnValueHandlerManager returnHandler;

    setUp(() {
      argResolver = FakeMethodArgumentResolverManager();
      returnHandler = FakeReturnValueHandlerManager();
      adapter = AnnotatedHandlerAdapter(argResolver, returnHandler);
    });

    test('supports returns true for AnnotatedHandlerMethod', () {
      final handler = AnnotatedHandlerMethod(
        DefaultHandlerArgumentContext(),
        '/test',
        definition: _getControllerDefinition(),
        method: _getTestMethod(),
        httpMethod: HttpMethod.GET,
        produces: [],
        consumes: [],
      );

      expect(adapter.supports(handler), isTrue);
    });

    test('supports returns false for non-AnnotatedHandlerMethod', () {
      final handler = FakeHandlerMethod();
      expect(adapter.supports(handler), isFalse);
    });

    test('supports returns false for FrameworkHandlerMethod', () {
      final handler = FrameworkHandlerMethod(
        DefaultHandlerArgumentContext(),
        _getRouteDefinition(),
      );
      expect(adapter.supports(handler), isFalse);
    });

    test('handle invokes doHandle for AnnotatedHandlerMethod', () async {
      final request = FakeServerHttpRequest();
      final response = FakeServerHttpResponse();
      final handler = AnnotatedHandlerMethod(
        DefaultHandlerArgumentContext(),
        '/test',
        definition: _getControllerDefinition(),
        method: _getTestMethod(),
        httpMethod: HttpMethod.GET,
        produces: [],
        consumes: [],
      );

      await adapter.handle(request, response, handler);
      expect(returnHandler.handleCount, 1);
    });

    test('handle sets Content-Type header from consumes', () async {
      final request = FakeServerHttpRequest();
      final response = FakeServerHttpResponse();
      final handler = AnnotatedHandlerMethod(
        DefaultHandlerArgumentContext(),
        '/test',
        definition: _getControllerDefinition(),
        method: _getTestMethod(),
        httpMethod: HttpMethod.POST,
        produces: [],
        consumes: [MediaType.APPLICATION_JSON],
      );

      await adapter.handle(request, response, handler);
      // Verify the request headers were updated
      final headers = request.getHeaders();
      expect(headers.getFirst(HttpHeaders.CONTENT_TYPE), isNotNull);
    });

    test('handle sets Accept header from produces', () async {
      final request = FakeServerHttpRequest();
      final response = FakeServerHttpResponse();
      final handler = AnnotatedHandlerMethod(
        DefaultHandlerArgumentContext(),
        '/test',
        definition: _getControllerDefinition(),
        method: _getTestMethod(),
        httpMethod: HttpMethod.GET,
        produces: [MediaType.APPLICATION_JSON],
        consumes: [],
      );

      await adapter.handle(request, response, handler);
      final headers = request.getHeaders();
      expect(headers.getFirst(HttpHeaders.ACCEPT), isNotNull);
    });

    test('handle does nothing for non-AnnotatedHandlerMethod', () async {
      final request = FakeServerHttpRequest();
      final response = FakeServerHttpResponse();
      final handler = FakeHandlerMethod();

      // Should not throw; handle returns early for non-matching type
      await adapter.handle(request, response, handler);
      expect(returnHandler.handleCount, 0);
    });
  });

  // ==========================================================================
  // HandlerMapping Interface
  // ==========================================================================
  group('HandlerMapping', () {
    test('is an abstract interface class', () {
      expect(HandlerMapping, isA<Type>());
    });

    test('can be implemented by a concrete class', () {
      final mapping = FakeHandlerMapping();
      expect(mapping, isA<HandlerMapping>());
    });

    test('getHandler returns handler when matched', () {
      final expectedHandler = FakeHandlerMethod();
      final mapping = FakeHandlerMapping(
        getHandler: (_) => expectedHandler,
      );

      final request = FakeServerHttpRequest();
      final result = mapping.getHandler(request);
      expect(result, same(expectedHandler));
    });

    test('getHandler returns null when no match', () {
      final mapping = FakeHandlerMapping(getHandler: (_) => null);
      final request = FakeServerHttpRequest();
      final result = mapping.getHandler(request);
      expect(result, isNull);
    });

    test('getHandler is called with the request', () {
      ServerHttpRequest? capturedRequest;
      final mapping = FakeHandlerMapping(
        getHandler: (req) {
          capturedRequest = req;
          return null;
        },
      );

      final request = FakeServerHttpRequest(method: HttpMethod.POST);
      mapping.getHandler(request);
      expect(capturedRequest, same(request));
    });
  });

  // ==========================================================================
  // RouteRegistryHandlerMapping
  // ==========================================================================
  group('RouteRegistryHandlerMapping', () {
    late RouteRegistryHandlerMapping mapping;

    setUp(() {
      mapping = _createRouteRegistryMapping();
    });

    test('addHandlerMapping registers a user mapping', () {
      final userMapping = FakeHandlerMapping(
        getHandler: (_) => FakeHandlerMethod(path: '/custom'),
      );

      mapping.addHandlerMapping(userMapping);

      final request = FakeServerHttpRequest(uri: Uri.parse('/custom'));
      final result = mapping.getHandler(request);
      expect(result, isNotNull);
      expect(result!.getPath(), '/custom');
    });

    test('addHandlerMapping keeps first mapping when different instances', () {
      final handler1 = FakeHandlerMethod(path: '/first');
      final handler2 = FakeHandlerMethod(path: '/second');

      final userMapping1 = FakeHandlerMapping(getHandler: (_) => handler1);
      final userMapping2 = FakeHandlerMapping(getHandler: (_) => handler2);

      mapping.addHandlerMapping(userMapping1);
      mapping.addHandlerMapping(userMapping2);

      // Different instances are not ==, so both stay; first one checked wins
      final request = FakeServerHttpRequest(uri: Uri.parse('/test'));
      final result = mapping.getHandler(request);
      expect(result, same(handler1));
    });

    test('getHandler delegates to user-defined mappings first', () {
      final userHandler = FakeHandlerMethod(path: '/from-user');
      final userMapping = FakeHandlerMapping(getHandler: (_) => userHandler);

      mapping.addHandlerMapping(userMapping);

      final request = FakeServerHttpRequest(uri: Uri.parse('/from-user'));
      final result = mapping.getHandler(request);
      expect(result, same(userHandler));
    });

    test('getHandler returns null when no route matches', () {
      final request = FakeServerHttpRequest(uri: Uri.parse('/nonexistent'));
      final result = mapping.getHandler(request);
      expect(result, isNull);
    });

    test('getPackageName returns WEB', () {
      expect(mapping.getPackageName(), PackageNames.WEB);
    });
  });

  // ==========================================================================
  // HandlerMethod Interface
  // ==========================================================================
  group('HandlerMethod', () {
    test('is an abstract interface class', () {
      expect(HandlerMethod, isA<Type>());
    });

    test('CLASS static field is not null', () {
      expect(HandlerMethod.CLASS, isNotNull);
    });

    test('getContext returns HandlerArgumentContext', () {
      final handler = FakeHandlerMethod();
      expect(handler.getContext(), isA<HandlerArgumentContext>());
    });

    test('getInvokingClass returns Class', () {
      final handler = FakeHandlerMethod();
      expect(handler.getInvokingClass(), isA<Class>());
    });

    test('getHttpMethod returns HttpMethod', () {
      final handler = FakeHandlerMethod(httpMethod: HttpMethod.POST);
      expect(handler.getHttpMethod(), HttpMethod.POST);
    });

    test('getPath returns path string', () {
      final handler = FakeHandlerMethod(path: '/api/users');
      expect(handler.getPath(), '/api/users');
    });

    test('getMethod returns Method or null', () {
      final handlerWithMethod = FakeHandlerMethod(method: _getTestMethod());
      expect(handlerWithMethod.getMethod(), isNotNull);

      final handlerWithoutMethod = FakeHandlerMethod(method: null);
      expect(handlerWithoutMethod.getMethod(), isNull);
    });
  });

  // ==========================================================================
  // DefaultHandlerArgumentContext
  // ==========================================================================
  group('DefaultHandlerArgumentContext', () {
    late DefaultHandlerArgumentContext context;

    setUp(() {
      context = DefaultHandlerArgumentContext();
    });

    test('get returns null when no args set', () {
      expect(context.get(), isNull);
    });

    test('get returns first positional arg when no name provided', () {
      context.setArgs(ArgumentValueHolder(
        positionalArgs: ['first', 'second'],
        namedArgs: {},
      ));
      expect(context.get(), 'first');
    });

    test('get returns named arg by name', () {
      context.setArgs(ArgumentValueHolder(
        positionalArgs: [],
        namedArgs: {'username': 'alice'},
      ));
      expect(context.get('username'), 'alice');
    });

    test('get returns null for missing named arg', () {
      context.setArgs(ArgumentValueHolder(
        positionalArgs: [],
        namedArgs: {'username': 'alice'},
      ));
      expect(context.get('password'), isNull);
    });

    test('getAs returns typed value from positional args', () {
      context.setArgs(ArgumentValueHolder(
        positionalArgs: [42, 'hello'],
        namedArgs: {},
      ));
      expect(context.getAs<int>(), 42);
    });

    test('getAs returns typed value from named args', () {
      context.setArgs(ArgumentValueHolder(
        positionalArgs: [],
        namedArgs: {'count': 99},
      ));
      expect(context.getAs<int>('count'), 99);
    });

    test('getAs returns null when type not found', () {
      context.setArgs(ArgumentValueHolder(
        positionalArgs: ['string'],
        namedArgs: {},
      ));
      expect(context.getAs<int>(), isNull);
    });

    test('getArgs returns current ArgumentValueHolder', () {
      final holder = ArgumentValueHolder(
        positionalArgs: [1],
        namedArgs: {'key': 'val'},
      );
      context.setArgs(holder);
      expect(context.getArgs(), same(holder));
    });

    test('setArgs replaces the ArgumentValueHolder', () {
      final holder1 = ArgumentValueHolder(positionalArgs: [1]);
      final holder2 = ArgumentValueHolder(positionalArgs: [2]);

      context.setArgs(holder1);
      expect(context.get(), 1);

      context.setArgs(holder2);
      expect(context.get(), 2);
    });

    test('toString includes context data', () {
      final str = context.toString();
      expect(str, contains('DefaultHandlerArgumentContext'));
    });
  });

  // ==========================================================================
  // AnnotatedHandlerMethod
  // ==========================================================================
  group('AnnotatedHandlerMethod', () {
    late AnnotatedHandlerMethod handler;

    setUp(() {
      handler = AnnotatedHandlerMethod(
        DefaultHandlerArgumentContext(),
        '/api/users',
        definition: _getControllerDefinition(),
        method: _getTestMethod(),
        httpMethod: HttpMethod.GET,
        produces: [MediaType.APPLICATION_JSON],
        consumes: [MediaType.APPLICATION_JSON],
      );
    });

    test('getContext returns HandlerArgumentContext', () {
      expect(handler.getContext(), isA<HandlerArgumentContext>());
    });

    test('getInvokingClass returns class from definition', () {
      expect(handler.getInvokingClass(), isA<Class>());
    });

    test('getHttpMethod returns configured method', () {
      expect(handler.getHttpMethod(), HttpMethod.GET);
    });

    test('getMethod returns the reflective method', () {
      expect(handler.getMethod(), isNotNull);
    });

    test('getPath returns the resolved path', () {
      expect(handler.getPath(), '/api/users');
    });

    test('produces list is accessible', () {
      expect(handler.produces, contains(MediaType.APPLICATION_JSON));
    });

    test('consumes list is accessible', () {
      expect(handler.consumes, contains(MediaType.APPLICATION_JSON));
    });

    test('definition is accessible', () {
      expect(handler.definition, isNotNull);
    });
  });

  // ==========================================================================
  // RouteDslHandlerMethod
  // ==========================================================================
  group('RouteDslHandlerMethod', () {
    late RouteDslHandlerMethod handler;

    setUp(() {
      final definition = _getRouteDefinition();
      handler = RouteDslHandlerMethod(
        DefaultHandlerArgumentContext(),
        definition,
        Object(),
      );
    });

    test('getContext returns HandlerArgumentContext', () {
      expect(handler.getContext(), isA<HandlerArgumentContext>());
    });

    test('getHttpMethod returns method from definition', () {
      expect(handler.getHttpMethod(), HttpMethod.GET);
    });

    test('getMethod returns null for DSL routes', () {
      expect(handler.getMethod(), isNull);
    });

    test('getPath returns path from definition', () {
      expect(handler.getPath(), '/dsl/test');
    });

    test('getInvokingClass returns target class', () {
      expect(handler.getInvokingClass(), isA<Class>());
    });

    test('definition is accessible', () {
      expect(handler.definition, isNotNull);
    });

    test('target is accessible', () {
      expect(handler.target, isA<Object>());
    });
  });

  // ==========================================================================
  // FrameworkHandlerMethod
  // ==========================================================================
  group('FrameworkHandlerMethod', () {
    late FrameworkHandlerMethod handler;

    setUp(() {
      handler = FrameworkHandlerMethod(
        DefaultHandlerArgumentContext(),
        _getRouteDefinition(),
      );
    });

    test('getContext returns HandlerArgumentContext', () {
      expect(handler.getContext(), isA<HandlerArgumentContext>());
    });

    test('getHttpMethod returns method from definition', () {
      expect(handler.getHttpMethod(), HttpMethod.GET);
    });

    test('getMethod returns null for framework handlers', () {
      expect(handler.getMethod(), isNull);
    });

    test('getPath returns path from definition', () {
      expect(handler.getPath(), '/dsl/test');
    });

    test('getInvokingClass returns own class', () {
      expect(handler.getInvokingClass(), isA<Class>());
    });
  });

  // ==========================================================================
  // ServerHttpRequest Interface
  // ==========================================================================
  group('ServerHttpRequest', () {
    test('is an abstract interface class', () {
      expect(ServerHttpRequest, isA<Type>());
    });

    test('CLASS static field is not null', () {
      expect(ServerHttpRequest.CLASS, isNotNull);
    });

    test('ATTRIBUTE_NAME constant is defined', () {
      expect(ServerHttpRequest.ATTRIBUTE_NAME, '@attributeName');
    });

    test('REST__REQUESTED__ constant is defined', () {
      expect(ServerHttpRequest.REST__REQUESTED__, contains('@attributeName'));
    });

    test('can be implemented by a concrete class', () {
      final request = FakeServerHttpRequest();
      expect(request, isA<ServerHttpRequest>());
    });

    test('getMethod returns configured HTTP method', () {
      final request = FakeServerHttpRequest(method: HttpMethod.POST);
      expect(request.getMethod(), HttpMethod.POST);
    });

    test('getRequestURI returns configured URI', () {
      final uri = Uri.parse('/api/users?page=1');
      final request = FakeServerHttpRequest(uri: uri);
      expect(request.getRequestURI(), uri);
    });

    test('getUri returns full URI', () {
      final uri = Uri.parse('/test?foo=bar');
      final request = FakeServerHttpRequest(uri: uri);
      expect(request.getUri(), uri);
    });

    test('getQueryString returns query or null', () {
      final withQuery = FakeServerHttpRequest(uri: Uri.parse('/test?q=hello'));
      expect(withQuery.getQueryString(), 'q=hello');

      final withoutQuery = FakeServerHttpRequest(uri: Uri.parse('/test'));
      expect(withoutQuery.getQueryString(), isNull);
    });

    test('getContextPath returns context path', () {
      final request = FakeServerHttpRequest(contextPath: '/app');
      expect(request.getContextPath(), '/app');
    });

    test('setContextPath updates context path', () {
      final request = FakeServerHttpRequest();
      request.setContextPath('/api');
      expect(request.getContextPath(), '/api');
    });

    test('getAttributes returns unmodifiable map', () {
      final request = FakeServerHttpRequest();
      request.setAttribute('key', 'value');
      final attrs = request.getAttributes();
      expect(attrs, {'key': 'value'});
    });

    test('setAttribute stores attribute', () {
      final request = FakeServerHttpRequest();
      request.setAttribute('userId', 42);
      expect(request.getAttribute('userId'), 42);
    });

    test('getAttribute returns null for missing key', () {
      final request = FakeServerHttpRequest();
      expect(request.getAttribute('missing'), isNull);
    });

    test('removeAttribute removes stored attribute', () {
      final request = FakeServerHttpRequest();
      request.setAttribute('key', 'value');
      request.removeAttribute('key');
      expect(request.getAttribute('key'), isNull);
    });

    test('getAttributeNames returns all attribute names', () {
      final request = FakeServerHttpRequest();
      request.setAttribute('a', 1);
      request.setAttribute('b', 2);
      expect(request.getAttributeNames(), containsAll(['a', 'b']));
    });

    test('getCookies returns HttpCookies instance', () {
      final request = FakeServerHttpRequest();
      expect(request.getCookies(), isA<HttpCookies>());
    });

    test('getSession returns null when create is false', () {
      final request = FakeServerHttpRequest();
      expect(request.getSession(false), isNull);
    });

    test('getPathVariables returns empty map for fake', () {
      final request = FakeServerHttpRequest();
      expect(request.getPathVariables(), isEmpty);
    });

    test('getPathVariable returns null for fake', () {
      final request = FakeServerHttpRequest();
      expect(request.getPathVariable('id'), isNull);
    });

    test('shouldUpgrade returns false for fake', () {
      final request = FakeServerHttpRequest();
      expect(request.shouldUpgrade(), isFalse);
    });

    test('setRequestUrl and getRequestUrl work together', () {
      final request = FakeServerHttpRequest();
      request.setRequestUrl('/resolved/path');
      expect(request.getRequestUrl(), '/resolved/path');
    });

    test('getContentLength returns 0 for fake', () {
      final request = FakeServerHttpRequest();
      expect(request.getContentLength(), 0);
    });

    test('getOrigin returns empty string for fake', () {
      final request = FakeServerHttpRequest();
      expect(request.getOrigin(), '');
    });

    test('getHeaders returns HttpHeaders instance', () {
      final request = FakeServerHttpRequest();
      expect(request.getHeaders(), isA<HttpHeaders>());
    });

    test('getParameter returns null for fake', () {
      final request = FakeServerHttpRequest();
      expect(request.getParameter('q'), isNull);
    });

    test('getParameterValues returns empty list for fake', () {
      final request = FakeServerHttpRequest();
      expect(request.getParameterValues('q'), isEmpty);
    });

    test('getParameterMap returns empty map for fake', () {
      final request = FakeServerHttpRequest();
      expect(request.getParameterMap(), isEmpty);
    });
  });

  // ==========================================================================
  // ServerHttpResponse Interface
  // ==========================================================================
  group('ServerHttpResponse', () {
    test('is an abstract interface class', () {
      expect(ServerHttpResponse, isA<Type>());
    });

    test('CLASS static field is not null', () {
      expect(ServerHttpResponse.CLASS, isNotNull);
    });

    test('can be implemented by a concrete class', () {
      final response = FakeServerHttpResponse();
      expect(response, isA<ServerHttpResponse>());
    });

    test('setStatus and getStatus work together', () {
      final response = FakeServerHttpResponse();
      response.setStatus(HttpStatus.OK);
      expect(response.getStatus(), HttpStatus.OK);
    });

    test('getStatus returns null when no status set', () {
      final response = FakeServerHttpResponse();
      expect(response.getStatus(), isNull);
    });

    test('setReason and getReason work together', () {
      final response = FakeServerHttpResponse();
      response.setReason('All good');
      expect(response.getReason(), 'All good');
    });

    test('isCommitted returns false initially', () {
      final response = FakeServerHttpResponse();
      expect(response.isCommitted(), isFalse);
    });

    test('getHeaders returns HttpHeaders instance', () {
      final response = FakeServerHttpResponse();
      expect(response.getHeaders(), isA<HttpHeaders>());
    });

    test('encodeRedirectUrl returns the location', () async {
      final response = FakeServerHttpResponse();
      final encoded = await response.encodeRedirectUrl('/login');
      expect(encoded, '/login');
    });

    test('sendRedirect completes without error', () async {
      final response = FakeServerHttpResponse();
      // Should not throw
      await response.sendRedirect('/home');
    });

    test('getBody returns OutputStream instance', () {
      final response = FakeServerHttpResponse();
      expect(response.getBody(), isA<OutputStream>());
    });
  });

  // ==========================================================================
  // PathPattern
  // ==========================================================================
  group('PathPattern', () {
    test('creates pattern with required properties', () {
      final pattern = PathPattern(
        pattern: '/api/users/{id}',
        segments: [
          LiteralSegment('api'),
          LiteralSegment('users'),
          VariableSegment('id'),
        ],
        hasWildcard: false,
        hasVariables: true,
        optionalTrailingSlash: false,
        caseInsensitive: false,
        isStatic: false,
        matchingRank: 0,
      );

      expect(pattern.pattern, '/api/users/{id}');
      expect(pattern.hasVariables, isTrue);
      expect(pattern.hasWildcard, isFalse);
      expect(pattern.isStatic, isFalse);
    });

    test('getVariableNames extracts variable names from segments', () {
      final pattern = PathPattern(
        pattern: '/users/{id}/posts/{postId}',
        segments: [
          LiteralSegment('users'),
          VariableSegment('id'),
          LiteralSegment('posts'),
          VariableSegment('postId'),
        ],
        hasWildcard: false,
        hasVariables: true,
        optionalTrailingSlash: false,
        caseInsensitive: false,
        isStatic: false,
        matchingRank: 0,
      );

      final names = pattern.getVariableNames();
      expect(names, containsAll(['id', 'postId']));
    });

    test('getVariableNames returns empty set for static pattern', () {
      final pattern = PathPattern(
        pattern: '/api/users',
        segments: [LiteralSegment('api'), LiteralSegment('users')],
        hasWildcard: false,
        hasVariables: false,
        optionalTrailingSlash: false,
        caseInsensitive: false,
        isStatic: true,
        matchingRank: 0,
      );

      expect(pattern.getVariableNames(), isEmpty);
    });

    test('getSpecificityScore computes correctly', () {
      final pattern = PathPattern(
        pattern: '/api/users/{id}',
        segments: [
          LiteralSegment('api'),
          LiteralSegment('users'),
          VariableSegment('id'),
        ],
        hasWildcard: false,
        hasVariables: true,
        optionalTrailingSlash: false,
        caseInsensitive: false,
        isStatic: false,
        matchingRank: 0,
      );

      // api=10000, users=10000, {id}=100 → 20100
      expect(pattern.getSpecificityScore(), 20100);
    });

    test('getSpecificityScore with wildcard segments', () {
      final singleWildcard = PathPattern(
        pattern: '/api/*',
        segments: [LiteralSegment('api'), WildcardSegment()],
        hasWildcard: true,
        hasVariables: false,
        optionalTrailingSlash: false,
        caseInsensitive: false,
        isStatic: false,
        matchingRank: 0,
      );

      final multiWildcard = PathPattern(
        pattern: '/api/**',
        segments: [LiteralSegment('api'), WildcardSegment(true)],
        hasWildcard: true,
        hasVariables: false,
        optionalTrailingSlash: false,
        caseInsensitive: false,
        isStatic: false,
        matchingRank: 0,
      );

      // api=10000, *=50 → 10050
      expect(singleWildcard.getSpecificityScore(), 10050);
      // api=10000, **=1 → 10001
      expect(multiWildcard.getSpecificityScore(), 10001);
    });

    test('toString returns pattern string', () {
      final pattern = PathPattern(
        pattern: '/test',
        segments: [LiteralSegment('test')],
        hasWildcard: false,
        hasVariables: false,
        optionalTrailingSlash: false,
        caseInsensitive: false,
        isStatic: true,
        matchingRank: 0,
      );

      expect(pattern.toString(), contains('/test'));
    });

    test('equality is based on pattern string', () {
      final p1 = PathPattern(
        pattern: '/test',
        segments: [],
        hasWildcard: false,
        hasVariables: false,
        optionalTrailingSlash: false,
        caseInsensitive: false,
        isStatic: true,
        matchingRank: 0,
      );

      final p2 = PathPattern(
        pattern: '/test',
        segments: [],
        hasWildcard: false,
        hasVariables: false,
        optionalTrailingSlash: false,
        caseInsensitive: false,
        isStatic: true,
        matchingRank: 0,
      );

      final p3 = PathPattern(
        pattern: '/other',
        segments: [],
        hasWildcard: false,
        hasVariables: false,
        optionalTrailingSlash: false,
        caseInsensitive: false,
        isStatic: true,
        matchingRank: 0,
      );

      expect(p1, equals(p2));
      expect(p1, isNot(equals(p3)));
    });
  });

  // ==========================================================================
  // PathSegment Types
  // ==========================================================================
  group('PathSegment types', () {
    group('LiteralSegment', () {
      test('matches exact string', () {
        final segment = LiteralSegment('users');
        expect(segment.matches('users'), isTrue);
      });

      test('does not match different string', () {
        final segment = LiteralSegment('users');
        expect(segment.matches('admin'), isFalse);
      });

      test('matches case-insensitively by default', () {
        final segment = LiteralSegment('Users');
        expect(segment.matches('users'), isTrue);
      });

      test('matches case-sensitively when specified', () {
        final segment = LiteralSegment('Users');
        expect(segment.matches('users', false), isFalse);
        expect(segment.matches('Users', false), isTrue);
      });

      test('getSegmentString returns value', () {
        expect(LiteralSegment('api').getSegmentString(), 'api');
      });

      test('getIsLiteral returns true', () {
        expect(LiteralSegment('x').getIsLiteral(), isTrue);
      });

      test('getIsWildcard returns false', () {
        expect(LiteralSegment('x').getIsWildcard(), isFalse);
      });

      test('extractVariables returns empty map', () {
        expect(LiteralSegment('x').extractVariables('y'), isEmpty);
      });

      test('equality is based on value', () {
        expect(LiteralSegment('a'), equals(LiteralSegment('a')));
        expect(LiteralSegment('a'), isNot(equals(LiteralSegment('b'))));
      });
    });

    group('VariableSegment', () {
      test('matches any non-empty string', () {
        final segment = VariableSegment('id');
        expect(segment.matches('42'), isTrue);
        expect(segment.matches('abc'), isTrue);
      });

      test('does not match empty string', () {
        final segment = VariableSegment('id');
        expect(segment.matches(''), isFalse);
      });

      test('matches with regex constraint', () {
        final segment = VariableSegment('id', regex: RegExp(r'^\d+$'));
        expect(segment.matches('123'), isTrue);
        expect(segment.matches('abc'), isFalse);
      });

      test('extractVariables returns name-value pair', () {
        final segment = VariableSegment('id');
        expect(segment.extractVariables('42'), {'id': '42'});
      });

      test('getSegmentString returns {name}', () {
        expect(VariableSegment('userId').getSegmentString(), '{userId}');
      });

      test('getIsLiteral returns false', () {
        expect(VariableSegment('id').getIsLiteral(), isFalse);
      });

      test('getIsWildcard returns false', () {
        expect(VariableSegment('id').getIsWildcard(), isFalse);
      });

      test('equality is based on name and pattern', () {
        expect(VariableSegment('id'), equals(VariableSegment('id')));
        expect(VariableSegment('id'), isNot(equals(VariableSegment('userId'))));
      });
    });

    group('WildcardSegment', () {
      test('single wildcard matches any string', () {
        final segment = WildcardSegment();
        expect(segment.matches('anything'), isTrue);
        expect(segment.matches(''), isTrue);
      });

      test('multi wildcard matches any string', () {
        final segment = WildcardSegment(true);
        expect(segment.matches('a/b/c'), isTrue);
      });

      test('getSegmentString returns * for single', () {
        expect(WildcardSegment().getSegmentString(), '*');
      });

      test('getSegmentString returns ** for multi', () {
        expect(WildcardSegment(true).getSegmentString(), '**');
      });

      test('getIsLiteral returns false', () {
        expect(WildcardSegment().getIsLiteral(), isFalse);
      });

      test('getIsWildcard returns true', () {
        expect(WildcardSegment().getIsWildcard(), isTrue);
      });

      test('extractVariables returns empty map', () {
        expect(WildcardSegment().extractVariables('x'), isEmpty);
      });

      test('equality is based on multiSegment flag', () {
        expect(WildcardSegment(), equals(WildcardSegment()));
        expect(WildcardSegment(true), equals(WildcardSegment(true)));
        expect(WildcardSegment(), isNot(equals(WildcardSegment(true))));
      });
    });

    group('RegexSegment', () {
      test('matches when regex matches', () {
        final segment = RegexSegment(r'^\d+$');
        expect(segment.matches('123'), isTrue);
      });

      test('does not match when regex fails', () {
        final segment = RegexSegment(r'^\d+$');
        expect(segment.matches('abc'), isFalse);
      });

      test('matches case-insensitively by default', () {
        final segment = RegexSegment(r'^hello$');
        expect(segment.matches('HELLO'), isTrue);
      });

      test('matches case-sensitively when specified', () {
        final segment = RegexSegment(r'^hello$');
        expect(segment.matches('HELLO', false), isFalse);
      });

      test('getSegmentString returns pattern', () {
        expect(RegexSegment(r'^\d+$').getSegmentString(), r'^\d+$');
      });

      test('getIsLiteral returns false', () {
        expect(RegexSegment(r'.').getIsLiteral(), isFalse);
      });

      test('getIsWildcard returns false', () {
        expect(RegexSegment(r'.').getIsWildcard(), isFalse);
      });

      test('equality is based on pattern', () {
        expect(RegexSegment(r'\d+'), equals(RegexSegment(r'\d+')));
        expect(RegexSegment(r'\d+'), isNot(equals(RegexSegment(r'\w+'))));
      });
    });
  });

  // ==========================================================================
  // HttpMethod (Additional)
  // ==========================================================================
  group('HttpMethod - additional', () {
    test('standard methods have correct string values', () {
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

    test('FROM normalizes to uppercase', () {
      expect(HttpMethod.FROM('get').toString(), 'GET');
      expect(HttpMethod.FROM('post').toString(), 'POST');
    });

    test('FROM creates custom method', () {
      final custom = HttpMethod.FROM('PROPFIND');
      expect(custom.toString(), 'PROPFIND');
    });

    test('matches is case-insensitive', () {
      expect(HttpMethod.GET.matches('get'), isTrue);
      expect(HttpMethod.GET.matches('GET'), isTrue);
      expect(HttpMethod.GET.matches('Get'), isTrue);
    });

    test('matches returns false for different method', () {
      expect(HttpMethod.GET.matches('POST'), isFalse);
    });

    test('valueOf returns matching method', () {
      expect(HttpMethod.valueOf('GET'), equals(HttpMethod.GET));
    });

    test('getMethods returns all standard methods', () {
      final methods = HttpMethod.getMethods();
      expect(methods.length, 9);
      expect(methods, containsAll([
        HttpMethod.GET, HttpMethod.POST, HttpMethod.PUT,
        HttpMethod.DELETE, HttpMethod.PATCH, HttpMethod.HEAD,
        HttpMethod.OPTIONS, HttpMethod.TRACE, HttpMethod.CONNECT,
      ]));
    });

    test('equality between predefined and FROM-created', () {
      expect(HttpMethod.FROM('GET'), equals(HttpMethod.GET));
      expect(HttpMethod.FROM('POST'), equals(HttpMethod.POST));
    });
  });

  // ==========================================================================
  // HttpStatus (Additional)
  // ==========================================================================
  group('HttpStatus - additional', () {
    test('OK has code 200', () {
      expect(HttpStatus.OK.getCode(), 200);
      expect(HttpStatus.OK.getName(), 'OK');
    });

    test('NOT_FOUND has code 404', () {
      expect(HttpStatus.NOT_FOUND.getCode(), 404);
    });

    test('INTERNAL_SERVER_ERROR has code 500', () {
      expect(HttpStatus.INTERNAL_SERVER_ERROR.getCode(), 500);
    });

    test('fromCode returns predefined status', () {
      expect(HttpStatus.fromCode(200), equals(HttpStatus.OK));
      expect(HttpStatus.fromCode(404), equals(HttpStatus.NOT_FOUND));
    });

    test('fromCode creates dynamic status for unknown codes', () {
      final status = HttpStatus.fromCode(777);
      expect(status.getCode(), 777);
      expect(status.getName(), 'UNKNOWN_777');
    });

    test('fromString returns matching status', () {
      expect(HttpStatus.fromString('OK'), equals(HttpStatus.OK));
      expect(HttpStatus.fromString('not_found'), equals(HttpStatus.NOT_FOUND));
    });

    test('fromString creates unknown status for unmatched name', () {
      final status = HttpStatus.fromString('CUSTOM');
      expect(status.getName(), 'CUSTOM');
      expect(status.getCode(), 0);
    });

    test('is2xxSuccessful returns true for 2xx codes', () {
      expect(HttpStatus.OK.is2xxSuccessful(), isTrue);
      expect(HttpStatus.CREATED.is2xxSuccessful(), isTrue);
    });

    test('is4xxClientError returns true for 4xx codes', () {
      expect(HttpStatus.NOT_FOUND.is4xxClientError(), isTrue);
      expect(HttpStatus.BAD_REQUEST.is4xxClientError(), isTrue);
    });

    test('is5xxServerError returns true for 5xx codes', () {
      expect(HttpStatus.INTERNAL_SERVER_ERROR.is5xxServerError(), isTrue);
    });

    test('toJson returns correct map', () {
      final json = HttpStatus.OK.toJson();
      expect(json['code'], 200);
      expect(json['name'], 'OK');
    });

    test('getAllStatusCodes returns list of statuses', () {
      final all = HttpStatus.getAllStatusCodes();
      expect(all.length, greaterThan(50));
    });
  });
}

// ---------------------------------------------------------------------------
// Test Helpers - Fakes for ApplicationContext-dependent classes
// ---------------------------------------------------------------------------

/// Helper to get a real [Method] from the framework's reflection system.
Method? _cachedMethod;
Method _getTestMethod() {
  _cachedMethod ??= Class<Object>().getMethod('toString');
  return _cachedMethod!;
}

/// Helper to get a real [ControllerDefinition] for testing.
/// Uses the framework's [TestControllerDefinition.createDefault] via the
/// public factory method exposed by the annotated_handler_mapping library.
dynamic _getControllerDefinition() {
  return TestControllerDefinition.createDefault();
}

/// Helper to get a [RouteDefinition] for testing.
RouteDefinition _getRouteDefinition() {
  return RouteDefinition(
    HttpMethod.GET,
    '/dsl/test',
    RequestOnlyRouterHandler((req) => Object()),
  );
}

/// Creates a [RouteRegistryHandlerMapping] for testing.
RouteRegistryHandlerMapping _createRouteRegistryMapping() {
  return RouteRegistryHandlerMapping(PathPatternParserManager());
}

// ---------------------------------------------------------------------------
// Test Doubles - ApplicationContext
// ---------------------------------------------------------------------------

/// A minimal fake [ApplicationContext] for testing [HandlerAdapterManager].
class _FakeApplicationContext extends ApplicationContext {
  final List<HandlerAdapter> adapters;

  _FakeApplicationContext({this.adapters = const []});

  @override
  Future<Map<String, T>> getPodsOf<T>(Class<T> type, {bool includeNonSingletons = false, bool allowEagerInit = false}) async {
    final result = <String, T>{};
    for (int i = 0; i < adapters.length; i++) {
      if (adapters[i] is T) {
        result['adapter_$i'] = adapters[i] as T;
      }
    }
    return result;
  }

  @override
  List<String> getDefinitionNames() => [];

  @override
  Future<bool> containsType(Class type, [bool allowPodProviderInit = false]) async => false;

  @override
  Environment getEnvironment() => _FakeEnvironment();

  @override
  String getId() => 'test-context';

  @override
  String getApplicationName() => 'test';

  @override
  DateTime getStartTime() => DateTime.now();

  @override
  bool isActive() => true;

  @override
  bool isClosed() => false;

  @override
  ApplicationContext? getParent() => null;

  @override
  String getDisplayName() => 'Test Context';

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A minimal fake [Environment] for testing.
class _FakeEnvironment implements Environment {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getProperty) return null;
    if (invocation.memberName == #containsProperty) return false;
    if (invocation.memberName == #getRequiredProperty) return '';
    if (invocation.memberName == #getPropertyAs) return null;
    if (invocation.memberName == #getActiveProfiles) return <String>{};
    if (invocation.memberName == #acceptsProfiles) return false;
    if (invocation.memberName == #getDefaultProfiles) return <String>{};
    if (invocation.memberName == #getPropertySources) return <Object>[];
    if (invocation.memberName == #setActiveProfiles) return null;
    if (invocation.memberName == #setDefaultProfiles) return null;
    if (invocation.memberName == #setPlaceholderPrefix) return null;
    if (invocation.memberName == #setPlaceholderSuffix) return null;
    if (invocation.memberName == #setValueSeparator) return null;
    if (invocation.memberName == #getPlaceholderPrefix) return r'${';
    if (invocation.memberName == #getPlaceholderSuffix) return '}';
    if (invocation.memberName == #getValueSeparator) return ':';
    if (invocation.memberName == #resolvePlaceholders) return '';
    if (invocation.memberName == #resolveRequiredPlaceholders) return '';
    if (invocation.memberName == #merge) return null;
    if (invocation.memberName == #getSystemProperties) return <String, Object>{};
    if (invocation.memberName == #getSystemEnvironment) return <String, Object>{};
    return null;
  }
}