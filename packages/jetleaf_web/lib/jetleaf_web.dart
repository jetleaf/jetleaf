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

/// 🌐 **Jetleaf Web Framework**
///
/// This library provides a comprehensive web application framework for
/// Jetleaf, offering features such as:
/// - Annotation-driven request handling
/// - HTTP request/response management
/// - REST and multipart support
/// - Content negotiation
/// - CSRF and CORS protection
/// - Exception handling and advisories
/// - Handler adapters, interceptors, and mappings
/// - Return value handling
/// - Routing and filters
/// - Template and view rendering
/// - Integration with Jetson (object mapping) and JTL (template engine)
///
///
/// ## 🔑 Core Concepts
///
/// ### 🏷 Annotations
/// - `core.dart`, `request_mapping.dart`, `request_parameter.dart`
/// - `resolvers.dart` — declarative method-level configuration for requests  
/// - `default_resolver_context.dart` — default context for annotation resolution
///
///
/// ### ⚙ Configuration & Auto-Configuration
/// Provides auto-configuration for web application components:
/// - `WebAutoConfiguration`, `CsrfAutoConfiguration`
/// - `ExceptionResolverAutoConfiguration`
/// - `HandlerAdapterAutoConfiguration`
/// - `HttpMessageAutoConfiguration`
/// - `JetsonAutoConfiguration`, `JtlAutoConfiguration`
/// - `MethodArgumentAutoConfiguration`
/// - `ReturnValueAutoConfiguration`
/// - `WebServerAutoConfiguration`
/// - `ContentNegotiationAutoConfiguration`
///
///
/// ### 🌐 Server Contexts
/// - `ServerContext`, `WebApplicationContext` — runtime web application contexts  
/// - `ServerWebApplicationContext` — full-featured server web context  
/// - `Aware`, `WebAwareProcessor`, `DefaultServerContext` — helpers for context awareness
///
///
/// ### 📨 HTTP & I/O
/// - Core HTTP: `HttpMessage`, `HttpHeaders`, `HttpMethod`, `HttpStatus`, `HttpBody`, `HttpSession`, `HttpCookie`, `MediaType`, `Etag`, `CacheControl`  
/// - I/O: `IoRequest`, `IoResponse`, `IoMultipartRequest`, `IoMultipartResolver`, `IoPart`, `IoWebServer`, `MultipartParser`  
/// - Rest Client: `io_rest/client.dart`, `io_rest/executor.dart`, `io_rest/request.dart`, `io_rest/response.dart`
///
///
/// ### 🛠 Converters & Content Negotiation
/// - `AbstractHttpMessageConverter` and concrete converters for JSON, XML, YAML, and form data  
/// - `HttpMessageConverterRegistry`, `HttpMessageConverters`  
/// - `Jetson2HttpMessageConverter`, `Jetson2XmlHttpMessageConverter`, `Jetson2YamlHttpMessageConverter`  
/// - Content negotiation strategies and resolvers for handling client preferences
///
///
/// ### ⚡ Exception Handling
/// - Core exceptions: `exceptions.dart`, `server_exceptions.dart`, `path_exception.dart`  
/// - Exception resolvers: `HtmlExceptionResolver`, `RestExceptionResolver`, `ExceptionResolverManager`  
/// - Advisers & Handlers: `ExceptionAdviser`, `MethodExceptionAdviser`, `ControllerExceptionHandler`, `RestControllerExceptionHandler`
///
///
/// ### 🔄 Handler Adapters & Interceptors
/// - `HandlerAdapter` abstractions, including framework, annotated, route DSL, and web view adapters  
/// - `HandlerInterceptor` and `HandlerInterceptorManager` for request pre/post-processing
///
///
/// ### 🗺 Routing & Path Matching
/// - `Route`, `RouteEntry`, `Router`, `RouterRegistrar`, `RouterSpec`  
/// - Path utilities: `PathMatch`, `PathPattern`, `PathPatternParser`, `PathSegment`
/// - DSL-based and registry-based routing strategies
///
///
/// ### 🎯 Method Argument & Return Value Handling
/// - `MethodArgumentResolver` abstractions for annotated and framework-driven argument resolution  
/// - `ReturnValueHandler` implementations: JSON, XML, YAML, view-based, redirect, string, void, page view
///
///
/// ### 🔒 Security
/// - CORS: `CorsConfiguration`, `CorsFilter`, `DefaultCorsConfigurationManager`  
/// - CSRF: `CsrfFilter`, `CsrfToken`, `CsrfTokenRepository`, `CsrfTokenRepositoryManager`, `DefaultCsrfTokenRepositoryManager`
///
///
/// ### 📦 Multipart Support
/// - `MultipartFile`, `MultipartResolver`, `MultipartServerHttpRequest`, `Part`
///
///
/// ### 🖼 Web Rendering
/// - Templates and views: `Renderable`, `View`, `ViewContext`  
/// - Web request utilities and helpers: `WebRequest`, `Web`, `WebConfigurer`  
/// - Error pages: `ErrorPage`, `ErrorPages`  
///
///
/// ### 📌 Utilities
/// - `Encoding`, `MatrixVariableUtils`, `WebUtils`  
/// - URI building: `UriBuilder`  
/// - Event handling: `Events`
///
///
/// ### 📦 Integrated Packages
/// - `package:jtl/jtl.dart` — Jetleaf Template Engine  
/// - `package:jetson/jetson.dart` — Jetleaf Object Mapping & Serialization
///
///
/// ## 🎯 Intended Usage
///
/// Import this library to build fully-featured web applications in Jetleaf:
/// ```dart
/// import 'package:jetleaf_web/jetleaf_web.dart';
///
/// @Controller
/// class MyController {
///   @GetMapping('/hello')
///   String hello() => 'Hello, Jetleaf!';
/// }
/// ```
///
/// Supports annotation-driven configuration, REST and web endpoints, multipart requests,
/// content negotiation, exception handling, routing, filters, and templating.
///
///
/// © 2025 Hapnium & Jetleaf Contributors
library;

export 'annotation.dart';
export 'context.dart';
export 'converter.dart';
export 'config.dart';
export 'cors.dart';
export 'csrf.dart';
export 'env.dart';
export 'exception.dart';
export 'http.dart';
export 'io.dart';
export 'path.dart';
export 'rest.dart';
export 'server.dart';
export 'utils.dart';
export 'web.dart';
export 'jtl.dart';
export 'jetson.dart';