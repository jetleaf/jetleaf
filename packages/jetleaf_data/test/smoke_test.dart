// test/smoke_test.dart
//
// Early smoke tests: can the AOT registry see test entities, can the
// metadata builder map them, and can TypeReifier produce reified typed
// collections for user entity and enum types?

import 'package:test/test.dart';
import 'package:jetleaf_core/lang.dart';
import 'package:jetleaf_data/jetleaf_data.dart';

import 'support/ensure_registry.dart';
import 'support/test_entities.dart';

void main() {
  setUpAll(ensureAotRegistered);

  test('Class<TestUser>() sees the declared fields', () {
    final entityClass = Class<TestUser>();
    final names = entityClass.getFields().map((field) => field.getName()).toList();

    expect(names, containsAll(['id', 'email', 'firstName', 'lastName', 'age', 'active']));
  });

  test('EntityMetadataRegistry builds metadata for TestUser', () {
    final metadata = EntityMetadataRegistry.instance.get<TestUser>();

    expect(metadata.getTableName(), 'users');
    expect(metadata.getIdColumn()?.getProperty(), 'id');
    expect(metadata.getIdColumn()?.isGenerated(), isTrue);
    expect(metadata.getIdColumn()?.getGenerationStrategy(), GenerationStrategy.autoIncrement);
    expect(metadata.getVersionColumn()?.getProperty(), 'version');
    expect(metadata.getCreatedDateColumn()?.getProperty(), 'createdAt');
    expect(metadata.getLastModifiedDateColumn()?.getProperty(), 'updatedAt');

    final emailColumn = metadata.columnByProperty('email')!;
    expect(emailColumn.getName(), 'email_address');
    expect(emailColumn.isNullable(), isFalse);
    expect(emailColumn.isUnique(), isTrue);
    expect(emailColumn.getLength(), 320);
  });

  test('Relationship metadata resolves the target type', () {
    final metadata = EntityMetadataRegistry.instance.get<TestOrder>();
    final relationship = metadata.relationshipByProperty('owner')!;

    expect(relationship.getType(), RelationshipType.manyToOne);
    expect(relationship.getTargetEntity(), TestUser);
    expect(relationship.getJoinColumn(), 'owner_id');
  });

  test('EntityRowMapper round-trips a row', () {
    final metadata = EntityMetadataRegistry.instance.get<TestUser>();
    final mapper = EntityRowMapper<TestUser>(metadata);

    final row = <String, Object?>{
      'id': 7,
      'email_address': 'ada@example.com',
      'firstName': 'Ada',
      'lastName': 'Lovelace',
      'user_age': 36,
      'is_active': 1,
      'createdAt': '2024-01-02T03:04:05.000Z',
      'version': 3,
    };

    final user = mapper.mapRow(row);
    expect(user.id, 7);
    expect(user.email, 'ada@example.com');
    expect(user.active, isTrue);
    expect(user.createdAt, isA<DateTime>());
    expect(user.version, 3);
  });

  test('EnumConverter round-trips TestStatus via the registry', () {
    const converter = EnumConverter();
    expect(converter.toColumn(TestStatus.active), 'active');
    expect(converter.fromColumn('banned', TestStatus), TestStatus.banned);
  });

  test('TypeReifier produces reified List<T>, Set<T>, Map<K, V> for custom types and Function.apply', () {
    // Ensure Class<TestUser> and Class<TestStatus> are initialized
    Class<TestUser>();
    Class<TestStatus>();

    final u1 = TestUser.withValues(id: 1, email: 'a@example.com');
    final u2 = TestUser.withValues(id: 2, email: 'b@example.com');

    final dynamic rawUsers = <Object?>[u1, u2];
    final reifiedUsers = MaterializedLibrary.reifyList(rawUsers, elementTypeName: 'TestUser');
    expect(reifiedUsers, isA<List<TestUser>>());

    final reifiedSet = MaterializedLibrary.reifySet(rawUsers, elementTypeName: 'TestUser');
    expect(reifiedSet, isA<Set<TestUser>>());

    final reifiedMap = MaterializedLibrary.reifyMap(
      <Object?, Object?>{'u1': u1, 'u2': u2},
      keyTypeName: 'String',
      valueTypeName: 'TestUser',
    );
    expect(reifiedMap, isA<Map<String, TestUser>>());

    // Function.apply requires exact reified List<TestUser> and List<TestStatus>
    String acceptTyped(List<TestUser> users, List<TestStatus> statuses) {
      return '${users.length}:${statuses.first.name}';
    }

    final coercedUsers = MaterializedLibrary.coerceValue(rawUsers, 'List<TestUser>');
    final coercedStatuses = MaterializedLibrary.coerceValue(
      <Object?>[TestStatus.active],
      'List<TestStatus>',
    );
    final applied = Function.apply(acceptTyped, [coercedUsers, coercedStatuses]);
    expect(applied, '2:active');
  });
}