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

/// 🌿 **Jetleaf Template Engine (JTL)**
///
/// The Jetleaf Template Language (JTL) provides a flexible and
/// efficient template engine for Jetleaf applications. It supports:
/// - template parsing and rendering  
/// - source code management  
/// - filters for content transformation  
/// - caching for optimized template reuse
///
/// This library exposes all core components required for template
/// management and rendering in a Jetleaf-based application.
///
///
/// ## 🔑 Key Concepts
///
/// ### 📄 Source Code Management
/// - `_source_code.dart` / `source_code.dart` — manage template source code,
///   including storage, retrieval, and preprocessing
///
///
/// ### 🏗 Template Parsing & Rendering
/// - `_template.dart` / `template.dart` — core template representation,
///   parsing logic, and rendering engine
///
///
/// ### 🛠 Filter Registry
/// - `filter_registry.dart` — register and manage template filters for
///   transforming template variables during rendering
///
///
/// ### ⚡ Template Caching
/// - `template_cache.dart` — caching layer to store precompiled or
///   frequently used templates for performance optimization
///
///
/// ## 🎯 Intended Usage
///
/// Import this library to enable template-based rendering in Jetleaf:
/// ```dart
/// import 'package:jtl/jtl.dart';
///
/// final template = Template.fromString('Hello, {{name}}!');
/// final output = template.render({'name': 'Jetleaf'});
/// print(output); // Hello, Jetleaf!
/// ```
///
/// Supports dynamic template evaluation, reusable filters, and efficient
/// caching for high-performance applications.
///
///
/// © 2025 Hapnium & Jetleaf Contributors
library;

/// Core source code management and representation
export 'src/_source_code.dart';
export 'src/source_code.dart';

/// Template definitions, parsing, and rendering
export 'src/_template.dart';
export 'src/template.dart';

/// Filter registry for template filters
export 'src/filter_registry.dart';

/// Template caching
export 'src/template_cache.dart';

import 'package:jetleaf_lang/lang.dart';

import 'src/_template.dart';
import 'src/filter_registry.dart';
import 'src/source_code.dart';
import 'src/template.dart';
import 'src/template_cache.dart';

/// {@template jtl}
/// The **core Jetleaf template engine interface**, providing access to
/// template rendering, caching, variable resolution, expression evaluation,
/// filters, and asset sourcing.
///
/// [Jtl] serves as the main entry point for template operations, abstracting
/// the internal components and providing a unified API for rendering templates
/// and accessing the engine’s runtime services.
///
/// ### Responsibilities
/// - Render templates into [SourceCode] objects.
/// - Provide access to a [TemplateCache] for storing and retrieving rendered templates.
/// - Expose a [TemplateRenderer] for low-level rendering operations.
/// - Provide a [TemplateVariableResolver] for resolving template variables.
/// - Provide a [TemplateExpressionEvaluator] for evaluating expressions within templates.
/// - Expose the current [TemplateContext] used during rendering.
/// - Provide a [AssetBuilder] to locate or load template sources.
/// - Provide a [TemplateFilterRegistry] to manage filters applied during template rendering.
///
/// ### Design Notes
/// - Implementations may cache templates or compiled structures for performance.
/// - The interface allows integration with custom resolvers, evaluators, caches,
///   renderers, filters, and asset providers.
/// - Serves as a central hub connecting all Jetleaf template components.
///
/// ### Example Usage
/// ```dart
/// final jtlEngine = MyJtlImplementation();
/// final template = myTemplate;
///
/// // Render template
/// final source = jtlEngine.render(template);
///
/// // Access cache
/// final cached = jtlEngine.getCache().get("homepage");
///
/// // Access variable resolver
/// final title = jtlEngine.getVariableResolver().resolve("title");
///
/// // Access expression evaluator
/// final evaluator = jtlEngine.getExpressionEvaluator();
///
/// // Access the renderer
/// final renderer = jtlEngine.getRenderer();
///
/// // Access asset builder
/// final asset = jtlEngine.getAssetBuilder()("templates/homepage.html");
///
/// // Access filter registry
/// final filter = jtlEngine.getFilterRegistry().getFilter("uppercase");
/// ```
/// {@endtemplate}
abstract interface class Jtl {
  /// Returns the [TemplateCache] used for storing and retrieving rendered templates.
  ///
  /// The cache stores fully rendered templates to improve performance by
  /// avoiding repeated parsing and rendering. Implementations may support
  /// in-memory caching, disk caching, or hybrid strategies. Consumers can
  /// retrieve cached templates or inspect cache contents.
  /// This method provides direct access to the cache for advanced operations.
  TemplateCache getCache();

