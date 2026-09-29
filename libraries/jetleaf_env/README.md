# Jetleaf Environment

A comprehensive environment configuration library for Dart that provides flexible property resolution and profile management. This package is part of the Jetleaf framework and offers a powerful way to manage application configuration across different environments.

## Features

- **Unified Property Access**: Access properties from multiple sources (environment variables, YAML, JSON, etc.)
- **Profile-based Configuration**: Activate different configurations based on active profiles
- **Property Resolution**: Advanced property resolution with placeholders and fallbacks
- **Type-safe Configuration**: Strongly-typed configuration classes
- **Command Line Integration**: Seamless integration with command line arguments
- **Environment Awareness**: Built-in support for different runtime environments

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  jetleaf_env: ^1.0.0
```

## Quick Start

```dart
import 'package:jetleaf_env/jetleaf_env.dart';

void main() {
  // Create an environment with default configuration
  final env = StandardEnvironment();
  
  // Access properties
  final appName = env.getProperty('app.name');
  print('Application: $appName');
  
  // Work with profiles
  if (env.acceptsProfiles({'dev'})) {
    print('Running in development mode');
  }
  
  // Type-safe configuration
  final port = env.getProperty('server.port', int);
  print('Server port: $port');
}
```

## Core Concepts

### Property Sources
Properties can be loaded from various sources:
- System environment variables
- Application properties files (YAML, JSON, Dart)
- Command line arguments
- In-memory property maps

### Profiles
Profiles provide a way to register pods only when specific profiles are active:

```dart
// application-dev.yaml
database:
  url: 'localhost:5432/dev'

// application-prod.yaml
database:
  url: 'prod-db.example.com:5432/prod'
```

### Property Resolution
Properties support placeholders and nested property access:

```yaml
app:
  name: 'My App'
  welcome: 'Welcome to ${app.name}!'  
  server:
    port: 8080
    host: 'localhost'
    url: 'http://${app.server.host}:${app.server.port}'
```

## Documentation

For detailed documentation, please refer to the [API Reference](doc/README.md).

## License

This project is licensed under the terms of the MIT license. See the [LICENSE](LICENSE) file for details.
