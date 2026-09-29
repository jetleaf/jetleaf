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

import 'template.dart';
import 'source_code.dart';
import '_source_code.dart';
import 'filter_registry.dart';

/// {@template jtl_template}
/// A concrete implementation of [Template] that stores a **template source**
/// and a map of **attributes** to inject during rendering.
///
/// [JtlTemplate] represents a template either as a raw string or as a reference
/// to a file or asset path, along with associated dynamic attributes. It is
/// immutable and suitable for use with [TemplateRenderer] or the Jetleaf engine.
///
/// ### Features
/// - Stores the template as a string or path.
/// - Attributes are stored as a map and exposed as an unmodifiable view.
/// - Immutable and simple to use for templates with static or dynamic content.
///
/// ### Example Usage
/// ```dart
/// final template = JtlTemplate(
///   "templates/homepage.html",
///   {"title": "Hello World", "showBanner": true},
/// );
///
/// print(template.getLocation()); // "templates/homepage.html"
/// print(template.getAttributes()); // {"title": "Hello World", "showBanner": true}
/// ```
///
/// ### Design Notes
/// - `_attributes` map is wrapped with `Map.unmodifiable` to prevent external mutation.
/// - Template content (`_location`) is immutable after creation.
/// - Can represent either raw content or a path/identifier to an external template.
/// {@endtemplate}
final class JtlTemplate implements Template {
  /// Internal storage for template attributes.
  final Map<String, Object?> _attributes;

  /// The template source, which may be raw content or a path/identifier.
  final String _location;

  /// Creates a new [JtlTemplate] with the given template content and attributes.
  ///
  /// - `template`: The raw template string or a path/location of the template.
  /// - `attributes`: A map of values to inject during rendering.
  JtlTemplate(this._location, this._attributes);

  @override
  Map<String, Object?> getAttributes() => Map.unmodifiable(_attributes);

  @override
  String getLocation() => _location;
}

/// {@template jetleaf_default_variable_resolver}
/// Default implementation of [TemplateVariableResolver], providing variable
/// resolution from a **flat or nested map** of values.
///
/// [DefaultVariableResolver] supports:
/// - Resolving simple variables: `'name'`
/// - Resolving nested variables using dot notation: `'user.address.city'`
/// - Converting values to string representations for template rendering.
///
/// ### Design Notes
/// - Nested variables are resolved recursively through `Map<String, Object?>`.
/// - Supports standard types: `String`, `bool`, `List`, `Map`, and general objects.
/// - Returns empty string `''` for `null` values to avoid template errors.
///
/// ### Usage Example
/// ```dart
/// final resolver = DefaultVariableResolver({
///   'name': 'Alice',
///   'user': {
///     'address': {'city': 'Paris', 'zip': 75000}
///   },
///   'tags': ['dart', 'flutter']
/// });
///
/// print(resolver.resolve('name')); // 'Alice'
/// print(resolver.resolve('user.address.city')); // 'Paris'
/// print(resolver.resolve('tags')); // 'dart, flutter'
/// print(resolver.resolve('unknown')); // ''
/// ```
/// {@endtemplate}
final class DefaultVariableResolver implements TemplateVariableResolver {
  /// Map of variable names to their values.
  Map<String, Object?> _variables = {};

  /// Creates a new [DefaultVariableResolver] with the given variable map.
  /// 
  /// {@macro jetleaf_default_variable_resolver}
  DefaultVariableResolver();

  @override
  void setVariables(Map<String, Object?> variables) {
    _variables = variables;
  }

  @override
  String resolve(String variable) {
    final value = _resolveNested(variable);
    return _valueToString(value);
  }

  /// Resolves a variable and returns the raw value, preserving types.
  Object? resolveRaw(String variable) {
    return _resolveNested(variable);
  }

  /// Resolves a variable using dot notation for nested access.
  Object? _resolveNested(String path) {
    final parts = path.trim().split('.');
    Object? current = _variables;

    for (final part in parts) {
      if (current is Map<String, Object?>) {
        current = current[part.trim()];
      } else if (current is Map) {
        current = current[part.trim()];
      } else {
        return null;
      }
    }

    return current;
  }

