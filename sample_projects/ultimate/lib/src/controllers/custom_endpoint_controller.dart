// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - Ultimate Test Suite
// Custom REST Controller Meta-Annotated with User-Defined Stereotype
// ---------------------------------------------------------------------------

import 'package:jetleaf_web/jetleaf_web.dart';
import '../annotations/custom_annotations.dart';

@CustomEndpoint('/api/custom')
class CustomEndpointController {
  const CustomEndpointController();

  @GetMapping(path: '/info')
  Future<ResponseBody<Map<String, String>>> getInfo() async {
    return ResponseBody.ok({
      'framework': 'Jetleaf v2',
      'source': 'CustomEndpointController',
      'status': 'VERIFIED',
    });
  }
}
