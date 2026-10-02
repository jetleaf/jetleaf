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

import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_env/env.dart';
import 'package:test/test.dart';

import 'package:jetleaf_web/src/cors/cors_configuration.dart';
import 'package:jetleaf_web/src/cors/cors_filter.dart';
import 'package:jetleaf_web/src/cors/default_cors_configuration_manager.dart';
import 'package:jetleaf_web/src/http/http_cookie.dart';
import 'package:jetleaf_web/src/http/http_cookies.dart';
import 'package:jetleaf_web/src/http/http_headers.dart';
import 'package:jetleaf_web/src/http/http_method.dart';
import 'package:jetleaf_web/src/http/http_session.dart';
import 'package:jetleaf_web/src/http/http_status.dart';
import 'package:jetleaf_web/src/path/path_pattern.dart';
import 'package:jetleaf_web/src/path/path_pattern_parser_manager.dart';
import 'package:jetleaf_web/src/server/filter/filter.dart';
import 'package:jetleaf_web/src/server/handler_method.dart';
import 'package:jetleaf_web/src/server/server_http_request.dart';
import 'package:jetleaf_web/src/server/server_http_response.dart';

// ---------------------------------------------------------------------------
// 🧪 Mocks
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
  final List<HttpCookie> _cookies;
  final Map<String, String> _pathVariables;

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
        _parameterMap = {},
        _cookies = [],
        _pathVariables = {};

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
  HttpCookies getCookies() => HttpCookies.fromList(_cookies);

  @override
  HttpSession? getSession([bool create = true]) => null;

  @override
  String? getPathVariable(String name) => _pathVariables[name];

  @override
  Map<String, String> getPathVariables() => _pathVariables;

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
  void setReason(String message) {}

  @override
  Future<String> encodeRedirectUrl(String location) async => location;

  @override
  Future<void> sendRedirect(String encodedLocation) async {}
}

class MockOutputStream extends OutputStream {
  @override
  Future<void> writeByte(int b) async {}

  @override
  Future<void> writeObject(Object? obj) async {}
}

class MockFilterChain implements FilterChain {
  bool nextCalled = false;
  ServerHttpRequest? lastRequest;
  ServerHttpResponse? lastResponse;

  @override
  Future<void> next(ServerHttpRequest request, ServerHttpResponse response) async {
    nextCalled = true;
    lastRequest = request;
    lastResponse = response;
  }
}

class MockEnvironment extends Environment {
  final Map<String, dynamic> _properties = {};

  void setProperty(String key, dynamic value) => _properties[key] = value;

  @override
  T? getPropertyAs<T>(String name, Class<T> type, [T? defaultValue]) {
    final value = _properties[name];
    if (value is T) return value;
    if (value is String && T == bool) {
      return (value == 'true') as T?;
    }
    if (value is String && T == int) {
      return (int.tryParse(value) ?? defaultValue) as T?;
    }
    return defaultValue;
  }

  @override
  bool containsProperty(String name) => _properties.containsKey(name);

  @override
  String? getProperty(String name, [String? defaultValue]) =>
      _properties[name]?.toString() ?? defaultValue;

  @override
  List<String> getActiveProfiles() => [];

  @override
  List<String> getDefaultProfiles() => [];

  @override
  bool acceptsProfiles(Profiles profiles) => false;

  void setActiveProfiles(List<String> profiles) {}

  void setDefaultProfiles(List<String> profiles) {}

  void addActiveProfile(String profile) {}

  void addDefaultProfile(String profile) {}

  void merge(Environment other) {}

  @override
  String getRequiredProperty(String key) {
    final value = _properties[key];
    if (value != null) return value.toString();
    throw Exception('Property $key not found');
  }

  @override
  T getRequiredPropertyAs<T>(String key, Class<T> targetType) {
    final value = getPropertyAs<T>(key, targetType);
    if (value != null) return value;
    throw Exception('Property $key not found');
  }

  @override
  String resolvePlaceholders(String text) => text;

  String resolvePlaceholdersRecursively(String text) => text;

  @override
  String resolveRequiredPlaceholders(String text) => text;

  @override
  List<String> suggestions(String key) => [];

  @override
  String getPackageName() => 'test';
}

class MockCorsConfigurationManager implements CorsConfigurationManager {
  final Map<String, CorsConfiguration> _configs = {};
  CorsConfiguration? _defaultConfig;

  void setConfig(String path, CorsConfiguration config) => _configs[path] = config;
  void setDefaultConfig(CorsConfiguration config) => _defaultConfig = config;

  @override
  CorsConfiguration? getCorsConfiguration(ServerHttpRequest request) {
    final path = request.getRequestURI().path;
    return _configs[path] ?? _defaultConfig;
  }

