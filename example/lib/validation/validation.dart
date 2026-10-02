import 'dart:async';

import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_scheduling/jetleaf_scheduling.dart';
import 'package:jetleaf_validation/jetleaf_validation.dart';

import '../core/common_infrastructure.dart';

@Validated()
final class ValidUser {
  
}

@Service()
class Validation {
  void doSomething() => print("Hello from doSomething()");

  @Validated()
  @NotNull()
  Future<User?> getUser() async {
    print("✅ getUser() called");
    return User(name: "Alice", email: "alice@example.com");
  }

  Future<void> saveUser(
    @Validated() @NotEmpty() String name,
    @Validated() @Email() String emailAddress,
  ) async {
    print("✅ saveUser() called with name=$name, email=$emailAddress");
  }

  Future<User?> getNullableUser() async {
    print("✅ getNullableUser() called");
    return User(name: "Bob", email: "bob@example.com");
  }
}

@Component()
@RequiredAll()
class ValidationTasks {
  final Validation validation;

  const ValidationTasks(this.validation);

  // ─────────────────────────────────────────────────────────────
  // Execute every 10 seconds
  // ─────────────────────────────────────────────────────────────
  @Scheduled(fixedRate: Duration(seconds: 10))
  Future<void> every10Seconds() async {
    // print('⏰ Running scheduled task: every10Seconds()');
    // try {
    //   // Example: call a simple method
    //   validation.doSomething();

    //   // Example: call validated getUser()
    //   final user = await validation.getUser();
    //   print('User fetched: ${user?.name}, ${user?.email}');

    //   // Example: call saveUser() with validation
    //   await validation.saveUser("Charlie", "charlie@example.com");

    //   print('✅ Completed scheduled task: every10Seconds()');
    // } catch (e, st) {
    //   print('❌ Error in scheduled task: every10Seconds() - $e - $st');
    // }
  }

  // ─────────────────────────────────────────────────────────────
  // Execute every 30 seconds
  // ─────────────────────────────────────────────────────────────
  @Scheduled(fixedRate: Duration(seconds: 30))
  Future<void> every30Seconds() async {
    // print('⏰ Running scheduled task: every30Seconds()');
    // try {
    //   // Example: call nullable user method
    //   final nullableUser = await validation.getNullableUser();
    //   if (nullableUser != null) {
    //     print('Nullable user fetched: ${nullableUser.name}, ${nullableUser.email}');
    //   } else {
    //     print('Nullable user returned null');
    //   }

    //   // Example: invalid input to trigger validation
    //   try {
    //     await validation.saveUser("", "invalid-email");
    //   } catch (e) {
    //     print('⚠️ Validation caught error as expected: $e');
    //   }

    //   print('✅ Completed scheduled task: every30Seconds()');
    // } catch (e, st) {
    //   print('❌ Error in scheduled task: every30Seconds() - $e - $st');
    // }
  }

  // ─────────────────────────────────────────────────────────────
  // Execute every minute - Clear all cache
  // ─────────────────────────────────────────────────────────────
  @Scheduled(type: CronType.EVERY_MINUTE)
  Future<void> everyMinute() async {
    // print('⏰ Running scheduled task: everyMinute() (clear cache)');
    // try {
    //   // You could clear a cache or refresh validation rules here
    //   print('✅ Completed scheduled task: everyMinute()');
    // } catch (e, st) {
    //   print('❌ Error in scheduled task: everyMinute() - $e - $st');
    // }
  }

  // ─────────────────────────────────────────────────────────────
  // Execute every 45 seconds
  // ─────────────────────────────────────────────────────────────
  @Scheduled(fixedRate: Duration(seconds: 45))
  Future<void> every45Seconds() async {
    // print('⏰ Running scheduled task: every45Seconds()');
    // try {
    //   // Example: call validated method again
    //   final user = await validation.getUser();
    //   print('User fetched in 45s task: ${user?.name}, ${user?.email}');
    //   print('✅ Completed scheduled task: every45Seconds()');
    // } catch (e, st) {
    //   print('❌ Error in scheduled task: every45Seconds() - $e - $st');
    // }
  }

  // ─────────────────────────────────────────────────────────────
  // Execute with fixed delay - Async operations
  // ─────────────────────────────────────────────────────────────
  @Scheduled(fixedDelay: Duration(seconds: 15))
  Future<void> fixedDelay() async {
    // print('⏰ Running scheduled task: fixedDelay()');
    // try {
    //   // Example: simulate async validation workflow
    //   final user = await validation.getUser();
    //   await validation.saveUser(user!.name, user.email);
    //   print('✅ Completed scheduled task: fixedDelay()');
    // } catch (e, st) {
    //   print('❌ Error in scheduled task: fixedDelay() - $e - $st');
    // }
  }
}