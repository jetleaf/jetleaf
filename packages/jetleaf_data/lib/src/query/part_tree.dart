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

import '../exception/data_access_exception.dart';
import '../mapping/default_entity_metadata_registry.dart';
import '../mapping/entity_metadata.dart';
import '../mapping/entity_metadata_registry.dart';
import '../paging/sort.dart';
import 'criterion.dart';
import 'part.dart';
import 'part_subject.dart';

export 'criterion.dart';
export 'part_subject.dart';

/// {@template jetleaf_part_tree}
/// AST parser and representation of a **derived repository query method name**.
///
/// ### Supported Grammar
/// ```text
/// method     := subject [Distinct]? [(Top|First)[0-9]*]? ('All' | 'By' predicate)? ('OrderBy' order+)?
/// subject    := find | read | get | query | count | exists | delete | remove
/// predicate  := andGroup ('Or' andGroup)*
/// andGroup   := part ('And' part)*
/// part       := propertyPath operator? ('IgnoreCase')?
/// order      := propertyPath ('Asc' | 'Desc')?
/// ```
///
/// ### Usage Example
/// ```dart
/// final tree = PartTree.parse(
///   'findTop5ByAgeGreaterThanEqualAndActiveTrueOrderByCreatedAtDesc',
///   metadata: userMetadata,
/// );
/// print(tree.getLimit()); // 5
/// print(tree.getParameterCount()); // 1
/// ```
///
/// ### See Also
/// - [Part]
/// - [PartOperator]
/// - [PartSubject]
/// - [Criterion]
/// {@endtemplate}
final class PartTree with EqualsAndHashCode {
  /// Reflective [Class] handle for [PartTree].
  static final Class<PartTree> CLASS = Class<PartTree>(null, PackageNames.DATA);

  final PartSubject _subject;
  final bool _distinct;
  final int? _limit;
  final Criterion? _predicate;
  final Sort _sort;

  /// {@macro jetleaf_part_tree}
  const PartTree({
    required PartSubject subject,
    required bool distinct,
    required Criterion? predicate,
    required Sort sort,
    int? limit,
  })  : _subject = subject,
        _distinct = distinct,
        _predicate = predicate,
        _sort = sort,
        _limit = limit;

  /// Returns the [PartSubject] verb of this query.
  PartSubject getSubject() => _subject;

  /// Returns `true` if `Distinct` was specified in the method name.
  bool isDistinct() => _distinct;

  /// Returns the `Top`/`First` row limit, if specified.
  int? getLimit() => _limit;

  /// Returns the root [Criterion] predicate tree, or `null` when unconditional.
  Criterion? getPredicate() => _predicate;

  /// Returns the [Sort] specification extracted from `OrderBy`.
  Sort getSort() => _sort;

  /// Returns the total number of method arguments consumed by [getPredicate].
  int getParameterCount() =>
      _predicate?.getParts().fold<int>(
            0,
            (sum, part) => sum + part.getParameterCount(),
          ) ??
      0;

  /// Returns `true` if this is a `count` query.
  bool isCount() => _subject.isCount();

  /// Returns `true` if this is an `exists` query.
  bool isExists() => _subject.isExists();

  /// Returns `true` if this is a `delete`/`remove` query.
  bool isDelete() => _subject.isDelete();

  /// Returns `true` if this is a `select` query.
  bool isSelect() => _subject.isSelect();

  /// Returns the flattened list of leaf [Part]s in parameter binding order.
  List<Part> getParts() => _predicate?.getParts().toList() ?? const [];

  @override
  List<Object?> equalizedProperties() => [
        _subject,
        _distinct,
        _predicate,
        _sort,
        _limit,
      ];

  // ---------------------------------------------------------------------------
  // Parser Implementation
  // ---------------------------------------------------------------------------

