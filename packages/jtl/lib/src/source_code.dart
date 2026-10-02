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

/// {@template jetleaf_source_code}
/// Represents the output of a template rendering or code generation process.
///
/// A [SourceCode] object encapsulates both the **structured representation**
/// of code and its **string content**, allowing consumers to work with either
/// the rendered content or its underlying components.
///
/// ### Responsibilities
/// - Provide access to the associated [Asset] (e.g., file or resource information).
/// - Provide the structured representation of code via [CodeStructure].
/// - Expose the fully rendered string content ready for output.
/// - Optionally expose the raw/unprocessed template content.
///
/// ### Usage Example
/// ```dart
/// final source = renderer.render(template);
/// final html = source.getRenderedContent(); // Fully rendered HTML
/// final rawTemplate = source.getRawContent(); // Original template string
/// final elements = source.getCodeStructure().getElements();
/// ```
/// {@endtemplate}
abstract interface class SourceCode with EqualsAndHashCode {
  /// Returns the [Asset] associated with this source code.
  ///
  /// The asset can represent a file, resource, or virtual location where
  /// the generated code should be saved or further processed.
  ///
  /// ### Design Notes
  /// - Useful for code generation pipelines or template engines.
  /// - Can be used to determine output paths or metadata for deployment.
  Asset getAsset();

  /// Returns the structured representation of the code.
  ///
  /// The [CodeStructure] captures the hierarchical elements of the code
  /// (e.g., HTML tags, JavaScript functions, etc.), enabling introspection,
  /// transformations, or analysis before rendering.
  ///
  /// ### Example
  /// ```dart
  /// final structure = source.getCodeStructure();
  /// for (final element in structure.getElements()) {
  ///   print(element.name);
  /// }
  /// ```
  CodeStructure getCodeStructure();

  /// Returns the fully rendered content as a string.
  ///
  /// This includes all dynamic values injected from the template context
  /// and any transformations performed during rendering.
  ///
  /// ### Design Notes
  /// - Typically used when writing content to files or sending over the network.
  String getRenderedContent();

  /// Returns the raw/unprocessed template content.
  ///
  /// This is the original template string before any variable resolution
  /// or rendering transformations. Useful for debugging or analysis.
  String getRawContent();
}

/// {@template jetleaf_code_structure}
/// Represents the **hierarchical structure** of a source code file.
///
/// A [CodeStructure] provides a structured representation of the code,
/// capturing its elements and type (HTML, JS, CSS, etc.). This enables
/// programmatic inspection, analysis, or modification of code before rendering.
///
/// ### Responsibilities
/// - Maintain an ordered list of [CodeElement] objects representing code fragments.
/// - Identify the type of code (e.g., HTML, JavaScript, CSS).
///
/// ### Usage Example
/// ```dart
/// final structure = source.getCodeStructure();
/// print(structure.getType()); // 'HTML'
/// for (final element in structure.getElements()) {
///   print(element.name);
/// }
/// ```
/// {@endtemplate}
abstract interface class CodeStructure with EqualsAndHashCode {
  /// Returns the list of [CodeElement] objects representing the code hierarchy.
  ///
  /// Each element can represent a tag, statement, function, or other code fragment,
  /// depending on the code type.
  ///
  /// ### Design Notes
  /// - Maintains the original order of elements as in the template or source.
  /// - Supports analysis, transformation, or code generation pipelines.
  List<CodeElement> getElements();

  /// Returns the type of the code (e.g., 'HTML', 'JS', 'CSS').
  ///
  /// This is used to determine how to process, render, or output the code.
  ///
  /// ### Design Notes
  /// - Type information can drive syntax highlighting, minification,
  ///   or other type-specific processing.
  String getType();
}

