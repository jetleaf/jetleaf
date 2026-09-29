import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_env/src/property_source/mutable_property_sources.dart';

import 'package:jetleaf_web/src/csrf/csrf_token.dart';
import 'package:jetleaf_web/src/csrf/csrf_token_repository.dart';
import 'package:jetleaf_web/src/csrf/csrf_token_repository_manager.dart';
import 'package:jetleaf_web/src/csrf/csrf_filter.dart';
import 'package:jetleaf_web/src/http/http_cookies.dart';
import 'package:jetleaf_web/src/http/http_headers.dart';
import 'package:jetleaf_web/src/http/http_method.dart';
import 'package:jetleaf_web/src/http/http_session.dart';
import 'package:jetleaf_web/src/http/http_status.dart';
import 'package:jetleaf_web/src/path/path_pattern.dart';
import 'package:jetleaf_web/src/server/handler_method.dart';
import 'package:jetleaf_web/src/server/server_http_request.dart';
import 'package:jetleaf_web/src/server/server_http_response.dart';
import 'package:jetleaf_web/src/server/filter/filter.dart';

// ---------------------------------------------------------------------------
// Mock / Fake Implementations
// ---------------------------------------------------------------------------

class _FakeHttpRequest implements ServerHttpRequest {
  final Map<String, Object> _attributes = {};
  final Map<String, String> _headers = {};
  final Map<String, String> _parameters = {};
  HttpMethod _method = HttpMethod.GET;

  void setMethod(HttpMethod method) => _method = method;
  void setHeader(String name, String value) => _headers[name] = value;
  void setParameter(String name, String value) => _parameters[name] = value;

  @override
  HttpMethod getMethod() => _method;

  @override
  Object? getAttribute(String name) => _attributes[name];

  @override
  void setAttribute(String name, Object value) => _attributes[name] = value;

  @override
  void removeAttribute(String name) => _attributes.remove(name);

  @override
  Set<String> getAttributeNames() => _attributes.keys.toSet();

  @override
  HttpHeaders getHeaders() {
    final h = HttpHeaders();
    _headers.forEach((k, v) => h.set(k, v));
    return h;
  }

  @override
  String? getParameter(String name) => _parameters[name];

  @override
  Map<String, Object> getAttributes() => Map.unmodifiable(_attributes);

  @override
  String getContextPath() => '';
  @override
  void setContextPath(String contextPath) {}
  @override
  Uri getRequestURI() => Uri.parse('/');
  @override
  Uri getUri() => Uri.parse('http://localhost/');
  @override
  String? getQueryString() => null;
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
  void setRequestUrl(String requestUrl) {}
  @override
  String? getRequestUrl() => null;
  @override
  int getContentLength() => 0;
  @override
  void setHandlerContext(HandlerMethod handler, PathPattern pattern) {}
  @override
  String getOrigin() => 'http://localhost';
  @override
  void setHeaders(HttpHeaders headers) {}
  @override
  InputStream getBody() => throw UnimplementedError();
}

class _FakeHttpResponse implements ServerHttpResponse {
  HttpStatus? _status;
  final bool _committed = false;
  final HttpHeaders _headers = HttpHeaders();

  @override
  void setStatus(HttpStatus httpStatus) {
    _status = httpStatus;
  }

  @override
  HttpStatus? getStatus() => _status;

  @override
  bool isCommitted() => _committed;

  @override
  void setReason(String message) {}

  @override
  Future<String> encodeRedirectUrl(String location) async => location;

  @override
  Future<void> sendRedirect(String encodedLocation) async {}

  @override
  HttpHeaders getHeaders() => _headers;

  @override
  void setHeaders(HttpHeaders headers) {}

  @override
  OutputStream getBody() => throw UnimplementedError();
}

class _FakeFilterChain implements FilterChain {
  bool nextCalled = false;

  @override
  Future<void> next(ServerHttpRequest request, ServerHttpResponse response) async {
    nextCalled = true;
  }
}

/// A minimal concrete [Environment] for testing property resolution.
class _TestEnvironment extends AbstractEnvironment {
  final Map<String, String?> _props = {};

  _TestEnvironment() : super();

  void setProperty(String key, String? value) => _props[key] = value;

  @override
  void customizePropertySources(MutablePropertySources sources) {}