  /// Parses [methodName] into a [PartTree] validated against [metadata].
  ///
  /// Uses [metadataRegistry] (or [DefaultEntityMetadataRegistry.instance]) to
  /// resolve nested relationship paths.
  static PartTree parse(
    String methodName, {
    required EntityMetadata<dynamic> metadata,
    EntityMetadataRegistry? metadataRegistry,
  }) {
    final registry = metadataRegistry ?? DefaultEntityMetadataRegistry.instance;
    var remaining = methodName;

    // 1. Subject prefix
    PartSubject? subject;
    for (final candidate in _subjectsByDescendingLength) {
      if (remaining.startsWith(candidate.keyword)) {
        subject = candidate.subject;
        remaining = remaining.substring(candidate.keyword.length);
        break;
      }
    }

    if (subject == null) {
      throw QueryDerivationException(
        'Method "$methodName" does not start with a recognized subject '
        '(find/read/get/query/count/exists/delete/remove)',
        methodName: methodName,
      );
    }

    // 1.5. Conventional `...All` no-predicate form
    if (remaining == 'All') {
      remaining = '';
    } else if (remaining.startsWith('AllOrderBy')) {
      remaining = remaining.substring('All'.length);
    }

    // 2. Optional Distinct
    var distinct = false;
    if (remaining.startsWith('Distinct')) {
      distinct = true;
      remaining = remaining.substring('Distinct'.length);
    }

    // 3. Optional TopN / FirstN
    int? limit;
    for (final prefix in const ['Top', 'First']) {
      if (remaining.startsWith(prefix)) {
        var rest = remaining.substring(prefix.length);
        final digits = _leadingDigits(rest);
        if (digits != null) {
          limit = int.parse(digits);
          rest = rest.substring(digits.length);
          if (limit <= 0) {
            throw QueryDerivationException(
              'Method "$methodName" — $prefix limit must be positive',
              methodName: methodName,
            );
          }
        } else {
          limit = 1;
        }

        remaining = rest;
        break;
      }
    }

    // 4. Split OrderBy
    var predicateSource = '';
    var orderBySource = '';

    final orderByIndex = remaining.indexOf('OrderBy');
    if (orderByIndex >= 0) {
      predicateSource = remaining.substring(0, orderByIndex);
      orderBySource = remaining.substring(orderByIndex + 'OrderBy'.length);
    } else {
      predicateSource = remaining;
    }

    // 5. "By" separator
    String? segmentSource;
    if (predicateSource.isEmpty) {
      segmentSource = null;
    } else if (predicateSource.startsWith('By')) {
      segmentSource = predicateSource.substring('By'.length);
      if (segmentSource.isEmpty) {
        if (orderByIndex >= 0) {
          segmentSource = null;
        } else {
          throw QueryDerivationException(
            'Method "$methodName" — expected at least one property after "By"',
            methodName: methodName,
          );
        }
      }
    } else {
      throw QueryDerivationException(
        'Method "$methodName" — expected "By" after the '
        '${distinct ? 'distinct ' : ''}${limit != null ? 'top/first ' : ''}'
        'subject, found "$predicateSource"',
        methodName: methodName,
      );
    }

    // 6. Parse predicate
    final predicate = segmentSource == null || segmentSource.isEmpty
        ? null
        : _parsePredicate(segmentSource, metadata, methodName, registry);

    // 7. Parse ordering
    final sort = _parseOrderBy(orderBySource, metadata, methodName, registry);

    return PartTree(
      subject: subject,
      distinct: distinct,
      predicate: predicate,
      sort: sort,
      limit: limit,
    );
  }

  static Criterion? _parsePredicate(
    String source,
    EntityMetadata<dynamic> metadata,
    String methodName,
    EntityMetadataRegistry registry,
  ) {
    final tokens = <String>[];
    final buffer = StringBuffer();
    var i = 0;

    while (i < source.length) {
      final matched = _matchConnectiveAt(source, i);
      if (matched != null) {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
        tokens.add(matched);
        i += matched.length;
        continue;
      }
      buffer.write(source[i]);
      i++;
    }

    if (buffer.isNotEmpty) {
      tokens.add(buffer.toString());
    }

    final orChildren = <Criterion>[];
    final andChildren = <Criterion>[];

    void flushAnd() {
      if (andChildren.isEmpty) return;
      orChildren.add(
        andChildren.length == 1
            ? andChildren.first
            : CompositeCriterion.and(andChildren),
      );
      andChildren.clear();
    }

    var lastWasConnective = false;
    for (final token in tokens) {
      if (token == 'And' || token == 'Or') {
        if ((andChildren.isEmpty && orChildren.isEmpty) || lastWasConnective) {
          throw QueryDerivationException(
            'Unexpected "$token" in predicate of "$methodName"',
            methodName: methodName,
          );
        }
        lastWasConnective = true;
        if (token == 'Or') {
          flushAnd();
        }
        continue;
      }

      lastWasConnective = false;
      final part = _parseSegment(token, metadata, methodName, registry);
      andChildren.add(PartCriterion(part));
    }

    if (lastWasConnective) {
      throw QueryDerivationException(
        'Predicate of "$methodName" ends with a dangling And/Or',
        methodName: methodName,
      );
    }

    flushAnd();

    if (orChildren.isEmpty) return null;
    return orChildren.length == 1
        ? orChildren.first
        : CompositeCriterion.or(orChildren);
  }

