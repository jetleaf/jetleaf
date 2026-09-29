import 'dart:async';
import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_resource/jetleaf_resource.dart';

final class PersonalRateLimitStorage extends HashMap<Object, DefaultRateLimitEntry> implements Resource<Object, DefaultRateLimitEntry> {
  @override
  bool exists(Object key) => false;

  @override
  DefaultRateLimitEntry? get(Object key) => this[key];
}

final class RateLimitStorageExample implements RateLimitStorage {
  final PersonalRateLimitStorage _storage = PersonalRateLimitStorage();
  final String name;
  final RateLimitMetrics _metrics = InMemoryRateLimitMetrics('default');
  
  RateLimitStorageExample([this.name = 'rate-limit']);
  
  @override
  FutureOr<void> clear() {
    print("🧹 [RateLimitStorage] Clearing all entries from storage '$name'");
    final count = _storage.length;
    _storage.clear();
    _metrics.recordReset('all');
    print("✅ [RateLimitStorage] Cleared $count entries from storage '$name'");
  }

  @override
  List<Object?> equalizedProperties() => [name, runtimeType];

  @override
  FutureOr<RateLimitResult> tryConsume(Object identifier, int limit, Duration window) async {
    print("🔍 [RateLimitStorage] Checking rate limit for '$identifier': $limit requests per ${window.inSeconds}s");
    
    final now = ZonedDateTime.now();
    final windowKey = _generateWindowKey(identifier, window);
    var entry = _storage[windowKey];
    
    // Create new entry if doesn't exist or expired
    if (entry == null || entry.isExpired()) {
      print("🆕 [RateLimitStorage] Creating new rate limit window for '$identifier'");
      entry = DefaultRateLimitEntry(
        windowKey: windowKey,
        identifier: identifier,
        limitName: name,
        count: 0,
        timeStamp: now,
        resetTime: now.plus(window),
        window: window,
        zoneId: ZoneId.systemDefault(),
      );
      _storage[windowKey] = entry;
    }
    
    final currentCount = entry.getCount();
    final resetTime = entry.getResetTime();
    final retryAfter = _calculateRetryAfter(resetTime, now);
    
    // Create the result object
    final result = RateLimitResult(
      identifier: identifier,
      limitName: name,
      currentCount: currentCount,
      limit: limit,
      window: window,
      resetTime: resetTime,
      retryAfter: retryAfter,
      zoneId: ZoneId.systemDefault(),
    );
    
    if (!result.allowed) {
      print("🚫 [RateLimitStorage] Rate limit exceeded for '$identifier': $currentCount/$limit");
      _metrics.recordDenied(identifier);
      return result;
    }
    
    // Increment count and update result
    entry.increment();
    final updatedCount = entry.getCount();
    
    print("✅ [RateLimitStorage] Request allowed for '$identifier': $updatedCount/$limit");
    _metrics.recordAllowed(identifier);
    
    // Return updated result with new count
    return RateLimitResult(
      identifier: identifier,
      limitName: name,
      currentCount: updatedCount,
      limit: limit,
      window: window,
      resetTime: resetTime,
      retryAfter: retryAfter,
      zoneId: ZoneId.systemDefault(),
    );
  }

  @override
  FutureOr<void> recordRequest(Object identifier, Duration window) {
    print("📝 [RateLimitStorage] Recording request for '$identifier'");
    
    final now = ZonedDateTime.now();
    final windowKey = _generateWindowKey(identifier, window);
    var entry = _storage[windowKey];
    
    if (entry == null || entry.isExpired()) {
      print("🆕 [RateLimitStorage] Creating new entry for recording request");
      entry = DefaultRateLimitEntry(
        windowKey: windowKey,
        identifier: identifier,
        limitName: name,
        count: 1, // Start with 1 since we're recording a request
        timeStamp: now,
        resetTime: now.plus(window),
        window: window,
        zoneId: ZoneId.systemDefault(),
      );
      _storage[windowKey] = entry;
    } else {
      entry.increment();
    }
    
    _metrics.recordAllowed(identifier);
    print("✅ [RateLimitStorage] Recorded request for '$identifier', count: ${entry.getCount()}");
  }

  @override
  FutureOr<int> getRequestCount(Object identifier, Duration window) {
    final windowKey = _generateWindowKey(identifier, window);
    final entry = _storage[windowKey];
    
    if (entry == null || entry.isExpired()) {
      print("🔍 [RateLimitStorage] No active requests for '$identifier'");
      return 0;
    }
    
    final count = entry.getCount();
    print("🔍 [RateLimitStorage] Request count for '$identifier': $count");
    return count;
  }

