// test/support/fake_database_client.dart
//
// A recording fake driver for unit tests. It captures every statement and
// parameter list, and serves canned or fixture-backed responses — no real
// database required.

import 'dart:async';

import 'package:jetleaf_data/src/driver/database_client.dart';
import 'package:jetleaf_data/src/driver/query_result.dart';

/// A recorded invocation against the fake.
final class RecordedStatement {
  /// The SQL text (or debug rendering for document operations).
  final String sql;

  /// The bound parameters.
  final List<Object?> parameters;

  const RecordedStatement(this.sql, this.parameters);

  @override
  String toString() => 'RecordedStatement($sql, $parameters)';
}

/// Handler inspecting a statement and optionally answering it.
typedef StatementHandler = QueryResult? Function(
  String sql,
  List<Object?> parameters,
);

/// A fake [DatabaseClient] for unit tests.
final class FakeDatabaseClient extends DatabaseClient {
  /// Every statement executed, in order.
  final List<RecordedStatement> recorded = [];

  /// Handlers consulted in registration order — first non-null result wins.
  final List<StatementHandler> handlers = [];

  /// Rows served for any query not handled by [handlers].
  final List<Map<String, Object?>> defaultRows;

  /// Rows affected by mutation statements (unless a handler overrides).
  int defaultAffectedRows;

  /// Value returned by [lastInsertId].
  int? nextLastInsertId;

  /// Whether transactions were begun on this client.
  int transactionBeginCount = 0;

  /// Commits issued on this client.
  int transactionCommitCount = 0;

  /// Rollbacks issued on this client.
  int transactionRollbackCount = 0;

  /// Read-only flag observed on the delegate.
  bool? readOnlyFlag;

  /// Number of times [close] was called.
  int closeCount = 0;

  @override
  Future<void> close() async {
    closeCount++;
  }

  /// In-memory document collections for document-dialect tests.
  final Map<String, List<Map<String, Object?>>> collections = {};

  FakeDatabaseClient({
    List<Map<String, Object?>>? defaultRows,
    this.defaultAffectedRows = 1,
    this.nextLastInsertId,
  }) : defaultRows = List<Map<String, Object?>>.of(defaultRows ?? const []);

  /// Registers a [handler] that answers matching statements.
  void when(StatementHandler handler) => handlers.add(handler);

  /// Serves [rows] when the statement contains [fragment] (case-insensitive).
  void whenSqlContains(String fragment, List<Map<String, Object?>> rows) =>
      handlers.add((sql, params) {
        if (!sql.toLowerCase().contains(fragment.toLowerCase())) {
          return null;
        }

        return QueryResult.fromRows(rows);
      });

  /// Serves [rows] for the next query matching [fragment].
  void whenSqlContainsOnce(String fragment, List<Map<String, Object?>> rows) {
    late final StatementHandler handler;
    handler = (sql, params) {
      if (!sql.toLowerCase().contains(fragment.toLowerCase())) {
        return null;
      }

      handlers.remove(handler);
      return QueryResult.fromRows(rows);
    };

    handlers.add(handler);
  }

  @override
  bool supportsSql() => true;

  @override
  bool supportsDocuments() => true;

  @override
  Future<QueryResult> query(
    String sql, {
    List<Object?> parameters = const [],
  }) async {
    recorded.add(RecordedStatement(sql, List.unmodifiable(parameters)));

    for (final handler in handlers) {
      final result = handler(sql, parameters);
      if (result != null) {
        return result;
      }
    }

    return QueryResult.fromRows(defaultRows);
  }

  @override
  Future<int> execute(
    String sql, {
    List<Object?> parameters = const [],
  }) async {
    recorded.add(RecordedStatement(sql, List.unmodifiable(parameters)));

    for (final handler in handlers) {
      final result = handler(sql, parameters);
      if (result != null) {
        return result.getAffectedRows();
      }
    }

    return defaultAffectedRows;
  }

  @override
  Future<void> beginTransaction() async => transactionBeginCount++;

  @override
  Future<void> commitTransaction() async => transactionCommitCount++;

  @override
  Future<void> rollbackTransaction() async => transactionRollbackCount++;

  @override
  Future<void> setReadOnly(bool readOnly) async => readOnlyFlag = readOnly;

  @override
  Future<int?> lastInsertId() async => nextLastInsertId;

  // ---- document operations ------------------------------------------------

  @override
  Future<Map<String, Object?>> insertDocument(
    String collection,
    Map<String, Object?> document,
  ) async {
    recorded.add(RecordedStatement('insertOne $collection', [document]));
    final store = collections.putIfAbsent(collection, () => []);
    final inserted = Map<String, Object?>.from(document);
    inserted.putIfAbsent('_id', () => 'fake-${store.length + 1}');
    store.add(inserted);
    return inserted;
  }