/// {@template jetleaf_code_element}
/// Represents a **single element or fragment of code** within a [CodeStructure].
///
/// A [CodeElement] can be a structural component of code, such as an HTML tag,
/// JavaScript function, CSS rule, or any hierarchical code unit. It allows
/// introspection and manipulation of code in a structured way.
///
/// ### Responsibilities
/// - Capture opening and closing tags (for languages with tag-like structures).
/// - Store tag or element names for identification.
/// - Provide the raw line or content associated with this element.
/// - Maintain child elements to represent hierarchical code structures.
///
/// ### Usage Example
/// ```dart
/// final element = HtmlElement(
///   openingTag: '<div>',
///   closingTag: '</div>',
///   tagName: 'div',
///   line: '<div>Hello</div>',
///   content: 'Hello',
///   children: [],
/// );
///
/// print(element.getTagName()); // 'div'
/// print(element.getContent()); // 'Hello'
/// ```
/// {@endtemplate}
abstract interface class CodeElement with EqualsAndHashCode {
  /// Returns the **opening tag** of this element, if applicable.
  ///
  /// For languages like HTML or XML, this represents the starting tag
  /// (e.g., `<div>`). Returns `null` for languages without explicit tags.
  ///
  /// ### Design Notes
  /// - May be used for rendering or generating nested structures.
  String? getOpeningTag();

  /// Returns the **closing tag** of this element, if applicable.
  ///
  /// For languages like HTML or XML, this represents the ending tag
  /// (e.g., `</div>`). Returns `null` for self-closing elements or
  /// languages without explicit closing tags.
  String? getClosingTag();

  /// Returns the **name of the tag or element**, if applicable.
  ///
  /// This is often the HTML tag name, CSS selector, or function name in JS.
  /// Can be `null` if the element does not have a specific identifier.
  ///
  /// ### Design Notes
  /// - Used to identify elements for traversal, styling, or manipulation.
  String? getTagName();

  /// Returns the raw **line of code** corresponding to this element.
  ///
  /// Typically used for debugging or rendering purposes.
  ///
  /// ### Example
  /// ```dart
  /// print(element.getLine()); // '<div>Hello</div>'
  /// ```
  String getLine();

  /// Returns the **content** of this element, excluding/including tags.
  ///
  /// For HTML, this would be the inner text. For other languages,
  /// it may represent the code contained within a block or statement.
  ///
  /// ### Design Notes
  /// - May include nested child content depending on implementation.
  String getContent();

  /// Returns the list of **child elements** contained within this element.
  ///
  /// Enables hierarchical representation of code (e.g., nested HTML tags,
  /// nested blocks in JavaScript, etc.).
  ///
  /// ### Design Notes
  /// - Can be empty for leaf elements.
  /// - Children maintain the original order from the source.
  List<CodeElement> getChildren();
}

/// {@template jetleaf_text_code_element}
/// Represents a **plain text element** within a [CodeStructure].
///
/// [TextCodeElement] is a concrete implementation of [CodeElement] for cases
/// where the code fragment has no opening or closing tags, and does not have
/// a specific tag name. It is typically used for inline text, code lines, or
/// fragments that are treated as leaf nodes in the code hierarchy.
///
/// ### Responsibilities
/// - Store a single line of code or text.
/// - Store the content of the element (usually the same as the line for text).
/// - Maintain optional child elements to represent nested structures.
/// - Provide equality comparison through `equalizedProperties`.
///
/// ### Design Notes
/// - Opening tag, closing tag, and tag name are always `null`.
/// - Children list is immutable when accessed via `getChildren`.
/// - Useful for representing statements, inline text, or non-tag code fragments.
///
/// ### Usage Example
/// ```dart
/// final element = TextCodeElement(
///   line: 'console.log("Hello");',
///   content: 'console.log("Hello");',
/// );
///
/// print(element.getLine()); // 'console.log("Hello");'
/// print(element.getChildren()); // []
/// print(element.getTagName()); // null
/// ```
/// {@endtemplate}
final class TextCodeElement implements CodeElement {
  /// The raw line of code or text.
  final String _line;

  /// The content of this code element.
  final String _content;

  /// The list of child elements contained within this element.
  final List<CodeElement> _children;

  /// Creates a new [TextCodeElement] with the given [line], [content], and
  /// optional [children].
  ///
  /// If [children] is not provided, it defaults to an empty list.
  /// 
  /// {@macro jetleaf_text_code_element}
  TextCodeElement({required String line, required String content, List<CodeElement>? children}) 
    : _line = line, _content = content, _children = children ?? [];

  @override
  String? getOpeningTag() => null;

  @override
  String? getClosingTag() => null;

