# JTL Example

This example demonstrates how to use the Jetleaf Template Language (JTL) 2.0.0 for dynamic HTML template rendering.

## Features Covered
- Instantiating `JtlFactory`
- Parsing and rendering dynamic HTML templates (`JtlTemplate`)
- Nested dot-notation variable resolution (`user.name`, `user.email`)
- Automatic HTML escaping to protect against XSS
- Custom filter registration (`registerFilter`) and application

## Running the Example

From this directory:

```bash
dart run lib/main.dart
```