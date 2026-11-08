/// 📚 **Jetleaf Language Primitives, Collections & Reflective Metadata**
///
/// This library provides the core language-level foundation and metadata abstractions
/// powering the Jetleaf framework:
/// - **Reflective Type Tokens:** [Class], [ClassType], [Method], [Field], [Parameter], [Constructor].
/// - **Language Metadata:** [ReflectableAnnotation], [Reflectable], declaration abstractions.
/// - **Functional Streams & Collections:** [GenericStream], [IntStream], [DoubleStream], [Collector], [ArrayList], [LinkedList], [CaseInsensitiveMap].
/// - **Runtime Scanning & AST Discovery:** [RuntimeScannerConfiguration], `runScan`, [RuntimeProvider].
/// - **Core Exceptions:** [RuntimeException], [ClassNotFoundException], assertion contracts.
///
/// ---
///
/// ## 🏛️ Type & Metadata Hierarchy
///
/// ```text
/// ┌────────────────────────────────────────────────────────────────────────┐
/// │                     Jetleaf Language Metadata Hierarchy                │
/// ├────────────────────────────────────────────────────────────────────────┤
/// │                             Declaration                                │
/// │                                  ▲                                     │
/// │         ┌────────────────────────┼────────────────────────┐            │
/// │         │                        │                        │            │
/// │  ClassDeclaration        MethodDeclaration        FieldDeclaration     │
/// │         │                        │                        │            │
/// │      [Class]                  [Method]                 [Field]         │
/// ├──────────────────────────────────┴─────────────────────────────────────┤
/// │ • Pure AOT Tokenization: Maps static class types without dart:mirrors  │
/// │ • Zero-Overhead Reflection: Fast field access & method invocation      │
/// └────────────────────────────────────────────────────────────────────────┘
/// ```
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### 🏷️ Reflective Type Modeling
/// - [Class] — type token representing a Dart class with full reflective introspection.
/// - [ClassType] — compile-time reified type reference token.
/// - [Method] — reflective model for class methods, return types, and annotations.
/// - [Field] — reflective model for class fields, getters, setters, and attributes.
/// - [Parameter] — reflective model for constructor and method parameters.
/// - [ReflectableAnnotation] — base class for all reflectively inspectable annotations.
///
/// ### 🌊 Functional Streams & Sequences
/// - [GenericStream] — lazy, high-performance functional pipeline with `map`, `filter`, `flatMap`, and `reduce`.
/// - [IntStream], [DoubleStream] — primitive-specialized high-performance numerical streams.
/// - [Collector] — terminal reduction accumulator into lists, sets, maps, or joined strings.
///
/// ### 📦 High-Performance Collections
/// - [ArrayList] — indexable contiguous list with amortized O(1) growth.
/// - [LinkedList] — doubly-linked sequential node container.
/// - [CaseInsensitiveMap] — map maintaining ASCII case-insensitive string keys.
///
/// ---
///
/// ## 🎯 Usage Example: Functional Stream Processing & Type Tokens
///
/// ```dart
/// import 'package:jetleaf/lang.dart';
///
/// class Product {
///   final String name;
///   final double price;
///   Product(this.name, this.price);
/// }
///
/// void main() {
///   // 1. Working with Class Type Tokens
///   final productClass = Class<Product>();
///   print('Simple Name: ${productClass.getSimpleName()}');
///
///   // 2. Functional Stream Pipeline
///   final products = [
///     Product('Laptop', 1200.0),
///     Product('Mouse', 25.0),
///     Product('Keyboard', 75.0),
///     Product('Monitor', 350.0),
///   ];
///
///   final affordableNames = GenericStream.from(products)
///       .filter((p) => p.price < 100.0)
///       .map((p) => '${p.name} (\$${p.price})')
///       .toList();
///
///   print('Affordable items: $affordableNames');
/// }
/// ```
///
/// {@category Jetleaf}
library;

export 'package:jetleaf_core/lang.dart';
