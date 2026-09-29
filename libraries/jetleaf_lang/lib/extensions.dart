/// # Architecture Ecosystem: Fluent Primitives & Object Lifecycle Extensions
///
/// A comprehensive suite of type-safe API extensions designed to enhance developer velocity, 
/// eliminate defensive boilerplate, and inject functional programming idioms directly into standard types.
///
/// Rather than utilizing classic procedural utility patterns (e.g., `StringUtils.hasText(str)`), this 
/// ecosystem maps expressive, declarative operations directly onto object targets via static extension routing.
///
/// ---
///
/// ## 1. Design Philosophy: Expressive Chaining & Safety
///
/// The extensions library focuses on three core software engineering patterns:
/// * **Defensive Null/Empty Validation:** Direct, expressive checks like `string.hasText()` or `iterable.isNotNullOrEmpty()` 
///   replace verbose structural logical checks.
/// * **Fluent Scope Blocks:** Global generic anchors (via `t.dart`) provide scope binding pipelines like `.let()` and `.also()`, 
///   bringing structural runtime initialization syntax mirroring Kotlin or advanced functional languages.
/// * **Primitive Arithmetic Precision:** Mathematical and chronological expansions allow readable units syntax 
///   (e.g., `5.minutes` or `10.divideBy(2).ceil()`) directly on primitive numeric instances.
///
/// ---
///
/// ## 2. Core Architectural Breakdown
///
/// ### Primitive Type Augmentations
/// Structural helpers targeting everyday data primitives:
/// * **[StringExtensions]:** Character sequence parsing, sanitization, pattern matching, and blank/empty state handling.
/// * **[IntExtensions] / [DoubleExtensions] / [NumExtensions]:** Localized numeric divisions, mathematical padding, and float manipulations.
/// * **[BoolExtensions]:** Pure bit conversions, inversion helpers, and conditional pipeline forks.
///
/// ### Structural Collection Modifiers
/// * **[IterableExtensions] / [ListExtensions] / [SetExtensions] / [MapExtensions]:** Native streaming hooks, 
///   safe index boundaries filtering, predictive slicing transformations, and structural group-by routines.
///
/// ### System Lifecycle Contexts
/// * **[TExtensions]:** The universal utility toolkit providing generic pipeline tapping hooks (`let`, `also`, `takeIf`) for all objects.
/// * **[DateTimeExtensions] / [DurationExtensions]:** Precise epoch calculation mappings, business calendar intervals, and time conversions.
/// * **[DynamicExtensions] / [TypeExtensions]:** Safe reflection runtime evaluation hooks, type checking assertions, and fallback casting handlers.
///
/// ### Pipeline Architecture Example
/// ```dart
/// // Standard continuous functional pipeline enabled by structural extensions
/// final processedConfig = configurationMap
///     .getOptional('timeout_duration')        // Safe Map retrieval
///     .takeIf((val) => val.hasText())        // Conditional filter validation
///     ?.let((str) => int.tryParse(str))       // Context transformation block
///     ?.also((num) => logger.info('Parsed: $num')); // Side-effect tracking execution
/// ```
library;

// ============================================================================
// SYSTEM LIFECYCLE, REFLECTION, & OBJECT CONTEXTS
// ============================================================================

export 'src/extensions/others/date_time.dart';
export 'src/extensions/others/duration.dart';
export 'src/extensions/others/dynamic.dart';
export 'src/extensions/others/t.dart';
export 'src/extensions/others/type.dart';

// ============================================================================
// PRIMITIVE TYPE DATA EXTENSIONS
// ============================================================================

export 'src/extensions/primitives/bool.dart';
export 'src/extensions/primitives/double.dart';
export 'src/extensions/primitives/int.dart';
export 'src/extensions/primitives/num.dart';
export 'src/extensions/primitives/string.dart';

// ============================================================================
// DATA STRUCTURES & COLLECTION PIPELINES
// ============================================================================

export 'src/extensions/primitives/iterable.dart';
export 'src/extensions/primitives/list.dart';
export 'src/extensions/primitives/map.dart';
export 'src/extensions/primitives/set.dart';