  /// Converts a value to its string representation, handling special cases.
  String _valueToString(Object? value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is bool) return value ? 'true' : 'false';
    if (value is List) return value.join(', ');
    if (value is Map) return value.toString();
    return value.toString();
  }
}

/// {@template jetleaf_default_expression_evaluator}
/// Default implementation of [TemplateExpressionEvaluator], capable of
/// evaluating template expressions in a given [TemplateContext].
///
/// [DefaultExpressionEvaluator] supports:
/// - Logical operators: `&&`, `||`
/// - Comparison operators: `==`, `!=`, `>`, `<`, `>=`, `<=`
/// - Nullish coalescing: `??`
/// - Literal values: strings, numbers, booleans, and null
/// - Variable resolution via [TemplateVariableResolver]
///
/// ### Design Notes
/// - Expressions are parsed in a **simple recursive manner**, handling
///   operator precedence manually (logical operators lowest, then comparison).
/// - Returns `false` on invalid expressions instead of throwing.
/// - Supports dot notation for nested variable access (`user.address.city`).
///
/// ### Usage Example
/// ```dart
/// final context = DefaultTemplateContext({'age': 25});
/// final evaluator = DefaultExpressionEvaluator();
///
/// print(evaluator.evaluate('age >= 18', context)); // true
/// print(evaluator.evaluate('age < 18 || false', context)); // false
/// print(evaluator.evaluate('"hello" == "hello"', context)); // true
/// ```
/// {@endtemplate}
final class DefaultExpressionEvaluator implements TemplateExpressionEvaluator {
  /// {@macro jetleaf_default_expression_evaluator}
  const DefaultExpressionEvaluator();

  @override
  bool evaluate(String expression, TemplateContext context) {
    try {
      final trimmed = expression.trim();

      // Handle logical operators first (lowest precedence)
      if (trimmed.contains('&&')) {
        final parts = trimmed.split('&&');
        return parts.every((part) => evaluate(part, context));
      }

      if (trimmed.contains('||')) {
        final parts = trimmed.split('||');
        return parts.any((part) => evaluate(part, context));
      }

      // Handle comparison operators
      for (final op in ['==', '!=', '>=', '<=', '>', '<']) {
        if (trimmed.contains(op)) {
          final parts = trimmed.split(op);
          if (parts.length == 2) {
            final left = _resolveValue(parts[0], context);
            final right = _resolveValue(parts[1], context);
            return _compare(left, right, op);
          }
        }
      }

      // Handle nullish coalescing
      if (trimmed.contains('??')) {
        final parts = trimmed.split('??');
        final left = _resolveValue(parts[0], context);
        if (left != null) {
          return _isTruthy(left);
        }

        final right = _resolveValue(parts[1], context);
        return _isTruthy(right);
      }

      // Simple variable evaluation
      final value = _resolveValue(trimmed, context);
      return _isTruthy(value);
    } catch (e) {
      return false;
    }
  }

  /// Resolves a value (variable or literal) in the given context.
  Object? _resolveValue(String value, TemplateContext context) {
    final trimmed = value.trim();

    // String literals
    if ((trimmed.startsWith('"') && trimmed.endsWith('"')) || (trimmed.startsWith("'") && trimmed.endsWith("'"))) {
      return trimmed.substring(1, trimmed.length - 1);
    }

    // Number literals
    if (int.tryParse(trimmed) != null) return int.parse(trimmed);
    if (double.tryParse(trimmed) != null) return double.parse(trimmed);

    // Boolean literals
    if (trimmed == 'true') return true;
    if (trimmed == 'false') return false;
    if (trimmed == 'null') return null;

    // Variable resolution — preserve raw types for comparisons
    final resolver = context.getVariableResolver();
    if (resolver is DefaultVariableResolver) {
      final rawValue = resolver.resolveRaw(trimmed);
      if (rawValue != null) return rawValue;
      // Check if variable exists but is null
      if (resolver.resolve(trimmed).isEmpty) return null;
    }
    final result = resolver.resolve(trimmed);
    return result.isEmpty ? null : result;
  }

