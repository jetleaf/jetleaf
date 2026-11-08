import 'dart:async';

import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_resource/jetleaf_resource.dart';

final class PersonalCacheStorage extends HashMap<Object, Cache> implements Resource<Object, Cache> {
  @override
  bool exists(Object key) => false;

  @override
  Cache? get(Object key) => this[key];
}

final class CacheStorageExample implements CacheStorage {
  final PersonalCacheStorage _storage = PersonalCacheStorage();
  final String name;
  
  CacheStorageExample([this.name = 'caem']);
  
  @override
  FutureOr<void> clear() {
    print("🧹 [CacheStorage] Clearing all entries from cache '$name'");
    final count = _storage.length;
    _storage.clear();
    print("✅ [CacheStorage] Cleared $count entries from cache '$name'");
  }

  @override
  List<Object?> equalizedProperties() => [name, runtimeType];

  @override
  FutureOr<void> evict(Object key) {
    print("🗑️ [CacheStorage] Attempting to evict key: $key from cache '$name'");
    if (_storage.containsKey(key)) {
      _storage.remove(key);
      print("✅ [CacheStorage] Successfully evicted key: $key from cache '$name'");
    } else {
      print("⚠️ [CacheStorage] Key not found for eviction: $key in cache '$name'");
    }
  }

  @override
  FutureOr<bool> evictIfPresent(Object key) {
    print("🔍 [CacheStorage] Checking if key exists for eviction: $key in cache '$name'");
    final exists = _storage.containsKey(key);
    if (exists) {
      _storage.remove(key);
      print("✅ [CacheStorage] Key existed and was evicted: $key from cache '$name'");
    } else {
      print("ℹ️ [CacheStorage] Key not present for eviction: $key in cache '$name'");
    }
    return exists;
  }

  @override
  FutureOr<Cache?> get(Object key) {
    print("🔍 [CacheStorage] Retrieving cache entry for key: $key from cache '$name'");
    final cache = _storage[key];
    if (cache != null) {
      print("✅ [CacheStorage] Retrieved cache entry for key: $key");
      cache.recordAccess(); // Record access for the cache entry
      return cache;
    } else {
      print("❌ [CacheStorage] Cache miss for key: $key");
      return null;
    }
  }

  @override
  FutureOr<T?> getAs<T>(Object key, [Class<T>? type]) {
    print("🔍 [CacheStorage] Retrieving typed cache entry for key: $key as ${type ?? T} from cache '$name'");
    final cache = _storage[key];
    
    if (cache == null) {
      print("❌ [CacheStorage] Cache miss for typed key: $key");
      return null;
    }
    
    cache.recordAccess(); // Record access for the cache entry
    
    try {
      final value = cache.get();
      if (value is T) {
        print("✅ [CacheStorage] Retrieved typed cache entry for key: $key -> $value");
        return value;
      } else {
        print("❌ [CacheStorage] Type mismatch for key: $key. Expected: ${type ?? T}, Got: ${value.runtimeType}");
        return null;
      }
    } catch (e) {
      print("❌ [CacheStorage] Failed to get value for key: $key. Error: $e");
      return null;
    }
  }

  @override
  String getName() {
    print("🏷️ [CacheStorage] Getting cache name: $name");
    return name;
  }

  @override
  PersonalCacheStorage getResource() {
    print("📦 [CacheStorage] Getting underlying store for cache '$name'");
    return _storage;
  }

  @override
  FutureOr<void> invalidate() {
    print("🔄 [CacheStorage] Invalidating cache '$name' (marking all entries for refresh)");
    final count = _storage.length;
    // In a real implementation, this might involve different logic
    // For this example, we'll just log the operation
    print("✅ [CacheStorage] Invalidated $count entries in cache '$name'");
  }

  @override
  FutureOr<void> put(Object key, [Object? value, Duration? ttl]) async {
    print("💾 [CacheStorage] Putting entry for key: $key with value: $value in cache '$name'");
    
    if (value == null) {
      print("⚠️ [CacheStorage] Null value provided for key: $key, removing existing entry if any");
      _storage.remove(key);
      return;
    }
    
    final cache = SimpleCache(value, ttl: ttl);
    _storage[key] = cache;
    
    if (ttl != null) {
      print("✅ [CacheStorage] Put entry for key: $key with TTL: $ttl");
    } else {
      print("✅ [CacheStorage] Put entry for key: $key with no expiration");
    }
  }

