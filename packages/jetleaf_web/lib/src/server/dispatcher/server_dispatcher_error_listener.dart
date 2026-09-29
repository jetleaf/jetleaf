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

import 'dart:async';

import 'package:jetleaf_lang/lang.dart';

/// {@template server_dispatcher_error_listener}
/// A listener interface for handling uncaught or propagated errors occurring
/// within the Jetleaf server dispatch lifecycle.
///
/// `ServerDispatcherErrorListener` provides a uniform error-notification
/// mechanism for components integrated into the server dispatcher pipeline.
/// Implementations receive structured information about failures that occur
/// during request routing, middleware execution, controller invocation,
/// lifecycle hooks, or any other dispatch-phase operation.
///
/// This interface is intentionally low-level and is designed for diagnostic,
/// logging, alerting, or error translation layers. It does **not** participate
/// in error recovery or exception masking; its purpose is **observation**, not
/// control.
///
/// ---
/// ## 🔥 When Is This Called?
///
/// Jetleaf’s dispatch loop invokes listeners whenever:
///
/// - An exception is thrown and not fully handled inside the dispatcher  
/// - A controller method encounters an error  
/// - Middleware fails during execution  
/// - A reflection-based instantiation or invocation throws  
/// - The dispatcher surfaces an unexpected runtime exception  
///
/// This makes the listener suitable for:
/// - Global logging  
/// - Error analytics  
/// - Crash reporting tools  
/// - Debugging utilities  
///
/// ---
/// ## 🏗 Typical Implementation
///
/// ```dart
/// final class LoggingErrorListener implements ServerDispatcherErrorListener {
///   @override
///   FutureOr<void> listen(Object exception, Class exceptionClass, StackTrace stacktrace) {
///     print('[ServerError] ${exceptionClass.name}: $exception');
///     print(stacktrace);
///   }
/// }
/// ```
///
/// ---
/// ## ⚙ Design Notes
///
/// - `exceptionClass` is the Jetleaf reflective [`Class`] representation of
///   the thrown exception, enabling type-based routing or categorization.
/// - Implementers **must not rethrow**, as the dispatcher manages propagation.
/// - Implementations should avoid expensive synchronous operations to prevent
///   delaying the dispatch loop. Asynchronous hand-off is recommended.
/// - To integrate multiple listeners, Jetleaf systems typically use a
///   composite dispatcher or chain of observers.
///
/// ---
/// ## 🔗 Related Components
///
/// - `ServerDispatcher` — The central request routing and execution engine  
/// - `ExceptionDiagnosisReporter` — Higher-level diagnostic and enriched  
///   exception analysis  
/// - `Class` — Jetleaf reflection metadata for types  
/// - Logging & monitoring integrations  
///
/// {@endtemplate}
abstract interface class ServerDispatcherErrorListener {
  /// Receives notification of an exception thrown during the Jetleaf server
  /// dispatch cycle.
  ///
  /// This method is invoked for **every uncaught or propagated error** within
  /// the dispatcher. The listener is provided with the raw exception object,
  /// its Jetleaf reflective class metadata, and the generated `StackTrace`.
  ///
  /// ### Parameters
  ///
  /// - **exception** – The thrown error or exception instance.  
  /// - **exceptionClass** – A reflective [`Class`] representing the
  ///   exception type.  
  /// - **stacktrace** – The captured invocation trace providing execution
  ///   context for debugging and diagnostics.  
  ///
  /// ### Behavioral Expectations
  ///
  /// - Implementations must not throw or rethrow errors.
  /// - The listener should be non-blocking; heavy work should be offloaded.
  /// - The method is guaranteed to be invoked synchronously at the point of
  ///   failure during dispatch.
  FutureOr<void> listen(Object exception, Class exceptionClass, StackTrace stacktrace);
}