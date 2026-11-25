import 'package:jetleaf_core/lang.dart';
import 'package:jetleaf_data/jetleaf_data.dart';
import 'package:jetleaf_data/mongo.dart';
import 'package:jetleaf_data/mysql.dart';
import 'package:jetleaf_data/postgres.dart';
import 'package:jetleaf_data/sqlite.dart';

@Entity()
@Table(name: 'users')
class User {
  @Id()
  @GeneratedValue(strategy: GenerationStrategy.autoIncrement)
  int? id;

  @Column(name: 'email_address', nullable: false, unique: true, length: 320)
  String email = '';

  @Column(name: 'user_age')
  int age = 0;

  @Column(name: 'is_active')
  bool active = true;

  @CreatedDate()
  DateTime? createdAt;
}

void main() {
  print('=== Jetleaf Data Example ===\n');

  // 1. Naming strategy & TypeConverterRegistry
  const naming = SnakeCaseNamingStrategy();
  final converters = TypeConverterRegistry.defaults();
  print('Column name for "createdAt": ${naming.fieldToColumnName('createdAt')}');
  print('Converted DateTime -> column: ${converters.toColumn(DateTime.utc(2026, 1, 15), DateTime)}');
  print('');

  // 2. Construct EntityMetadata<User>
  final metadata = EntityMetadata<User>(
    entityClass: Class<User>(null, 'jetleaf_data_example'),
    entityType: User,
    simpleName: 'User',
    tableName: 'users',
    columns: const [
      ColumnMetadata(
        name: 'id',
        property: 'id',
        fieldType: int,
        isId: true,
        isGenerated: true,
        generationStrategy: GenerationStrategy.autoIncrement,
        nullable: false,
      ),
      ColumnMetadata(
        name: 'email_address',
        property: 'email',
        fieldType: String,
        nullable: false,
        unique: true,
        length: 320,
      ),
      ColumnMetadata(
        name: 'user_age',
        property: 'age',
        fieldType: int,
      ),
      ColumnMetadata(
        name: 'is_active',
        property: 'active',
        fieldType: bool,
      ),
      ColumnMetadata(
        name: 'created_at',
        property: 'createdAt',
        fieldType: DateTime,
        isCreatedDate: true,
      ),
    ],
    relationships: const [],
    indexes: const [],
    fields: const {},
  );

  // 3. Parse derived repository method names into PartTree
  final methods = [
    'findByEmail',
    'findTop5ByActiveTrueAndAgeGreaterThanEqualOrderByCreatedAtDesc',
    'countByActiveTrue',
  ];

  for (final method in methods) {
    final tree = PartTree.parse(method, metadata: metadata);
    print('Parsed "$method" -> subject=${tree.getSubject().name}, limit=${tree.getLimit()}, parts=${tree.getParts().length}');
  }
  print('');

  // 4. Render QueryCriteria across SQL & Document dialects
  final page = PageRequest.of(0, 10, SortDirection.DESC, ['createdAt']);
  final criteria = QueryCriteria.select(
    metadata: metadata,
    predicate: CompositeCriterion.and([
      PartCriterion(Part(property: 'age', operator_: PartOperator.greaterThanEqual)),
      PartCriterion(Part(property: 'active', operator_: PartOperator.isTrue)),
    ]),
    values: [21],
    sort: page.getSort(),
    limit: page.getPageSize(),
    offset: page.getOffset(),
  );

  final dialects = <DatabaseDialect>[
    const PostgreSqlDialect(),
    const MySqlDialect(),
    const SqliteDialect(),
    const MongoDialect(),
  ];

  for (final dialect in dialects) {
    final rendered = dialect.renderQuery(criteria);
    print('[${dialect.getName()}] ${rendered.getSql()} | params=${rendered.getParameters()}');
  }
}