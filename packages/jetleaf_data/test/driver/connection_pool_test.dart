// test/driver/connection_pool_test.dart

import 'dart:async';

import 'package:test/test.dart';
import 'package:jetleaf_data/jetleaf_data.dart';

import '../support/ensure_registry.dart';
import '../support/fake_database_client.dart';

void main() {
  setUpAll(ensureAotRegistered);

  group('DefaultConnectionPool', () {
    test('opens connections lazily up to the configured maximum', () async {
      var opened = 0;
      final pool = DefaultConnectionPool(
        clientFactory: () async {
          opened++;
          return FakeDatabaseClient();
        },
        configuration: const PoolConfiguration(maxConnections: 3),
      );

      final connections = <PooledConnection>[];
      for (var i = 0; i < 3; i++) {
        connections.add(await pool.getConnection());
      }

      expect(opened, 3);
      expect(pool.getActiveCount(), 3);
      expect(pool.getIdleCount(), 0);
      expect(pool.getMaxConnections(), 3);

      await pool.close();
    });

    test('reuses idle connections instead of opening new ones', () async {
      var opened = 0;
      final pool = DefaultConnectionPool(
        clientFactory: () async {
          opened++;
          return FakeDatabaseClient();
        },
        configuration: const PoolConfiguration(maxConnections: 2),
      );

      final first = await pool.getConnection();
      await first.close();
      expect(pool.getIdleCount(), 1);

      final second = await pool.getConnection();
      expect(opened, 1);
      expect(identical(first, second) || second.isOpen(), isTrue);

      await pool.close();
    });

    test('validates idle connections on checkout', () async {
      final clients = <FakeDatabaseClient>[];
      final pool = DefaultConnectionPool(
        clientFactory: () async {
          final client = FakeDatabaseClient();
          clients.add(client);
          return client;
        },
        configuration: const PoolConfiguration(maxConnections: 2, validateOnCheckout: true),
      );

      final connection = await pool.getConnection();
      await connection.close();

      await pool.getConnection();
      expect(clients.single.recorded.any((statement) => statement.sql == 'SELECT 1'), isTrue);

      await pool.close();
    });

    test('checkouts beyond capacity time out', () async {
      final pool = DefaultConnectionPool(
        clientFactory: () async => FakeDatabaseClient(),
        configuration: const PoolConfiguration(
          maxConnections: 1,
          connectionTimeout: Duration(milliseconds: 100),
        ),
      );

      await pool.getConnection();

      await expectLater(
        () => pool.getConnection(),
        throwsA(isA<CannotGetJdbcConnectionException>()),
      );

      await pool.close();
    });

    test('a released connection wakes the waiter', () async {
      final clients = <FakeDatabaseClient>[];
      final pool = DefaultConnectionPool(
        clientFactory: () async {
          final client = FakeDatabaseClient();
          clients.add(client);
          return client;
        },
        configuration: const PoolConfiguration(
          maxConnections: 1,
          connectionTimeout: Duration(seconds: 2),
        ),
      );

      final first = await pool.getConnection();
      final future = pool.getConnection();

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await first.close();

      final second = await future;
      expect(second.isOpen(), isTrue);

      await pool.close();
    });

    test('close shuts down idle connections', () async {
      final clients = <FakeDatabaseClient>[];
      final pool = DefaultConnectionPool(
        clientFactory: () async {
          final client = FakeDatabaseClient();
          clients.add(client);
          return client;
        },
        configuration: const PoolConfiguration(maxConnections: 2),
      );

      final connection = await pool.getConnection();
      await connection.close();
      expect(pool.getIdleCount(), 1);

      await pool.close();
      expect(clients.single.closeCount, 1);
    });

    test('an uncommitted transaction is rolled back when the lease returns', () async {
      final clients = <FakeDatabaseClient>[];
      final pool = DefaultConnectionPool(
        clientFactory: () async {
          final client = FakeDatabaseClient();
          clients.add(client);
          return client;
        },
        configuration: const PoolConfiguration(maxConnections: 1),
      );

      final connection = await pool.getConnection();
      await connection.beginTransaction();
      await connection.close();

      expect(clients.single.transactionRollbackCount, 1);
    });
  });
}