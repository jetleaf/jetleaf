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

import '../annotation/transactional.dart';
import 'transaction_definition.dart';

/// {@template jetleaf_default_transaction_definition}
/// Immutable default implementation of [TransactionDefinition].
///
/// Defaults to `Propagation.required`, `Isolation.readCommitted`, a 30-second
/// timeout, read-write execution, and rollback on any [Exception] or [Error].
/// {@endtemplate}
final class DefaultTransactionDefinition with EqualsAndHashCode implements TransactionDefinition {
  /// Reflective [Class] handle for [DefaultTransactionDefinition].
  static final Class<DefaultTransactionDefinition> CLASS = Class<DefaultTransactionDefinition>(null, PackageNames.DATA);

  final Propagation _propagation;
  final Isolation _isolation;
  final int _timeoutSeconds;
  final bool _readOnly;
  final List<ClassType<dynamic>> _rollbackFor;
  final List<ClassType<dynamic>> _noRollbackFor;
  final String? _name;

  /// {@macro jetleaf_default_transaction_definition}
  const DefaultTransactionDefinition({
    Propagation propagation = Propagation.required,
    Isolation isolation = Isolation.readCommitted,
    int timeoutSeconds = 30,
    bool readOnly = false,
    List<ClassType<dynamic>> rollbackFor = const [
      ClassType<Exception>(),
      ClassType<Error>(),
    ],
    List<ClassType<dynamic>> noRollbackFor = const [],
    String? name,
  })  : _propagation = propagation,
        _isolation = isolation,
        _timeoutSeconds = timeoutSeconds,
        _readOnly = readOnly,
        _rollbackFor = rollbackFor,
        _noRollbackFor = noRollbackFor,
        _name = name;

  @override
  Propagation getPropagation() => _propagation;

  @override
  Isolation getIsolation() => _isolation;

  @override
  int getTimeoutSeconds() => _timeoutSeconds;

  @override
  bool isReadOnly() => _readOnly;

  @override
  List<ClassType<dynamic>> getRollbackFor() => _rollbackFor;

  @override
  List<ClassType<dynamic>> getNoRollbackFor() => _noRollbackFor;

  @override
  String? getName() => _name;

  @override
  List<Object?> equalizedProperties() => [
    _propagation,
    _isolation,
    _timeoutSeconds,
    _readOnly,
    _rollbackFor,
    _noRollbackFor,
    _name,
  ];
}