  @override
  String? getProperty(String key, [String? defaultValue]) =>
      _props[key] ?? defaultValue;

  @override
  bool containsProperty(String key) => _props.containsKey(key);

  @override
  String getRequiredProperty(String key) {
    final value = _props[key];
    if (value == null) {
      throw StateError('Missing property: $key');
    }
    return value;
  }

  @override
  String resolvePlaceholders(String text) => text;

  @override
  String resolveRequiredPlaceholders(String text) => text;

  @override
  List<String> suggestions(String key) => [];

  @override
  String getPackageName() => PackageNames.ENV;
}

class _FakeCsrfTokenRepositoryManager implements CsrfTokenRepositoryManager {
  final CsrfTokenRepository _repository;

  const _FakeCsrfTokenRepositoryManager(this._repository);

  @override
  CsrfTokenRepository getRepository() => _repository;
}

/// In-memory CSRF token repository for integration tests.
///
/// Unlike [RequestAttributeCsrfTokenRepository] which stores tokens per-request,
/// this stores a single token that persists across separate request objects.
class _InMemoryCsrfTokenRepository implements CsrfTokenRepository {
  CsrfToken? _token;

  @override
  CsrfToken generateToken(ServerHttpRequest request) {
    return CsrfToken(
      token: Uuid.randomUuid().toString(),
      headerName: CsrfTokenRepository.DEFAULT_CSRF_HEADER_NAME,
      parameterName: CsrfTokenRepository.DEFAULT_CSRF_PARAMETER_NAME,
    );
  }

  @override
  void saveToken(CsrfToken token, ServerHttpRequest request, ServerHttpResponse response) {
    _token = token;
  }