  @override
  FutureOr<int> getRemainingRequests(Object identifier, int limit, Duration window) {
    final currentCount = getRequestCount(identifier, window);
    final remaining = limit - (currentCount as int);
    final finalRemaining = remaining < 0 ? 0 : remaining;
    
    print("🔍 [RateLimitStorage] Remaining requests for '$identifier': $finalRemaining/$limit");
    return finalRemaining;
  }

  @override
  FutureOr<DateTime?> getResetTime(Object identifier, Duration window) {
    final windowKey = _generateWindowKey(identifier, window);
    final entry = _storage[windowKey];
    
    if (entry == null || entry.isExpired()) {
      print("🔍 [RateLimitStorage] No reset time for '$identifier' (no active window)");
      return null;
    }
    
    final resetTime = entry.getResetTime();
    print("🔍 [RateLimitStorage] Reset time for '$identifier': $resetTime");
    return resetTime.toDateTime();
  }

  @override
  FutureOr<ZonedDateTime?> getRetryAfter(Object identifier, Duration window) {
    final windowKey = _generateWindowKey(identifier, window);
    final entry = _storage[windowKey];
    
    if (entry == null || entry.isExpired()) {
      print("🔍 [RateLimitStorage] No retry-after for '$identifier' (no active window)");
      return null;
    }
    
    final now = ZonedDateTime.now();
    final resetTime = entry.getResetTime();
    final retryAfter = resetTime.isAfter(now) ? resetTime : now;
    
    print("🔍 [RateLimitStorage] Retry after for '$identifier': $retryAfter");
    return retryAfter;
  }

  @override
  FutureOr<void> reset(Object identifier) {
    print("🔄 [RateLimitStorage] Resetting rate limit for '$identifier'");
    
    // Remove all windows for this identifier
    final keysToRemove = _storage.keys.where((key) => key.toString().startsWith('$identifier|')).toList();
    
    for (final key in keysToRemove) {
      _storage.remove(key);
      _metrics.recordReset(identifier);
    }
    
    print("✅ [RateLimitStorage] Reset ${keysToRemove.length} windows for '$identifier'");
  }

  @override
  FutureOr<void> invalidate() {
    print("♻️ [RateLimitStorage] Invalidating storage '$name'");
    // Clean up expired entries
    final expiredKeys = _storage.keys.where((key) {
      final entry = _storage[key];
      return entry != null && entry.isExpired();
    }).toList();
    
    for (final key in expiredKeys) {
      _storage.remove(key);
    }
    
    print("✅ [RateLimitStorage] Invalidated ${expiredKeys.length} expired entries");
  }

  @override
  String getName() {
    print("🏷️ [RateLimitStorage] Getting storage name: $name");
    return name;
  }

  @override
  PersonalRateLimitStorage getResource() {
    print("📦 [RateLimitStorage] Getting underlying store for storage '$name'");
    return _storage;
  }

  @override
  RateLimitMetrics getMetrics() {
    print("📊 [RateLimitStorage] Getting metrics for storage '$name'");
    return _metrics;
  }

  // Utility method to generate window keys
  String _generateWindowKey(Object identifier, Duration window) {
    final now = ZonedDateTime.now();
    // Create window boundaries based on window duration
    final windowStart = _calculateWindowStart(now, window);
    return '$identifier|${window.inSeconds}s|${windowStart.toDateTime().millisecondsSinceEpoch}';
  }

  // Calculate window start time based on current time and window duration
  ZonedDateTime _calculateWindowStart(ZonedDateTime now, Duration window) {
    DateTime dateTime;

    if (window.inSeconds <= 60) {
      // For windows <= 1 minute, round to second
      dateTime = DateTime(now.year, now.month, now.day, now.hour, now.minute, now.second);
    } else if (window.inSeconds <= 3600) {
      // For windows <= 1 hour, round to minute
      dateTime = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    } else {
      // For longer windows, round to hour
      dateTime = DateTime(now.year, now.month, now.day, now.hour);
    }

    return ZonedDateTime.fromDateTime(dateTime);
  }

  // Calculate retry after duration
  Duration _calculateRetryAfter(ZonedDateTime resetTime, ZonedDateTime now) {
    if (resetTime.isAfter(now)) {
      return Duration(milliseconds: resetTime.toDateTime().millisecondsSinceEpoch - now.toDateTime().millisecondsSinceEpoch);
    }
    return Duration.zero;
  }

