/// 🧩 **Jetleaf Utilities Subsystem**
///
/// This library provides general-purpose helper utilities, text processors,
/// configuration format parsers, and diagnostic decoding tools for the Jetleaf framework.
///
/// Key capabilities:
/// - **Recursive Placeholder Resolution:** Dynamic resolution of `${key:default}` patterns.
/// - **Multi-Format Parsers:** Unified AST and object parsing for YAML, JSON, XML, Properties, and ENV.
/// - **Stack Trace Sanitization:** Demangling and filtering internal VM frames for clear diagnostics.
/// - **Assertion & String Helpers:** Defensive programming guards and casing utilities.
///
/// ---
///
/// ## 🔄 Placeholder Resolution Flow
///
/// ```text
/// ┌─────────────────────────────────────────────────────────────┐
/// │                     Input Template String                   │
/// │              "https://${server.host:localhost}:${port}"     │
/// ├─────────────────────────────────────────────────────────────┤
/// │ 1. Parse Token         Find prefix "${" and suffix "}"      │
/// │                               │                             │
/// │ 2. Extract Key/Default  key: "server.host", fallback: "..." │
/// │                               │                             │
/// │ 3. Query Resolver      Look up key in PropertyPlaceholder   │
/// │                               │                             │
/// │ 4. Recursive Replace   Substitute nested expressions        │
/// └─────────────────────────────────────────────────────────────┘
/// ```
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### 🏷️ Placeholder Resolution
/// - [PropertyPlaceholderHelper] — utility for replacing `${...}` placeholders with property values.
/// - [PlaceholderResolver] — functional contract mapping placeholder keys to replacement values.
/// - [PlaceholderParser] — low-level parser extracting placeholder keys, prefixes, and suffixes.
///
/// ### 📄 Configuration Parsers
/// - [YamlParser] — parses structured YAML documents into Dart Maps and Lists.
/// - [JsonParser] — parses JSON streams and strings with strict type safety.
/// - [PropertiesParser] — parses Java-style `.properties` key-value pairs.
/// - [EnvParser] — parses `.env` files with quoted strings and variable expansion.
///
/// ### 🩺 Stack Trace Utilities
/// - [StackTraceParser] — parses raw Dart stack traces into structured [TraceFrame] instances.
/// - [TraceFrame] — encapsulates file, line number, column, member, and package metadata.
///
/// ### 🛡️ Guards & Defensiveness
/// - [Assert] — defensive programming validation helpers (e.g. `notNull`, `hasText`, `state`).
/// - [StringUtils] — high-performance string manipulation, casing, and collection joining.
///
/// ---
///
/// ## 🎯 Usage Example: Placeholders & Defensive Assertions
///
/// ```dart
/// import 'package:jetleaf_core/utils.dart';
///
/// void main() {
///   // 1. Validate preconditions with Assert
///   final username = 'alice';
///   Assert.hasText(username, 'Username must not be empty');
///
///   // 2. Resolve placeholders dynamically
///   final helper = PropertyPlaceholderHelper('\${', '}');
///   final properties = {
///     'api.host': 'api.jetleaf.dev',
///     'api.version': 'v2',
///   };
///
///   final endpoint = helper.replacePlaceholders(
///     'https://\${api.host}/\${api.version}/users/\${api.missing:current}',
///     (key) => properties[key],
///   );
///
///   print('Resolved Endpoint: $endpoint');
///   // Output: https://api.jetleaf.dev/v2/users/current
/// }
/// ```
library;

export 'src/utils/placeholder/placeholder_parser.dart';
export 'src/utils/placeholder/placeholder_resolver.dart';
export 'src/utils/placeholder/property_placeholder_helper.dart';

export 'src/utils/parsers/json_parser.dart';
export 'src/utils/parsers/xml_parser.dart';
export 'src/utils/parsers/properties_parser.dart';
export 'src/utils/parsers/yaml_parser.dart';
export 'src/utils/parsers/dart_parser.dart';
export 'src/utils/parsers/env_parser.dart';
export 'src/utils/parsers/parser.dart';

export 'src/utils/stack_trace/stack_trace_parser.dart';
export 'src/utils/stack_trace/trace_frame.dart';
export 'src/utils/stack_trace/trace_mapping.dart';

export 'src/utils/exceptions.dart';
export 'src/utils/assert.dart';
export 'src/utils/package_utils.dart';
export 'src/utils/string_utils.dart';
export 'src/utils/system_property_utils.dart';