  /// Compares two values using the given operator.
  bool _compare(Object? left, Object? right, String operator) {
    switch (operator) {
      case '==':
        return left == right;
      case '!=':
        return left != right;
      case '>':
        return ((left is num ? left as num? : 0) ?? 0) > ((right is num ? right as num? : 0) ?? 0);
      case '<':
        return ((left is num ? left as num? : 0) ?? 0) < ((right is num ? right as num? : 0) ?? 0);
      case '>=':
        return ((left is num ? left as num? : 0) ?? 0) >= ((right is num ? right as num? : 0) ?? 0);
      case '<=':
        return ((left is num ? left as num? : 0) ?? 0) <= ((right is num ? right as num? : 0) ?? 0);
      default:
        return false;
    }
  }

  /// Evaluates if a value is truthy.
  bool _isTruthy(Object? value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.isNotEmpty;
    if (value is num) return value != 0;
    if (value is List) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    return true;
  }
}

/// {@template jetleaf_default_template_context}
/// Default implementation of [TemplateContext], representing the context
/// in which a template is rendered.
///
/// Provides access to:
/// - Dynamic attributes for template injection ([getAttributes])
/// - Variable resolution via [TemplateVariableResolver]
/// - Expression evaluation via [TemplateExpressionEvaluator]
///
/// ### Design Notes
/// - Attributes are immutable from the outside (unmodifiable map).
/// - Supports custom [TemplateVariableResolver] and [TemplateExpressionEvaluator],
///   but provides default implementations if none are supplied.
/// - Lazy initialization ensures resolvers are available without redundant instantiation.
///
/// ### Usage Example
/// ```dart
/// final context = DefaultTemplateContext({
///   'user': {'name': 'Alice', 'age': 30},
///   'isAdmin': true,
/// });
///
/// final name = context.getVariableResolver().resolve('user.name'); // 'Alice'
/// final isAdult = context.getExpressionEvaluator().evaluate('user.age >= 18', context); // true
/// ```
/// {@endtemplate}
final class DefaultTemplateContext implements TemplateContext {
  /// Variable resolver used to resolve template variables to their string values.
  final TemplateVariableResolver _variableResolver;

  /// Expression evaluator used to evaluate expressions in the template context.
  late final TemplateExpressionEvaluator _expressionEvaluator;

  /// Creates a new [DefaultTemplateContext] with the given attributes.
  ///
  /// [_attributes] - Map of key-value pairs to inject into the template.
  /// [variableResolver] - Optional custom resolver for template variables.
  /// [expressionEvaluator] - Optional custom evaluator for expressions.
  /// 
  /// {@macro jetleaf_default_template_context}
  DefaultTemplateContext(this._variableResolver, [TemplateExpressionEvaluator? expressionEvaluator]) {
    _expressionEvaluator = expressionEvaluator ?? DefaultExpressionEvaluator();
  }

  @override
  TemplateVariableResolver getVariableResolver() => _variableResolver;

  @override
  TemplateExpressionEvaluator getExpressionEvaluator() => _expressionEvaluator;
}

/// {@template default_template_renderer}
/// A **template renderer** that converts `Template` instances into
/// fully-rendered source code strings (`SourceCode`) using context-aware
/// processing, variable substitution, conditionals, loops, and filters.
///
/// This renderer is part of a template processing framework and works with
/// a [TemplateFilterRegistry] to apply custom transformations to variables during
/// rendering.
///
/// ### Features
/// - Parses template structure to identify includes, conditionals, loops, and variables.
/// - Renders templates with context-aware variable resolution.
/// - Supports **nested templates**, conditional blocks, loops, and custom filters.
/// - Escapes HTML by default to prevent XSS vulnerabilities.
/// - Returns a [SourceCode] object containing raw content, rendered content, and code structure.
///
/// ### Template Syntax
/// - **Includes**: `{{> templateName}}`
/// - **Conditionals**: `{{#if condition}}content{{/if}}`
/// - **Loops**: `{{#each items}}content{{/each}}`
/// - **Variables**: `{{variableName}}`
/// - **Variables with filters**: `{{variableName | filter1 | filter2}}`
///
/// ### Example Usage
/// ```dart
/// final renderer = DefaultTemplateRenderer(filterRegistry);
/// final template = Template(
///   getLocation: () => '<h1>{{title}}</h1>',
///   getContext: () => DefaultTemplateContext({'title': 'Hello World'}),
/// );
///
/// final result = renderer.render(template);
/// print(result.renderedContent); // <h1>Hello World</h1>
/// ```
///
/// ### Processing Order
/// 1. Includes (`{{> ...}}`)
/// 2. Conditional blocks (`{{#if ...}} ... {{/if}}`)
/// 3. Loops (`{{#each ...}} ... {{/each}}`)
/// 4. Filters (`{{variable | filter1 | filter2}}`)
/// 5. Variables (`{{variable}}`)
///
/// ### Design Notes
/// - Simple regex-based parsing for structural elements (includes, conditionals, loops).
/// - Context cloning ensures each loop iteration has isolated variables like `this`, `@index`, `@first`, `@last`.
/// - Filter processing uses the provided [TemplateFilterRegistry] to transform variable output.
/// - HTML escaping applied to variable values by default.
///
/// ### See Also
/// - [Template]
/// - [TemplateContext]
/// - [TemplateFilterRegistry]
/// - [SourceCode]
/// {@endtemplate}
final class DefaultTemplateRenderer implements TemplateRenderer {
  /// The registry of filters used during template rendering.
  final TemplateFilterRegistry _filterRegistry;

