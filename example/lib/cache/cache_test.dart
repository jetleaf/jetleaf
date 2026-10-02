// import 'package:example/cache/cache_annotation.dart';
// import 'package:example/core/common_infrastructure.dart';
// import 'package:jetleaf/jetleaf.dart';
// import 'package:jetleaf_scheduling/jetleaf_scheduling.dart';

// @Component()
// @RequiredAll()
// final class CacheScheduledTasks {
//   final CacheAnnotation cacheAnnotation;

//   const CacheScheduledTasks(this.cacheAnnotation);

//   // Execute every 10 seconds - Add users and test cache
//   @Scheduled(fixedRate: Duration(seconds: 10))
//   void cacheOperations() async {
//     print('\n⏰ [${DateTime.now()}] === Starting Cache Operations ===');
    
//     // Generate and add a new user
//     final newUser = await cacheAnnotation.generateUser();
    
//     // Try to get the user (should be cached from generateUser)
//     print("--- Testing Cacheable Get ---");
//     await cacheAnnotation.getUser(newUser.email);
    
//     // Try again (should hit cache)
//     print("--- Testing Cache Hit ---");
//     await cacheAnnotation.getUser(newUser.email);
    
//     // Get existing users to test cache
//     print("--- Testing Existing Users ---");
//     await cacheAnnotation.getUser("alice@example.com");
//     await cacheAnnotation.getUser("bob@example.com");
    
//     // Show database state
//     final allUsers = await cacheAnnotation.getAllUsers();
//     print("📊 Current database: ${allUsers.length} users");
    
//     print('✅ [${DateTime.now()}] === Cache Operations Completed ===\n');
//   }

//   // Execute every 30 seconds - Remove users and test cache eviction
//   @Scheduled(fixedRate: Duration(seconds: 30))
//   void cacheEvictionTest() async {
//     print('\n⏰ [${DateTime.now()}] === Starting Cache Eviction Test ===');
    
//     // Remove a user if we have any auto-generated ones
//     final allUsers = await cacheAnnotation.getAllUsers();
//     final autoUsers = allUsers.where((u) => u.email.startsWith('autouser')).toList();
    
//     if (autoUsers.isNotEmpty) {
//       final userToRemove = autoUsers.first;
//       print("--- Testing CacheEvict ---");
//       await cacheAnnotation.removeUser(userToRemove);
      
//       // Try to get the removed user (should hit database since cache was evicted)
//       print("--- Testing Cache After Eviction ---");
//       await cacheAnnotation.getUser(userToRemove.email);
//     } else {
//       print("ℹ️ No auto-generated users to remove");
//     }
    
//     print('✅ [${DateTime.now()}] === Cache Eviction Test Completed ===\n');
//   }

//   // Execute every minute - Clear all cache
//   @Scheduled(type: CronType.EVERY_MINUTE)
//   void clearAllCache() async {
//     print('\n⏰ [${DateTime.now()}] === Clearing All Cache ===');
//     await cacheAnnotation.clearAllUsers();
//     print('✅ [${DateTime.now()}] === All Cache Cleared ===\n');
//   }

//   // Execute every 45 seconds - Mixed operations
//   @Scheduled(fixedRate: Duration(seconds: 45))
//   void mixedCacheOperations() async {
//     print('\n⏰ [${DateTime.now()}] === Mixed Cache Operations ===');
    
//     // Add multiple users
//     final user1 = User(name: "MixedUser1", email: "mixed1@example.com");
//     final user2 = User(name: "MixedUser2", email: "mixed2@example.com");
    
//     await cacheAnnotation.addUser(user1);
//     await cacheAnnotation.addUser(user2);
    
//     // Test cache for mixed users
//     await cacheAnnotation.getUser("mixed1@example.com");
//     await cacheAnnotation.getUser("mixed2@example.com");
    
//     // Remove one mixed user
//     await cacheAnnotation.removeUser(user1);
    
//     print('✅ [${DateTime.now()}] === Mixed Operations Completed ===\n');
//   }

//   // Execute with fixed delay - Async operations
//   @Scheduled(fixedDelay: Duration(seconds: 15))
//   Future<void> asyncCacheOperations() async {
//     print('\n⏰ [${DateTime.now()}] === Starting Async Cache Operations ===');
    
//     // Simulate async cache operations
//     final tasks = [
//       cacheAnnotation.getUser("alice@example.com"),
//       cacheAnnotation.getUser("bob@example.com"),
//       cacheAnnotation.generateUser(),
//     ];
    
//     await Future.wait(tasks);
    
//     print('✅ [${DateTime.now()}] === Async Cache Operations Completed ===\n');
//   }
// }

// @Component()
// final class ConfiguredScheduler implements SchedulingConfigurer {
//   @override
//   void configure(SchedulingTaskRegistrar schedulingTaskRegistrar) {
//     schedulingTaskRegistrar.maxConcurrency = 5;
    
//     // Add custom scheduled task that uses cache
//     schedulingTaskRegistrar.addFixedRateTask(() {
//       print("🔄 [Custom Task] Running cache health check");
//     }, Duration(seconds: 20), "cache-health-check");
    
//     schedulingTaskRegistrar.addFixedDelayTask(() async {
//       print("⏳ [Custom Delay Task] Simulating delayed cache operation");
//       await Future.delayed(Duration(seconds: 1));
//       print("✅ [Custom Delay Task] Delayed operation completed");
//     }, Duration(seconds: 25), "cache-delay-task");
//   }
// }