// import 'package:example/core/common_infrastructure.dart';
// import 'package:jetleaf/jetleaf.dart';
// import 'package:jetleaf_resource/jetleaf_resource.dart';
// import 'package:jetleaf_scheduling/jetleaf_scheduling.dart';
// import 'package:jetleaf_intercept/jetleaf_intercept.dart';

// import 'rate_limit_annotation.dart';

// @Component()
// @RequiredAll()
// final class RateLimitScheduledTasks with Interceptable {
//   final RateLimitAnnotation rateLimitAnnotation;

//   RateLimitScheduledTasks(this.rateLimitAnnotation);

//   // Execute every 15 seconds - Test user registration rate limiting
//   @Scheduled(fixedRate: Duration(seconds: 15))
//   void userRegistrationTest() async {
//     print('\n⏰ [${DateTime.now()}] === Starting User Registration Rate Limit Test ===');
    
//     // Try to register multiple users quickly to test rate limiting
//     for (int i = 0; i < 8; i++) { // Try 8 registrations (limit is 5 per minute)
//       final user = User(
//         name: "TestUser${DateTime.now().millisecondsSinceEpoch}",
//         email: "test${DateTime.now().millisecondsSinceEpoch}@example.com",
//         password: "password123"
//       );
      
//       try {
//         print("--- Registration Attempt ${i + 1}/8 ---");
//         final registeredUser = await rateLimitAnnotation.registerUser(user);
//         print("✅ Registration successful: ${registeredUser.email}");
//       } on RateLimitExceededException catch (e) {
//         print("🚫 RateLimitExceededException caught (expected): ${e.message}");
//         print("   Retry after: ${e.retryAfter}");
//         break; // Stop when we hit rate limit
//       } catch (e) {
//         print("❌ Unexpected error: $e");
//         break;
//       }
      
//       // Small delay between attempts
//       await Future.delayed(Duration(milliseconds: 500));
//     }
    
//     print('✅ [${DateTime.now()}] === User Registration Test Completed ===\n');
//   }

//   // Execute every 20 seconds - Test login attempt rate limiting with explicit exception testing
//   @Scheduled(fixedRate: Duration(seconds: 20))
//   void loginAttemptTest() async {
//     print('\n⏰ [${DateTime.now()}] === Starting Login Attempt Rate Limit Test ===');
    
//     final testIp = "192.168.1.${DateTime.now().second % 255}"; // Vary IP slightly
//     print("📡 Testing with IP: $testIp");
    
//     bool rateLimitHit = false;
    
//     // Try multiple login attempts (limit is 10 per hour) - force hitting the limit
//     for (int i = 0; i < 15; i++) {
//       print("--- Login Attempt ${i + 1}/15 ---");
      
//       try {
//         final response = await rateLimitAnnotation.login(
//           "test@example.com", 
//           "wrongpassword", 
//           testIp
//         );
        
//         if (response.success) {
//           print("✅ Login successful");
//         } else {
//           print("❌ Login failed: ${response.reason}");
//         }
//       } on RateLimitExceededException catch (e) {
//         print("🚫 RateLimitExceededException caught: ${e.message}");
//         print("   Identifier: ${e.identifier}");
//         print("   Limit: ${e.limit}");
//         print("   Window: ${e.window}");
//         print("   Retry After: ${e.retryAfter}");
//         rateLimitHit = true;
//         break;
//       } catch (e) {
//         print("⚠️ Other error: $e");
//       }
      
//       // Very small delay to hit rate limit faster
//       await Future.delayed(Duration(milliseconds: 100));
//     }
    
//     if (!rateLimitHit) {
//       print("ℹ️ Rate limit not hit in this test cycle");
//     }
    
//     print('✅ [${DateTime.now()}] === Login Attempt Test Completed ===\n');
//   }

//   // Execute every 10 seconds - Test API call rate limiting with burst
//   @Scheduled(fixedRate: Duration(seconds: 10))
//   void apiCallTest() async {
//     print('\n⏰ [${DateTime.now()}] === Starting API Call Rate Limit Test ===');
    
