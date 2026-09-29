# 🍃 Jetleaf Lang

[![License](https://img.shields.io/badge/License-Jetleaf-blue)](https://github.com/hapnium/jetleaf_framework/blob/main/LICENSE)
[![Pub Version](https://img.shields.io/pub/v/jetleaf_lang)](https://pub.dev/packages/jetleaf_lang)
[![Dart CI](https://github.com/hapnium/jetleaf_framework/actions/workflows/dart.yml/badge.svg)](https://github.com/hapnium/jetleaf_framework/actions/workflows/dart.yml)

## Overview

Jetleaf Lang is a comprehensive utility library for Dart that provides extended language features, collections, I/O operations, and more. It's part of the Jetleaf Framework ecosystem, designed to enhance Dart's standard library with additional functionality and convenience methods.

## Features

- **Extended Primitives**: Enhanced versions of Dart's built-in types
- **Collections**: Specialized collection types and utilities
- **I/O Operations**: Extended file and stream handling
- **Concurrency**: Threading and synchronization utilities
- **Math & Statistics**: Advanced mathematical operations and statistical functions
- **Time & Date**: Extended date/time manipulation
- **Networking**: Network-related utilities
- **System Interaction**: System-level operations and utilities

## Documentation

- [Getting Started](doc/getting_started.md) - How to add and use Jetleaf Lang in your project
- [Core Features](doc/core_features.md) - Detailed documentation of core features
- [API Reference](doc/api_reference.md) - Complete API documentation
- [Examples](doc/examples/) - Code examples and usage patterns

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  jetleaf_lang: ^1.0.0  # Use the latest version
```

Then run:
```bash
dart pub get
```

## Usage

```dart
import 'package:jetleaf_lang/jetleaf_lang.dart';

void main() {
  // Example usage
  final optional = Optional.of('Hello, Jetleaf!');
  print(optional.orElse('Default'));
}
```

## Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting pull requests.

## License

This project is licensed under the Jetleaf License - see the [LICENSE](LICENSE) file for details.

## Support

For support, please open an issue on our [GitHub repository](https://github.com/hapnium/jetleaf_framework).