  @override
  String? getTagName() => null;

  @override
  String getLine() => _line;

  @override
  String getContent() => _content;

  @override
  List<CodeElement> getChildren() => List.unmodifiable(_children);

  @override
  List<Object?> equalizedProperties() => [_line, _children, _content];
}

/// {@template jetleaf_html_tag_element}
/// Represents an **HTML tag element** within a [CodeStructure], including
/// optional opening and closing tags, content, and nested child elements.
///
/// [HtmlTagElement] is a concrete implementation of [CodeElement] used to
/// represent standard HTML tags (e.g., `<div>`, `<span>`, `<p>`) and their
/// hierarchical content structure.
///
/// ### Responsibilities
/// - Store opening and closing tags (optional).
/// - Store the tag name.
/// - Store the raw line of code where the element appears.
/// - Store the inner content of the element.
/// - Maintain a list of child [CodeElement]s representing nested HTML elements.
///
/// ### Design Notes
/// - If [_openingTag] or [_closingTag] is `null`, it indicates the tag is
///   self-closing or the markup is handled externally.
/// - Children list is immutable when accessed via [getChildren].
/// - Can be used to construct hierarchical HTML representations programmatically.
///
/// ### Usage Example
/// ```dart
/// final child = TextCodeElement(
///   line: '<span>Hello</span>',
///   content: 'Hello',
/// );
///
/// final element = HtmlTagElement(
///   tagName: 'div',
///   line: '<div>Hello</div>',
///   content: 'Hello',
///   openingTag: '<div>',
///   closingTag: '</div>',
///   children: [child],
/// );
///
/// print(element.getTagName()); // 'div'
/// print(element.getOpeningTag()); // '<div>'
/// print(element.getChildren().first.getContent()); // 'Hello'
/// ```
/// {@endtemplate}
final class HtmlTagElement implements CodeElement {
  /// Optional opening tag string (e.g., '<div>').
  final String? _openingTag;

  /// Optional closing tag string (e.g., '</div>').
  final String? _closingTag;

  /// The tag name (e.g., 'div', 'span').
  final String _tagName;

  /// The raw line of code where the element appears.
  final String _line;

  /// The inner content of the element.
  final String _content;

  /// List of child elements contained within this HTML element.
  final List<CodeElement> _children;

  /// Creates a new [HtmlTagElement] with the given [tagName], [line], [content],
  /// optional [openingTag], [closingTag], and optional [children].
  ///
  /// If [children] is not provided, it defaults to an empty list.
  /// 
  /// {@macro jetleaf_html_tag_element}
  HtmlTagElement({
    required String tagName,
    required String line,
    required String content,
    String? openingTag,
    String? closingTag,
    List<CodeElement>? children,
  })  : _tagName = tagName,
        _line = line,
        _content = content,
        _openingTag = openingTag,
        _closingTag = closingTag,
        _children = children ?? [];

  @override
  String? getOpeningTag() => _openingTag;

  @override
  String? getClosingTag() => _closingTag;

  @override
  String? getTagName() => _tagName;

  @override
  String getLine() => _line;

  @override
  String getContent() => _content;

  @override
  List<CodeElement> getChildren() => List.unmodifiable(_children);

  @override
  List<Object?> equalizedProperties() => [_children, _closingTag, _content, _line, _openingTag, _tagName];
}

/// {@template jetleaf_statement}
/// Represents a **code statement** within a [CodeStructure] or template.
///
/// [Statement] extends [CodeElement] and adds the concept of a **statement string**,
/// which represents the logical or functional content of the statement. This can
/// substitute or complement the raw line of code returned by [CodeElement.getLine].
///
/// ### Responsibilities
/// - Provide the core statement content via [getStatement].
/// - Be compatible with [CodeElement] so it can exist in a hierarchical code structure.
/// - Serve as a base interface for specific statement implementations,
///   such as [ConditionalStatement], loop statements, or custom template statements.
///
/// ### Design Notes
/// - `getStatement` is intended to provide the semantic content of the statement,
///   whereas `getLine` may provide the raw code line from the template or source.
/// - Implementations should maintain consistency with `getLine` and `getContent`.
///
/// ### Usage Example
/// ```dart
/// final ifStatement = ConditionalStatement(
///   condition: 'user.isLoggedIn',
///   statement: 'Show welcome message',
///   line: '{{#if user.isLoggedIn}}',
///   content: 'Hello World',
/// );
///
/// print(ifStatement.getStatement()); // 'Show welcome message'
/// print(ifStatement.getLine()); // '{{#if user.isLoggedIn}}'
/// ```
/// {@endtemplate}
abstract interface class Statement implements CodeElement {
  /// Returns the core **statement content**.
  ///
  /// This is a semantic representation of the statement and may be used
  /// in place of or in addition to the raw line of code.
  String getStatement();
}

