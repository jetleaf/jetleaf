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

import 'package:jetleaf_core/lang.dart';

/// {@template limiting}
/// Marker mixin indicating that a type provides limiting behavior.
///
/// This mixin itself defines no behavior. It is used purely as a semantic
/// indicator so that frameworks and utilities can detect whether a type
/// participates in limiting operations (for example, pagination limits,
/// maximum result sizes, or query bounds).
/// {@endtemplate}
abstract mixin class Limiting {
  /// Reflective class descriptor for [Limiting].
  static final Class<Limiting> CLASS = Class<Limiting>(null, PackageNames.DATA);
}

/// {@template limit}
/// A value object representing an upper bound (limit) typically used in
/// pagination, query constraints, or result-size restrictions.
///
/// A [Limit] expresses either:
/// - a **finite limit**: created via [Limit.of], representing a concrete
///   non-negative maximum, or
/// - an **unbounded state**: created via [Limit.unlimited], representing no
///   restriction.
/// {@endtemplate}
sealed class Limit extends Limiting implements EqualsAndHashCode {
  /// Reflective class descriptor for [Limit].
  static final Class<Limit> CLASS = Class<Limit>(null, PackageNames.DATA);

  /// Creates an unlimited (unbounded) limit.
  static Limit unlimited() => _Unlimited._();

  /// Creates a finite limit with the given [max] value.
  static Limit of(int max) => _Limited(max);

  /// Returns the concrete maximum number of elements allowed by this limit.
  int max();

  /// Returns `true` if this limit represents a concrete, non-negative maximum.
  bool isLimited() => this is _Limited;

  /// Returns `true` if this limit has no upper bound.
  bool isUnlimited() => !isLimited();
}

/// {@template limited}
/// Internal implementation of a finite [Limit] representing a concrete,
/// non-negative maximum value.
/// {@endtemplate}
final class _Limited extends Limit {
  /// The concrete maximum value represented by this limit.
  final int _max;

  /// {@macro limited}
  _Limited(this._max);

  @override
  List<Object?> equalizedProperties() => [_max];

  @override
  int max() => _max;

  @override
  bool isLimited() => true;
}

/// {@template unlimited}
/// Internal implementation of an unbounded [Limit] that represents the absence
/// of any maximum constraint.
/// {@endtemplate}
final class _Unlimited extends Limit {
  /// {@macro unlimited}
  _Unlimited._();

  @override
  List<Object?> equalizedProperties() => [runtimeType];

  @override
  bool isLimited() => false;

  @override
  int max() => throw UnsupportedOperationException("Always check isLimited() because unlimited limits do not define a max value");
}