  @override
  FutureOr<Cache?> putIfAbsent(Object key, [Object? value, Duration? ttl]) {
    print("🔍 [CacheStorage] Put-if-absent for key: $key with value: $value in cache '$name'");
    
    final existing = _storage[key];
    if (existing != null) {
      print("✅ [CacheStorage] Key already exists, returning existing value: $key");
      existing.recordAccess();
      return existing;
    }
    
    if (value == null) {
      print("⚠️ [CacheStorage] Null value provided for putIfAbsent, returning null");
      return null;
    }
    
    final newCache = SimpleCache(value, ttl: ttl);
    _storage[key] = newCache;
    
    if (ttl != null) {
      print("✅ [CacheStorage] Added new entry for key: $key with TTL: $ttl");
    } else {
      print("✅ [CacheStorage] Added new entry for key: $key with no expiration");
    }
    
    return newCache;
  }

  // Utility method for monitoring
  void printStats() {
    print("\n📊 [CacheStorage] Cache '$name' Statistics:");
    print("   Total entries: ${_storage.length}");
    
    int expiredCount = 0;
    for (final cache in _storage.values) {
      if (cache.isExpired()) {
        expiredCount++;
      }
    }
    
    print("   Expired entries: $expiredCount");
    print("   Valid entries: ${_storage.length - expiredCount}");
    
    if (_storage.isNotEmpty) {
      print("   Keys: ${_storage.keys.join(', ')}");
    }
    print("");
  }
}

final class SimpleCache implements Cache {
  final Object? _value;
  final Duration? _ttl;
  final ZonedDateTime _createdAt;
  ZonedDateTime _lastAccessedAt;
  int _accessCount = 0;

  SimpleCache(this._value, {Duration? ttl}) 
    : _ttl = ttl,
      _createdAt = ZonedDateTime.now(),
      _lastAccessedAt = ZonedDateTime.now() {
    print("🆕 [SimpleCache] Created cache entry for value: $_value with TTL: $ttl");
  }

  @override
  Object? get() {
    print("🔍 [SimpleCache] Getting cached value");
    recordAccess();
    return _value;
  }

  @override
  int getAccessCount() {
    print("📈 [SimpleCache] Getting access count: $_accessCount");
    return _accessCount;
  }

  @override
  int getAgeInMilliseconds() {
    final age = _createdAt.offsetInMilliseconds;
    print("⏰ [SimpleCache] Getting age in milliseconds: $age");
    return age;
  }

  @override
  ZonedDateTime getCreatedAt() {
    print("🕐 [SimpleCache] Getting creation time: $_createdAt");
    return _createdAt;
  }

  @override
  ZonedDateTime getLastAccessedAt() {
    print("🕐 [SimpleCache] Getting last access time: $_lastAccessedAt");
    return _lastAccessedAt;
  }

  @override
  Duration? getRemainingTtl() {
    if (_ttl == null) {
      print("∞ [SimpleCache] No TTL set, remaining TTL is null");
      return null;
    }
    
    final age = Duration(milliseconds: getAgeInMilliseconds());
    final remaining = _ttl - age;
    
    if (remaining.isNegative) {
      print("⏰ [SimpleCache] TTL expired, remaining TTL: 0ms");
      return Duration.zero;
    } else {
      print("⏰ [SimpleCache] Remaining TTL: $remaining");
      return remaining;
    }
  }

  @override
  int getTimeSinceLastAccessInMilliseconds() {
    final timeSinceLastAccess = _lastAccessedAt.offsetInMilliseconds;
    print("⏰ [SimpleCache] Time since last access: ${timeSinceLastAccess}ms");
    return timeSinceLastAccess;
  }

  @override
  Duration? getTtl() {
    print("⏰ [SimpleCache] Getting original TTL: $_ttl");
    return _ttl;
  }

  @override
  bool isExpired() {
    if (_ttl == null) {
      print("✅ [SimpleCache] No TTL set, cache entry is not expired");
      return false;
    }
    
    final remainingTtl = getRemainingTtl();
    final expired = remainingTtl == Duration.zero;
    
    if (expired) {
      print("❌ [SimpleCache] Cache entry is EXPIRED");
    } else {
      print("✅ [SimpleCache] Cache entry is NOT expired");
    }
    
    return expired;
  }

  @override
  void recordAccess() {
    _accessCount++;
    _lastAccessedAt = ZonedDateTime.now();
    print("📝 [SimpleCache] Recorded access #$_accessCount at $_lastAccessedAt");
  }

  @override
  String toString() {
    return 'SimpleCache{value: $_value, accessCount: $_accessCount, createdAt: $_createdAt, lastAccessedAt: $_lastAccessedAt, ttl: $_ttl, expired: ${isExpired()}}';
  }
}