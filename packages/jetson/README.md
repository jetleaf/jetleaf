# 📊 Jetson — JSON Object Mapping & Serialization

[![pub package](https://img.shields.io/badge/version-1.0.0-blue)](https://pub.dev/packages/jetson)
[![License](https://img.shields.io/badge/license-Jetleaf-green)](#license)
[![Dart SDK](https://img.shields.io/badge/sdk-%3E%3D3.9.0-blue)](https://dart.dev)

Flexible and extensible JSON serialization/deserialization library inspired by Jackson, with support for custom converters, naming strategies, and XML/YAML support.

## 📋 Overview

`jetson` provides comprehensive object mapping capabilities:

- **JSON Serialization/Deserialization** — Object ↔ JSON conversion
- **Custom Annotations** — `@JsonProperty`, `@JsonIgnore`, etc.
- **Type-Safe Mapping** — Generics support with runtime type information
- **Naming Strategies** — snake_case, camelCase, kebab-case conversion
- **Custom Converters** — User-defined serialization logic
- **XML & YAML Support** — Multi-format serialization
- **Date/Time Handling** — ISO-8601 and custom date formats
- **JSON Tree Traversal** — JSONNode for flexible parsing
- **Streaming JSON** — String generators and parsers

## 🚀 Quick Start

### Installation

```yaml
dependencies:
  jetson: ^1.0.0
```

### Basic Serialization/Deserialization

```dart
import 'package:jetson/jetson.dart';

class User {
  final String id;
  final String name;
  final String email;
  final int age;

  User({required this.id, required this.name, required this.email, required this.age});
}

void main() {
  final mapper = JetsonObjectMapper();

  // Serialize to JSON
  final user = User(
    id: '123',
    name: 'Alice',
    email: 'alice@example.com',
    age: 30,
  );

  final json = mapper.writeValueAsString(user);
  print(json);
  // {"id":"123","name":"Alice","email":"alice@example.com","age":30}

  // Deserialize from JSON
  final jsonString = '{"id":"456","name":"Bob","email":"bob@example.com","age":25}';
  final deserializedUser = mapper.readValue(
    jsonString,
    Class<User>(),
  );

  print(deserializedUser.name);  // Bob
}
```

## 📚 Key Features

### 1. Custom Annotations

**Control serialization behavior**:

```dart
import 'package:jetson/jetson.dart';

class Employee {
  @JsonProperty('emp_id')
  final String id;

  final String name;

  @JsonProperty(required: true)
  final String department;

  @JsonIgnore()
  final String? internalNotes;

  @JsonProperty(serialize: false)
  final String? tempValue;

  Employee({
    required this.id,
    required this.name,
    required this.department,
    this.internalNotes,
    this.tempValue,
  });
}

final emp = Employee(
  id: 'E001',
  name: 'John',
  department: 'Engineering',
  internalNotes: 'Note',
);

final mapper = JetsonObjectMapper();
final json = mapper.writeValueAsString(emp);
// {"emp_id":"E001","name":"John","department":"Engineering"}
// Note: internalNotes and tempValue are ignored
```

### 2. Naming Strategies

**Automatic field name conversion**:

```dart
import 'package:jetson/jetson.dart';

class Product {
  final String productName;
  final int stockQuantity;
  final double unitPrice;

  Product({
    required this.productName,
    required this.stockQuantity,
    required this.unitPrice,
  });
}

// snake_case
final mapperSnake = JetsonObjectMapper()
  .setNamingStrategy(SnakeCaseNamingStrategy());

// camelCase (default)
final mapperCamel = JetsonObjectMapper()
  .setNamingStrategy(CamelCaseNamingStrategy());

// kebab-case
final mapperKebab = JetsonObjectMapper()
  .setNamingStrategy(KebabCaseNamingStrategy());

final product = Product(
  productName: 'Laptop',
  stockQuantity: 50,
  unitPrice: 999.99,
);

// snake_case: {"product_name":"Laptop","stock_quantity":50,"unit_price":999.99}
// camelCase: {"productName":"Laptop","stockQuantity":50,"unitPrice":999.99}
// kebab-case: {"product-name":"Laptop","stock-quantity":50,"unit-price":999.99}
```

### 3. Custom Converters

**User-defined serialization logic**:

```dart
import 'package:jetson/jetson.dart';

class DateConverter implements JsonConverter<DateTime> {
  @override
  DateTime deserialize(dynamic json, DeserializationContext context) {
    if (json is String) {
      return DateTime.parse(json);
    }
    throw FormatException('Invalid date format');
  }

  @override
  dynamic serialize(DateTime value, SerializationContext context) {
    return value.toIso8601String();
  }
}

class Event {
  final String name;
  final DateTime date;

  Event({required this.name, required this.date});
}

final mapper = JetsonObjectMapper()
  .registerConverter(DateTime, DateConverter());

final event = Event(
  name: 'Conference',
  date: DateTime(2025, 6, 15),
);

final json = mapper.writeValueAsString(event);
// {"name":"Conference","date":"2025-06-15T00:00:00.000"}
```

### 4. Nested Objects

**Handle complex hierarchies**:

```dart
class Address {
  final String street;
  final String city;
  final String zipCode;

  Address({
    required this.street,
    required this.city,
    required this.zipCode,
  });
}

class Person {
  final String name;
  final Address address;
  final List<String> phoneNumbers;

  Person({
    required this.name,
    required this.address,
    required this.phoneNumbers,
  });
}

final mapper = JetsonObjectMapper();

final person = Person(
  name: 'Alice',
  address: Address(
    street: '123 Main St',
    city: 'Springfield',
    zipCode: '12345',
  ),
  phoneNumbers: ['555-1234', '555-5678'],
);

final json = mapper.writeValueAsString(person);
// {
//   "name": "Alice",
//   "address": {
//     "street": "123 Main St",
//     "city": "Springfield",
//     "zipCode": "12345"
//   },
//   "phoneNumbers": ["555-1234", "555-5678"]
// }
```

### 5. JSON Tree Navigation

**Flexible JSON parsing with JSONNode**:

```dart
import 'package:jetson/jetson.dart';

void main() {
  final jsonString = '''
  {
    "users": [
      {"id": 1, "name": "Alice", "email": "alice@example.com"},
      {"id": 2, "name": "Bob", "email": "bob@example.com"}
    ]
  }
  ''';

  final mapper = JetsonObjectMapper();
  final root = mapper.readTree(jsonString);

  // Navigate the tree
  final users = root.get('users');
  for (int i = 0; i < users.size(); i++) {
    final user = users.get(i);
    print('${user.get('name').asText()}: ${user.get('email').asText()}');
  }
}
```

### 6. XML Support

**Serialize/deserialize XML**:

```dart
import 'package:jetson/jetson.dart';

class Book {
  final String title;
  final String author;
  final int year;

  Book({required this.title, required this.author, required this.year});
}

final mapper = JetsonObjectMapper();

final book = Book(title: 'Dart Guide', author: 'Jane', year: 2024);

// Serialize to XML
final xml = mapper.writeValueAsXml(book);
/*
<?xml version="1.0"?>
<Book>
  <title>Dart Guide</title>
  <author>Jane</author>
  <year>2024</year>
</Book>
*/

// Deserialize from XML
final parsed = mapper.readValueFromXml(xml, Class<Book>());
print(parsed.title);  // Dart Guide
```

### 7. YAML Support

**Serialize/deserialize YAML**:

```dart
final yaml = '''
title: Dart Guide
author: Jane
year: 2024
''';

final mapper = JetsonObjectMapper();
final book = mapper.readValueFromYaml(yaml, Class<Book>());
print(book.author);  // Jane

// Serialize back to YAML
final yamlOutput = mapper.writeValueAsYaml(book);
```

### 8. Builder Configuration

**Fluent mapper configuration**:

```dart
final mapper = JetsonObjectMapperBuilder()
  .setNamingStrategy(SnakeCaseNamingStrategy())
  .registerConverter(DateTime, DateConverter())
  .disableFeature(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS)
  .enableFeature(SerializationFeature.INDENT_OUTPUT)
  .enableFeature(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES)
  .build();

final json = mapper.writeValueAsString(obj);
```

## 📖 Naming Strategies

| Strategy | Example | Use Case |
|----------|---------|----------|
| `SnakeCaseNamingStrategy` | `user_name` | Python/SQL compatibility |
| `CamelCaseNamingStrategy` | `userName` | JavaScript/JSON default |
| `KebabCaseNamingStrategy` | `user-name` | YAML/properties files |
| `PascalCaseNamingStrategy` | `UserName` | Java compatibility |

## 🎯 Common Patterns

### Pattern 1: API Request/Response Mapping

```dart
class CreateUserRequest {
  final String name;
  final String email;

  CreateUserRequest({required this.name, required this.email});
}

class UserResponse {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  UserResponse({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });
}

@RestController('/api/users')
class UserController {
  final UserService _service;
  final JetsonObjectMapper _mapper;

  @Autowired
  UserController(this._service, this._mapper);

  @PostMapping('/')
  Future<HttpResponse> createUser(@RequestBody String json) async {
    final request = _mapper.readValue(json, Class<CreateUserRequest>());
    final user = await _service.createUser(request.name, request.email);
    final response = UserResponse(
      id: user.id,
      name: user.name,
      email: user.email,
      createdAt: user.createdAt,
    );
    return HttpResponse.created(_mapper.writeValueAsString(response));
  }
}
```

### Pattern 2: Database ↔ JSON Mapping

```dart
class DatabaseRecord {
  @JsonProperty('user_id')
  final String userId;

  @JsonProperty('created_at')
  final DateTime createdAt;

  @JsonIgnore()
  final String? internalId;

  DatabaseRecord({
    required this.userId,
    required this.createdAt,
    this.internalId,
  });
}
```

### Pattern 3: Configuration File Loading

```dart
class AppConfig {
  final String appName;
  final int serverPort;
  final String databaseUrl;
  final Map<String, String> features;

  AppConfig({
    required this.appName,
    required this.serverPort,
    required this.databaseUrl,
    required this.features,
  });
}

// Load from YAML or JSON
final configJson = File('config/app.json').readAsStringSync();
final mapper = JetsonObjectMapper();
final config = mapper.readValue(configJson, Class<AppConfig>());
```

## ⚠️ Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Type mismatch | JSON type doesn't match field type | Provide custom converter |
| Unknown property error | Extra properties in JSON | Use `FAIL_ON_UNKNOWN_PROPERTIES` feature |
| Null values included | Default serialization behavior | Use `@JsonProperty(required: false)` |
| Date format errors | Invalid date format | Register custom DateConverter |

## 📋 Best Practices

### ✅ DO

- Use `@JsonProperty` to rename fields
- Create custom converters for complex types
- Use naming strategies for API compatibility
- Validate data after deserialization
- Test serialization/deserialization roundtrips
- Document custom converters

### ❌ DON'T

- Use generic `dynamic` types
- Ignore serialization errors
- Share mapper instances without thread safety consideration
- Rely on field order
- Mix multiple naming strategies in one object

## 📦 Dependencies

- **`jetleaf_lang`** — Language utilities
- **`jetleaf_convert`** — Type conversion
- **`meta`** — Annotations

## 📄 License

This package is part of the Jetleaf Framework. See LICENSE in the root directory.

## 🔗 Related Packages

- **`jetleaf_web`** — HTTP integration
- **`jetleaf_convert`** — Type conversion utilities
- **`jetleaf_env`** — Configuration

## 📞 Support

For issues, questions, or contributions, visit:
- [GitHub Issues](https://github.com/jetleaf/jetson/issues)
- [Documentation](https://jetleaf.hapnium.com/docs/jetson)
- [Community Forum](https://forum.jetleaf.hapnium.com)

---

**Created with ❤️ by [Hapnium](https://hapnium.com)**
