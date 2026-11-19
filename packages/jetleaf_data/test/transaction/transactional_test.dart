// test/transaction/transactional_test.dart

import 'dart:async';

import 'package:test/test.dart';
import 'package:jetleaf_core/lang.dart';
import 'package:jetleaf_core/intercept.dart';
import 'package:jetleaf_data/jetleaf_data.dart';

import '../support/ensure_registry.dart';
import '../support/fake_database_client.dart';

/// Records connections and hands them out on demand.
final class FakeConnectionFactory implements ConnectionFactory {
  final List<PooledConnection> created = [];

  @override
  Future<PooledConnection> getConnection() async {
    final client = FakeDatabaseClient();
    final connection = PooledConnection(client);
    created.add(connection);
    return connection;
  }

  @override
  Future<void> close() async {}

  @override
  int? getMaxConnections() => null;

  PooledConnection getLast() => created.last;
}

class TxService {
  int calls = 0;
  TransactionContext? observedContext;

  @Transactional()
  Future<int> increment(int by) async {
    calls++;
    observedContext = ZoneTransactionHolder.getCurrent();
    return calls + by;
  }

  Future<int> failing() async {
    throw StateError('boom');
  }

  @Transactional()
  Future<int> failingTransactional() async => failing();

  @Transactional(noRollbackFor: [ClassType<StateError>()])
  Future<int> exemptTransactional() async => failing();

  @Transactional(rollbackFor: [ClassType<FormatException>()])
  Future<int> narrowRollback() async => failing();

  @Transactional(readOnly: true)
  Future<int> readOnlyTx() async {
    observedContext = ZoneTransactionHolder.getCurrent();
    return 1;
  }
}

