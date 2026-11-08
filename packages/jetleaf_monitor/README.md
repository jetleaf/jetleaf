# 📊 Jetleaf Monitor

[![pub package](https://img.shields.io/badge/pub-v2.0.0-blue.svg)](https://pub.dev/packages/jetleaf_monitor)
[![Dart](https://img.shields.io/badge/dart-%5E3.9.0-0175C2.svg?logo=dart)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Jetleaf Monitor** is the production-grade Actuator, telemetry, and diagnostics subsystem for the [Jetleaf Framework](https://jetleaf.hapnium.com). It provides lightweight, reflection-free, and AOT-safe runtime monitoring, process telemetry, memory analytics, and execution performance tracking.

---

## 🚀 Key Features

- **⚡ Zero Reflection & AOT Safe:** Built entirely for native ahead-of-time compilation with strict typing and no `dart:mirrors`.
- **💻 Host & Process Diagnostics:** Inspect operating system details, CPU cores, hostnames, and resident memory (RSS) in real time.
- **📈 Memory Trend Analytics:** Sample chronological memory readings and compute statistical summaries (min, max, average, and current memory consumption).
- **⏱️ Performance & Method Interception:** Non-intrusive method-level and pod-level execution profiling with the `@Monitor` annotation.
- **📦 Structured Diagnostic Reports:** Compile complete application snapshots into immutable, serialized `MonitoringReport` objects suitable for HTTP Actuator endpoints and observability dashboards.
- **🧩 Jetson Integration:** Seamless serialization of runtime health metrics into standardized JSON payloads.

---

## 📦 Installation

Add `jetleaf_monitor` to your `pubspec.yaml`:

```yaml
dependencies:
  jetleaf_core: ^2.0.0
  jetleaf_monitor: ^2.0.0
```

---

## 💡 Quick Start

### 1. Generating a Diagnostic Snapshot

```dart
import 'dart:io';
import 'package:jetleaf_monitor/jetleaf_monitor.dart';
import 'package:jetson/jetson.dart';

void main() {
  final startTime = DateTime.now().subtract(Duration(hours: 1));
  final uptime = DateTime.now().difference(startTime);

  // 1. Capture process characteristics
  final processInfo = DefaultProcessInformation(
    ProcessInfo.currentRss,
    0,
    ProcessInfo.maxRss,
  );

  // 2. Historical memory readings
  final readings = [
    DefaultMemoryReading(
      timestamp: startTime.add(Duration(minutes: 30)),
      memoryMB: 38.5,
      uptime: Duration(minutes: 30),
    ),
    DefaultMemoryReading(
      timestamp: DateTime.now(),
      memoryMB: ProcessInfo.currentRss / (1024 * 1024),
      uptime: uptime,
    ),
  ];

  // 3. Compute memory analytics
  final analytics = DefaultMemoryAnalytics(
    timeWindow: Duration(hours: 1),
    minMemoryMB: 38.5,
    maxMemoryMB: 52.0,
    avgMemoryMB: 45.2,
    currentMemoryMB: ProcessInfo.currentRss / (1024 * 1024),
    readings: readings,
  );

  // 4. Assemble the diagnostic report
  final report = DefaultMonitoringReport(
    processInfo,
    startTime,
    analytics,
    readings,
    uptime,
  );

  // 5. Serialize to JSON with Jetson
  final jsonPayload = ObjectMapper().writeValueAsString(report.toJson());
  print(jsonPayload);
}
```

---

### 2. Method Execution Tracking

Use `@Monitor` to track method invocation durations, memory spikes, and failures:

```dart
import 'package:jetleaf_monitor/jetleaf_monitor.dart';

class PaymentProcessor {
  @Monitor(name: 'processPayment')
  Future<void> processPayment(String transactionId) async {
    // Monitored method execution
  }
}
```

---

## 🔍 Core Abstractions

| Concept | Description |
|---|---|
| `ProcessInformation` | Host details, OS version, CPU counts, Dart VM version, and RSS memory values. |
| `MemoryReading` | Immutable snapshot of memory consumption at a specific timestamp and uptime. |
| `MemoryAnalytics` | Statistical aggregation over a collection of memory readings within a time window. |
| `MonitoringReport` | Holistic diagnostic payload capturing system state, uptime, and memory history. |
| `MonitoringService` | Background service managing scheduled health polling and metric collection. |

---

## 🤝 Contributing

Contributions are welcome! Please open an issue or submit a pull request on the [Jetleaf GitHub repository](https://github.com/jetleaf/jetleaf).

## 📄 License

Licensed under the MIT License. See [LICENSE](LICENSE) for details.