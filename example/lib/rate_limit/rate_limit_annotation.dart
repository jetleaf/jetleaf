import 'dart:async';

import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_resource/jetleaf_resource.dart';

import '../core/common_infrastructure.dart';
import 'rate_limit_storage.dart';

@Service()
final class RateLimitAnnotation with Interceptable {
  final List<User> _userDatabase = [];
  
  RateLimitAnnotation();

  // Rate limited user registration - 5 per minute
  @RateLimit({"userRegistration"}, limit: 5, window: Duration(minutes: 1))
  Future<User> registerUser(User user) async => when(() async {
    print("👤 [RateLimit] Registering user: ${user.email}");

    _userDatabase.add(user);
    await Future.delayed(Duration(milliseconds: 100));

    print("✅ [RateLimit] User registered: ${user.email}");
    return user;
  }, this, 'registerUser', ExecutableArgument.positional([user.email]));

  // Rate limited login with custom key generator
  @RateLimit(
    {"loginAttempts"}, 
    limit: 10, 
    window: Duration(hours: 1),
    keyGenerator: 'ipBasedKeyGenerator'
  )
  Future<LoginResponse> login(String email, String password, String ipAddress) async => when(() async {
    print("🔐 [RateLimit] Login attempt for: $email from IP: $ipAddress");

    await Future.delayed(Duration(milliseconds: 200));
    final user = _userDatabase.firstWhere(
      (u) => u.email == email && u.password == password,
      orElse: () => User(name: "Unknown", email: email)
    );

    final success = user.name != "Unknown";
    
    if (success) {
      print("✅ [RateLimit] Login successful for: $email");
      return LoginResponse.success(user: user);
    } else {
      print("❌ [RateLimit] Login failed for: $email");
      return LoginResponse.failure(reason: "Invalid credentials");
    }
  }, this, 'login', ExecutableArgument.positional([email, password, ipAddress]));

  // API endpoint that checks rate limit status
  @RateLimit({"apiCalls"}, limit: 100, window: Duration(minutes: 1))
  Future<ApiResponse> searchUsers(String query, String apiKey) async => when(() async {
    print("🔍 [RateLimit] Searching users with query: '$query' for API key: $apiKey");

    await Future.delayed(Duration(milliseconds: 150));
    final results = _userDatabase.where((user) => 
      user.name.toLowerCase().contains(query.toLowerCase()) ||
      user.email.toLowerCase().contains(query.toLowerCase())
    ).toList();

    print("✅ [RateLimit] Search completed: ${results.length} results for '$query'");
    
    return ApiResponse(
      success: true,
      data: results,
      message: "Search completed successfully",
    );
  }, this, 'searchUsers', ExecutableArgument.positional([query, apiKey]));

  // Method to check rate limit without consuming
  Future<RateLimitResult> checkRateLimitStatus(String identifier, String storageName) async {
    // This would use the rate limit manager to get current status
    // without consuming a request
    print("📊 [RateLimit] Checking rate limit status for: $identifier in storage: $storageName");
    
    // Simulated check - in real implementation, this would query the storage
    await Future.delayed(Duration(milliseconds: 50));
    
    return RateLimitResult(
      identifier: identifier,
      limitName: storageName,
      currentCount: 3, // Example current count
      limit: 10, // Example limit
      window: Duration(minutes: 1),
      resetTime: ZonedDateTime.now().plus(Duration(minutes: 1)),
      retryAfter: Duration(minutes: 1),
      zoneId: ZoneId.systemDefault(),
    );
  }

  // Get all users (not rate limited for admin purposes)
  Future<List<User>> getAllUsers() async {
    print("📋 Getting all users from database (${_userDatabase.length} users)");
    return _userDatabase.toList();
  }
}

// Supporting data classes
final class LoginResponse {
  final bool success;
  final User? user;
  final String? reason;
  
  LoginResponse.success({required this.user}) 
    : success = true, reason = null;
    
  LoginResponse.failure({required this.reason}) 
    : success = false, user = null;
}

final class ApiResponse {
  final bool success;
  final List<User> data;
  final String message;
  
  const ApiResponse({
    required this.success,
    required this.data,
    required this.message,
  });
}

@Component("myRateLimitRegistrar")
class RateLimitRegistrar extends RateLimitConfigurer {
  @override
  void configureRateLimitStorage(RateLimitStorageRegistry registry) {
    print("📝 [RateLimitRegistrar] Configuring rate limit storages");
    
    // Register different storages for different use cases
    registry.addStorage(RateLimitStorageExample('userRegistration'));
    registry.addStorage(RateLimitStorageExample('loginAttempts'));
    registry.addStorage(RateLimitStorageExample('apiCalls'));
    registry.addStorage(RateLimitStorageExample('burstCalls'));
    registry.addStorage(RateLimitStorageExample('productionCalls'));
    
    print("✅ [RateLimitRegistrar] Registered 5 rate limit storages");
  }

  @override
  void configureRateLimitManager(RateLimitManagerRegistry registry) {
    print("📝 [RateLimitRegistrar] Configuring rate limit manager");
    // Default manager will be used
  }

  @override
  void configureRateLimitResolver(RateLimitResolverRegistry registry) {
    print("📝 [RateLimitRegistrar] Configuring rate limit resolver");
    // Default resolver will be used
  }
}

// @Service("ipBasedKeyGenerator")
// final class IpBasedKeyGenerator implements KeyGenerator {
//   @override
//   FutureOr<Object> generate(Object target, Method method, MethodArgument? args) {
//     // Use IP address as the key for rate limiting
//     if (args.length >= 3 && args[2] is String) {
//       final ipAddress = args[2] as String;
//       print("🔑 [IpBasedKeyGenerator] Generating key for IP: $ipAddress");
//       return 'ip:$ipAddress';
//     }
    
//     // Fallback to method signature
//     final fallbackKey = '${target.runtimeType}.${method.name}';
//     print("🔑 [IpBasedKeyGenerator] Using fallback key: $fallbackKey");
//     return fallbackKey;
//   }
// }