/// 📝 **Jetleaf Logging API Entry Point**
///
/// This library provides a unified import for Jetleaf's logging system,
/// combining both the core logging API and all built-in printer
/// implementations.
///
/// Instead of importing multiple modules, applications can access everything
/// through a single entry point.
///
///
/// ## ✅ Includes
///
/// ### 📦 Core Logging System
/// Re-exported from `logging.dart`:
/// - log levels, types, and steps
/// - `Log`, `LogFactory`, and configuration
/// - listeners and log record models
///
/// Typical usage:
/// ```dart
/// import 'package:jetleaf_logging/jetleaf_logging.dart';
///
/// final log = LogFactory.get('server');
/// log.info('Server started');
/// ```
///
///
/// ### 🖨️ Built-in Printers
/// Re-exported from `printers.dart`:
/// - pretty / flat / structured / hybrid printers
/// - prefix and simple formatting options
///
/// Example:
/// ```dart
/// final printer = PrettyPrinter();
/// ```
///
///
/// ## 🎯 Intended Usage
///
/// Preferred single import for application developers:
/// ```dart
/// import 'package:jetleaf_logging/jetleaf_logging.dart';
/// ```
///
/// This keeps logging configuration consistent and reduces import noise.
///
///
/// © 2025 Hapnium & Jetleaf Contributors
library;

export 'printers.dart';
export 'logging.dart';