  // Utility method for monitoring
  void printStats() {
    print("\n📊 [RateLimitStorage] Storage '$name' Statistics:");
    print("   Total active windows: ${_storage.length}");
    
    int expiredCount = 0;
    int activeCount = 0;
    
    for (final entry in _storage.values) {
      if (entry.isExpired()) {
        expiredCount++;
      } else {
        activeCount++;
      }
    }
    
    print("   Active windows: $activeCount");
    print("   Expired windows: $expiredCount");
    
    final metrics = getMetrics();
    print("   Allowed requests: ${metrics.getAllowedRequests()}");
    print("   Denied requests: ${metrics.getDeniedRequests()}");
    print("   Reset operations: ${metrics.getResets()}");
    
    if (_storage.isNotEmpty) {
      print("   Active keys: ${_storage.keys.take(5).join(', ')}${_storage.length > 5 ? '...' : ''}");
    }
    print("");
  }
}

final class DefaultRateLimitEntry implements RateLimitEntry {
  final String _windowKey;
  final Object _identifier;
  final String _limitName;
  int _count;
  final ZonedDateTime _timeStamp;
  final ZonedDateTime _resetTime;
  final Duration _window;
  final ZoneId _zoneId;

  DefaultRateLimitEntry({
    required String windowKey,
    required Object identifier,
    required String limitName,
    required int count,
    required ZonedDateTime timeStamp,
    required ZonedDateTime resetTime,
    required Duration window,
    required ZoneId zoneId,
  }) : _windowKey = windowKey,
       _identifier = identifier,
       _limitName = limitName,
       _count = count,
       _timeStamp = timeStamp,
       _resetTime = resetTime,
       _window = window,
       _zoneId = zoneId {
    print("🆕 [DefaultRateLimitEntry] Created entry for '$_identifier' with count: $_count");
  }

  @override
  String getWindowKey() {
    print("🔑 [DefaultRateLimitEntry] Getting window key: $_windowKey");
    return _windowKey;
  }

  @override
  bool isExpired() {
    final now = ZonedDateTime.now();
    final expired = now.isAfter(_resetTime);
    
    if (expired) {
      print("⏰ [DefaultRateLimitEntry] Window expired for $_identifier");
    } else {
      final remaining = Duration(milliseconds: _resetTime.toDateTime().millisecondsSinceEpoch - now.toDateTime().millisecondsSinceEpoch);
      print("✅ [DefaultRateLimitEntry] Window active for $_identifier (${remaining.inSeconds}s remaining)");
    }
    
    return expired;
  }

  @override
  int getCount() {
    print("🔢 [DefaultRateLimitEntry] Getting count for $_identifier: $_count");
    return _count;
  }

  @override
  int decrement() => _count--;

  @override
  int secondsUntilReset() => 0;

  @override
  void increment() {
    _count++;
    print("➕ [DefaultRateLimitEntry] Incremented count for $_identifier: $_count");
  }

  @override
  ZonedDateTime getTimeStamp() {
    print("🕐 [DefaultRateLimitEntry] Getting timestamp for $_identifier: $_timeStamp");
    return _timeStamp;
  }

  @override
  ZonedDateTime getResetTime() {
    print("🔄 [DefaultRateLimitEntry] Getting reset time for $_identifier: $_resetTime");
    return _resetTime;
  }

  @override
  ZonedDateTime getRetryAfter() {
    final now = ZonedDateTime.now();
    final retryAfter = _resetTime.isAfter(now) ? _resetTime : now;
    print("⏳ [DefaultRateLimitEntry] Getting retry after for $_identifier: $retryAfter");
    return retryAfter;
  }

  @override
  Duration getWindowDuration() {
    print("⏱️ [DefaultRateLimitEntry] Getting window duration for $_identifier: $_window");
    return _window;
  }

  @override
  void reset() {
    print("🔄 [DefaultRateLimitEntry] Resetting entry for $_identifier");
    _count = 0;
  }

  /// Creates a RateLimitResult from this entry
  RateLimitResult toRateLimitResult(int limit) {
    final now = DateTime.now();
    final retryAfter = Duration(milliseconds: _resetTime.toDateTime().millisecondsSinceEpoch - now.millisecondsSinceEpoch);
    
    return RateLimitResult(
      identifier: _identifier,
      limitName: _limitName,
      currentCount: _count,
      limit: limit,
      window: _window,
      resetTime: _resetTime,
      retryAfter: retryAfter,
      zoneId: _zoneId,
    );
  }

  @override
  String toString() {
    return 'DefaultRateLimitEntry{identifier: $_identifier, count: $_count, limitName: $_limitName, timestamp: $_timeStamp, resetTime: $_resetTime, window: $_window, expired: ${isExpired()}}';
  }
}

