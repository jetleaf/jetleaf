import 'dart:convert';
import 'dart:io';

import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_web/context.dart';


import 'package:jetleaf_security_example/_jetleaf/main.dart'
    show registerGeneratedArtifacts;
import 'package:jetleaf_security_example/main.dart' show SecurityDemoApplication;
import 'package:test/test.dart';

/// Exercises the security package through a real server and real requests.
void main() {
  late ConfigurableApplicationContext context;
  late Uri base;
  late HttpClient client;

  setUpAll(() async {
    final app = JetleafApplication(SecurityDemoApplication())
      ..setBannerMode(BannerMode.OFF)
      ..setApplicationType(ApplicationType.WEB)
      ..setAotRegistrar(registerGeneratedArtifacts);

    context = (await app.create([
      '--server.host=127.0.0.1',
      '--server.port=0',
    ]))!;

    base = (context as ServerWebApplicationContext).getWebServer().getUri()!;
    client = HttpClient();
  });

  tearDownAll(() async {
    client.close();
    await context.close();
  });

  Future<(int status, Map<String, Object?> body, HttpHeaders headers)> request(
    String method,
    String path, {
    Map<String, String> query = const {},
    Map<String, String> headers = const {},
  }) async {
    final uri = base.replace(path: path, queryParameters: query.isEmpty ? null : query);
    final req = await client.openUrl(method, uri);
    headers.forEach(req.headers.set);
    final response = await req.close();
    final text = await response.transform(utf8.decoder).join();
    final body = text.isEmpty
        ? <String, Object?>{}
        : jsonDecode(text) as Map<String, Object?>;
    return (response.statusCode, body, response.headers);
  }

  Future<(int status, Map<String, Object?> body, HttpHeaders headers)> get(
    String path, {
    Map<String, String> query = const {},
    Map<String, String> headers = const {},
  }) =>
      request('GET', path, query: query, headers: headers);

  Future<(int status, Map<String, Object?> body, HttpHeaders headers)> post(
    String path, {
    Map<String, String> query = const {},
  }) =>
      request('POST', path, query: query);

  Future<String> login(String username, [String password = 'password']) async {
    final result = await post(
      '/api/auth/login',
      query: {'username': username, 'password': password},
    );
    expect(result.$1, 200, reason: 'login failed: ${result.$2}');
    return result.$2['access_token'] as String;
  }

  Map<String, String> bearer(String token) => {
        HttpHeaders.authorizationHeader: 'Bearer $token',
      };

  group('public and configuration', () {
    test('public health and permitAll rules work', () async {
      final result = await get('/api/public/health');
      expect(result.$1, 200);
      expect(result.$2['status'], 'UP');
      expect(result.$3.value('x-content-type-options'), 'nosniff');
      expect(result.$3.value('x-frame-options'), 'DENY');
      expect(result.$3.value('x-request-id'), isNotNull);
    });

    test('request parameters are bound', () async {
      final result = await get('/api/public/echo', query: {'message': 'hello'});
      expect(result.$2['echo'], 'hello');
    });

    test('CORS preflight is answered by the CORS config', () async {
      final preflightClient = HttpClient();
      final req = await preflightClient.openUrl(
        'OPTIONS',
        base.replace(path: '/api/public/health'),
      );
      req.headers.set('Origin', 'https://app.example.com');
      req.headers.set('Access-Control-Request-Method', 'GET');
      final response = await req.close();
      expect(response.statusCode, 204);
      expect(response.headers.value('access-control-allow-origin'),
          'https://app.example.com');
      preflightClient.close();
    });
  });

  group('authentication', () {
    late String alice;

    setUpAll(() async {
      alice = await login('alice');
    });

    test('bad credentials are rejected', () async {
      final result = await post(
        '/api/auth/login',
        query: {'username': 'alice', 'password': 'wrong'},
      );
      expect(result.$1, 401);
    });

    test('authentication events reach user @EventListener pods', () async {
      final result = await get('/api/public/events');
      expect(result.$1, 200);
      final events = result.$2['events'] as List;
      expect(events, contains('SUCCESS alice'));
    });

    test('/me resolves the JWT principal', () async {
      final result = await get('/api/auth/me', headers: bearer(alice));
      expect(result.$1, 200);
      expect(result.$2['name'], 'alice');
      expect(result.$2['authorities'], contains('ROLE_USER'));
    });

    test('refresh token works for refresh but not for authentication', () async {
      final loginResult = await post(
        '/api/auth/login',
        query: {'username': 'alice', 'password': 'password'},
      );
      final refresh = loginResult.$2['refresh_token'] as String;
      final refreshed = await post(
        '/api/auth/refresh',
        query: {'token': refresh},
      );
      expect(refreshed.$1, 200);
      expect(refreshed.$2['access_token'], isA<String>());

      final direct = await get('/api/auth/me', headers: bearer(refresh));
      expect(direct.$1, 401);
    });

    test('account status exceptions are enforced', () async {
      final result = await post(
        '/api/auth/login',
        query: {'username': 'locked', 'password': 'password'},
      );
      expect(result.$1, 401);
    });
  });

  group('authorization', () {
    late String alice;
    late String admin;
    late String bob;

    setUpAll(() async {
      alice = await login('alice');
      admin = await login('admin');
      bob = await login('bob');
    });

    test('anonymous access to protected route is 401', () async {
      final result = await get('/api/orgs/acme/reports');
      expect(result.$1, 401);
    });

    test('@Secured and @RolesAllowed enforce admin routes', () async {
      final asAdmin = await get('/api/admin/stats', headers: bearer(admin));
      expect(asAdmin.$1, 200);
      final asAlice = await get('/api/admin/stats', headers: bearer(alice));
      expect(asAlice.$1, 403);
      final audit = await get('/api/admin/audit', headers: bearer(admin));
      expect(audit.$1, 200);
    });

    test('method security honours the injected role hierarchy', () async {
      final result = await get(
        '/api/admin/user-access',
        headers: bearer(admin),
      );
      expect(result.$1, 200);
      expect(result.$2['granted_by_hierarchy'], isTrue);
    });

    test('@PreAuthorize binds #orgId and principal.organizationId', () async {
      final allowed = await get('/api/orgs/acme/reports', headers: bearer(alice));
      expect(allowed.$1, 200);
      final denied = await get('/api/orgs/beta/reports', headers: bearer(alice));
      expect(denied.$1, 403);
      final asAdmin = await get('/api/orgs/beta/reports', headers: bearer(admin));
      expect(asAdmin.$1, 200);
    });

    test('@PostAuthorize checks the return object', () async {
      final result = await get('/api/orgs/acme/audit', headers: bearer(alice));
      expect(result.$1, 200);
      expect(result.$2['owner_id'], 'alice');
    });

    test('hasAuthority works for granted authorities', () async {
      final aliceResult = await get('/api/orgs/reports', headers: bearer(alice));
      expect(aliceResult.$1, 200);
      final bobResult = await get('/api/orgs/reports', headers: bearer(bob));
      expect(bobResult.$1, 403);
    });

    test('custom API-key provider and addFilterBefore work', () async {
      final allowed = await get(
        '/api/service/status',
        headers: {'X-Api-Key': 'demo-service-key'},
      );
      expect(allowed.$1, 200);
      final denied = await get('/api/service/status');
      expect(denied.$1, anyOf(401, 403));
    });
  });

  group('session chain', () {
    test('Basic auth works on the second filter chain', () async {
      final credentials = base64Encode(utf8.encode('alice:password'));
      final result = await get(
        '/session/profile',
        headers: {HttpHeaders.authorizationHeader: 'Basic $credentials'},
      );
      expect(result.$1, 200);
      expect(result.$2['name'], 'alice');
    });

    test('anonymous access to the session chain is 401', () async {
      final result = await get('/session/profile');
      expect(result.$1, 401);
    });
  });

  group('OAuth2 and OIDC', () {
    test('resource server verifies a locally signed bearer token', () async {
      final minted = await get(
        '/api/oauth2/token',
        query: {'subject': 'alice', 'provider': 'resource', 'nonce': 'n'},
      );
      expect(minted.$1, 200);
      final profile = await get(
        '/api/oauth2/resource',
        headers: bearer(minted.$2['id_token'] as String),
      );
      expect(profile.$1, 200);
      expect(profile.$2['name'], 'alice');
    });

    test('Google ID token validation honours nonce and azp', () async {
      final minted = await get(
        '/api/oauth2/token',
        query: {'subject': 'alice', 'provider': 'google', 'nonce': 'nonce-1'},
      );
      final token = minted.$2['id_token'] as String;
      final ok = await get(
        '/api/oauth2/google',
        query: {'idToken': token, 'nonce': 'nonce-1'},
      );
      expect(ok.$1, 200);
      expect(ok.$2['provider'], 'google');

      final replay = await get(
        '/api/oauth2/google',
        query: {'idToken': token, 'nonce': 'wrong-nonce'},
      );
      expect(replay.$1, 401);
    });

    test('Apple ID token validation works', () async {
      final minted = await get(
        '/api/oauth2/token',
        query: {'subject': 'alice', 'provider': 'apple', 'nonce': 'nonce-2'},
      );
      final result = await get(
        '/api/oauth2/apple',
        query: {'idToken': minted.$2['id_token'] as String, 'nonce': 'nonce-2'},
      );
      expect(result.$1, 200);
      expect(result.$2['provider'], 'apple');
    });
  });
}