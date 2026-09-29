// ---------------------------------------------------------------------------
// Jetleaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & Jetleaf Contributors. All rights reserved.
//
// This source file is part of the Jetleaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the Jetleaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------

import 'package:test/test.dart';
import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetson/jetson.dart';
import 'package:jtl/jtl.dart';

import 'package:jetleaf_web/src/annotation/core.dart';
import 'package:jetleaf_web/src/annotation/default_resolver_context.dart';
import 'package:jetleaf_web/src/annotation/request_parameter.dart';
import 'package:jetleaf_web/src/config/content_negotiation_auto_configuration.dart';
import 'package:jetleaf_web/src/config/cors_auto_configuration.dart';
import 'package:jetleaf_web/src/config/csrf_auto_configuration.dart';
import 'package:jetleaf_web/src/config/exception_resolver_auto_configuration.dart';
import 'package:jetleaf_web/src/config/handler_adapter_auto_configuration.dart';
import 'package:jetleaf_web/src/config/http_message_auto_configuration.dart';
import 'package:jetleaf_web/src/config/jetson_auto_configuration.dart';
import 'package:jetleaf_web/src/config/jtl_auto_configuration.dart';
import 'package:jetleaf_web/src/config/method_argument_auto_configuration.dart';
import 'package:jetleaf_web/src/config/return_value_auto_configuration.dart';
import 'package:jetleaf_web/src/config/web_auto_configuration.dart';
import 'package:jetleaf_web/src/config/web_server_auto_configuration.dart';
import 'package:jetleaf_web/src/context/default_server_context.dart';
import 'package:jetleaf_web/src/context/server_context.dart';
import 'package:jetleaf_web/src/converter/common_http_message_converters.dart';
import 'package:jetleaf_web/src/converter/form_http_message_converter.dart';
import 'package:jetleaf_web/src/converter/http_message_converter.dart';
import 'package:jetleaf_web/src/converter/http_message_converters.dart';
import 'package:jetleaf_web/src/converter/jetson_2_http_message_converter.dart';
import 'package:jetleaf_web/src/converter/jetson_2_xml_http_message_converter.dart';
import 'package:jetleaf_web/src/converter/jetson_2_yaml_http_message_converter.dart';
import 'package:jetleaf_web/src/cors/cors_configuration.dart';
import 'package:jetleaf_web/src/cors/cors_filter.dart';
import 'package:jetleaf_web/src/cors/default_cors_configuration_manager.dart';
import 'package:jetleaf_web/src/csrf/csrf_filter.dart';
import 'package:jetleaf_web/src/csrf/csrf_token_repository.dart';
import 'package:jetleaf_web/src/csrf/csrf_token_repository_manager.dart';
import 'package:jetleaf_web/src/csrf/default_csrf_token_repository_manager.dart';
import 'package:jetleaf_web/src/io/io_encoding_decoder.dart';
import 'package:jetleaf_web/src/io/io_multipart_resolver.dart';
import 'package:jetleaf_web/src/path/path_pattern_parser_manager.dart';
import 'package:jetleaf_web/src/rest/client.dart';
import 'package:jetleaf_web/src/server/content_negotiation/accept_header_negotiation_strategy.dart';
import 'package:jetleaf_web/src/server/content_negotiation/content_negotiation_resolver.dart';
import 'package:jetleaf_web/src/server/content_negotiation/content_negotiation_strategy.dart';
import 'package:jetleaf_web/src/server/content_negotiation/default_content_negotiation_resolver.dart';
import 'package:jetleaf_web/src/server/dispatcher/global_server_dispatcher.dart';
import 'package:jetleaf_web/src/server/dispatcher/server_dispatcher.dart';
import 'package:jetleaf_web/src/server/exception_handler/controller_exception_handler.dart';
import 'package:jetleaf_web/src/server/exception_handler/rest_controller_exception_handler.dart';
import 'package:jetleaf_web/src/server/exception_resolver/exception_resolver.dart';
import 'package:jetleaf_web/src/server/exception_resolver/exception_resolver_manager.dart';
import 'package:jetleaf_web/src/server/exception_resolver/html_exception_resolver.dart';
import 'package:jetleaf_web/src/server/exception_resolver/rest_exception_resolver.dart';
import 'package:jetleaf_web/src/server/filter/filter_manager.dart';
import 'package:jetleaf_web/src/server/handler_adapter/annotated_handler_adapter.dart';
import 'package:jetleaf_web/src/server/handler_adapter/framework_handler_adapter.dart';
import 'package:jetleaf_web/src/server/handler_adapter/handler_adapter.dart';
import 'package:jetleaf_web/src/server/handler_adapter/handler_adapter_manager.dart';
import 'package:jetleaf_web/src/server/handler_adapter/route_dsl_handler_adapter.dart';
import 'package:jetleaf_web/src/server/handler_adapter/web_view_handler_adapter.dart';
import 'package:jetleaf_web/src/server/handler_interceptor/handler_interceptor_manager.dart';
import 'package:jetleaf_web/src/server/handler_mapping/route_registry_handler_mapping.dart';
import 'package:jetleaf_web/src/server/method_argument_resolver/annotated_method_argument_resolver.dart';
import 'package:jetleaf_web/src/server/method_argument_resolver/default_method_argument_resolver_manager.dart';
import 'package:jetleaf_web/src/server/method_argument_resolver/framework_method_argument_resolver.dart';
import 'package:jetleaf_web/src/server/method_argument_resolver/method_argument_resolver.dart';
import 'package:jetleaf_web/src/server/multipart/multipart_resolver.dart';
import 'package:jetleaf_web/src/server/return_value_handler/default_return_value_handler_manager.dart';
import 'package:jetleaf_web/src/server/return_value_handler/json_return_value_handler.dart';
import 'package:jetleaf_web/src/server/return_value_handler/page_view_return_value_handler.dart';
import 'package:jetleaf_web/src/server/return_value_handler/redirect_return_value_handler.dart';
import 'package:jetleaf_web/src/server/return_value_handler/response_body_return_value_handler.dart';
import 'package:jetleaf_web/src/server/return_value_handler/return_value_handler.dart';
import 'package:jetleaf_web/src/server/return_value_handler/string_return_value_handler.dart';
import 'package:jetleaf_web/src/server/return_value_handler/view_name_return_value_handler.dart';
import 'package:jetleaf_web/src/server/return_value_handler/void_return_value_handler.dart';
import 'package:jetleaf_web/src/server/return_value_handler/xml_return_value_handler.dart';
import 'package:jetleaf_web/src/server/return_value_handler/yaml_return_value_handler.dart';
import 'package:jetleaf_web/src/utils/encoding.dart';
import 'package:jetleaf_web/src/web/error_pages.dart';
import 'package:jetleaf_web/src/web/web.dart';

// ---------------------------------------------------------------------------
// Test Environment
// ---------------------------------------------------------------------------

class _TestEnvironment implements Environment {
  final Map<String, String> _properties = {};

  void setProperty(String key, String value) => _properties[key] = value;

  @override
  T? getPropertyAs<T>(String name, Class<T> type, [T? defaultValue]) {
    final value = _properties[name];
    if (value == null) return defaultValue;
    if (T == bool) return (value == 'true') as T?;
    if (T == int) return (int.tryParse(value) ?? defaultValue) as T?;
    return defaultValue;
  }

  @override
  bool containsProperty(String name) => _properties.containsKey(name);

  @override
  String? getProperty(String name, [String? defaultValue]) =>
      _properties[name] ?? defaultValue;

  @override
  List<String> getActiveProfiles() => [];

  @override
  List<String> getDefaultProfiles() => [];

  @override
  bool acceptsProfiles(Profiles profiles) => false;

  @override
  bool matchesProfiles(List<String> profileExpressions) => false;

  @override
  String getRequiredProperty(String key) {
    final value = _properties[key];
    if (value != null) return value;
    throw StateError('Property $key not found');
  }

  @override
  T getRequiredPropertyAs<T>(String key, Class<T> targetType) {
    final value = getPropertyAs<T>(key, targetType);
    if (value != null) return value;
    throw StateError('Property $key not found');
  }

  @override
  String resolvePlaceholders(String text) => text;

  String resolvePlaceholdersRecursively(String text) => text;

  @override
  String resolveRequiredPlaceholders(String text) => text;

  @override
  List<String> suggestions(String key) => [];

