# Jetleaf Resource Example

This example demonstrates how to use `jetleaf_resource` 2.0.0 for in-memory caching and rate-limiting.

## Features Covered
- Creating and configuring named cache storage (`DefaultCacheStorage`)
- Associating entries with TTL, access counts, and expiration (`DefaultCache`)
- Rate-limiting sliding window tracking and increments (`SimpleRateLimitEntry`)
- Rollback capability (`decrement()`)

## Running the Example

From this directory:

```bash
dart run lib/main.dart
```