  static Part _parseSegment(
    String segment,
    EntityMetadata<dynamic> metadata,
    String methodName,
    EntityMetadataRegistry registry,
  ) {
    if (segment.isEmpty) {
      throw QueryDerivationException(
        'Empty predicate segment in "$methodName"',
        methodName: methodName,
      );
    }

    var remaining = segment;

    var ignoreCase = false;
    if (remaining.endsWith('IgnoreCase')) {
      ignoreCase = true;
      remaining =
          remaining.substring(0, remaining.length - 'IgnoreCase'.length);
      if (remaining.isEmpty) {
        throw QueryDerivationException(
          '"IgnoreCase" without a property in "$methodName"',
          methodName: methodName,
        );
      }
    }

    for (final candidate in PartOperator.byDescendingKeywordLength) {
      if (remaining.endsWith(candidate.keyword)) {
        final property =
            remaining.substring(0, remaining.length - candidate.keyword.length);
        if (property.isEmpty) {
          continue;
        }

        final operator = candidate.operator;
        if (ignoreCase &&
            !operator.isLikeFamily() &&
            operator != PartOperator.equals &&
            operator != PartOperator.notEquals) {
          throw QueryDerivationException(
            '"IgnoreCase" is only supported on string comparison operators, '
            'not ${operator.getKeyword()} in "$methodName"',
            methodName: methodName,
          );
        }

        final resolved =
            _resolvePropertyPath(property, metadata, methodName, registry);
        return Part(
          property: resolved,
          operator: operator,
          ignoreCase: ignoreCase,
        );
      }
    }

    final resolved =
        _resolvePropertyPath(remaining, metadata, methodName, registry);
    return Part(
      property: resolved,
      operator: PartOperator.equals,
      ignoreCase: ignoreCase,
    );
  }

  static String _resolvePropertyPath(
    String raw,
    EntityMetadata<dynamic> metadata,
    String methodName,
    EntityMetadataRegistry registry,
  ) {
    final path = <String>[];
    var current = metadata;
    var remaining = raw;

    while (remaining.isNotEmpty) {
      final candidates = <_PropertyCandidate>[];
      for (final column in current.getColumns()) {
        candidates.add(
          _PropertyCandidate(
            name: column.getProperty(),
            normalized: _normalize(column.getProperty()),
            isRelationship: false,
          ),
        );
      }

      for (final relationship in current.getRelationships()) {
        candidates.add(
          _PropertyCandidate(
            name: relationship.getProperty(),
            normalized: _normalize(relationship.getProperty()),
            isRelationship: true,
          ),
        );
      }

      candidates
          .sort((a, b) => b.normalized.length.compareTo(a.normalized.length));

      _PropertyCandidate? matched;
      final remainingNormalized = _normalize(remaining);
      for (final candidate in candidates) {
        if (remainingNormalized.startsWith(candidate.normalized)) {
          matched = candidate;
          break;
        }
      }

      if (matched == null) {
        final fragment =
            remaining.length <= 32 ? remaining : remaining.substring(0, 32);
        throw QueryDerivationException(
          'No property "$fragment" on ${current.getSimpleName()} (parsing "$methodName")',
          methodName: methodName,
        );
      }

      path.add(matched.name);
      remaining = _consumeRaw(remaining, matched.normalized.length);

      if (remaining.isNotEmpty) {
        if (!matched.isRelationship) {
          throw QueryDerivationException(
            'Property "${matched.name}" on ${current.getSimpleName()} is not navigable — cannot continue path "$raw"',
            methodName: methodName,
          );
        }

        final relationship = current.getRelationshipByProperty(matched.name);
        try {
          current = registry.getForType(relationship!.getTargetEntity());
        } on Object catch (error) {
          throw QueryDerivationException(
            'Cannot resolve relationship "${matched.name}" (target ${relationship!.getTargetEntity()}): $error',
            methodName: methodName,
          );
        }
      }
    }

    return path.join('.');
  }

  static String _normalize(String value) =>
      value.toLowerCase().replaceAll('_', '');

  static String _consumeRaw(String raw, int normalizedLength) {
    var consumed = 0;
    var normalized = 0;

    while (consumed < raw.length && normalized < normalizedLength) {
      final char = raw[consumed];
      if (char != '_' && char != '-') {
        normalized++;
      }
      consumed++;
    }

    return raw.substring(consumed);
  }