  @override
  String getPackageName() => 'test';
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

@JetleafTest()
void main() {
  // =========================================================================
  // WebAutoConfiguration
  // =========================================================================
  group('WebAutoConfiguration', () {
    late WebAutoConfiguration config;

    setUp(() {
      config = WebAutoConfiguration();
    });

    group('Constants', () {
      test('WEB_AUTO_CONFIGURATION_POD_NAME is correct', () {
        expect(
          WebAutoConfiguration.WEB_AUTO_CONFIGURATION_POD_NAME,
          equals('jetleaf.web.webAutoConfiguration'),
        );
      });

      test('RESOLVER_CONTEXT_POD_NAME is correct', () {
        expect(
          WebAutoConfiguration.RESOLVER_CONTEXT_POD_NAME,
          equals('jetleaf.web.resolver.resolverContext'),
        );
      });

      test('REST_POD_NAME is correct', () {
        expect(
          WebAutoConfiguration.REST_POD_NAME,
          equals('jetleaf.web.rest.ioRest'),
        );
      });

      test('PATH_PATTERN_PARSER_MANAGER_POD_NAME is correct', () {
        expect(
          WebAutoConfiguration.PATH_PATTERN_PARSER_MANAGER_POD_NAME,
          equals('jetleaf.web.path.pathPatternParserManager'),
        );
      });

      test('HANDLER_INTERCEPTOR_MANAGER_POD_NAME is correct', () {
        expect(
          WebAutoConfiguration.HANDLER_INTERCEPTOR_MANAGER_POD_NAME,
          equals('jetleaf.web.handler.interceptorManager'),
        );
      });

      test('HANDLER_ADAPTER_MANAGER_POD_NAME is correct', () {
        expect(
          WebAutoConfiguration.HANDLER_ADAPTER_MANAGER_POD_NAME,
          equals('jetleaf.web.handler.adapterManager'),
        );
      });

      test('EXCEPTION_RESOLVER_MANAGER_POD_NAME is correct', () {
        expect(
          WebAutoConfiguration.EXCEPTION_RESOLVER_MANAGER_POD_NAME,
          equals('jetleaf.web.exception.resolverManager'),
        );
      });

      test('FILTER_MANAGER_POD_NAME is correct', () {
        expect(
          WebAutoConfiguration.FILTER_MANAGER_POD_NAME,
          equals('jetleaf.web.filter.filterManager'),
        );
      });

      test('ROUTE_REGISTRY_HANDLER_MAPPING_POD_NAME is correct', () {
        expect(
          WebAutoConfiguration.ROUTE_REGISTRY_HANDLER_MAPPING_POD_NAME,
          equals('jetleaf.web.route.registryHandlerMapping'),
        );
      });
    });

    group('pathPatternParserManager', () {
      test('returns PathPatternParserManager instance', () {
        final manager = config.pathPatternParserManager();
        expect(manager, isA<PathPatternParserManager>());
      });

      test('returns a new instance each time', () {
        final a = config.pathPatternParserManager();
        final b = config.pathPatternParserManager();
        expect(identical(a, b), isFalse);
      });
    });

    group('ioRestClient', () {
      test('returns RestClient instance', () {
        final decoder = IoEncodingDecoder();
        final client = config.ioRestClient(decoder);
        expect(client, isA<RestClient>());
      });
    });

    group('resolverContext', () {
      test('returns ResolverContext instance', () {
        final converters = HttpMessageConverters();
        final ctx = config.resolverContext(converters);
        expect(ctx, isA<ResolverContext>());
      });
    });

    group('handlerInterceptorManager', () {
      test('returns HandlerInterceptorManager instance', () {
        final manager = config.handlerInterceptorManager();
        expect(manager, isA<HandlerInterceptorManager>());
      });
    });

    group('handlerAdapterManager', () {
      test('returns HandlerAdapterManager instance', () {
        final manager = config.handlerAdapterManager();
        expect(manager, isA<HandlerAdapterManager>());
      });
    });

    group('exceptionResolverManager', () {
      test('returns ExceptionResolverManager instance', () {
        final resolver = DefaultContentNegotiationResolver();
        final manager = config.exceptionResolverManager(resolver);
        expect(manager, isA<ExceptionResolverManager>());
      });
    });

    group('filterManager', () {
      test('returns FilterManager instance', () {
        final manager = config.filterManager();
        expect(manager, isA<FilterManager>());
      });
    });

    group('registryHandlerMapping', () {
      test('returns RouteRegistryHandlerMapping instance', () {
        final parser = PathPatternParserManager();
        final mapping = config.registryHandlerMapping(parser);
        expect(mapping, isA<RouteRegistryHandlerMapping>());
      });
    });
  });

  // =========================================================================
  // AnnotatedTypeFilter
  // =========================================================================
  group('AnnotatedTypeFilter', () {
    test('can be instantiated', () {
      final filter = AnnotatedTypeFilter<Controller>();
      expect(filter, isA<TypeFilter>());
    });
  });

  // =========================================================================
  // WebServerAutoConfiguration
  // =========================================================================
  group('WebServerAutoConfiguration', () {
    late WebServerAutoConfiguration config;

    setUp(() {
      config = WebServerAutoConfiguration();
    });

    group('Constants', () {
      test('NAME is correct', () {
        expect(
          WebServerAutoConfiguration.NAME,
          equals('jetleaf.web.webServerAutoConfiguration'),
        );
      });

      test('IO_ENCODING_DECODER_POD_NAME is correct', () {
        expect(
          WebServerAutoConfiguration.IO_ENCODING_DECODER_POD_NAME,
          equals('jetleaf.web.encoding.ioEncodingDecoder'),
        );
      });

      test('GLOBAL_SERVER_DISPATCHER_POD_NAME is correct', () {
        expect(
          WebServerAutoConfiguration.GLOBAL_SERVER_DISPATCHER_POD_NAME,
          equals('jetleaf.web.dispatcher.globalServerDispatcher'),
        );
      });

      test('IO_MULTIPART_RESOLVER_POD_NAME is correct', () {
        expect(
          WebServerAutoConfiguration.IO_MULTIPART_RESOLVER_POD_NAME,
          equals('jetleaf.web.multipart.resolver.ioMultipartResolver'),
        );
      });

      test('WEB_SERVER_FACTORY_POD_NAME is correct', () {
        expect(
          WebServerAutoConfiguration.WEB_SERVER_FACTORY_POD_NAME,
          equals('jetleaf.web.server.ioWebServerFactory'),
        );
      });

      test('SERVER_CONTEXT_POD_NAME is correct', () {
        expect(
          WebServerAutoConfiguration.SERVER_CONTEXT_POD_NAME,
          equals('jetleaf.web.context.ioServerContext'),
        );
      });
    });

    group('jtlEncodingDecoder', () {
      test('returns EncodingDecoder instance', () {
        final decoder = config.jtlEncodingDecoder();
        expect(decoder, isA<EncodingDecoder>());
      });
    });

    group('globalServerDispatcher', () {
      test('returns ServerDispatcher instance', () {
        final multipartResolver = IoMultipartResolver(IoEncodingDecoder());
        final serverContext = IoServerContext();
        final parser = PathPatternParserManager();
        final interceptor = HandlerInterceptorManager();
        final adapterManager = HandlerAdapterManager();
        final exceptionManager = ExceptionResolverManager(
          DefaultContentNegotiationResolver(),
        );
        final filterManager = FilterManager();
        final routeMapping = RouteRegistryHandlerMapping(parser);

        final dispatcher = config.globalServerDispatcher(
          multipartResolver,
          serverContext,
          parser,
          interceptor,
          adapterManager,
          exceptionManager,
          filterManager,
          routeMapping,
        );

        expect(dispatcher, isA<ServerDispatcher>());
        expect(dispatcher, isA<GlobalServerDispatcher>());
      });
    });

    group('ioMultipartResolver', () {
      test('returns MultipartResolver instance', () {
        final decoder = IoEncodingDecoder();
        final resolver = config.ioMultipartResolver(decoder);
        expect(resolver, isA<MultipartResolver>());
      });
    });

    group('ioWebServerFactory', () {
      test('returns WebServerFactory instance', () {
        final multipartResolver = IoMultipartResolver(IoEncodingDecoder());
        final serverContext = IoServerContext();
        final parser = PathPatternParserManager();
        final interceptor = HandlerInterceptorManager();
        final adapterManager = HandlerAdapterManager();
        final exceptionManager = ExceptionResolverManager(
          DefaultContentNegotiationResolver(),
        );
        final filterManager = FilterManager();
        final routeMapping = RouteRegistryHandlerMapping(parser);

        final dispatcher = config.globalServerDispatcher(
          multipartResolver,
          serverContext,
          parser,
          interceptor,
          adapterManager,
          exceptionManager,
          filterManager,
          routeMapping,
        );

        final factory = config.ioWebServerFactory(dispatcher, null);
        expect(factory, isA<WebServerFactory>());
      });
    });

    group('ioServerContext', () {
      test('returns ServerContext instance', () {
        final ctx = config.ioServerContext();
        expect(ctx, isA<ServerContext>());
      });
    });
  });

  // =========================================================================
  // CorsAutoConfiguration
  // =========================================================================
  group('CorsAutoConfiguration', () {
    late CorsAutoConfiguration config;

    setUp(() {
      config = CorsAutoConfiguration();
    });

    group('Constants', () {
      test('NAME is correct', () {
        expect(
          CorsAutoConfiguration.NAME,
          equals('jetleaf.cors.corsAutoConfiguration'),
        );
      });

      test('CORS_MANAGER is correct', () {
        expect(
          CorsAutoConfiguration.CORS_MANAGER,
          equals('jetleaf.cors.corsConfigurationManager'),
        );
      });

      test('CORS_FILTER is correct', () {
        expect(
          CorsAutoConfiguration.CORS_FILTER,
          equals('jetleaf.cors.corsFilter'),
        );
      });
    });

    group('manager', () {
      test('returns CorsConfigurationManager instance', () {
        final parser = PathPatternParserManager();
        final manager = config.manager(parser);
        expect(manager, isA<CorsConfigurationManager>());
      });

      test('returns DefaultCorsConfigurationManager', () {
        final parser = PathPatternParserManager();
        final manager = config.manager(parser);
        expect(manager, isA<DefaultCorsConfigurationManager>());
      });
    });

    group('corsFilter', () {
      test('returns CorsFilter instance', () {
        final parser = PathPatternParserManager();
        final manager = config.manager(parser);
        final filter = config.corsFilter(manager);
        expect(filter, isA<CorsFilter>());
      });

      test('filter depends on CorsConfigurationManager', () {
        final parser = PathPatternParserManager();
        final manager = config.manager(parser);
        final filter = config.corsFilter(manager);
        expect(filter.getOrder(), isNotNull);
      });
    });
  });

  // =========================================================================
  // CsrfAutoConfiguration
  // =========================================================================
  group('CsrfAutoConfiguration', () {
    late CsrfAutoConfiguration config;

    setUp(() {
      config = const CsrfAutoConfiguration();
    });

    group('Constants', () {
      test('NAME is correct', () {
        expect(
          CsrfAutoConfiguration.NAME,
          equals('jetleaf.web.csrf.csrfAutoConfiguration'),
        );
      });

      test('TOKEN_REPOSITORY_MANAGER_POD is correct', () {
        expect(
          CsrfAutoConfiguration.TOKEN_REPOSITORY_MANAGER_POD,
          equals('jetleaf.web.csrf.tokenRepositoryManager'),
        );
      });

      test('TOKEN_REPOSITORY_POD is correct', () {
        expect(
          CsrfAutoConfiguration.TOKEN_REPOSITORY_POD,
          equals('jetleaf.web.csrf.tokenRepository'),
        );
      });

      test('CSRF_FILTER_POD is correct', () {
        expect(
          CsrfAutoConfiguration.CSRF_FILTER_POD,
          equals('jetleaf.web.csrf.csrfFilter'),
        );
      });
    });

    group('csrfTokenRepositoryManager', () {
      test('returns CsrfTokenRepositoryManager instance', () {
        final manager = config.csrfTokenRepositoryManager();
        expect(manager, isA<CsrfTokenRepositoryManager>());
      });

      test('returns DefaultCsrfTokenRepositoryManager', () {
        final manager = config.csrfTokenRepositoryManager();
        expect(manager, isA<DefaultCsrfTokenRepositoryManager>());
      });
    });

    group('csrfTokenRepository', () {
      test('returns CsrfTokenRepository instance', () {
        final repository = config.csrfTokenRepository();
        expect(repository, isA<CsrfTokenRepository>());
      });

      test('returns RequestAttributeCsrfTokenRepository', () {
        final repository = config.csrfTokenRepository();
        expect(repository, isA<RequestAttributeCsrfTokenRepository>());
      });
    });

    group('csrfFilter', () {
      test('returns CsrfFilter instance', () {
        final manager = config.csrfTokenRepositoryManager();
        final filter = config.csrfFilter(manager);
        expect(filter, isA<CsrfFilter>());
      });

      test('filter depends on CsrfTokenRepositoryManager', () {
        final manager = config.csrfTokenRepositoryManager();
        final filter = config.csrfFilter(manager);
        expect(filter.getOrder(), isNotNull);
      });
    });
  });

  // =========================================================================
  // ContentNegotiationAutoConfiguration
  // =========================================================================
  group('ContentNegotiationAutoConfiguration', () {
    late ContentNegotiationAutoConfiguration config;

    setUp(() {
      config = ContentNegotiationAutoConfiguration();
    });

    group('Constants', () {
      test('CONFIG_POD_NAME is correct', () {
        expect(
          ContentNegotiationAutoConfiguration.CONFIG_POD_NAME,
          equals('jetleaf.web.contentNegotiationAutoConfiguration'),
        );
      });

      test('CONTENT_NEGOTIATION_STRATEGY_POD_NAME is correct', () {
        expect(
          ContentNegotiationAutoConfiguration.CONTENT_NEGOTIATION_STRATEGY_POD_NAME,
          equals('jetleaf.web.contentNegotiationStrategy'),
        );
      });

      test('CONTENT_NEGOTIATION_RESOLVER_POD_NAME is correct', () {
        expect(
          ContentNegotiationAutoConfiguration.CONTENT_NEGOTIATION_RESOLVER_POD_NAME,
          equals('jetleaf.web.contentNegotiationResolver'),
        );
      });
    });

    group('acceptHeaderNegotiationStrategy', () {
      test('returns ContentNegotiationStrategy instance', () {
        final strategy = config.acceptHeaderNegotiationStrategy();
        expect(strategy, isA<ContentNegotiationStrategy>());
      });

      test('returns AcceptHeaderNegotiationStrategy', () {
        final strategy = config.acceptHeaderNegotiationStrategy();
        expect(strategy, isA<AcceptHeaderNegotiationStrategy>());
      });
    });

    group('defaultContentNegotiationResolver', () {
      test('returns ContentNegotiationResolver instance', () {
        final resolver = config.defaultContentNegotiationResolver();
        expect(resolver, isA<ContentNegotiationResolver>());
      });

      test('returns DefaultContentNegotiationResolver', () {
        final resolver = config.defaultContentNegotiationResolver();
        expect(resolver, isA<DefaultContentNegotiationResolver>());
      });
    });
  });

  // =========================================================================
  // ExceptionResolverAutoConfiguration
  // =========================================================================
  group('ExceptionResolverAutoConfiguration', () {
    late ExceptionResolverAutoConfiguration config;

    setUp(() {
      config = ExceptionResolverAutoConfiguration();
    });

    group('Constants', () {
      test('NAME is correct', () {
        expect(
          ExceptionResolverAutoConfiguration.NAME,
          equals('jetleaf.web.exceptionResolverAutoConfiguration'),
        );
      });

      test('HTML_EXCEPTION_RESOLVER_POD_NAME is correct', () {
        expect(
          ExceptionResolverAutoConfiguration.HTML_EXCEPTION_RESOLVER_POD_NAME,
          equals('jetleaf.web.resolver.htmlExceptionResolver'),
        );
      });

      test('REST_EXCEPTION_RESOLVER_POD_NAME is correct', () {
        expect(
          ExceptionResolverAutoConfiguration.REST_EXCEPTION_RESOLVER_POD_NAME,
          equals('jetleaf.web.resolver.restExceptionResolver'),
        );
      });

      test('DEFAULT_REST_CONTROLLER_EXCEPTION_HANDLER_POD_NAME is correct', () {
        expect(
          ExceptionResolverAutoConfiguration.DEFAULT_REST_CONTROLLER_EXCEPTION_HANDLER_POD_NAME,
          equals('jetleaf.web.defaultRestControllerExceptionHandler'),
        );
      });

      test('DEFAULT_CONTROLLER_EXCEPTION_HANDLER_POD_NAME is correct', () {
        expect(
          ExceptionResolverAutoConfiguration.DEFAULT_CONTROLLER_EXCEPTION_HANDLER_POD_NAME,
          equals('jetleaf.web.defaultControllerExceptionHandler'),
        );
      });

      test('ERROR_PAGES_POD_NAME is correct', () {
        expect(
          ExceptionResolverAutoConfiguration.ERROR_PAGES_POD_NAME,
          equals('jetleaf.web.errorPages'),
        );
      });
    });

    group('errorPages', () {
      test('returns ErrorPages instance', () {
        final pages = config.errorPages();
        expect(pages, isA<ErrorPages>());
      });
    });

    group('restControllerAdviceExceptionResolver', () {
      test('returns ExceptionResolver instance', () {
        final methodResolver = DefaultMethodArgumentResolverManager();
        final returnValueHandler = DefaultReturnValueHandlerManager(
          DefaultContentNegotiationResolver(),
        );
        final resolver = config.restControllerAdviceExceptionResolver(
          methodResolver,
          returnValueHandler,
        );
        expect(resolver, isA<ExceptionResolver>());
      });

      test('returns RestExceptionResolver', () {
        final methodResolver = DefaultMethodArgumentResolverManager();
        final returnValueHandler = DefaultReturnValueHandlerManager(
          DefaultContentNegotiationResolver(),
        );
        final resolver = config.restControllerAdviceExceptionResolver(
          methodResolver,
          returnValueHandler,
        );
        expect(resolver, isA<RestExceptionResolver>());
      });
    });

    group('controllerAdviceExceptionResolver', () {
      test('returns ExceptionResolver instance', () {
        final methodResolver = DefaultMethodArgumentResolverManager();
        final returnValueHandler = DefaultReturnValueHandlerManager(
          DefaultContentNegotiationResolver(),
        );
        final pages = config.errorPages();
        final resolver = config.controllerAdviceExceptionResolver(
          methodResolver,
          returnValueHandler,
          pages,
        );
        expect(resolver, isA<ExceptionResolver>());
      });

      test('returns HtmlExceptionResolver', () {
        final methodResolver = DefaultMethodArgumentResolverManager();
        final returnValueHandler = DefaultReturnValueHandlerManager(
          DefaultContentNegotiationResolver(),
        );
        final pages = config.errorPages();
        final resolver = config.controllerAdviceExceptionResolver(
          methodResolver,
          returnValueHandler,
          pages,
        );
        expect(resolver, isA<HtmlExceptionResolver>());
      });
    });

    group('restControllerAdviceExceptionHandler', () {
      test('returns RestControllerExceptionHandler instance', () {
        final handler = config.restControllerAdviceExceptionHandler();
        expect(handler, isA<RestControllerExceptionHandler>());
      });
    });

    group('controllerAdviceExceptionHandler', () {
      test('returns ControllerExceptionHandler instance', () {
        final handler = config.controllerAdviceExceptionHandler();
        expect(handler, isA<ControllerExceptionHandler>());
      });
    });
  });

  // =========================================================================
  // HandlerAdapterAutoConfiguration
  // =========================================================================
  group('HandlerAdapterAutoConfiguration', () {
    late HandlerAdapterAutoConfiguration config;

    setUp(() {
      config = HandlerAdapterAutoConfiguration();
    });

    group('Constants', () {
      test('NAME is correct', () {
        expect(
          HandlerAdapterAutoConfiguration.NAME,
          equals('jetleaf.web.handlerAdapterAutoConfiguration'),
        );
      });

      test('ANNOTATED_HANDLER_ADAPTER_POD_NAME is correct', () {
        expect(
          HandlerAdapterAutoConfiguration.ANNOTATED_HANDLER_ADAPTER_POD_NAME,
          equals('jetleaf.web.adapter.annotatedHandlerAdapter'),
        );
      });

      test('WEB_VIEW_HANDLER_ADAPTER_POD_NAME is correct', () {
        expect(
          HandlerAdapterAutoConfiguration.WEB_VIEW_HANDLER_ADAPTER_POD_NAME,
          equals('jetleaf.web.adapter.webViewHandlerAdapter'),
        );
      });

      test('ROUTE_DSL_HANDLER_ADAPTER_POD_NAME is correct', () {
        expect(
          HandlerAdapterAutoConfiguration.ROUTE_DSL_HANDLER_ADAPTER_POD_NAME,
          equals('jetleaf.web.adapter.routeDslHandlerAdapter'),
        );
      });

      test('FRAMEWORK_HANDLER_ADAPTER_POD_NAME is correct', () {
        expect(
          HandlerAdapterAutoConfiguration.FRAMEWORK_HANDLER_ADAPTER_POD_NAME,
          equals('jetleaf.web.adapter.frameworkHandlerAdapter'),
        );
      });
    });

    group('annotatedHandlerAdapter', () {
      test('returns HandlerAdapter instance', () {
        final methodResolver = DefaultMethodArgumentResolverManager();
        final returnValueHandler = DefaultReturnValueHandlerManager(
          DefaultContentNegotiationResolver(),
        );
        final adapter = config.annotatedHandlerAdapter(
          methodResolver,
          returnValueHandler,
        );
        expect(adapter, isA<HandlerAdapter>());
      });

      test('returns AnnotatedHandlerAdapter', () {
        final methodResolver = DefaultMethodArgumentResolverManager();
        final returnValueHandler = DefaultReturnValueHandlerManager(
          DefaultContentNegotiationResolver(),
        );
        final adapter = config.annotatedHandlerAdapter(
          methodResolver,
          returnValueHandler,
        );
        expect(adapter, isA<AnnotatedHandlerAdapter>());
      });
    });

    group('routeDslHandlerAdapter', () {
      test('returns HandlerAdapter instance', () {
        final methodResolver = DefaultMethodArgumentResolverManager();
        final returnValueHandler = DefaultReturnValueHandlerManager(
          DefaultContentNegotiationResolver(),
        );
        final adapter = config.routeDslHandlerAdapter(
          methodResolver,
          returnValueHandler,
        );
        expect(adapter, isA<HandlerAdapter>());
      });

      test('returns RouteDslHandlerAdapter', () {
        final methodResolver = DefaultMethodArgumentResolverManager();
        final returnValueHandler = DefaultReturnValueHandlerManager(
          DefaultContentNegotiationResolver(),
        );
        final adapter = config.routeDslHandlerAdapter(
          methodResolver,
          returnValueHandler,
        );
        expect(adapter, isA<RouteDslHandlerAdapter>());
      });
    });

    group('frameworkHandlerAdapter', () {
      test('returns HandlerAdapter instance', () {
        final methodResolver = DefaultMethodArgumentResolverManager();
        final returnValueHandler = DefaultReturnValueHandlerManager(
          DefaultContentNegotiationResolver(),
        );
        final adapter = config.frameworkHandlerAdapter(
          methodResolver,
          returnValueHandler,
        );
        expect(adapter, isA<HandlerAdapter>());
      });

      test('returns FrameworkHandlerAdapter', () {
        final methodResolver = DefaultMethodArgumentResolverManager();
        final returnValueHandler = DefaultReturnValueHandlerManager(
          DefaultContentNegotiationResolver(),
        );
        final adapter = config.frameworkHandlerAdapter(
          methodResolver,
          returnValueHandler,
        );
        expect(adapter, isA<FrameworkHandlerAdapter>());
      });
    });

    group('webViewHandlerAdapter', () {
      test('returns HandlerAdapter instance', () {
        final methodResolver = DefaultMethodArgumentResolverManager();
        final returnValueHandler = DefaultReturnValueHandlerManager(
          DefaultContentNegotiationResolver(),
        );
        final adapter = config.webViewHandlerAdapter(
          methodResolver,
          returnValueHandler,
        );
        expect(adapter, isA<HandlerAdapter>());
      });

      test('returns WebViewHandlerAdapter', () {
        final methodResolver = DefaultMethodArgumentResolverManager();
        final returnValueHandler = DefaultReturnValueHandlerManager(
          DefaultContentNegotiationResolver(),
        );
        final adapter = config.webViewHandlerAdapter(
          methodResolver,
          returnValueHandler,
        );
        expect(adapter, isA<WebViewHandlerAdapter>());
      });
    });
  });

  // =========================================================================
  // HttpMessageAutoConfiguration
  // =========================================================================
  group('HttpMessageAutoConfiguration', () {
    late HttpMessageAutoConfiguration config;

    setUp(() {
      config = HttpMessageAutoConfiguration();
    });

    group('Constants', () {
      test('NAME is correct', () {
        expect(
          HttpMessageAutoConfiguration.NAME,
          equals('jetleaf.web.HttpMessageAutoConfiguration'),
        );
      });

      test('HTTP_MESSAGE_CONVERTERS_POD_NAME is correct', () {
        expect(
          HttpMessageAutoConfiguration.HTTP_MESSAGE_CONVERTERS_POD_NAME,
          equals('jetleaf.web.http.httpMessageConverters'),
        );
      });

      test('JETSON_2_HTTP_MESSAGE_CONVERTER_POD_NAME is correct', () {
        expect(
          HttpMessageAutoConfiguration.JETSON_2_HTTP_MESSAGE_CONVERTER_POD_NAME,
          equals('jetleaf.web.http.jetson2HttpMessageConverter'),
        );
      });

      test('STRING_HTTP_MESSAGE_CONVERTER_POD_NAME is correct', () {
        expect(
          HttpMessageAutoConfiguration.STRING_HTTP_MESSAGE_CONVERTER_POD_NAME,
          equals('jetleaf.web.http.stringHttpMessageConverter'),
        );
      });

      test('BYTE_ARRAY_HTTP_MESSAGE_CONVERTER_POD_NAME is correct', () {
        expect(
          HttpMessageAutoConfiguration.BYTE_ARRAY_HTTP_MESSAGE_CONVERTER_POD_NAME,
          equals('jetleaf.web.http.byteArrayHttpMessageConverter'),
        );
      });

      test('JETSON_2_XML_HTTP_MESSAGE_CONVERTER_POD_NAME is correct', () {
        expect(
          HttpMessageAutoConfiguration.JETSON_2_XML_HTTP_MESSAGE_CONVERTER_POD_NAME,
          equals('jetleaf.web.http.jetson2XmlHttpMessageConverter'),
        );
      });

      test('JETSON_2_YAML_HTTP_MESSAGE_CONVERTER_POD_NAME is correct', () {
        expect(
          HttpMessageAutoConfiguration.JETSON_2_YAML_HTTP_MESSAGE_CONVERTER_POD_NAME,
          equals('jetleaf.web.http.jetson2YamlHttpMessageConverter'),
        );
      });

      test('FORM_HTTP_MESSAGE_CONVERTER_POD_NAME is correct', () {
        expect(
          HttpMessageAutoConfiguration.FORM_HTTP_MESSAGE_CONVERTER_POD_NAME,
          equals('jetleaf.web.http.formHttpMessageConverter'),
        );
      });
    });

    group('httpMessageConverters', () {
      test('returns HttpMessageConverters instance', () {
        final converters = config.httpMessageConverters();
        expect(converters, isA<HttpMessageConverters>());
      });

      test('returns empty converters registry', () {
        final converters = config.httpMessageConverters();
        expect(converters.getMessageConverters(), isEmpty);
      });
    });

    group('stringHttpMessageConverter', () {
      test('returns HttpMessageConverter instance', () {
        final converter = config.stringHttpMessageConverter();
        expect(converter, isA<HttpMessageConverter>());
      });

      test('returns StringHttpMessageConverter', () {
        final converter = config.stringHttpMessageConverter();
        expect(converter, isA<StringHttpMessageConverter>());
      });
    });

    group('byteArrayHttpMessageConverter', () {
      test('returns HttpMessageConverter instance', () {
        final converter = config.byteArrayHttpMessageConverter();
        expect(converter, isA<HttpMessageConverter>());
      });

      test('returns ByteArrayHttpMessageConverter', () {
        final converter = config.byteArrayHttpMessageConverter();
        expect(converter, isA<ByteArrayHttpMessageConverter>());
      });
    });

    group('jetson2HttpMessageConverter', () {
      test('returns HttpMessageConverter instance', () {
        final mapper = ObjectMapper();
        final converter = config.jetson2HttpMessageConverter(mapper);
        expect(converter, isA<HttpMessageConverter>());
      });

      test('returns Jetson2HttpMessageConverter', () {
        final mapper = ObjectMapper();
        final converter = config.jetson2HttpMessageConverter(mapper);
        expect(converter, isA<Jetson2HttpMessageConverter>());
      });
    });

    group('jetson2XmlHttpMessageConverter', () {
      test('returns HttpMessageConverter instance', () {
        final mapper = ObjectMapper();
        final converter = config.jetson2XmlHttpMessageConverter(mapper);
        expect(converter, isA<HttpMessageConverter>());
      });

      test('returns Jetson2XmlHttpMessageConverter', () {
        final mapper = ObjectMapper();
        final converter = config.jetson2XmlHttpMessageConverter(mapper);
        expect(converter, isA<Jetson2XmlHttpMessageConverter>());
      });
    });

    group('jetson2YamlHttpMessageConverter', () {
      test('returns HttpMessageConverter instance', () {
        final mapper = ObjectMapper();
        final converter = config.jetson2YamlHttpMessageConverter(mapper);
        expect(converter, isA<HttpMessageConverter>());
      });

      test('returns Jetson2YamlHttpMessageConverter', () {
        final mapper = ObjectMapper();
        final converter = config.jetson2YamlHttpMessageConverter(mapper);
        expect(converter, isA<Jetson2YamlHttpMessageConverter>());
      });
    });

    group('formHttpMessageConverter', () {
      test('returns HttpMessageConverter instance', () {
        final converter = config.formHttpMessageConverter();
        expect(converter, isA<HttpMessageConverter>());
      });

      test('returns FormHttpMessageConverter', () {
        final converter = config.formHttpMessageConverter();
        expect(converter, isA<FormHttpMessageConverter>());
      });
    });
  });

  // =========================================================================
  // MethodArgumentAutoConfiguration
  // =========================================================================
  group('MethodArgumentAutoConfiguration', () {
    late MethodArgumentAutoConfiguration config;

    setUp(() {
      config = MethodArgumentAutoConfiguration();
    });

    group('Constants', () {
      test('NAME is correct', () {
        expect(
          MethodArgumentAutoConfiguration.NAME,
          equals('jetleaf.web.methodArgumentAutoConfiguration'),
        );
      });

      test('ANNOTATED_METHOD_ARGUMENT_RESOLVER_POD_NAME is correct', () {
        expect(
          MethodArgumentAutoConfiguration.ANNOTATED_METHOD_ARGUMENT_RESOLVER_POD_NAME,
          equals('jetleaf.web.resolver.annotatedMethodArgumentResolver'),
        );
      });

      test('FRAMEWORK_METHOD_ARGUMENT_RESOLVER_POD_NAME is correct', () {
        expect(
          MethodArgumentAutoConfiguration.FRAMEWORK_METHOD_ARGUMENT_RESOLVER_POD_NAME,
          equals('jetleaf.web.resolver.frameworkMethodArgumentResolver'),
        );
      });

      test('DEFAULT_METHOD_ARGUMENT_RESOLVER_MANAGER_POD_NAME is correct', () {
        expect(
          MethodArgumentAutoConfiguration.DEFAULT_METHOD_ARGUMENT_RESOLVER_MANAGER_POD_NAME,
          equals('jetleaf.web.handler.defaultMethodArgumentResolverManager'),
        );
      });
    });

    group('defaultMethodArgumentResolver', () {
      test('returns MethodArgumentResolverManager instance', () {
        final manager = config.defaultMethodArgumentResolver();
        expect(manager, isA<MethodArgumentResolverManager>());
      });

      test('returns DefaultMethodArgumentResolverManager', () {
        final manager = config.defaultMethodArgumentResolver();
        expect(manager, isA<DefaultMethodArgumentResolverManager>());
      });
    });

    group('annotatedMethodArgumentResolver', () {
      test('returns MethodArgumentResolver instance', () {
        final converters = HttpMessageConverters();
        final ctx = DefaultResolverContext(converters);
        final resolver = config.annotatedMethodArgumentResolver(ctx);
        expect(resolver, isA<MethodArgumentResolver>());
      });

      test('returns AnnotatedMethodArgumentResolver', () {
        final converters = HttpMessageConverters();
        final ctx = DefaultResolverContext(converters);
        final resolver = config.annotatedMethodArgumentResolver(ctx);
        expect(resolver, isA<AnnotatedMethodArgumentResolver>());
      });
    });

    group('frameworkMethodArgumentResolver', () {
      test('returns MethodArgumentResolver instance', () {
        final resolver = config.frameworkMethodArgumentResolver();
        expect(resolver, isA<MethodArgumentResolver>());
      });

      test('returns FrameworkMethodArgumentResolver', () {
        final resolver = config.frameworkMethodArgumentResolver();
        expect(resolver, isA<FrameworkMethodArgumentResolver>());
      });
    });
  });

  // =========================================================================
  // ReturnValueAutoConfiguration
  // =========================================================================
  group('ReturnValueAutoConfiguration', () {
    late ReturnValueAutoConfiguration config;

    setUp(() {
      config = ReturnValueAutoConfiguration();
    });

    group('Constants', () {
      test('NAME is correct', () {
        expect(
          ReturnValueAutoConfiguration.NAME,
          equals('jetleaf.web.returnValueAutoConfiguration'),
        );
      });

      test('VIEW_NAME_RETURN_VALUE_HANDLER_POD_NAME is correct', () {
        expect(
          ReturnValueAutoConfiguration.VIEW_NAME_RETURN_VALUE_HANDLER_POD_NAME,
          equals('jetleaf.web.handler.viewNameReturnValueHandler'),
        );
      });

      test('PAGE_VIEW_RETURN_VALUE_HANDLER_POD_NAME is correct', () {
        expect(
          ReturnValueAutoConfiguration.PAGE_VIEW_RETURN_VALUE_HANDLER_POD_NAME,
          equals('jetleaf.web.handler.pageViewReturnValueHandler'),
        );
      });

      test('REDIRECT_RETURN_VALUE_HANDLER_POD_NAME is correct', () {
        expect(
          ReturnValueAutoConfiguration.REDIRECT_RETURN_VALUE_HANDLER_POD_NAME,
          equals('jetleaf.web.handler.redirectReturnValueHandler'),
        );
      });

      test('RESPONSE_BODY_RETURN_VALUE_HANDLER_POD_NAME is correct', () {
        expect(
          ReturnValueAutoConfiguration.RESPONSE_BODY_RETURN_VALUE_HANDLER_POD_NAME,
          equals('jetleaf.web.handler.responseBodyReturnValueHandler'),
        );
      });

      test('STRING_RETURN_VALUE_HANDLER_POD_NAME is correct', () {
        expect(
          ReturnValueAutoConfiguration.STRING_RETURN_VALUE_HANDLER_POD_NAME,
          equals('jetleaf.web.handler.stringReturnValueHandler'),
        );
      });

      test('VOID_RETURN_VALUE_HANDLER_POD_NAME is correct', () {
        expect(
          ReturnValueAutoConfiguration.VOID_RETURN_VALUE_HANDLER_POD_NAME,
          equals('jetleaf.web.handler.voidReturnValueHandler'),
        );
      });

      test('JSON_RETURN_VALUE_HANDLER_POD_NAME is correct', () {
        expect(
          ReturnValueAutoConfiguration.JSON_RETURN_VALUE_HANDLER_POD_NAME,
          equals('jetleaf.web.handler.jsonReturnValueHandler'),
        );
      });

      test('XML_RETURN_VALUE_HANDLER_POD_NAME is correct', () {
        expect(
          ReturnValueAutoConfiguration.XML_RETURN_VALUE_HANDLER_POD_NAME,
          equals('jetleaf.web.handler.xmlReturnValueHandler'),
        );
      });

      test('YAML_RETURN_VALUE_HANDLER_POD_NAME is correct', () {
        expect(
          ReturnValueAutoConfiguration.YAML_RETURN_VALUE_HANDLER_POD_NAME,
          equals('jetleaf.web.handler.yamlReturnValueHandler'),
        );
      });

      test('DEFAULT_RETURN_VALUE_HANDLER_MANAGER_POD_NAME is correct', () {
        expect(
          ReturnValueAutoConfiguration.DEFAULT_RETURN_VALUE_HANDLER_MANAGER_POD_NAME,
          equals('jetleaf.web.handler.defaultReturnValueHandlerManager'),
        );
      });
    });

    group('defaultReturnValueHandler', () {
      test('returns ReturnValueHandlerManager instance', () {
        final resolver = DefaultContentNegotiationResolver();
        final manager = config.defaultReturnValueHandler(resolver);
        expect(manager, isA<ReturnValueHandlerManager>());
      });

      test('returns DefaultReturnValueHandlerManager', () {
        final resolver = DefaultContentNegotiationResolver();
        final manager = config.defaultReturnValueHandler(resolver);
        expect(manager, isA<DefaultReturnValueHandlerManager>());
      });
    });

    group('viewNameReturnValueHandler', () {
      test('returns ReturnValueHandler instance', () {
        final jtl = JtlFactory();
        final assetBuilder = AssetBuilder();
        final handler = config.viewNameReturnValueHandler(jtl, assetBuilder);
        expect(handler, isA<ReturnValueHandler>());
      });

      test('returns ViewNameReturnValueHandler', () {
        final jtl = JtlFactory();
        final assetBuilder = AssetBuilder();
        final handler = config.viewNameReturnValueHandler(jtl, assetBuilder);
        expect(handler, isA<ViewNameReturnValueHandler>());
      });
    });

    group('pageViewReturnValueHandler', () {
      test('returns ReturnValueHandler instance', () {
        final jtl = JtlFactory();
        final assetBuilder = AssetBuilder();
        final handler = config.pageViewReturnValueHandler(jtl, assetBuilder);
        expect(handler, isA<ReturnValueHandler>());
      });

      test('returns PageViewReturnValueHandler', () {
        final jtl = JtlFactory();
        final assetBuilder = AssetBuilder();
        final handler = config.pageViewReturnValueHandler(jtl, assetBuilder);
        expect(handler, isA<PageViewReturnValueHandler>());
      });
    });

    group('redirectReturnValueHandler', () {
      test('returns ReturnValueHandler instance', () {
        final jtl = JtlFactory();
        final assetBuilder = AssetBuilder();
        final handler = config.redirectReturnValueHandler(jtl, assetBuilder);
        expect(handler, isA<ReturnValueHandler>());
      });

      test('returns RedirectReturnValueHandler', () {
        final jtl = JtlFactory();
        final assetBuilder = AssetBuilder();
        final handler = config.redirectReturnValueHandler(jtl, assetBuilder);
        expect(handler, isA<RedirectReturnValueHandler>());
      });
    });

    group('responseBodyReturnValueHandler', () {
      test('returns ReturnValueHandler instance', () {
        final converters = HttpMessageConverters();
        final handler = config.responseBodyReturnValueHandler(converters);
        expect(handler, isA<ReturnValueHandler>());
      });

      test('returns ResponseBodyReturnValueHandler', () {
        final converters = HttpMessageConverters();
        final handler = config.responseBodyReturnValueHandler(converters);
        expect(handler, isA<ResponseBodyReturnValueHandler>());
      });
    });

    group('jsonReturnValueHandler', () {
      test('returns ReturnValueHandler instance', () {
        final converters = HttpMessageConverters();
        final handler = config.jsonReturnValueHandler(converters);
        expect(handler, isA<ReturnValueHandler>());
      });

      test('returns JsonReturnValueHandler', () {
        final converters = HttpMessageConverters();
        final handler = config.jsonReturnValueHandler(converters);
        expect(handler, isA<JsonReturnValueHandler>());
      });
    });

    group('voidReturnValueHandler', () {
      test('returns ReturnValueHandler instance', () {
        final handler = config.voidReturnValueHandler();
        expect(handler, isA<ReturnValueHandler>());
      });

      test('returns VoidReturnValueHandler', () {
        final handler = config.voidReturnValueHandler();
        expect(handler, isA<VoidReturnValueHandler>());
      });
    });

    group('stringReturnValueHandler', () {
      test('returns ReturnValueHandler instance', () {
        final handler = config.stringReturnValueHandler();
        expect(handler, isA<ReturnValueHandler>());
      });

      test('returns StringReturnValueHandler', () {
        final handler = config.stringReturnValueHandler();
        expect(handler, isA<StringReturnValueHandler>());
      });
    });

    group('xmlReturnValueHandler', () {
      test('returns ReturnValueHandler instance', () {
        final converters = HttpMessageConverters();
        final handler = config.xmlReturnValueHandler(converters);
        expect(handler, isA<ReturnValueHandler>());
      });

      test('returns XmlReturnValueHandler', () {
        final converters = HttpMessageConverters();
        final handler = config.xmlReturnValueHandler(converters);
        expect(handler, isA<XmlReturnValueHandler>());
      });
    });

    group('yamlReturnValueHandler', () {
      test('returns ReturnValueHandler instance', () {
        final converters = HttpMessageConverters();
        final handler = config.yamlReturnValueHandler(converters);
        expect(handler, isA<ReturnValueHandler>());
      });

      test('returns YamlReturnValueHandler', () {
        final converters = HttpMessageConverters();
        final handler = config.yamlReturnValueHandler(converters);
        expect(handler, isA<YamlReturnValueHandler>());
      });
    });
  });

  // =========================================================================
  // JetsonAutoConfiguration
  // =========================================================================
  group('JetsonAutoConfiguration', () {
    late JetsonAutoConfiguration config;
    late _TestEnvironment environment;

    setUp(() {
      config = JetsonAutoConfiguration();
      environment = _TestEnvironment();
      config.setEnvironment(environment);
    });

    group('Constants', () {
      test('NAME is correct', () {
        expect(
          JetsonAutoConfiguration.NAME,
          equals('jetleaf.web.jetsonAutoConfiguration'),
        );
      });

      test('JETSON_OBJECT_MAPPER_POD_NAME is correct', () {
        expect(
          JetsonAutoConfiguration.JETSON_OBJECT_MAPPER_POD_NAME,
          equals('jetson.objectMapper'),
        );
      });

      test('PRETTY_PRINT is correct', () {
        expect(
          JetsonAutoConfiguration.PRETTY_PRINT,
          equals('jetleaf.jetson.pretty-print'),
        );
      });
    });

    group('setEnvironment', () {
      test('sets the environment without throwing', () {
        final cfg = JetsonAutoConfiguration();
        expect(() => cfg.setEnvironment(environment), returnsNormally);
      });
    });

    group('objectMapper', () {
      test('returns ObjectMapper instance', () {
        final mapper = config.objectMapper();
        expect(mapper, isA<ObjectMapper>());
      });

      test('enables pretty print when property is true', () {
        environment.setProperty('jetleaf.jetson.pretty-print', 'true');
        final mapper = config.objectMapper();
        expect(mapper, isA<ObjectMapper>());
      });

      test('disables pretty print when property is false', () {
        environment.setProperty('jetleaf.jetson.pretty-print', 'false');
        final mapper = config.objectMapper();
        expect(mapper, isA<ObjectMapper>());
      });

      test('defaults to pretty print when property is not set', () {
        final mapper = config.objectMapper();
        expect(mapper, isA<ObjectMapper>());
      });
    });
  });

  // =========================================================================
  // JtlAutoConfiguration
  // =========================================================================
  group('JtlAutoConfiguration', () {
    late JtlAutoConfiguration config;

    setUp(() {
      config = JtlAutoConfiguration();
    });

    group('Constants', () {
      test('NAME is correct', () {
        expect(
          JtlAutoConfiguration.NAME,
          equals('jetleaf.web.JtlAutoConfiguration'),
        );
      });

      test('JTL_POD_NAME is correct', () {
        expect(
          JtlAutoConfiguration.JTL_POD_NAME,
          equals('jtl.factory'),
        );
      });

      test('JTL_TEMPLATE_CACHE_POD_NAME is correct', () {
        expect(
          JtlAutoConfiguration.JTL_TEMPLATE_CACHE_POD_NAME,
          equals('jtl.template.cache'),
        );
      });

      test('JTL_ASSET_BUILDER_POD_NAME is correct', () {
        expect(
          JtlAutoConfiguration.JTL_ASSET_BUILDER_POD_NAME,
          equals('jtl.asset.builder'),
        );
      });

      test('JTL_TEMPLATE_FILTER_REGISTRY_POD_NAME is correct', () {
        expect(
          JtlAutoConfiguration.JTL_TEMPLATE_FILTER_REGISTRY_POD_NAME,
          equals('jtl.template.filter-registry'),
        );
      });

      test('JTL_TEMPLATE_EXPRESSION_EVALUATOR_POD_NAME is correct', () {
        expect(
          JtlAutoConfiguration.JTL_TEMPLATE_EXPRESSION_EVALUATOR_POD_NAME,
          equals('jtl.template.expression-evaluator'),
        );
      });

      test('JTL_TEMPLATE_VARIABLE_RESOLVER_POD_NAME is correct', () {
        expect(
          JtlAutoConfiguration.JTL_TEMPLATE_VARIABLE_RESOLVER_POD_NAME,
          equals('jtl.template.variable-resolver'),
        );
      });

      test('JTL_TEMPLATE_RENDERER_POD_NAME is correct', () {
        expect(
          JtlAutoConfiguration.JTL_TEMPLATE_RENDERER_POD_NAME,
          equals('jtl.template.renderer'),
        );
      });
    });

    group('jtlTemplateCache', () {
      test('returns TemplateCache instance', () {
        final cache = config.jtlTemplateCache();
        expect(cache, isA<TemplateCache>());
      });
    });

    group('jtlAssetBuilder', () {
      test('returns AssetBuilder instance', () {
        final builder = config.jtlAssetBuilder();
        expect(builder, isA<AssetBuilder>());
      });
    });

    group('jtlFilterRegistry', () {
      test('returns TemplateFilterRegistry instance', () {
        final registry = config.jtlFilterRegistry();
        expect(registry, isA<TemplateFilterRegistry>());
      });
    });

    group('jtlTemplateExpressionEvaluator', () {
      test('returns TemplateExpressionEvaluator instance', () {
        final evaluator = config.jtlTemplateExpressionEvaluator();
        expect(evaluator, isA<TemplateExpressionEvaluator>());
      });
    });

    group('jtlTemplateVariableResolver', () {
      test('returns TemplateVariableResolver instance', () {
        final resolver = config.jtlTemplateVariableResolver();
        expect(resolver, isA<TemplateVariableResolver>());
      });
    });

    group('jtlTemplateRenderer', () {
      test('returns TemplateRenderer instance', () {
        final assetBuilder = config.jtlAssetBuilder();
        final filterRegistry = config.jtlFilterRegistry();
        final renderer = config.jtlTemplateRenderer(assetBuilder, filterRegistry);
        expect(renderer, isA<TemplateRenderer>());
      });
    });

    group('jtl', () {
      test('returns Jtl instance', () {
        final cache = config.jtlTemplateCache();
        final assetBuilder = config.jtlAssetBuilder();
        final filterRegistry = config.jtlFilterRegistry();
        final expressionEvaluator = config.jtlTemplateExpressionEvaluator();
        final variableResolver = config.jtlTemplateVariableResolver();
        final renderer = config.jtlTemplateRenderer(assetBuilder, filterRegistry);

        final jtl = config.jtl(
          cache,
          assetBuilder,
          filterRegistry,
          expressionEvaluator,
          variableResolver,
          renderer,
        );

        expect(jtl, isA<Jtl>());
      });
    });
  });

  // =========================================================================
  // Configuration Dependency Chain
  // =========================================================================
  group('Configuration Dependency Chain', () {
    test('JtlAutoConfiguration beans can be fully wired', () {
      final config = JtlAutoConfiguration();
      final cache = config.jtlTemplateCache();
      final assetBuilder = config.jtlAssetBuilder();
      final filterRegistry = config.jtlFilterRegistry();
      final expressionEvaluator = config.jtlTemplateExpressionEvaluator();
      final variableResolver = config.jtlTemplateVariableResolver();
      final renderer = config.jtlTemplateRenderer(assetBuilder, filterRegistry);

      final jtl = config.jtl(
        cache,
        assetBuilder,
        filterRegistry,
        expressionEvaluator,
        variableResolver,
        renderer,
      );

      expect(jtl, isNotNull);
      expect(cache, isNotNull);
      expect(assetBuilder, isNotNull);
      expect(filterRegistry, isNotNull);
      expect(expressionEvaluator, isNotNull);
      expect(variableResolver, isNotNull);
      expect(renderer, isNotNull);
    });

    test('CorsAutoConfiguration beans can be fully wired', () {
      final config = CorsAutoConfiguration();
      final parser = PathPatternParserManager();
      final manager = config.manager(parser);
      final filter = config.corsFilter(manager);

      expect(manager, isNotNull);
      expect(filter, isNotNull);
    });

    test('CsrfAutoConfiguration beans can be fully wired', () {
      final config = const CsrfAutoConfiguration();
      final manager = config.csrfTokenRepositoryManager();
      final repository = config.csrfTokenRepository();
      final filter = config.csrfFilter(manager);

      expect(manager, isNotNull);
      expect(repository, isNotNull);
      expect(filter, isNotNull);
    });

    test('ContentNegotiationAutoConfiguration beans can be fully wired', () {
      final config = ContentNegotiationAutoConfiguration();
      final strategy = config.acceptHeaderNegotiationStrategy();
      final resolver = config.defaultContentNegotiationResolver();

      expect(strategy, isNotNull);
      expect(resolver, isNotNull);
    });

    test('HttpMessageAutoConfiguration converters can be registered', () {
      final config = HttpMessageAutoConfiguration();
      final converters = config.httpMessageConverters();

      converters.add(config.stringHttpMessageConverter());
      converters.add(config.byteArrayHttpMessageConverter());
      converters.add(config.formHttpMessageConverter());

      final jetsonConverter = config.jetson2HttpMessageConverter(ObjectMapper());
      converters.add(jetsonConverter);

      expect(converters.getMessageConverters(), hasLength(4));
    });

    test('MethodArgumentAutoConfiguration beans can be fully wired', () {
      final config = MethodArgumentAutoConfiguration();
      final manager = config.defaultMethodArgumentResolver();
      final converters = HttpMessageConverters();
      final ctx = DefaultResolverContext(converters);
      final annotatedResolver = config.annotatedMethodArgumentResolver(ctx);
      final frameworkResolver = config.frameworkMethodArgumentResolver();

      expect(manager, isNotNull);
      expect(annotatedResolver, isNotNull);
      expect(frameworkResolver, isNotNull);
    });

    test('HandlerAdapterAutoConfiguration beans can be fully wired', () {
      final config = HandlerAdapterAutoConfiguration();
      final methodResolver = DefaultMethodArgumentResolverManager();
      final returnValueHandler = DefaultReturnValueHandlerManager(
        DefaultContentNegotiationResolver(),
      );

      final annotated = config.annotatedHandlerAdapter(methodResolver, returnValueHandler);
      final routeDsl = config.routeDslHandlerAdapter(methodResolver, returnValueHandler);
      final framework = config.frameworkHandlerAdapter(methodResolver, returnValueHandler);
      final webView = config.webViewHandlerAdapter(methodResolver, returnValueHandler);

      expect(annotated, isNotNull);
      expect(routeDsl, isNotNull);
      expect(framework, isNotNull);
      expect(webView, isNotNull);
    });

    test('ExceptionResolverAutoConfiguration beans can be fully wired', () {
      final config = ExceptionResolverAutoConfiguration();
      final methodResolver = DefaultMethodArgumentResolverManager();
      final returnValueHandler = DefaultReturnValueHandlerManager(
        DefaultContentNegotiationResolver(),
      );
      final pages = config.errorPages();

      final restResolver = config.restControllerAdviceExceptionResolver(
        methodResolver,
        returnValueHandler,
      );
      final htmlResolver = config.controllerAdviceExceptionResolver(
        methodResolver,
        returnValueHandler,
        pages,
      );
      final restHandler = config.restControllerAdviceExceptionHandler();
      final controllerHandler = config.controllerAdviceExceptionHandler();

      expect(restResolver, isNotNull);
      expect(htmlResolver, isNotNull);
      expect(restHandler, isNotNull);
      expect(controllerHandler, isNotNull);
    });

    test('WebAutoConfiguration beans can be fully wired', () {
      final config = WebAutoConfiguration();
      final parser = config.pathPatternParserManager();
      final decoder = IoEncodingDecoder();
      final client = config.ioRestClient(decoder);
      final converters = HttpMessageConverters();
      final ctx = config.resolverContext(converters);
      final interceptor = config.handlerInterceptorManager();
      final adapterManager = config.handlerAdapterManager();
      final resolver = DefaultContentNegotiationResolver();
      final exceptionManager = config.exceptionResolverManager(resolver);
      final filterManager = config.filterManager();
      final mapping = config.registryHandlerMapping(parser);

      expect(parser, isNotNull);
      expect(client, isNotNull);
      expect(ctx, isNotNull);
      expect(interceptor, isNotNull);
      expect(adapterManager, isNotNull);
      expect(exceptionManager, isNotNull);
      expect(filterManager, isNotNull);
      expect(mapping, isNotNull);
    });

    test('JetsonAutoConfiguration with environment configuration', () {
      final config = JetsonAutoConfiguration();
      final environment = _TestEnvironment();
      environment.setProperty('jetleaf.jetson.pretty-print', 'false');
      config.setEnvironment(environment);

      final mapper = config.objectMapper();
      expect(mapper, isA<ObjectMapper>());
    });

    test('ReturnValueAutoConfiguration handlers can be fully wired', () {
      final config = ReturnValueAutoConfiguration();
      final resolver = DefaultContentNegotiationResolver();
      final converters = HttpMessageConverters();
      final jtl = JtlFactory();
      final assetBuilder = AssetBuilder();

      final manager = config.defaultReturnValueHandler(resolver);
      final viewName = config.viewNameReturnValueHandler(jtl, assetBuilder);
      final pageView = config.pageViewReturnValueHandler(jtl, assetBuilder);
      final redirect = config.redirectReturnValueHandler(jtl, assetBuilder);
      final responseBody = config.responseBodyReturnValueHandler(converters);
      final json = config.jsonReturnValueHandler(converters);
      final voidHandler = config.voidReturnValueHandler();
      final string = config.stringReturnValueHandler();
      final xml = config.xmlReturnValueHandler(converters);
      final yaml = config.yamlReturnValueHandler(converters);

      expect(manager, isNotNull);
      expect(viewName, isNotNull);
      expect(pageView, isNotNull);
      expect(redirect, isNotNull);
      expect(responseBody, isNotNull);
      expect(json, isNotNull);
      expect(voidHandler, isNotNull);
      expect(string, isNotNull);
      expect(xml, isNotNull);
      expect(yaml, isNotNull);
    });
  });

  // =========================================================================
  // Configuration Ordering & Role Verification
  // =========================================================================
  group('Configuration Ordering & Role', () {
    test('WebAutoConfiguration has INFRASTRUCTURE role annotation', () {
      expect(WebAutoConfiguration, isNotNull);
    });

    test('WebServerAutoConfiguration has INFRASTRUCTURE role annotation', () {
      expect(WebServerAutoConfiguration, isNotNull);
    });

    test('CorsAutoConfiguration has INFRASTRUCTURE role annotation', () {
      expect(CorsAutoConfiguration, isNotNull);
    });

    test('CsrfAutoConfiguration has INFRASTRUCTURE role annotation', () {
      expect(CsrfAutoConfiguration, isNotNull);
    });

    test('ContentNegotiationAutoConfiguration has INFRASTRUCTURE role annotation', () {
      expect(ContentNegotiationAutoConfiguration, isNotNull);
    });

    test('ExceptionResolverAutoConfiguration has INFRASTRUCTURE role annotation', () {
      expect(ExceptionResolverAutoConfiguration, isNotNull);
    });

    test('HandlerAdapterAutoConfiguration has INFRASTRUCTURE role annotation', () {
      expect(HandlerAdapterAutoConfiguration, isNotNull);
    });

    test('HttpMessageAutoConfiguration has INFRASTRUCTURE role annotation', () {
      expect(HttpMessageAutoConfiguration, isNotNull);
    });

    test('MethodArgumentAutoConfiguration has INFRASTRUCTURE role annotation', () {
      expect(MethodArgumentAutoConfiguration, isNotNull);
    });

    test('ReturnValueAutoConfiguration has INFRASTRUCTURE role annotation', () {
      expect(ReturnValueAutoConfiguration, isNotNull);
    });

    test('JetsonAutoConfiguration has INFRASTRUCTURE role annotation', () {
      expect(JetsonAutoConfiguration, isNotNull);
    });

    test('JtlAutoConfiguration has INFRASTRUCTURE role annotation', () {
      expect(JtlAutoConfiguration, isNotNull);
    });
  });

  // =========================================================================
  // Pod Name Consistency
  // =========================================================================
  group('Pod Name Consistency', () {
    test('all pod names follow jetleaf.web prefix convention', () {
      final podNames = [
        WebAutoConfiguration.WEB_AUTO_CONFIGURATION_POD_NAME,
        WebAutoConfiguration.RESOLVER_CONTEXT_POD_NAME,
        WebAutoConfiguration.REST_POD_NAME,
        WebAutoConfiguration.PATH_PATTERN_PARSER_MANAGER_POD_NAME,
        WebAutoConfiguration.HANDLER_INTERCEPTOR_MANAGER_POD_NAME,
        WebAutoConfiguration.HANDLER_ADAPTER_MANAGER_POD_NAME,
        WebAutoConfiguration.EXCEPTION_RESOLVER_MANAGER_POD_NAME,
        WebAutoConfiguration.FILTER_MANAGER_POD_NAME,
        WebAutoConfiguration.ROUTE_REGISTRY_HANDLER_MAPPING_POD_NAME,
        WebServerAutoConfiguration.NAME,
        WebServerAutoConfiguration.IO_ENCODING_DECODER_POD_NAME,
        WebServerAutoConfiguration.GLOBAL_SERVER_DISPATCHER_POD_NAME,
        WebServerAutoConfiguration.IO_MULTIPART_RESOLVER_POD_NAME,
        WebServerAutoConfiguration.WEB_SERVER_FACTORY_POD_NAME,
        WebServerAutoConfiguration.SERVER_CONTEXT_POD_NAME,
        ContentNegotiationAutoConfiguration.CONFIG_POD_NAME,
        ContentNegotiationAutoConfiguration.CONTENT_NEGOTIATION_STRATEGY_POD_NAME,
        ContentNegotiationAutoConfiguration.CONTENT_NEGOTIATION_RESOLVER_POD_NAME,
        ExceptionResolverAutoConfiguration.NAME,
        ExceptionResolverAutoConfiguration.HTML_EXCEPTION_RESOLVER_POD_NAME,
        ExceptionResolverAutoConfiguration.REST_EXCEPTION_RESOLVER_POD_NAME,
        ExceptionResolverAutoConfiguration.DEFAULT_REST_CONTROLLER_EXCEPTION_HANDLER_POD_NAME,
        ExceptionResolverAutoConfiguration.DEFAULT_CONTROLLER_EXCEPTION_HANDLER_POD_NAME,
        ExceptionResolverAutoConfiguration.ERROR_PAGES_POD_NAME,
        HandlerAdapterAutoConfiguration.NAME,
        HandlerAdapterAutoConfiguration.ANNOTATED_HANDLER_ADAPTER_POD_NAME,
        HandlerAdapterAutoConfiguration.WEB_VIEW_HANDLER_ADAPTER_POD_NAME,
        HandlerAdapterAutoConfiguration.ROUTE_DSL_HANDLER_ADAPTER_POD_NAME,
        HandlerAdapterAutoConfiguration.FRAMEWORK_HANDLER_ADAPTER_POD_NAME,
        HttpMessageAutoConfiguration.NAME,
        HttpMessageAutoConfiguration.HTTP_MESSAGE_CONVERTERS_POD_NAME,
        HttpMessageAutoConfiguration.JETSON_2_HTTP_MESSAGE_CONVERTER_POD_NAME,
        HttpMessageAutoConfiguration.STRING_HTTP_MESSAGE_CONVERTER_POD_NAME,
        HttpMessageAutoConfiguration.BYTE_ARRAY_HTTP_MESSAGE_CONVERTER_POD_NAME,
        HttpMessageAutoConfiguration.JETSON_2_XML_HTTP_MESSAGE_CONVERTER_POD_NAME,
        HttpMessageAutoConfiguration.JETSON_2_YAML_HTTP_MESSAGE_CONVERTER_POD_NAME,
        HttpMessageAutoConfiguration.FORM_HTTP_MESSAGE_CONVERTER_POD_NAME,
        MethodArgumentAutoConfiguration.NAME,
        MethodArgumentAutoConfiguration.ANNOTATED_METHOD_ARGUMENT_RESOLVER_POD_NAME,
        MethodArgumentAutoConfiguration.FRAMEWORK_METHOD_ARGUMENT_RESOLVER_POD_NAME,
        MethodArgumentAutoConfiguration.DEFAULT_METHOD_ARGUMENT_RESOLVER_MANAGER_POD_NAME,
        ReturnValueAutoConfiguration.NAME,
        ReturnValueAutoConfiguration.VIEW_NAME_RETURN_VALUE_HANDLER_POD_NAME,
        ReturnValueAutoConfiguration.PAGE_VIEW_RETURN_VALUE_HANDLER_POD_NAME,
        ReturnValueAutoConfiguration.REDIRECT_RETURN_VALUE_HANDLER_POD_NAME,
        ReturnValueAutoConfiguration.RESPONSE_BODY_RETURN_VALUE_HANDLER_POD_NAME,
        ReturnValueAutoConfiguration.STRING_RETURN_VALUE_HANDLER_POD_NAME,
        ReturnValueAutoConfiguration.VOID_RETURN_VALUE_HANDLER_POD_NAME,
        ReturnValueAutoConfiguration.JSON_RETURN_VALUE_HANDLER_POD_NAME,
        ReturnValueAutoConfiguration.XML_RETURN_VALUE_HANDLER_POD_NAME,
        ReturnValueAutoConfiguration.YAML_RETURN_VALUE_HANDLER_POD_NAME,
        ReturnValueAutoConfiguration.DEFAULT_RETURN_VALUE_HANDLER_MANAGER_POD_NAME,
        JetsonAutoConfiguration.NAME,
        JetsonAutoConfiguration.JETSON_OBJECT_MAPPER_POD_NAME,
        JtlAutoConfiguration.NAME,
        CorsAutoConfiguration.NAME,
        CorsAutoConfiguration.CORS_MANAGER,
        CorsAutoConfiguration.CORS_FILTER,
        CsrfAutoConfiguration.NAME,
        CsrfAutoConfiguration.TOKEN_REPOSITORY_MANAGER_POD,
        CsrfAutoConfiguration.TOKEN_REPOSITORY_POD,
        CsrfAutoConfiguration.CSRF_FILTER_POD,
      ];

      for (final name in podNames) {
        if (name == JetsonAutoConfiguration.JETSON_OBJECT_MAPPER_POD_NAME) continue;
        expect(
          name.startsWith('jetleaf.'),
          isTrue,
          reason: 'Pod name "$name" should start with "jetleaf."',
        );
      }
    });

    test('no duplicate pod names across configurations', () {
      final podNames = <String>{
        WebAutoConfiguration.WEB_AUTO_CONFIGURATION_POD_NAME,
        WebAutoConfiguration.RESOLVER_CONTEXT_POD_NAME,
        WebAutoConfiguration.REST_POD_NAME,
        WebAutoConfiguration.PATH_PATTERN_PARSER_MANAGER_POD_NAME,
        WebAutoConfiguration.HANDLER_INTERCEPTOR_MANAGER_POD_NAME,
        WebAutoConfiguration.HANDLER_ADAPTER_MANAGER_POD_NAME,
        WebAutoConfiguration.EXCEPTION_RESOLVER_MANAGER_POD_NAME,
        WebAutoConfiguration.FILTER_MANAGER_POD_NAME,
        WebAutoConfiguration.ROUTE_REGISTRY_HANDLER_MAPPING_POD_NAME,
        WebServerAutoConfiguration.NAME,
        WebServerAutoConfiguration.IO_ENCODING_DECODER_POD_NAME,
        WebServerAutoConfiguration.GLOBAL_SERVER_DISPATCHER_POD_NAME,
        WebServerAutoConfiguration.IO_MULTIPART_RESOLVER_POD_NAME,
        WebServerAutoConfiguration.WEB_SERVER_FACTORY_POD_NAME,
        WebServerAutoConfiguration.SERVER_CONTEXT_POD_NAME,
        ContentNegotiationAutoConfiguration.CONFIG_POD_NAME,
        ContentNegotiationAutoConfiguration.CONTENT_NEGOTIATION_STRATEGY_POD_NAME,
        ContentNegotiationAutoConfiguration.CONTENT_NEGOTIATION_RESOLVER_POD_NAME,
        ExceptionResolverAutoConfiguration.NAME,
        ExceptionResolverAutoConfiguration.HTML_EXCEPTION_RESOLVER_POD_NAME,
        ExceptionResolverAutoConfiguration.REST_EXCEPTION_RESOLVER_POD_NAME,
        ExceptionResolverAutoConfiguration.DEFAULT_REST_CONTROLLER_EXCEPTION_HANDLER_POD_NAME,
        ExceptionResolverAutoConfiguration.DEFAULT_CONTROLLER_EXCEPTION_HANDLER_POD_NAME,
        ExceptionResolverAutoConfiguration.ERROR_PAGES_POD_NAME,
        HandlerAdapterAutoConfiguration.NAME,
        HandlerAdapterAutoConfiguration.ANNOTATED_HANDLER_ADAPTER_POD_NAME,
        HandlerAdapterAutoConfiguration.WEB_VIEW_HANDLER_ADAPTER_POD_NAME,
        HandlerAdapterAutoConfiguration.ROUTE_DSL_HANDLER_ADAPTER_POD_NAME,
        HandlerAdapterAutoConfiguration.FRAMEWORK_HANDLER_ADAPTER_POD_NAME,
        HttpMessageAutoConfiguration.NAME,
        HttpMessageAutoConfiguration.HTTP_MESSAGE_CONVERTERS_POD_NAME,
        HttpMessageAutoConfiguration.JETSON_2_HTTP_MESSAGE_CONVERTER_POD_NAME,
        HttpMessageAutoConfiguration.STRING_HTTP_MESSAGE_CONVERTER_POD_NAME,
        HttpMessageAutoConfiguration.BYTE_ARRAY_HTTP_MESSAGE_CONVERTER_POD_NAME,
        HttpMessageAutoConfiguration.JETSON_2_XML_HTTP_MESSAGE_CONVERTER_POD_NAME,
        HttpMessageAutoConfiguration.JETSON_2_YAML_HTTP_MESSAGE_CONVERTER_POD_NAME,
        HttpMessageAutoConfiguration.FORM_HTTP_MESSAGE_CONVERTER_POD_NAME,
        MethodArgumentAutoConfiguration.NAME,
        MethodArgumentAutoConfiguration.ANNOTATED_METHOD_ARGUMENT_RESOLVER_POD_NAME,
        MethodArgumentAutoConfiguration.FRAMEWORK_METHOD_ARGUMENT_RESOLVER_POD_NAME,
        MethodArgumentAutoConfiguration.DEFAULT_METHOD_ARGUMENT_RESOLVER_MANAGER_POD_NAME,
        ReturnValueAutoConfiguration.NAME,
        ReturnValueAutoConfiguration.VIEW_NAME_RETURN_VALUE_HANDLER_POD_NAME,
        ReturnValueAutoConfiguration.PAGE_VIEW_RETURN_VALUE_HANDLER_POD_NAME,
        ReturnValueAutoConfiguration.REDIRECT_RETURN_VALUE_HANDLER_POD_NAME,
        ReturnValueAutoConfiguration.RESPONSE_BODY_RETURN_VALUE_HANDLER_POD_NAME,
        ReturnValueAutoConfiguration.STRING_RETURN_VALUE_HANDLER_POD_NAME,
        ReturnValueAutoConfiguration.VOID_RETURN_VALUE_HANDLER_POD_NAME,
        ReturnValueAutoConfiguration.JSON_RETURN_VALUE_HANDLER_POD_NAME,
        ReturnValueAutoConfiguration.XML_RETURN_VALUE_HANDLER_POD_NAME,
        ReturnValueAutoConfiguration.YAML_RETURN_VALUE_HANDLER_POD_NAME,
        ReturnValueAutoConfiguration.DEFAULT_RETURN_VALUE_HANDLER_MANAGER_POD_NAME,
        JetsonAutoConfiguration.NAME,
        JetsonAutoConfiguration.JETSON_OBJECT_MAPPER_POD_NAME,
        JtlAutoConfiguration.NAME,
        JtlAutoConfiguration.JTL_POD_NAME,
        JtlAutoConfiguration.JTL_TEMPLATE_CACHE_POD_NAME,
        JtlAutoConfiguration.JTL_ASSET_BUILDER_POD_NAME,
        JtlAutoConfiguration.JTL_TEMPLATE_FILTER_REGISTRY_POD_NAME,
        JtlAutoConfiguration.JTL_TEMPLATE_EXPRESSION_EVALUATOR_POD_NAME,
        JtlAutoConfiguration.JTL_TEMPLATE_VARIABLE_RESOLVER_POD_NAME,
        JtlAutoConfiguration.JTL_TEMPLATE_RENDERER_POD_NAME,
        CorsAutoConfiguration.NAME,
        CorsAutoConfiguration.CORS_MANAGER,
        CorsAutoConfiguration.CORS_FILTER,
        CsrfAutoConfiguration.NAME,
        CsrfAutoConfiguration.TOKEN_REPOSITORY_MANAGER_POD,
        CsrfAutoConfiguration.TOKEN_REPOSITORY_POD,
        CsrfAutoConfiguration.CSRF_FILTER_POD,
      };

      final nonJetsonPodNames = podNames.where(
        (name) => name != JetsonAutoConfiguration.JETSON_OBJECT_MAPPER_POD_NAME,
      ).toList();
      expect(nonJetsonPodNames.length, equals(nonJetsonPodNames.toSet().length),
        reason: 'Duplicate pod names detected across configurations',
      );
    });
  });
}
