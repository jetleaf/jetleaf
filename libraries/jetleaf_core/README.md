<div align="center">

# jetleaf_core

**The unified core runtime powering dependency injection, lifecycle management, environment configuration, logging, and type conversion for the Jetleaf framework.**

[![pub package](https://img.shields.io/pub/v/jetleaf_core.svg?logo=dart&logoColor=white&color=0b2ab5)](https://pub.dev/packages/jetleaf_core)
[![tests](https://img.shields.io/badge/tests-3600%2B%20passing-brightgreen.svg?logo=github)](https://github.com/jetleaf/jetleaf)
[![pure AOT](https://img.shields.io/badge/AOT-100%25%20mirror--free-success.svg)](https://pub.dev/packages/jetleaf_core)
[![license](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![platform](https://img.shields.io/badge/platform-dart%20%7C%20server%20%7C%20cli%20%7C%20web%20%7C%20flutter-lightgrey)](https://pub.dev/packages/jetleaf_core)

</div>

<p align="left">
  <a href="#-features">Features</a> •
  <a href="#-installation">Installation</a> •
  <a href="#-quick-start">Quick Start</a> •
  <a href="#-architectural-subsystems">Architecture & Subsystems</a> •
  <a href="#-dependency-injection-pods">Dependency Injection</a> •
  <a href="#-environment--properties">Environment & Config</a> •
  <a href="#-type-conversion">Type Conversion</a> •
  <a href="#-structured-logging">Logging</a> •
  <a href="#-language-primitives--collections">Language Primitives</a> •
  <a href="#-utilities">Utilities</a> •
  <a href="#-aot-compilation">AOT Compilation</a> •
  <a href="#-testing">Testing</a>
</p>

---

`jetleaf_core` is the enterprise-grade foundation of the Jetleaf application framework. It brings robust dependency injection, hierarchical configuration resolution, declarative metadata, event-driven decoupling, structured logging, and extensible type conversion to Dart — engineered from the ground up for **pure AOT compilation (`dart compile exe`)** with zero reflection runtime performance penalties.

```dart
// Import the complete unified framework
import 'package:jetleaf_core/jetleaf_core.dart';

// Or import specific modular entry points
import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_core/pod.dart';
import 'package:jetleaf_core/env.dart';
import 'package:jetleaf_core/logging.dart';
import 'package:jetleaf_core/convert.dart';
import 'package:jetleaf_core/utils.dart';
import 'package:jetleaf_core/lang.dart';
```

---

## ✨ Features

* **Unified 7-in-1 Architecture** — Consolidates the complete Jetleaf runtime (core context, pods/IoC, environment, logging, conversion, utilities, and language extensions) into a single cohesive package.
* **Declarative Inversion of Control (IoC)** — Full container lifecycle management (`GenericApplicationContext`, `AnnotationConfigApplicationContext`, `DefaultListablePodFactory`) supporting singleton and prototype scopes, eager/lazy initialization, constructor/property autowiring, and circular dependency resolution.
* **Hierarchical Environment & Properties** — Type-safe configuration binding (`@ConfigurationProperties`), multi-profile support (`dev`, `prod`, `test`), and hierarchical property resolution across environment variables, CLI options, YAML/JSON/Properties files, and custom property sources.
* **Pure AOT Native Compilation** — Completely mirror-free (`dart:mirrors` free). Generates deterministic dispatch registries at build time that survive Dart's aggressive tree-shaker without reflection compromises.
* **Decoupled Event Bus** — Synchronous and asynchronous application event dispatching (`ApplicationEvent`, `@EventListener`, `SimpleApplicationEventBus`) with ordering and payload validation.
* **Extensible Type Conversion Service** — Robust conversion pipeline (`ConversionService`, `ConverterRegistry`) covering primitives, collections, custom objects, enums, dates, and localized strings with bidirectional adapters.
* **Structured Leveled Logging** — Pluggable ANSI-formatted console logging with customizable log levels (`TRACE` through `FATAL`), formatters (`PrettyPrinter`, `FlatStructuredPrinter`, `FmtPrinter`), and filter pipelines.
* **High-Performance Collections & Functional Streams** — Low-overhead linear data structures (`ArrayList`, `LinkedList`, `Stack`, `Queue`, `HashMap`, `CaseInsensitiveMap`) and functional streams (`GenericStream`, `IntStream`, `DoubleStream`, `Collector`).
* **Cross-Cutting Method Interception** — Method interception hooks (`@Intercept`, `Interceptable`, `MethodInterceptor`) for declarative caching, audit trails, transactions, and metrics.

---

## 📦 Installation

Add `jetleaf_core` to your `pubspec.yaml`:

```yaml
dependencies:
  jetleaf_core: ^2.0.0

dev_dependencies:
  jetleaf_tools: ^1.0.0
```

Fetch dependencies:

```sh
dart pub get
```

---

## 🚀 Quick Start

Here is a complete, runnable example showcasing configuration classes, pods, dependency injection, and environment property resolution in under 40 lines of code:

```dart
import 'package:jetleaf_core/jetleaf_core.dart';

// 1. Define a domain service
@Service()
class UserService {
  final DatabaseClient _db;
  
  UserService(this._db);

  Future<void> createUser(String name) async {
    console.info('Creating user: $name via ${_db.url}');
  }
}

// 2. Define a dependency pod
class DatabaseClient {
  final String url;
  DatabaseClient(this.url);
}

// 3. Define an application configuration module
@Configuration()
class AppConfig {
  @Pod()
  DatabaseClient databaseClient(@Value('\${app.database.url:memory://default}') String url) {
    return DatabaseClient(url);
  }
}

void main() async {
  // 4. Initialize the application context
  final context = AnnotationConfigApplicationContext();
  context.register(AppConfig);
  context.register(UserService);
  await context.refresh();

  // 5. Retrieve and execute the managed pod
  final userService = context.getPod<UserService>();
  await userService.createUser('Alice');

  // 6. Gracefully shut down
  await context.close();
}
```

---

## 🏛 Architectural Subsystems

`jetleaf_core` is organized into 7 distinct, cohesive subsystems under `lib/src/`:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                          jetleaf_core (2.0.0)                          │
├──────────────┬──────────────┬──────────────┬──────────────┬────────────┤
│  src/core/   │   src/pod/   │   src/env/   │ src/logging/ │src/convert/│
│ Context,     │ IoC Container│ Environment, │ Structured   │ Type       │
│ Events,      │ Factories,   │ Profiles,    │ Loggers,     │ Conversion │
│ Lifecycle    │ Scopes       │ Properties   │ Printers     │ Pipeline   │
├──────────────┴──────────────┴──────────────┴──────────────┴────────────┤
│                src/lang/                │          src/utils/          │
│ Metaprogramming, Collections, I/O       │ Placeholders, Parsers, Assert│
└─────────────────────────────────────────┴──────────────────────────────┘
```

---

## 🫘 Dependency Injection (Pods)

The IoC container in `jetleaf_core` is built around the concept of **Pods** — lightweight, managed components that participate in dependency injection, lifecycle callbacks, and scoping.

### Registering Pods

Pods can be declared using annotations or registered programmatically:

```dart
// Declarative stereotype annotations
@Component()
class EmailNotifier implements Notifier {}

@Repository()
class OrderRepository {}

// Programmatic pod registration
final context = GenericApplicationContext();
context.registerPod<OrderRepository>();
context.registerPod<EmailNotifier>(name: 'primaryNotifier');
```

### Autowiring & Injection

Constructor injection is the recommended pattern:

```dart
@Service()
class OrderService {
  final OrderRepository repository;
  final Notifier notifier;

  // Dependencies are automatically resolved by type and qualifier
  OrderService(this.repository, @Qualifier('primaryNotifier') this.notifier);
}
```

### Pod Lifecycles & Callbacks

Components can hook into the container lifecycle via interfaces or annotations:

```dart
@Service()
class CacheService implements InitializingPod, DisposablePod {
  @override
  Future<void> onReady() async {
    console.info('Cache warmed up.');
  }

  @override
  Future<void> onDestroy() async {
    console.info('Cache flushed to disk.');
  }
}
```

---

## 🌍 Environment & Properties

The environment abstraction (`Environment`) provides unified access to runtime configuration, active profiles, and hierarchical property resolution.

### Hierarchical Resolution Order

Properties are resolved across multiple layered sources with deterministic precedence:

1. **Command Line Arguments** (`--server.port=8080`)
2. **System Environment Variables** (`SERVER_PORT=8080`)
3. **Profile-Specific Configuration** (`application-prod.yaml`)
4. **Default Configuration** (`application.yaml`)

```dart
final env = StandardEnvironment();
env.setActiveProfiles(['prod']);

// Placeholder resolution with default fallback syntax
final port = env.resolvePlaceholders('\${server.port:8080}');
final dbHost = env.getProperty<String>('database.host', defaultValue: 'localhost');
```

### Strongly-Typed Configuration Binding

Bind structured configuration maps directly into immutable classes:

```dart
@ConfigurationProperties(prefix: 'server')
class ServerConfig {
  final int port;
  final String host;
  final Duration timeout;

  const ServerConfig({
    required this.port,
    this.host = '0.0.0.0',
    this.timeout = const Duration(seconds: 30),
  });
}
```

---

## 🔄 Type Conversion

`jetleaf_core` includes a comprehensive type conversion service (`DefaultConversionService`) capable of converting between primitives, collections, complex objects, and dates:

```dart
import 'package:jetleaf_core/convert.dart';

final conversionService = DefaultConversionService();

// Primitives and numbers
final intVal = conversionService.convert<int>('42'); // 42
final boolVal = conversionService.convert<bool>('true'); // true

// Dates and durations
final duration = conversionService.convert<Duration>('5s'); // Duration(seconds: 5)
final dateTime = conversionService.convert<DateTime>('2026-11-08T07:00:00Z');

// Custom Converter Registration
conversionService.addConverter<String, GeoLocation>(
  Converter.from((source) => GeoLocation.parse(source)),
);
```

---

## 📝 Structured Logging

The logging engine (`package:jetleaf_core/logging.dart`) provides structured, leveled, colorized output with zero external dependencies:

```dart
import 'package:jetleaf_core/logging.dart';

// Quick global console logger
console.info('Application started successfully.');
console.warn('Cache hit ratio below 80%');
console.error('Database connection timeout', error: err, stackTrace: st);

// Custom scoped logger with formatted output
final logger = Logger(
  name: 'HTTP-Worker',
  level: LogLevel.DEBUG,
  printer: PrettyPrinter(),
);

logger.debug('Handled request in 12ms', tag: 'perf');
```

---

## 📚 Language Primitives & Collections

`jetleaf_core` bundles low-overhead, deterministic data structures and streaming pipelines:

| Structure | Access / Peek | Mutation | Memory Alignment |
| :--- | :--- | :--- | :--- |
| `ArrayList<T>` | $\mathcal{O}(1)$ | Amortized $\mathcal{O}(1)$ | Contiguous flat memory buffer |
| `LinkedList<T>` | $\mathcal{O}(n)$ | $\mathcal{O}(1)$ | Doubly linked node chain |
| `Stack<T>` / `LinkedStack<T>` | $\mathcal{O}(1)$ | $\mathcal{O}(1)$ | LIFO ring / node sequence |
| `Queue<T>` / `LinkedQueue<T>` | $\mathcal{O}(1)$ | $\mathcal{O}(1)$ | FIFO ring buffer |
| `CaseInsensitiveMap<V>` | $\mathcal{O}(1)$ avg | $\mathcal{O}(1)$ avg | Normalized header/key lookup |

### Functional Streams

```dart
import 'package:jetleaf_core/lang.dart';

final totalOrderAmount = GenericStream.of(orders)
    .filter((order) => order.isPaid)
    .mapToDouble((order) => order.total)
    .sum();
```

---

## 🧩 Utilities

- **`PropertyPlaceholderHelper`**: Fast, recursive `${placeholder:default}` resolution.
- **Parsers**: Native parsers for YAML, JSON, XML, `.env`, and `.properties`.
- **`Assert`**: Framework assertion preconditions (`Assert.notNull`, `Assert.hasText`, `Assert.state`).
- **`StackTraceParser`**: Clean stack trace parsing, frame mapping, and sanitization.

---

## ⚙️ AOT Compilation

`jetleaf_core` is architected for Dart's ahead-of-time (AOT) compiler:
1. Zero usage of `dart:mirrors`.
2. Static dispatch registries generated via `jetleaf_tools`.
3. Fully compatible with `dart compile exe` producing standalone, native OS binaries without external VM dependencies.

```sh
# Compile to a standalone binary
dart compile exe bin/main.dart -o build/server.exe

# Execute native binary
./build/server.exe
```

---

## 🧪 Testing

The repository includes over 3,600 automated tests exercising the container, factories, converters, logging formats, environment resolution, and collections:

```sh
# Run the test suite
dart test test/all_tests.dart
```

---

## 📄 License

Licensed under the Apache License, Version 2.0. See the [LICENSE](LICENSE) file for details.