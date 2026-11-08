// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - Ultimate Test Suite
// Global REST Controller Advice and Exception Handler
// ---------------------------------------------------------------------------

import 'package:jetleaf/jetleaf.dart' hide ExceptionHandler;
import 'package:jetleaf_core/lang.dart';
import 'package:jetleaf_web/jetleaf_web.dart';

@RestControllerAdvice()
class UltimateControllerAdvice {
  const UltimateControllerAdvice();

  @ExceptionHandler([ClassType<ArgumentError>()])
  Future<ResponseBody<Map<String, Object>>> handleArgumentError(ArgumentError error) async {
    return ResponseBody.of(HttpStatus.BAD_REQUEST, {
      'error': 'ArgumentError',
      'message': error.message.toString(),
      'handled': true,
    });
  }
}
