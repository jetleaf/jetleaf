// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - Ultimate Test Suite
// Ultimate REST Controller Covering All Web Annotations
// ---------------------------------------------------------------------------

import 'package:jetleaf_web/jetleaf_web.dart';
import '../models/user_dto.dart';
import '../services/billing_service.dart';

@RestController('/api/ultimate')
@CrossOrigin(origins: ['*'])
class UltimateController {
  final BillingService _billingService;

  const UltimateController(this._billingService);

  @GetMapping(path: '/hello')
  @Produces([MediaType.APPLICATION_JSON])
  Future<ResponseBody<Map<String, Object>>> getHello() async {
    return ResponseBody.ok({
      'message': 'Welcome to Jetleaf Ultimate!',
      'status': 'OPERATIONAL',
    });
  }

  @GetMapping(path: '/users/{id}')
  Future<ResponseBody<Map<String, Object>>> getUserById(@PathVariable(value: 'id') String id) async {
    return ResponseBody.ok({
      'id': id,
      'fullName': 'Test User $id',
      'email': 'user$id@example.com',
    });
  }

  @PostMapping(path: '/users')
  Future<ResponseBody<UserDto>> createUser(@RequestBody() UserDto user) async {
    return ResponseBody.of(HttpStatus.CREATED, user);
  }

  @GetMapping(path: '/query')
  Future<ResponseBody<Map<String, String>>> queryParams(@RequestParam(value: 'filter') String filter) async {
    return ResponseBody.ok({'filter': filter});
  }

  @GetMapping(path: '/header')
  Future<ResponseBody<Map<String, String>>> headerParam(@RequestHeader(value: 'X-Trace-Id') String traceId) async {
    return ResponseBody.ok({'traceId': traceId});
  }

  @GetMapping(path: '/cookie')
  Future<ResponseBody<Map<String, String>>> cookieParam(@CookieValue(value: 'session_id') String sessionId) async {
    return ResponseBody.ok({'sessionId': sessionId});
  }

  @PutMapping(path: '/users/{id}')
  Future<ResponseBody<Map<String, Object>>> updateUser(
    @PathVariable(value: 'id') String id,
    @RequestBody() UserDto user,
  ) async {
    return ResponseBody.ok({
      'updatedId': id,
      'user': user.toJson(),
    });
  }

  @DeleteMapping(path: '/users/{id}')
  Future<ResponseBody<Map<String, String>>> deleteUser(@PathVariable(value: 'id') String id) async {
    return ResponseBody.ok({'deletedId': id});
  }

  @PatchMapping(path: '/users/{id}')
  Future<ResponseBody<Map<String, String>>> patchUser(
    @PathVariable(value: 'id') String id,
    @RequestParam(value: 'status') String status,
  ) async {
    return ResponseBody.ok({'id': id, 'newStatus': status});
  }

  @GetMapping(path: '/invoice/{accountId}')
  Future<ResponseBody<Map<String, String>>> getInvoice(@PathVariable(value: 'accountId') String accountId) async {
    final invoice = await _billingService.calculateInvoice(accountId);
    return ResponseBody.ok({'invoice': invoice});
  }

  @GetMapping(path: '/trigger-error')
  Future<ResponseBody<String>> triggerError() async {
    throw ArgumentError('Simulated argument error for exception handler');
  }
}