//     final apiKey = "test-api-key-123";
//     final queries = ["john", "test", "user", "admin", "search"];
    
//     int successfulCalls = 0;
//     int rateLimitedCalls = 0;
    
//     // Make multiple API calls quickly (limit is 100 per minute)
//     for (int i = 0; i < 120; i++) { // Try 120 calls to ensure we hit the 100 limit
//       final query = queries[i % queries.length];
      
//       try {
//         final response = await rateLimitAnnotation.searchUsers(query, apiKey);
//         successfulCalls++;
//         if (i % 20 == 0) { // Only log every 20th call to reduce noise
//           print("✅ API call $i successful: ${response.message}");
//         }
//       } on RateLimitExceededException catch (e) {
//         rateLimitedCalls++;
//         print("🚫 API call $i - RateLimitExceededException: ${e.message}");
//         break;
//       } catch (e) {
//         print("❌ API call $i - Unexpected error: $e");
//         break;
//       }
      
//       // Very small delay to simulate rapid API calls
//       await Future.delayed(Duration(milliseconds: 50));
//     }
    
//     print("📊 API Call Test Results:");
//     print("   ✅ Successful calls: $successfulCalls");
//     print("   🚫 Rate limited calls: $rateLimitedCalls");
    
//     print('✅ [${DateTime.now()}] === API Call Test Completed ===\n');
//   }

//   // Execute every 45 seconds - Mixed operations with exception handling
//   @Scheduled(fixedRate: Duration(seconds: 45))
//   void mixedOperationsTest() async {
//     print('\n⏰ [${DateTime.now()}] === Starting Mixed Operations Test ===');
    
//     final mixedTasks = <Future>[];
//     final testIp = "10.0.1.${DateTime.now().second % 100}";
    
//     // Mix different types of operations
//     mixedTasks.add(_testRegistrationWithException("mixed@example.com"));
//     mixedTasks.add(_testLoginWithException("user@example.com", testIp));
//     mixedTasks.add(_testApiCallWithException("mixed", "api-key-mixed"));
    
//     await Future.wait(mixedTasks, eagerError: false);
    
//     print('✅ [${DateTime.now()}] === Mixed Operations Test Completed ===\n');
//   }

//   // Execute every 25 seconds - Rate limit status checking
//   @Scheduled(fixedRate: Duration(seconds: 25))
//   void rateLimitStatusTest() async {
//     print('\n⏰ [${DateTime.now()}] === Starting Rate Limit Status Check ===');
    
//     try {
//       // Check status for different identifiers
//       final status1 = await rateLimitAnnotation.checkRateLimitStatus("test@example.com", "userRegistration");
//       final status2 = await rateLimitAnnotation.checkRateLimitStatus("192.168.1.100", "loginAttempts");
//       final status3 = await rateLimitAnnotation.checkRateLimitStatus("api-key-123", "apiCalls");
      
//       print("📊 Rate Limit Status Report:");
//       _printRateLimitStatus("User Registration", status1);
//       _printRateLimitStatus("Login Attempts", status2);
//       _printRateLimitStatus("API Calls", status3);
      
//     } catch (e) {
//       print("❌ Failed to check rate limit status: $e");
//     }
    
//     print('✅ [${DateTime.now()}] === Rate Limit Status Check Completed ===\n');
//   }

//   // Execute every minute - Cleanup and show current state
//   @Scheduled(type: CronType.EVERY_MINUTE)
//   void cleanupAndStateTest() async {
//     print('\n⏰ [${DateTime.now()}] === Starting Cleanup and State Check ===');
    
//     try {
//       // Get current state
//       final allUsers = await rateLimitAnnotation.getAllUsers();
//       print("📊 Current database state:");
//       print("   Total users: ${allUsers.length}");
      
//       if (allUsers.length > 20) {
//         print("🧹 Database has many users, consider cleanup in real implementation");
//       }
      
//     } catch (e) {
//       print("❌ Error during cleanup check: $e");
//     }
    
