/// **Jetleaf Language Utilities**
///
/// This library acts as a lightweight entry point for Jetleaf's
/// language-level helpers and foundational runtime utilities.
///
/// It re-exports the `lang.dart` module, which provides core constructs,
/// type helpers, and language extensions used throughout the framework.
///
///
/// ## ✅ What This Library Provides
///
/// - foundational language abstractions
/// - utility types and helpers
/// - common patterns shared across Jetleaf modules
///
/// These are low-level building blocks—not application-level APIs.
///
///
/// ## 🎯 Intended Usage
///
/// Import when you need core language support:
/// ```dart
/// import 'package:jetleaf_lang/jetleaf_lang.dart';
/// ```
///
/// Most users will not need to import this directly unless working with
/// framework internals or building extensions.
library;

export 'lang.dart';
export 'package:jetleaf_build/jetleaf_build.dart';