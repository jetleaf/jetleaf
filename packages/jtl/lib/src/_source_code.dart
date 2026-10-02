// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & Jetleaf Contributors. All rights reserved.
//
// This source file is part of the Jetleaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the Jetleaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'package:jetleaf_lang/lang.dart';

import 'source_code.dart';

/// {@template jetleaf_default_source_code}
/// Represents the **concrete implementation of [SourceCode]**, encapsulating
/// an asset, its code structure, raw content, and rendered content.
///
/// [DefaultSourceCode] provides access to both the **structured representation**
/// of the code via [CodeStructure] and the **string representations** of the code.
///
/// ### Responsibilities
/// - Store the associated [Asset].
/// - Store the hierarchical [CodeStructure] representing the parsed code elements.
/// - Store the original raw content of the source code.
/// - Store the rendered content, which may include dynamic substitutions or template evaluations.
///
/// ### Design Notes
/// - Immutable: all fields are `final` and provided via the constructor.
/// - Provides direct getters for all properties, ensuring thread-safety and consistency.
/// - Useful in template engines for separating source and rendered output.
///
/// ### Usage Example
/// ```dart
/// final codeStructure = DefaultCodeStructure(elements: []);
/// final sourceCode = DefaultSourceCode(
///   asset,
///   codeStructure,
///   '<div>Hello World</div>',
///   '{{content}}',
/// );
///
/// print(sourceCode.getAsset()); // asset reference
/// print(sourceCode.getCodeStructure()); // DefaultCodeStructure instance
/// print(sourceCode.getRenderedContent()); // '<div>Hello World</div>'
/// print(sourceCode.getRawContent()); // '{{content}}'
/// ```
/// {@endtemplate}
final class DefaultSourceCode implements SourceCode {
  /// The associated asset for this source code.
  final Asset _asset;

  /// The hierarchical code structure of this source code.
  final CodeStructure _codeStructure;

  /// The rendered content after template evaluation.
  final String _renderedContent;

  /// The raw content of the source code (before rendering).
  final String _rawContent;

  /// Creates a new [DefaultSourceCode] instance with the given [_asset],
  /// [_codeStructure], [_renderedContent], and [_rawContent].
  /// 
  /// {@macro jetleaf_default_source_code}
  const DefaultSourceCode(this._asset, this._codeStructure, this._renderedContent, this._rawContent);

  @override
  Asset getAsset() => _asset;

  @override
  CodeStructure getCodeStructure() => _codeStructure;

  @override
  String getRawContent() => _rawContent;

  @override
  String getRenderedContent() => _renderedContent;

  @override
  List<Object?> equalizedProperties() => [_asset, _codeStructure, _renderedContent, _rawContent];
}

/// {@template jetleaf_default_code_structure}
/// Default implementation of [CodeStructure], representing a hierarchical
/// structure of code elements within a template or source file.
///
/// [DefaultCodeStructure] encapsulates a list of [CodeElement] instances and
/// identifies the type of code (e.g., HTML, JS, CSS, etc.).
///
/// ### Responsibilities
/// - Maintain an ordered, immutable list of [CodeElement] objects.
/// - Provide the type of the code structure via [getType].
/// - Support equality and comparison through [equalizedProperties].
///
/// ### Design Notes
/// - The elements list is immutable when accessed via [getElements].
/// - Type is a string identifying the language or format (e.g., `'HTML'`, `'JS'`).
/// - Useful for templating engines or code analysis tools to represent parsed structures.
///
/// ### Usage Example
/// ```dart
/// final elements = [
///   TextCodeElement(line: 'Hello', content: 'Hello'),
///   HtmlTagElement(
///     tagName: 'div',
///     line: '<div>',
///     content: 'Content',
///   ),
/// ];
///
/// final codeStructure = DefaultCodeStructure(elements, 'HTML');
///
/// print(codeStructure.getType()); // 'HTML'
/// print(codeStructure.getElements().length); // 2
/// ```
/// {@endtemplate}
final class DefaultCodeStructure implements CodeStructure {
  /// List of code elements in this structure.
  final List<CodeElement> _elements;

  /// The type of code represented (e.g., HTML, JS, CSS).
  final String _type;

  /// Creates a new [DefaultCodeStructure] with the given [elements] and [type].
  /// 
  /// {@macro jetleaf_default_code_structure}
  DefaultCodeStructure(List<CodeElement> elements, String type) : _elements = elements, _type = type;

  @override
  List<CodeElement> getElements() => List.unmodifiable(_elements);

  @override
  String getType() => _type;

  @override
  List<Object?> equalizedProperties() => [_elements, _type];
}

