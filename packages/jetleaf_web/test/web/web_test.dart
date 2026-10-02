import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import 'package:jetleaf_web/src/http/http_cookie.dart';
import 'package:jetleaf_web/src/http/http_cookies.dart';
import 'package:jetleaf_web/src/http/http_headers.dart' as jetleaf_headers;
import 'package:jetleaf_web/src/http/http_method.dart';
import 'package:jetleaf_web/src/http/http_session.dart';
import 'package:jetleaf_web/src/http/http_status.dart';
import 'package:jetleaf_web/src/server/server_http_request.dart';
import 'package:jetleaf_web/src/server/server_http_response.dart';
import 'package:jetleaf_web/src/web/error_page.dart';
import 'package:jetleaf_web/src/web/error_pages.dart';
import 'package:jetleaf_web/src/web/renderable.dart';
import 'package:jetleaf_web/src/web/view.dart';
import 'package:jetleaf_web/src/web/view_context.dart';
import 'package:jetleaf_web/src/web/web.dart';
import 'package:jetleaf_web/src/web/web_request.dart';

// ---------------------------------------------------------------------------
// Mock / Stub implementations
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
  @override
  Future<void> writeByte(int b) async {}

  @override
  Future<void> writeObject(Object? obj) async {}
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

  // Setters for test configuration
  void setMethod(HttpMethod method) => _method = method;
  void setUri(Uri uri) {
    _uri = uri;
    _requestUri = Uri(path: uri.path, query: uri.query);
  }
  void setRequestUri(Uri uri) => _requestUri = uri;
  void setSession(HttpSession? session) => _session = session;

  void addHeader(String name, String value) {
    _headers.add(name, value);
  }

  void addPathVariable(String name, String value) {
    _pathVariables[name] = value;
  }

  void addParameter(String name, String value) {
    _parameters.putIfAbsent(name, () => []).add(value);
  }

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
  List<String> getParameterValues(String name) {
    return _parameters[name] ?? [];
  }

  @override
  Map<String, List<String>> getParameterMap() =>
      UnmodifiableMapView(_parameters);

  @override
  String getContextPath() => _contextPath;

  @override
  void setContextPath(String contextPath) => _contextPath = contextPath;

  @override
  Map<String, Object> getAttributes() => UnmodifiableMapView(_attributes);

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
  Map<String, String> getPathVariables() => UnmodifiableMapView(_pathVariables);

  @override
  bool shouldUpgrade() => false;

  @override
  void setRequestUrl(String requestUrl) => _requestUrl = requestUrl;

  @override
  String? getRequestUrl() => _requestUrl;

  @override
  int getContentLength() => 0;

  @override
  void setHandlerContext(
          dynamic /*HandlerMethod*/ handler, dynamic /*PathPattern*/ pattern) =>
      {};

  @override
  String getOrigin() => '${_uri.scheme}://${_uri.host}';

  @override
  InputStream getBody() => _StubInputStream();
}

class MockHttpResponse implements ServerHttpResponse {
  int _statusCode = 200;
  final jetleaf_headers.HttpHeaders _headers = jetleaf_headers.HttpHeaders();

  @override
  void setStatus(HttpStatus httpStatus) => _statusCode = httpStatus.getCode();

  @override
  jetleaf_headers.HttpHeaders getHeaders() => _headers;

  @override
  void setHeaders(jetleaf_headers.HttpHeaders headers) {
    _headers.clear();
    _headers.addAllFromHeaders(headers);
  }

  @override
  OutputStream getBody() => _StubOutputStream();

  @override
  Future<String> encodeRedirectUrl(String location) async => location;

  @override
  Future<void> sendRedirect(String encodedLocation) async {}

  @override
  HttpStatus? getStatus() => HttpStatus.fromCode(_statusCode);

  @override
  bool isCommitted() => false;

