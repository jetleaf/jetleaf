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

import '../handler_mapping/abstract_route_dsl_handler_mapping.dart';
import '../handler_method.dart';
import '../server_http_request.dart';
import '../server_http_response.dart';
import 'abstract_url_handler_adapter.dart';

/// {@template route_dsl_handler_adapter}
/// Adapter that supports Jetleaf’s DSL-based routing system.
///
/// The [RouteDslHandlerAdapter] is responsible for invoking route handlers
/// defined using the Jetleaf routing DSL (e.g. via [RouterBuilder] or
/// [RouterRegistrar]).
///
/// It extends [AbstractUrlHandlerAdapter], inheriting its argument and return
/// value processing pipeline.
///
/// ### Responsibilities
/// - Check if the provided [HandlerMethod] is a [RouteDslHandlerMethod].
/// - Execute the corresponding route’s handler function.
/// - Delegate the return value to the configured
///   [CompositeReturnValueHandler].
///
/// ### Example
/// ```dart
/// final adapter = RouteDslHandlerAdapter(argResolver, returnHandler);
/// if (adapter.supports(handler)) {
///   await adapter.handle(request, response, handler);
/// }
/// ```
///
/// {@macro abstract_url_handler_adapter}
/// {@endtemplate}
@Author("Evaristus Adimonyemma")
class RouteDslHandlerAdapter extends AbstractUrlHandlerAdapter {
  /// {@macro route_dsl_handler_adapter}
  RouteDslHandlerAdapter(super.methodArgumentResolver, super.methodReturnValueHandler);
  
  @override
  bool supports(HandlerMethod handler) => handler is RouteDslHandlerMethod;

  @override
  Future<void> handle(ServerHttpRequest request, ServerHttpResponse response, HandlerMethod handler) async {
    // --- 1️⃣ Handle DSL-based Route Handlers ---
    if (handler is RouteDslHandlerMethod) {
      final result = await handler.definition.handler.invoke(request, response);
      if (result is Future) {
        final update = await result;
        return methodReturnValueHandler.handleReturnValue(update, null, request, response, handler);
      }

      return methodReturnValueHandler.handleReturnValue(result, null, request, response, handler);
    }
  }
}