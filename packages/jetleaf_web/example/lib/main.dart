// ignore_for_file: avoid_print

import 'package:jetleaf_web/jetleaf_web.dart';

void main() {
  print('========================================================');
  print('  🍃 Jetleaf Web 2.0.0 Architecture Showcase');
  print('========================================================\n');

  // 1. Declarative Routing with RouterBuilder
  print('[1] Defining Composable Routes with RouterBuilder:');
  final router = RouterBuilder()
    ..route(GET('/health'), (req) => {'status': 'UP', 'service': 'Jetleaf Web API'})
    ..group('/api/v1', RouterBuilder()
      ..route(GET('/users'), (req) => ['Alice', 'Bob', 'Charlie'])
      ..route(POST('/users'), (req) => {'created': true, 'id': 'USR-101'})
      ..route(GET('/users/{id}'), (req) => {'id': 'USR-101', 'name': 'Alice'})
      ..route(PUT('/users/{id}'), (req) => {'updated': true})
      ..route(DELETE('/users/{id}'), (req) => {'deleted': true})
    );

  final spec = router.build();
  print('Registered ${spec.routes.length} HTTP routes:');
  for (final route in spec.routes) {
    print('  ${route.method.toString().padRight(7)} ${route.path}');
  }

  // 2. URI Construction and Path Templating
  print('\n[2] Dynamic URI Templating with SimpleUriBuilder:');
  const uriBuilder = SimpleUriBuilder();

  final userUri = uriBuilder.build(
    '/api/v1/users/{userId}/orders/{orderId}',
    {'userId': 'USR-891', 'orderId': 'ORD-4492'},
    {'expand': 'items,customer', 'format': 'json'},
  );

  print('Interpolated Path: ${userUri.path}');
  print('Query Parameters : ${userUri.queryParameters}');
  print('Full Resource URI: $userUri\n');

  // 3. HTTP Primitives & Content Negotiation
  print('[3] HTTP Headers & Media Types:');
  final headers = HttpHeaders()
    ..setContentType(MediaType.APPLICATION_JSON)
    ..setAccept([MediaType.APPLICATION_JSON, MediaType.TEXT_HTML])
    ..set('X-Jetleaf-Version', '2.0.0')
    ..set('X-Request-Trace', 'trace-99238-a1');

  print('Content-Type    : ${headers.getContentType()}');
  print('Accept          : ${headers.getAccept()}');
  print('Custom Header   : X-Request-Trace=${headers.get('X-Request-Trace')?.firstOrNull}');
  print('Status Code 200 : ${HttpStatus.OK.getCode()} ${HttpStatus.OK.getName()} - ${HttpStatus.OK.getDescription()}');
  print('Status Code 201 : ${HttpStatus.CREATED.getCode()} ${HttpStatus.CREATED.getName()} - ${HttpStatus.CREATED.getDescription()}\n');

  // 4. REST Payload Serialization with Jetson
  print('[4] Serializing RESTful API Response:');
  final responsePayload = {
    'statusCode': HttpStatus.OK.getCode(),
    'message': HttpStatus.OK.getName(),
    'timestamp': DateTime.now().toIso8601String(),
    'data': {
      'routesRegistered': spec.routes.length,
      'engine': 'Jetleaf Web 2.0.0 AOT',
      'host': '127.0.0.1:8080',
    },
  };

  final mapper = ObjectMapper();
  final jsonOutput = mapper.writeValueAsString(responsePayload);
  print(jsonOutput);

  print('\n========================================================');
  print('  ✅ Jetleaf Web Example executed successfully!');
  print('========================================================');
}