final class InMemoryRateLimitMetrics implements RateLimitMetrics {
  final String _name;
  final Map<Object, int> _allowedRequests = {};
  final Map<Object, int> _deniedRequests = {};
  final Map<Object, int> _resets = {};
  ZonedDateTime _lastUpdated = ZonedDateTime.now();
  int _totalAllowed = 0;
  int _totalDenied = 0;
  int _totalResets = 0;

  InMemoryRateLimitMetrics(this._name) {
    print("🆕 [InMemoryRateLimitMetrics] Created metrics tracker: $_name");
  }

  @override
  String getName() {
    print("🏷️ [InMemoryRateLimitMetrics] Getting name: $_name");
    return _name;
  }

  @override
  int getAllowedRequests() {
    print("📈 [InMemoryRateLimitMetrics] Total allowed requests: $_totalAllowed");
    return _totalAllowed;
  }

  @override
  int getDeniedRequests() {
    print("📈 [InMemoryRateLimitMetrics] Total denied requests: $_totalDenied");
    return _totalDenied;
  }

  @override
  int getResets() {
    print("📈 [InMemoryRateLimitMetrics] Total resets: $_totalResets");
    return _totalResets;
  }

  @override
  ZonedDateTime getLastUpdated() {
    print("🕐 [InMemoryRateLimitMetrics] Last updated: $_lastUpdated");
    return _lastUpdated;
  }

  @override
  void recordAllowed(Object identifier) {
    _allowedRequests[identifier] = (_allowedRequests[identifier] ?? 0) + 1;
    _totalAllowed++;
    _lastUpdated = ZonedDateTime.now();
    print("✅ [InMemoryRateLimitMetrics] Recorded allowed request for '$identifier' (total: ${_allowedRequests[identifier]})");
  }

  @override
  void recordDenied(Object identifier) {
    _deniedRequests[identifier] = (_deniedRequests[identifier] ?? 0) + 1;
    _totalDenied++;
    _lastUpdated = ZonedDateTime.now();
    print("🚫 [InMemoryRateLimitMetrics] Recorded denied request for '$identifier' (total: ${_deniedRequests[identifier]})");
  }

  @override
  void recordReset(Object identifier) {
    _resets[identifier] = (_resets[identifier] ?? 0) + 1;
    _totalResets++;
    _lastUpdated = ZonedDateTime.now();
    print("🔄 [InMemoryRateLimitMetrics] Recorded reset for '$identifier' (total: ${_resets[identifier]})");
  }

  @override
  void reset() {
    _allowedRequests.clear();
    _deniedRequests.clear();
    _resets.clear();
    _totalAllowed = 0;
    _totalDenied = 0;
    _totalResets = 0;
    _lastUpdated = ZonedDateTime.now();
    print("🔄 [InMemoryRateLimitMetrics] Reset all metrics for '$_name'");
  }

  @override
  Map<String, Object> buildGraph() {
    final graph = {
      'rate_limit_name': _name,
      'operations': {
        'allowed': Map.from(_allowedRequests),
        'denied': Map.from(_deniedRequests),
        'resets': Map.from(_resets),
      },
      'totals': {
        'allowed': _totalAllowed,
        'denied': _totalDenied,
        'resets': _totalResets,
      },
      'last_updated': _lastUpdated.toDateTime().toIso8601String(),
    };
    
    print("📊 [InMemoryRateLimitMetrics] Built metrics graph for '$_name'");
    return graph;
  }

  @override
  int decrementAllowed(Object identifier) {
    final current = _allowedRequests[identifier] ?? 0;
    final newCount = current > 0 ? current - 1 : 0;
    _allowedRequests[identifier] = newCount;
    _totalAllowed = _totalAllowed > 0 ? _totalAllowed - 1 : 0;
    _lastUpdated = ZonedDateTime.now();
    
    print("➖ [InMemoryRateLimitMetrics] Decremented allowed for '$identifier': $current -> $newCount");
    return newCount;
  }

  @override
  int decrementDenied(Object identifier) {
    final current = _deniedRequests[identifier] ?? 0;
    final newCount = current > 0 ? current - 1 : 0;
    _deniedRequests[identifier] = newCount;
    _totalDenied = _totalDenied > 0 ? _totalDenied - 1 : 0;
    _lastUpdated = ZonedDateTime.now();
    
    print("➖ [InMemoryRateLimitMetrics] Decremented denied for '$identifier': $current -> $newCount");
    return newCount;
  }

  @override
  String toString() {
    return 'InMemoryRateLimitMetrics{name: $_name, allowed: $_totalAllowed, denied: $_totalDenied, resets: $_totalResets, lastUpdated: $_lastUpdated}';
  }
}