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

/// {@template template_variable_resolver}
/// Resolves **template variable names** into their string representations
/// at runtime during template rendering.
///
/// [TemplateVariableResolver] provides a flexible mechanism to supply values
/// for placeholders in templates. It abstracts how variables are looked up,
/// computed, or fetched from external sources.
///
/// ### Responsibilities
/// - Resolve a variable name to a string that can be substituted into a
///   template.
/// - Support dynamic or computed variable resolution.
/// - Optionally allow bulk setting of variables for later resolution.
///
/// ### Design Notes
/// - Implementations may use an internal map, lazy computation, or integrate
///   with external services.
/// - Should handle unknown or missing variables gracefully:
///   - Return an empty string,
///   - Provide a default value, or
///   - Throw a descriptive exception, depending on the use case.
/// - Useful in combination with [TemplateContext] and [TemplateRenderer].
///
/// ### Example Implementation
/// ```dart
/// class MapVariableResolver implements TemplateVariableResolver {
///   final Map<String, Object?> _variables;
///
///   MapVariableResolver([Map<String, Object?>? variables])
///       : _variables = variables ?? {};
///
///   @override
///   String resolve(String variable) => _variables[variable]?.toString() ?? '';
///
///   @override
///   void setVariables(Map<String, Object?> variables) {
///     _variables.clear();
///     _variables.addAll(variables);
///   }
/// }
/// ```
/// {@endtemplate}
abstract interface class TemplateVariableResolver {
  /// Resolves the given [variable] name to its **string representation**.
  ///
  /// - **Parameters**
  ///   - `variable`: The name of the variable to resolve.
  /// - **Returns**
  ///   - The string representation of the variable's value, or a fallback if
  ///     the variable is unknown.
  ///
  /// ### Design Notes
  /// - Resolution may be backed by a map, computed on-the-fly, or fetched
  ///   externally.
  /// - Implementations should handle unknown variables gracefully.
  String resolve(String variable);

  /// Sets multiple variables at once.
  ///
  /// - **Parameters**
  ///   - `variables`: A map of variable names to values.
  /// - **Behavior**
  ///   - Updates or replaces the resolver’s internal variable state.
  ///   - Subsequent calls to [resolve] will use the updated variables.
  void setVariables(Map<String, Object?> variables);
}

/// {@template jetleaf_expression_evaluator}
/// Evaluates expressions in the context of a template, returning a
/// boolean result that indicates whether the expression is truthy.
///
/// An [TemplateExpressionEvaluator] is used within template engines to support
/// conditional rendering, loops, or dynamic content based on the values
/// in a [TemplateContext].
///
/// ### Responsibilities
/// - Parse and evaluate expressions provided as strings.
/// - Resolve variables and values using a [TemplateContext].
/// - Return a boolean indicating whether the expression is considered "truthy".
/// - Support template logic such as `if` statements, `for` loops, or custom
///   conditional directives.
///
/// ### Design Notes
/// - Implementations may use expression parsing libraries, regex evaluation,
///   or custom interpreters.
/// - Should handle unknown variables gracefully, e.g., treat missing variables
///   as `null` or false, depending on the template logic.
/// - Can be extended to support operators, comparisons, and functions within
///   template expressions.
///
/// ### Usage Example
/// ```dart
/// final evaluator = MyExpressionEvaluator();
/// final context = MyTemplateContext({'isLoggedIn': true});
///
/// final result = evaluator.evaluate('isLoggedIn', context);
/// print(result); // true
///
/// final result2 = evaluator.evaluate('user.age > 18', context);
/// print(result2); // true or false depending on context
/// ```
/// {@endtemplate}
abstract interface class TemplateExpressionEvaluator {
  /// Evaluates the given [expression] string using the provided [context].
  ///
  /// Returns `true` if the expression evaluates to a truthy value, `false`
  /// otherwise.
  ///
  /// ### Parameters
  /// - [expression]: The expression string to evaluate (e.g., `'user.isAdmin'`).
  /// - [context]: The [TemplateContext] providing variable values for resolution.
  ///
  /// ### Design Notes
  /// - Must use [context.getVariableResolver()] or attributes for variable resolution.
  /// - Should throw a descriptive exception if the expression syntax is invalid,
  ///   or optionally return `false`.
  bool evaluate(String expression, TemplateContext context);
}

