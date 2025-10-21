# JetLeaf

🍃 **JetLeaf** is a comprehensive, enterprise-grade Dart backend framework that brings Jetleaf-like dependency injection, configuration management, and application lifecycle to Dart server-side development.

JetLeaf provides a complete foundation for building scalable, maintainable backend applications with powerful features like annotation-driven configuration, automatic component scanning, profile-based environments, and event-driven architecture.

- Homepage: https://jetleaf.hapnium.com
- Repository: https://github.com/jetleaf/jetleaf
- License: See `LICENSE`

## Contents
- **[Features](#features)**
- **[Install](#install)**
- **[Quick Start](#quick-start)**
- **[Core Concepts](#core-concepts)**
  - **[Application Bootstrap](#application-bootstrap)**
  - **[Dependency Injection](#dependency-injection)**
  - **[Configuration Management](#configuration-management)**
  - **[Component Scanning](#component-scanning)**
  - **[Lifecycle Management](#lifecycle-management)**
  - **[Profile Management](#profile-management)**
- **[Usage](#usage)**
  - **[Creating an Application](#creating-an-application)**
  - **[Configuration Classes](#configuration-classes)**
  - **[Services and Components](#services-and-components)**
  - **[Property Injection](#property-injection)**
  - **[Conditional Configuration](#conditional-configuration)**
  - **[Application Runners](#application-runners)**
  - **[Event Handling](#event-handling)**
- **[Configuration Files](#configuration-files)**
- **[CLI Tools](#cli-tools)**
- **[API Reference](#api-reference)**
- **[Examples](#examples)**
- **[Changelog](#changelog)**
- **[Contributing](#contributing)**
- **[Compatibility](#compatibility)**

## Features

### Core Framework
- **🚀 Application Bootstrap** – `JetApplication` for rapid application startup with `@JetLeafApplication`
- **💉 Dependency Injection** – Full IoC container with constructor, field, and setter injection
- **📦 Component Scanning** – Automatic discovery of `@Component`, `@Service`, `@Repository`, `@Controller`
- **⚙️ Configuration Management** – YAML, JSON, Properties, and Dart-based configuration
- **🔄 Lifecycle Management** – `@PostConstruct`, `@PreDestroy`, and context lifecycle hooks
- **🎯 Profile Management** – Environment-specific configuration with `@Profile`
- **🔀 Conditional Processing** – `@Conditional`, `@ConditionalOnProperty`, `@ConditionalOnPod`
- **📡 Event System** – Application-wide event publishing and listening
- **🌍 Internationalization** – Multi-locale message resolution
- **🎨 Banner Display** – Customizable startup banners

### Advanced Features
- **Auto-Configuration** – `@EnableAutoConfiguration` for framework and library auto-setup
- **Property Binding** – `@Value` for property injection with placeholders and expressions
- **Type Conversion** – Automatic type conversion for properties and dependencies
- **Circular Reference Handling** – Smart resolution of circular dependencies
- **Lazy Initialization** – `@Lazy` for deferred pod creation
- **Primary Pods** – `@Primary` for disambiguation when multiple candidates exist
- **Ordered Components** – `@Order` for component ordering
- **Exit Code Management** – Graceful shutdown with exit code generation
- **Exception Handling** – Comprehensive exception reporting and handling

## Install

Add to your `pubspec.yaml`:

```yaml
dependencies:
  jetleaf:
    hosted: https://onepub.dev/api/fahnhnofly/
    version: ^1.0.0
```

Minimum SDK: Dart ^3.9.0

Import:

```dart
import 'package:jetleaf/jetleaf.dart';
```

## Quick Start

### 1. Create Your Application

```dart
import 'package:jetleaf/jetleaf.dart';

void main(List<String> args) {
    JetApplication.run(MyApplication, args);
}

@JetLeafApplication()
class MyApplication {}
```

### 2. Define Services

```dart
@Service()
class UserService {
  final UserRepository repository;
  
  UserService(this.repository);
  
  Future<User> findById(String id) async {
    return await repository.findById(id);
  }
}

@Repository()
class UserRepository {
  Future<User> findById(String id) async {
    // Database access logic
    return User(id: id, name: 'John Doe');
  }
}
```

### 3. Create Configuration

```dart
@Configuration()
class DatabaseConfig {
  @Pod()
  DatabaseConnection databaseConnection() {
    return DatabaseConnection(
      host: 'localhost',
      port: 5432,
      database: 'myapp',
    );
  }
}
```

### 4. Run Your Application

```bash
dart run lib/main.dart
```

## Core Concepts

### Application Bootstrap

JetLeaf applications start with the `JetApplication` class, which handles:
- **Runtime Detection**: AOT vs JIT compilation detection
- **Bootstrap Context**: Early component registration
- **Environment Setup**: Property sources and profile activation
- **Context Creation**: Application context building and configuration
- **Lifecycle Management**: Startup, refresh, and shutdown orchestration

```dart
void main(List<String> args) async {
  final app = JetApplication(MyApplication);
  
  // Custom configuration
  app.setBannerMode(BannerMode.CONSOLE);
  app.setAdditionalProfiles({'production'});
  app.setLazyInitialization(true);
  
  // Add initializers
  app.addInitializer((context) {
    // Custom initialization
  });
  
  // Launch
  final context = await app.create(args, null);
}
```

### Dependency Injection

JetLeaf provides comprehensive dependency injection with multiple strategies:

**Constructor Injection** (recommended):
```dart
@Service()
class OrderService {
  final UserService userService;
  final PaymentService paymentService;
  
  OrderService(this.userService, this.paymentService);
}
```

**Field Injection**:
```dart
@Service()
class OrderService {
  @Autowired()
  late UserService userService;
  
  @Autowired()
  late PaymentService paymentService;
}
```

**Auto-Injection**:
```dart
@Service()
@RequiredAll()
class OrderService {
  late UserService userService;       // Auto-injected
  late PaymentService paymentService; // Auto-injected
}
```

### Configuration Management

JetLeaf supports multiple configuration formats:

**YAML Configuration** (`application.yaml`):
```yaml
server:
  port: 8080
  host: localhost

database:
  url: postgresql://localhost:5432/myapp
  maxConnections: 20

logging:
  level: INFO
```

**Properties Configuration** (`application.properties`):
```properties
server.port=8080
server.host=localhost
database.url=postgresql://localhost:5432/myapp
database.maxConnections=20
```

**Dart Configuration**:
```dart
@Configuration()
class AppConfig {
  @Pod()
  ServerConfig serverConfig() {
    return ServerConfig(port: 8080, host: 'localhost');
  }
}
```

### Component Scanning

JetLeaf automatically discovers and registers components:

**Stereotype Annotations**:
- `@Component` – Generic component
- `@Service` – Business logic layer
- `@Repository` – Data access layer
- `@Controller` – Presentation/routing layer

```dart
@Service()
class EmailService {
  Future<void> sendEmail(String to, String subject, String body) async {
    // Email sending logic
  }
}

@Repository()
class UserRepository {
  Future<User> save(User user) async {
    // Database persistence
  }
}

@Controller()
class UserController {
  final UserService userService;
  
  UserController(this.userService);
}
```

### Lifecycle Management

Control component lifecycle with annotations:

```dart
@Service()
class DatabaseService {
  late DatabaseConnection connection;
  
  @PostConstruct()
  Future<void> initialize() async {
    connection = await DatabaseConnection.connect();
    print('Database connected');
  }
  
  @PreDestroy()
  Future<void> cleanup() async {
    await connection.close();
    print('Database connection closed');
  }
}
```

### Profile Management

Configure environment-specific behavior:

```dart
@Configuration()
@Profile('development')
class DevConfig {
  @Pod()
  Logger logger() => Logger.debug();
}

@Configuration()
@Profile('production')
class ProdConfig {
  @Pod()
  Logger logger() => Logger.production();
}
```

Activate profiles via command line:
```bash
dart run lib/main.dart --jetleaf.profiles.active=production
```

## Usage

### Creating an Application

```dart
import 'package:jetleaf/jetleaf.dart';

@JetLeafApplication()
class MyApplication {
  static void main(List<String> args) {
    JetApplication.run(MyApplication, args);
  }
}
```

With custom configuration:
```dart
void main(List<String> args) async {
  final app = JetApplication(MyApplication);
  
  // Banner configuration
  app.setBannerMode(BannerMode.CONSOLE);
  
  // Profile activation
  app.setAdditionalProfiles({'production', 'cloud'});
  
  // Performance tuning
  app.setLazyInitialization(true);
  app.setAllowCircularReferences(false);
  
  // Custom initializers
  app.addInitializer((context) async {
    // Pre-refresh initialization
  });
  
  // Event listeners
  app.addListener(MyApplicationListener());
  
  // Launch application
  final context = await app.create(args, null);
}
```

### Configuration Classes

```dart
@Configuration()
class DatabaseConfig {
  @Value('#{database.url}')
  late String databaseUrl;
  
  @Value('#{database.maxConnections:20}')
  late int maxConnections;
  
  @Pod()
  DatabaseConnection primaryDatabase() {
    return DatabaseConnection(
      url: databaseUrl,
      maxConnections: maxConnections,
    );
  }
  
  @Pod('readOnlyDatabase')
  @Scope('prototype')
  DatabaseConnection readOnlyDatabase() {
    return DatabaseConnection(
      url: databaseUrl,
      readOnly: true,
    );
  }
}
```

### Services and Components

```dart
@Service()
class UserService {
  final UserRepository repository;
  final EmailService emailService;
  final Logger logger;
  
  UserService(this.repository, this.emailService, this.logger);
  
  Future<User> registerUser(CreateUserRequest request) async {
    logger.info('Registering user: ${request.email}');
    
    final user = await repository.save(User.fromRequest(request));
    
    await emailService.sendWelcomeEmail(user.email);
    
    return user;
  }
}

@Repository()
class UserRepository {
  final DatabaseConnection db;
  
  UserRepository(this.db);
  
  Future<User> save(User user) async {
    // Database persistence logic
    return user;
  }
  
  Future<User?> findByEmail(String email) async {
    // Database query logic
    return null;
  }
}
```

### Property Injection

```dart
@Component()
class ApiClient {
  @Value('#{api.baseUrl}')
  late String baseUrl;
  
  @Value('#{api.timeout:30}')
  late int timeout;
  
  @Value('#{api.apiKey}')
  late String apiKey;
  
  Future<Response> get(String endpoint) async {
    final url = '$baseUrl$endpoint';
    // HTTP request logic
  }
}
```

### Conditional Configuration

```dart
// Conditional on property
@ConditionalOnProperty(
  prefix: 'cache',
  names: ['enabled'],
  havingValue: 'true',
)
@Configuration()
class CacheConfig {
  @Pod()
  CacheManager cacheManager() => RedisCacheManager();
}

// Conditional on pod existence
@ConditionalOnPod(DatabaseConnection)
@Service()
class DatabaseMigrationService {
  final DatabaseConnection db;
  
  DatabaseMigrationService(this.db);
  
  @PostConstruct()
  Future<void> runMigrations() async {
    // Migration logic
  }
}

// Conditional on missing pod
@ConditionalOnMissingPod(CacheManager)
@Configuration()
class DefaultCacheConfig {
  @Pod()
  CacheManager cacheManager() => InMemoryCacheManager();
}
```

### Application Runners

Execute logic after application startup:

```dart
@Component()
class DataInitializer implements ApplicationRunner {
  final UserRepository userRepository;
  
  DataInitializer(this.userRepository);
  
  @override
  Future<void> run(ApplicationArguments args) async {
    print('Initializing data...');
    await userRepository.seedDefaultUsers();
  }
}

@Component()
class CommandLineProcessor implements CommandLineRunner {
  @override
  Future<void> run(List<String> args) async {
    print('Processing command line arguments: $args');
  }
}
```

### Event Handling

```dart
// Define custom event
class UserRegisteredEvent extends ApplicationEvent {
  final User user;
  
  UserRegisteredEvent(Object source, this.user) : super(source);
}

// Publish event
@Service()
class UserService {
  final ApplicationContext context;
  
  UserService(this.context);
  
  Future<User> registerUser(CreateUserRequest request) async {
    final user = await userRepository.save(request);
    
    // Publish event
    await context.publishEvent(UserRegisteredEvent(this, user));
    
    return user;
  }
}

// Listen to event
@Component()
class UserEventListener implements ApplicationEventListener<UserRegisteredEvent> {
  final EmailService emailService;
  
  UserEventListener(this.emailService);
  
  @override
  Future<void> onApplicationEvent(UserRegisteredEvent event) async {
    await emailService.sendWelcomeEmail(event.user.email);
  }
}
```

## Configuration Files

JetLeaf supports multiple configuration file formats in the `resources/` directory:

### application.yaml
```yaml
jetleaf:
  application:
    name: MyApplication
    version: 1.0.0
  profiles:
    active: development

server:
  port: 8080
  host: 0.0.0.0

database:
  url: postgresql://localhost:5432/myapp
  username: admin
  password: secret
  maxConnections: 20

logging:
  level: INFO
  pattern: "%d{yyyy-MM-dd HH:mm:ss} [%level] %logger - %msg"
```

### application.properties
```properties
jetleaf.application.name=MyApplication
jetleaf.application.version=1.0.0
jetleaf.profiles.active=development

server.port=8080
server.host=0.0.0.0

database.url=postgresql://localhost:5432/myapp
database.username=admin
database.password=secret
```

### Profile-Specific Configuration
- `application-dev.yaml` – Development profile
- `application-prod.yaml` – Production profile
- `application-test.yaml` – Test profile

## CLI Tools

JetLeaf provides CLI tools for development and deployment:

### Development
```bash
# Run in development mode with hot reload
jl dev

# Run with specific profile
jl dev --profile=development
```

### Build and Deploy
```bash
# Generate bootstrap file
jl generate

# Build production executable
jl build

# Generate and build
jl serve

# Run production build
dart run build/main.dill
```

## API Reference

### Main Exports (`lib/jetleaf.dart`)
- **Bootstrap**: `BootstrapContext`
- **Application**: `JetApplication`, `JetLeafApplication`
- **Lang**: Re-exports from `jetleaf_lang` (Class, Annotation, etc.)
- **Environment**: Re-exports from `jetleaf_env` (Environment, PropertyResolver, etc.)
- **Core**: Re-exports from `jetleaf_core` (ApplicationContext, annotations, etc.)
- **Convert**: Re-exports from `jetleaf_convert` (ConversionService, Converters, etc.)
- **Pod**: Re-exports from `jetleaf_pod` (PodFactory, PodDefinition, etc.)

### Key Classes
- **`JetApplication`**: Main application bootstrap class
- **`@JetLeafApplication`**: Application entry point annotation
- **`@EnableAutoConfiguration`**: Enable auto-configuration
- **`ApplicationContext`**: Central application container
- **`ConfigurableApplicationContext`**: Configurable context interface

### Annotations
- **Configuration**: `@Configuration`, `@AutoConfiguration`, `@Pod`
- **Stereotypes**: `@Component`, `@Service`, `@Repository`, `@Controller`
- **Dependency Injection**: `@Autowired`, `@Value`, `@Qualifier`, `@RequiredAll`
- **Lifecycle**: `@PostConstruct`, `@PreDestroy`, `@Lazy`
- **Conditional**: `@Conditional`, `@ConditionalOnProperty`, `@ConditionalOnPod`
- **Others**: `@Primary`, `@Scope`, `@Order`, `@Profile`

## Examples

### REST API Application
```dart
@JetLeafApplication()
class ApiApplication {
  static void main(List<String> args) {
    JetApplication.run(ApiApplication, args);
  }
}

@Controller()
class UserController {
  final UserService userService;
  
  UserController(this.userService);
  
  Future<Response> getUser(String id) async {
    final user = await userService.findById(id);
    return Response.ok(user);
  }
}
```

### Microservice with Database
```dart
@JetLeafApplication()
@EnableAutoConfiguration()
class MicroserviceApplication {
  static void main(List<String> args) {
    JetApplication.run(MicroserviceApplication, args);
  }
}

@Configuration()
class DatabaseConfig {
  @Pod()
  DatabaseConnection database(
    @Value('#{database.url}') String url,
    @Value('#{database.maxConnections}') int maxConnections,
  ) {
    return DatabaseConnection(url: url, maxConnections: maxConnections);
  }
}
```

### Scheduled Tasks
```dart
@Service()
class ScheduledTaskService {
  @Scheduled(cron: '0 0 * * * *') // Every hour
  Future<void> hourlyTask() async {
    print('Running hourly task');
  }
  
  @Scheduled(fixedDelay: Duration(minutes: 5))
  Future<void> periodicTask() async {
    print('Running every 5 minutes');
  }
}
```

## Changelog
See `CHANGELOG.md`.

## Contributing
Issues and PRs are welcome at the GitHub repository.

1. Fork and create a feature branch.
2. Add tests for new functionality.
3. Run `dart test` and ensure lints pass.
4. Open a PR with a concise description and examples.

## Compatibility
- Dart SDK: `>=3.9.0 <4.0.0`
- Depends on: `jetleaf_lang`, `jetleaf_logging`, `jetleaf_convert`, `jetleaf_core`, `jetleaf_utils`, `jetleaf_env`, `jetleaf_pod`

---

Built with 🍃 by the JetLeaf team.
