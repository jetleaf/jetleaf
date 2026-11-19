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

import '../annotation/param.dart';
import '../exception/data_access_exception.dart';
import '../mapping/type_converter_registry.dart';
import '../paging/pageable.dart';
import '../paging/sort.dart';
import 'bound_parameters.dart';
import 'part.dart';
import 'part_tree.dart';

export 'bound_parameters.dart';

/// {@template jetleaf_parameter_binder}
/// Binds repository method arguments to query parameters for both **derived
/// queries** ([PartTree]) and **declared queries** (`@Query`).
///
/// Converts bound values into their database column representations via
/// [TypeConverterRegistry], applies SQL `LIKE` wildcard wrapping for
/// `StartingWith`/`EndingWith`/`Containing`, and extracts trailing [Pageable]
/// and [Sort] arguments.
/// {@endtemplate}
final class ParameterBinder with EqualsAndHashCode {
  /// Reflective [Class] handle for [ParameterBinder].
  static final Class<ParameterBinder> CLASS =
      Class<ParameterBinder>(null, PackageNames.DATA);

  final TypeConverterRegistry _converters;

  /// {@macro jetleaf_parameter_binder}
  ParameterBinder([TypeConverterRegistry? converters])
      : _converters = converters ?? TypeConverterRegistry.instance;

  /// Returns the [TypeConverterRegistry] used by this binder.
  TypeConverterRegistry getConverters() => _converters;

  /// Normalizes positional and named call arguments into the declaration order
  /// of [method]'s parameters.
  static List<Object?> normalizeArguments(
    List<Object?> positionalArguments,
    Map<Symbol, Object?> namedArguments,
    Method method, {
    required String methodName,
  }) {
    final parameters = method.getParameters().toList();
    final result = List<Object?>.filled(parameters.length, _Unset.instance);

    var positionalIndex = 0;
    for (var i = 0; i < parameters.length; i++) {
      final parameter = parameters[i];
      if (parameter.isPositional()) {
        if (positionalIndex < positionalArguments.length) {
          result[i] = positionalArguments[positionalIndex++];
        }
        continue;
      }

      final name = parameter.getName();
      final symbol = Symbol(name);
      if (namedArguments.containsKey(symbol)) {
        result[i] = namedArguments[symbol];
      }
    }

    while (positionalIndex < positionalArguments.length) {
      result.add(positionalArguments[positionalIndex++]);
    }

    for (var i = 0; i < result.length; i++) {
      if (identical(result[i], _Unset.instance)) {
        final parameter = i < parameters.length ? parameters[i] : null;
        if (parameter != null && parameter.isOptional()) {
          result[i] = null;
          continue;
        }

        throw QueryDerivationException(
          'Missing argument for parameter "${parameter?.getName() ?? i}" of $methodName',
          methodName: methodName,
        );
      }
    }

    return result;
  }

  /// Normalizes an [ExecutableArgument] from JetLeaf's interception pipeline
  /// into declaration order for [method].
  static List<Object?> normalizeExecutableArgument(
    ExecutableArgument argument,
    Method method, {
    required String methodName,
  }) {
    final namedBySymbol = <Symbol, Object?>{
      for (final entry in argument.getNamedArguments().entries)
        Symbol(entry.key): entry.value,
    };
    return normalizeArguments(
      argument.getPositionalArguments(),
      namedBySymbol,
      method,
      methodName: methodName,
    );
  }

  /// Binds [orderedArguments] against a derived [tree].
  BoundParameters bindDerived(
    List<Object?> orderedArguments,
    PartTree tree, {
    required String methodName,
  }) {
    final positional = <Object?>[];
    Pageable? pageable;
    Sort? sort;

    final valueArgs = <Object?>[];
    for (final argument in orderedArguments) {
      if (argument is Pageable) {
        pageable = argument;
        continue;
      }
      if (argument is Sort) {
        sort = argument;
        continue;
      }
      valueArgs.add(argument);
    }

    var cursor = 0;
    for (final part in tree.getParts()) {
      final paramCount = part.getParameterCount();
      final op = part.getOperator();
      for (var i = 0; i < paramCount; i++) {
        if (cursor >= valueArgs.length) {
          throw QueryDerivationException(
            'Not enough arguments for "${part.getProperty()}" in $methodName — expected $paramCount',
            methodName: methodName,
          );
        }

        final raw = valueArgs[cursor++];

        if (op == PartOperator.in_ || op == PartOperator.notIn) {
          if (raw is! Iterable) {
            throw QueryDerivationException(
              'Operator ${op.getKeyword()} on "${part.getProperty()}" requires an Iterable argument, got ${raw.runtimeType}',
              methodName: methodName,
            );
          }

          positional.add(_toColumn(raw.toList(growable: false)));
          continue;
        }

        positional.add(_toColumn(_wrapLikeValue(part, raw)));
      }
    }

    if (cursor < valueArgs.length) {
      throw QueryDerivationException(
        'Too many arguments for $methodName — consumed $cursor of ${valueArgs.length}',
        methodName: methodName,
      );
    }

    return BoundParameters(
      positional: List.unmodifiable(positional),
      named: const {},
      pageable: pageable,
      sort: sort,
    );
  }

  /// Binds [orderedArguments] for a `@Query`-declared [method].
  BoundParameters bindNamed(
    List<Object?> orderedArguments,
    Method method, {
    required String methodName,
    required String query,
  }) {
    final positional = <Object?>[];
    final named = <String, Object?>{};
    Pageable? pageable;
    Sort? sort;

    final parameters = method.getParameters().toList();
    for (var i = 0; i < orderedArguments.length && i < parameters.length; i++) {
      final argument = orderedArguments[i];
      final parameter = parameters[i];

      if (argument is Pageable) {
        pageable = argument;
        continue;
      }
      if (argument is Sort) {
        sort = argument;
        continue;
      }

      final paramAnnotation = parameter.getDirectAnnotation<Param>();
      final name = paramAnnotation?.getName() ?? parameter.getName();
      named[name] = _toColumn(argument);
    }

    for (var i = parameters.length; i < orderedArguments.length; i++) {
      positional.add(_toColumn(orderedArguments[i]));
    }

    return BoundParameters(
      positional: List.unmodifiable(positional),
      named: Map.unmodifiable(named),
      pageable: pageable,
      sort: sort,
    );
  }

  Object? _toColumn(Object? value) {
    if (value == null) return null;
    if (value is Iterable) {
      return value.map(_toColumn).toList(growable: false);
    }
    return _converters.toColumn(value, value.runtimeType);
  }

  Object? _wrapLikeValue(Part part, Object? value) {
    if (value is! String) return value;

    switch (part.getOperator()) {
      case PartOperator.startingWith:
        return '$value%';
      case PartOperator.endingWith:
        return '%$value';
      case PartOperator.containing:
      case PartOperator.notContaining:
        return '%$value%';
      default:
        return value;
    }
  }

  @override
  List<Object?> equalizedProperties() => [_converters];
}

final class _Unset {
  static final _Unset instance = _Unset._();
  const _Unset._();
}
