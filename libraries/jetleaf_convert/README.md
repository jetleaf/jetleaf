# Jetleaf Convert

A powerful type conversion library for Dart that provides high-level conversion capabilities between different data types. This package is part of the Jetleaf framework and offers a flexible and extensible way to handle type conversions in your Dart applications.

## Features

- **Type Conversion**: Convert between various Dart and custom types
- **Extensible**: Easily add custom converters for your types
- **Format Support**: Built-in support for common data formats
- **Null Safety**: Fully null-safe implementation
- **Dependency Injection**: Seamless integration with dependency injection systems

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  jetleaf_convert: ^1.0.0
```

## Quick Start

```dart
import 'package:jetleaf_convert/jetleaf_convert.dart';

void main() {
  // Create a conversion service
  final conversionService = DefaultConversionService();
  
  // Convert between types
  final int number = conversionService.convert('42', int);
  print(number); // 42
  
  // Convert collections
  final List<Object> stringList = conversionService.convert([1, 2, 3], List<String>);
  print(stringList); // ['1', '2', '3']
}
```

## Documentation

For detailed documentation, please refer to the [API Reference](doc/api/README.md).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