  @override
  Future<int> updateDocuments(
    String collection,
    Map<String, Object?> filter,
    Map<String, Object?> update,
  ) async {
    recorded.add(RecordedStatement('updateMany $collection', [filter, update]));
    final set = update['\$set'] as Map<String, Object?>?;
    if (set == null) {
      return 0;
    }

    var affected = 0;
    for (final document in collections[collection] ?? <Map<String, Object?>>[]) {
      if (!_matchesFilter(document, filter)) {
        continue;
      }

      document.addAll(set);
      affected++;
    }

    return affected;
  }

  @override
  Future<int> deleteDocuments(
    String collection,
    Map<String, Object?> filter,
  ) async {
    recorded.add(RecordedStatement('deleteMany $collection', [filter]));
    final store = collections[collection];
    if (store == null) {
      return 0;
    }

    final before = store.length;
    store.removeWhere((document) => _matchesFilter(document, filter));
    return before - store.length;
  }

  @override
  Future<List<Map<String, Object?>>> findDocuments(
    String collection,
    Map<String, Object?> filter, {
    Map<String, Object?>? sort,
    int? limit,
    int? skip,
  }) async {
    recorded.add(RecordedStatement('find $collection', [filter]));
    var rows = (collections[collection] ?? const [])
        .where((document) => _matchesFilter(document, filter))
        .toList();

    if (sort != null) {
      rows.sort((left, right) {
        for (final entry in sort.entries) {
          final direction = (entry.value as num?)?.toInt() ?? 1;
          final leftValue = left[entry.key];
          final rightValue = right[entry.key];
          final comparison = _compareValues(leftValue, rightValue);
          if (comparison != 0) {
            return direction >= 0 ? comparison : -comparison;
          }
        }

        return 0;
      });
    }

    if (skip != null) {
      rows = rows.skip(skip).toList();
    }

    if (limit != null) {
      rows = rows.take(limit).toList();
    }

    return rows.map(Map<String, Object?>.from).toList(growable: false);
  }

  @override
  Future<int> countDocuments(
    String collection,
    Map<String, Object?> filter,
  ) async {
    recorded.add(RecordedStatement('countDocuments $collection', [filter]));
    return (collections[collection] ?? const [])
        .where((document) => _matchesFilter(document, filter))
        .length;
  }

  bool _matchesFilter(
    Map<String, Object?> document,
    Map<String, Object?> filter,
  ) {
    for (final entry in filter.entries) {
      final key = entry.key;
      if (key == '\$and') {
        return (entry.value as List).every(
          (clause) => _matchesFilter(document, clause as Map<String, Object?>),
        );
      }

      if (key == '\$or') {
        return (entry.value as List).any(
          (clause) => _matchesFilter(document, clause as Map<String, Object?>),
        );
      }

      final condition = entry.value;
      final actual = document[key];

      if (condition is Map<String, Object?>) {
        final regex = condition['\$regex'];
        if (regex != null) {
          if (actual is! String) {
            return false;
          }

          final options = condition['\$options']?.toString() ?? '';
          if (!RegExp(
            regex.toString(),
            caseSensitive: !options.contains('i'),
          ).hasMatch(actual)) {
            return false;
          }

          continue;
        }

        for (final op in condition.entries) {
          if (op.key == '\$options' || op.key == '\$regex') {
            continue;
          }

          if (!_matchesOperator(actual, op.key, op.value)) {
            return false;
          }
        }

        continue;
      }

      if (actual != condition) {
        return false;
      }
    }

    return true;
  }

  bool _matchesOperator(Object? actual, String operator, Object? expected) {
    switch (operator) {
      case '\$eq':
        return actual == expected;
      case '\$ne':
        return actual != expected;
      case '\$gt':
        return _compareValues(actual, expected) > 0;
      case '\$gte':
        return _compareValues(actual, expected) >= 0;
      case '\$lt':
        return _compareValues(actual, expected) < 0;
      case '\$lte':
        return _compareValues(actual, expected) <= 0;
      case '\$in':
        return (expected as List).contains(actual);
      case '\$nin':
        return !(expected as List).contains(actual);
      default:
        return actual == expected;
    }
  }

  int _compareValues(Object? left, Object? right) {
    if (left == null && right == null) {
      return 0;
    }

    if (left == null) {
      return -1;
    }

    if (right == null) {
      return 1;
    }

    if (left is num && right is num) {
      return left.compareTo(right);
    }

    if (left is DateTime && right is DateTime) {
      return left.compareTo(right);
    }

    return left.toString().compareTo(right.toString());
  }
}
