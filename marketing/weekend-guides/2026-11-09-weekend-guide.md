Here is the complete **Full-Stack Dart Weekend Hack Guide** content package, produced across three ready-to-publish formats.

---

# Format A: X (Twitter) Mega-Thread

### 🧵 1/10 (Hook)
Stop context-switching between Flutter and Node/Go. You can now build enterprise-grade Dart backends with full Spring Boot / NestJS architecture.

Here’s how to build a full-stack **AI-Powered Workspace Engine** in 48 hours using Jetleaf + Flutter. 👇

---

### 🧵 2/10 (Architecture)
Here is the system architecture for our weekend hack:

```
[ Flutter Mobile/Web App ]
           │  (Shared Typed DTOs via jetson)
           ▼
┌─────────────────────────────────────────────────┐
│               JETLEAF BACKEND                   │
│  ┌─────────────────┐    ┌────────────────────┐  │
│  │ @RestController │───>│    TaskService     │  │
│  │ (jetleaf_web)   │    │      (@Pod)        │  │
│  └─────────────────┘    └────────────────────┘  │
│           │                       │             │
│  ┌─────────────────┐    ┌────────────────────┐  │
│  │ jetleaf_actuator│    │ jetleaf_validation │  │
│  └─────────────────┘    └────────────────────┘  │
└─────────────────────────────────────────────────┘
```

100% Dart. Zero boilerplate code-gen.

---

### 🧵 3/10 (CLI Setup)
Step 1: Install the `jl` CLI and scaffold your microservice.

```bash
dart pub global activate jetleaf_tools
jl create task_engine --template=web-actuator
cd task_engine
jl dev
```

`jl dev` starts the resident JetleafVM daemon with sub-second isolate pre-warming and true hot reload. ⚡️

---

### 🧵 4/10 (Shared DTO & Validation)
Step 2: Define your shared Request/Response DTOs using `jetleaf_validation`.

```dart
// shared/lib/models/create_task_dto.dart
import 'package:jetleaf_validation/jetleaf_validation.dart';

class CreateTaskDto {
  @NotNull()
  @Size(min: 3, max: 100)
  final String title;

  @NotNull()
  final String description;

  CreateTaskDto({required this.title, required this.description});
}
```

This exact DTO runs validation on the server AND typed forms in Flutter!

---

### 🧵 5/10 (IoC Business Logic)
Step 3: Create your business logic layer with `@Pod` for Inversion of Control.

```dart
// lib/services/task_service.dart
import 'package:jetleaf_core/jetleaf_core.dart';

@Pod()
class TaskService {
  final List<Map<String, dynamic>> _tasks = [];

  Future<Map<String, dynamic>> createTask(String title, String desc) async {
    final task = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'description': desc,
      'status': 'PENDING'
    };
    _tasks.add(task);
    return task;
  }
}
```

---

### 🧵 6/10 (REST Controller)
Step 4: Expose your REST API endpoints with declarative annotations.

```dart
// lib/controllers/task_controller.dart
import 'package:jetleaf_web/jetleaf_web.dart';
import 'package:jetleaf_validation/jetleaf_validation.dart';
import '../services/task_service.dart';

@RestController()
@RequestMapping('/api/v1/tasks')
class TaskController {
  final TaskService taskService;

  TaskController(this.taskService); // Constructor Injection

  @PostMapping('/')
  Future<ResponseEntity> create(@Valid() @RequestBody() CreateTaskDto dto) async {
    final result = await taskService.createTask(dto.title, dto.description);
    return ResponseEntity.created(result);
  }
}
```

---

### 🧵 7/10 (Production Telemetry)
Step 5: Zero-config production monitoring with `jetleaf_actuator`.

```dart
// lib/main.dart
import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_actuator/jetleaf_actuator.dart';

void main(List<String> args) {
  JetleafApplication.run(
    modules: [WebModule(), ActuatorModule()],
    args: args,
  );
}
```

Instant access to isolate health, RAM, and CPU metrics:
`GET http://localhost:8080/actuator/health`
`GET http://localhost:8080/actuator/metrics`

---

### 🧵 8/10 (Flutter Frontend Integration)
Step 6: Import your backend package models straight into Flutter.

```dart
import 'package:task_engine_shared/models/create_task_dto.dart';
import 'package:http/http.dart' as http;

Future<void> submitTask(String title, String desc) async {
  final dto = CreateTaskDto(title: title, description: desc);
  
  await http.post(
    Uri.parse('http://localhost:8080/api/v1/tasks'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(dto.toJson()),
  );
}
```
No OpenAPI generators. No mismatched JSON keys. Just pure Dart end-to-end.

---

### 🧵 9/10 (Testing & Hot Reload)
Step 7: Run high-speed isolated tests with the `jl` daemon.

