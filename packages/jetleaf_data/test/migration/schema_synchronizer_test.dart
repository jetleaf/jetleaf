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

import 'package:jetleaf_data/jetleaf_data.dart';
import 'package:jetleaf_data/sqlite.dart';
import 'package:test/test.dart';

import '../support/ensure_registry.dart';
import '../support/fake_database_client.dart';

@Entity()
@Table(name: 'sync_users')
class SyncUser {
  @Id()
  @GeneratedValue(strategy: GenerationStrategy.autoIncrement)
  int? id;

  @Column(nullable: false)
  String? email;

  String? displayName;
}

void main() {
  setUpAll(ensureAotRegistered);

  group('AutoSchemaSynchronizer', () {
    test('DdlAutoMode.parse parses supported modes and rejects invalid ones', () {
      expect(DdlAutoMode.parse('none'), DdlAutoMode.none);
      expect(DdlAutoMode.parse('validate'), DdlAutoMode.validate);
      expect(DdlAutoMode.parse('update'), DdlAutoMode.update);
      expect(DdlAutoMode.parse('create'), DdlAutoMode.create);
      expect(DdlAutoMode.parse('create-drop'), DdlAutoMode.createDrop);
      expect(() => DdlAutoMode.parse('invalid'), throwsA(isA<MigrationException>()));
    });

    test('update mode creates table when missing', () async {
      final client = FakeDatabaseClient();
      final synchronizer = AutoSchemaSynchronizer(
        client: client,
        dialect: const SqliteDialect(),
        mode: DdlAutoMode.update,
      );

      final result = await synchronizer.synchronize([SyncUser]);

      expect(result.getTablesCreated(), ['sync_users']);
      expect(result.getColumnsAdded(), isEmpty);
      expect(
        client.recorded.any((s) => s.sql.startsWith('CREATE TABLE IF NOT EXISTS "sync_users"')),
        isTrue,
      );
    });

    test('update mode issues ALTER TABLE ADD COLUMN for newly added entity fields', () async {
      final client = FakeDatabaseClient()
        ..handlers.add((sql, _) {
          if (sql == 'PRAGMA table_info("sync_users")') {
            return QueryResult(rows: [
              {'name': 'id'},
              {'name': 'email'},
            ]);
          }
          return null;
        });
      final synchronizer = AutoSchemaSynchronizer(
        client: client,
        dialect: const SqliteDialect(),
        mode: DdlAutoMode.update,
      );

      final result = await synchronizer.synchronize([SyncUser]);

      expect(result.getTablesCreated(), isEmpty);
      expect(result.getColumnsAdded(), ['sync_users.display_name']);
      expect(
        client.recorded.map((s) => s.sql),
        contains('ALTER TABLE "sync_users" ADD COLUMN "display_name" TEXT'),
      );
    });

    test('createDrop mode creates on synchronize and drops on dropAll', () async {
      final client = FakeDatabaseClient();
      final synchronizer = AutoSchemaSynchronizer(
        client: client,
        dialect: const SqliteDialect(),
        mode: DdlAutoMode.createDrop,
      );

      await synchronizer.synchronize([SyncUser]);
      await synchronizer.dropAll([SyncUser]);

      expect(client.recorded.first.sql, 'DROP TABLE IF EXISTS "sync_users"');
      expect(client.recorded.last.sql, 'DROP TABLE IF EXISTS "sync_users"');
    });

    test('validate mode throws MigrationException when a column is missing', () async {
      final client = FakeDatabaseClient()
        ..handlers.add((sql, _) {
          if (sql == 'PRAGMA table_info("sync_users")') {
            return QueryResult(rows: [
              {'name': 'id'},
              {'name': 'email'},
            ]);
          }
          return null;
        });
      final synchronizer = AutoSchemaSynchronizer(
        client: client,
        dialect: const SqliteDialect(),
        mode: DdlAutoMode.validate,
      );

      expect(
        () => synchronizer.synchronize([SyncUser]),
        throwsA(isA<MigrationException>()),
      );
    });

    test('none mode performs no database operations', () async {
      final client = FakeDatabaseClient();
      final synchronizer = AutoSchemaSynchronizer(
        client: client,
        dialect: const SqliteDialect(),
        mode: DdlAutoMode.none,
      );

      final result = await synchronizer.synchronize([SyncUser]);
      expect(result.getStatementsExecuted(), isEmpty);
      expect(client.recorded, isEmpty);
    });
  });
}