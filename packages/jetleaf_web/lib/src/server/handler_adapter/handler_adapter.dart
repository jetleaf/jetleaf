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

import '../handler_method.dart';
import '../server_http_request.dart';
import '../server_http_response.dart';

/// {@template handler_adapter}
/// Defines the contract for all handler adapters within the Jetleaf Web framework.
///
/// A [HandlerAdapter] acts as the invocation bridge between the HTTP layer and the
/// application’s handler layer. It receives a resolved [HandlerMethod] from a
/// [HandlerMapping], checks if it supports the method, and if so, executes it.
///
/// ### Responsibilities
/// - Determine if it supports a specific [HandlerMethod] type via [supports].
/// - Invoke the handler and process its return value via [handle].
///
/// ### Implementations
/// - [AnnotatedHandlerAdapter]: Invokes annotated controller methods.
/// - [RouteDslHandlerAdapter]: Executes DSL-defined route handlers.
/// - [FrameworkHandlerAdapter]: Handles internal framework endpoints.
///
/// ### Example
/// ```dart
/// final adapter = AnnotatedHandlerAdapter(argumentResolver, returnValueHandler);
/// if (adapter.supports(handler)) {
///   await adapter.handle(request, response, handler);
/// }
/// ```
/// {@endtemplate}
@Author("Evaristus Adimonyemma")
abstract interface class HandlerAdapter {
  /// Creates a new [HandlerAdapter].
  /// 
  /// {@macro handler_adapter}
  const HandlerAdapter();

  /// Determines whether this adapter supports the given [HandlerMethod].
  ///
  /// Implementations typically check the handler’s runtime type to decide whether
  /// they can execute it.
  ///
  /// For example:
  /// ```dart
  /// bool supports(HandlerMethod handler) => handler is AnnotatedHandlerMethod;
  /// ```
  bool supports(HandlerMethod handler);

  /// Handles the given [HandlerMethod] for the provided HTTP [request] and [response].
  ///
  /// Implementations perform:
  /// 1. Parameter resolution via argument resolvers.
  /// 2. Method invocation via reflection or direct function calls.
  /// 3. Return value handling via configured return value handlers.
  ///
  /// ### Parameters
  /// - [request]: The incoming [ServerHttpRequest].
  /// - [response]: The outgoing [ServerHttpResponse].
  /// - [handler]: The [HandlerMethod] to be executed.
  ///
  /// ### Returns
  /// A [Future] that completes when the handler has finished processing the request.
  Future<void> handle(ServerHttpRequest request, ServerHttpResponse response, HandlerMethod handler);
}