  static Sort _parseOrderBy(
    String source,
    EntityMetadata<dynamic> metadata,
    String methodName,
    EntityMetadataRegistry registry,
  ) {
    if (source.isEmpty) {
      return Sort.UNSORTED;
    }

    final orders = <SortOrder>[];
    var remaining = source;

    while (remaining.isNotEmpty) {
      final resolution =
          _resolveLeadingPath(remaining, metadata, methodName, registry);
      remaining = remaining.substring(resolution.consumed);

      var direction = SortDirection.ASC;
      if (remaining.startsWith('Desc')) {
        direction = SortDirection.DESC;
        remaining = remaining.substring('Desc'.length);
      } else if (remaining.startsWith('Asc')) {
        remaining = remaining.substring('Asc'.length);
      }

      orders.add(SortOrder(resolution.path, direction: direction));
    }

    return Sort.by(orders);
  }

  static ({String path, int consumed}) _resolveLeadingPath(
    String source,
    EntityMetadata<dynamic> metadata,
    String methodName,
    EntityMetadataRegistry registry,
  ) {
    var current = metadata;
    var remaining = source;
    var consumed = 0;
    final segments = <String>[];

    while (true) {
      if (segments.length >= _maxNestingDepth) {
        break;
      }

      final candidates = <_PropertyCandidate>[];
      for (final column in current.getColumns()) {
        candidates.add(
          _PropertyCandidate(
            name: column.getProperty(),
            normalized: _normalize(column.getProperty()),
            isRelationship: false,
          ),
        );
      }

      for (final relationship in current.getRelationships()) {
        candidates.add(
          _PropertyCandidate(
            name: relationship.getProperty(),
            normalized: _normalize(relationship.getProperty()),
            isRelationship: true,
          ),
        );
      }

      candidates
          .sort((a, b) => b.normalized.length.compareTo(a.normalized.length));

      final remainingNormalized = _normalize(remaining);
      _PropertyCandidate? matched;
      for (final candidate in candidates) {
        if (remainingNormalized.startsWith(candidate.normalized)) {
          matched = candidate;
          break;
        }
      }

      if (matched == null) {
        break;
      }

      segments.add(matched.name);
      final taken = _consumeRaw(remaining, matched.normalized.length);
      consumed += remaining.length - taken.length;
      remaining = taken;

      if (remaining.isEmpty || !matched.isRelationship) {
        break;
      }

      final relationship = current.getRelationshipByProperty(matched.name);
      if (relationship == null) {
        break;
      }

      try {
        current = registry.getForType(relationship.getTargetEntity());
      } catch (_) {
        break;
      }
    }

    if (segments.isEmpty) {
      throw QueryDerivationException(
        'No property found at "$source" on ${metadata.getSimpleName()} (OrderBy clause of "$methodName")',
        methodName: methodName,
      );
    }

    return (path: segments.join('.'), consumed: consumed);
  }

  static const int _maxNestingDepth = 4;

  static String? _leadingDigits(String value) {
    var end = 0;
    while (end < value.length && _isDigitCode(value.codeUnitAt(end))) {
      end++;
    }
    return end == 0 ? null : value.substring(0, end);
  }

  static bool _isDigitCode(int unit) => unit >= 48 && unit <= 57;

  static String? _matchConnectiveAt(String source, int index) {
    for (final connective in const ['And', 'Or']) {
      if (source.startsWith(connective, index)) {
        final afterIndex = index + connective.length;
        final after = afterIndex >= source.length ? null : source[afterIndex];
        if (after == null || _isUpper(after)) {
          return connective;
        }
      }
    }
    return null;
  }

  static bool _isUpper(String c) =>
      c == c.toUpperCase() && c != c.toLowerCase();

  static final List<_SubjectCandidate> _subjectsByDescendingLength =
      List<_SubjectCandidate>.unmodifiable(
    [
      const _SubjectCandidate('exists', PartSubject.exists),
      const _SubjectCandidate('delete', PartSubject.delete),
      const _SubjectCandidate('remove', PartSubject.remove),
      const _SubjectCandidate('count', PartSubject.count),
      const _SubjectCandidate('query', PartSubject.query),
      const _SubjectCandidate('find', PartSubject.find),
      const _SubjectCandidate('read', PartSubject.read),
      const _SubjectCandidate('get', PartSubject.get),
    ]..sort((a, b) => b.keyword.length.compareTo(a.keyword.length)),
  );
}

final class _PropertyCandidate {
  final String name;
  final String normalized;
  final bool isRelationship;

  const _PropertyCandidate({
    required this.name,
    required this.normalized,
    required this.isRelationship,
  });
}

final class _SubjectCandidate {
  final String keyword;
  final PartSubject subject;

  const _SubjectCandidate(this.keyword, this.subject);
}
