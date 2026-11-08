# Jetleaf Retry Example

This example demonstrates how to use `jetleaf_retry` 2.0.0 for fault-tolerant retries, exponential backoffs, and fallback recovery.

## Features Covered
- Calculating dynamic exponential backoff intervals (`ExponentialBackoffPolicy`)
- Configuring resilient executors (`DefaultRetryExecutor`)
- Implementing `RetryCallback<T>` with automatic retry handling
- Implementing `RecoveryCallback<T>` fallback when retries are exhausted
- Tracking runtime retry metrics via `InMemoryStatistics`

## Running the Example

From this directory:

```bash
dart run lib/main.dart
```