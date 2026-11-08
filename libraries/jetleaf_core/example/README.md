# jetleaf_core example

A runnable showcase demonstrating the core architectural features of `jetleaf_core` 2.0.0.

## Running the Example

```sh
cd example
dart pub get
dart run lib/main.dart
```

## Features Demonstrated

1. **Environment Configuration (`jetleaf_core/env.dart`)**
   - Property sources, type-safe property retrieval, default fallbacks.
2. **Type Conversion (`jetleaf_core/convert.dart`)**
   - Registering custom converters (`Converter<String, Duration>`) into `DefaultConversionService`.
3. **Inversion of Control & Pod Lifecycle (`jetleaf_core/pod.dart`)**
   - Pod registration with `DefaultListablePodFactory`.
   - Constructor-based dependency injection.
   - Lifecycle integration via `InitializingPod` (`afterPropertiesSet`) and `DisposablePod` (`destroy`).
4. **Structured Logging (`jetleaf_core/logging.dart`)**
   - High-performance logger outputting structured lifecycle and audit diagnostics.