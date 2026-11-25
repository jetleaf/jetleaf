import 'package:jetleaf_security/authorization.dart';
import 'package:jetleaf_security/core.dart';
import 'package:jetleaf_security/filter.dart';
import 'package:jetleaf_web/jetleaf_web.dart';
import 'package:test/test.dart';

import '../helpers/mock_http.dart';

final class _RecordingDeniedHandler implements AccessDeniedHandler {
  bool called = false;

  @override
  Future<void> handle(
    ServerHttpRequest request,
    ServerHttpResponse response,
    AccessDeniedException exception,
  ) async {
    called = true;
    response.setStatus(HttpStatus.FORBIDDEN);
  }
}

void main() {
  test('handler-level denials use the configured AccessDeniedHandler', () async {
    final handler = _RecordingDeniedHandler();
    final resolver = SecurityExceptionResolver(accessDeniedHandler: handler);

    final handled = await resolver.resolve(
      MockServerHttpRequest(),
      MockServerHttpResponse(),
      null,
      AccessDeniedException('no'),
      StackTrace.current,
    );

    expect(handled, isTrue);
    expect(handler.called, isTrue);
  });
}