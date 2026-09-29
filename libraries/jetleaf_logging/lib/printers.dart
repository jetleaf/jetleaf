/// 🖨️ **Jetleaf Logging Printers**
///
/// This library exposes all built-in printer implementations used by the
/// Jetleaf logging system to format and render log output.
///
/// Printers control **how logs are displayed**, whether in human-readable,
/// compact, or structured formats. They can be combined, customized, or
/// replaced with custom implementations.
///
///
/// ## 🎨 Available Printers
///
/// ### 📌 Flat Output
/// - `FlatPrinter` — minimal single-line output
/// - `FlatStructuredPrinter` — flat formatting with structured fields
///
/// Ideal for CLI tools and compact logs.
///
///
/// ### 🧾 Formatted Output
/// - `FmtPrinter` — template-driven formatting (printf-style)
///
/// Useful when enforcing consistent patterns.
///
///
/// ### 🔀 Hybrid Output
/// - `HybridPrinter` — mixes pretty and structured formatting based on context
///
/// Great when balancing human readability and machine parsing.
///
///
/// ### 🏷 Prefixing Support
/// - `PrefixPrinter` — adds prefixes (categories, timestamps, thread IDs, etc.)
///
/// Can wrap other printers to extend behavior.
///
///
/// ### 🌈 Pretty Output
/// - `PrettyPrinter` — colorized, multi-line, developer-friendly formatting
/// - `PrettyStructuredPrinter` — pretty formatting with structured metadata
///
/// Ideal for debugging and local development.
///
///
/// ### ✅ Simple Output
/// - `SimplePrinter` — lightweight text output without styling
///
/// Good for environments with limited terminal capabilities.
///
///
/// ## 🎯 Intended Usage
///
/// Import to configure logging behavior:
/// ```dart
/// import 'package:jetleaf_logging/printers.dart';
///
/// final printer = PrettyPrinter();
/// ```
///
/// Printers are typically assigned through `LogConfig` or `LogFactory`.
///
///
/// © 2025 Hapnium & Jetleaf Contributors
library;

export 'src/printers/flat_printer.dart';
export 'src/printers/flat_structured_printer.dart';
export 'src/printers/fmt_printer.dart';
export 'src/printers/hybrid_printer.dart';
export 'src/printers/prefix_printer.dart';
export 'src/printers/pretty_printer.dart';
export 'src/printers/pretty_structured_printer.dart';
export 'src/printers/simple_printer.dart';