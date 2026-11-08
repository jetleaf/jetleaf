// ignore_for_file: avoid_print

import 'package:jetleaf_core/lang.dart';
import 'package:jetleaf_resource/jetleaf_resource.dart';

void main() async {
  print('========================================================');
  print('  🍃 Jetleaf Resource 2.0.0 Showcase');
  print('========================================================\n');

  // 1. In-Memory Cache Storage with TTL
  print('[1] Cache Storage & Value Expiration:');
  final storage = DefaultCacheStorage.named('user-cache');
  final now = ZonedDateTime.now(ZoneId.UTC);

  final userCache = DefaultCache(
    {'id': 'usr_42', 'name': 'Sarah Connor'},
    const Duration(minutes: 10),
    now,
    ZoneId.UTC,
  );

  print('Cache Storage: "${storage.getName()}" initialized.');
  print('Stored Value: ${userCache.get()}');
  print('TTL Duration: ${userCache.getTtl()?.inMinutes} minutes');
  print('Is Expired? ${userCache.isExpired()}');

  userCache.recordAccess();
  print('Access Count recorded: ${userCache.getAccessCount()}\n');

  // 2. Rate-Limiting Sliding Window
  print('[2] Rate-Limiting Entry (Window & Throttling):');
  final rateEntry = SimpleRateLimitEntry(
    'client_ip:192.168.1.100',
    const Duration(minutes: 1),
    ZoneId.UTC,
  );

  print('Client Window Key: ${rateEntry.getWindowKey()}');
  print('Initial Request Count: ${rateEntry.getCount()}');

  // Simulate requests
  rateEntry.increment();
  rateEntry.increment();
  rateEntry.increment();
  print('Count after 3 requests: ${rateEntry.getCount()}');

  final decremented = rateEntry.decrement();
  print('Count after decrement rollback: $decremented');
  print('Is Window Expired? ${rateEntry.isExpired()}');

  print('\n========================================================');
  print('  ✅ Jetleaf Resource Example executed successfully!');
  print('========================================================');
}
