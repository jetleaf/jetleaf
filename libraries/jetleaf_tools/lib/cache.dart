/// ⚡ **Jetleaf Cache & Binary Indexing Subsystem**
///
/// This library provides binary caching, incremental indexing, and startup acceleration
/// infrastructure for Jetleaf. By caching scanned AST declarations into compact binary
/// artifacts (`.jetleaf/cache/`), subsequent application boots bypass full source scanning.
///
/// ---
///
/// ## ⚡ Cache Acceleration Pipeline
///
/// ```text
/// ┌─────────────────────────────────────────────────────────────┐
/// │                     Jetleaf Startup Flow                    │
/// ├─────────────────────────────────────────────────────────────┤
/// │ 1. Compute Hash        File timestamps & content fingerprint│
/// │                               │                             │
/// │ 2. Check Binary Cache  .jetleaf/cache/cache_<hash>.bin       │
/// │                               │                             │
/// │    ┌───────────── Hit ────────┴──────── Miss ───────────┐   │
/// │    ▼                                                    ▼   │
/// │ Deserializer [BinaryReader]                     Full AST Scan│
/// │ Instant Startup (~10ms)                         Write Cache │
/// └─────────────────────────────────────────────────────────────┘
/// ```
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### 💾 Serialization & Binary I/O
/// - [CacheableSerializer] — contract for serializing and deserializing cached objects.
/// - [BinaryBuilder] — low-allocation binary byte packer supporting string deduplication.
/// - [BinaryReader] — zero-copy binary parser unpacking serialized AST declarations.
///
/// ### 🗂️ Cache Management & Scanners
/// - [CacheableManager] — orchestrates cache invalidation, pruning, and persistence.
/// - [CacheScanner] — reads and writes cached metadata during build phases.
/// - [SubClassEntry] — indexed hierarchy entry mapping parents to subclasses.
///
/// ### 📁 Paths & Locations
/// - [JetleafPaths] — centralized path resolution for `.jetleaf/cache/` directories.
///
/// ---
///
/// ## 🎯 Usage Example: Binary Serialization
///
/// ```dart
/// import 'package:jetleaf_tools/cache.dart';
///
/// void main() {
///   final builder = BinaryBuilder();
///
///   // Pack structured data into binary format
///   builder.writeString('package:my_app/user.dart');
///   builder.writeBool(true);
///   builder.writeInt(42);
///
///   final bytes = builder.takeBytes();
///   print('Packed ${bytes.length} binary bytes.');
///
///   // Read back through BinaryReader
///   final reader = BinaryReader(bytes);
///   final uri = reader.readString();
///   final active = reader.readBool();
///   final count = reader.readInt();
///
///   print('Read back: $uri, active: $active, count: $count');
/// }
/// ```
library;

// Serializer (public API + helpers)
export 'src/cache/serializer/cacheable_serializer.dart';
export 'src/cache/serializer/helpers.dart';

// Manager (public API + diff)
export 'src/cache/manager/cacheable_manager.dart';

// Scanner hierarchy (cache read/write)
export 'src/cache/scanner/cache_scanners.dart';
export 'src/cache/scanner/cache_models.dart';

// Utilities
export 'src/cache/jetleaf_paths.dart';
export 'src/cache/models.dart';