  @override
  void configureFor(String pathPattern, CorsConfiguration corsConfig) {
    _configs[pathPattern] = corsConfig;
  }
}

// ---------------------------------------------------------------------------
// 🧪 Tests
// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  // CorsConfiguration
  // =========================================================================
  group('CorsConfiguration', () {
    group('Default Values', () {
      test('allowedOrigins defaults to wildcard', () {
        final config = CorsConfiguration();
        expect(config.allowedOrigins, equals(['*']));
      });

      test('allowedMethods defaults to GET, POST, PUT, DELETE, OPTIONS', () {
        final config = CorsConfiguration();
        expect(config.allowedMethods, equals(['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']));
      });

      test('allowedHeaders defaults to wildcard', () {
        final config = CorsConfiguration();
        expect(config.allowedHeaders, equals(['*']));
      });

      test('exposedHeaders defaults to empty list', () {
        final config = CorsConfiguration();
        expect(config.exposedHeaders, isEmpty);
      });

      test('allowCredentials defaults to false', () {
        final config = CorsConfiguration();
        expect(config.allowCredentials, isFalse);
      });

      test('maxAgeSeconds defaults to 86400 (1 day)', () {
        final config = CorsConfiguration();
        expect(config.maxAgeSeconds, equals(86400));
      });
    });

    group('Custom Values', () {
      test('accepts custom allowedOrigins', () {
        final config = CorsConfiguration(
          allowedOrigins: ['https://example.com', 'https://other.com'],
        );
        expect(config.allowedOrigins, equals(['https://example.com', 'https://other.com']));
      });

      test('accepts custom allowedMethods', () {
        final config = CorsConfiguration(
          allowedMethods: ['GET', 'PATCH'],
        );
        expect(config.allowedMethods, equals(['GET', 'PATCH']));
      });

      test('accepts custom allowedHeaders', () {
        final config = CorsConfiguration(
          allowedHeaders: ['Content-Type', 'Authorization'],
        );
        expect(config.allowedHeaders, equals(['Content-Type', 'Authorization']));
      });

      test('accepts custom exposedHeaders', () {
        final config = CorsConfiguration(
          exposedHeaders: ['X-Custom-Header', 'X-Rate-Limit'],
        );
        expect(config.exposedHeaders, equals(['X-Custom-Header', 'X-Rate-Limit']));
      });

      test('accepts allowCredentials true', () {
        final config = CorsConfiguration(allowCredentials: true);
        expect(config.allowCredentials, isTrue);
      });

      test('accepts custom maxAgeSeconds', () {
        final config = CorsConfiguration(maxAgeSeconds: 3600);
        expect(config.maxAgeSeconds, equals(3600));
      });
    });

    group('Immutability', () {
      test('fields are final and cannot be mutated', () {
        final config = CorsConfiguration();
        expect(
          () => (config as dynamic).allowedOrigins = ['https://hack.com'],
          throwsA(anything),
        );
      });

      test('list fields are const by default', () {
        final config = CorsConfiguration();
        expect(config.allowedOrigins, isA<List<String>>());
        expect(config.allowedOrigins, isNot(isEmpty));
      });
    });

    group('Edge Cases', () {
      test('empty allowedOrigins list', () {
        final config = CorsConfiguration(allowedOrigins: const []);
        expect(config.allowedOrigins, isEmpty);
      });

      test('empty allowedMethods list', () {
        final config = CorsConfiguration(allowedMethods: const []);
        expect(config.allowedMethods, isEmpty);
      });

      test('empty allowedHeaders list', () {
        final config = CorsConfiguration(allowedHeaders: const []);
        expect(config.allowedHeaders, isEmpty);
      });

      test('single origin', () {
        final config = CorsConfiguration(allowedOrigins: const ['https://single.com']);
        expect(config.allowedOrigins.length, equals(1));
      });

      test('multiple exposedHeaders', () {
        final config = CorsConfiguration(
          exposedHeaders: const ['X-A', 'X-B', 'X-C'],
        );
        expect(config.exposedHeaders.length, equals(3));
      });

      test('maxAgeSeconds of 0', () {
        final config = CorsConfiguration(maxAgeSeconds: 0);
        expect(config.maxAgeSeconds, equals(0));
      });

      test('maxAgeSeconds of 31536000 (1 year)', () {
        final config = CorsConfiguration(maxAgeSeconds: 31536000);
        expect(config.maxAgeSeconds, equals(31536000));
      });
    });
  });

  // =========================================================================
  // CorsConfigurationSource
  // =========================================================================
  group('CorsConfigurationSource', () {
    test('can be implemented to return null', () {
      final source = _NullCorsConfigurationSource();
      final request = MockServerHttpRequest();
      expect(source.getCorsConfiguration(request), isNull);
    });

    test('can be implemented to return a configuration', () {
      final source = _FixedCorsConfigurationSource(
        CorsConfiguration(allowedOrigins: const ['https://trusted.com']),
      );
      final request = MockServerHttpRequest();
      final config = source.getCorsConfiguration(request);
      expect(config, isNotNull);
      expect(config!.allowedOrigins, equals(['https://trusted.com']));
    });
  });

  // =========================================================================
  // CorsConfigurationManager constants
  // =========================================================================
  group('CorsConfigurationManager Constants', () {
    test('PREFIX is correct', () {
      expect(CorsConfigurationManager.PREFIX, equals('jetleaf.web.cors'));
    });

    test('ALLOWED_ORIGINS_PROPERTY_NAME is correct', () {
      expect(
        CorsConfigurationManager.ALLOWED_ORIGINS_PROPERTY_NAME,
        equals('jetleaf.web.cors.allowed-origins'),
      );
    });

    test('ALLOWED_METHODS_PROPERTY_NAME is correct', () {
      expect(
        CorsConfigurationManager.ALLOWED_METHODS_PROPERTY_NAME,
        equals('jetleaf.web.cors.allowed-methods'),
      );
    });

    test('ALLOWED_HEADERS_PROPERTY_NAME is correct', () {
      expect(
        CorsConfigurationManager.ALLOWED_HEADERS_PROPERTY_NAME,
        equals('jetleaf.web.cors.allowed-headers'),
      );
    });

    test('EXPOSED_HEADERS_PROPERTY_NAME is correct', () {
      expect(
        CorsConfigurationManager.EXPOSED_HEADERS_PROPERTY_NAME,
        equals('jetleaf.web.cors.exposed-headers'),
      );
    });

    test('ALLOW_CREDENTIALS_PROPERTY_NAME is correct', () {
      expect(
        CorsConfigurationManager.ALLOW_CREDENTIALS_PROPERTY_NAME,
        equals('jetleaf.web.cors.allow-credentials'),
      );
    });

    test('MAX_AGE_PROPERTY_NAME is correct', () {
      expect(
        CorsConfigurationManager.MAX_AGE_PROPERTY_NAME,
        equals('jetleaf.web.cors.max-age'),
      );
    });

    test('ENABLED_PROPERTY_NAME is correct', () {
      expect(
        CorsConfigurationManager.ENABLED_PROPERTY_NAME,
        equals('jetleaf.web.cors.enabled'),
      );
    });
  });

  // =========================================================================
  // CorsFilter
  // =========================================================================
  group('CorsFilter', () {
    late MockCorsConfigurationManager manager;
    late MockServerHttpRequest request;
    late MockServerHttpResponse response;
    late MockFilterChain chain;
    late MockEnvironment environment;

    setUp(() {
      manager = MockCorsConfigurationManager();
      request = MockServerHttpRequest(path: '/api/test');
      response = MockServerHttpResponse();
      chain = MockFilterChain();
      environment = MockEnvironment();
    });

    group('Order', () {
      test('returns HIGHEST_PRECEDENCE', () {
        final filter = CorsFilter(manager);
        expect(filter.getOrder(), equals(Ordered.HIGHEST_PRECEDENCE));
      });
    });

    group('equalizedProperties', () {
      test('returns CorsFilter type', () {
        final filter = CorsFilter(manager);
        expect(filter.equalizedProperties(), equals([CorsFilter]));
      });
    });

    group('setEnvironment', () {
      test('sets the environment without throwing', () {
        final filter = CorsFilter(manager);
        expect(() => filter.setEnvironment(environment), returnsNormally);
      });
    });

    group('doFilter - CORS Disabled', () {
      test('passes request through when CORS is disabled', () async {
        environment.setProperty(CorsConfigurationManager.ENABLED_PROPERTY_NAME, 'false');
        final filter = CorsFilter(manager);
        filter.setEnvironment(environment);

        await filter.doFilter(request, response, chain);

        expect(chain.nextCalled, isTrue);
        expect(response.getStatus(), isNull);
      });

      test('passes request through when CORS enabled property is not set', () async {
        final filter = CorsFilter(manager);
        filter.setEnvironment(environment);

        await filter.doFilter(request, response, chain);

        expect(chain.nextCalled, isTrue);
      });
    });

    group('doFilter - No Configuration', () {
      test('passes request through when no CORS config is found', () async {
        environment.setProperty(CorsConfigurationManager.ENABLED_PROPERTY_NAME, 'true');
        final filter = CorsFilter(manager);
        filter.setEnvironment(environment);

        await filter.doFilter(request, response, chain);

        expect(chain.nextCalled, isTrue);
        expect(response.getStatus(), isNull);
      });
    });

    group('doFilter - CORS Enabled with Config', () {
      test('applies CORS headers to response', () async {
        environment.setProperty(CorsConfigurationManager.ENABLED_PROPERTY_NAME, 'true');
        manager.setDefaultConfig(CorsConfiguration(
          allowedOrigins: const ['https://example.com'],
          allowedMethods: const ['GET', 'POST'],
          allowedHeaders: const ['Content-Type'],
          exposedHeaders: const ['X-Custom'],
          allowCredentials: true,
          maxAgeSeconds: 3600,
        ));

        final filter = CorsFilter(manager);
        filter.setEnvironment(environment);

        request = MockServerHttpRequest(
          path: '/api/test',
          origin: 'https://example.com',
        );

        await filter.doFilter(request, response, chain);

        expect(chain.nextCalled, isTrue);
        expect(response.getHeaders().getAccessControlAllowOrigin(), equals('https://example.com'));
        expect(response.getHeaders().getAccessControlAllowCredentials(), isTrue);
      });

      test('continues chain for non-preflight request', () async {
        environment.setProperty(CorsConfigurationManager.ENABLED_PROPERTY_NAME, 'true');
        manager.setDefaultConfig(CorsConfiguration(
          allowedOrigins: const ['https://example.com'],
        ));

        final filter = CorsFilter(manager);
        filter.setEnvironment(environment);

        request = MockServerHttpRequest(
          method: 'GET',
          path: '/api/test',
          origin: 'https://example.com',
        );

        await filter.doFilter(request, response, chain);

        expect(chain.nextCalled, isTrue);
        expect(response.getStatus(), isNull);
      });
    });

    group('doFilter - Preflight Requests', () {
      test('handles OPTIONS preflight request and returns 204', () async {
        environment.setProperty(CorsConfigurationManager.ENABLED_PROPERTY_NAME, 'true');
        manager.setDefaultConfig(CorsConfiguration(
          allowedOrigins: const ['https://example.com'],
          allowedMethods: const ['POST', 'PUT'],
          allowedHeaders: const ['Content-Type'],
        ));

        final filter = CorsFilter(manager);
        filter.setEnvironment(environment);

        request = MockServerHttpRequest(
          method: 'OPTIONS',
          path: '/api/test',
          origin: 'https://example.com',
          headers: {
            'Origin': 'https://example.com',
            'Access-Control-Request-Method': 'POST',
          },
        );

        await filter.doFilter(request, response, chain);

        expect(chain.nextCalled, isFalse);
        expect(response.getStatus(), equals(HttpStatus.NO_CONTENT));
      });

      test('does not handle OPTIONS without Origin header', () async {
        environment.setProperty(CorsConfigurationManager.ENABLED_PROPERTY_NAME, 'true');
        manager.setDefaultConfig(CorsConfiguration(
          allowedOrigins: const ['*'],
        ));

        final filter = CorsFilter(manager);
        filter.setEnvironment(environment);

        request = MockServerHttpRequest(
          method: 'OPTIONS',
          path: '/api/test',
          headers: {
            'Access-Control-Request-Method': 'POST',
          },
        );

        await filter.doFilter(request, response, chain);

        expect(chain.nextCalled, isTrue);
      });

      test('does not handle OPTIONS without Access-Control-Request-Method', () async {
        environment.setProperty(CorsConfigurationManager.ENABLED_PROPERTY_NAME, 'true');
        manager.setDefaultConfig(CorsConfiguration(
          allowedOrigins: const ['*'],
        ));

        final filter = CorsFilter(manager);
        filter.setEnvironment(environment);

        request = MockServerHttpRequest(
          method: 'OPTIONS',
          path: '/api/test',
          origin: 'https://example.com',
          headers: {
            'Origin': 'https://example.com',
          },
        );

        await filter.doFilter(request, response, chain);

        expect(chain.nextCalled, isTrue);
      });
    });

    group('doFilter - Origin Matching', () {
      test('sets Access-Control-Allow-Origin for matching origin', () async {
        environment.setProperty(CorsConfigurationManager.ENABLED_PROPERTY_NAME, 'true');
        manager.setDefaultConfig(CorsConfiguration(
          allowedOrigins: const ['https://trusted.com'],
        ));

        final filter = CorsFilter(manager);
        filter.setEnvironment(environment);

        request = MockServerHttpRequest(
          path: '/api/test',
          origin: 'https://trusted.com',
        );

        await filter.doFilter(request, response, chain);

        expect(
          response.getHeaders().getAccessControlAllowOrigin(),
          equals('https://trusted.com'),
        );
      });

      test('does not set Access-Control-Allow-Origin for non-matching origin', () async {
        environment.setProperty(CorsConfigurationManager.ENABLED_PROPERTY_NAME, 'true');
        manager.setDefaultConfig(CorsConfiguration(
          allowedOrigins: const ['https://trusted.com'],
        ));

        final filter = CorsFilter(manager);
        filter.setEnvironment(environment);

        request = MockServerHttpRequest(
          path: '/api/test',
          origin: 'https://evil.com',
        );

        await filter.doFilter(request, response, chain);

        expect(response.getHeaders().getAccessControlAllowOrigin(), isNull);
      });

      test('sets origin to request origin when wildcard is present', () async {
        environment.setProperty(CorsConfigurationManager.ENABLED_PROPERTY_NAME, 'true');
        manager.setDefaultConfig(CorsConfiguration(
          allowedOrigins: const ['*'],
        ));

        final filter = CorsFilter(manager);
        filter.setEnvironment(environment);

        request = MockServerHttpRequest(
          path: '/api/test',
          origin: 'https://any-origin.com',
        );

        await filter.doFilter(request, response, chain);

        expect(
          response.getHeaders().getAccessControlAllowOrigin(),
          equals('https://any-origin.com'),
        );
      });
    });

    group('doFilter - Header Application', () {
      test('applies allowed methods header', () async {
        environment.setProperty(CorsConfigurationManager.ENABLED_PROPERTY_NAME, 'true');
        manager.setDefaultConfig(CorsConfiguration(
          allowedOrigins: const ['*'],
          allowedMethods: const ['GET', 'POST', 'DELETE'],
        ));

        final filter = CorsFilter(manager);
        filter.setEnvironment(environment);

        request = MockServerHttpRequest(path: '/api/test', origin: 'https://test.com');

        await filter.doFilter(request, response, chain);

        final methodsHeader = response.getHeaders().get(HttpHeaders.ACCESS_CONTROL_ALLOW_METHODS);
        expect(methodsHeader, isNotNull);
        final trimmedMethods = methodsHeader!.map((m) => m.trim()).toList();
        expect(trimmedMethods, contains('GET'));
        expect(trimmedMethods, contains('POST'));
        expect(trimmedMethods, contains('DELETE'));
      });

      test('applies allowed headers header', () async {
        environment.setProperty(CorsConfigurationManager.ENABLED_PROPERTY_NAME, 'true');
        manager.setDefaultConfig(CorsConfiguration(
          allowedOrigins: const ['*'],
          allowedHeaders: const ['Content-Type', 'Authorization'],
        ));

        final filter = CorsFilter(manager);
        filter.setEnvironment(environment);

        request = MockServerHttpRequest(path: '/api/test', origin: 'https://test.com');

        await filter.doFilter(request, response, chain);

        final headersValue = response.getHeaders().get(HttpHeaders.ACCESS_CONTROL_ALLOW_HEADERS);
        expect(headersValue, isNotNull);
        final trimmedHeaders = headersValue!.map((h) => h.trim()).toList();
        expect(trimmedHeaders, contains('Content-Type'));
        expect(trimmedHeaders, contains('Authorization'));
      });

      test('applies credentials header', () async {
        environment.setProperty(CorsConfigurationManager.ENABLED_PROPERTY_NAME, 'true');
        manager.setDefaultConfig(CorsConfiguration(
          allowedOrigins: const ['https://example.com'],
          allowCredentials: true,
        ));

        final filter = CorsFilter(manager);
        filter.setEnvironment(environment);

        request = MockServerHttpRequest(path: '/api/test', origin: 'https://example.com');

        await filter.doFilter(request, response, chain);

        expect(response.getHeaders().getAccessControlAllowCredentials(), isTrue);
      });

      test('applies exposed headers', () async {
        environment.setProperty(CorsConfigurationManager.ENABLED_PROPERTY_NAME, 'true');
        manager.setDefaultConfig(CorsConfiguration(
          allowedOrigins: const ['*'],
          exposedHeaders: const ['X-Request-Id', 'X-Rate-Limit'],
        ));

        final filter = CorsFilter(manager);
        filter.setEnvironment(environment);

        request = MockServerHttpRequest(path: '/api/test', origin: 'https://test.com');

        await filter.doFilter(request, response, chain);

        final exposed = response.getHeaders().get(HttpHeaders.ACCESS_CONTROL_EXPOSE_HEADERS);
        expect(exposed, isNotNull);
        expect(exposed, contains('X-Request-Id'));
        expect(exposed, contains('X-Rate-Limit'));
      });

      test('applies max-age header', () async {
        environment.setProperty(CorsConfigurationManager.ENABLED_PROPERTY_NAME, 'true');
        manager.setDefaultConfig(CorsConfiguration(
          allowedOrigins: const ['*'],
          maxAgeSeconds: 7200,
        ));

        final filter = CorsFilter(manager);
        filter.setEnvironment(environment);

        request = MockServerHttpRequest(path: '/api/test', origin: 'https://test.com');

        await filter.doFilter(request, response, chain);

        final maxAge = response.getHeaders().getFirst(HttpHeaders.ACCESS_CONTROL_MAX_AGE);
        expect(maxAge, equals('7200'));
      });
    });

    group('doFilter - Empty Origins', () {
      test('handles empty allowedOrigins list', () async {
        environment.setProperty(CorsConfigurationManager.ENABLED_PROPERTY_NAME, 'true');
        manager.setDefaultConfig(CorsConfiguration(
          allowedOrigins: const [],
        ));

        final filter = CorsFilter(manager);
        filter.setEnvironment(environment);

        request = MockServerHttpRequest(path: '/api/test', origin: 'https://test.com');

        await filter.doFilter(request, response, chain);

        expect(chain.nextCalled, isTrue);
        expect(response.getHeaders().getAccessControlAllowOrigin(), isNull);
      });
    });

    group('doFilter - Multiple Methods', () {
      test('allows all standard methods', () async {
        environment.setProperty(CorsConfigurationManager.ENABLED_PROPERTY_NAME, 'true');
        manager.setDefaultConfig(CorsConfiguration(
          allowedOrigins: const ['*'],
          allowedMethods: const ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS'],
        ));

        final filter = CorsFilter(manager);
        filter.setEnvironment(environment);

        request = MockServerHttpRequest(path: '/api/test', origin: 'https://test.com');

        await filter.doFilter(request, response, chain);

        final methodsHeader = response.getHeaders().get(HttpHeaders.ACCESS_CONTROL_ALLOW_METHODS);
        expect(methodsHeader, isNotNull);
        final trimmedMethods = methodsHeader!.map((m) => m.trim()).toList();
        expect(trimmedMethods, contains('GET'));
        expect(trimmedMethods, contains('POST'));
        expect(trimmedMethods, contains('PUT'));
        expect(trimmedMethods, contains('DELETE'));
        expect(trimmedMethods, contains('PATCH'));
        expect(trimmedMethods, contains('HEAD'));
        expect(trimmedMethods, contains('OPTIONS'));
      });
    });
  });

  // =========================================================================
  // DefaultCorsConfigurationManager
  // =========================================================================
  group('DefaultCorsConfigurationManager', () {
    late DefaultCorsConfigurationManager manager;
    late PathPatternParserManager parserManager;

    setUp(() {
      parserManager = PathPatternParserManager();
      manager = DefaultCorsConfigurationManager(parserManager);
    });

    group('configureFor', () {
      test('registers configuration for a path pattern', () {
        final config = CorsConfiguration(
          allowedOrigins: const ['https://example.com'],
        );

        manager.configureFor('/api/**', config);

        final request = MockServerHttpRequest(path: '/api/users');
        final result = manager.getCorsConfiguration(request);

        expect(result, isNotNull);
        expect(result!.allowedOrigins, equals(['https://example.com']));
      });

      test('registers configuration for exact path', () {
        final config = CorsConfiguration(
          allowedOrigins: const ['https://specific.com'],
          maxAgeSeconds: 1800,
        );

        manager.configureFor('/api/exact', config);

        final request = MockServerHttpRequest(path: '/api/exact');
        final result = manager.getCorsConfiguration(request);

        expect(result, isNotNull);
        expect(result!.allowedOrigins, equals(['https://specific.com']));
        expect(result.maxAgeSeconds, equals(1800));
      });

      test('replaces existing configuration for same pattern', () {
        final config1 = CorsConfiguration(allowedOrigins: const ['https://first.com']);
        final config2 = CorsConfiguration(allowedOrigins: const ['https://second.com']);

        manager.configureFor('/api/**', config1);
        manager.configureFor('/api/**', config2);

        final request = MockServerHttpRequest(path: '/api/test');
        final result = manager.getCorsConfiguration(request);

        expect(result, isNotNull);
        expect(result!.allowedOrigins, equals(['https://second.com']));
      });
    });

    group('getCorsConfiguration', () {
      test('returns null when no configuration is registered', () {
        final request = MockServerHttpRequest(path: '/api/test');
        final result = manager.getCorsConfiguration(request);
        expect(result, isNull);
      });

      test('matches pattern-based paths', () {
        manager.configureFor('/api/**', CorsConfiguration(
          allowedOrigins: const ['https://api.com'],
        ));

        final request = MockServerHttpRequest(path: '/api/users');
        final result = manager.getCorsConfiguration(request);
        expect(result, isNotNull);
        expect(result!.allowedOrigins, equals(['https://api.com']));
      });

      test('matches static paths', () {
        manager.configureFor('/health', CorsConfiguration(
          allowedOrigins: const ['*'],
        ));

        final request = MockServerHttpRequest(path: '/health');
        final result = manager.getCorsConfiguration(request);
        expect(result, isNotNull);
      });

      test('does not match unrelated paths', () {
        manager.configureFor('/api/**', CorsConfiguration(
          allowedOrigins: const ['https://api.com'],
        ));

        final request = MockServerHttpRequest(path: '/web/test');
        final result = manager.getCorsConfiguration(request);
        expect(result, isNull);
      });

      test('returns first matching pattern', () {
        manager.configureFor('/api/**', CorsConfiguration(
          allowedOrigins: const ['https://api.com'],
          maxAgeSeconds: 3600,
        ));

        manager.configureFor('/api/v1/**', CorsConfiguration(
          allowedOrigins: const ['https://v1.com'],
          maxAgeSeconds: 1800,
        ));

        final request = MockServerHttpRequest(path: '/api/v1/users');
        final result = manager.getCorsConfiguration(request);

        expect(result, isNotNull);
        expect(result!.maxAgeSeconds, equals(3600));
      });
    });

    group('Configuration Priority', () {
      test('path-specific config takes precedence over sources', () {
        manager.configureFor('/api/**', CorsConfiguration(
          allowedOrigins: const ['https://api.com'],
        ));

        final request = MockServerHttpRequest(path: '/api/test');
        final result = manager.getCorsConfiguration(request);

        expect(result, isNotNull);
        expect(result!.allowedOrigins, equals(['https://api.com']));
      });
    });

    group('Multiple Registrations', () {
      test('handles multiple different path patterns', () {
        manager.configureFor('/api/**', CorsConfiguration(
          allowedOrigins: const ['https://api.com'],
          maxAgeSeconds: 3600,
        ));

        manager.configureFor('/web/**', CorsConfiguration(
          allowedOrigins: const ['https://web.com'],
          maxAgeSeconds: 1800,
        ));

        manager.configureFor('/admin', CorsConfiguration(
          allowedOrigins: const ['https://admin.com'],
          allowCredentials: true,
        ));

        final apiRequest = MockServerHttpRequest(path: '/api/users');
        final webRequest = MockServerHttpRequest(path: '/web/pages');
        final adminRequest = MockServerHttpRequest(path: '/admin');

        expect(manager.getCorsConfiguration(apiRequest)!.allowedOrigins, equals(['https://api.com']));
        expect(manager.getCorsConfiguration(webRequest)!.allowedOrigins, equals(['https://web.com']));
        expect(manager.getCorsConfiguration(adminRequest)!.allowedOrigins, equals(['https://admin.com']));
      });
    });
  });

  // =========================================================================
  // CorsConfigurationRegistry (via DefaultCorsConfigurationManager)
  // =========================================================================
  group('CorsConfigurationRegistry', () {
    test('DefaultCorsConfigurationManager implements registry interface', () {
      final manager = DefaultCorsConfigurationManager(PathPatternParserManager());
      expect(manager, isA<CorsConfigurationRegistry>());
    });

    test('configureFor is callable on registry', () {
      final manager = DefaultCorsConfigurationManager(PathPatternParserManager());
      manager.configureFor('/test', CorsConfiguration());
      expect(manager.getCorsConfiguration(MockServerHttpRequest(path: '/test')), isNotNull);
    });
  });

  // =========================================================================
  // CorsConfigurationSource Interface
  // =========================================================================
  group('CorsConfigurationSource Interface', () {
    test('source can be implemented independently', () {
      final source = _DynamicCorsSource();
      final request = MockServerHttpRequest(
        path: '/api/test',
        origin: 'https://specific.com',
      );

      final config = source.getCorsConfiguration(request);
      expect(config, isNotNull);
      expect(config!.allowedOrigins, equals(['https://specific.com']));
    });

    test('source returns null for unknown origin', () {
      final source = _DynamicCorsSource();
      final request = MockServerHttpRequest(
        path: '/api/test',
        origin: 'https://unknown.com',
      );

      final config = source.getCorsConfiguration(request);
      expect(config, isNull);
    });
  });

  // =========================================================================
  // Integration-style Tests
  // =========================================================================
  group('Integration', () {
    test('full CORS flow with preflight', () async {
      final parserManager = PathPatternParserManager();
      final manager = DefaultCorsConfigurationManager(parserManager);

      manager.configureFor('/api/**', CorsConfiguration(
        allowedOrigins: const ['https://app.example.com'],
        allowedMethods: const ['GET', 'POST', 'PUT', 'DELETE'],
        allowedHeaders: const ['Content-Type', 'Authorization'],
        allowCredentials: true,
        maxAgeSeconds: 3600,
      ));

      final environment = MockEnvironment();
      environment.setProperty(CorsConfigurationManager.ENABLED_PROPERTY_NAME, 'true');

      final filter = CorsFilter(manager);
      filter.setEnvironment(environment);

      final preflightRequest = MockServerHttpRequest(
        method: 'OPTIONS',
        path: '/api/users',
        origin: 'https://app.example.com',
        headers: {
          'Origin': 'https://app.example.com',
          'Access-Control-Request-Method': 'POST',
        },
      );

      final response = MockServerHttpResponse();
      final chain = MockFilterChain();

      await filter.doFilter(preflightRequest, response, chain);

      expect(response.getStatus(), equals(HttpStatus.NO_CONTENT));
      expect(response.getHeaders().getAccessControlAllowOrigin(), equals('https://app.example.com'));
      expect(response.getHeaders().getAccessControlAllowCredentials(), isTrue);
      expect(chain.nextCalled, isFalse);
    });

    test('full CORS flow with actual request', () async {
      final parserManager = PathPatternParserManager();
      final manager = DefaultCorsConfigurationManager(parserManager);

      manager.configureFor('/api/**', CorsConfiguration(
        allowedOrigins: const ['https://app.example.com'],
        allowedMethods: const ['GET', 'POST'],
        allowedHeaders: const ['Content-Type'],
        maxAgeSeconds: 1800,
      ));

      final environment = MockEnvironment();
      environment.setProperty(CorsConfigurationManager.ENABLED_PROPERTY_NAME, 'true');

      final filter = CorsFilter(manager);
      filter.setEnvironment(environment);

      final getRequest = MockServerHttpRequest(
        method: 'GET',
        path: '/api/users',
        origin: 'https://app.example.com',
      );

      final response = MockServerHttpResponse();
      final chain = MockFilterChain();

      await filter.doFilter(getRequest, response, chain);

      expect(chain.nextCalled, isTrue);
      expect(response.getHeaders().getAccessControlAllowOrigin(), equals('https://app.example.com'));
        expect(response.getHeaders().getAccessControlMaxAge(), equals(1800));
    });

    test('CORS disabled allows all requests through', () async {
      final parserManager = PathPatternParserManager();
      final manager = DefaultCorsConfigurationManager(parserManager);

      manager.configureFor('/api/**', CorsConfiguration(
        allowedOrigins: const ['https://app.example.com'],
      ));

      final environment = MockEnvironment();
      environment.setProperty(CorsConfigurationManager.ENABLED_PROPERTY_NAME, 'false');

      final filter = CorsFilter(manager);
      filter.setEnvironment(environment);

      final request = MockServerHttpRequest(
        method: 'GET',
        path: '/api/users',
        origin: 'https://app.example.com',
      );

      final response = MockServerHttpResponse();
      final chain = MockFilterChain();

      await filter.doFilter(request, response, chain);

      expect(chain.nextCalled, isTrue);
      expect(response.getHeaders().getAccessControlAllowOrigin(), isNull);
    });

    test('request without Origin header is handled gracefully', () async {
      final parserManager = PathPatternParserManager();
      final manager = DefaultCorsConfigurationManager(parserManager);

      manager.configureFor('/api/**', CorsConfiguration(
        allowedOrigins: const ['https://app.example.com'],
      ));

      final environment = MockEnvironment();
      environment.setProperty(CorsConfigurationManager.ENABLED_PROPERTY_NAME, 'true');

      final filter = CorsFilter(manager);
      filter.setEnvironment(environment);

      final request = MockServerHttpRequest(
        method: 'GET',
        path: '/api/users',
        origin: '',
      );

      final response = MockServerHttpResponse();
      final chain = MockFilterChain();

      await filter.doFilter(request, response, chain);

      expect(chain.nextCalled, isTrue);
    });
  });
}

// ---------------------------------------------------------------------------
// 🧪 Helper Classes
// ---------------------------------------------------------------------------

class _NullCorsConfigurationSource implements CorsConfigurationSource {
  @override
  CorsConfiguration? getCorsConfiguration(ServerHttpRequest request) => null;
}

class _FixedCorsConfigurationSource implements CorsConfigurationSource {
  final CorsConfiguration? _config;

  _FixedCorsConfigurationSource(this._config);

  @override
  CorsConfiguration? getCorsConfiguration(ServerHttpRequest request) => _config;
}

class _DynamicCorsSource implements CorsConfigurationSource {
  @override
  CorsConfiguration? getCorsConfiguration(ServerHttpRequest request) {
    final origin = request.getOrigin();
    if (origin == 'https://specific.com') {
      return CorsConfiguration(
        allowedOrigins: [origin],
        allowedMethods: const ['GET'],
      );
    }
    return null;
  }
}