  /// Renders the given [template] into a [SourceCode] object.
  ///
  /// The renderer processes template placeholders, conditionals, loops, and
  /// filters, producing a fully resolved output. Implementations may leverage
  /// caching, custom variable resolvers, and expression evaluators. All
  /// dynamic attributes from the template context are applied during rendering.
  /// This method returns a [SourceCode] object containing the rendered result.
  /// 
  /// The [built] parameter, is for any built asset that the user wants to render.
  /// This skips future asset building when rendering is called.
  SourceCode render(Template template, [Asset? built]);

  /// Returns the [TemplateRenderer] responsible for rendering templates.
  ///
  /// The renderer handles the detailed parsing and processing of templates,
  /// including placeholder substitution, control structures, and filter
  /// application. Accessing the renderer allows custom rendering pipelines
  /// or inspection of intermediate rendering results.
  TemplateRenderer getRenderer();

  /// Returns the [TemplateVariableResolver] for resolving template variables
  /// to their runtime string representations.
  ///
  /// The variable resolver converts variable names into actual values during
  /// template rendering. Custom resolvers can support computed values,
  /// external data sources, or dynamic formatting. Access to the resolver
  /// allows runtime inspection or modification of variable resolution logic.
  TemplateVariableResolver getVariableResolver();

  /// Returns the [TemplateExpressionEvaluator] for evaluating expressions
  /// within templates.
  ///
  /// Expressions may include logical operations, comparisons, and computed
  /// values. The evaluator ensures that expressions in templates are correctly
  /// executed according to the current context. Access to the evaluator allows
  /// inspection or replacement with custom evaluation logic.
  TemplateExpressionEvaluator getExpressionEvaluator();

  /// Returns the [AssetBuilder] used to locate or load template content.
  ///
  /// The asset builder maps template paths or identifiers to actual template
  /// content. Custom builders allow sourcing templates from files, memory,
  /// network, or other external systems. This method gives access to the
  /// builder for dynamic or programmatic template sourcing.
  AssetBuilder getAssetBuilder();

  /// Returns the [TemplateFilterRegistry] used to manage filters for template variables.
  ///
  /// Filters modify or transform variable values during rendering, such as
  /// formatting, escaping, or custom transformations. Accessing the registry
  /// allows adding, removing, or overriding filters globally for the template
  /// engine. This ensures flexible and extensible template transformations.
  TemplateFilterRegistry getFilterRegistry();
}