/// {@template template_context}
/// Represents the **runtime context for a template**, providing the mechanisms
/// to resolve variables and evaluate expressions during template rendering.
///
/// A [TemplateContext] abstracts how template variables and expressions are
/// resolved, enabling dynamic rendering of templates with placeholders,
/// conditionals, loops, and filters.
///
/// ### Responsibilities
/// - Provide a [TemplateVariableResolver] to map template variable names to
///   their runtime string representations.
/// - Provide a [TemplateExpressionEvaluator] to evaluate expressions,
///   supporting logical operations, comparisons, and conditional flow.
/// - Serve as the bridge between raw template content and the actual data used
///   to populate it.
///
/// ### Design Notes
/// - Implementations may wrap attribute maps, computed values, or external
///   sources for dynamic resolution.
/// - Should ensure consistency between variable resolution and attributes.
/// - Must handle invalid variable names or expressions gracefully, either by
///   returning default values or throwing descriptive exceptions.
///
/// ### Example Implementation
/// ```dart
/// class DefaultTemplateContext implements TemplateContext {
///   final Map<String, Object?> _attributes;
///   final TemplateVariableResolver _resolver;
///   final TemplateExpressionEvaluator _evaluator;
///
///   DefaultTemplateContext(this._attributes)
///       : _resolver = MapVariableResolver(_attributes),
///         _evaluator = SimpleExpressionEvaluator(_attributes);
///
///   @override
///   TemplateVariableResolver getVariableResolver() => _resolver;
///
///   @override
///   TemplateExpressionEvaluator getExpressionEvaluator() => _evaluator;
/// }
/// ```
/// {@endtemplate}
abstract interface class TemplateContext {
  /// Returns a [TemplateVariableResolver] capable of resolving template
  /// variable names into their string representations.
  ///
  /// - Allows templates to dynamically resolve placeholders at runtime.
  /// - Can support formatting, computed values, or fallback strategies.
  ///
  /// ### Design Notes
  /// - Resolution should be consistent with [getExpressionEvaluator] and
  ///   underlying attributes.
  /// - Implementations may cache resolved variables for performance.
  TemplateVariableResolver getVariableResolver();

  /// Returns a [TemplateExpressionEvaluator] capable of evaluating
  /// expressions within the template context.
  ///
  /// - Expressions can reference variables from the context.
  /// - Supports logical operators, comparisons, and control flow.
  ///
  /// ### Design Notes
  /// - Should handle invalid expressions gracefully, either returning
  ///   `false` or throwing descriptive exceptions.
  /// - Can be implemented using a scripting engine, expression parser,
  ///   or custom evaluator.
  TemplateExpressionEvaluator getExpressionEvaluator();
}

/// {@template template}
/// Represents an **abstract template source** that can be rendered by a
/// [TemplateRenderer] using a set of dynamic attributes or a
/// [TemplateContext].
///
/// A [Template] provides a **path or location** to the template content, along
/// with a map of attributes to inject during rendering. This abstraction allows
/// templates to be sourced from files, memory, network, or other storage
/// mechanisms.
///
/// ### Responsibilities
/// - Provide the template location or path as a string, which will be loaded
///   and rendered by the template renderer.
/// - Supply a map of attributes (`Map<String, Object?>`) for variable
///   substitution and evaluation.
/// - Serve as an abstraction over different template sources (file system,
///   asset bundle, or dynamic content).
///
/// ### Design Notes
/// - Implementations may load the template content lazily based on the path.
/// - Attributes may be evaluated lazily, cached, or computed dynamically.
/// - Implementations must ensure `getAttributes()` never returns `null`.
///
/// ### Example Implementation
/// ```dart
/// class FileTemplate implements Template {
///   final String _path;
///   final Map<String, Object?> _attributes;
///
///   FileTemplate(this._path, [this._attributes = const {}]);
///
///   @override
///   String getLocation() => _path;
///
///   @override
///   Map<String, Object?> getAttributes() => _attributes;
/// }
/// ```
/// {@endtemplate}
abstract interface class Template {
  /// Returns the **path or location of the template** as a string.
  ///
  /// - The returned string is used by the renderer or asset loader to access
  ///   the template content.
  /// - May represent a file path, asset identifier, or other source.
  /// - Should be safe to call multiple times.
  String getLocation();