  @override
  CsrfToken? loadToken(ServerHttpRequest request) => _token;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  // CsrfToken
  // =========================================================================
  group('CsrfToken', () {
    test('stores and returns token value', () {
      final token = CsrfToken(
        token: 'abc123def456',
        headerName: 'X-CSRF-TOKEN',
        parameterName: '_csrf',
      );

      expect(token.getToken(), 'abc123def456');
    });

    test('stores and returns header name', () {
      final token = CsrfToken(
        token: 'tok',
        headerName: 'X-XSRF-TOKEN',
        parameterName: '_csrf',
      );

      expect(token.getHeaderName(), 'X-XSRF-TOKEN');
    });

    test('stores and returns parameter name', () {
      final token = CsrfToken(
        token: 'tok',
        headerName: 'X-CSRF-TOKEN',
        parameterName: 'csrf_param',
      );

      expect(token.getParameterName(), 'csrf_param');
    });

    test('uses default header name when not specified', () {
      final token = CsrfToken(token: 'tok');
      expect(token.getHeaderName(), CsrfTokenRepository.DEFAULT_CSRF_HEADER_NAME);
    });

    test('uses default parameter name when not specified', () {
      final token = CsrfToken(token: 'tok');
      expect(token.getParameterName(), CsrfTokenRepository.DEFAULT_CSRF_PARAMETER_NAME);
    });

    test('equality — identical tokens are equal', () {
      final a = CsrfToken(
        token: 'abc123',
        headerName: 'X-CSRF-TOKEN',
        parameterName: '_csrf',
      );
      final b = CsrfToken(
        token: 'abc123',
        headerName: 'X-CSRF-TOKEN',
        parameterName: '_csrf',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('equality — different token values are not equal', () {
      final a = CsrfToken(token: 'abc', headerName: 'X-CSRF-TOKEN', parameterName: '_csrf');
      final b = CsrfToken(token: 'xyz', headerName: 'X-CSRF-TOKEN', parameterName: '_csrf');

      expect(a, isNot(equals(b)));
    });

    test('equality — different header names are not equal', () {
      final a = CsrfToken(token: 'abc', headerName: 'X-CSRF-TOKEN', parameterName: '_csrf');
      final b = CsrfToken(token: 'abc', headerName: 'X-XSRF-TOKEN', parameterName: '_csrf');

      expect(a, isNot(equals(b)));
    });

    test('equality — different parameter names are not equal', () {
      final a = CsrfToken(token: 'abc', headerName: 'X-CSRF-TOKEN', parameterName: '_csrf');
      final b = CsrfToken(token: 'abc', headerName: 'X-CSRF-TOKEN', parameterName: 'csrf');

      expect(a, isNot(equals(b)));
    });

    test('equality — not equal to non-CsrfToken object', () {
      final token = CsrfToken(token: 'abc', headerName: 'X-CSRF-TOKEN', parameterName: '_csrf');
      expect(token, isNot(equals('abc')));
      expect(token, isNot(equals(42)));
    });

    test('toString includes header name and truncated token', () {
      final token = CsrfToken(
        token: 'abcdefghijklmnop',
        headerName: 'X-CSRF-TOKEN',
        parameterName: '_csrf',
      );

      final str = token.toString();
      expect(str, contains('X-CSRF-TOKEN'));
      expect(str, contains('abcdefgh'));
      expect(str, contains('_csrf'));
    });

    test('toString truncates token at 8 characters', () {
      final token = CsrfToken(
        token: '1234567890',
        headerName: 'H',
        parameterName: 'P',
      );

      expect(token.toString(), contains('12345678'));
      expect(token.toString(), isNot(contains('1234567890')));
    });
  });

  // =========================================================================
  // CsrfTokenRepository — RequestAttributeCsrfTokenRepository
  // =========================================================================
  group('RequestAttributeCsrfTokenRepository', () {
    late RequestAttributeCsrfTokenRepository repository;

    setUp(() {
      repository = const RequestAttributeCsrfTokenRepository();
    });

    test('generateToken returns a valid CsrfToken', () {
      final request = _FakeHttpRequest();
      final token = repository.generateToken(request);

      expect(token, isA<CsrfToken>());
      expect(token.getToken(), isNotEmpty);
      expect(token.getToken().length, greaterThanOrEqualTo(36));
    });

    test('generateToken produces unique tokens on successive calls', () {
      final request = _FakeHttpRequest();
      final token1 = repository.generateToken(request);
      final token2 = repository.generateToken(request);

      expect(token1.getToken(), isNot(equals(token2.getToken())));
    });

    test('generateToken sets default header and parameter names', () {
      final request = _FakeHttpRequest();
      final token = repository.generateToken(request);

      expect(token.getHeaderName(), CsrfTokenRepository.DEFAULT_CSRF_HEADER_NAME);
      expect(token.getParameterName(), CsrfTokenRepository.DEFAULT_CSRF_PARAMETER_NAME);
    });

    test('saveToken stores token as request attribute', () {
      final request = _FakeHttpRequest();
      final response = _FakeHttpResponse();
      final token = CsrfToken(token: 'test-token-value');

      repository.saveToken(token, request, response);

      final stored = request.getAttribute(CsrfTokenRepository.CSRF_TOKEN_ATTR_NAME);
      expect(stored, equals(token));
    });

    test('loadToken retrieves saved token', () {
      final request = _FakeHttpRequest();
      final response = _FakeHttpResponse();
      final token = CsrfToken(token: 'loadable-token');

      repository.saveToken(token, request, response);
      final loaded = repository.loadToken(request);

      expect(loaded, equals(token));
    });

    test('loadToken returns null when no token saved', () {
      final request = _FakeHttpRequest();
      final loaded = repository.loadToken(request);

      expect(loaded, isNull);
    });

    test('loadToken returns null when attribute is not a CsrfToken', () {
      final request = _FakeHttpRequest();
      request.setAttribute(CsrfTokenRepository.CSRF_TOKEN_ATTR_NAME, 'not-a-token');

      final loaded = repository.loadToken(request);
      expect(loaded, isNull);
    });

    test('saveToken overwrites previously saved token', () {
      final request = _FakeHttpRequest();
      final response = _FakeHttpResponse();
      final token1 = CsrfToken(token: 'first');
      final token2 = CsrfToken(token: 'second');

      repository.saveToken(token1, request, response);
      repository.saveToken(token2, request, response);

      final loaded = repository.loadToken(request);
      expect(loaded, equals(token2));
    });
  });

  // =========================================================================
  // CsrfTokenRepositoryManager — constants
  // =========================================================================
  group('CsrfTokenRepositoryManager constants', () {
    test('PREFIX is correct', () {
      expect(CsrfTokenRepositoryManager.PREFIX, 'jetleaf.web.csrf');
    });

    test('ENABLED_PROPERTY_NAME is correct', () {
      expect(CsrfTokenRepositoryManager.ENABLED_PROPERTY_NAME, 'jetleaf.web.csrf.enabled');
    });

    test('HEADER_NAME_PROPERTY_NAME is correct', () {
      expect(CsrfTokenRepositoryManager.HEADER_NAME_PROPERTY_NAME, 'jetleaf.web.csrf.header-name');
    });

    test('PARAMETER_NAME_PROPERTY_NAME is correct', () {
      expect(CsrfTokenRepositoryManager.PARAMETER_NAME_PROPERTY_NAME, 'jetleaf.web.csrf.parameter-name');
    });

    test('TOKEN_ATTR_NAME_PROPERTY_NAME is correct', () {
      expect(CsrfTokenRepositoryManager.TOKEN_ATTR_NAME_PROPERTY_NAME, 'jetleaf.web.csrf.token-attribute-name');
    });
  });

  // =========================================================================
  // CsrfTokenRepository constants
  // =========================================================================
  group('CsrfTokenRepository constants', () {
    test('CSRF_TOKEN_ATTR_NAME is _csrf', () {
      expect(CsrfTokenRepository.CSRF_TOKEN_ATTR_NAME, '_csrf');
    });

    test('DEFAULT_CSRF_HEADER_NAME is X-CSRF-TOKEN', () {
      expect(CsrfTokenRepository.DEFAULT_CSRF_HEADER_NAME, 'X-CSRF-TOKEN');
    });

    test('DEFAULT_CSRF_PARAMETER_NAME is _csrf', () {
      expect(CsrfTokenRepository.DEFAULT_CSRF_PARAMETER_NAME, '_csrf');
    });
  });

  // =========================================================================
  // CsrfFilter
  // =========================================================================
  group('CsrfFilter', () {
    late _FakeCsrfTokenRepositoryManager manager;
    late RequestAttributeCsrfTokenRepository repository;
    late _TestEnvironment env;

    setUp(() {
      repository = const RequestAttributeCsrfTokenRepository();
      manager = _FakeCsrfTokenRepositoryManager(repository);
      env = _TestEnvironment();
    });

    CsrfFilter createFilter({CsrfTokenRepositoryManager? mgr, _TestEnvironment? environment}) {
      final f = CsrfFilter(mgr ?? manager);
      f.setEnvironment(environment ?? env);
      return f;
    }

    // -----------------------------------------------------------------------
    // Disabled CSRF
    // -----------------------------------------------------------------------
    group('CSRF disabled', () {
      test('bypasses filter chain when CSRF disabled', () async {
        final request = _FakeHttpRequest();
        request.setMethod(HttpMethod.POST);
        final response = _FakeHttpResponse();
        final chain = _FakeFilterChain();

        // Default: property not set → enabled == null → disabled
        final filter = createFilter();
        await filter.doFilter(request, response, chain);

        expect(chain.nextCalled, isTrue);
      });

      test('bypasses filter chain when CSRF explicitly disabled', () async {
        env.setProperty(CsrfTokenRepositoryManager.ENABLED_PROPERTY_NAME, 'false');

        final request = _FakeHttpRequest();
        request.setMethod(HttpMethod.POST);
        final response = _FakeHttpResponse();
        final chain = _FakeFilterChain();

        final filter = createFilter();
        await filter.doFilter(request, response, chain);

        expect(chain.nextCalled, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // Enabled CSRF — safe methods
    // -----------------------------------------------------------------------
    group('Safe methods (GET, HEAD, OPTIONS, TRACE)', () {
      setUp(() {
        env.setProperty(CsrfTokenRepositoryManager.ENABLED_PROPERTY_NAME, 'true');
      });

      test('GET request generates and injects CSRF token', () async {
        final request = _FakeHttpRequest();
        request.setMethod(HttpMethod.GET);
        final response = _FakeHttpResponse();
        final chain = _FakeFilterChain();

        final filter = createFilter();
        await filter.doFilter(request, response, chain);

        expect(chain.nextCalled, isTrue);

        final token = request.getAttribute(CsrfTokenRepository.CSRF_TOKEN_ATTR_NAME);
        expect(token, isA<CsrfToken>());
      });

      test('HEAD request generates and injects CSRF token', () async {
        final request = _FakeHttpRequest();
        request.setMethod(HttpMethod.HEAD);
        final response = _FakeHttpResponse();
        final chain = _FakeFilterChain();

        final filter = createFilter();
        await filter.doFilter(request, response, chain);

        expect(chain.nextCalled, isTrue);
        final token = request.getAttribute(CsrfTokenRepository.CSRF_TOKEN_ATTR_NAME);
        expect(token, isA<CsrfToken>());
      });

      test('OPTIONS request generates and injects CSRF token', () async {
        final request = _FakeHttpRequest();
        request.setMethod(HttpMethod.OPTIONS);
        final response = _FakeHttpResponse();
        final chain = _FakeFilterChain();

        final filter = createFilter();
        await filter.doFilter(request, response, chain);

        expect(chain.nextCalled, isTrue);
        final token = request.getAttribute(CsrfTokenRepository.CSRF_TOKEN_ATTR_NAME);
        expect(token, isA<CsrfToken>());
      });

      test('TRACE request generates and injects CSRF token', () async {
        final request = _FakeHttpRequest();
        request.setMethod(HttpMethod.TRACE);
        final response = _FakeHttpResponse();
        final chain = _FakeFilterChain();

        final filter = createFilter();
        await filter.doFilter(request, response, chain);

        expect(chain.nextCalled, isTrue);
        final token = request.getAttribute(CsrfTokenRepository.CSRF_TOKEN_ATTR_NAME);
        expect(token, isA<CsrfToken>());
      });

      test('safe method reuses existing token if already saved', () async {
        final request = _FakeHttpRequest();
        request.setMethod(HttpMethod.GET);
        final response = _FakeHttpResponse();
        final chain = _FakeFilterChain();

        final existingToken = CsrfToken(token: 'pre-existing-token');
        repository.saveToken(existingToken, request, response);

        final filter = createFilter();
        await filter.doFilter(request, response, chain);

        final token = request.getAttribute(CsrfTokenRepository.CSRF_TOKEN_ATTR_NAME);
        expect(token, equals(existingToken));
      });
    });

    // -----------------------------------------------------------------------
    // Enabled CSRF — state-changing methods
    // -----------------------------------------------------------------------
    group('State-changing methods (POST, PUT, DELETE, PATCH)', () {
      setUp(() {
        env.setProperty(CsrfTokenRepositoryManager.ENABLED_PROPERTY_NAME, 'true');
      });

      test('POST with valid header token passes validation', () async {
        // Use in-memory repository so token persists across request objects
        final inMemoryRepo = _InMemoryCsrfTokenRepository();
        final mgr = _FakeCsrfTokenRepositoryManager(inMemoryRepo);

        // Generate and store token via GET (separate filter to avoid OncePerRequestFilter marker)
        final getFilter = createFilter(mgr: mgr);
        final getRequest = _FakeHttpRequest();
        getRequest.setMethod(HttpMethod.GET);
        await getFilter.doFilter(getRequest, _FakeHttpResponse(), _FakeFilterChain());

        final savedToken = getRequest.getAttribute(CsrfTokenRepository.CSRF_TOKEN_ATTR_NAME) as CsrfToken;

        // POST with correct header (new filter instance)
        final postFilter = createFilter(mgr: mgr);
        final postRequest = _FakeHttpRequest();
        postRequest.setMethod(HttpMethod.POST);
        postRequest.setHeader(savedToken.getHeaderName(), savedToken.getToken());
        final postChain = _FakeFilterChain();

        await postFilter.doFilter(postRequest, _FakeHttpResponse(), postChain);
        expect(postChain.nextCalled, isTrue);
      });

      test('POST with valid parameter token passes validation', () async {
        final inMemoryRepo = _InMemoryCsrfTokenRepository();
        final mgr = _FakeCsrfTokenRepositoryManager(inMemoryRepo);

        // Generate and store token via GET
        final getFilter = createFilter(mgr: mgr);
        final getRequest = _FakeHttpRequest();
        getRequest.setMethod(HttpMethod.GET);
        await getFilter.doFilter(getRequest, _FakeHttpResponse(), _FakeFilterChain());

        final savedToken = getRequest.getAttribute(CsrfTokenRepository.CSRF_TOKEN_ATTR_NAME) as CsrfToken;

        // POST with correct parameter
        final postFilter = createFilter(mgr: mgr);
        final postRequest = _FakeHttpRequest();
        postRequest.setMethod(HttpMethod.POST);
        postRequest.setParameter(savedToken.getParameterName(), savedToken.getToken());
        final postChain = _FakeFilterChain();

        await postFilter.doFilter(postRequest, _FakeHttpResponse(), postChain);
        expect(postChain.nextCalled, isTrue);
      });

      test('POST without token throws ForbiddenException', () async {
        final inMemoryRepo = _InMemoryCsrfTokenRepository();
        final mgr = _FakeCsrfTokenRepositoryManager(inMemoryRepo);

        // Seed token via GET
        final getFilter = createFilter(mgr: mgr);
        final getRequest = _FakeHttpRequest();
        getRequest.setMethod(HttpMethod.GET);
        await getFilter.doFilter(getRequest, _FakeHttpResponse(), _FakeFilterChain());

        // POST without any CSRF token
        final postFilter = createFilter(mgr: mgr);
        final postRequest = _FakeHttpRequest();
        postRequest.setMethod(HttpMethod.POST);
        final postChain = _FakeFilterChain();

        expect(
          () => postFilter.doFilter(postRequest, _FakeHttpResponse(), postChain),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('CSRF token validation failed'),
          )),
        );
      });

      test('POST with wrong token value throws ForbiddenException', () async {
        final inMemoryRepo = _InMemoryCsrfTokenRepository();
        final mgr = _FakeCsrfTokenRepositoryManager(inMemoryRepo);

        // Seed token via GET
        final getFilter = createFilter(mgr: mgr);
        final getRequest = _FakeHttpRequest();
        getRequest.setMethod(HttpMethod.GET);
        await getFilter.doFilter(getRequest, _FakeHttpResponse(), _FakeFilterChain());

        // POST with wrong token
        final postFilter = createFilter(mgr: mgr);
        final postRequest = _FakeHttpRequest();
        postRequest.setMethod(HttpMethod.POST);
        postRequest.setHeader('X-CSRF-TOKEN', 'wrong-token-value');
        final postChain = _FakeFilterChain();

        expect(
          () => postFilter.doFilter(postRequest, _FakeHttpResponse(), postChain),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('CSRF token validation failed'),
          )),
        );
      });

      test('PUT with valid header token passes', () async {
        final inMemoryRepo = _InMemoryCsrfTokenRepository();
        final mgr = _FakeCsrfTokenRepositoryManager(inMemoryRepo);

        final getFilter = createFilter(mgr: mgr);
        final getRequest = _FakeHttpRequest();
        getRequest.setMethod(HttpMethod.GET);
        await getFilter.doFilter(getRequest, _FakeHttpResponse(), _FakeFilterChain());
        final savedToken = getRequest.getAttribute(CsrfTokenRepository.CSRF_TOKEN_ATTR_NAME) as CsrfToken;

        final putFilter = createFilter(mgr: mgr);
        final putRequest = _FakeHttpRequest();
        putRequest.setMethod(HttpMethod.PUT);
        putRequest.setHeader(savedToken.getHeaderName(), savedToken.getToken());
        final putChain = _FakeFilterChain();

        await putFilter.doFilter(putRequest, _FakeHttpResponse(), putChain);
        expect(putChain.nextCalled, isTrue);
      });

      test('DELETE with valid header token passes', () async {
        final inMemoryRepo = _InMemoryCsrfTokenRepository();
        final mgr = _FakeCsrfTokenRepositoryManager(inMemoryRepo);

        final getFilter = createFilter(mgr: mgr);
        final getRequest = _FakeHttpRequest();
        getRequest.setMethod(HttpMethod.GET);
        await getFilter.doFilter(getRequest, _FakeHttpResponse(), _FakeFilterChain());
        final savedToken = getRequest.getAttribute(CsrfTokenRepository.CSRF_TOKEN_ATTR_NAME) as CsrfToken;

        final deleteFilter = createFilter(mgr: mgr);
        final deleteRequest = _FakeHttpRequest();
        deleteRequest.setMethod(HttpMethod.DELETE);
        deleteRequest.setHeader(savedToken.getHeaderName(), savedToken.getToken());
        final deleteChain = _FakeFilterChain();

        await deleteFilter.doFilter(deleteRequest, _FakeHttpResponse(), deleteChain);
        expect(deleteChain.nextCalled, isTrue);
      });

      test('PATCH with valid parameter token passes', () async {
        final inMemoryRepo = _InMemoryCsrfTokenRepository();
        final mgr = _FakeCsrfTokenRepositoryManager(inMemoryRepo);

        final getFilter = createFilter(mgr: mgr);
        final getRequest = _FakeHttpRequest();
        getRequest.setMethod(HttpMethod.GET);
        await getFilter.doFilter(getRequest, _FakeHttpResponse(), _FakeFilterChain());
        final savedToken = getRequest.getAttribute(CsrfTokenRepository.CSRF_TOKEN_ATTR_NAME) as CsrfToken;

        final patchFilter = createFilter(mgr: mgr);
        final patchRequest = _FakeHttpRequest();
        patchRequest.setMethod(HttpMethod.PATCH);
        patchRequest.setParameter(savedToken.getParameterName(), savedToken.getToken());
        final patchChain = _FakeFilterChain();

        await patchFilter.doFilter(patchRequest, _FakeHttpResponse(), patchChain);
        expect(patchChain.nextCalled, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // Header priority over parameter
    // -----------------------------------------------------------------------
    group('Header priority over parameter', () {
      setUp(() {
        env.setProperty(CsrfTokenRepositoryManager.ENABLED_PROPERTY_NAME, 'true');
      });

      test('header token takes precedence over parameter token', () async {
        final inMemoryRepo = _InMemoryCsrfTokenRepository();
        final mgr = _FakeCsrfTokenRepositoryManager(inMemoryRepo);

        final getFilter = createFilter(mgr: mgr);
        final getRequest = _FakeHttpRequest();
        getRequest.setMethod(HttpMethod.GET);
        await getFilter.doFilter(getRequest, _FakeHttpResponse(), _FakeFilterChain());
        final savedToken = getRequest.getAttribute(CsrfTokenRepository.CSRF_TOKEN_ATTR_NAME) as CsrfToken;

        // Correct header, wrong parameter
        final postFilter = createFilter(mgr: mgr);
        final postRequest = _FakeHttpRequest();
        postRequest.setMethod(HttpMethod.POST);
        postRequest.setHeader(savedToken.getHeaderName(), savedToken.getToken());
        postRequest.setParameter(savedToken.getParameterName(), 'wrong-param-token');
        final postChain = _FakeFilterChain();

        await postFilter.doFilter(postRequest, _FakeHttpResponse(), postChain);
        expect(postChain.nextCalled, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // Empty header falls through to parameter
    // -----------------------------------------------------------------------
    group('Empty header falls through to parameter', () {
      setUp(() {
        env.setProperty(CsrfTokenRepositoryManager.ENABLED_PROPERTY_NAME, 'true');
      });

      test('empty header value causes fallback to parameter', () async {
        final inMemoryRepo = _InMemoryCsrfTokenRepository();
        final mgr = _FakeCsrfTokenRepositoryManager(inMemoryRepo);

        final getFilter = createFilter(mgr: mgr);
        final getRequest = _FakeHttpRequest();
        getRequest.setMethod(HttpMethod.GET);
        await getFilter.doFilter(getRequest, _FakeHttpResponse(), _FakeFilterChain());
        final savedToken = getRequest.getAttribute(CsrfTokenRepository.CSRF_TOKEN_ATTR_NAME) as CsrfToken;

        // Empty header, correct parameter
        final postFilter = createFilter(mgr: mgr);
        final postRequest = _FakeHttpRequest();
        postRequest.setMethod(HttpMethod.POST);
        postRequest.setHeader(savedToken.getHeaderName(), '');
        postRequest.setParameter(savedToken.getParameterName(), savedToken.getToken());
        final postChain = _FakeFilterChain();

        await postFilter.doFilter(postRequest, _FakeHttpResponse(), postChain);
        expect(postChain.nextCalled, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // No saved token in repository
    // -----------------------------------------------------------------------
    group('No saved token in repository', () {
      setUp(() {
        env.setProperty(CsrfTokenRepositoryManager.ENABLED_PROPERTY_NAME, 'true');
      });

      test('POST without any saved token throws ForbiddenException', () async {
        final inMemoryRepo = _InMemoryCsrfTokenRepository();
        final mgr = _FakeCsrfTokenRepositoryManager(inMemoryRepo);

        final postFilter = createFilter(mgr: mgr);
        final postRequest = _FakeHttpRequest();
        postRequest.setMethod(HttpMethod.POST);
        postRequest.setHeader('X-CSRF-TOKEN', 'some-token');
        final postChain = _FakeFilterChain();

        expect(
          () => postFilter.doFilter(postRequest, _FakeHttpResponse(), postChain),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('CSRF token validation failed'),
          )),
        );
      });
    });

    // -----------------------------------------------------------------------
    // getOrder
    // -----------------------------------------------------------------------
    group('getOrder', () {
      test('returns HIGHEST_PRECEDENCE + 1', () {
        final filter = createFilter();
        expect(filter.getOrder(), Ordered.HIGHEST_PRECEDENCE + 1);
      });
    });

    // -----------------------------------------------------------------------
    // equalizedProperties
    // -----------------------------------------------------------------------
    group('equalizedProperties', () {
      test('returns list containing CsrfFilter type', () {
        final filter = createFilter();
        final props = filter.equalizedProperties();
        expect(props, contains(CsrfFilter));
      });
    });
  });

  // =========================================================================
  // Integration — full request lifecycle
  // =========================================================================
  group('Integration — full request lifecycle', () {
    test('GET then POST with token succeeds', () async {
      final testEnv = _TestEnvironment();
      testEnv.setProperty(CsrfTokenRepositoryManager.ENABLED_PROPERTY_NAME, 'true');

      final inMemoryRepo = _InMemoryCsrfTokenRepository();
      final mgr = _FakeCsrfTokenRepositoryManager(inMemoryRepo);

      // Step 1: GET request to obtain token
      final getFilter = CsrfFilter(mgr);
      getFilter.setEnvironment(testEnv);
      final getRequest = _FakeHttpRequest();
      getRequest.setMethod(HttpMethod.GET);
      final getChain = _FakeFilterChain();

      await getFilter.doFilter(getRequest, _FakeHttpResponse(), getChain);

      final token = getRequest.getAttribute(CsrfTokenRepository.CSRF_TOKEN_ATTR_NAME) as CsrfToken;
      expect(token, isNotNull);

      // Step 2: POST request with valid token (new filter instance)
      final postFilter = CsrfFilter(mgr);
      postFilter.setEnvironment(testEnv);
      final postRequest = _FakeHttpRequest();
      postRequest.setMethod(HttpMethod.POST);
      postRequest.setHeader(token.getHeaderName(), token.getToken());
      final postChain = _FakeFilterChain();

      await postFilter.doFilter(postRequest, _FakeHttpResponse(), postChain);

      expect(postChain.nextCalled, isTrue);
    });

    test('GET then POST without token is rejected', () async {
      final testEnv = _TestEnvironment();
      testEnv.setProperty(CsrfTokenRepositoryManager.ENABLED_PROPERTY_NAME, 'true');

      final inMemoryRepo = _InMemoryCsrfTokenRepository();
      final mgr = _FakeCsrfTokenRepositoryManager(inMemoryRepo);

      // Step 1: GET to seed token
      final getFilter = CsrfFilter(mgr);
      getFilter.setEnvironment(testEnv);
      final getRequest = _FakeHttpRequest();
      getRequest.setMethod(HttpMethod.GET);
      await getFilter.doFilter(getRequest, _FakeHttpResponse(), _FakeFilterChain());

      // Step 2: POST without token (new filter instance)
      final postFilter = CsrfFilter(mgr);
      postFilter.setEnvironment(testEnv);
      final postRequest = _FakeHttpRequest();
      postRequest.setMethod(HttpMethod.POST);
      final postChain = _FakeFilterChain();

      expect(
        () => postFilter.doFilter(postRequest, _FakeHttpResponse(), postChain),
        throwsA(isA<Exception>()),
      );
    });
  });
}