/// {@template configurable_jtl}
/// An extension of [Jtl] that provides **full runtime configurability** for
/// the Jetleaf template engine, allowing developers to customize or replace
/// all core components that affect template rendering.
///
/// [ConfigurableJtl] serves as the central hub for controlling the behavior of
/// the template engine. It allows hot-swapping of variable resolution,
/// expression evaluation, caching, rendering strategies, filters, and template
/// asset sourcing, enabling highly dynamic, testable, and extensible workflows.
///
/// ### Responsibilities
/// - Replace the [TemplateVariableResolver] to change how template variables
///   are resolved at runtime.
/// - Replace the [TemplateExpressionEvaluator] to modify expression
///   evaluation logic within templates.
/// - Replace the [TemplateCache] to implement different caching strategies,
///   such as in-memory, disk-based, or hybrid caches.
/// - Replace the [TemplateRenderer] to implement custom rendering pipelines
///   or pre/post-processing steps.
/// - Replace the [TemplateFilterRegistry] to extend, override, or add new filters
///   for template variables.
/// - Replace the [AssetBuilder] to source templates from files,
///   network locations, memory, or any custom system.
///
/// ### Design Notes
/// - Changing these components affects **all subsequent template renders**.
/// - Implementations should ensure **thread-safety** if used in concurrent
///   environments.
/// - Component replacements should remain **consistent with the current
///   TemplateContext**, so that variable resolution and expression evaluation
///   produce predictable results.
/// - Useful for testing, dynamic configuration, multi-environment deployments,
///   and plugin-based extensions.
///
/// ### Example Usage
/// ```dart
/// final configurableJtl = MyConfigurableJtlImplementation();
///
/// // Replace the variable resolver with a custom implementation
/// configurableJtl.setVariableResolver(CustomVariableResolver());
///
/// // Replace the expression evaluator for dynamic computations
/// configurableJtl.setExpressionEvaluator(CustomExpressionEvaluator());
///
/// // Swap out the template cache
/// configurableJtl.setTemplateCache(InMemoryTemplateCache());
///
/// // Use a custom renderer that adds pre/post-processing
/// configurableJtl.setTemplateRenderer(DefaultTemplateRenderer(filterRegistry));
///
/// // Extend filters to support additional string transformations
/// configurableJtl.setFilterRegistry(CustomFilterRegistry());
///
/// // Provide templates from a custom asset source
/// configurableJtl.setAssetBuilder((templateName) => Asset.load(templateName));
///
/// // Render a template using the new configuration
/// final source = configurableJtl.render(template);
/// ```
///
/// ### Method Details
/// - [setVariableResolver]: Replaces the resolver for template variables. All
///   subsequent render calls will use the new resolver.
/// - [setExpressionEvaluator]: Replaces the evaluator for template expressions.
///   This affects all expressions in templates after the replacement.
/// - [setTemplateCache]: Replaces the caching strategy. Previously cached
///   templates may not be available in the new cache.
/// - [setTemplateRenderer]: Replaces the renderer, which may include custom
///   parsing, escaping, or rendering behavior.
/// - [setFilterRegistry]: Replaces or extends the set of filters applied to
///   template variables during rendering.
/// - [setAssetBuilder]: Replaces the source of template content. Useful for
///   dynamic or remote templates.
/// {@endtemplate}
abstract interface class ConfigurableJtl implements Jtl {
  /// Replaces the [TemplateVariableResolver] used by the template engine.
  ///
  /// This resolver is responsible for converting variable names into their
  /// runtime string representations during rendering. By setting a custom
  /// resolver, developers can introduce dynamic computation, external data
  /// sources, or custom formatting rules for template variables.
  /// All subsequent template renders will use this resolver.
  void setVariableResolver(TemplateVariableResolver variableResolver);

  /// Replaces the [TemplateExpressionEvaluator] used by the template engine.
  ///
  /// This evaluator handles the execution of expressions within templates,
  /// such as conditionals or computed values. Providing a custom evaluator
  /// allows support for new operators, complex logic, or integration with
  /// external data sources. Changes take effect immediately for all future
  /// renders.
  void setExpressionEvaluator(TemplateExpressionEvaluator expressionEvaluator);

  /// Replaces the [TemplateCache] used for storing and retrieving rendered templates.
  ///
  /// The cache improves rendering performance by storing previously rendered
  /// templates. By setting a custom cache implementation, developers can
  /// control caching strategies, implement persistence, or integrate memory
  /// and disk-based storage. All subsequent template renders will use this
  /// new cache instance.
  void setTemplateCache(TemplateCache templateCache);

