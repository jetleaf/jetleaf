# Jetleaf Web Example

This example demonstrates how to use `jetleaf_web` to build RESTful APIs, define route specs with `RouterBuilder`, construct dynamic URIs with variable interpolation, work with `HttpHeaders` and `MediaType` content negotiation, and serialize structured responses with `jetson`.

## Running the Example

Run the example using the Dart CLI:

```bash
dart run lib/main.dart
```

## Features Highlighted

1. **Composable Routing (`RouterBuilder`):** Declarative route specifications with HTTP verbs (`GET`, `POST`, `PUT`, `DELETE`) and route prefix grouping.
2. **Dynamic URI Templating (`SimpleUriBuilder`):** Variable substitution (`/users/{id}/orders/{orderId}`) and query parameter formatting.
3. **HTTP Primitives & Content Negotiation:** Managing `HttpHeaders`, `HttpStatus`, and `MediaType` headers.
4. **JSON Serialization:** Direct integration with `jetson`'s `ObjectMapper` for REST payloads.
