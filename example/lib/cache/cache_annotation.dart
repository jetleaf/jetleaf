import 'package:example/cache/cache_storage.dart';
import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_resource/jetleaf_resource.dart';

import '../core/common_infrastructure.dart';

@Service()
final class CacheAnnotation with Interceptable {
  final List<User> _userDatabase = [];
  int _userCounter = 0;
  
  CacheAnnotation();

  // CachePut - Always executes and updates cache
  @CachePut({"users"}, ttl: Duration(minutes: 5))
  Future<User> addUser(User user) async => when(() async {
    print("💾 [CachePut] Adding user to database: ${user.email}");

    _userDatabase.add(user);

    await Future.delayed(Duration(milliseconds: 100)); // Simulate DB operation

    print("✅ [CachePut] User added: ${user.email}");
    return user;
  }, this, 'addUser', ExecutableArgument.positional([user.email]));

  // CacheEvict - Removes from cache
  @CacheEvict({"users"}, beforeInvocation: true)
  Future<void> removeUser(User user) async => when(() async {
    print("🗑️ [CacheEvict] Removing user from database: ${user.email}");

    int removed = 0;
    _userDatabase.removeWhere((u) {
      if (u.email == user.email) {
        removed++;
        return true;
      }

      return false;
    });

    await Future.delayed(Duration(milliseconds: 50));
    if (removed > 0) {
      print("✅ [CacheEvict] User removed: ${user.email}");
    } else {
      print("⚠️ [CacheEvict] User not found: ${user.email}");
    }
  }, this, 'removeUser', ExecutableArgument.positional([user.email]));

  // Cacheable - Only executes if not in cache
  @Cacheable({"users"}, ttl: Duration(minutes: 10))
  Future<User> getUser(String email) async => when(() async {
    print("🔍 [Cacheable] Fetching user from database: $email");

    await Future.delayed(Duration(milliseconds: 200)); // Simulate expensive DB call
    final user = _userDatabase.firstWhere(
      (u) => u.email == email,
      orElse: () => User(name: "Unknown", email: email)
    );

    print("✅ [Cacheable] User fetched: $user");
    return user;
  }, this, 'getUser', ExecutableArgument.positional([email]));

  // CacheEvict all entries
  @CacheEvict({"users"}, allEntries: true)
  Future<void> clearAllUsers() async => when(() async {
    print("🧹 [CacheEvict-All] Clearing all user cache entries");
    await Future.delayed(Duration(milliseconds: 50));
    print("✅ [CacheEvict-All] All user cache entries cleared");
  }, this, 'clearAllUsers');

  // CachePut with automatic user generation
  @CachePut({"users"}, ttl: Duration(minutes: 2))
  Future<User> generateUser() async => when(() async {
    _userCounter++;

    final user = User(
      name: "AutoUser$_userCounter", 
      email: "autouser$_userCounter@example.com",
      age: 20 + _userCounter
    );

    print("💾 [CachePut] Generating new user: ${user.email}");
    _userDatabase.add(user);
    await Future.delayed(Duration(milliseconds: 80));
    print("✅ [CachePut] User generated: $user");
    return user;
  }, this, 'generateUser');

  // Get all users (not cached to show database state)
  Future<List<User>> getAllUsers() async {
    print("📋 Getting all users from database (${_userDatabase.length} users)");
    return _userDatabase.toList();
  }
}

@Component("myCacheRegistrar")
class CacheRegistrar extends CacheConfigurer {
  @override
  void configureErrorHandler(CacheErrorHandlerRegistry registry) {}

  @override
  void configureCacheManager(CacheManagerRegistry registry) {}

  @override
  void configureCacheResolver(CacheResolverRegistry registry) {}

  @override
  void configureCacheStorage(CacheStorageRegistry registry) {
    registry.addStorage(CacheStorageExample());
  }

  @override
  void configureKeyGenerator(KeyGeneratorRegistry registry) {}
}