  /// The asset builder to use in finding the template asset.
  final AssetBuilder _assetBuilder;

  /// {@macro default_template_renderer}
  DefaultTemplateRenderer(this._filterRegistry, this._assetBuilder);

  @override
  SourceCode render(Template template, TemplateContext context, [Asset? built]) {
    final asset = built ?? _assetBuilder.build(template.getLocation());
    final rawContent = asset.getContentAsString();

    // Parse template structure
    final codeStructure = _parseTemplate(rawContent, context);

    // Render template with context
    final renderedContent = _renderTemplate(rawContent, template, context);

    return SourceCodeBuilder()
        .withAsset(asset)
        .withCodeStructure(codeStructure)
        .withRenderedContent(renderedContent)
        .withRawContent(rawContent)
        .build();
  }

  /// Parses the template and creates a code structure.
  CodeStructure _parseTemplate(String rawContent, TemplateContext context) {
    final elements = <CodeElement>[];
    final builder = CodeStructureBuilder().withType('HTML');

    // Simple parsing: extract structural elements
    final includePattern = RegExp(r'\{\{>\s*([^}]+)\s*\}\}');
    final conditionalPattern = RegExp(r'\{\{#if\s+([^}]+)\}\}(.*?)\{\{/if\}\}', dotAll: true);
    final loopPattern = RegExp(r'\{\{#each\s+([^}]+)\}\}(.*?)\{\{/each\}\}', dotAll: true);

    // Extract and parse each type of statement
    for (final match in conditionalPattern.allMatches(rawContent)) {
      final condition = match.group(1)!.trim();
      final content = match.group(2)!;
      elements.add(ConditionalStatement(
        condition: condition,
        statement: match.group(0)!,
        line: match.group(0)!,
        content: content,
      ));
    }

    for (final match in loopPattern.allMatches(rawContent)) {
      final itemsKey = match.group(1)!.trim();
      final content = match.group(2)!;
      elements.add(ForEachStatement(
        itemsKey: itemsKey,
        statement: match.group(0)!,
        line: match.group(0)!,
        content: content,
      ));
    }

    for (final match in includePattern.allMatches(rawContent)) {
      final templateName = match.group(1)!.trim();
      elements.add(IncludeStatement(
        templateName: templateName,
        statement: match.group(0)!,
        line: match.group(0)!,
      ));
    }

    return builder.addElements(elements).build();
  }

  /// Renders a rawContent with the provided context.
  String _renderTemplate(String rawContent, Template template, TemplateContext context) {
    String result = rawContent;

    // Process in order of precedence
    result = _processIncludes(result, template, context);
    result = _processLoops(result, template, context);
    result = _processConditionals(result, template, context);
    result = _processFilters(result, template, context);
    result = _processVariables(result, template, context);

    return result;
  }

  /// Processes rawContent includes.
  /// Syntax: `{{>templateName}}`
  String _processIncludes(String rawContent, Template template, TemplateContext context) {
    final includePattern = RegExp(r'\{\{>\s*([^}]+)\s*\}\}');
    return rawContent.replaceAllMapped(includePattern, (match) {
      final templateName = match.group(1)!.trim();
      return '<!-- Include: $templateName -->'; // Placeholder for actual file loading
    });
  }

