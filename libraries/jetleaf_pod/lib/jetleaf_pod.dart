/// 🫘 **Jetleaf Pod Entry Point**
///
/// This library provides a lightweight public entry to Jetleaf's
/// dependency-injection (DI) system by re-exporting the `pod.dart` module.
///
/// It serves as a convenience import for applications that only need the
/// **pod-facing APIs** rather than the full DI infrastructure.
///
///
/// ## ✅ What This Library Provides
///
/// Re-exported from `pod.dart`:
/// - core pod access helpers
/// - convenience APIs for retrieving managed components
/// - simplified interaction with the Jetleaf DI container
///
/// This keeps application code clean without exposing internals.
///
///
/// ## 🎯 Intended Usage
///
/// Prefer the simplified entry:
/// ```dart
/// import 'package:jetleaf_pod/jetleaf_pod.dart';
///
/// final service = pod<MyService>();
/// ```
///
/// Suitable for application-level usage, extensions, and integration layers.
///
///
/// © 2025 Hapnium & Jetleaf Contributors
library;

export 'pod.dart';