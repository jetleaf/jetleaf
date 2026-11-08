# Jetson Example

This example demonstrates how to use the Jetson 2.0.0 object mapping engine for JSON and YAML serialization and deserialization.

## Features Covered
- Instantiating `JetsonObjectMapper`
- Serializing structured maps and models to formatted JSON (`writeValueAsString`)
- Deserializing JSON text into strongly-typed structures (`readValue<T>`)
- Multi-format serialization: Serializing maps to YAML (`writeYamlAsString`)

## Running the Example

From this directory:

```bash
dart run lib/main.dart
```
