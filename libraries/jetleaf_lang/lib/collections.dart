/// # Architecture Ecosystem: Collections, Linear Topologies, and Accumulators
///
/// This library provides a performance-optimized, memory-isolated alternative to the default platform collections framework.
/// It introduces deterministic computational complexities, type-safe data structures, and standard functional stream 
/// accumulation layers.
///
/// Unlike standard platform collections which often hide their structural foundations under generic interfaces, this ecosystem 
/// provides predictable memory layouts and concrete execution behaviors. These structures are designed for low-overhead loops, 
/// specialized cache-locality mapping, and strict state constraints across mission-critical codebeds.
///
/// ---
///
/// ## 1. Structural Performance Specifications
///
/// The following complexity matrix profiles the concrete implementations exported by this library:
///
/// | Structural Component | Index Read / Peek | Sequential Mutation | Dynamic Resizing Overhead | Underpinning Layout |
/// | :--- | :--- | :--- | :--- | :--- |
/// | [ArrayList] | $\mathcal{O}(1)$ | $\mathcal{O}(n)$ | Amortized $\mathcal{O}(1)$ | Contiguous Array Block |
/// | [LinkedList] | $\mathcal{O}(n)$ | $\mathcal{O}(1)$ | $\mathcal{O}(1)$ (No Resizing) | Doubly Linked Pointer Tree |
/// | [Stack] / [LinkedStack] | $\mathcal{O}(1)$ | $\mathcal{O}(1)$ | $\mathcal{O}(1)$ | Last-In, First-Out Ring |
/// | [Queue] / [LinkedQueue] | $\mathcal{O}(1)$ | $\mathcal{O}(1)$ | $\mathcal{O}(1)$ | First-In, First-Out Loop |
/// | [HashMap] / [HashSet] | $\mathcal{O}(1)$ avg | $\mathcal{O}(1)$ avg | $\mathcal{O}(n)$ during rehash | Open-address / Chained Buckets |
///
/// ---
///
/// ## 2. Functional Accumulation Pipelines (Collectors)
///
/// Beyond structural storage, this library provides an entry framework for terminal map-reduce streaming pipelines 
/// via [Collector] and [Collectors]. These abstractions enable thread-safe data reduction, grouping, and transformations 
/// on continuous streams of objects without allocating transient intermediate arrays.
///
/// ### Architecture Pipeline Example
/// ```dart
/// // Grouping domain data entries into a case-insensitive map structure using stream adapters
/// final CaseInsensitiveMap<UserGroup> aggregate = userStream
///     .collect(Collectors.toGroupedMap(
///         keyMapper: (user) => user.departmentName,
///         valueMapper: (user) => user.computeAccessGroup(),
///         mapFactory: () => CaseInsensitiveMap(),
///     ));
/// ```
library;

// ============================================================================
// LINEAR STORAGE INFRASTRUCTURE
// ============================================================================

export 'src/collections/array_list.dart';
export 'src/collections/linked_list.dart';

// ============================================================================
// CONSTRAINED ACCESS TOPOLOGIES (LIFO / FIFO)
// ============================================================================

export 'src/collections/stack.dart';
export 'src/collections/queue.dart';
export 'src/collections/linked_queue.dart';
export 'src/collections/linked_stack.dart';

// ============================================================================
// ASSOCIATIVE REPOSITORIES & HASH SPACES
// ============================================================================

export 'src/collections/hash_map.dart';
export 'src/collections/hash_set.dart';
export 'src/collections/case_insensitive_map.dart';

// ============================================================================
// POLYMORPHIC ADAPTER ENGINES
// ============================================================================

export 'src/collections/adaptable.dart';

// ============================================================================
// TERMINAL STREAM REDUCTION UTILITIES
// ============================================================================

export 'src/collectors/collector.dart';
export 'src/collectors/collectors.dart';