  @override
  void setReason(String message) {}
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  // ErrorPage
  // =========================================================================
  group('ErrorPage', () {
    test('constructor stores path and status', () {
      final page = ErrorPage('/errors/500.html', HttpStatus.INTERNAL_SERVER_ERROR);
      expect(page.getPath(), '/errors/500.html');
      expect(page.getStatus(), HttpStatus.INTERNAL_SERVER_ERROR);
    });

    test('constructor with path only defaults status to OK', () {
      final page = ErrorPage('/errors/custom.html');
      expect(page.getPath(), '/errors/custom.html');
      expect(page.getStatus(), HttpStatus.OK);
    });

    test('FRAMEWORK_ERROR_PAGE_IDENTIFIER is correct', () {
      expect(
        ErrorPage.FRAMEWORK_ERROR_PAGE_IDENTIFIER,
        'jetleaf_web/resources/error_pages',
      );
    });

    test('ERROR_NOT_FOUND_PAGE has correct path and status', () {
      final page = ErrorPage.ERROR_NOT_FOUND_PAGE;
      expect(page.getStatus(), HttpStatus.NOT_FOUND);
      expect(page.getPath(), contains('404.html'));
      expect(page.getPath(), startsWith(ErrorPage.FRAMEWORK_ERROR_PAGE_IDENTIFIER));
    });

    test('ERROR_BAD_REQUEST_PAGE has correct status and redirect', () {
      final page = ErrorPage.ERROR_BAD_REQUEST_PAGE;
      expect(page.getStatus(), HttpStatus.BAD_REQUEST);
      expect(page.getRedirectPath(), isNotNull);
      expect(page.getRedirectStatus(), HttpStatus.NOT_FOUND);
    });

    test('ERROR_UNAUTHORIZED_PAGE has correct status and redirect', () {
      final page = ErrorPage.ERROR_UNAUTHORIZED_PAGE;
      expect(page.getStatus(), HttpStatus.UNAUTHORIZED);
      expect(page.getRedirectPath(), isNotNull);
      expect(page.getRedirectStatus(), HttpStatus.NOT_FOUND);
    });

    test('ERROR_FORBIDDEN_PAGE has correct status and redirect', () {
      final page = ErrorPage.ERROR_FORBIDDEN_PAGE;
      expect(page.getStatus(), HttpStatus.FORBIDDEN);
      expect(page.getRedirectPath(), isNotNull);
      expect(page.getRedirectStatus(), HttpStatus.NOT_FOUND);
    });

    test('ERROR_INTERNAL_SERVER_PAGE has correct status and redirect', () {
      final page = ErrorPage.ERROR_INTERNAL_SERVER_PAGE;
      expect(page.getStatus(), HttpStatus.INTERNAL_SERVER_ERROR);
      expect(page.getRedirectPath(), isNotNull);
      expect(page.getRedirectStatus(), HttpStatus.NOT_FOUND);
    });

    test('ERROR_BAD_GATEWAY_PAGE has correct status and redirect', () {
      final page = ErrorPage.ERROR_BAD_GATEWAY_PAGE;
      expect(page.getStatus(), HttpStatus.BAD_GATEWAY);
      expect(page.getRedirectPath(), isNotNull);
      expect(page.getRedirectStatus(), HttpStatus.NOT_FOUND);
    });

    test('ERROR_SERVICE_UNAVAILABLE_PAGE has correct status and redirect', () {
      final page = ErrorPage.ERROR_SERVICE_UNAVAILABLE_PAGE;
      expect(page.getStatus(), HttpStatus.SERVICE_UNAVAILABLE);
      expect(page.getRedirectPath(), isNotNull);
      expect(page.getRedirectStatus(), HttpStatus.NOT_FOUND);
    });

    test('custom error page with redirect configuration', () {
      final page = ErrorPage('/errors/maintenance.html', HttpStatus.SERVICE_UNAVAILABLE)
        ..setRedirectPath('/errors/general.html')
        ..setRedirectStatus(HttpStatus.OK);

      expect(page.getPath(), '/errors/maintenance.html');
      expect(page.getStatus(), HttpStatus.SERVICE_UNAVAILABLE);
      expect(page.getRedirectPath(), '/errors/general.html');
      expect(page.getRedirectStatus(), HttpStatus.OK);
    });

    test('setRedirectPath is fluent', () {
      final page = ErrorPage('/errors/test.html', HttpStatus.BAD_REQUEST)
        ..setRedirectPath('/fallback.html');
      expect(page.getRedirectPath(), '/fallback.html');
    });

    test('default redirect path is null', () {
      final page = ErrorPage('/errors/simple.html', HttpStatus.NOT_FOUND);
      expect(page.getRedirectPath(), isNull);
    });

    test('default redirect status is FOUND (302)', () {
      final page = ErrorPage('/errors/simple.html', HttpStatus.NOT_FOUND);
      expect(page.getRedirectStatus(), HttpStatus.FOUND);
    });

    test('attributes are mutable map', () {
      final page = ErrorPage('/errors/500.html', HttpStatus.INTERNAL_SERVER_ERROR);
      page.addAttribute('customKey', 'customValue');
      expect(page.getAttributes()['customKey'], 'customValue');
    });

    test('addAttribute is fluent', () {
      final page = ErrorPage('/errors/test.html', HttpStatus.NOT_FOUND)
        ..addAttribute('key', 'value');
      expect(page.getAttributes()['key'], 'value');
    });

    test('addAllAttributes merges multiple attributes', () {
      final page = ErrorPage('/errors/test.html', HttpStatus.NOT_FOUND)
        ..addAllAttributes({'a': 1, 'b': 2});
      expect(page.getAttributes()['a'], 1);
      expect(page.getAttributes()['b'], 2);
    });

    test('setStatusCode via int code', () {
      final page = ErrorPage('/errors/test.html', HttpStatus.NOT_FOUND);
      page.setStatusCode(500);
      expect(page.getStatus(), HttpStatus.INTERNAL_SERVER_ERROR);
    });

    test('framework page identifier prefix', () {
      final page = ErrorPage(
        '${ErrorPage.FRAMEWORK_ERROR_PAGE_IDENTIFIER}/418.html',
        HttpStatus.IM_A_TEAPOT,
      );
      expect(page.getPath(), startsWith(ErrorPage.FRAMEWORK_ERROR_PAGE_IDENTIFIER));
    });
  });

