// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_lang/lang.dart';

/// {@template jet_leaf_exception}
/// A [RuntimeException] thrown when the application context is considered
/// "abandoned" during startup or shutdown.
///
/// This typically indicates a failure or interruption during the
/// initialization or lifecycle process of the JetLeaf application context.
///
/// Use this exception to signal that the [ConfigurableApplicationContext]
/// is no longer valid and cannot continue.
///
/// ### Example
/// ```dart
/// if (context == null) {
///   throw JetLeafException.nullable();
/// }
///
/// if (context.failed) {
///   throw JetLeafException(context);
/// }
/// ```
/// {@endtemplate}
class JetLeafException extends RuntimeException {
  /// The application context that was abandoned, if available.
  final ConfigurableApplicationContext? _applicationContext;

  /// {@macro jet_leaf_exception}
  ///
  /// Creates a [JetLeafException] with a reference to the abandoned
  /// [applicationContext].
  ///
  /// Use this when the context exists but is no longer valid, such as after
  /// a failed refresh or shutdown sequence.
  JetLeafException(this._applicationContext)
      : super("Application context was abandoned");

  /// Returns the [ConfigurableApplicationContext] that was abandoned,
  /// or `null` if no context was ever created.
  ///
  /// ### Example
  /// ```dart
  /// try {
  ///   // startup logic...
  /// } on JetLeafException catch (ex) {
  ///   final ctx = ex.getApplicationContext();
  ///   log.warn('Context abandoned: $ctx');
  /// }
  /// ```
  ConfigurableApplicationContext? getApplicationContext() => _applicationContext;
}