  /// Replaces the [TemplateRenderer] used to render templates into [SourceCode].
  ///
  /// The renderer is responsible for parsing templates, processing placeholders,
  /// conditionals, loops, and applying filters. A custom renderer allows
  /// implementing additional preprocessing, custom escaping, or different
  /// output formats. All future template renders will use the new renderer.
  void setTemplateRenderer(TemplateRenderer templateRenderer);

  /// Replaces the [TemplateFilterRegistry] used for variable filters in templates.
  ///
  /// Filters can transform variables during rendering, such as formatting,
  /// escaping, or applying custom logic. By setting a new filter registry,
  /// developers can add, remove, or override filters for dynamic template
  /// behavior. Changes apply to all subsequent renders.
  void setFilterRegistry(TemplateFilterRegistry filterRegistry);

  /// Replaces the [AssetBuilder] used to locate or load template content.
  ///
  /// The asset builder maps a template name or path to an actual template
  /// source. By setting a custom asset builder, templates can be sourced from
  /// files, memory, network, or any external system. All subsequent renders
  /// will use the new builder to locate templates.
  void setAssetBuilder(AssetBuilder assetBuilder);
}

/// {@template jtl_factory}
/// A **concrete, fully configurable factory** for the Jetleaf template engine,
/// implementing [ConfigurableJtl] and providing a complete, ready-to-use
/// template engine instance.
///
/// [JtlFactory] acts as the central hub of the Jetleaf framework, managing
/// all core components required for template rendering. It is designed to
/// be both **immediately usable with defaults** and **highly configurable**
/// for advanced use cases. Developers can replace any of the core components
/// at runtime or via constructor injection, allowing full control over
/// rendering behavior, caching strategies, variable resolution, expression
/// evaluation, template asset management, and filter application.
///
/// This class is intended for scenarios including:
/// - **Production usage** where default implementations are sufficient.
/// - **Testing or sandboxing**, where components need to be replaced with
///   mocks or stubs.
/// - **Custom template pipelines**, where advanced rendering logic or
///   preprocessing is required.
/// - **Dynamic configuration**, such as runtime switching of caches,
///   renderers, or variable resolvers based on environment or user context.
///
/// ### Features
/// - Provides default implementations for all core components:
///   - [InMemoryTemplateCache] for caching rendered templates
///   - [DefaultAssetPathResource] for template loading
///   - [TemplateFilterRegistry] for variable filters
///   - [DefaultExpressionEvaluator] for evaluating template expressions
///   - [DefaultVariableResolver] for resolving template variables
///   - [DefaultTemplateRenderer] for parsing and rendering templates
/// - Supports **hot-swapping** of components via setter methods
/// - Lazy initialization of components like the renderer for efficient
///   resource usage
/// - Ensures consistent rendering behavior across templates by centralizing
///   context, filters, and evaluators
///
/// ### Design Notes
/// - All core fields are private and accessed through the [ConfigurableJtl]
///   interface methods to enforce encapsulation.
/// - Replacing components at runtime affects all subsequent template renders.
/// - The factory is compatible with all Jetleaf templates, contexts, and
///   rendering extensions.
/// - Provides a single, unified entry point for configuring and rendering
///   templates in a maintainable and testable way.
/// {@endtemplate}
final class JtlFactory implements ConfigurableJtl {
  /// The [TemplateCache] used for storing and retrieving rendered templates.
  ///
  /// This cache improves performance by avoiding repeated parsing and rendering
  /// of templates. The cache can be replaced with custom implementations, such
  /// as in-memory, disk-based, or hybrid strategies, to suit different
  /// performance or persistence requirements.
  TemplateCache _templateCache;

  /// The [AssetBuilder] responsible for locating and loading template content.
  ///
  /// By default, this maps template names to [DefaultAssetPathResource] instances.
  /// It can be replaced to load templates from files, memory, network, or
  /// other external sources. This allows dynamic template sourcing strategies.
  AssetBuilder _assetBuilder;

