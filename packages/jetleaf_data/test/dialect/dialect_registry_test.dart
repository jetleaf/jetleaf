// test/dialect/dialect_registry_test.dart

import 'package:test/test.dart';
import 'package:jetleaf_core/lang.dart';
import 'package:jetleaf_data/jetleaf_data.dart';
import 'package:jetleaf_data/sqlite.dart';

import '../support/ensure_registry.dart';

void main() {
  setUpAll(ensureAotRegistered);

  test('built-in dialects are registered', () {
    final registry = DialectRegistry.getSharedInstance();
    expect(registry.supports('postgresql'), isTrue);
    expect(registry.supports('postgres'), isTrue);
    expect(registry.supports('mysql'), isTrue);
    expect(registry.supports('mariadb'), isTrue);
    expect(registry.supports('sqlite'), isTrue);
    expect(registry.supports('mongodb'), isTrue);
    expect(registry.supports('mongo'), isTrue);
  });

  test('unknown dialect throws with the available list', () {
    expect(
      () => DialectRegistry.getSharedInstance().get('cockroachdb'),
      throwsA(
        isA<IllegalArgumentException>().having(
          (e) => e.message,
          'message',
          contains('cockroachdb'),
        ),
      ),
    );
  });

  test('forUrl resolves known engines', () {
    final registry = DialectRegistry.getSharedInstance();
    expect(registry.forUrl('jdbc:postgresql://localhost:5432/app').getName(), 'postgresql');
    expect(registry.forUrl('mysql://root@localhost/app').getName(), 'mysql');
    expect(registry.forUrl('file:app.db').getName(), 'sqlite');
    expect(registry.forUrl(':memory:').getName(), 'sqlite');
    expect(registry.forUrl('mongodb://localhost:27017/app').getName(), 'mongodb');
  });

  test('forUrl throws for unknown engines', () {
    expect(
      () => DialectRegistry.getSharedInstance().forUrl('redis://localhost'),
      throwsA(isA<IllegalArgumentException>()),
    );
  });

  test('custom dialect can be registered without touching the framework', () {
    final registry = DialectRegistry();
    registry.register('mydb', () => const SqliteDialect());

    expect(registry.get('mydb'), isA<SqliteDialect>());
    expect(registry.supports('MYDB'), isTrue);
  });

  test('defaults registry is independent instances', () {
    final one = DialectRegistry.defaults();
    final two = DialectRegistry.defaults();

    one.register('only_one', () => const SqliteDialect());
    expect(two.supports('only_one'), isFalse);
  });
}