/// {@template jetleaf_conditional_statement}
/// Represents a **conditional (if) statement** in a template or code structure.
///
/// [ConditionalStatement] implements [Statement] and [CodeElement], providing
/// information about the condition, statement, and nested child elements within
/// the if block.
///
/// ### Responsibilities
/// - Store the condition expression for the if block.
/// - Store the statement associated with the condition.
/// - Maintain optional child elements that are executed/rendered if the condition is true.
/// - Provide opening and closing tag representations for template rendering.
///
/// ### Design Notes
/// - Opening tag uses the syntax `'{{#if condition}}'`.
/// - Closing tag uses `'{{/if}}'`.
/// - The tag name is fixed as `'if'`.
/// - Children list is immutable when accessed via [getChildren].
/// - Useful in template engines that support conditional rendering.
///
/// ### Usage Example
/// ```dart
/// final child = TextCodeElement(
///   line: '  Hello World',
///   content: 'Hello World',
/// );
///
/// final conditional = ConditionalStatement(
///   condition: 'user.isLoggedIn',
///   statement: 'Show welcome message',
///   line: '{{#if user.isLoggedIn}}',
///   content: 'Hello World',
///   children: [child],
/// );
///
/// print(conditional.getOpeningTag()); // '{{#if user.isLoggedIn}}'
/// print(conditional.getClosingTag()); // '{{/if}}'
/// print(conditional.getChildren().first.getContent()); // 'Hello World'
/// ```
/// {@endtemplate}
final class ConditionalStatement implements Statement {
  /// The conditional expression for the if block.
  final String _condition;

  /// The statement or description associated with the condition.
  final String _statement;

  /// The raw line representing this statement in the template.
  final String _line;

  /// The content of this conditional statement.
  final String _content;

  /// List of child elements nested inside the if block.
  final List<CodeElement> _children;

  /// Creates a new [ConditionalStatement] with the given [condition], [statement],
  /// [line], [content], and optional [children].
  /// 
  /// {@macro jetleaf_conditional_statement}
  ConditionalStatement({
    required String condition,
    required String statement,
    required String line,
    required String content,
    List<CodeElement>? children,
  })  : _condition = condition,
        _statement = statement,
        _line = line,
        _content = content,
        _children = children ?? [];

  String get condition => _condition;

  @override
  String getStatement() => _statement;

  @override
  String? getOpeningTag() => '{{#if $_condition}}';

  @override
  String? getClosingTag() => '{{/if}}';

  @override
  String? getTagName() => 'if';

  @override
  String getLine() => _line;

  @override
  String getContent() => _content;

  @override
  List<CodeElement> getChildren() => List.unmodifiable(_children);

  @override
  List<Object?> equalizedProperties() => [_children, _condition, _content, _line, _statement];
}