```bash
jl test
```

Sub-second VM pre-warming means your unit and integration test suite runs instantly in memory. No 5-second Dart VM cold boot on every run.

---

### 🧵 10/10 (Call to Action)
Ready to build your next full-stack project in 100% Dart?

⭐ Star Jetleaf on GitHub: https://github.com/hapnium/jetleaf
📖 Docs & Guides: https://jetleaf.hapnium.com
📦 Pub: https://pub.dev/packages/jetleaf

Build faster. Ship cleaner. Stay in Dart. 🚀

---

# Format B: LinkedIn / Medium Step-by-Step Tutorial

# Full-Stack Dart Weekend Hack: Build an Enterprise Task Engine with Jetleaf & Flutter

For years, Flutter developers faced a familiar dilemma when building complete applications: context-switch to Node.js, Go, or Java for the backend, or rely on client-heavy BaaS solutions like Firebase.

With **Jetleaf**, Dart now has a modern, enterprise-grade framework designed around Inversion of Control (IoC), declarative annotations, and production observability — bringing the developer experience of Spring Boot and NestJS directly to the Dart ecosystem.

In this guide, we will build a full-stack **Task Engine** backend in Jetleaf and connect it to a Flutter frontend in a single weekend.

---

## Prerequisites
- Dart SDK `>=3.5.0`
- Flutter SDK `>=3.24.0`
- Jetleaf CLI (`jl`)

Install the `jl` CLI globally:
```bash
dart pub global activate jetleaf_tools
```

---

## Step 1: Project Scaffolding
Create a modular backend workspace using the standard `web-actuator` project structure:

```bash
jl create task_engine --template=web-actuator
cd task_engine
```

Start the live development environment with JetleafVM:
```bash
jl dev
```
`jl dev` keeps a warm Dart isolate in memory, enabling **sub-second hot reload** for server code changes.

---

## Step 2: Defining Data Transfer Objects & Validation
Jetleaf promotes typed contracts between your backend and frontend. Create a shared payload definition using `jetleaf_validation`:

`lib/dtos/create_task_dto.dart`:
```dart
import 'package:jetleaf_validation/jetleaf_validation.dart';

class CreateTaskDto {
  @NotNull(message: "Title cannot be null")
  @Size(min: 3, max: 100, message: "Title must be between 3 and 100 characters")
  final String title;

  @NotNull(message: "Description is required")
  final String description;

  CreateTaskDto({required this.title, required this.description});

  factory CreateTaskDto.fromJson(Map<String, dynamic> json) => CreateTaskDto(
        title: json['title'] as String,
        description: json['description'] as String,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
      };
}
```

---

## Step 3: Building the Service Layer (`@Pod`)
Jetleaf manages dependency resolution using typed `@Pod` instances. 

`lib/services/task_service.dart`:
```dart
import 'package:jetleaf_core/jetleaf_core.dart';

@Pod()
class TaskService {
  final List<Map<String, dynamic>> _storage = [];

  Future<Map<String, dynamic>> createTask(String title, String description) async {
    final task = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'description': description,
      'createdAt': DateTime.now().toIso8601String(),
    };
    _storage.add(task);
    return task;
  }

  List<Map<String, dynamic>> getAllTasks() => List.unmodifiable(_storage);
}
```

---

## Step 4: Constructing the REST Controller (`@RestController`)
Expose typed endpoints using `packages/jetleaf_web`. Inject the service instance via standard constructor injection.

`lib/controllers/task_controller.dart`:
```dart
import 'package:jetleaf_web/jetleaf_web.dart';
import 'package:jetleaf_validation/jetleaf_validation.dart';
import '../dtos/create_task_dto.dart';
import '../services/task_service.dart';

@RestController()
@RequestMapping('/api/v1/tasks')
class TaskController {
  final TaskService taskService;

  // Jetleaf automatically injects TaskService from the IoC Container
  TaskController(this.taskService);

  @GetMapping('/')
  Future<ResponseEntity> getAll() async {
    final tasks = taskService.getAllTasks();
    return ResponseEntity.ok(tasks);
  }

  @PostMapping('/')
  Future<ResponseEntity> create(@Valid() @RequestBody() CreateTaskDto dto) async {
    final createdTask = await taskService.createTask(dto.title, dto.description);
    return ResponseEntity.created(createdTask);
  }
}
```

---

## Step 5: Enabling Production Telemetry (`jetleaf_actuator`)
Production servers require insight into memory usage, active isolates, and process health. Register the `ActuatorModule` in your bootstrap entrypoint:

`lib/main.dart`:
```dart
import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_actuator/jetleaf_actuator.dart';
import 'package:jetleaf_web/jetleaf_web.dart';

void main(List<String> args) {
  JetleafApplication.run(
    modules: [
      WebModule(),
      ActuatorModule(),
    ],
    args: args,
  );
}
```

