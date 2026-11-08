/// 📚 **Jetleaf Collections, Linear Topologies & Accumulators Subsystem**
///
/// This library provides high-performance data structures, specialized collection implementations,
/// and streaming collectors optimized for enterprise backend workloads in Dart.
///
/// Key capabilities:
/// - **Resizing Linear Buffers:** Low-allocation [ArrayList] with capacity pre-allocation.
/// - **Doubly-Linked Nodes:** Deterministic $O(1)$ insertion and removal with [LinkedList].
/// - **LIFO/FIFO Topologies:** Strict FIFO [Queue] / [LinkedQueue] and LIFO [Stack] / [LinkedStack].
/// - **Case-Insensitive Indexing:** [CaseInsensitiveMap] for headers, query params, and environment keys.
/// - **Functional Collectors:** Java/Stream-style stream reductions and grouping operations.
///
/// ---
///
/// ## 📊 Collection Topology Matrix
///
/// ```text
/// ┌─────────────────────────────────────────────────────────────┐
/// │                     Specialized Collections                 │
/// ├───────────────────┬───────────────────┬─────────────────────┤
/// │ Linear Arrays     │ Node-Linked Lists │ Specialized Maps    │
/// ├───────────────────┼───────────────────┼─────────────────────┤
/// │ • ArrayList<E>    │ • LinkedList<E>   │ • HashMap<K, V>     │
/// │ • Stack<E>        │ • LinkedQueue<E>  │ • CaseInsensitiveMap│
/// │ • Queue<E>        │ • LinkedStack<E>  │ • HashSet<E>        │
/// └───────────────────┴───────────────────┴─────────────────────┘
/// ```
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### 📋 Lists & Buffers
/// - [ArrayList] — indexable array with dynamic capacity expansion and minimal memory churn.
/// - [LinkedList] — doubly-linked list supporting fast constant-time head and tail operations.
///
/// ### 📥 Queues & Stacks
/// - [Queue], [LinkedQueue] — First-In-First-Out (FIFO) queue implementations.
/// - [Stack], [LinkedStack] — Last-In-First-Out (LIFO) stack implementations.
///
/// ### 🗃️ Maps & Sets
/// - [CaseInsensitiveMap] — map whose string keys are matched case-insensitively while preserving original case.
/// - [HashMap], [HashSet] — high-performance hashing structures.
///
/// ### 🧪 Collectors & Reductions
/// - [Collector] — functional reduction contract transforming elements into aggregated results.
/// - [Collectors] — standard factory creating common collectors (`toList`, `toSet`, `joining`, `groupingBy`).
///
/// ---
///
/// ## 🎯 Usage Example: Case-Insensitive Headers & Collectors
///
/// ```dart
/// import 'package:jetleaf_core/collections.dart';
///
/// void main() {
///   // 1. Case-insensitive HTTP header map
///   final headers = CaseInsensitiveMap<String>();
///   headers['Content-Type'] = 'application/json';
///   headers['Authorization'] = 'Bearer token_abc123';
///
///   // Lookups succeed regardless of case
///   print(headers['content-type']); // 'application/json'
///   print(headers['AUTHORIZATION']); // 'Bearer token_abc123'
///
///   // 2. Linear ArrayList with collectors
///   final list = ArrayList<int>.of([10, 20, 30, 40]);
///   final sum = list.fold<int>(0, (prev, curr) => prev + curr);
///   print('Total sum: $sum');
/// }
/// ```
library;

export 'src/lang/collections/array_list.dart';
export 'src/lang/collections/linked_list.dart';

export 'src/lang/collections/stack.dart';
export 'src/lang/collections/queue.dart';
export 'src/lang/collections/linked_queue.dart';
export 'src/lang/collections/linked_stack.dart';

export 'src/lang/collections/hash_map.dart';
export 'src/lang/collections/hash_set.dart';
export 'src/lang/collections/case_insensitive_map.dart';

export 'src/lang/collections/adaptable.dart';

export 'src/lang/collectors/collector.dart';
export 'src/lang/collectors/collectors.dart';