void main() {
  setUpAll(ensureAotRegistered);

  late DataSourceTransactionManager manager;
  late FakeConnectionFactory factory;

  setUp(() {
    factory = FakeConnectionFactory();
    manager = DataSourceTransactionManager(factory);
  });

  TransactionDefinition def({
    Propagation propagation = Propagation.required,
    List<ClassType<dynamic>>? rollbackFor,
    List<ClassType<dynamic>>? noRollbackFor,
    bool readOnly = false,
  }) =>
      DefaultTransactionDefinition(
        propagation: propagation,
        rollbackFor: rollbackFor ?? const [ClassType<Exception>()],
        noRollbackFor: noRollbackFor ?? const [],
        readOnly: readOnly,
      );

  group('propagation', () {
    test('required creates a new transaction when none exists', () async {
      final status = await manager.getTransaction(def());

      expect(status.isNewTransaction(), isTrue);
      expect(factory.created, hasLength(1));
      expect((factory.created.single.getDelegate() as FakeDatabaseClient).transactionBeginCount, 1);
      await manager.commit(status);
    });

    test('required joins an existing transaction', () async {
      final outer = await manager.getTransaction(def());
      final outerContext = outer.getContext();

      TransactionStatus? inner;
      await ZoneTransactionHolder.run(outerContext, () async {
        inner = await manager.getTransaction(def());
      });

      expect(inner!.isNewTransaction(), isFalse);
      expect(inner!.getContext(), same(outerContext));
      expect(factory.created, hasLength(1));
      await manager.rollback(inner!);
      await manager.rollback(outer);
    });

    test('requiresNew creates an independent transaction', () async {
      final outer = await manager.getTransaction(def());
      final outerContext = outer.getContext();

      TransactionStatus? inner;
      await ZoneTransactionHolder.run(outerContext, () async {
        inner = await manager.getTransaction(def(propagation: Propagation.requiresNew));
      });

      expect(inner!.isNewTransaction(), isTrue);
      expect(factory.created, hasLength(2));
      expect(inner!.getContext(), isNot(same(outerContext)));
      await manager.rollback(inner!);
      await manager.rollback(outer);
    });

    test('mandatory throws without an existing transaction', () async {
      await expectLater(
        () => manager.getTransaction(def(propagation: Propagation.mandatory)),
        throwsA(isA<MandatoryTransactionException>()),
      );
    });

    test('mandatory joins an existing transaction', () async {
      final outer = await manager.getTransaction(def());
      final outerContext = outer.getContext();

      TransactionStatus? inner;
      await ZoneTransactionHolder.run(outerContext, () async {
        inner = await manager.getTransaction(def(propagation: Propagation.mandatory));
      });

      expect(inner!.isNewTransaction(), isFalse);
      await manager.rollback(inner!);
      await manager.rollback(outer);
    });

    test('never throws with an existing transaction', () async {
      final outer = await manager.getTransaction(def());
      final outerContext = outer.getContext();

      await ZoneTransactionHolder.run(outerContext, () async {
        await expectLater(
          () => manager.getTransaction(def(propagation: Propagation.never)),
          throwsA(isA<TransactionSystemException>()),
        );
      });
      await manager.rollback(outer);
    });

    test('never runs without a transaction', () async {
      final status = await manager.getTransaction(def(propagation: Propagation.never));
      expect(status.isNewTransaction(), isFalse);
      expect(status.getContext(), isNull);
      await manager.commit(status);
    });

    test('supports joins when a transaction exists', () async {
      final outer = await manager.getTransaction(def());
      final outerContext = outer.getContext();

      TransactionStatus? inner;
      await ZoneTransactionHolder.run(outerContext, () async {
        inner = await manager.getTransaction(def(propagation: Propagation.supports));
      });

      expect(inner!.getContext(), same(outerContext));
      await manager.rollback(inner!);
      await manager.rollback(outer);
    });

    test('supports runs unbound otherwise', () async {
      final status = await manager.getTransaction(def(propagation: Propagation.supports));
      expect(status.getContext(), isNull);
      await manager.commit(status);
      expect(factory.created, isEmpty);
    });

    test('notSupported runs unbound and shadows the ambient transaction', () async {
      final outer = await manager.getTransaction(def());
      final outerContext = outer.getContext();

      TransactionContext? innerContext = outerContext;
      await ZoneTransactionHolder.run(outerContext, () async {
        final status = await manager.getTransaction(def(propagation: Propagation.notSupported));
        expect(status.getContext(), isNull);
        await ZoneTransactionHolder.run(null, () async {
          innerContext = ZoneTransactionHolder.getCurrent();
        });
        await manager.commit(status);
      });

      expect(innerContext, isNull);
      await manager.rollback(outer);
    });
  });

  group('rollback semantics', () {
    test('commit issues COMMIT on the delegate connection', () async {
      final status = await manager.getTransaction(def());
      await manager.commit(status);

      final client = factory.created.single.getDelegate() as FakeDatabaseClient;
      expect(client.transactionCommitCount, 1);
      expect(client.transactionRollbackCount, 0);
    });

    test('rollback issues ROLLBACK on the delegate connection', () async {
      final status = await manager.getTransaction(def());
      await manager.rollback(status);

      final client = factory.created.single.getDelegate() as FakeDatabaseClient;
      expect(client.transactionRollbackCount, 1);
      expect(client.transactionCommitCount, 0);
    });

    test('joined participant rollback-marks instead of rolling back physically', () async {
      final outer = await manager.getTransaction(def());
      final outerContext = outer.getContext();

      await ZoneTransactionHolder.run(outerContext, () async {
        final inner = await manager.getTransaction(def());
        await manager.rollback(inner);
      });

      final client = factory.created.single.getDelegate() as FakeDatabaseClient;
      expect(client.transactionRollbackCount, 0);
      expect(outerContext!.isRollbackOnly(), isTrue);
      await manager.commit(outer);

      expect(client.transactionRollbackCount, 1);
      expect(client.transactionCommitCount, 0);
    });

    test('outer commit honors inner rollback-only mark', () async {
      final outer = await manager.getTransaction(def());

      await ZoneTransactionHolder.run(outer.getContext(), () async {
        final inner = await manager.getTransaction(def());
        inner.setRollbackOnly();
      });

      await manager.commit(outer);

      final client = factory.created.single.getDelegate() as FakeDatabaseClient;
      expect(client.transactionCommitCount, 0);
      expect(client.transactionRollbackCount, 1);
    });

    test('readOnly marks the connection read-only', () async {
      final status = await manager.getTransaction(def(readOnly: true));
      await manager.commit(status);

      final client = factory.created.single.getDelegate() as FakeDatabaseClient;
      expect(client.readOnlyFlag, isTrue);
    });

    test('connection released back to the factory after commit', () async {
      final status = await manager.getTransaction(def());
      await manager.commit(status);

      expect(factory.created.single.isOpen(), isFalse);
    });

    test('connection released back to the factory after rollback', () async {
      final status = await manager.getTransaction(def());
      await manager.rollback(status);

      expect(factory.created.single.isOpen(), isFalse);
    });
  });

  group('PooledConnection lease semantics', () {
    test('returning a lease with an open transaction rolls it back', () async {
      final connection = await factory.getConnection();
      await connection.beginTransaction();
      await connection.close();

      final client = connection.getDelegate() as FakeDatabaseClient;
      expect(client.transactionRollbackCount, 1);
    });

    test('using a closed lease throws StateError', () async {
      final connection = await factory.getConnection();
      await connection.close();

      expect(() => connection.query('SELECT 1'), throwsA(isA<StateError>()));
    });

    test('closing twice is a no-op', () async {
      final connection = await factory.getConnection();
      await connection.close();
      await connection.close();
    });
  });

  group('@Transactional interceptor', () {
    late TransactionalMethodInterceptor interceptor;
    late TxService service;

    setUp(() {
      interceptor = TransactionalMethodInterceptor(manager);
      service = TxService();
    });

    Future<T> call<T>(
      String methodName,
      Future<T> Function(TxService service) body, {
      bool transactional = true,
    }) async {
      final method = Class<TxService>().getMethod(methodName)!;
      final targetClass = Class<TxService>();
      final result = await interceptor.aroundInvocation<T>(
        SimpleMethodInvocation<T>(
          service,
          targetClass,
          method,
          null,
          () => body(service),
        ),
      );
      return result as T;
    }

    test('commits on a clean exit and binds the transaction into the zone', () async {
      final result = await call<int>('increment', (service) => service.increment(1));

      expect(result, 2);
      expect(service.calls, 1);
      expect(service.observedContext, isNotNull);

      final client = factory.created.single.getDelegate() as FakeDatabaseClient;
      expect(client.transactionCommitCount, 1);
      expect(client.transactionRollbackCount, 0);
    });

    test('does not leak the transaction to the caller zone', () async {
      await call<int>('increment', (service) => service.increment(1));

      expect(ZoneTransactionHolder.getCurrent(), isNull);
    });

    test('rolls back when a matching exception escapes', () async {
      await expectLater(
        () => call<int>('failingTransactional', (service) => service.failingTransactional()),
        throwsA(isA<StateError>()),
      );

      final client = factory.created.single.getDelegate() as FakeDatabaseClient;
      expect(client.transactionRollbackCount, 1);
      expect(client.transactionCommitCount, 0);
    });

    test('noRollbackFor exempts matching exceptions from rollback', () async {
      await expectLater(
        () => call<int>('exemptTransactional', (service) => service.exemptTransactional()),
        throwsA(isA<StateError>()),
      );

      final client = factory.created.single.getDelegate() as FakeDatabaseClient;
      expect(client.transactionCommitCount, 1);
      expect(client.transactionRollbackCount, 0);
    });

    test('narrow rollbackFor spares non-matching exceptions', () async {
      await expectLater(
        () => call<int>('narrowRollback', (service) => service.narrowRollback()),
        throwsA(isA<StateError>()),
      );

      final client = factory.created.single.getDelegate() as FakeDatabaseClient;
      expect(client.transactionCommitCount, 1);
      expect(client.transactionRollbackCount, 0);
    });

    test('readOnly transactional methods are honored', () async {
      await call<int>('readOnlyTx', (service) => service.readOnlyTx());

      final client = factory.created.single.getDelegate() as FakeDatabaseClient;
      expect(client.readOnlyFlag, isTrue);
    });

    test('throws TransactionSystemException when no manager is bound', () async {
      final unbound = TransactionalMethodInterceptor();
      final method = Class<TxService>().getMethod('increment')!;
      final targetClass = Class<TxService>();

      await expectLater(
        () => unbound.aroundInvocation<int>(
          SimpleMethodInvocation<int>(
            service,
            targetClass,
            method,
            null,
            () async => 1,
          ),
        ),
        throwsA(isA<TransactionSystemException>()),
      );
    });

    test('canIntercept reflects @Transactional on the method', () {
      final increment = Class<TxService>().getMethod('increment')!;
      final failing = Class<TxService>().getMethod('failing')!;

      expect(interceptor.canIntercept(increment), isTrue);
      expect(interceptor.canIntercept(failing), isFalse);
    });
  });
}