  /// Returns a map of **dynamic attributes** to inject into the template.
  ///
  /// - Keys are attribute names (usually strings).
  /// - Values can be of any type (`Object?`) and may be `null` for optional
  ///   attributes.
  ///
  /// ### Design Notes
  /// - Implementations may provide lazy evaluation, caching, or computed
  ///   attributes.
  /// - Must return a **non-null map**, even if empty.
  /// - Attributes serve as the context for rendering variables, conditionals,
  ///   loops, and filters.
  ///
  /// ### Example
  /// ```dart
  /// final attributes = myTemplate.getAttributes();
  /// print(attributes["title"]); // "Hello World"
  /// ```
  Map<String, Object?> getAttributes();
}

/// {@template template_renderer}
/// An **interface for rendering templates** into fully-formed [SourceCode]
/// using a given [TemplateContext].
///
/// [TemplateRenderer] is responsible for processing template content,
/// resolving placeholders, evaluating expressions, handling loops and
/// conditionals, applying filters, and producing the final rendered output.
///
/// ### Responsibilities
/// - Accept a [Template] and its corresponding [TemplateContext].
/// - Replace variables with their resolved values from the context.
/// - Evaluate expressions and control structures (e.g., conditionals, loops).
/// - Optionally escape content to prevent XSS or injection attacks.
/// - Return a [SourceCode] object containing both raw and rendered content,
///   and optionally metadata such as parsed code structure.
///
/// ### Design Notes
/// - Implementations may use caching to avoid re-parsing templates on repeated
///   render calls.
/// - Should handle missing, null, or invalid attributes gracefully according
///   to template syntax rules.
/// - Can support custom variable resolvers, filters, and expression evaluators
///   to extend template behavior.
///
/// ### Example Implementation
/// ```dart
/// class DefaultTemplateRenderer implements TemplateRenderer {
///   final FilterRegistry _filters;
///
///   DefaultTemplateRenderer(this._filters);
///
///   @override
///   SourceCode render(Template template, TemplateContext context, [Asset? built]) {
///     final content = template.getLocation();
///     final attributes = context.getVariableResolver();
///     // Render logic goes here...
///     return SourceCodeBuilder()
///         .withRenderedContent(renderedContent)
///         .withRawContent(content)
///         .build();
///   }
/// }
/// ```
/// {@endtemplate}
abstract interface class TemplateRenderer {
  /// Renders the given [template] using its associated [TemplateContext].
  ///
  /// - **Parameters**
  ///   - `template`: The [Template] to render, containing placeholders and
  ///     structure.
  ///   - `context`: The [TemplateContext] providing variable resolution and
  ///     expression evaluation.
  ///   - `built`:  An already verified or built [Asset] to skip building later on
  ///
  /// - **Returns**
  ///   - A [SourceCode] object containing the fully rendered template, raw
  ///     content, and optionally parsed structure or metadata.
  ///
  /// - **Behavior**
  ///   - Performs variable substitution, expression evaluation, and any
  ///     custom template processing (e.g., filters, includes, loops).
  ///   - Should gracefully handle missing or null values in the context.
  ///   - Implementations may cache intermediate representations or
  ///     compiled templates to improve performance.
  SourceCode render(Template template, TemplateContext context, [Asset? built]);
}