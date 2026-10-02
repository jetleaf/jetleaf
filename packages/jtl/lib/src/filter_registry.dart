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

/// {@template jetleaf_template_filter}
/// Represents a **filter function** that transforms a value in a template.
///
/// [TemplateFilter] is a function type that accepts an input value (which can
/// be `null`) and returns a transformed output value (which can also be `null`).
/// Filters are commonly used in template engines to format, modify, or compute
/// dynamic content before rendering.
///
/// ### Design Notes
/// - Input and output are both `Object?`, allowing maximum flexibility (strings,
///   numbers, lists, custom objects, etc.).
/// - Often used with a [TemplateFilterRegistry] to map filter names to implementations.
/// - Can be applied to template variables during rendering.
///
/// ### Usage Example
/// ```dart
/// TemplateFilter uppercase = (value) => value?.toString().toUpperCase();
/// TemplateFilter length = (value) {
///   if (value is String || value is List) return value.length;
///   return 0;
/// };
///
/// print(uppercase('hello')); // 'HELLO'
/// print(length([1, 2, 3])); // 3
/// ```
/// {@endtemplate}
typedef TemplateFilter = Object? Function(Object? value);

/// {@template jetleaf_filter_registry}
/// Registry for template filters that transform or process values during
/// template rendering.
///
/// A [TemplateFilterRegistry] maintains a map of filter names to their corresponding
/// functions, allowing templates to apply transformations dynamically. Filters
/// can operate on strings, numbers, lists, maps, or any object, returning a
/// processed value for rendering.
///
/// ### Responsibilities
/// - Provide built-in filters for common string, number, and list operations.
/// - Support registration of custom filters at runtime.
/// - Resolve filters by name for use during template rendering.
///
/// ### Design Notes
/// - Filters are functions of type `TemplateFilter`.
/// - Built-in filters cover common tasks like string capitalization,
///   length calculation, reversing, formatting numbers, and HTML/URL escaping.
/// - Custom filters can be added using [registerFilter].
///
/// ### Usage Example
/// ```dart
/// final registry = FilterRegistry();
///
/// final uppercase = registry.getFilter('uppercase');
/// print(uppercase?.call('hello')); // 'HELLO'
///
/// registry.registerFilter('double', (value) {
///   if (value is num) return value * 2;
///   return value;
/// });
///
/// final doubleFilter = registry.getFilter('double');
/// print(doubleFilter?.call(10)); // 20
/// ```
/// {@endtemplate}
class TemplateFilterRegistry {
  /// Internal map of filter names to their implementations.
  ///
  /// Keys are the filter names (e.g., 'uppercase', 'round'), and values
  /// are functions taking an `Object?` input and returning a processed `Object?`.
  final Map<String, TemplateFilter> _filters = {};

  /// Creates a new [TemplateFilterRegistry] and registers all built-in filters.
  ///
  /// Built-in filters include string transformations, number formatting,
  /// conditional filters, list operations, and URL/HTML escaping.
  /// 
  /// - [registerBuiltInFilters] If true, built in filters will be added automatically
  TemplateFilterRegistry([bool registerBuiltInFilters = true]) {
    if (registerBuiltInFilters) {
      _registerBuiltInFilters();
    }
  }

  /// Retrieves a filter by its [name].
  ///
  /// Returns the filter function if found, otherwise `null`.
  ///
  /// ### Example
  /// ```dart
  /// final filter = registry.getFilter('trim');
  /// print(filter?.call('  hello ')); // 'hello'
  /// ```
  TemplateFilter? getFilter(String name) => _filters[name];

  /// Registers a custom filter with the given [name] and [filter] function.
  ///
  /// ### Design Notes
  /// - If a filter with the same name already exists, it will be overwritten.
  /// - The filter function must accept an `Object?` and return an `Object?`.
  ///
  /// ### Example
  /// ```dart
  /// registry.registerFilter('double', (value) {
  ///   if (value is num) return value * 2;
  ///   return value;
  /// });
  /// ```
  void registerFilter(String name, TemplateFilter filter) {
    _filters[name] = filter;
  }

  /// Registers all built-in filters provided by default.
  ///
  /// ### Built-in Filters
  /// **String transformations**
  /// - `uppercase`, `lowercase`, `trim`, `capitalize`, `titlecase`
  ///
  /// **String/List manipulations**
  /// - `length`, `reverse`, `substring`
  ///
  /// **Number formatting**
  /// - `abs`, `round`, `ceil`, `floor`, `toFixed`
  ///
  /// **Conditional**
  /// - `default`, `emptycheck`
  ///
  /// **List operations**
  /// - `first`, `last`, `join`, `size`
  ///
  /// **URL/HTML**
  /// - `urlencode`, `htmlescape`
  void _registerBuiltInFilters() {
    // String transformations
    _filters['uppercase'] = (value) => value?.toString().toUpperCase() ?? '';
    _filters['lowercase'] = (value) => value?.toString().toLowerCase() ?? '';
    _filters['trim'] = (value) => value?.toString().trim() ?? '';

    _filters['capitalize'] = (value) {
      final str = value?.toString() ?? '';
      return str.isEmpty ? '' : str[0].toUpperCase() + str.substring(1);
    };

    _filters['titlecase'] = (value) {
      final str = value?.toString() ?? '';
      return str.split(' ').map((word) {
        return word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1);
      }).join(' ');
    };

    // String/List manipulations
    _filters['length'] = (value) {
      if (value is String) return value.length;
      if (value is List) return value.length;
      if (value is Map) return value.length;
      return 0;
    };

    _filters['reverse'] = (value) {
      if (value is String) return value.split('').reversed.join();
      if (value is List) return value.reversed.toList();
      return value;
    };

    _filters['substring'] = (value) {
      if (value is String && value.length > 10) {
        return '${value.substring(0, 10)}...';
      }
      return value;
    };

    // Number formatting
    _filters['abs'] = (value) => (value is num) ? value.abs() : value;
    _filters['round'] = (value) => (value is double) ? value.round() : value;
    _filters['ceil'] = (value) => (value is double) ? value.ceil() : value;
    _filters['floor'] = (value) => (value is double) ? value.floor() : value;
    _filters['toFixed'] = (value) => (value is double) ? value.toStringAsFixed(2) : value;

    // Conditional filters
    _filters['default'] = (value) => (value == null || (value is String && value.isEmpty)) ? '' : value;
    _filters['emptycheck'] = (value) => (value == null || (value is String && value.isEmpty)) ? 'N/A' : value;

    // List operations
    _filters['first'] = (value) => (value is List && value.isNotEmpty) ? value.first : value;
    _filters['last'] = (value) => (value is List && value.isNotEmpty) ? value.last : value;
    _filters['join'] = (value) => (value is List) ? value.join(', ') : value;
    _filters['size'] = (value) {
      if (value is List) return value.length;
      if (value is Map) return value.length;
      return 0;
    };

    // URL/HTML filters
    _filters['urlencode'] = (value) => Uri.encodeComponent(value?.toString() ?? '');
    _filters['htmlescape'] = (value) => _escapeHtml(value?.toString() ?? '');
  }

  /// Escapes HTML special characters to prevent injection and rendering issues.
  ///
  /// Replaces:
  /// - `&` → `&amp;`
  /// - `<` → `&lt;`
  /// - `>` → `&gt;`
  /// - `"` → `&quot;`
  /// - `'` → `&#x27;`
  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }
}