/// {@template jetleaf_code_structure_builder}
/// Builder for constructing a [CodeStructure] using a **fluent API**.
///
/// [CodeStructureBuilder] allows incremental creation of a code structure by
/// adding individual or multiple [CodeElement] instances and specifying the
/// type of code (e.g., HTML, JS, CSS).
///
/// ### Responsibilities
/// - Maintain a list of code elements to be included in the structure.
/// - Allow configuration of the code type via [withType].
/// - Provide fluent methods for adding elements individually or in bulk.
/// - Construct a [DefaultCodeStructure] instance via [build].
///
/// ### Design Notes
/// - Supports method chaining for concise and readable code.
/// - The resulting [CodeStructure] is immutable; the builder can continue
///   being reused or discarded after building.
/// - Useful in template engines or code generation pipelines.
///
/// ### Usage Example
/// ```dart
/// final builder = CodeStructureBuilder()
///   .withType('HTML')
///   .addElement(TextCodeElement(line: 'Hello', content: 'Hello'))
///   .addElement(HtmlTagElement(tagName: 'div', line: '<div>', content: 'Content'));
///
/// final codeStructure = builder.build();
///
/// print(codeStructure.getType()); // 'HTML'
/// print(codeStructure.getElements().length); // 2
/// ```
/// {@endtemplate}
final class CodeStructureBuilder {
  /// Internal list of code elements to be included in the structure.
  final List<CodeElement> _elements = [];

  /// The type of the code (default is `'HTML'`).
  String _type = 'HTML';

  /// Creates a new [CodeStructureBuilder] instance.
  /// 
  /// {@macro jetleaf_code_structure_builder}
  CodeStructureBuilder();

  /// Sets the code type (e.g., `'HTML'`, `'JS'`, `'CSS'`) for the structure.
  ///
  /// Returns `this` for fluent chaining.
  CodeStructureBuilder withType(String type) {
    _type = type;
    return this;
  }

  /// Adds a single [element] to the code structure.
  ///
  /// Returns `this` for fluent chaining.
  CodeStructureBuilder addElement(CodeElement element) {
    _elements.add(element);
    return this;
  }

  /// Adds multiple [elements] to the code structure.
  ///
  /// Returns `this` for fluent chaining.
  CodeStructureBuilder addElements(List<CodeElement> elements) {
    _elements.addAll(elements);
    return this;
  }

  /// Builds the [CodeStructure] using the accumulated elements and type.
  ///
  /// Returns a [DefaultCodeStructure] instance.
  CodeStructure build() => DefaultCodeStructure(_elements, _type);
}

/// {@template jetleaf_source_code_builder}
/// Builder for constructing a [SourceCode] instance using a **fluent API**.
///
/// [SourceCodeBuilder] allows incremental configuration of all required
/// properties for a [DefaultSourceCode] object, including asset, code structure,
/// rendered content, and raw template content.
///
/// ### Responsibilities
/// - Set the associated [Asset] for the source code.
/// - Set the hierarchical [CodeStructure] representing parsed elements.
/// - Set the rendered content after template evaluation.
/// - Set the raw content of the template before rendering.
/// - Build an immutable [DefaultSourceCode] instance.
///
/// ### Design Notes
/// - Supports fluent method chaining for concise code.
/// - Ensures all required fields are set before calling [build].
/// - Useful in templating engines, code generation, and testing pipelines.
///
/// ### Usage Example
/// ```dart
/// final codeStructure = CodeStructureBuilder()
///   .addElement(TextCodeElement(line: '1', content: 'Hello'))
///   .build();
///
/// final sourceCode = SourceCodeBuilder()
///   .withAsset(myAsset)
///   .withCodeStructure(codeStructure)
///   .withRawContent('{{content}}')
///   .withRenderedContent('<div>Hello</div>')
///   .build();
///
/// print(sourceCode.getRenderedContent()); // '<div>Hello</div>'
/// print(sourceCode.getRawContent()); // '{{content}}'
/// ```
/// {@endtemplate}
final class SourceCodeBuilder {
  /// The associated asset for this source code.
  late Asset _asset;

  /// The hierarchical code structure of the source code.
  late CodeStructure _codeStructure;

  /// The rendered content after template evaluation.
  late String _renderedContent;

  /// The raw template content before rendering.
  late String _rawContent;

  /// {@macro jetleaf_source_code_builder}
  SourceCodeBuilder();

  /// Sets the asset for this source code.
  ///
  /// Returns `this` for fluent chaining.
  SourceCodeBuilder withAsset(Asset asset) {
    _asset = asset;
    return this;
  }

  /// Sets the code structure.
  ///
  /// Returns `this` for fluent chaining.
  SourceCodeBuilder withCodeStructure(CodeStructure codeStructure) {
    _codeStructure = codeStructure;
    return this;
  }

  /// Sets the rendered content after template evaluation.
  ///
  /// Returns `this` for fluent chaining.
  SourceCodeBuilder withRenderedContent(String content) {
    _renderedContent = content;
    return this;
  }

  /// Sets the raw template content before rendering.
  ///
  /// Returns `this` for fluent chaining.
  SourceCodeBuilder withRawContent(String content) {
    _rawContent = content;
    return this;
  }

  /// Builds the [SourceCode] instance.
  ///
  /// Returns a [DefaultSourceCode] with all previously configured properties.
  SourceCode build() => DefaultSourceCode(_asset, _codeStructure, _renderedContent, _rawContent);
}