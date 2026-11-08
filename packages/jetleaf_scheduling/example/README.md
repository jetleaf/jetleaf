# Jetleaf Scheduling Example

This example demonstrates how to use `jetleaf_scheduling` 2.0.0 for cron parsing and asynchronous task scheduling.

## Features Covered
- Parsing and calculating next execution times with `CronExpression` and `CronTrigger`
- Timezone awareness using `ZoneId`
- Scheduling fixed-rate recurring jobs with `ConcurrentTaskScheduler`
- Task cancellation and graceful scheduler shutdown

## Running the Example

From this directory:

```bash
dart run lib/main.dart
```