/// {@template jetleaf_for_each_statement}
/// Represents a **loop statement** (each block) within a template or code structure.
///
/// [ForEachStatement] implements [Statement] and [CodeElement], providing
/// information about the collection to iterate, the statement inside the loop,
/// and any nested child elements.
///
/// ### Responsibilities
/// - Store the key or identifier of the collection to iterate (`itemsKey`).
/// - Store the statement executed on each iteration.
/// - Maintain child elements that are repeated for each item in the collection.
/// - Provide opening and closing tag representations for template rendering.
///
/// ### Design Notes
/// - Opening tag uses the syntax `'{{#each itemsKey}}'`.
/// - Closing tag uses `'{{/each}}'`.
/// - Tag name is fixed as `'each'`.
/// - Children list is immutable when accessed via [getChildren].
/// - Useful in template engines that support iteration over collections.
///
/// ### Usage Example
/// ```dart
/// final itemElement = TextCodeElement(
///   line: '  {{this.name}}',
///   content: '{{this.name}}',
/// );
///
/// final loop = ForEachStatement(
///   itemsKey: 'users',
///   statement: 'Render user names',
///   line: '{{#each users}}',
///   content: '{{this.name}}',
///   children: [itemElement],
/// );
///
/// print(loop.getOpeningTag()); // '{{#each users}}'
/// print(loop.getClosingTag()); // '{{/each}}'
/// print(loop.getChildren().first.getContent()); // '{{this.name}}'
/// ```
/// {@endtemplate}
final class ForEachStatement implements Statement {
  /// The key or identifier of the collection to iterate.
  final String _itemsKey;

  /// The statement executed on each iteration.
  final String _statement;

  /// The raw line representing this loop in the template.
  final String _line;

  /// The content inside the loop block.
  final String _content;

  /// List of child elements that are repeated for each item in the collection.
  final List<CodeElement> _children;

  /// Creates a new [ForEachStatement] with the given [itemsKey], [statement],
  /// [line], [content], and optional [children].
  /// 
  /// {@macro jetleaf_for_each_statement}
  ForEachStatement({
    required String itemsKey,
    required String statement,
    required String line,
    required String content,
    List<CodeElement>? children,
  })  : _itemsKey = itemsKey,
        _statement = statement,
        _line = line,
        _content = content,
        _children = children ?? [];

  /// Returns the key of the collection being iterated.
  String getItemsKey() => _itemsKey;

  @override
  String getStatement() => _statement;

  @override
  String? getOpeningTag() => '{{#each $_itemsKey}}';

  @override
  String? getClosingTag() => '{{/each}}';

  @override
  String? getTagName() => 'each';

  @override
  String getLine() => _line;

  @override
  String getContent() => _content;

  @override
  List<CodeElement> getChildren() => List.unmodifiable(_children);

  @override
  List<Object?> equalizedProperties() => [_children, _content, _itemsKey, _line, _statement];
}

/// {@template jetleaf_include_statement}
/// Represents an **include statement** in a template, which imports or
/// embeds another template within the current template.
///
/// [IncludeStatement] implements [Statement] and [CodeElement], providing
/// information about the included template and the statement associated with it.
///
/// ### Responsibilities
/// - Store the name of the template to include (`templateName`).
/// - Store the statement or description related to the include.
/// - Provide opening tag representation for template rendering.
///
/// ### Design Notes
/// - Opening tag uses the syntax `'{{>templateName}}'`.
/// - Include statements do not have a closing tag.
/// - Children list is always empty because include statements are atomic.
/// - Useful in template engines that support modular templates or partials.
///
/// ### Usage Example
/// ```dart
/// final include = IncludeStatement(
///   templateName: 'header',
///   statement: 'Include header template',
///   line: '{{>header}}',
/// );
///
/// print(include.getOpeningTag()); // '{{>header}}'
/// print(include.getClosingTag()); // null
/// print(include.getChildren().length); // 0
/// ```
/// {@endtemplate}
final class IncludeStatement implements Statement {
  /// The name of the template to include.
  final String _templateName;

  /// The statement or description associated with this include.
  final String _statement;

  /// The raw line representing this include statement in the template.
  final String _line;

  /// Creates a new [IncludeStatement] with the given [templateName], [statement], and [line].
  /// 
  /// {@macro jetleaf_include_statement}
  IncludeStatement({required String templateName, required String statement, required String line})
    : _templateName = templateName, _statement = statement, _line = line;

  /// Returns the name of the included template.
  String getTemplateName() => _templateName;

  @override
  String getStatement() => _statement;

  @override
  String? getOpeningTag() => '{{>$_templateName}}';

  @override
  String? getClosingTag() => null;

  @override
  String? getTagName() => 'include';

  @override
  String getLine() => _line;

  @override
  String getContent() => _statement;

  @override
  List<CodeElement> getChildren() => [];

  @override
  List<Object?> equalizedProperties() => [_line, _statement, _templateName];
}