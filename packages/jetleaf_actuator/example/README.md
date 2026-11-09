# Jetleaf Actuator Example

This example demonstrates how to use `jetleaf_actuator` to capture process statistics, track memory analytics over time, build diagnostic monitoring reports, and serialize runtime health metrics into structured JSON with `jetson`.

## Running the Example

Run the example using the Dart CLI:

```bash
dart run lib/main.dart
```

## Features Highlighted

1. **Process Information Inspection:** Query resident memory (RSS), CPU core count, operating system platform, and Dart runtime metadata.
2. **Memory Readings & Analytics:** Capture chronological memory snapshots and compute aggregated statistics (min, max, average, current).
3. **Structured Monitoring Reports:** Compile full system state snapshots into a single immutable `DefaultMonitoringReport`.
4. **Structured JSON Export:** Serialize diagnostic reports into production-ready JSON payloads for Actuator and telemetry dashboards.