  // =========================================================================
  // ErrorPages
  // =========================================================================
  group('ErrorPages', () {
    late ErrorPages errorPages;

    setUp(() {
      errorPages = ErrorPages();
    });

    test('add application page', () {
      final page = ErrorPage('/errors/500.html', HttpStatus.INTERNAL_SERVER_ERROR);
      errorPages.add(page);

      final appPages = errorPages.getApplicationPages();
      expect(appPages, hasLength(1));
      expect(appPages.first.getPath(), '/errors/500.html');
    });

    test('add framework page via path prefix', () {
      final page = ErrorPage(
        '${ErrorPage.FRAMEWORK_ERROR_PAGE_IDENTIFIER}/404.html',
        HttpStatus.NOT_FOUND,
      );
      errorPages.add(page);

      final frameworkPages = errorPages.getFrameworkPages();
      expect(frameworkPages, hasLength(1));
      expect(frameworkPages.first.getPath(), contains('404.html'));
    });

    test('addPage with application path', () {
      errorPages.addPage('/errors/400.html', HttpStatus.BAD_REQUEST);

      final appPages = errorPages.getApplicationPages();
      expect(appPages, hasLength(1));
      expect(appPages.first.getStatus(), HttpStatus.BAD_REQUEST);
    });

    test('addPage with framework path', () {
      errorPages.addPage(
        '${ErrorPage.FRAMEWORK_ERROR_PAGE_IDENTIFIER}/503.html',
        HttpStatus.SERVICE_UNAVAILABLE,
      );

      final frameworkPages = errorPages.getFrameworkPages();
      expect(frameworkPages, hasLength(1));
      expect(frameworkPages.first.getStatus(), HttpStatus.SERVICE_UNAVAILABLE);
    });

    test('addPage creates a new ErrorPage for each call', () {
      errorPages.addPage('/errors/500-a.html', HttpStatus.INTERNAL_SERVER_ERROR);
      errorPages.addPage('/errors/500-b.html', HttpStatus.INTERNAL_SERVER_ERROR);

      final appPages = errorPages.getApplicationPages();
      expect(appPages, hasLength(2));
    });

    test('getResolvedPages returns application pages first', () {
      errorPages.addPage('/app/500.html', HttpStatus.INTERNAL_SERVER_ERROR);
      errorPages.addPage(
        '${ErrorPage.FRAMEWORK_ERROR_PAGE_IDENTIFIER}/500.html',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );

      final resolved = errorPages.getResolvedPages();
      expect(resolved, hasLength(1));
      expect(resolved.first.getPath(), '/app/500.html');
    });

    test('getResolvedPages fills framework pages when no app override', () {
      errorPages.addPage('/app/500.html', HttpStatus.INTERNAL_SERVER_ERROR);
      errorPages.addPage(
        '${ErrorPage.FRAMEWORK_ERROR_PAGE_IDENTIFIER}/404.html',
        HttpStatus.NOT_FOUND,
      );

      final resolved = errorPages.getResolvedPages();
      expect(resolved, hasLength(2));
      // Sorted by status code
      expect(resolved[0].getStatus(), HttpStatus.NOT_FOUND);
      expect(resolved[1].getStatus(), HttpStatus.INTERNAL_SERVER_ERROR);
    });

    test('getResolvedPages returns empty when no pages added', () {
      final resolved = errorPages.getResolvedPages();
      expect(resolved, isEmpty);
    });

    test('getFrameworkPages returns only framework pages', () {
      errorPages.addPage('/app/500.html', HttpStatus.INTERNAL_SERVER_ERROR);
      errorPages.addPage(
        '${ErrorPage.FRAMEWORK_ERROR_PAGE_IDENTIFIER}/404.html',
        HttpStatus.NOT_FOUND,
      );

      final frameworkPages = errorPages.getFrameworkPages();
      expect(frameworkPages, hasLength(1));
      expect(frameworkPages.first.getStatus(), HttpStatus.NOT_FOUND);
    });

    test('getApplicationPages returns only application pages', () {
      errorPages.addPage('/app/500.html', HttpStatus.INTERNAL_SERVER_ERROR);
      errorPages.addPage(
        '${ErrorPage.FRAMEWORK_ERROR_PAGE_IDENTIFIER}/404.html',
        HttpStatus.NOT_FOUND,
      );

      final appPages = errorPages.getApplicationPages();
      expect(appPages, hasLength(1));
      expect(appPages.first.getStatus(), HttpStatus.INTERNAL_SERVER_ERROR);
    });

    test('findPossibleErrorPage returns null for unknown status', () {
      final page = errorPages.findPossibleErrorPage(HttpStatus.IM_A_TEAPOT);
      expect(page, isNull);
    });

    test('findPossibleErrorPage returns page for matching status', () {
      errorPages.addPage('/errors/404.html', HttpStatus.NOT_FOUND);

      final page = errorPages.findPossibleErrorPage(HttpStatus.NOT_FOUND);
      expect(page, isNotNull);
      expect(page!.getPath(), '/errors/404.html');
    });

    test('findPossibleErrorPage returns null for null status', () {
      final page = errorPages.findPossibleErrorPage(null);
      expect(page, isNull);
    });

    test('getPackageName returns WEB', () {
      expect(errorPages.getPackageName(), PackageNames.WEB);
    });

    test('unmodifiable list returned by getResolvedPages', () {
      errorPages.addPage('/app/500.html', HttpStatus.INTERNAL_SERVER_ERROR);
      final resolved = errorPages.getResolvedPages();
      expect(
        () => resolved.add(ErrorPage('/test.html', HttpStatus.NOT_FOUND)),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  // =========================================================================
  // Renderable
  // =========================================================================
  group('Renderable', () {
    test('METHOD_NAME constant is "render"', () {
      expect(Renderable.METHOD_NAME, 'render');
    });

    test('RenderableView can be implemented', () {
      final view = _TestRenderableView();
      expect(view, isA<Renderable>());
      expect(view, isA<RenderableView>());
    });

    test('RenderableWebView can be implemented', () {
      final view = _TestRenderableWebView();
      expect(view, isA<Renderable>());
      expect(view, isA<RenderableWebView>());
    });
  });

  // =========================================================================
  // View / PageView
  // =========================================================================
  group('View / PageView', () {
    test('PageView constructor with path and status', () {
      final view = PageView('templates/home', HttpStatus.OK);
      expect(view.getPath(), 'templates/home');
      expect(view.getStatus(), HttpStatus.OK);
    });

    test('PageView constructor with path only defaults to OK', () {
      final view = PageView('templates/home');
      expect(view.getPath(), 'templates/home');
      expect(view.getStatus(), HttpStatus.OK);
    });

    test('setPath returns self for chaining', () {
      final view = PageView('old-path');
      final result = view.setPath('new-path');
      expect(identical(result, view), isTrue);
      expect(view.getPath(), 'new-path');
    });

    test('setRedirectPath sets redirect path', () {
      final view = PageView('primary')
        ..setRedirectPath('fallback');
      expect(view.getRedirectPath(), 'fallback');
    });

    test('setRedirectPath returns self for chaining', () {
      final view = PageView('primary');
      final result = view.setRedirectPath('fallback');
      expect(identical(result, view), isTrue);
    });

    test('setStatus sets status', () {
      final view = PageView('template')..setStatus(HttpStatus.CREATED);
      expect(view.getStatus(), HttpStatus.CREATED);
    });

    test('setStatus returns self for chaining', () {
      final view = PageView('template');
      final result = view.setStatus(HttpStatus.ACCEPTED);
      expect(identical(result, view), isTrue);
      expect(view.getStatus(), HttpStatus.ACCEPTED);
    });

    test('setStatusCode via int', () {
      final view = PageView('template')..setStatusCode(404);
      expect(view.getStatus(), HttpStatus.NOT_FOUND);
    });

    test('setStatusCode returns self for chaining', () {
      final view = PageView('template');
      final result = view.setStatusCode(201);
      expect(identical(result, view), isTrue);
    });

    test('setRedirectStatus sets redirect status', () {
      final view = PageView('template')..setRedirectStatus(HttpStatus.MOVED_PERMANENTLY);
      expect(view.getRedirectStatus(), HttpStatus.MOVED_PERMANENTLY);
    });

    test('setRedirectStatus returns self for chaining', () {
      final view = PageView('template');
      final result = view.setRedirectStatus(HttpStatus.SEE_OTHER);
      expect(identical(result, view), isTrue);
    });

    test('default redirect status is FOUND (302)', () {
      final view = PageView('template');
      expect(view.getRedirectStatus(), HttpStatus.FOUND);
    });

    test('addAttribute adds to model', () {
      final view = PageView('template')
        ..addAttribute('title', 'Welcome')
        ..addAttribute('count', 42);
      expect(view.getAttributes()['title'], 'Welcome');
      expect(view.getAttributes()['count'], 42);
    });

    test('addAttribute returns self for chaining', () {
      final view = PageView('template');
      final result = view.addAttribute('key', 'value');
      expect(identical(result, view), isTrue);
    });

    test('addAllAttributes merges map into model', () {
      final view = PageView('template')
        ..addAllAttributes({'a': 1, 'b': 'two', 'c': true});
      expect(view.getAttributes()['a'], 1);
      expect(view.getAttributes()['b'], 'two');
      expect(view.getAttributes()['c'], true);
    });

    test('addAllAttributes returns self for chaining', () {
      final view = PageView('template');
      final result = view.addAllAttributes({'x': 1});
      expect(identical(result, view), isTrue);
    });

    test('getAttributes returns unmodifiable map', () {
      final view = PageView('template')
        ..addAttribute('key', 'value');
      final attrs = view.getAttributes();
      expect(
        () => attrs['newKey'] = 'newValue',
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('redirect path defaults to null', () {
      final view = PageView('template');
      expect(view.getRedirectPath(), isNull);
    });

    test('fluent builder pattern', () {
      final view = PageView('templates/user/profile')
        ..setStatus(HttpStatus.OK)
        ..addAttribute('user', 'John')
        ..addAttribute('profile', 'admin')
        ..setRedirectPath('templates/errors/not-found')
        ..setRedirectStatus(HttpStatus.NOT_FOUND);

      expect(view.getPath(), 'templates/user/profile');
      expect(view.getStatus(), HttpStatus.OK);
      expect(view.getAttributes()['user'], 'John');
      expect(view.getAttributes()['profile'], 'admin');
      expect(view.getRedirectPath(), 'templates/errors/not-found');
      expect(view.getRedirectStatus(), HttpStatus.NOT_FOUND);
    });

    test('toString contains key info', () {
      final view = PageView('test-path', HttpStatus.OK)
        ..addAttribute('key', 'value');
      final str = view.toString();
      expect(str, contains('test-path'));
      expect(str, contains('OK'));
    });

    test('REDIRECT_ATTRIBUTE constant', () {
      expect(View.REDIRECT_ATTRIBUTE, 'redirect:');
    });

    test('PageView CLASS static field', () {
      expect(PageView.CLASS, isNotNull);
    });
  });

  // =========================================================================
  // RedirectView
  // =========================================================================
  group('RedirectView', () {
    test('is a PageView', () {
      final view = RedirectView('/login');
      expect(view, isA<PageView>());
      expect(view, isA<View>());
    });

    test('stores path correctly', () {
      final view = RedirectView('/dashboard');
      expect(view.getPath(), '/dashboard');
    });

    test('inherits PageView behavior', () {
      final view = RedirectView('/profile')
        ..setStatus(HttpStatus.FOUND)
        ..addAttribute('reason', 'auth');

      expect(view.getPath(), '/profile');
      expect(view.getStatus(), HttpStatus.FOUND);
      expect(view.getAttributes()['reason'], 'auth');
    });
  });

  // =========================================================================
  // ViewContext / WebViewContext
  // =========================================================================
  group('ViewContext', () {
    test('CLASS static field exists', () {
      expect(ViewContext.CLASS, isNotNull);
    });

    test('WebViewContext delegates header to request', () {
      final mockReq = MockHttpRequest();
      mockReq.addHeader('Content-Type', 'application/json');
      final context = WebViewContext(mockReq);

      expect(context.getHeader('Content-Type'), 'application/json');
    });

    test('WebViewContext returns empty string for missing header', () {
      final mockReq = MockHttpRequest();
      final context = WebViewContext(mockReq);

      expect(context.getHeader('X-Missing'), '');
    });

    test('WebViewContext delegates session attribute to request', () {
      final mockReq = MockHttpRequest();
      final session = HttpSession.create();
      session.setAttribute('userId', 'user-123');
      mockReq.setSession(session);
      final context = WebViewContext(mockReq);

      expect(context.getSessionAttribute('userId'), 'user-123');
    });

    test('WebViewContext returns null for missing session attribute', () {
      final mockReq = MockHttpRequest();
      mockReq.setSession(HttpSession.create());
      final context = WebViewContext(mockReq);

      expect(context.getSessionAttribute('missing'), isNull);
    });

    test('WebViewContext returns null when session is null', () {
      final mockReq = MockHttpRequest();
      mockReq.setSession(null);
      final context = WebViewContext(mockReq);

      expect(context.getSessionAttribute('anything'), isNull);
    });

    test('WebViewContext delegates path variable to request', () {
      final mockReq = MockHttpRequest();
      mockReq.addPathVariable('id', '42');
      final context = WebViewContext(mockReq);

      expect(context.getPathVariable('id'), '42');
    });

    test('WebViewContext returns null for missing path variable', () {
      final mockReq = MockHttpRequest();
      final context = WebViewContext(mockReq);

      expect(context.getPathVariable('missing'), isNull);
    });

    test('WebViewContext delegates query param to request', () {
      final mockReq = MockHttpRequest();
      mockReq.addParameter('page', '1');
      final context = WebViewContext(mockReq);

      expect(context.getQueryParam('page'), '1');
    });

    test('WebViewContext returns null for missing query param', () {
      final mockReq = MockHttpRequest();
      final context = WebViewContext(mockReq);

      expect(context.getQueryParam('q'), isNull);
    });

    test('WebViewContext delegates attribute to request', () {
      final mockReq = MockHttpRequest();
      mockReq.setAttribute('startTime', DateTime(2025, 1, 1));
      final context = WebViewContext(mockReq);

      expect(context.getAttribute('startTime'), isA<DateTime>());
    });

    test('WebViewContext returns null for missing attribute', () {
      final mockReq = MockHttpRequest();
      final context = WebViewContext(mockReq);

      expect(context.getAttribute('missing'), isNull);
    });

    test('WebViewContext delegates cookie to request', () {
      final mockReq = MockHttpRequest();
      mockReq.getCookies().addCookie(HttpCookie('sessionId', 'abc123'));
      final context = WebViewContext(mockReq);

      expect(context.getCookie('sessionId'), 'abc123');
    });

    test('WebViewContext returns null for missing cookie', () {
      final mockReq = MockHttpRequest();
      final context = WebViewContext(mockReq);

      expect(context.getCookie('missing'), isNull);
    });

    test('setViewAttributes stores attributes', () {
      final mockReq = MockHttpRequest();
      final context = WebViewContext(mockReq);

      context.setViewAttributes({
        'title': 'Test Page',
        'count': 5,
        'active': true,
      });

      final attrs = context.getViewAttributes();
      expect(attrs['title'], 'Test Page');
      expect(attrs['count'], 5);
      expect(attrs['active'], true);
    });

    test('getViewAttributes returns unmodifiable map', () {
      final mockReq = MockHttpRequest();
      final context = WebViewContext(mockReq);

      context.setViewAttributes({'key': 'value'});
      final attrs = context.getViewAttributes();

      expect(
        () => attrs['newKey'] = 'newValue',
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('setViewAttributes overwrites previous attributes', () {
      final mockReq = MockHttpRequest();
      final context = WebViewContext(mockReq);

      context.setViewAttributes({'a': 1});
      context.setViewAttributes({'b': 2});

      final attrs = context.getViewAttributes();
      expect(attrs.containsKey('a'), isFalse);
      expect(attrs['b'], 2);
    });

    test('multiple data sources combined', () {
      final mockReq = MockHttpRequest();
      mockReq.addHeader('Accept-Language', 'en-US');
      mockReq.addPathVariable('id', '99');
      mockReq.addParameter('format', 'json');
      mockReq.setAttribute('traceId', 'trace-abc');

      final context = WebViewContext(mockReq);
      context.setViewAttributes({'user': 'Alice'});

      expect(context.getHeader('Accept-Language'), 'en-US');
      expect(context.getPathVariable('id'), '99');
      expect(context.getQueryParam('format'), 'json');
      expect(context.getAttribute('traceId'), 'trace-abc');
      expect(context.getViewAttributes()['user'], 'Alice');
    });
  });

  // =========================================================================
  // WebRequest
  // =========================================================================
  group('WebRequest', () {
    test('constructor stores request and response', () {
      final mockReq = MockHttpRequest();
      final mockRes = MockHttpResponse();
      final webReq = WebRequest(mockReq, mockRes);

      expect(webReq.getRequest(), same(mockReq));
      expect(webReq.getResponse(), same(mockRes));
    });

    test('getRequest returns ServerHttpRequest', () {
      final mockReq = MockHttpRequest();
      final mockRes = MockHttpResponse();
      final webReq = WebRequest(mockReq, mockRes);

      expect(webReq.getRequest(), isA<ServerHttpRequest>());
    });

    test('getResponse returns ServerHttpResponse', () {
      final mockReq = MockHttpRequest();
      final mockRes = MockHttpResponse();
      final webReq = WebRequest(mockReq, mockRes);

      expect(webReq.getResponse(), isA<ServerHttpResponse>());
    });

    test('getRequestedAt returns null for non-IoRequest', () {
      final mockReq = MockHttpRequest();
      final mockRes = MockHttpResponse();
      final webReq = WebRequest(mockReq, mockRes);

      expect(webReq.getRequestedAt(), isNull);
    });

    test('getCompletedAt returns null for non-IoRequest', () {
      final mockReq = MockHttpRequest();
      final mockRes = MockHttpResponse();
      final webReq = WebRequest(mockReq, mockRes);

      expect(webReq.getCompletedAt(), isNull);
    });

    test('getDuration returns null when timestamps unavailable', () {
      final mockReq = MockHttpRequest();
      final mockRes = MockHttpResponse();
      final webReq = WebRequest(mockReq, mockRes);

      expect(webReq.getDuration(), isNull);
    });

    test('equalizedProperties returns class identity', () {
      final mockReq1 = MockHttpRequest();
      final mockRes1 = MockHttpResponse();
      final mockReq2 = MockHttpRequest();
      final mockRes2 = MockHttpResponse();

      final webReq1 = WebRequest(mockReq1, mockRes1);
      final webReq2 = WebRequest(mockReq2, mockRes2);

      expect(webReq1.equalizedProperties(), [WebRequest]);
      expect(webReq2.equalizedProperties(), [WebRequest]);
    });

    test('two WebRequests are equal by class identity', () {
      final webReq1 = WebRequest(MockHttpRequest(), MockHttpResponse());
      final webReq2 = WebRequest(MockHttpRequest(), MockHttpResponse());

      expect(webReq1, equals(webReq2));
    });

    test('WebRequest has CLASS static field', () {
      expect(WebRequest.CLASS, isNotNull);
    });

    test('WebRequest can be constructed with mock request/response', () {
      final mockReq = MockHttpRequest();
      mockReq.setMethod(HttpMethod.POST);
      mockReq.setUri(Uri.parse('http://localhost:8080/api/users'));

      final mockRes = MockHttpResponse();
      final webReq = WebRequest(mockReq, mockRes);

      expect(webReq.getRequest().getMethod(), HttpMethod.POST);
      expect(webReq.getRequest().getUri().path, '/api/users');
    });
  });

  // =========================================================================
  // WebServer
  // =========================================================================
  group('WebServer', () {
    test('SERVER_PORT default is 8080', () {
      expect(WebServer.SERVER_PORT, 8080);
    });

    test('SERVER_HOST default is localhost', () {
      expect(WebServer.SERVER_HOST, 'localhost');
    });

    test('SERVER_HOST_PROPERTY_NAME is correct', () {
      expect(WebServer.SERVER_HOST_PROPERTY_NAME, 'server.host');
    });

    test('SERVER_PORT_PROPERTY_NAME is correct', () {
      expect(WebServer.SERVER_PORT_PROPERTY_NAME, 'server.port');
    });
  });

  // =========================================================================
  // Integration: ErrorPage + PageView relationship
  // =========================================================================
  group('ErrorPage + PageView Integration', () {
    test('ErrorPage extends PageView', () {
      final errorPage = ErrorPage('/errors/404.html', HttpStatus.NOT_FOUND);
      expect(errorPage, isA<PageView>());
      expect(errorPage, isA<View>());
    });

    test('ErrorPage can use PageView fluent API', () {
      final errorPage = ErrorPage('/errors/maintenance.html', HttpStatus.SERVICE_UNAVAILABLE)
        ..setRedirectPath('/errors/general.html')
        ..setRedirectStatus(HttpStatus.OK)
        ..addAttribute('maintenanceMessage', 'System update in progress')
        ..addAttribute('estimatedTime', '30 minutes');

      expect(errorPage.getPath(), '/errors/maintenance.html');
      expect(errorPage.getStatus(), HttpStatus.SERVICE_UNAVAILABLE);
      expect(errorPage.getRedirectPath(), '/errors/general.html');
      expect(errorPage.getRedirectStatus(), HttpStatus.OK);
      expect(errorPage.getAttributes()['maintenanceMessage'], 'System update in progress');
      expect(errorPage.getAttributes()['estimatedTime'], '30 minutes');
    });

    test('RedirectView is a View', () {
      final view = RedirectView('/login');
      expect(view, isA<View>());
    });
  });

  // =========================================================================
  // Edge cases
  // =========================================================================
  group('Edge Cases', () {
    test('PageView with empty path', () {
      final view = PageView('');
      expect(view.getPath(), '');
    });

    test('PageView with null attributes', () {
      final view = PageView('template');
      expect(view.getAttributes(), isEmpty);
    });

    test('ErrorPage with empty path', () {
      final page = ErrorPage('', HttpStatus.NOT_FOUND);
      expect(page.getPath(), '');
    });

    test('ErrorPage with null status', () {
      final page = ErrorPage('/errors/test.html');
      expect(page.getStatus(), HttpStatus.OK);
    });

    test('ViewContext with multiple cookies', () {
      final mockReq = MockHttpRequest();
      mockReq.getCookies().addCookie(HttpCookie('session', 'abc'));
      mockReq.getCookies().addCookie(HttpCookie('theme', 'dark'));
      final context = WebViewContext(mockReq);

      expect(context.getCookie('session'), 'abc');
      expect(context.getCookie('theme'), 'dark');
    });

    test('ErrorPages with multiple different statuses', () {
      final errorPages = ErrorPages();
      errorPages.addPage('/errors/400.html', HttpStatus.BAD_REQUEST);
      errorPages.addPage('/errors/401.html', HttpStatus.UNAUTHORIZED);
      errorPages.addPage('/errors/403.html', HttpStatus.FORBIDDEN);
      errorPages.addPage('/errors/500.html', HttpStatus.INTERNAL_SERVER_ERROR);

      final resolved = errorPages.getResolvedPages();
      expect(resolved, hasLength(4));

      final codes = resolved.map((p) => p.getStatus().getCode()).toList();
      expect(codes, [400, 401, 403, 500]);
    });

    test('ErrorPages framework page attribute detection', () {
      final eps = ErrorPages();
      final page = ErrorPage('/custom/404.html', HttpStatus.NOT_FOUND);
      page.addAttribute(ErrorPage.FRAMEWORK_ERROR_PAGE_IDENTIFIER, true);

      eps.add(page);
      final frameworkPages = eps.getFrameworkPages();
      expect(frameworkPages, hasLength(1));
    });
  });
}

// ---------------------------------------------------------------------------
// Test helper classes
// ---------------------------------------------------------------------------

class _TestRenderableView extends RenderableView {
  @override
  Future<String> render(ViewContext context) async {
    return '<h1>Hello from RenderableView</h1>';
  }
}

class _TestRenderableWebView extends RenderableWebView {
  @override
  Future<PageView> render(ViewContext context) async {
    return PageView('test/template')
      ..addAttribute('message', 'Hello from RenderableWebView');
  }
}