  /// The [TemplateFilterRegistry] used to manage and apply filters to template variables.
  ///
  /// Filters allow transforming variable values during rendering, such as
  /// formatting, escaping, or applying custom transformations. The registry
  /// can be replaced to add, remove, or override filters globally.
  TemplateFilterRegistry _filterRegistry;

  /// The [TemplateExpressionEvaluator] responsible for evaluating expressions
  /// inside templates.
  ///
  /// Expressions can include logical operations, comparisons, and computed
  /// values. A custom evaluator can implement additional operators, integrate
  /// external data sources, or support complex expression logic.
  TemplateExpressionEvaluator _expressionEvaluator;

  /// The [TemplateVariableResolver] responsible for resolving template
  /// variable names to their runtime string values.
  ///
  /// Custom resolvers can compute values dynamically, fetch them from external
  /// sources, or implement custom formatting rules. This ensures templates
  /// remain flexible and context-aware.
  TemplateVariableResolver _variableResolver;

  /// The [TemplateRenderer] used to render templates into [SourceCode].
  ///
  /// This field may be `null` initially and is lazily initialized if not
  /// provided. The renderer handles parsing templates, applying placeholders,
  /// conditionals, loops, and filters, producing fully rendered output.
  TemplateRenderer? _renderer;

  /// {@macro jtl_factory}
  JtlFactory({
    TemplateCache? templateCache,
    AssetBuilder? assetBuilder,
    TemplateFilterRegistry? filterRegistry,
    TemplateExpressionEvaluator? expressionEvaluator,
    TemplateVariableResolver? variableResolver,
    TemplateRenderer? renderer,
  })  : _templateCache = templateCache ?? InMemoryTemplateCache(),
        _assetBuilder = assetBuilder ?? AssetBuilder(),
        _filterRegistry = filterRegistry ?? TemplateFilterRegistry(),
        _expressionEvaluator = expressionEvaluator ?? DefaultExpressionEvaluator(),
        _variableResolver = variableResolver ?? DefaultVariableResolver(),
        _renderer = renderer;

  @override
  AssetBuilder getAssetBuilder() => _assetBuilder;

  @override
  TemplateCache getCache() => _templateCache;

  @override
  TemplateExpressionEvaluator getExpressionEvaluator() => _expressionEvaluator;

  @override
  TemplateFilterRegistry getFilterRegistry() => _filterRegistry;

  @override
  TemplateRenderer getRenderer() => _renderer ??= DefaultTemplateRenderer(_filterRegistry, _assetBuilder);

  @override
  TemplateVariableResolver getVariableResolver() => _variableResolver;

  @override
  SourceCode render(Template template, [Asset? built]) {
    final cache = getCache().get(template.getLocation());
    if (cache != null) {
      return cache;
    }

    final renderer = getRenderer();
    final resolver = getVariableResolver();
    resolver.setVariables(template.getAttributes());

    final result = renderer.render(template, DefaultTemplateContext(resolver, getExpressionEvaluator()), built);
    getCache().put(template.getLocation(), result);

    return result;
  }

  @override
  void setAssetBuilder(AssetBuilder assetBuilder) {
    _assetBuilder = assetBuilder;
  }

  @override
  void setExpressionEvaluator(TemplateExpressionEvaluator expressionEvaluator) {
    _expressionEvaluator = expressionEvaluator;
  }

  @override
  void setFilterRegistry(TemplateFilterRegistry filterRegistry) {
    _filterRegistry = filterRegistry;
  }

  @override
  void setTemplateCache(TemplateCache templateCache) {
    _templateCache = templateCache;
  }

  @override
  void setTemplateRenderer(TemplateRenderer templateRenderer) {
    _renderer = templateRenderer;
  }

  @override
  void setVariableResolver(TemplateVariableResolver variableResolver) {
    _variableResolver = variableResolver;
  }
}