Test your operational health endpoint:
```bash
curl http://localhost:8080/actuator/health
# Output: {"status":"UP","isolate":"isolate-main","uptimeMs":1240}
```

---

## Step 6: Connecting the Flutter Frontend
Because both your backend and frontend are written in Dart, you can place your DTOs in a shared Dart package (`shared_models`) and import them directly into your Flutter UI:

```dart
// inside Flutter Screen widget
import 'package:shared_models/create_task_dto.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> handleTaskSubmission(String title, String description) async {
  final payload = CreateTaskDto(title: title, description: description);

  final response = await http.post(
    Uri.parse('http://10.0.2.2:8080/api/v1/tasks'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(payload.toJson()),
  );

  if (response.statusCode == 201) {
    print('Task successfully created on Jetleaf backend!');
  }
}
```

---

## Step 7: Fast Test Suites with `jl test`
Run enterprise integration tests using Jetleaf’s daemon test driver:

```bash
jl test
```

Jetleaf reuses warm isolates to run unit and API tests with sub-second feedback loops, allowing you to validate controllers and service pods instantaneously.

---

## Conclusion
Building full-stack apps no longer requires context-switching between different programming languages and framework paradigms. With **Jetleaf** on the backend and **Flutter** on the frontend, Dart developers get end-to-end type safety, high productivity, and production-grade software architecture.

### Resources
- 🌐 Website: [jetleaf.hapnium.com](https://jetleaf.hapnium.com)
- 📦 Pub: [pub.dev/packages/jetleaf](https://pub.dev/packages/jetleaf)
- 🐙 GitHub Repository: [github.com/hapnium/jetleaf](https://github.com/hapnium/jetleaf)

---

# Format C: Reddit / Discord Community Announcement

**Subreddits:** `r/FlutterDev`, `r/dartlang`  
**Discord Channels:** `#showcase`, `#dart-backend`, `#built-with-flutter`

### Title:
**[Showcase / Open Source] Built Spring Boot for Dart (Jetleaf) — Here is a step-by-step Weekend Guide for Full-Stack Dart**

---

### Body:

Hey r/FlutterDev & r/dartlang!

Like many of you, I love Dart and Flutter. But whenever it was time to build an enterprise API, I kept running into the same friction: context-switching to Node.js/Go/Java, re-writing data models across languages, or wrestling with light HTTP packages that lack formal Dependency Injection and configuration management.

We created **Jetleaf** (https://github.com/hapnium/jetleaf) to bring an enterprise-grade framework (inspired by Spring Boot and NestJS) directly to the Dart ecosystem.

### What makes Jetleaf different?
1. **True IoC & Dependency Injection:** Clean `@Pod` services, `@Configuration` classes, and automatic constructor injection without messy global singletons.
2. **Declarative Web Framework:** Annotate controllers using `@RestController`, `@GetMapping`, `@PostMapping`, `@Valid`, `@RequestBody`, and `ResponseEntity`.
3. **Resident Development VM (`jl dev`):** Sub-second hot reload for server code using pre-warmed Dart isolates.
4. **Built-in Actuator:** Production metrics, isolate health checks, and memory profiling out-of-the-box via `jetleaf_actuator`.
5. **Shared End-to-End DTOs:** Run your validation models (`@NotNull`, `@Size`, `@Email`) on both server and client without code-gen overhead.

---

### Quick Code Preview:

**The Service (`@Pod`):**
```dart
@Pod()
class TaskService {
  Future<Task> create(String title) async {
    // Business logic here
  }
}
```

**The REST Controller (`@RestController`):**
```dart
@RestController()
@RequestMapping('/api/v1/tasks')
class TaskController {
  final TaskService taskService;
  
  TaskController(this.taskService); // Auto-injected

  @PostMapping('/')
  Future<ResponseEntity> create(@Valid() @RequestBody() CreateTaskDto dto) async {
    final task = await taskService.create(dto.title);
    return ResponseEntity.created(task);
  }
}
```

---

### Weekend Hack Tutorial & Code
We just released a complete **Weekend Hack Guide** showing how to construct a complete task microservice backend with Jetleaf and hook it into a Flutter UI:

👉 **Read the full guide / documentation:** [jetleaf.hapnium.com](https://jetleaf.hapnium.com)  
👉 **Source Code & Core Framework:** [github.com/hapnium/jetleaf](https://github.com/hapnium/jetleaf)

We’d love for you to try out `jl create` and `jl dev`, give us your honest feedback, report bugs, or join in on expanding the ecosystem (Spring Data for Dart `jetleaf_data` and Spring Security `jetleaf_security` are currently on our active roadmap!).

What backend features do you want to see most in Dart? Let's discuss in the comments below! 👇