//     print('✅ [${DateTime.now()}] === Cleanup and State Check Completed ===\n');
//   }

//   Future<void> _testRegistrationWithException(String email) async {
//     try {
//       final user = User(name: "MixedOpUser", email: email, password: "pass123");
//       await rateLimitAnnotation.registerUser(user);
//       print("✅ Mixed op: Registration successful for $email");
//     } on RateLimitExceededException catch (e) {
//       print("🚫 Mixed op: Registration RateLimitExceededException for $email: ${e.message}");
//     } catch (e) {
//       print("❌ Mixed op: Registration other error for $email: $e");
//     }
//   }

//   Future<void> _testLoginWithException(String email, String ip) async {
//     try {
//       final response = await rateLimitAnnotation.login(email, "password", ip);
//       print("✅ Mixed op: Login attempt completed for $email - $response");
//     } on RateLimitExceededException catch (e) {
//       print("🚫 Mixed op: Login RateLimitExceededException for $email: ${e.message}");
//     } catch (e) {
//       print("❌ Mixed op: Login other error for $email: $e");
//     }
//   }

//   Future<void> _testApiCallWithException(String query, String apiKey) async {
//     try {
//       final response = await rateLimitAnnotation.searchUsers(query, apiKey);
//       print("✅ Mixed op: API call successful for '$query' - $response");
//     } on RateLimitExceededException catch (e) {
//       print("🚫 Mixed op: API call RateLimitExceededException for '$query': ${e.message}");
//     } catch (e) {
//       print("❌ Mixed op: API call other error for '$query': $e");
//     }
//   }

//   void _printRateLimitStatus(String service, RateLimitResult status) {
//     final statusEmoji = status.allowed ? "✅" : "🚫";
//     print("   $statusEmoji $service:");
//     print("      📍 Identifier: ${status.identifier}");
//     print("      📊 Usage: ${status.currentCount}/${status.limit}");
//     print("      🎫 Remaining: ${status.remainingCount}");
//     print("      ⏰ Reset: ${status.resetTime}");
//     print("      🔄 Retry After: ${status.retryAfter.inSeconds}s");
//   }
// }

// // Supporting classes for result tracking
// final class CallResult {
//   final int attempt;
//   final bool isSuccess;
//   final bool isRateLimited;
//   final RateLimitExceededException? rateLimitException;
//   final Object? error;

//   CallResult.success(this.attempt) 
//     : isSuccess = true, 
//       isRateLimited = false, 
//       rateLimitException = null, 
//       error = null;

//   CallResult.rateLimited(this.attempt, this.rateLimitException) 
//     : isSuccess = false, 
//       isRateLimited = true, 
//       error = null;

//   CallResult.error(this.attempt, this.error) 
//     : isSuccess = false, 
//       isRateLimited = false, 
//       rateLimitException = null;
// }

// final class ResultAnalysis {
//   final int successful;
//   final int rateLimited;
//   final int otherErrors;

//   const ResultAnalysis(this.successful, this.rateLimited, this.otherErrors);
// }

// @Component()
// final class RateLimitSchedulerConfig implements SchedulingConfigurer {
//   @override
//   void configure(SchedulingTaskRegistrar schedulingTaskRegistrar) {
//     schedulingTaskRegistrar.maxConcurrency = 8;
    
//     // Add custom scheduled task for additional rate limit testing
//     schedulingTaskRegistrar.addFixedRateTask(() {
//       print("🔄 [Custom Rate Limit Task] Running additional rate limit health check");
//     }, Duration(seconds: 35), "rate-limit-health-check");
    
//     schedulingTaskRegistrar.addFixedDelayTask(() async {
//       print("⏳ [Custom Rate Limit Delay] Simulating delayed rate limit operation");
//       await Future.delayed(Duration(seconds: 2));
//       print("✅ [Custom Rate Limit Delay] Delayed rate limit operation completed");
//     }, Duration(seconds: 40), "rate-limit-delay-task");
//   }
// }