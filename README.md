<div align="center">

# Jetleaf

**Enterprise-grade backend framework bringing dependency injection, configuration management, and application lifecycle to Dart.**

[![pub package](https://img.shields.io/pub/v/jetleaf.svg?logo=dart&logoColor=white&color=0b2ab5)](https://pub.dev/packages/jetleaf)
[![tests](https://img.shields.io/badge/tests-137%2B%20passing-brightgreen.svg?logo=github)](https://github.com/jetleaf/jetleaf)
[![pure AOT](https://img.shields.io/badge/AOT-100%25%20mirror--free-success.svg)](https://pub.dev/packages/jetleaf)
[![license](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![platform](https://img.shields.io/badge/platform-dart%20%7C%20server%20%7C%20cli%20%7C%20web%20%7C%20docker-lightgrey)](https://pub.dev/packages/jetleaf)

</div>

<p align="left">
  <a href="#-features">Features</a> •
  <a href="#-installation">Installation</a> •
  <a href="#-quick-start">Quick Start</a> •
  <a href="#-architectural-overview">Architecture</a> •
  <a href="#-core-concepts">Core Concepts</a> •
  <a href="#-application-types">Application Types</a> •
  <a href="#-ahead-of-time-aot-compilation">AOT Tooling</a> •
  <a href="#-ecosystem-packages">Ecosystem</a> •
  <a href="#-testing">Testing</a>
</p>

---

**Jetleaf** is a modern, modular, enterprise-grade backend application framework for Dart. Inspired by modern application paradigms and Spring Boot, Jetleaf brings declarative Inversion of Control (IoC), constructor & property dependency injection, automatic component discovery, hierarchical environment profiles, cross-cutting interceptors, and application lifecycle hooks to server-side Dart.

Designed from the ground up for **pure Ahead-of-Time (AOT) compilation (`dart compile exe`)**, Jetleaf uses static AST scanning and zero-reflection registries — delivering enterprise developer productivity with blazing-fast native startup times and zero mirror overhead.

```dart
import 'package:jetleaf/jetleaf.dart';
```

---

## ✨ Features

* **🚀 Declarative Application Bootstrap** — Rapid setup via `JetleafApplication.run()` with built-in banner rendering, PID tracking, environment resolution, and graceful shutdown signal handling (`SIGINT`, `SIGTERM`).
* **💉 Inversion of Control (IoC) & Pods** — Complete container lifecycle managing singleton and prototype pods, eager and lazy initialization (`@Lazy`), primary candidates (`@Primary`), and priority ordering (`@Order`).
* **⚡ 100% Mirror-Free AOT Compilation** — Ahead-of-Time static AST analysis synthesizes deterministic constructor and method invocation tables at build time, completely eliminating `dart:mirrors` and surviving Dart's aggressive tree-shaker.
* **📦 Component Stereotypes** — First-class declarative annotations: `@Component`, `@Service`, `@Repository`, `@Controller`, `@RestController`, `@Configuration`, and `@Pod`.
* **⚙️ Hierarchical Configuration & Properties** — Type-safe property binding (`@ConfigurationProperties`), `@Value` expression resolution, and cascade loading across command-line flags, environment variables, `.properties`, `.yaml`, and `.json`.
* **🎯 Multi-Profile Environments** — Activate granular profiles (`--jetleaf.profiles.active=dev,docker`) to load environment-specific properties (`application-dev.properties`) and conditional components.
* **🔄 Comprehensive Lifecycle Processors** — Standardized lifecycle execution phases: `@PostConstruct`, `@PreDestroy`, `@OnApplicationStarting`, and `@OnApplicationReady`.
* **💻 Universal Application Profiles** — Built-in execution profiles for web servers (`ApplicationType.WEB`) and command-line utilities / batch runners (`ApplicationType.NONE`).
* **📡 Decoupled Application Events** — Synchronous and asynchronous event dispatching with `@EventListener` and `ApplicationEvent` publishers.
* **🛠️ Native Tooling (`jetleaf_tools`)** — High-performance resident compiler CLI (`jl build`, `jl dev`) offering file watching, fast reloads, and automatic registry synthesis.

---

## 📦 Installation

Add `jetleaf` and its core dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  jetleaf: ^2.0.0
  jetleaf_core: ^2.0.0

dev_dependencies:
  jetleaf_tools: ^1.0.1
```

Fetch dependencies using `dart pub get`:

```sh
dart pub get
```

---

## 🚀 Quick Start

Here is a complete, runnable Jetleaf application:

```dart
import 'package:jetleaf/jetleaf.dart';

// 1. Declare a service component
@Service()
class GreeterService {
  String greet(String name) => 'Hello, $name! Welcome to Jetleaf 🍃';
}

// 2. Mark your main entry application starter
@JetleafApplicationStarter()
class ExampleApp implements CommandLineRunner {
  final GreeterService _greeterService;

  // Constructor dependency injection
  ExampleApp(this._greeterService);

  @override
  void run(List<String> args) {
    print(_greeterService.greet('Developer'));
  }
}

// 3. Bootstrap your application
void main(List<String> args) async {
  await JetleafApplication.run(
    ExampleApp,
    args,
  );
}
```

Run the application:

```sh
dart run bin/main.dart
```

---

## 🏛️ Architectural Overview

Jetleaf applications follow a clean, decoupled layered architecture:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                          Jetleaf Application                           │
├─────────────────────┬──────────────────────┬───────────────────────────┤
│    Bootstrap & CLI  │     IoC Container    │    Environment & Config   │
├─────────────────────┼──────────────────────┼───────────────────────────┤
│ • JetleafApplication│ • ListablePodFactory │ • PropertySources         │
│ • ApplicationRunner │ • DependencyResolver │ • Multi-Profile Resolvers │
│ • Lifecycle Hooks   │ • Early Singleton Mgt│ • @Value / ConfigBinding  │
├─────────────────────┴──────────────────────┴───────────────────────────┤
│                       AOT Static Dispatch Engine                       │
├────────────────────────────────────────────────────────────────────────┤
│ • AotRuntimeExecutor │ • Type Token Map    │ • Zero Mirrors Reflection │
│ • Constructor Tables │ • Member Adapters   │ • Tree-Shaking Resilient  │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 💡 Core Concepts

### 1. Application Bootstrap & `JetleafApplication`

The `JetleafApplication` class provides the central bootstrap pipeline:

```dart
void main(List<String> args) async {
  final app = JetleafApplication(MyApplication);
  app.setApplicationType(ApplicationType.NONE); // CLI Mode
  
  final context = await app.create(args, null);
  // Context is now running and fully initialized!
}
```

### 2. Dependency Injection & Pods

Pods are the basic building blocks managed by the Jetleaf IoC container. Dependencies are resolved through constructors, fields, and factory methods.

#### Constructor Injection (Recommended)

```dart
@Service()
class OrderService {
  final PaymentService _paymentService;
  final InventoryService _inventoryService;

  OrderService(this._paymentService, this._inventoryService);
}
```

#### Field Injection with `@Autowired`

```dart
@Component()
class ReportGenerator {
  @Autowired()
  late DatabaseConnection db;

  @Value('#{app.name:JetleafApp}')
  late String applicationName;
}
```

#### Factory Method Pods with `@Configuration`

```dart
@Configuration()
class AppConfig {
  @Pod()
  @Primary()
  HttpClient httpClient() {
    return HttpClient()..connectionTimeout = Duration(seconds: 10);
  }
}
```

### 3. Lifecycle Hooks

Jetleaf invokes lifecycle callbacks in a deterministic order during container setup and teardown:

```dart
@Component()
class CacheManager {
  @PostConstruct()
  void initialize() {
    print('Initializing in-memory cache storage...');
  }

  @OnApplicationReady()
  void onReady() {
    print('Application is ready to process traffic!');
  }

  @PreDestroy()
  void cleanup() {
    print('Flushing pending cache entries to persistent disk...');
  }
}
```

### 4. Hierarchical Properties & Profiles

Jetleaf reads properties from `application.properties`, `application.yaml`, environment variables, and CLI parameters.

Activate specific profiles with the active profile switch:

```sh
dart run bin/main.dart --jetleaf.profiles.active=prod
```

This merges `application-prod.properties` over the default configuration:

```properties
# application.properties
server.port=8080
database.url=postgres://localhost:5432/dev_db

# application-prod.properties
server.port=80
database.url=postgres://prod-cluster.internal:5432/prod_db
```

Inject configuration dynamically with `@Value` or bind strongly-typed objects:

```dart
@Service()
class ConfigurableWorker {
  @Value('#{server.port:8080}')
  late int port;

  @Value('#{database.url}')
  late String dbUrl;
}
```

---

## 💻 Application Types

Jetleaf adapts its lifecycle to your application's domain via [ApplicationType]:

| Application Type | Target Use Case | Lifecycle Characteristics |
|:---|:---|:---|
| **`ApplicationType.WEB`** | HTTP / REST APIs | Starts the embedded web server, registers web routes, and processes HTTP traffic. |
| **`ApplicationType.NONE`** | CLI / Batch / Tasks | Executes `ApplicationRunner` / `CommandLineRunner` and exits cleanly upon task completion. |

```dart
// Explicitly configure CLI mode
final app = JetleafApplication(CliTask);
app.setApplicationType(ApplicationType.NONE);
await app.create(args, null);
```

---

## ⚡ Ahead-of-Time (AOT) Compilation

Dart does not support `dart:mirrors` in native AOT compiled executables. Jetleaf solves this with **compile-time code synthesis** via `jetleaf_tools`.

### 1. Build Caches & Production Registry

Run the compiler to scan your components and generate static dispatchers in `lib/_jetleaf/`:

```sh
dart run jetleaf_tools build
```

This generates:
- `lib/_jetleaf/aot_registry.g.dart` — Master registry linking typed constructor and member functions.
- `lib/_jetleaf/<pkg>/registry_pods.g.dart` — Typed instance suppliers and lifecycle hooks.

### 2. Pass Generated Registrar to Bootstrap

```dart
import 'package:jetleaf/jetleaf.dart';
import '_jetleaf/aot_registry.g.dart';

void main(List<String> args) async {
  await JetleafApplication.run(
    MyApplication(),
    args,
    null,
    registerGeneratedAotPods, // Pure Dart function pointers
  );
}
```

### 3. Compile to Standalone Native Binary

Compile a self-contained, high-performance binary:

```sh
dart compile exe bin/main.dart -o server
./server
```

---

## 📦 Ecosystem Packages

Jetleaf provides a modular suite of official extensions:

| Package | Version | Description |
|:---|:---:|:---|
| [`jetleaf_core`](https://pub.dev/packages/jetleaf_core) | `^2.0.0` | Unified runtime engine: IoC, environments, properties, logging, and type conversions. |
| [`jetleaf_tools`](https://pub.dev/packages/jetleaf_tools) | `^1.0.0` | Developer tooling CLI (`jl`), static AST scanner, resident compiler daemon, and AOT generator. |
| [`jetleaf_web`](https://pub.dev/packages/jetleaf_web) | `^2.0.0` | High-throughput HTTP server, REST controllers, route mapping, and middleware pipeline. |
| [`jetleaf_resource`](https://pub.dev/packages/jetleaf_resource) | `^2.0.0` | Multi-source resource loading (`file:`, `classpath:`, `asset:`), caching, and profile assets. |
| [`jetleaf_scheduling`](https://pub.dev/packages/jetleaf_scheduling) | `^2.0.0` | Cron, fixed-rate, and delayed background task scheduling with `@Scheduled`. |
| [`jetleaf_retry`](https://pub.dev/packages/jetleaf_retry) | `^2.0.0` | Declarative fault-tolerance with exponential backoff retries and `@Recover` methods. |
| [`jetleaf_validation`](https://pub.dev/packages/jetleaf_validation) | `^2.0.0` | Bean and field validation framework (`@NotNull`, `@Size`, `@Email`, `@Pattern`). |
| [`jetleaf_monitor`](https://pub.dev/packages/jetleaf_monitor) | `^2.0.0` | Health checks, metrics collectors, latency timers, and actuator endpoints. |
| [`jetson`](https://pub.dev/packages/jetson) | `^2.0.0` | High-performance JSON serialization engine with zero mirrors. |
| [`jtl`](https://pub.dev/packages/jtl) | `^2.0.0` | Jetleaf Template Language for server-side HTML rendering. |

---

## 🧪 Testing

Jetleaf provides seamless integration with the `test` package:

```dart
import 'package:test/test.dart';
import 'package:jetleaf/jetleaf.dart';
import 'package:my_app/my_app.dart';
import 'package:my_app/_jetleaf/aot_registry.g.dart';

void main() {
  test('Boots application context and resolves service', () async {
    final app = JetleafApplication(MyApplication);
    app.setApplicationType(ApplicationType.NONE);
    app.setAotRegistrar(registerGeneratedAotPods);

    final context = await app.create([], null);
    expect(context, isNotNull);

    final greeter = await context!.getPod<GreeterService>('greeterService');
    expect(greeter.greet('Tester'), contains('Welcome'));

    await JetleafApplication.exit(context, []);
  });
}
```

Run test suite:

```sh
dart test
```

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](https://github.com/jetleaf/jetleaf/blob/main/CONTRIBUTING.md) and [Code of Conduct](https://github.com/jetleaf/jetleaf/blob/main/CODE_OF_CONDUCT.md).

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to your branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.