  /// Processes conditional blocks.
  /// Syntax: `{{#if condition}}content{{/if}}`
  String _processConditionals(String rawContent, Template template, TemplateContext context) {
    final conditionalPattern = RegExp(r'\{\{#if\s+([^}]+)\}\}(.*?)\{\{/if\}\}', dotAll: true);

    return rawContent.replaceAllMapped(conditionalPattern, (match) {
      final condition = match.group(1)!.trim();
      final content = match.group(2)!;

      final evaluator = context.getExpressionEvaluator();
      final conditionValue = evaluator.evaluate(condition, context);

      if (conditionValue) {
        return _renderTemplate(content, template, context);
      }
      return '';
    });
  }

  /// Processes loop blocks.
  /// Syntax: `{{#each items}}content{{/each}}`
  String _processLoops(String rawContent, Template template, TemplateContext context) {
    final loopPattern = RegExp(r'\{\{#each\s+([^}]+)\}\}(.*?)\{\{/each\}\}', dotAll: true);

    return rawContent.replaceAllMapped(loopPattern, (match) {
      final itemsKey = match.group(1)!.trim();
      final content = match.group(2)!;

      // Try to parse as list-like structure
      final attributes = template.getAttributes();
      final items = _getNestedValue(itemsKey, attributes);

      if (items is! List) return '';

      final buffer = StringBuffer();
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final itemContext = Map<String, Object?>.from(attributes);
        itemContext['this'] = item;
        itemContext['@index'] = i;
        itemContext['@first'] = i == 0;
        itemContext['@last'] = i == items.length - 1;

        // Create a new context with iteration variables
        final itemResolver = DefaultVariableResolver();
        itemResolver.setVariables(itemContext);
        final itemTemplateContext = DefaultTemplateContext(itemResolver);
        final templateClone = JtlTemplate(template.getLocation(), itemContext);
        final renderedContent = _renderTemplate(content, templateClone, itemTemplateContext);
        buffer.write(renderedContent);
      }

      return buffer.toString();
    });
  }

  /// Processes variables with optional filters.
  /// Syntax: `{{variableName}}` or `{{variableName | filter1 | filter2}}`
  String _processVariables(String rawContent, Template template, TemplateContext context) {
    final variablePattern = RegExp(r'\{\{([^#/>][^}]*)\}\}');

    return rawContent.replaceAllMapped(variablePattern, (match) {
      final variable = match.group(1)!.trim();
      final resolver = context.getVariableResolver();
      var value = resolver.resolve(variable);

      return _escapeHtml(value);
    });
  }

  /// Processes variable filters.
  /// Syntax: `{{variable | filter1 | filter2}}`
  String _processFilters(String rawContent, Template template, TemplateContext context) {
    final filterPattern = RegExp(r'\{\{([^#/>]*?)\s*\|\s*([^}]+)\}\}');

    return rawContent.replaceAllMapped(filterPattern, (match) {
      final variable = match.group(1)!.trim();
      final filterChain = match.group(2)!.trim().split('|');

      final resolver = context.getVariableResolver();
      // Resolve raw value (preserving types) for filter input
      Object? value;
      if (resolver is DefaultVariableResolver) {
        value = resolver.resolveRaw(variable);
      }
      value ??= resolver.resolve(variable);

      bool htmlescapeApplied = false;

      // Apply filters in sequence
      for (final filterName in filterChain) {
        final name = filterName.trim();
        final filter = _filterRegistry.getFilter(name);
        if (filter != null) {
          value = filter(value);
          if (name == 'htmlescape') htmlescapeApplied = true;
        }
      }

      final strValue = value?.toString() ?? '';
      return htmlescapeApplied ? strValue : _escapeHtml(strValue);
    });
  }

  /// Gets a nested value from attributes using dot notation.
  dynamic _getNestedValue(String path, Map<String, Object?> attributes) {
    final parts = path.split('.');
    Object? current = attributes;

    for (final part in parts) {
      if (current is Map<String, Object?>) {
        current = current[part];
      } else if (current is Map) {
        current = current[part];
      } else {
        return null;
      }
    }

    return current;
  }

  /// Escapes HTML special characters to prevent XSS attacks.
  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }
}