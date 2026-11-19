// test/mapping/entity_metadata_test.dart

import 'package:test/test.dart';
import 'package:jetleaf_core/lang.dart';
import 'package:jetleaf_data/jetleaf_data.dart';

import '../support/ensure_registry.dart';
import '../support/test_entities.dart';

void main() {
  setUpAll(ensureAotRegistered);

  test('snake_case strategy converts names', () {
    expect(NamingStrategy.snakeCase.classToTableName('UserProfile'), 'user_profile');
    expect(NamingStrategy.snakeCase.fieldToColumnName('createdAt'), 'created_at');
    expect(NamingStrategy.snakeCase.fieldToColumnName('HTMLParser'), 'html_parser');
    expect(NamingStrategy.snakeCase.fieldToColumnName('field2Go'), 'field2_go');
    expect(NamingStrategy.snakeCase.fieldToColumnName('already_snake'), 'already_snake');
  });

  test('camelCase strategy keeps names', () {
    expect(NamingStrategy.camelCase.classToTableName('UserProfile'), 'userProfile');
    expect(NamingStrategy.camelCase.fieldToColumnName('createdAt'), 'createdAt');
  });

  test('kebab-case strategy converts names', () {
    expect(NamingStrategy.kebabCase.classToTableName('UserProfile'), 'user-profile');
    expect(NamingStrategy.kebabCase.fieldToColumnName('createdAt'), 'created-at');
  });

  test('EntityMetadata is value-equal across builds', () {
    EntityMetadataRegistry.instance.clear();
    final first = EntityMetadataRegistry.instance.get<TestUser>();
    EntityMetadataRegistry.instance.clear();
    final second = EntityMetadataRegistry.instance.get<TestUser>();

    expect(first, second);
    expect(first.getColumns(), second.getColumns());
    expect(first.getTableName(), 'users');
  });

  test('@Transient fields are excluded and @DataVersion is mapped', () {
    final metadata = EntityMetadataRegistry.instance.get<TestUser>();
    expect(metadata.getIdColumn()?.isGenerated(), isTrue);
    expect(metadata.getIdColumn()?.getGenerationStrategy(), GenerationStrategy.autoIncrement);
    expect(metadata.getVersionColumn()?.getProperty(), 'version');
    expect(metadata.getVersionColumn()?.isVersion(), isTrue);
  });

  test('@Indexes are resolved with explicit and derived names', () {
    final metadata = EntityMetadataRegistry.instance.get<TestProduct>();
    final byColumn = {
      for (final index in metadata.getIndexes()) index.getColumnList(): index,
    };

    expect(byColumn['sku']?.isUnique(), isTrue);
    expect(byColumn['sku']?.getName(), 'idx_products_sku');
    expect(byColumn['name']?.isUnique(), isFalse);
    expect(byColumn['name']?.getName(), 'idx_products_name');
  });

  test('relationship target inferred from to-one field type', () {
    final metadata = EntityMetadataRegistry.instance.get<TestOrder>();
    final relationship = metadata.relationshipByProperty('owner')!;

    expect(relationship.getTargetEntity(), TestUser);
    expect(relationship.getType(), RelationshipType.manyToOne);
  });

  test('relationship target inferred from explicit targetEntity', () {
    final metadata = EntityMetadataRegistry.instance.get<TestAccount>();
    final relationship = metadata.relationshipByProperty('profile')!;
    expect(relationship.getTargetEntity(), TestProfile);
  });

  test('missing @Id throws a descriptive exception', () {
    expect(
      () => EntityMetadataBuilder().build<TestNoId>(Class<TestNoId>()),
      throwsA(
        isA<EntityMappingException>().having(
          (e) => e.message,
          'message',
          contains('@Id'),
        ),
      ),
    );
  });

  test('@Entity annotation is required', () {
    expect(
      () => EntityMetadataBuilder().build<TestNotAnEntity>(Class<TestNotAnEntity>()),
      throwsA(
        isA<EntityMappingException>().having(
          (e) => e.message,
          'message',
          contains('@Entity'),
        ),
      ),
    );
  });

  test('insert and update column sets respect database-generated ids and updatable', () {
    final metadata = EntityMetadataRegistry.instance.get<TestUser>();
    expect(metadata.getInsertColumns().map((c) => c.getProperty()), isNot(contains('id')));
    expect(metadata.getUpdateColumns().map((c) => c.getProperty()), isNot(contains('id')));
    expect(metadata.getUpdateColumns().map((c) => c.getProperty()), contains('version'));
  });

  test('column lookup helpers work', () {
    final metadata = EntityMetadataRegistry.instance.get<TestUser>();

    expect(metadata.columnByProperty('email')?.getName(), 'email_address');
    expect(metadata.columnByName('EMAIL_ADDRESS')?.getProperty(), 'email');
    expect(metadata.columnByName('nope'), isNull);
  });

  group('type converter registry', () {
    late TypeConverterRegistry converters;

    setUpAll(() {
      converters = TypeConverterRegistry.defaults();
    });

    test('bool round-trips through 0/1', () {
      expect(converters.toColumn(true, bool), 1);
      expect(converters.toColumn(false, bool), 0);
      expect(converters.fromColumn(1, bool), isTrue);
      expect(converters.fromColumn(0, bool), isFalse);
      expect(converters.fromColumn('true', bool), isTrue);
      expect(converters.fromColumn('0', bool), isFalse);
    });

    test('DateTime round-trips through ISO strings', () {
      final when = DateTime.utc(2030, 5, 1, 12, 30, 45);
      final stored = converters.toColumn(when, DateTime);
      expect(stored, isA<String>());

      final restored = converters.fromColumn(stored, DateTime);
      expect(restored, isA<DateTime>());
      expect((restored as DateTime).toUtc(), when);
    });

    test('DateTime accepts epoch millis', () {
      final millis = DateTime.utc(2030, 5, 1).millisecondsSinceEpoch;
      final restored = converters.fromColumn(millis, DateTime) as DateTime;
      expect(restored.toUtc().year, 2030);
    });

    test('enum round-trips through name', () {
      expect(converters.toColumn(TestStatus.banned, TestStatus), 'banned');
      expect(converters.fromColumn('banned', TestStatus), TestStatus.banned);
    });

    test('unknown enum value throws EntityMappingException', () {
      expect(
        () => converters.fromColumn('nonexistent', TestStatus),
        throwsA(isA<EntityMappingException>()),
      );
    });

    test('int and double widen/narrow', () {
      expect(converters.fromColumn(42, double), 42.0);
      expect(converters.fromColumn(42.0, int), 42);
      expect(converters.fromColumn('42', int), 42);
      expect(converters.fromColumn('42.5', double), 42.5);
    });
  });
}

@Entity()
class TestNoId {
  String? id;

  TestNoId();
}

class TestNotAnEntity {
  int? id;

  TestNotAnEntity();
}
