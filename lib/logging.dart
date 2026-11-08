/// 🪵 **Jetleaf Logging Subsystem & Structured Diagnostics**
///
/// This library provides the centralized, high-performance structured logging
/// and diagnostics infrastructure for the Jetleaf framework.
///
/// It encapsulates:
/// - **Logger Abstractions:** [Log], [LogFactory], [LogLevel].
/// - **Standard Printers:** [PrettyPrinter], [FlatStructuredPrinter], [FmtPrinter].
/// - **Output Sinks:** [ConsoleLogger], [FileLogger], and configurable stream destinations.
/// - **Configurable Log Formatting:** Timestamps, thread/isolate identifiers, caller locations, and ANSI colors.
///
/// ---
///
/// ## 📊 Log Level Hierarchy
///
/// ```text
/// ┌────────────────────────────────────────────────────────────────────────┐
/// │                          LogLevel Priority Order                       │
/// ├────────────────────────────────────────────────────────────────────────┤
/// │ TRACE  ──►  DEBUG  ──►  INFO  ──►  WARN  ──►  ERROR  ──►  FATAL        │
/// ├────────────────────────────────────────────────────────────────────────┤
/// │ • Lowest: TRACE (fine-grained tracing, loop iterations, internal hops) │
/// │ • Default: INFO (standard lifecycle messages, service readiness)       │
/// │ • Highest: FATAL (unrecoverable system failure requiring termination)  │
/// └────────────────────────────────────────────────────────────────────────┘
/// ```
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### 🪵 Core Logger Contracts
/// - [Log] — primary logging interface with `trace`, `debug`, `info`, `warn`, `error`, and `fatal` methods.
/// - [LogFactory] — factory for retrieving named and class-scoped [Log] instances.
/// - [LogLevel] — enumeration defining log severities and threshold comparisons.
///
/// ### 🖨️ Formatters & Printers
/// - [PrettyPrinter] — human-friendly multi-line console printer with color-coded borders and stack traces.
/// - [FlatStructuredPrinter] — compact single-line printer optimized for cloud log collectors (Datadog, CloudWatch).
/// - [FmtPrinter] — custom template-based formatter.
///
/// ---
///
/// ## 🎯 Usage Example: Class-Scoped Logging & Dynamic Log Levels
///
/// ```dart
/// import 'package:jetleaf/logging.dart';
///
/// class OrderProcessor {
///   static final Log _logger = LogFactory.getLog(OrderProcessor);
///
///   void processOrder(String orderId, double amount) {
///     _logger.info('Processing order: $orderId for \$$amount');
///
///     try {
///       if (amount <= 0) {
///         throw ArgumentError('Order amount must be positive');
///       }
///       _logger.debug('Order $orderId validated successfully.');
///     } catch (e, stackTrace) {
///       _logger.error('Failed to process order $orderId', e, stackTrace);
///     }
///   }
/// }
///
/// void main() {
///   final processor = OrderProcessor();
///   processor.processOrder('ORD-101', 49.99);
///   processor.processOrder('ORD-102', -10.0);
/// }
/// ```
///
/// {@category Jetleaf}
library;

export 'package:jetleaf_core/logging.dart';
